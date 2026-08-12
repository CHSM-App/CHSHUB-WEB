/*
 * FIX: sp_house's @village_id is narrower than the column it is compared to.
 *
 * Why it matters
 * --------------
 * dbo.house.village_id and dbo.house$ARC.village_id are both nvarchar(50), but
 * the procedure declares:
 *
 *     @village_id nvarchar(10) = Null
 *
 * SQL Server truncates a longer argument silently on the way in. The truncated
 * value then equals nothing in the table, so every branch that filters on it —
 * Grid_Show, Grid_Show_hist and house_history — returns an empty result for
 * such a village. No error is raised; the page simply looks like it has no
 * records.
 *
 * Today's ids are short enough to fit, so this is latent rather than active.
 * It becomes a live fault the moment a village is registered with an id over
 * ten characters, and the failure gives no clue as to its cause.
 *
 * Why it is a separate script
 * ---------------------------
 * FIX_house_history_missing_rows.sql grew this change after it had already
 * been applied to a database. That script stamps the body with a
 * 'house_history_patched' marker and short-circuits on it, so re-running it
 * will not pick this up. This one is keyed on the parameter text itself.
 *
 * Nothing else about the procedure is touched, and widening a parameter
 * accepts everything it accepted before.
 *
 * Safe to re-run, and safe on a database where the other script never ran.
 */

SET NOCOUNT ON;
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house not found in this database.', 16, 1);
    SET @stop = 1;
END

DECLARE @old NVARCHAR(MAX) = N'@village_id nvarchar(10)=Null';
DECLARE @new NVARCHAR(MAX) = N'@village_id nvarchar(50)=Null';

IF @stop = 0 AND CHARINDEX(@old, @body) = 0
BEGIN
    IF CHARINDEX(@new, @body) > 0
        PRINT 'sp_house: @village_id is already nvarchar(50) - no change made.';
    ELSE
        RAISERROR('Could not locate the @village_id parameter - apply the change by hand.', 16, 1);

    SET @stop = 1;
END

IF @stop = 0
BEGIN
    SET @body = REPLACE(@body, @old, @new);

    -- OBJECT_DEFINITION returns the body from 'CREATE PROCEDURE' onward, so the
    -- first CREATE is the one to turn into ALTER.
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

    EXEC sp_executesql @body;

    PRINT 'sp_house: @village_id widened to nvarchar(50).';
END
GO

/* ---------------------------------------------------------- verification */

-- Should report nvarchar with max_length 100 (bytes: 50 nvarchar characters).
SELECT
    p.name              AS parameter,
    t.name              AS type,
    p.max_length        AS max_length_bytes,
    p.max_length / 2    AS characters
FROM sys.parameters AS p
JOIN sys.types      AS t ON p.user_type_id = t.user_type_id
WHERE p.object_id = OBJECT_ID('dbo.sp_house')
  AND p.name = '@village_id';
GO
