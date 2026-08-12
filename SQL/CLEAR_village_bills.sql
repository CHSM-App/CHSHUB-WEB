/*
 * Clear every village tax bill, so generation can start from a clean sheet.
 *
 * Run at the user's explicit instruction: the existing rows are test data from
 * the old generation code and cannot be reconciled. They are removed and the
 * periods re-raised from the Generate Bills screen.
 *
 * WHAT IS BEING REMOVED
 * ---------------------
 * All 112 rows of dbo.house_tax_receipt, including the 14 marked paid
 * (12,150 recorded as collected). The user has confirmed these are not real
 * receipts. Several of them corroborate that: receipt_no 1008 appears twice,
 * and some rows are marked paid with Amount_paid = 0.
 *
 * Why they could not be salvaged:
 *   - 69 of them carry Amount_paid = 0, so they are unpaid bills that ask for
 *     nothing. The old bill_gen wrote 0 into the amount column.
 *   - receipt numbers repeat, so a receipt does not identify a bill.
 *   - 12 house/charge/period combinations appear twice, from generation being
 *     run more than once with no guard against it.
 *
 * BACKUP FIRST
 * ------------
 * Everything is copied to house_tax_receipt_bak_20260812 before anything is
 * deleted. 112 rows costs nothing to keep, and restoring is a single INSERT if
 * this turns out to have been the wrong call. The backup is NOT dropped by
 * this script — delete it by hand once you are satisfied, or leave it.
 *
 * WHAT IS NOT TOUCHED
 * -------------------
 * house_charge, Village_payment_type, village_setting, the houses and their
 * owners. Only the raised bills go. Everything needed to raise them again is
 * left exactly as it is, so the Generate Bills screen can rebuild any period.
 *
 * AFTER RUNNING
 * -------------
 * Raise each period you want, oldest first, from Generate Bills. Yearly
 * charges are raised once per year whichever month is chosen, so pick the
 * month for the monthly ones and let property tax follow.
 *
 * Safe to re-run — the second run finds nothing to delete and says so.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------------------------- 1. backup */

IF OBJECT_ID('dbo.house_tax_receipt_bak_20260812', 'U') IS NULL
BEGIN
    SELECT * INTO dbo.house_tax_receipt_bak_20260812 FROM dbo.house_tax_receipt;
    PRINT 'Backup taken: house_tax_receipt_bak_20260812.';
END
ELSE
    PRINT 'Backup house_tax_receipt_bak_20260812 already exists - left as it is.';
GO

-- What is about to go, one last time.
SELECT COUNT(*) AS bills_to_delete,
       SUM(CASE WHEN payment_status = 1 THEN 1 ELSE 0 END) AS marked_paid,
       ISNULL(SUM(CASE WHEN payment_status = 1 THEN Amount_paid ELSE 0 END), 0) AS recorded_as_collected
FROM   dbo.house_tax_receipt;
GO

/* ------------------------------------------------------------- 2. clear */

/*
 * DELETE, not TRUNCATE: house_receipt_id is an IDENTITY and TRUNCATE would
 * reset it, so new bills would reuse ids the backup still refers to. Keeping
 * the counter climbing means a restored row and a new row can never collide.
 */
DELETE FROM dbo.house_tax_receipt;

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' bill(s) deleted.';
GO

/* ---------------------------------------------------------- verification */

SELECT (SELECT COUNT(*) FROM dbo.house_tax_receipt)                    AS bills_now,
       (SELECT COUNT(*) FROM dbo.house_tax_receipt_bak_20260812)       AS in_backup;

-- Nothing outstanding, because nothing has been billed.
SELECT COUNT(*) AS rows_on_the_pending_screen
FROM   dbo.Housewise_pending_charges_vw;

/*
 * What the charges would raise for a period, ready to go. The August figures
 * come from house_charge, which this script did not touch.
 */
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC dbo.sp_village_bill_run @operation = 'Preview', @village_id = @v,
                             @bill_year = 2026, @bill_month = 8;
GO

/*
 * To undo, before any new bills are raised:
 *
 *   SET IDENTITY_INSERT dbo.house_tax_receipt ON;
 *   INSERT INTO dbo.house_tax_receipt
 *       (house_receipt_id, receipt_no, village_id, house_id, payment_type,
 *        pay_date, pay_mode, Amount_paid, payment_status, chqdate, chqno,
 *        Transation_ref, remark, bill_month, bill_year)
 *   SELECT house_receipt_id, receipt_no, village_id, house_id, payment_type,
 *          pay_date, pay_mode, Amount_paid, payment_status, chqdate, chqno,
 *          Transation_ref, remark, bill_month, bill_year
 *   FROM   dbo.house_tax_receipt_bak_20260812;
 *   SET IDENTITY_INSERT dbo.house_tax_receipt OFF;
 */
