/*
 * FIX: village bill generation files every bill under one hard-coded village,
 *      and the pending-charges list is not filtered by village at all.
 *
 * Four faults, all in the same path — generating a tax bill and then listing
 * what is outstanding. They are only invisible today because exactly one
 * village (V10004, Adeli) has houses; the moment a second village generates a
 * bill, money is attributed to the wrong village.
 *
 *
 * FAULT 1 — bills are filed under a hard-coded village
 * ----------------------------------------------------
 * sp_house_tax_receipt's three bill_gen branches ignore @village_id entirely:
 *
 *     SELECT house_id, gharpatti_charges FROM dbo.house WHERE village_id='V10004'
 *     ...
 *     INSERT INTO house_tax_receipt (... village_id ...) VALUES (..., 'V10004', ...)
 *
 * So whichever village signs in and generates bills, the cursor reads V10004's
 * houses and stamps V10004 on every row. Another village would bill Adeli's
 * houses and see nothing of its own.
 *
 * Fixed by: using @village_id in both the cursor and the INSERT.
 *
 *
 * FAULT 2 — receipt numbers restart at a fixed number every run
 * -------------------------------------------------------------
 * @receipt_no1 is initialised to 1001 (2001 water, 3001 waste) on every call,
 * so a second run re-issues 1001, 1002, … alongside the first run's. Receipt
 * numbers are how a payment is identified on paper; duplicates make a receipt
 * ambiguous.
 *
 * Fixed by: seeding from the highest receipt_no already issued for that
 * village and payment type, so numbering continues rather than restarts. The
 * legacy starting points are kept as the floor for a village with no history.
 *
 *
 * FAULT 3 — a bill can be generated twice for the same house
 * ----------------------------------------------------------
 * Nothing checks whether an unpaid bill already exists, so running generation
 * twice bills every house twice and doubles the outstanding total.
 *
 * Fixed by: skipping houses that already have an unpaid (payment_status = 0)
 * bill of that type.
 *
 *
 * FAULT 4 — pending charges are not filtered by village
 * ------------------------------------------------------
 * Grid_pending_charges reads:
 *
 *     FROM dbo.Housewise_pending_charges_vw
 *     WHERE @village_id = @village_id      -- always true
 *
 * That compares the parameter with itself, so it is true for every row and the
 * list returns every village's pending charges. The reason it was written that
 * way is that Housewise_pending_charges_vw does not expose village_id, so
 * there was no column to filter on.
 *
 * Fixed by: adding village_id to the view (it is already available on the
 * underlying House_wise_payment_vw) and filtering on it properly. The view
 * gains a column and loses none, so anything selecting named columns from it
 * is unaffected.
 *
 *
 * Existing data is not modified. Bills already written under V10004 belong to
 * V10004 — the only village with houses — so they are correct as they stand.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------------- part 1: the view */

/*
 * ALTER, not DROP/CREATE: dropping would briefly break anything selecting from
 * it, and ALTER VIEW keeps permissions. Written out in full because a view
 * cannot be patched textually the way a procedure body can.
 */
IF OBJECT_ID('dbo.Housewise_pending_charges_vw', 'V') IS NULL
BEGIN
    RAISERROR('Housewise_pending_charges_vw not found in this database.', 16, 1);
END
GO

ALTER VIEW [dbo].[Housewise_pending_charges_vw]
AS
-- village_id added so the caller can scope to one village; every other column
-- is unchanged, in its original order.
SELECT house_id, house_no, owner_name, pre_mob, Month, year, village_id,
       pending_amount AS pending_property_tax, 0 AS pending_water_charges, 0 AS pending_waste_charges
FROM   dbo.House_wise_payment_vw
WHERE  (payment_type = 1)
UNION
SELECT house_id, house_no, owner_name, pre_mob, Month, year, village_id,
       0 AS pending_property_tax, pending_amount AS pending_water_charges, 0 AS pending_waste_charges
FROM   dbo.House_wise_payment_vw
WHERE  (payment_type = 2)
UNION
SELECT house_id, house_no, owner_name, pre_mob, Month, year, village_id,
       0 AS pending_property_tax, 0 AS pending_water_charges, pending_amount AS pending_waste_charges
FROM   dbo.House_wise_payment_vw
WHERE  (payment_type = 3);
GO

PRINT 'Housewise_pending_charges_vw: village_id added.';
GO

