/*
 * FIX: village pending charges are wrong in two ways.
 *
 * Symptom
 * -------
 * On Tax Payments, the Pending Bills grid shows a house owing (say) Rs.6,000
 * property tax, but clicking that figure opens a dialog with no bills in it —
 * nothing to tick, nothing to pay. Meanwhile houses from other villages appear
 * in the list.
 *
 * Cause 1 — Housewise_pending_charges_vw counts paid bills as pending
 * -------------------------------------------------------------------
 * The view selects pending_amount from House_wise_payment_vw for each payment
 * type, but never filters on payment_status:
 *
 *     SELECT ... pending_amount AS pending_property_tax ...
 *     FROM   dbo.House_wise_payment_vw
 *     WHERE  (payment_type = 1)          -- no payment_status test
 *
 * so a settled receipt keeps contributing to the total. House 1 in V10004 has
 * both its property-tax receipts paid (Rs.6,000 collected) and still reports
 * Rs.6,000 outstanding. The pay dialog reads Grid_not_paid_p, which *does*
 * filter on payment_status = 0, correctly finds nothing, and opens empty.
 *
 * Cause 2 — sp_house_tax_receipt 'Grid_pending_charges' does not scope by village
 * ------------------------------------------------------------------------------
 *     Where @village_id=@village_id
 *
 * compares the parameter to itself, which is true for every row, so the grid
 * lists every village's houses. The view has no village_id column to filter on,
 * which is why the predicate was written this way; adding the column fixes it.
 *
 * Fix
 * ---
 * Rebuild the view with a payment_status filter and a village_id column, then
 * point the procedure's WHERE at that column. Column order and names are
 * preserved and village_id is added at the end, so the legacy WebForms page —
 * which binds by name — is unaffected.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------- the view */

ALTER VIEW [dbo].[Housewise_pending_charges_vw]
AS
/*
 * One row per unpaid bill, with the amount landing in the column for its
 * payment type. payment_status = 0 is "Not Paid" — without it a settled
 * receipt kept counting towards the outstanding total.
 *
 * UNION ALL rather than UNION: the branches are disjoint by payment_type, so
 * there are no duplicates to remove, and UNION was also collapsing two genuinely
 * separate bills of the same type, month and amount into one.
 */
SELECT house_id, house_no, owner_name, pre_mob, Month, year,
       pending_amount AS pending_property_tax,
       0              AS pending_water_charges,
       0              AS pending_waste_charges,
       village_id
FROM   dbo.House_wise_payment_vw
WHERE  payment_type = 1 AND ISNULL(payment_status, 0) = 0
UNION ALL
SELECT house_id, house_no, owner_name, pre_mob, Month, year,
       0              AS pending_property_tax,
       pending_amount AS pending_water_charges,
       0              AS pending_waste_charges,
       village_id
FROM   dbo.House_wise_payment_vw
WHERE  payment_type = 2 AND ISNULL(payment_status, 0) = 0
UNION ALL
SELECT house_id, house_no, owner_name, pre_mob, Month, year,
       0              AS pending_property_tax,
       0              AS pending_water_charges,
       pending_amount AS pending_waste_charges,
       village_id
FROM   dbo.House_wise_payment_vw
WHERE  payment_type = 3 AND ISNULL(payment_status, 0) = 0;
GO

/* ----------------------------------------------------------- the procedure */

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house_tax_receipt'));

IF @body IS NULL
BEGIN
    RAISERROR('sp_house_tax_receipt not found in this database.', 16, 1);
    RETURN;
END

IF CHARINDEX('Where @village_id=@village_id', @body) = 0
BEGIN
    PRINT 'Grid_pending_charges already scoped (or the text has changed) - procedure left alone.';
END
ELSE
BEGIN
    SET @body = REPLACE(
        @body,
        'Where @village_id=@village_id',
        'Where village_id = @village_id');
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_house_tax_receipt Grid_pending_charges now filters by village.';
END
GO

/*
 * Verification. For every house, what the grid reports as pending should match
 * what the pay dialog can actually list. Any row returned here is still
 * disagreeing.
 */
SELECT  p.house_id,
        p.owner_name,
        p.pending_property_tax,
        p.pending_water_charges,
        p.pending_waste_charges
FROM   (SELECT house_id, owner_name,
               SUM(ISNULL(pending_property_tax, 0))  AS pending_property_tax,
               SUM(ISNULL(pending_water_charges, 0)) AS pending_water_charges,
               SUM(ISNULL(pending_waste_charges, 0)) AS pending_waste_charges
        FROM   dbo.Housewise_pending_charges_vw
        GROUP BY house_id, owner_name) p
WHERE  (p.pending_property_tax > 0
        AND NOT EXISTS (SELECT 1 FROM dbo.House_wise_payment_vw v
                        WHERE v.house_id = p.house_id AND v.payment_type = 1
                          AND ISNULL(v.payment_status, 0) = 0))
   OR  (p.pending_water_charges > 0
        AND NOT EXISTS (SELECT 1 FROM dbo.House_wise_payment_vw v
                        WHERE v.house_id = p.house_id AND v.payment_type = 2
                          AND ISNULL(v.payment_status, 0) = 0))
   OR  (p.pending_waste_charges > 0
        AND NOT EXISTS (SELECT 1 FROM dbo.House_wise_payment_vw v
                        WHERE v.house_id = p.house_id AND v.payment_type = 3
                          AND ISNULL(v.payment_status, 0) = 0));
GO
