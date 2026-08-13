/*
 * FIX: deleting a village resident appears to do nothing — the row stays in
 * the Village Residents list.
 *
 * What happens
 * ------------
 * Delete on that page calls DELETE /village/owners/:id, which runs
 * sp_house_owner 'Delete'. That branch is a soft delete: it sets
 * house_owner.active_status rather than removing the row. Every other query in
 * the database honours the flag —
 *
 *     LEFT JOIN dbo.house_owner o ON o.house_id = r.house_id
 *                                AND ISNULL(o.active_status, 0) = 0
 *
 * (see FIX_duplicate_village_tax_bills.sql) — so 0 is live and anything else
 * is deleted.
 *
 * sp_house 'Grid_Show' is the one that does not. It is what the residents page
 * lists, and it joins house_owner with no filter on active_status, so a
 * resident that has just been deleted is read back on the very next refresh.
 * The API returned success, the toast said "deleted", and the row reappeared —
 * which reads as the button doing nothing at all.
 *
 * Fix
 * ---
 * Add the same ISNULL(...) = 0 predicate to Grid_Show's house_owner join.
 * Nothing is removed or renamed and no column list changes, so the legacy
 * WebForms grid — which binds these columns by name — is unaffected.
 *
 * A house whose only resident has been deleted still appears, now with the
 * owner columns empty. That is correct: the house itself was not deleted, and
 * the page's Add flow files a new resident against it.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house'));

IF @body IS NULL
BEGIN
    RAISERROR('sp_house not found in this database.', 16, 1);
    RETURN;
END

/* Already patched? The predicate below is unique to this change. */
IF @body LIKE '%house_owner.active_status%'
BEGIN
    PRINT 'Already patched - no change made.';
    RETURN;
END

/*
 * The join as Grid_Show writes it. Matched on the ON clause rather than the
 * whole statement so the surrounding projection — which other scripts have
 * extended — does not have to be reproduced here.
 *
 * The same clause appears twice: once in Grid_Show and once in
 * Grid_Show_hist. REPLACE patches both, which is what we want — a deleted
 * resident should not reappear in either. Nothing in the API calls
 * Grid_Show_hist (the history screen uses the 'house_history' branch), so
 * that second edit changes no screen currently in use.
 */
DECLARE @old NVARCHAR(MAX) =
    N'dbo.house_owner ON dbo.house.house_id = dbo.house_owner.house_id';

DECLARE @new NVARCHAR(MAX) =
    N'dbo.house_owner ON dbo.house.house_id = dbo.house_owner.house_id AND ISNULL(dbo.house_owner.active_status, 0) = 0';

IF CHARINDEX(@old, @body) = 0
BEGIN
    RAISERROR('Could not locate the house_owner join in sp_house - apply the change by hand.', 16, 1);
    RETURN;
END

SET @body = REPLACE(@body, @old, @new);
SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

EXEC sp_executesql @body;

PRINT 'sp_house Grid_Show now hides deleted residents.';
GO

/* ---------------------------------------------------------- verification */

/*
 * 1. The predicate is now in the procedure. This should print 'patched'.
 */
SELECT CASE
         WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house')) LIKE '%house_owner.active_status%'
         THEN 'patched'
         ELSE 'NOT patched'
       END AS grid_show_state;
GO

/*
 * 2. How many residents are soft-deleted. Any count above zero is what used to
 *    keep showing on the page; run sp_house 'Grid_Show' for that village and
 *    none of these names should appear.
 */
SELECT COUNT(*) AS deleted_residents_now_hidden
FROM   dbo.house_owner
WHERE  ISNULL(active_status, 0) <> 0;
GO