/* ------------------------------------------- part 2: the procedure */

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house_tax_receipt'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house_tax_receipt not found in this database.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%bill_gen_patched%'
BEGIN
    PRINT 'sp_house_tax_receipt: already patched - no change made.';
    SET @stop = 1;
END

/* -- fault 4: the self-comparing WHERE ---------------------------------- */

/*
 * Optional, unlike the others: on some databases this branch has already been
 * corrected by hand to `Where village_id = @village_id`. Missing text here
 * means the fix is present, not that the script is looking in the wrong
 * place — so it is skipped rather than treated as a failure.
 */
DECLARE @oldWhere NVARCHAR(MAX) = N'Where @village_id=@village_id';

IF @stop = 0
BEGIN
    IF CHARINDEX(@oldWhere, @body) > 0
    BEGIN
        SET @body = REPLACE(@body, @oldWhere, N'Where village_id=@village_id');
        PRINT 'Grid_pending_charges: village filter corrected.';
    END
    /*
     * Spacing around the `=` varies between databases — one has been corrected
     * by hand as `Where village_id = @village_id`. Match on the parts either
     * form shares rather than on an exact string, so a stray space is not read
     * as "the fix is missing".
     */
    ELSE IF @body LIKE N'%Where village_id%=%@village_id%'
        PRINT 'Grid_pending_charges: village filter already correct - left as is.';
    ELSE
    BEGIN
        RAISERROR('Grid_pending_charges WHERE clause is in neither known form - check by hand.', 16, 1);
        SET @stop = 1;
    END
END

/*
 * The branch's GROUP BY does not need village_id: the WHERE now pins it to a
 * single value, so it is constant across the result and grouping by it would
 * change nothing.
 */

/* -- faults 1-3: the three bill_gen branches ---------------------------- */

/*
 * Each branch differs only in the charge column, the receipt-number seed and
 * the payment type, so the same three replacements are applied to each with
 * the numbers varied. Done as literal replacements against the known text.
 */
/*
 * Every variable is declared once, up front, and assigned with SET inside the
 * loop.
 *
 * T-SQL hoists DECLARE to the start of the batch and runs the initialiser
 * only where the statement sits — but a DECLARE inside a WHILE body does NOT
 * re-initialise on the second pass. Declaring @oldSeed = <expression> in the
 * loop therefore kept its first-iteration value ('@receipt_no1 int=1001')
 * while @rn and @seed had moved on to branch 2, so the search text no longer
 * matched anything and the run stopped with "Could not locate a receipt_no
 * declaration".
 */
DECLARE @i INT = 1;
/*
 * Generous widths on purpose. @rn held '@receipt_no1' — twelve characters — in
 * an NVARCHAR(10), so it was silently truncated to '@receipt_no' and the seed
 * text it built ('@receipt_no int=1001') matched nothing in the procedure.
 * That is the same class of bug this script exists to fix, so there is no
 * reason to keep these tight.
 */
DECLARE @charge NVARCHAR(128), @rn NVARCHAR(128), @seed NVARCHAR(128), @hid NVARCHAR(128);
DECLARE @oldCur NVARCHAR(MAX), @newCur NVARCHAR(MAX);
DECLARE @oldSeed NVARCHAR(MAX), @newSeed NVARCHAR(MAX);
DECLARE @oldOpen NVARCHAR(MAX) = N'OPEN Village_bill_gen;', @newOpen NVARCHAR(MAX);
DECLARE @oldIns NVARCHAR(MAX), @newIns NVARCHAR(MAX);
DECLARE @curAt INT, @openAt INT;

