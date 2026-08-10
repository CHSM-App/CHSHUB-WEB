/* ============================================================================
   FIX -- Owner wise Maintenance Bill Report: the "To Date" day is left out

   Open this file in SSMS and press F5.

   ALREADY APPLIED on 2026-08-10. This file documents the change and can be
   re-run safely -- section (3) detects that the fix is present and does
   nothing. Re-running it is how you would apply the same change to another
   environment (test, staging, a second server).

   WHAT WAS WRONG
   --------------
   sp_dashboard's 'ownerwise_maintenance' branch bounded the Period and Tx
   CTEs like this:

       WHERE m_date BETWEEN @date1 AND DATEADD(dd, -1, @date2)
                                       ^^^^^^^^^^^^^^^^^^^^^^^

   @date2 is the "To Date" the user types on the report. Subtracting a day
   means the report stops the day BEFORE the date they asked for, so anything
   dated on the end date itself never appeared.

   To see it, the user had to enter one day LATER than the period they
   actually wanted -- which nobody would guess.

   MEASURED ON LIVE DATA (owner 49, building 18, from 2025-04-01):

       To Date      before fix                  after fix
       2026-08-06   20 tx, 5906.05              20 tx, 5906.05   (no data on 06)
       2026-08-07   20 tx, 5906.05   <-- lost   21 tx, 5972.72   (66.67 on 07)
       2026-08-08   21 tx, 5972.72              21 tx, 5972.72   (no data on 08)

   The 66.67 dated 07 Aug 2026 was dropped whenever the user asked for a
   period ending 07 Aug. Society-wide, 07 Aug carries 46 ledger rows and
   01 Aug carries 46 -- every report ending on a day that has data lost that
   day's rows.

   Note this only bites when the end date is a day that actually has data.
   Bills are generated on the 1st of each month, so month-end dates
   (31 Mar, 30 Jun, 31 Jul) were unaffected -- which is why the problem went
   unnoticed.

   WHAT THIS CHANGES
   -----------------
       WHERE m_date BETWEEN @date1 AND @date2

   Applied to BOTH the Period CTE and the Tx CTE. They must agree: the
   balance figures and the transaction list have to cover the same span, or
   the Total row stops reconciling against the rows above it.

   The Opening CTE is deliberately NOT changed. It reads:

       WHERE m_date BETWEEN DATEADD(yy, DATEDIFF(yy, 0, @date1), 0)
                        AND DATEADD(dd, -1, @date1)

   That -1 is on @date1, not @date2, and it is correct: the opening balance
   covers everything up to the day BEFORE the period starts, so the From Date
   itself must be excluded there.

   VERIFIED AFTER APPLYING
   -----------------------
   For all three end dates above, Total = Opening + listed transactions, and
   Closing is consistent with Total.

   EFFECT ON FIGURES
   -----------------
   Reports ending on a date that carries data now include that date, so their
   totals go UP. Previously printed copies will not match a fresh run. The
   new figures are the correct ones.

   STILL NOT CHANGED
   -----------------
   One known cosmetic issue remains in unitwise_main's bills branch:

       GROUP BY gen_date, name, o.owner_id, total_amount, o.build_id

   total_amount is both grouped by and summed, so SUM(total_amount) does not
   actually aggregate. Checked against live data: no owner currently has two
   bills on the same date, so this produces no visible error today.
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   (1) CHECK -- what the end date is worth

   Set @d2 to a date that HAS data (a report end date you would really use).
   The two rows show the figures before and after the fix. Picking a date
   with no activity returns two identical rows, which proves nothing -- use
   section (2) to find a date that does.
   ------------------------------------------------------------------------ */
DECLARE @o  int           = 49;             -- owner_id
DECLARE @b  int           = 18;             -- build_id
DECLARE @d1 smalldatetime = '2025-04-01';   -- From Date
DECLARE @d2 smalldatetime = '2026-08-07';   -- To Date

SELECT 'before fix (To Date excluded)' AS variant,
       COUNT(*)                        AS transactions,
       ISNULL(SUM(Maintenance), 0)     AS maintenance,
       ISNULL(SUM(Payment), 0)         AS payment
FROM   unitwise_main
WHERE  m_date BETWEEN @d1 AND DATEADD(dd, -1, @d2)
  AND  build_id = @b AND owner_id = @o
UNION ALL
SELECT 'after fix (To Date included)',
       COUNT(*), ISNULL(SUM(Maintenance), 0), ISNULL(SUM(Payment), 0)
FROM   unitwise_main
WHERE  m_date BETWEEN @d1 AND @d2
  AND  build_id = @b AND owner_id = @o;
GO

/* ---------------------------------------------------------------------------
   (2) CHECK -- which dates carry data

   Any date listed here would have lost its rows when used as a To Date.
   ------------------------------------------------------------------------ */
SELECT TOP 20
       CAST(gen_date AS date)      AS activity_date,
       COUNT(*)                    AS rows_on_that_date,
       ISNULL(SUM(Maintenance), 0) AS maintenance,
       ISNULL(SUM(Payment), 0)     AS payment
FROM   unitwise_main
GROUP BY CAST(gen_date AS date)
ORDER BY CAST(gen_date AS date) DESC;
GO


/* ---------------------------------------------------------------------------
   (3) FIX

   sp_dashboard is a large procedure and only this one branch needs changing,
   so rather than restating the whole thing the script reads the procedure's
   current text, swaps the bound, and runs it back as ALTER. Every other
   branch is left untouched.

   The search text appears exactly twice -- once in Period, once in Tx -- and
   REPLACE updates both, which is what we want. Opening uses @date1 in its
   DATEADD, so it does not match and is left alone.

   Safe to re-run: if the fix is already in place it reports that and makes
   no change.
   ------------------------------------------------------------------------ */
DECLARE @sql nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard'));
DECLARE @c   int;

IF @sql IS NULL
    PRINT 'STOPPED: sp_dashboard not found.';
ELSE IF CHARINDEX(N'BETWEEN @date1 AND DATEADD(dd, -1, @date2)', @sql) = 0
    PRINT 'No change: the fix is already applied (or the procedure has been edited).';
ELSE
BEGIN
    SET @sql = REPLACE(@sql,
        N'BETWEEN @date1 AND DATEADD(dd, -1, @date2)',
        N'BETWEEN @date1 AND @date2');

    /* CREATE -> ALTER (first occurrence only). */
    SET @c = CHARINDEX(N'CREATE', @sql);
    SET @sql = STUFF(@sql, @c, 6, N'ALTER');

    EXEC sp_executesql @sql;
    PRINT 'The To Date is now included in the report.';
END
GO


/* ---------------------------------------------------------------------------
   (4) CHECK -- confirm what the procedure now contains

   Expect exactly three rows:
     ... DATEADD(dd, -1, @date1)    <- Opening, correct, must stay
     ... BETWEEN @date1 AND @date2  <- Period, fixed
     ... BETWEEN @date1 AND @date2  <- Tx, fixed

   If any line still reads DATEADD(dd, -1, @date2), the fix did not apply.
   ------------------------------------------------------------------------ */
SELECT value AS procedure_line
FROM   STRING_SPLIT(
           SUBSTRING(
               OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard')),
               CHARINDEX(N'''ownerwise_maintenance''', OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard'))),
               CHARINDEX(N'ORDER BY seq', OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard')))
             - CHARINDEX(N'''ownerwise_maintenance''', OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard')))),
           CHAR(10))
WHERE  value LIKE '%BETWEEN%' OR value LIKE '%DATEADD%';
GO

PRINT 'Ownerwise end-date fix complete.';
GO
