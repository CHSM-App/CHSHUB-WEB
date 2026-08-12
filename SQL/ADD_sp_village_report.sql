/*
 * Village billing reports.
 *
 * Analytics & Reports opened the balance sheet, which is a list of accounting
 * heads and their amounts — of little use to a panchayat clerk asking the four
 * questions this covers:
 *
 *   Collection   what was billed against what came in, per charge
 *   Defaulters   who owes, how much, and for how many periods
 *   Monthly      what was collected each month
 *   Ledger       one house's bills and payments, in order
 *
 * All four read house_tax_receipt, which is where bills are raised and
 * payments settled. Amount_paid holds the bill's amount whether or not it has
 * been settled; payment_status says which. So billed is every bill in range,
 * collected is the settled ones, and outstanding is the rest.
 *
 * One procedure rather than four: they share the same date filtering and the
 * same definition of "collected", and splitting them would be four places for
 * those to drift apart.
 *
 * @from / @to bound the period being reported on. Both optional — omitted
 * means everything on file, which is what a defaulters list usually wants.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_village_report', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_report;
GO

CREATE PROCEDURE dbo.sp_village_report
    @operation  NVARCHAR(50) = NULL,
    @village_id NVARCHAR(50) = NULL,
    @from       DATE         = NULL,
    @to         DATE         = NULL,
    @house_id   INT          = 0
AS
BEGIN
    SET NOCOUNT ON;

    /*
     * Reports are filtered on the period a bill is *for*, not the day it was
     * raised: eight months raised in one sitting all carry today's pay_date,
     * so filtering on that would put them all in one month.
     *
     * A yearly charge has no bill_month, so it falls on the first of its year.
     */
    DECLARE @fromY INT = YEAR(ISNULL(@from, '1900-01-01'));
    DECLARE @fromM INT = MONTH(ISNULL(@from, '1900-01-01'));
    DECLARE @toY   INT = YEAR(ISNULL(@to,   '2999-12-31'));
    DECLARE @toM   INT = MONTH(ISNULL(@to,  '2999-12-31'));

    /* ------------------------------------------------------- collection */

    IF @operation = 'Collection'
    BEGIN
        SELECT t.payment_type,
               t.payment_type_name,
               t.frequency,
               COUNT(*)                                                                   AS bills,
               ISNULL(SUM(r.Amount_paid), 0)                                              AS billed,
               ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN r.Amount_paid ELSE 0 END), 0) AS collected,
               ISNULL(SUM(CASE WHEN r.payment_status = 0 THEN r.Amount_paid ELSE 0 END), 0) AS outstanding,
               SUM(CASE WHEN r.payment_status = 1 THEN 1 ELSE 0 END)                       AS paid_bills,
               SUM(CASE WHEN r.payment_status = 0 THEN 1 ELSE 0 END)                       AS unpaid_bills
        FROM   dbo.house_tax_receipt AS r
        JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
        WHERE  r.village_id = @village_id
          AND  (r.bill_year * 100 + ISNULL(r.bill_month, 1)) >= (@fromY * 100 + @fromM)
          AND  (r.bill_year * 100 + ISNULL(r.bill_month, 1)) <= (@toY   * 100 + @toM)
        GROUP  BY t.payment_type, t.payment_type_name, t.frequency
        ORDER  BY t.payment_type;
    END

    /* ------------------------------------------------------- defaulters */

    IF @operation = 'Defaulters'
    BEGIN
        /*
         * Houses with something unpaid, worst first. periods counts the
         * distinct year/month combinations owed, which is what says whether a
         * household is one month behind or a year.
         */
        SELECT h.house_id,
               h.house_no,
               o.name       AS owner_name,
               o.pre_mob    AS contact,
               COUNT(*)                                     AS unpaid_bills,
               /*
                * Distinct periods owed — one month behind or a year. A yearly
                * charge has no bill_month, so it is counted as the year on its
                * own rather than being written "2025-00", which reads as a
                * month that does not exist.
                */
               COUNT(DISTINCT CAST(r.bill_year AS NVARCHAR(4))
                            + CASE WHEN r.bill_month IS NULL THEN ''
                                   ELSE '-' + RIGHT('0' + CAST(r.bill_month AS NVARCHAR(2)), 2) END) AS periods,
               ISNULL(SUM(r.Amount_paid), 0)                AS outstanding,
               MIN(CAST(r.bill_year AS NVARCHAR(4))
                 + CASE WHEN r.bill_month IS NULL THEN ''
                        ELSE '-' + RIGHT('0' + CAST(r.bill_month AS NVARCHAR(2)), 2) END)            AS oldest_period
        FROM   dbo.house_tax_receipt AS r
        JOIN   dbo.house AS h ON h.house_id = r.house_id
        LEFT   JOIN dbo.house_owner AS o ON o.house_id = h.house_id
        WHERE  r.village_id = @village_id
          AND  r.payment_status = 0
          AND  (r.bill_year * 100 + ISNULL(r.bill_month, 1)) >= (@fromY * 100 + @fromM)
          AND  (r.bill_year * 100 + ISNULL(r.bill_month, 1)) <= (@toY   * 100 + @toM)
        GROUP  BY h.house_id, h.house_no, o.name, o.pre_mob
        ORDER  BY outstanding DESC;
    END

    /* ---------------------------------------------------------- monthly */

    IF @operation = 'Monthly'
    BEGIN
        /*
         * Collected by the month the money came in — pay_date is right here,
         * because this asks when the office took the payment, not which period
         * it settled.
         */
        SELECT YEAR(r.pay_date)                    AS y,
               MONTH(r.pay_date)                   AS m,
               COUNT(*)                            AS receipts,
               ISNULL(SUM(r.Amount_paid), 0)       AS collected
        FROM   dbo.house_tax_receipt AS r
        WHERE  r.village_id = @village_id
          AND  r.payment_status = 1
          AND  r.pay_date IS NOT NULL
          AND  (@from IS NULL OR r.pay_date >= @from)
          AND  (@to   IS NULL OR r.pay_date <= @to)
        GROUP  BY YEAR(r.pay_date), MONTH(r.pay_date)
        ORDER  BY y, m;
    END

    /* ----------------------------------------------------------- ledger */

    IF @operation = 'Ledger'
    BEGIN
        -- One house's bills and payments, oldest period first.
        SELECT r.house_receipt_id,
               r.receipt_no,
               t.payment_type_name,
               t.frequency,
               r.bill_year,
               r.bill_month,
               r.Amount_paid                       AS amount,
               r.payment_status,
               CASE WHEN r.payment_status = 1 THEN 'Paid' ELSE 'Unpaid' END AS status,
               CASE WHEN r.payment_status = 1 THEN r.pay_date END           AS paid_on,
               m.pay_mode
        FROM   dbo.house_tax_receipt AS r
        JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
        LEFT   JOIN dbo.pay_mode AS m ON m.pay_id = r.pay_mode
        WHERE  r.village_id = @village_id
          AND  r.house_id = @house_id
        ORDER  BY r.bill_year, ISNULL(r.bill_month, 0), r.payment_type;

        -- The totals the ledger adds up to, so the screen does not re-add them.
        SELECT ISNULL(SUM(r.Amount_paid), 0)                                              AS billed,
               ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN r.Amount_paid ELSE 0 END), 0) AS paid,
               ISNULL(SUM(CASE WHEN r.payment_status = 0 THEN r.Amount_paid ELSE 0 END), 0) AS outstanding
        FROM   dbo.house_tax_receipt AS r
        WHERE  r.village_id = @village_id
          AND  r.house_id = @house_id;
    END
END
GO

PRINT 'sp_village_report created.';
GO

/* ---------------------------------------------------------- verification */

DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);

EXEC dbo.sp_village_report @operation = 'Collection', @village_id = @v;
EXEC dbo.sp_village_report @operation = 'Defaulters', @village_id = @v;
EXEC dbo.sp_village_report @operation = 'Monthly',    @village_id = @v;
GO
