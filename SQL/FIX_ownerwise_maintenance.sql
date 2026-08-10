/* ============================================================================
   FIX -- Owner wise Maintenance Bill Report: Opening Balance is wrong

   Open this file in SSMS and press F5.

   WHAT IS WRONG
   -------------
   sp_dashboard's 'ownerwise_maintenance' branch has three CTEs. Opening has
   no build_id filter, but Period and Tx do:

       Opening AS (... WHERE m_date BETWEEN ... AND owner_id = @owner_id)
                                              ^^^ no build_id

       Period  AS (... AND build_id = @build_id AND owner_id = @owner_id)
       Tx      AS (... AND build_id = @build_id AND owner_id = @owner_id)

   So the opening balance sums across ALL of the owner's buildings, while
   the period figures and the transaction list cover only the selected one.

   Effect, when an owner holds flats in more than one building:

     * Opening Balance    -- wrong (includes the other building's money)
     * Total Balance      -- wrong (Opening + Period, so it inherits the error)
     * Closing Balance    -- wrong (same reason)
     * Transactions       -- CORRECT (Tx does filter on build_id)

   The report therefore shows one building's transactions next to a balance
   covering every building, and the two do not reconcile.

   Owners who hold flats in a single building are unaffected: their figures
   are correct today and stay identical after this fix.

   WHAT THIS CHANGES
   -----------------
   Adds the same build_id filter to Opening that Period and Tx already have.
   Nothing else is touched.

   DELIBERATELY NOT CHANGED HERE
   -----------------------------
   Three further problems were found while checking this report. They are
   left alone for now, because fixing them changes the figures the report
   produces and those would no longer match previously printed copies:

     1) The "To Date" day is excluded:
            WHERE m_date BETWEEN @date1 AND DATEADD(dd, -1, @date2)
        Enter 31 March as the end date and 31 March's transactions are
        left out of the report.

     2) The unitwise_main view uses UNION, not UNION ALL. If one owner has
        two payments on the same date for the same amount by the same
        pay_mode, they collapse into a single row -- one payment vanishes
        from the report.

     3) In that view's first branch:
            GROUP BY gen_date, name, o.owner_id, total_amount, o.build_id
        total_amount is both grouped by and summed, so SUM(total_amount)
        aggregates nothing. Two bills on one date stay as two rows rather
        than being added together.

   Say the word if you want these fixed and they will go in a separate file.
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   (1) CHECK -- run this BEFORE applying the fix

   Lists the owners this fix can affect: those holding flats in more than one
   building. ONLY these owners' figures can change. If this returns no rows,
   applying the fix changes no numbers anywhere.
   ------------------------------------------------------------------------ */
SELECT   o.owner_id,
         MIN(o.name)                AS owner_name,
         COUNT(DISTINCT o.build_id) AS building_count,
         STRING_AGG(CONVERT(varchar(20), o.build_id), ', ')
             WITHIN GROUP (ORDER BY o.build_id) AS building_ids
FROM     dbo.owner_search_vw AS o
GROUP BY o.owner_id
HAVING   COUNT(DISTINCT o.build_id) > 1
ORDER BY building_count DESC, o.owner_id;
GO

/* ---------------------------------------------------------------------------
   (2) CHECK -- how much one owner's Opening Balance would move

   Take an owner_id from the list above together with one of their build_id
   values and plug them in here. "before_fix" is what the report returns
   today; "after_fix" is what it will return once the fix is applied. Equal
   values mean that owner/building pair is unaffected.

   Use the same "From Date" you would enter on the report for @check_date1.
   ------------------------------------------------------------------------ */
DECLARE @check_owner_id int          = 1;              -- <-- change
DECLARE @check_build_id int          = 1;              -- <-- change
DECLARE @check_date1    smalldatetime = '2025-04-01';  -- <-- change

