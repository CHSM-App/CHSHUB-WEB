/*
 * Automatic village bill generation, on the same footing as the society side.
 *
 * How the society side does it
 * ----------------------------
 * app.js runs node-cron at 10:00 daily and calls gen_bill with no arguments.
 * The procedure decides for itself which societies are due: it reads each
 * one's auto_bill_generation flag and its bill-generation day, and skips any
 * that have already been billed this month.
 *
 * There is no SQL Server Agent job involved, which matters here — the backend
 * is going onto Plesk, where Agent is generally unavailable. node-cron runs
 * inside the Node process, so it needs nothing from the database host.
 *
 * What this adds
 * --------------
 * sp_village_bill_run gains an 'Auto' operation with the same shape: called
 * with no village and no period, it works out both.
 *
 *   For each village where village_setting.auto_bill_generation is on and
 *   bill_gen_day matches today:
 *     - raise the current month's monthly charges
 *     - raise the current year's yearly charges, but only in the month named
 *       by property_tax_month, so a yearly charge is not attempted every month
 *
 * Everything else is unchanged. Auto and manual both go through the same
 * Generate path, so the bills are identical and both land in
 * house_tax_receipt — which is what Tax Payments reads. There is no separate
 * store and no second code path to keep in step.
 *
 * Re-running on the same day raises nothing: the existing guard skips any
 * house and charge already billed for the period.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_village_bill_run', 'P') IS NULL
BEGIN
    RAISERROR('sp_village_bill_run not found - run ADD_sp_village_bill_run.sql first.', 16, 1);
END
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_village_bill_run'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_village_bill_run not found.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%auto_bill_run%'
BEGIN
    PRINT 'sp_village_bill_run: Auto already present - no change made.';
    SET @stop = 1;
END

/*
 * The Auto branch is inserted ahead of the operation check, and returns before
 * reaching it. It loops the due villages and calls this same procedure's
 * Generate path for each, so nothing about how a bill is raised is duplicated.
 */
DECLARE @anchor NVARCHAR(MAX) = N'IF @operation NOT IN (''Preview'', ''Generate'')';

DECLARE @auto NVARCHAR(MAX) = N'/* auto_bill_run — called with no arguments by the daily cron in app.js,
       the same way gen_bill is on the society side. */
    IF @operation = ''Auto''
    BEGIN
        DECLARE @today DATE = CAST(GETDATE() AS DATE);
        DECLARE @day   INT  = DAY(@today);
        DECLARE @month INT  = MONTH(@today);
        DECLARE @year  INT  = YEAR(@today);

        DECLARE @vid NVARCHAR(50), @pt_month INT;

        DECLARE village_auto CURSOR LOCAL FAST_FORWARD FOR
            SELECT s.village_id, s.property_tax_month
            FROM   dbo.village_setting AS s
            WHERE  s.auto_bill_generation = 1
              AND  s.bill_gen_day = @day
              AND  ISNULL(s.active_status, 0) = 0;

        OPEN village_auto;
        FETCH NEXT FROM village_auto INTO @vid, @pt_month;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            /*
             * Generate raises the month''s monthly charges and, because a
             * yearly charge is compared against the start of the year, would
             * also raise property tax whichever month this ran in. Restricting
             * the yearly charges to their own month is what property_tax_month
             * is for, so outside it they are held back and picked up when that
             * month comes round.
             */
            IF @month = ISNULL(@pt_month, 4)
            BEGIN
                EXEC dbo.sp_village_bill_run
                     @operation  = ''Generate'',
                     @village_id = @vid,
                     @bill_year  = @year,
                     @bill_month = @month;
            END
            ELSE
            BEGIN
                EXEC dbo.sp_village_bill_run
                     @operation      = ''Generate'',
                     @village_id     = @vid,
                     @bill_year      = @year,
                     @bill_month     = @month,
                     @monthly_only   = 1;
            END

            FETCH NEXT FROM village_auto INTO @vid, @pt_month;
        END

        CLOSE village_auto;
        DEALLOCATE village_auto;
        RETURN;
    END

    IF @operation NOT IN (''Preview'', ''Generate'')';

IF @stop = 0 AND CHARINDEX(@anchor, @body) = 0
BEGIN
    RAISERROR('Could not locate the operation check - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @anchor, @auto);

/*
 * @monthly_only holds back the yearly charges, so a monthly run in, say, June
 * does not raise property tax eleven months before its own month comes round.
 */
DECLARE @oldParams NVARCHAR(MAX) = N'@audt_user   INT          = 0';
DECLARE @newParams NVARCHAR(MAX) = N'@audt_user   INT          = 0,
    @monthly_only BIT        = 0';

IF @stop = 0 AND CHARINDEX(@oldParams, @body) = 0
BEGIN
    RAISERROR('Could not locate the parameter list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldParams, @newParams);

-- Applied to the WHERE that selects what is due.
DECLARE @oldWhere NVARCHAR(MAX) = N'AND  ISNULL(c.amount, 0) > 0';
DECLARE @newWhere NVARCHAR(MAX) = N'AND  ISNULL(c.amount, 0) > 0
      AND  (@monthly_only = 0 OR t.frequency = ''M'')';

IF @stop = 0 AND CHARINDEX(@oldWhere, @body) = 0
BEGIN
    RAISERROR('Could not locate the selection WHERE - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldWhere, @newWhere);

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_village_bill_run: Auto added.';
END
GO

/* ---------------------------------------------------------- verification */

-- Which villages the daily run would act on today, and why.
SELECT s.village_id,
       s.auto_bill_generation,
       s.bill_gen_day,
       DAY(GETDATE())        AS today,
       s.property_tax_month,
       MONTH(GETDATE())      AS this_month,
       CASE WHEN s.auto_bill_generation = 1 AND s.bill_gen_day = DAY(GETDATE())
            THEN 'would run today' ELSE 'not today' END AS status
FROM   dbo.village_setting AS s
ORDER  BY s.village_id;
GO
