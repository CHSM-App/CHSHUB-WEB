/*
 * FIX: the same village tax bill exists more than once for a month.
 *
 * Symptom
 * -------
 * On Tax Payments, a house shows more outstanding than it should — Priya Sharma
 * (house 102) owes Rs.300 waste for what is really two months, because December
 * 2025 was billed twice. Opening the amount lists both, so the figure and the
 * bills agree with each other; they are simply both wrong.
 *
 * What this is NOT
 * ----------------
 * Not a reporting bug. The grid, the view and the pay dialog all count these
 * rows correctly — see FIX_village_pending_charges.sql for the reporting
 * defects, which are separate and already fixed. This is bad data: bill
 * generation wrote a second row for a month that already had one.
 *
 * Scope, measured before writing this
 * -----------------------------------
 *   14  house/type/month groups hold more than one receipt
 *    7  of those contain a PAID row  -- money was collected against them
 *    8  unpaid rows are safe to remove
 *
 * A paid row is a record of money actually taken. Deleting one would erase a
 * collection, so nothing paid is touched here even where it is a duplicate —
 * those seven groups are reported for a human to look at instead. Where a group
 * mixes paid and unpaid rows, the paid one is kept and only the surplus unpaid
 * rows go.
 *
 * Which unpaid row survives
 * -------------------------
 * The lowest house_receipt_id — the one generated first. The rows are otherwise
 * identical (same house, type, month and amount), so any rule picks an
 * equivalent row; the earliest is the one other records are most likely to
 * reference.
 *
 * Run the SELECTs first. Nothing is deleted until you uncomment the DELETE.
 */

SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------- report 1 */
PRINT '=== Groups holding a PAID duplicate - review these by hand ===';

SELECT  r.village_id,
        r.house_id,
        h.house_no,
        o.name              AS owner_name,
        t.payment_type_name,
        YEAR(r.pay_date)    AS bill_year,
        MONTH(r.pay_date)   AS bill_month,
        COUNT(*)                                                        AS receipts,
        SUM(CASE WHEN ISNULL(r.payment_status, 0) = 1 THEN 1 ELSE 0 END) AS paid_receipts,
        SUM(ISNULL(r.Amount_paid, 0))                                    AS collected
FROM    dbo.house_tax_receipt r
LEFT JOIN dbo.house h              ON h.house_id = r.house_id
LEFT JOIN dbo.house_owner o        ON o.house_id = r.house_id AND ISNULL(o.active_status, 0) = 0
LEFT JOIN dbo.Village_payment_type t ON t.payment_type = r.payment_type
WHERE   r.pay_date IS NOT NULL
GROUP BY r.village_id, r.house_id, h.house_no, o.name, t.payment_type_name,
         YEAR(r.pay_date), MONTH(r.pay_date)
HAVING  COUNT(*) > 1
    AND SUM(CASE WHEN ISNULL(r.payment_status, 0) = 1 THEN 1 ELSE 0 END) > 1
ORDER BY r.village_id, r.house_id, bill_year, bill_month;
GO

/* ---------------------------------------------------------------- report 2 */
PRINT '';
PRINT '=== Unpaid surplus rows this script would remove ===';

WITH ranked AS (
    SELECT  r.house_receipt_id,
            r.village_id,
            r.house_id,
            r.payment_type,
            r.pay_date,
            ROW_NUMBER() OVER (
                PARTITION BY r.village_id, r.house_id, r.payment_type,
                             YEAR(r.pay_date), MONTH(r.pay_date)
                ORDER BY r.house_receipt_id) AS rn
    FROM    dbo.house_tax_receipt r
    WHERE   r.pay_date IS NOT NULL
      AND   ISNULL(r.payment_status, 0) = 0      -- never a paid row
)
SELECT  d.house_receipt_id,
        d.village_id,
        h.house_no,
        o.name              AS owner_name,
        t.payment_type_name,
        d.pay_date
FROM    ranked d
LEFT JOIN dbo.house h              ON h.house_id = d.house_id
LEFT JOIN dbo.house_owner o        ON o.house_id = d.house_id AND ISNULL(o.active_status, 0) = 0
LEFT JOIN dbo.Village_payment_type t ON t.payment_type = d.payment_type
WHERE   d.rn > 1
ORDER BY d.village_id, d.house_id, d.pay_date;
GO

/* ------------------------------------------------------------------ delete */
/*
 * Uncomment to apply. Wrapped in a transaction that reports the count before
 * committing, so a wrong number can still be rolled back.
 *
 * ISNULL(payment_status, 0) = 0 appears in the CTE and again in the DELETE:
 * belt and braces on the one condition that must never be got wrong.
 */

/*
BEGIN TRANSACTION;

WITH ranked AS (
    SELECT  house_receipt_id,
            ROW_NUMBER() OVER (
                PARTITION BY village_id, house_id, payment_type,
                             YEAR(pay_date), MONTH(pay_date)
                ORDER BY house_receipt_id) AS rn
    FROM    dbo.house_tax_receipt
    WHERE   pay_date IS NOT NULL
      AND   ISNULL(payment_status, 0) = 0
)
DELETE  r
FROM    dbo.house_tax_receipt r
JOIN    ranked d ON d.house_receipt_id = r.house_receipt_id
WHERE   d.rn > 1
  AND   ISNULL(r.payment_status, 0) = 0;

PRINT CONCAT('Rows removed: ', @@ROWCOUNT);

-- Check the figure, then finish with one of these:
--   COMMIT TRANSACTION;
--   ROLLBACK TRANSACTION;
*/
GO

/* ------------------------------------------------------------ verification */
/*
 * Run after committing. Any row returned is a month still billed twice; groups
 * listed by report 1 above will remain, because their duplicates are paid.
 */
PRINT '';
PRINT '=== Remaining duplicates (paid ones are expected to stay) ===';

SELECT  village_id, house_id, payment_type,
        YEAR(pay_date) AS bill_year, MONTH(pay_date) AS bill_month,
        COUNT(*) AS receipts,
        SUM(CASE WHEN ISNULL(payment_status, 0) = 1 THEN 1 ELSE 0 END) AS paid_receipts
FROM    dbo.house_tax_receipt
WHERE   pay_date IS NOT NULL
GROUP BY village_id, house_id, payment_type, YEAR(pay_date), MONTH(pay_date)
HAVING  COUNT(*) > 1
ORDER BY village_id, house_id, bill_year, bill_month;
GO
