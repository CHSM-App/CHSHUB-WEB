/*
 * Show a bill's own period, not the day it was raised.
 *
 * The bug
 * -------
 * The pay dialog lists eight water bills for one house and labels every one of
 * them "August 2026". They are in fact January through August — the stored
 * rows are correct, with bill_month 1 to 8. The screen is reading the wrong
 * thing.
 *
 * House_wise_payment_vw derives its Month and year from pay_date:
 *
 *     MONTH(pay_date) AS month_no, DATENAME(MONTH, pay_date) AS Month,
 *     YEAR(pay_date)  AS year
 *
 * pay_date is the day the row was written. Raising January to August in one
 * sitting stamps every one of them with today, so all eight read August — the
 * day of the run rather than the month being billed.
 *
 * That was defensible before bills carried a period at all. They do now:
 * house_tax_receipt.bill_year and bill_month say which period each bill
 * covers, and those are the columns that answer "what is this bill for".
 *
 * The fix
 * -------
 * Month, month_no and year come from bill_month / bill_year, falling back to
 * pay_date for any older row that predates those columns. pay_date is still
 * returned unchanged, so anything that genuinely wants the raising date has
 * it.
 *
 * A yearly charge has no bill_month — it belongs to the year, not a month — so
 * its Month reads as the year alone rather than inventing one.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

ALTER VIEW [dbo].[House_wise_payment_vw]
AS
SELECT        dbo.house_tax_receipt.receipt_no, dbo.house_tax_receipt.house_receipt_id, dbo.house_tax_receipt.house_id, dbo.house_tax_receipt.pay_date,
                         /*
                          * The period the bill covers. Was MONTH(pay_date) —
                          * the day the row was written — so a run that raised
                          * eight months in one go labelled all eight with the
                          * day of the run.
                          */
                         ISNULL(dbo.house_tax_receipt.bill_month, MONTH(dbo.house_tax_receipt.pay_date)) AS month_no,
                         CASE
                           WHEN dbo.house_tax_receipt.bill_month IS NOT NULL
                             THEN DATENAME(MONTH, DATEFROMPARTS(2000, dbo.house_tax_receipt.bill_month, 1))
                           -- A yearly charge covers the year; naming a month
                           -- against it would misdescribe it.
                           WHEN dbo.house_tax_receipt.bill_year IS NOT NULL THEN ''
                           ELSE DATENAME(MONTH, dbo.house_tax_receipt.pay_date)
                         END AS Month,
                         ISNULL(dbo.house_tax_receipt.bill_year, YEAR(dbo.house_tax_receipt.pay_date)) AS year,
                         dbo.house_tax_receipt.pay_mode, dbo.house_tax_receipt.Amount_paid, dbo.house_tax_receipt.chqno,
                         dbo.house_tax_receipt.chqdate, dbo.house_tax_receipt.village_id, dbo.house.house_no, dbo.house_owner.name AS owner_name, dbo.house_tax_receipt.payment_type, dbo.Village_payment_type.payment_type_name,
                         dbo.house_tax_receipt.payment_status, CASE WHEN dbo.house_tax_receipt.payment_status = 0 THEN 'Not Paid' WHEN dbo.house_tax_receipt.payment_status = 1 THEN 'Paid' END AS pay_status,
                         -- An unpaid bill is owed in full; a paid one is not.
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

PRINT 'House_wise_payment_vw: Month and year now describe the bill''s period.';
GO

/* ---------------------------------------------------------- verification */

/*
 * One house's water bills. These were raised in a single sitting, so pay_date
 * is the same on all of them — the period must not be.
 */
SELECT TOP 12 house_no, payment_type_name, Month, year, pay_date, pending_amount
FROM   dbo.House_wise_payment_vw
WHERE  house_no = (SELECT TOP 1 house_no FROM dbo.house WHERE village_id IS NOT NULL ORDER BY house_id)
ORDER  BY year, month_no, payment_type;
GO
