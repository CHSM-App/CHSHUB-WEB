/* ============================================================================
   FIX -- unitwise_main: UNION can silently swallow a genuine payment

   Open this file in SSMS and press F5.

   This view feeds the Owner wise Maintenance Bill Report
   (sp_dashboard, 'ownerwise_maintenance' branch). Nothing else uses it.

   WHAT IS WRONG
   -------------
   The view joins bills to payments with UNION -- not UNION ALL:

       SELECT ... FROM maintenance_cal INNER JOIN owner_search_vw ...
       UNION                                   <-- here
       SELECT ... FROM dbo.receipt_search_vw

   UNION removes exact duplicate rows. That is currently masking a different
   problem rather than solving one.

   receipt_search_vw deliberately repeats a receipt once per bill it settles:

       CROSS APPLY STRING_SPLIT(r.bill_details, ',') AS split_vals
       INNER JOIN dbo.maintenance_cal AS mc ON mc.bill_no = TRIM(split_vals.value)

   That is correct for the receipt search screen, which shows bill-level
   columns (Billno, bill_ref, amount, month_name). A receipt paying two bills
   genuinely is two rows there.

   unitwise_main only wants the payment, not the bills. It currently relies on
   UNION to collapse those repeats back down. Two problems follow:

     1) It works by accident. UNION means "drop identical rows", not "count
        each receipt once". Right now that produces the correct figure.

     2) It cannot tell a repeat apart from a real second payment. If one owner
        makes two separate payments on the same date, for the same amount, by
        the same pay_mode with the same reference, UNION merges them and one
        payment disappears from the report -- money silently missing.

   Today, receipt RCPT-2026-0069 (700.00, Cash) is listed twice by
   receipt_search_vw because it settles two bills, and UNION folds it back to
   one. The report figure is right; the mechanism is not.

   WHAT THIS CHANGES
   -----------------
   Takes each receipt once at the source, then switches to UNION ALL:

     * the payments branch selects DISTINCT receipt-level columns, so a
       receipt paying several bills contributes exactly one row
     * UNION ALL then keeps every remaining row, so two genuinely separate
       payments that happen to look alike both survive

   Both changes are needed together. UNION ALL on its own would count
   RCPT-2026-0069 twice and overstate collections by 700.00.

   VERIFIED AGAINST LIVE DATA BEFORE WRITING THIS
   ----------------------------------------------
     bills branch rows                786
     payments branch rows              43   (receipt-per-bill repeats)
     payments branch, de-duplicated    32
     786 + 32                       =  818  = the current view's row count

     Neither branch contains duplicate rows of its own, so UNION was only ever
     removing the receipt repeats -- nothing else.

     SUM(Payment)      now 31363.48   after 31363.48
     SUM(Maintenance)  now 851355.66  after 851355.66

   So this fix changes NO current figures. It stops a future duplicate-looking
   payment from being lost.

   NOT CHANGED HERE
   ----------------
   Two known issues in this area are deliberately left alone, because fixing
   them would move the numbers the report produces:

     1) sp_dashboard excludes the "To Date" day:
            WHERE m_date BETWEEN @date1 AND DATEADD(dd, -1, @date2)

     2) The bills branch groups by total_amount and also sums it, so
        SUM(total_amount) aggregates nothing:
            GROUP BY gen_date, name, o.owner_id, total_amount, o.build_id
        (checked: this produces no duplicate rows on the current data)
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   (1) CHECK -- run this BEFORE applying the fix

   Confirms the arithmetic above on your data. Expect:
     * bills + payments_deduped = current_view_rows
     * payment_now = payment_after  (the fix moves no money today)

   If payment_after is LARGER than payment_now, then UNION is currently
   losing real payments on your data -- review section (2) before applying.
   ------------------------------------------------------------------------ */
SELECT
    (SELECT COUNT(*) FROM unitwise_main)                                   AS current_view_rows,
    (SELECT COUNT(*) FROM dbo.receipt_search_vw)                           AS payment_rows_raw,
    (SELECT COUNT(*) FROM (SELECT DISTINCT receipt_id, [date], transaction_ref,
                                  pay_mode, unit, name, paid_amount, owner_id, build_id
                           FROM dbo.receipt_search_vw) z)                  AS payment_rows_deduped,
    (SELECT SUM(Payment) FROM unitwise_main)                               AS payment_now,
    (SELECT SUM(paid_amount) FROM (SELECT DISTINCT receipt_id, [date], transaction_ref,
                                          pay_mode, unit, name, paid_amount, owner_id, build_id
                                   FROM dbo.receipt_search_vw) z)          AS payment_after;
GO

/* ---------------------------------------------------------------------------
   (2) CHECK -- payments that UNION is currently merging away

   After de-duplicating each receipt, these rows are STILL identical to one
   another -- meaning they are separate payments that the current view loses.
   An empty result means the fix recovers nothing and only guards the future.
   ------------------------------------------------------------------------ */
SELECT   [date], owner_id, build_id, paid_amount, pay_mode, transaction_ref,
         COUNT(*) AS copies_currently_shown_as_one
FROM     (SELECT DISTINCT receipt_id, [date], transaction_ref, pay_mode,
                 unit, name, paid_amount, owner_id, build_id
          FROM   dbo.receipt_search_vw) z
GROUP BY [date], owner_id, build_id, paid_amount, pay_mode, transaction_ref
HAVING   COUNT(*) > 1
ORDER BY [date] DESC;
GO


/* ---------------------------------------------------------------------------
   (3) FIX -- apply once the figures above look right

   The bills branch is unchanged. Only the payments branch and the UNION
   keyword differ from the original.
   ------------------------------------------------------------------------ */
ALTER VIEW [dbo].[unitwise_main]
AS
SELECT CONVERT(varchar, gen_date, 106) AS m_date, gen_date, NULL AS ref, DateNAme(M,gen_date)+ ' Maintenance Created'  AS Particular, null AS Payment, CAST(isnull(sum(total_amount), 0) AS decimal(10, 2)) AS Maintenance, o.owner_id,
                  o.build_id
FROM     maintenance_cal INNER JOIN
                  owner_search_vw AS o ON maintenance_cal.flat_id = o.flat_id
GROUP BY gen_date, name, o.owner_id, total_amount, o.build_id
/* UNION ALL, not UNION: the payments below are already one row per receipt,
   so nothing needs collapsing -- and two separate payments that look alike
   must both survive. */
UNION ALL
SELECT CONVERT(varchar, r.date, 106) AS m_date, r.date, r.transaction_ref AS ref, 'BY ' + r.pay_mode + ': ' + r.unit + ' ' + r.name AS Particular, CAST(r.paid_amount AS decimal(10, 2)) AS Payment, null AS Maintenance, r.owner_id,
                  r.build_id
/* receipt_search_vw repeats a receipt once per bill it settles (its
   CROSS APPLY over bill_details). This view wants the payment, not the
   bills, so take each receipt once. receipt_id is carried into the DISTINCT
   so two different receipts that otherwise match are still two rows. */
FROM     (SELECT DISTINCT receipt_id, [date], transaction_ref, pay_mode,
                 unit, name, paid_amount, owner_id, build_id
          FROM   dbo.receipt_search_vw) AS r;
GO


/* ---------------------------------------------------------------------------
   (4) CHECK -- after applying

   Row count and totals should match what section (1) predicted.
   ------------------------------------------------------------------------ */
SELECT COUNT(*)        AS view_rows,
       SUM(Payment)     AS payment_total,
       SUM(Maintenance) AS maintenance_total
FROM   unitwise_main;
GO

PRINT 'unitwise_main fix complete.';
GO