WHILE @stop = 0 AND @i <= 3
BEGIN
    SELECT
        @charge = CASE @i WHEN 1 THEN 'gharpatti_charges' WHEN 2 THEN 'water_charges' ELSE 'waste_charges' END,
        @rn     = CASE @i WHEN 1 THEN '@receipt_no1' WHEN 2 THEN '@receipt_no2' ELSE '@receipt_no3' END,
        @seed   = CASE @i WHEN 1 THEN '1001' WHEN 2 THEN '2001' ELSE '3001' END,
        @hid    = CASE @i WHEN 1 THEN '@house_id1' WHEN 2 THEN '@house_id2' ELSE '@house_id3' END;

    -- 1. the cursor's village
    SET @oldCur = N'SELECT  house_id, ' + @charge + N'  FROM  dbo.house where village_id=''V10004''';
    -- Carries the marker the re-run check above looks for.
    SET @newCur =
        N'SELECT  house_id, ' + @charge + N'  FROM  dbo.house where village_id=@village_id' +
        N' /* bill_gen_patched */' +
        N' AND NOT EXISTS (SELECT 1 FROM dbo.house_tax_receipt r WHERE r.house_id = dbo.house.house_id' +
        N' AND r.payment_type = ' + CAST(@i AS NVARCHAR(2)) + N' AND r.payment_status = 0)';

    IF CHARINDEX(@oldCur, @body) = 0
    BEGIN
        RAISERROR('Could not locate a bill_gen cursor - apply by hand.', 16, 1);
        SET @stop = 1;
        BREAK;
    END

    SET @body = REPLACE(@body, @oldCur, @newCur);

    -- 2. the receipt-number seed
    SET @oldSeed = @rn + N' int=' + @seed;
    SET @newSeed = @rn + N' int';

    IF CHARINDEX(@oldSeed, @body) = 0
    BEGIN
        RAISERROR('Could not locate a receipt_no declaration - apply by hand.', 16, 1);
        SET @stop = 1;
        BREAK;
    END

    SET @body = REPLACE(@body, @oldSeed, @newSeed);

    -- Continue from the highest number already issued, rather than restarting.
    SET @newOpen =
        N'SELECT ' + @rn + N' = ISNULL(MAX(receipt_no), ' + @seed + N' - 1) + 1 FROM dbo.house_tax_receipt' +
        N' WHERE village_id = @village_id AND payment_type = ' + CAST(@i AS NVARCHAR(2)) + N';
OPEN Village_bill_gen;';

    /*
     * All three branches contain the identical text 'OPEN Village_bill_gen;',
     * so searching from the start would put every seed in the first branch.
     * Anchor the search to this branch's own cursor — just rewritten above,
     * and unique because it names this branch's charge column.
     */
    SET @curAt = CHARINDEX(@newCur, @body);
    IF @curAt = 0
    BEGIN
        RAISERROR('Could not re-locate the patched cursor - apply by hand.', 16, 1);
        SET @stop = 1;
        BREAK;
    END

    SET @openAt = CHARINDEX(@oldOpen, @body, @curAt);
    IF @openAt = 0
    BEGIN
        RAISERROR('Could not locate a cursor OPEN - apply by hand.', 16, 1);
        SET @stop = 1;
        BREAK;
    END

    SET @body = STUFF(@body, @openAt, LEN(@oldOpen), @newOpen);

    -- 3. the INSERT's hard-coded village
    SET @oldIns = N'values(' + @hid + N',@' + @charge + N',getdate(),null,0,''V10004''';
    SET @newIns = N'values(' + @hid + N',@' + @charge + N',getdate(),null,0,@village_id';

    IF CHARINDEX(@oldIns, @body) = 0
    BEGIN
        RAISERROR('Could not locate a bill_gen INSERT - apply by hand.', 16, 1);
        SET @stop = 1;
        BREAK;
    END

    SET @body = REPLACE(@body, @oldIns, @newIns);

    SET @i = @i + 1;
END

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

    EXEC sp_executesql @body;

    PRINT 'sp_house_tax_receipt: bills now use @village_id, numbering continues, duplicates skipped, pending filtered.';
END
GO

/* ---------------------------------------------------------- verification */

-- No row should remain where a receipt's village differs from its house's.
SELECT COUNT(*) AS receipts_filed_under_the_wrong_village
FROM   dbo.house_tax_receipt r
JOIN   dbo.house h ON h.house_id = r.house_id
WHERE  ISNULL(r.village_id, '') <> ISNULL(h.village_id, '');

-- Duplicate receipt numbers within a village and payment type.
SELECT village_id, payment_type, receipt_no, COUNT(*) AS times_issued
FROM   dbo.house_tax_receipt
GROUP  BY village_id, payment_type, receipt_no
HAVING COUNT(*) > 1
ORDER  BY village_id, payment_type, receipt_no;

-- The view now carries village_id.
SELECT TOP 5 village_id, house_no, owner_name,
       pending_property_tax, pending_water_charges, pending_waste_charges
FROM   dbo.Housewise_pending_charges_vw;
GO
