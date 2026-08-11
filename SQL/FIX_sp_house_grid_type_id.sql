/*
 * FIX: sp_house 'Grid_Show' returns the house type's name but not its id.
 *
 * Why it matters
 * --------------
 * v_resident.aspx edits a row's charges inline and posts them back through
 * sp_house 'Update'. That branch writes house_no along with the charges:
 *
 *     UPDATE house
 *     SET house_no = @house_no, area = @area, gharpatti_charges = ...
 *
 * so a caller has to send the row's existing house_no or the column is blanked.
 * The web API asks for house_type on the same call, because sp_house's INSERT
 * path does write it and defaulting it there would file new houses under type 0.
 *
 * But Grid_Show returns `dbo.house_type.house_type` — the *name*
 * ("Kaccha house") — and never house_type_id, so a grid row has no id to send
 * back. The React page currently works around that by passing a placeholder,
 * which is only safe for as long as the UPDATE branch keeps ignoring the column.
 *
 * Fix
 * ---
 * Add house_type_id to the Grid_Show projection. Nothing is removed or
 * renamed — the existing `house_type` name column stays exactly where it was —
 * so the legacy WebForms grid, which binds by name, is unaffected.
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

IF @body LIKE '%house_type.house_type_id%'
BEGIN
    PRINT 'Already patched - no change made.';
    RETURN;
END

DECLARE @old NVARCHAR(MAX) =
    N'dbo.house_owner.address, dbo.house_owner.pre_mob, dbo.house_owner.village_owner_id';

DECLARE @new NVARCHAR(MAX) =
    N'dbo.house_owner.address, dbo.house_owner.pre_mob, dbo.house_owner.village_owner_id, dbo.house_type.house_type_id';

IF CHARINDEX(@old, @body) = 0
BEGIN
    RAISERROR('Could not locate the Grid_Show column list - apply the change by hand.', 16, 1);
    RETURN;
END

SET @body = REPLACE(@body, @old, @new);
SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

EXEC sp_executesql @body;

PRINT 'sp_house Grid_Show now returns house_type_id.';
GO

-- Verification: house_type_id should appear beside the existing house_type name.
DECLARE @v NVARCHAR(10) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC sp_house @operation = 'Grid_Show', @village_id = @v;
GO