SELECT
    'Opening Maintenance' AS figure,
    (SELECT ISNULL(SUM(Maintenance), 0) FROM unitwise_main
      WHERE m_date BETWEEN DATEADD(yy, DATEDIFF(yy, 0, @check_date1), 0)
                       AND DATEADD(dd, -1, @check_date1)
        AND owner_id = @check_owner_id)                        AS before_fix,
    (SELECT ISNULL(SUM(Maintenance), 0) FROM unitwise_main
      WHERE m_date BETWEEN DATEADD(yy, DATEDIFF(yy, 0, @check_date1), 0)
                       AND DATEADD(dd, -1, @check_date1)
        AND owner_id = @check_owner_id
        AND build_id = @check_build_id)                        AS after_fix
UNION ALL
SELECT
    'Opening Payment',
    (SELECT ISNULL(SUM(Payment), 0) FROM unitwise_main
      WHERE m_date BETWEEN DATEADD(yy, DATEDIFF(yy, 0, @check_date1), 0)
                       AND DATEADD(dd, -1, @check_date1)
        AND owner_id = @check_owner_id),
    (SELECT ISNULL(SUM(Payment), 0) FROM unitwise_main
      WHERE m_date BETWEEN DATEADD(yy, DATEDIFF(yy, 0, @check_date1), 0)
                       AND DATEADD(dd, -1, @check_date1)
        AND owner_id = @check_owner_id
        AND build_id = @check_build_id);
GO


/* ---------------------------------------------------------------------------
   (3) FIX -- run this once you have reviewed the figures above

   sp_dashboard is a large procedure and only its 'ownerwise_maintenance'
   branch needs changing, so rather than restating the whole thing this
   script:

     1) reads the procedure's current text
     2) inserts the build_id condition after Opening's owner_id line
     3) turns CREATE into ALTER and runs it back

   That leaves the procedure's other 40-odd branches untouched.

   The three-line search string below occurs exactly once in the procedure
   ("Period AS (" appears nowhere else), so the replacement cannot land in
   the wrong place. If the procedure has been edited since, the script
   reports that and changes nothing.
   ------------------------------------------------------------------------ */
DECLARE @sql      nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_dashboard'));
DECLARE @nl       nvarchar(2);
DECLARE @find     nvarchar(max);
DECLARE @replace  nvarchar(max);
DECLARE @c        int;

/* The procedure text normally comes back with CRLF line endings, but it may
   be LF only if it was ever saved through another editor -- so detect it. */
SET @nl = CASE WHEN CHARINDEX(NCHAR(13) + NCHAR(10), ISNULL(@sql, N'')) > 0
               THEN NCHAR(13) + NCHAR(10)
               ELSE NCHAR(10)
          END;

/* Opening's last condition, followed by the start of the Period CTE. Period
   and Tx each carry an "AND build_id" line after their owner_id condition,
   so neither of them matches this -- it can only be Opening. */
SET @find = N'AND owner_id = @owner_id' + @nl
          + N'),' + @nl
          + N'Period AS (';

SET @replace = N'AND owner_id = @owner_id' + @nl
             + N'      AND build_id = @build_id' + @nl
             + N'),' + @nl
             + N'Period AS (';

IF @sql IS NULL
    PRINT 'STOPPED: sp_dashboard not found.';
ELSE IF CHARINDEX(N'AND build_id = @build_id' + @nl + N'),' + @nl + N'Period AS (', @sql) > 0
    PRINT 'No change: the fix is already applied.';
ELSE IF CHARINDEX(@find, @sql) = 0
    PRINT 'STOPPED: Opening CTE not found -- the procedure has changed. Nothing was modified.';
ELSE
BEGIN
    SET @sql = REPLACE(@sql, @find, @replace);

    /* CREATE -> ALTER (first occurrence only). */
    SET @c = CHARINDEX(N'CREATE', @sql);
    SET @sql = STUFF(@sql, @c, 6, N'ALTER');

    EXEC sp_executesql @sql;
    PRINT 'Opening CTE now filters on build_id.';
END
GO

PRINT 'Ownerwise maintenance fix complete.';
GO
