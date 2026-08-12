/*
 * FIX: sp_house 'house_history' returns fewer rows than the archive holds, and
 *      nothing writes to the archive in the first place.
 *
 * Two separate faults, both of which have to be fixed for the History page to
 * be correct. This script fixes both.
 *
 *
 * FAULT 1 — the report drops rows it should return
 * ------------------------------------------------
 * house$ARC does not store house_no, only house_id, so the projection reaches
 * for it through dbo.house. It does so with INNER JOINs:
 *
 *     FROM dbo.house$ARC
 *     INNER JOIN dbo.house     ON house$ARC.house_id = house.house_id
 *                             AND house$ARC.village_id = house.village_id
 *     INNER JOIN dbo.UserLogin ON house$ARC.audt_modify_id = UserLogin.user_id
 *     WHERE dbo.house.village_id = @village_id
 *
 * An INNER JOIN keeps a row only when the other side matches, so a history row
 * disappears whenever either lookup fails:
 *
 *   - the house is gone. dbo.house has no active/deleted flag and rows are
 *     removed outright, taking every archived edit with them — precisely the
 *     history an audit trail exists to preserve.
 *   - audt_modify_id matches no UserLogin row: a since-removed operator, or a
 *     0 written by a path that never set the column. house.audt_modify_id is
 *     nullable and sp_house defaults @audt_modify_id to 0, so 0 is common.
 *
 * The WHERE compounds it by scoping on dbo.house.village_id — the surviving
 * house — rather than the archived row, so even a LEFT JOIN would still drop a
 * deleted house's history when that column came back NULL.
 *
 * Fixed by: LEFT JOIN both lookups, scope on house$ARC.village_id, and read
 * house_id from the archive. house_no falls back to '#<id>' and updated_by to
 * 'Unknown', so a deleted house or a removed operator still reads as something
 * rather than an empty cell.
 *
 *
 * FAULT 2 — the archive is never written
 * --------------------------------------
 * Nothing in this database inserts into house$ARC: sp_house's Update branch
 * writes only to dbo.house, and there is no trigger on the table. Whatever
 * populated the existing rows is not part of the schema any more, so every
 * edit made from here on is lost and the History page slowly goes stale.
 *
 * Fixed by: an AFTER INSERT, UPDATE, DELETE trigger on dbo.house that records
 * each change. It reads the row's own audt_modify_id — the column sp_house
 * already sets from the signed-in user — so no caller has to change.
 *
 * A DELETE is archived from the `deleted` pseudo-table, which is why fault 1
 * had to be fixed too: those rows have no dbo.house to join back to, and under
 * the old INNER JOIN they would have been invisible the moment they were
 * written.
 *
 * Both parts are safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------------------------------ part 1 */

/*
 * Guarded with @stop rather than a run of bare RETURNs: outside a procedure
 * RETURN only leaves the batch, so a failed anchor check would fall through to
 * sp_executesql and install a half-patched body. The ALTER runs only when
 * every anchor was found.
 */
DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house not found in this database.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%house_history_patched%'
BEGIN
    PRINT 'sp_house: already patched - no change made.';
    SET @stop = 1;
END

-- dbo.house$ARC -> dbo.house
DECLARE @oldFrom NVARCHAR(MAX) = N'FROM            dbo.house$ARC INNER JOIN';
DECLARE @newFrom NVARCHAR(MAX) = N'FROM            dbo.house$ARC LEFT JOIN';

