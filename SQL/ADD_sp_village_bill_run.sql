/*
 * Raising bills from house_charge.
 *
 * Replaces the three propety_tax_bill_gen / water_bill_gen / waste_bill_gen
 * branches, which cannot express what a gram panchayat actually does:
 *
 *   - they read dbo.house's three fixed columns, so a charge a village adds
 *     itself is invisible to them
 *   - they bill every house for every charge, so a house with no tap
 *     connection gets a water bill
 *   - they carry no period, so "has December been billed?" is unanswerable and
 *     a second run bills the same month again
 *   - they restart receipt numbering at 1001 on every run, so numbers repeat
 *
 * This works from house_charge instead: one row per house per charge, with the
 * amount, whether it applies, and the period it starts from. Adding a charge
 * needs no change here.
 *
 *
 * PREVIEW FIRST
 * -------------
 * @operation = 'Preview' returns exactly what 'Generate' would write, and
 * writes nothing. The screen shows it and the user confirms before any bill
 * exists. Raising a bill is not something that can be quietly undone — it is
 * what a household is told it owes — so it should never be a surprise.
 *
 * Both operations share one SELECT, so the preview cannot drift from what the
 * generate actually does.
 *
 *
 * WHICH PERIOD IS BILLED
 * ----------------------
 * The caller names it: @bill_year, and @bill_month for monthly charges. A
 * charge is included when
 *
 *   - it applies to that house (a house_charge row, active)
 *   - it has an amount above zero
 *   - its effective_from falls on or before the start of that period, so an
 *     amount dated ahead is not applied retroactively
 *   - that house has no bill for that charge and period already
 *
 * The last condition is what makes a second run safe: it raises what is
 * missing and leaves the rest alone. Bills already raised are never touched,
 * whatever the amount has since become.
 *
 *
 * RECEIPT NUMBERS
 * ---------------
 * Continue from the highest already issued for that charge, rather than
 * restarting. The existing rows run 1001-1010, 2001-2010 and 3001-3010, so a
 * fresh run picks up at 1011, 2011 and 3011. A charge that has never been
 * billed starts at payment_type * 1000 + 1, matching the pattern.
 *
 * Safe to re-run — the script, and the generation itself.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.sp_village_bill_run', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_bill_run;
GO

CREATE PROCEDURE dbo.sp_village_bill_run
    @operation   NVARCHAR(50) = NULL,   -- 'Preview' or 'Generate'
    @village_id  NVARCHAR(50) = NULL,
    @bill_year   SMALLINT     = NULL,
    @bill_month  TINYINT      = NULL,   -- ignored for yearly charges
    @audt_user   INT          = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation NOT IN ('Preview', 'Generate')
    BEGIN
        RAISERROR('operation must be Preview or Generate.', 16, 1);
        RETURN;
    END

    IF @bill_year IS NULL
    BEGIN
        RAISERROR('bill_year is required.', 16, 1);
        RETURN;
    END

    IF @bill_month IS NULL OR @bill_month NOT BETWEEN 1 AND 12
    BEGIN
        RAISERROR('bill_month must be 1-12.', 16, 1);
        RETURN;
    END

    -- The first day of the period being billed, for comparing effective_from.
    DECLARE @period_start DATE = DATEFROMPARTS(@bill_year, @bill_month, 1);
    DECLARE @year_start   DATE = DATEFROMPARTS(@bill_year, 1, 1);

    /*
     * Everything that would be billed. A yearly charge is compared against the
     * start of the year and carries no month; a monthly one against the start
     * of the month.
     */
    DECLARE @due TABLE (
        house_id     INT,
        house_no     NVARCHAR(50),
        owner_name   NVARCHAR(150),
        pre_mob      NVARCHAR(50),
        payment_type INT,
        charge_name  NVARCHAR(50),
        frequency    CHAR(1),
        amount       DECIMAL(18,2),
        bill_month   TINYINT
    );

    /*
     * The owner is joined LEFT: a house with no owner recorded is still billed,
     * and dropping it here would quietly leave that household off the run.
     */
    INSERT INTO @due (house_id, house_no, owner_name, pre_mob, payment_type, charge_name, frequency, amount, bill_month)
    SELECT h.house_id, h.house_no, o.name, o.pre_mob, t.payment_type, t.payment_type_name, t.frequency,
           c.amount,
           CASE WHEN t.frequency = 'M' THEN @bill_month END
    FROM   dbo.house_charge      AS c
    JOIN   dbo.house             AS h ON h.house_id = c.house_id
    LEFT   JOIN dbo.house_owner  AS o ON o.house_id = h.house_id
    JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
    WHERE  h.village_id   = @village_id
      AND  c.active_status = 0          -- the charge applies to this house
      AND  t.active_status = 0          -- and the charge itself is still levied
      AND  ISNULL(c.amount, 0) > 0
      -- Not yet in force for this period.
      AND  c.effective_from <= CASE WHEN t.frequency = 'Y' THEN @year_start ELSE @period_start END
      -- Not already billed for this period.
      AND  NOT EXISTS (
             SELECT 1 FROM dbo.house_tax_receipt AS r
             WHERE  r.house_id     = c.house_id
               AND  r.payment_type = c.payment_type
               AND  r.bill_year    = @bill_year
               AND  (t.frequency = 'Y' OR r.bill_month = @bill_month)
           );

    IF @operation = 'Preview'
    BEGIN
        /*
         * One row per house, not per charge. A household gets one bill listing
         * everything it owes for the period — a screen showing "101 water" and
         * "101 waste" as separate rows describes the stored rows rather than
         * the thing being handed over.
         */
        SELECT house_id, house_no, owner_name, pre_mob,
               COUNT(*)   AS charge_count,
               SUM(amount) AS total
        FROM   @due
        GROUP  BY house_id, house_no, owner_name, pre_mob
        ORDER  BY house_no;

        -- The lines making up each of those bills, for the printed copy.
        SELECT house_id, house_no, owner_name, payment_type, charge_name, frequency,
               amount, bill_month
        FROM   @due
        ORDER  BY house_no, payment_type;

        SELECT COUNT(DISTINCT house_id) AS bills,
               COUNT(*)                 AS lines,
               ISNULL(SUM(amount), 0)   AS total
        FROM   @due;
        RETURN;
    END

    /* ---------------------------------------------------------- Generate */

    IF NOT EXISTS (SELECT 1 FROM @due)
    BEGIN
        SELECT 0 AS bills, 0 AS lines, CAST(0 AS DECIMAL(18,2)) AS total;
        RETURN;
    END

    /*
     * Receipt numbers, one sequence per charge, continuing from the highest
     * already issued. TRY_CAST because receipt_no is nvarchar and older rows
     * are not guaranteed to be numeric.
     */
    DECLARE @seq TABLE (payment_type INT PRIMARY KEY, next_no INT);

    INSERT INTO @seq (payment_type, next_no)
    SELECT d.payment_type,
           ISNULL((SELECT MAX(TRY_CAST(r.receipt_no AS INT))
                     FROM dbo.house_tax_receipt AS r
                    WHERE r.payment_type = d.payment_type),
                  d.payment_type * 1000) + 1
    FROM   (SELECT DISTINCT payment_type FROM @due) AS d;

    /*
     * One transaction: a run that fails half way would leave some households
     * billed and others not, with no record of which.
     */
    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.house_tax_receipt
            (village_id, house_id, payment_type, pay_date, pay_mode, Amount_paid,
             payment_status, receipt_no, bill_year, bill_month)
        SELECT @village_id, d.house_id, d.payment_type, CAST(GETDATE() AS DATE), NULL, d.amount,
               0,                                     -- unpaid
               CAST(s.next_no + ROW_NUMBER() OVER (PARTITION BY d.payment_type ORDER BY d.house_no) - 1
                    AS NVARCHAR(50)),
               @bill_year, d.bill_month
        FROM   @due AS d
        JOIN   @seq AS s ON s.payment_type = d.payment_type;

        COMMIT;

        -- Bills is households billed; lines is the charges across them.
        SELECT COUNT(DISTINCT house_id) AS bills,
               COUNT(*)                 AS lines,
               ISNULL(SUM(amount), 0)   AS total
        FROM   @due;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

PRINT 'sp_village_bill_run created.';
GO

/* ---------------------------------------------------------- verification */

-- What August 2026 would raise, without raising it.
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC dbo.sp_village_bill_run @operation = 'Preview', @village_id = @v,
                             @bill_year = 2026, @bill_month = 8;
GO
