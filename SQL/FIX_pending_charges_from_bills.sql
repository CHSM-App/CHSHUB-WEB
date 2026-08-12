/*
 * A bill that has been raised must show as outstanding.
 *
 * The bug
 * -------
 * Tax Payments shows nothing owing for houses that plainly owe. House 453 has
 * three unpaid bills — 8,750, 150 and 150 — and its row reads 0.00 across.
 * House 0 is the same.
 *
 * House_wise_payment_vw works out what is owed like this:
 *
 *     CASE WHEN payment_type = 1 THEN gharpatti_charges - Amount_paid
 *          WHEN payment_type = 2 THEN water_charges     - Amount_paid
 *          WHEN payment_type = 3 THEN waste_charges     - Amount_paid END
 *
 * That is the house's *current* charge minus the bill's amount — not what is
 * owed. A bill raised at the house's own rate therefore subtracts to zero and
 * disappears, which is exactly what a freshly generated bill looks like.
 *
 * The same expression names the three built-in charges one by one, so a charge
 * a village adds itself falls through every branch and yields NULL. House 0's
 * "other charges" bill is invisible for that reason.
 *
 * What is owed is much simpler than either:
 *
 *     an unpaid bill is owed in full; a paid one is not owed at all
 *
 * Amount_paid holds the bill's amount, and payment_status says whether it has
 * been settled — the two facts the calculation actually needs. Nothing has to
 * be looked up on dbo.house, and no charge has to be named.
 *
 * The fix
 * -------
 * House_wise_payment_vw:
 *   pending_amount becomes the bill's own amount when unpaid and 0 when paid.
 *   Every column it already returned is kept, in place, so anything selecting
 *   by name is unaffected.
 *
 * Housewise_pending_charges_vw:
 *   its three UNION arms hard-code payment_type 1, 2 and 3, so a fourth charge
 *   has no arm and never reaches the screen. Replaced with one pass that
 *   pivots on Village_payment_type, so every charge a village levies is
 *   included — the built-in three land in the columns they always did, and
 *   anything beyond them is summed into pending_other_charges.
 *
 * Existing rows are not touched: both are views, and the bills themselves are
 * left exactly as they are.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------- 1. what a bill leaves owing */

ALTER VIEW [dbo].[House_wise_payment_vw]
AS
SELECT        dbo.house_tax_receipt.receipt_no, dbo.house_tax_receipt.house_receipt_id, dbo.house_tax_receipt.house_id, dbo.house_tax_receipt.pay_date, MONTH(dbo.house_tax_receipt.pay_date) AS month_no, DATENAME(MONTH,
                         dbo.house_tax_receipt.pay_date) AS Month, YEAR(dbo.house_tax_receipt.pay_date) AS year, dbo.house_tax_receipt.pay_mode, dbo.house_tax_receipt.Amount_paid, dbo.house_tax_receipt.chqno,
                         dbo.house_tax_receipt.chqdate, dbo.house_tax_receipt.village_id, dbo.house.house_no, dbo.house_owner.name AS owner_name, dbo.house_tax_receipt.payment_type, dbo.Village_payment_type.payment_type_name,
                         dbo.house_tax_receipt.payment_status, CASE WHEN dbo.house_tax_receipt.payment_status = 0 THEN 'Not Paid' WHEN dbo.house_tax_receipt.payment_status = 1 THEN 'Paid' END AS pay_status,
                         /*
                          * An unpaid bill is owed in full; a paid one is not
                          * owed at all. This used to subtract the bill from the
                          * house's current charge, which cancelled to zero for
                          * any bill raised at that charge, and returned NULL for
                          * a charge the CASE did not name.
                          */
                         CASE WHEN dbo.house_tax_receipt.payment_status = 0
                              THEN ISNULL(dbo.house_tax_receipt.Amount_paid, 0)
                              ELSE 0 END AS pending_amount,
                         dbo.house.gharpatti_charges, dbo.house.water_charges, dbo.house.waste_charges,
                         dbo.house_owner.pre_mob
FROM            dbo.house_tax_receipt INNER JOIN
                         dbo.house ON dbo.house_tax_receipt.house_id = dbo.house.house_id INNER JOIN
                         dbo.house_owner ON dbo.house.house_id = dbo.house_owner.house_id INNER JOIN
                         dbo.Village_payment_type ON dbo.house_tax_receipt.payment_type = dbo.Village_payment_type.payment_type;
GO

PRINT 'House_wise_payment_vw: an unpaid bill is now owed in full.';
GO

/* --------------------------------- 2. every charge, not just the first three */

ALTER VIEW [dbo].[Housewise_pending_charges_vw]
AS
/*
 * One pass rather than three UNIONed arms. The old shape had an arm per
 * payment_type, so charge 4 and beyond had nowhere to go; this keeps the three
 * named columns the screens already read and collects everything else into
 * pending_other_charges.
 */
SELECT house_id, house_no, owner_name, pre_mob, Month, year, village_id,
       SUM(CASE WHEN payment_type = 1 THEN pending_amount ELSE 0 END) AS pending_property_tax,
       SUM(CASE WHEN payment_type = 2 THEN pending_amount ELSE 0 END) AS pending_water_charges,
       SUM(CASE WHEN payment_type = 3 THEN pending_amount ELSE 0 END) AS pending_waste_charges,
       SUM(CASE WHEN payment_type > 3 THEN pending_amount ELSE 0 END) AS pending_other_charges
FROM   dbo.House_wise_payment_vw
GROUP  BY house_id, house_no, owner_name, pre_mob, Month, year, village_id;
GO

PRINT 'Housewise_pending_charges_vw: charges a village added are included.';
GO

/* ------------------------------- 3. carry the new column through the SP */

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house_tax_receipt'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house_tax_receipt not found.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%pending_other_charges%'
BEGIN
    PRINT 'sp_house_tax_receipt: already returns pending_other_charges.';
    SET @stop = 1;
END

DECLARE @old NVARCHAR(MAX) =
    N'SUM(ISNULL(pending_waste_charges, 0)) as pending_waste_charges,pre_mob';
DECLARE @new NVARCHAR(MAX) =
    N'SUM(ISNULL(pending_waste_charges, 0)) as pending_waste_charges, SUM(ISNULL(pending_other_charges, 0)) AS pending_other_charges,pre_mob';

IF @stop = 0 AND CHARINDEX(@old, @body) = 0
BEGIN
    RAISERROR('Could not locate the Grid_pending_charges column list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0
BEGIN
    SET @body = REPLACE(@body, @old, @new);
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_house_tax_receipt: Grid_pending_charges now returns other charges too.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * Every house with an unpaid bill should now show what it owes. Houses 453 and
 * 0 read 0.00 across before this, despite having three unpaid bills each.
 */
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);

EXEC dbo.sp_house_tax_receipt @operation = 'Grid_pending_charges', @village_id = @v;

-- Cross-check: the same figure straight from the bills.
SELECT h.house_no,
       SUM(CASE WHEN r.payment_status = 0 THEN r.Amount_paid ELSE 0 END) AS owed_per_bills
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.house AS h ON h.house_id = r.house_id
WHERE  h.village_id = @v
GROUP  BY h.house_no
ORDER  BY h.house_no;
GO