IF @stop = 0 AND CHARINDEX(@oldFrom, @body) = 0
BEGIN
    RAISERROR('Could not locate the house_history FROM clause - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldFrom, @newFrom);

-- dbo.house -> dbo.UserLogin
DECLARE @oldJoin NVARCHAR(MAX) = N'dbo.house.village_id INNER JOIN';
DECLARE @newJoin NVARCHAR(MAX) = N'dbo.house.village_id LEFT JOIN';

IF @stop = 0 AND CHARINDEX(@oldJoin, @body) = 0
BEGIN
    RAISERROR('Could not locate the house_history UserLogin join - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldJoin, @newJoin);

/*
 * Scope from the archived row, which outlives the house.
 *
 * This WHERE text appears three times in sp_house — Grid_Show and
 * Grid_Show_hist carry it too, and both are correct as they stand — so it is
 * rewritten by position rather than with REPLACE: the one that follows the
 * UserLogin join, which only house_history has.
 */
DECLARE @anchor   NVARCHAR(MAX) = N'dbo.UserLogin ON dbo.house$ARC.audt_modify_id = dbo.UserLogin.user_id';
DECLARE @oldWhere NVARCHAR(MAX) = N'WHERE  dbo.house.village_id=@village_id';
DECLARE @newWhere NVARCHAR(MAX) = N'WHERE  dbo.house$ARC.village_id=@village_id /* house_history_patched */';

DECLARE @anchorAt INT = CASE WHEN @stop = 0 THEN CHARINDEX(@anchor, @body) ELSE 0 END;
IF @stop = 0 AND @anchorAt = 0
BEGIN
    RAISERROR('Could not locate the house_history UserLogin join - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

DECLARE @whereAt INT = CASE WHEN @stop = 0 THEN CHARINDEX(@oldWhere, @body, @anchorAt) ELSE 0 END;
IF @stop = 0 AND @whereAt = 0
BEGIN
    RAISERROR('Could not locate the house_history WHERE clause - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = STUFF(@body, @whereAt, LEN(@oldWhere), @newWhere);

-- Display fallbacks, so a deleted house or a removed operator still reads.
DECLARE @oldCols NVARCHAR(MAX) =
    N'SELECT        TOP (100) PERCENT dbo.house.house_no, dbo.UserLogin.name AS updated_by,';
DECLARE @newCols NVARCHAR(MAX) =
    N'SELECT        TOP (100) PERCENT ISNULL(dbo.house.house_no, ''#'' + CAST(dbo.house$ARC.house_id AS NVARCHAR(20))) AS house_no, ISNULL(dbo.UserLogin.name, ''Unknown'') AS updated_by,';

IF @stop = 0 AND CHARINDEX(@oldCols, @body) = 0
BEGIN
    RAISERROR('Could not locate the house_history SELECT list - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldCols, @newCols);

-- The trailing house_id reads from dbo.house, now NULL for a deleted house.
DECLARE @oldId NVARCHAR(MAX) = N'dbo.house$ARC.waste_charges, dbo.house.house_id';
DECLARE @newId NVARCHAR(MAX) = N'dbo.house$ARC.waste_charges, dbo.house$ARC.house_id';

/*
 * @village_id is also too narrow — nvarchar(10) against an nvarchar(50)
 * column — but that change lives in FIX_sp_house_village_id_width.sql. It was
 * found after this script had already been applied, and the marker check above
 * makes this one a no-op on such a database, so putting it here would mean it
 * never ran. Apply that script as well.
 */

IF @stop = 0 AND CHARINDEX(@oldId, @body) = 0
BEGIN
    RAISERROR('Could not locate the house_history house_id column - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldId, @newId);

IF @stop = 0
BEGIN
    -- OBJECT_DEFINITION returns the body from 'CREATE PROCEDURE' onward, so the
    -- first CREATE is the one to turn into ALTER.
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

    EXEC sp_executesql @body;

    PRINT 'sp_house: house_history now keeps rows whose house or operator is gone.';
END
GO

/* ------------------------------------------------------------------ part 2 */

IF OBJECT_ID('dbo.trg_house_archive', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_house_archive;
GO

/*
 * Records every change to dbo.house in house$ARC.
 *
 * action_type is nvarchar(50) and the existing rows use plain words, so this
 * writes 'Insert' / 'Update' / 'Delete' to match.
 *
 * audt_modify_id is NOT NULL on house$ARC but nullable on house, and sp_house
 * defaults it to 0 — so it is coalesced to 0 rather than failing the insert.
 * house_history's UserLogin join is LEFT after part 1, so a 0 shows as
 * 'Unknown' instead of dropping the row.
 *
 * Set-based, not row-by-row: an UPDATE touching many houses archives them all.
 */
CREATE TRIGGER dbo.trg_house_archive
ON dbo.house
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert and update both leave a row in `inserted`; only a delete does not.
    INSERT INTO dbo.house$ARC
        (house_id, village_id, audt_modify_id, modification_date, action_type,
         area, gharpatti_charges, no_of_tab, water_charges, waste_charges)
    SELECT
        i.house_id,
        i.village_id,
        ISNULL(i.audt_modify_id, 0),
        CAST(GETDATE() AS DATE),
        CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN 'Update' ELSE 'Insert' END,
        i.area,
        i.gharpatti_charges,
        i.no_of_tab,
        i.water_charges,
        i.waste_charges
    FROM inserted AS i;

    -- A delete: archive the row as it stood, so the history outlives the house.
    INSERT INTO dbo.house$ARC
        (house_id, village_id, audt_modify_id, modification_date, action_type,
         area, gharpatti_charges, no_of_tab, water_charges, waste_charges)
    SELECT
        d.house_id,
        d.village_id,
        ISNULL(d.audt_modify_id, 0),
        CAST(GETDATE() AS DATE),
        'Delete',
        d.area,
        d.gharpatti_charges,
        d.no_of_tab,
        d.water_charges,
        d.waste_charges
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted);
END
GO

PRINT 'dbo.trg_house_archive created - edits to dbo.house are now archived.';
GO

/* ---------------------------------------------------------- verification */

/*
 * archived_rows is what the village actually has on file; returned_before_fix
 * is what the old INNER-JOIN form would have handed back. The second being
 * lower is the bug — those were the missing houses. The result set below
 * should now carry archived_rows many rows.
 */
-- house$ARC.village_id is nvarchar(50); declaring this narrower would truncate.
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house$ARC WHERE village_id IS NOT NULL);

SELECT
    @v                                                          AS village_id,
    (SELECT COUNT(*) FROM dbo.house$ARC WHERE village_id = @v)  AS archived_rows,
    (SELECT COUNT(*)
       FROM dbo.house$ARC a
       JOIN dbo.house h     ON a.house_id = h.house_id AND a.village_id = h.village_id
       JOIN dbo.UserLogin u ON a.audt_modify_id = u.user_id
      WHERE h.village_id = @v)                                  AS returned_before_fix;

EXEC sp_house @operation = 'house_history', @village_id = @v;
GO
