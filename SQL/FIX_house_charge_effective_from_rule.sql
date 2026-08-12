/*
 * A changed amount applies from the first period that has not been billed.
 *
 * The rule
 * --------
 *   Bills already raised keep the amount they were raised at.
 *
 *   A change applies from the earliest period that has no bill yet:
 *
 *     this period not billed  ->  the change applies to THIS period
 *     this period billed      ->  the change applies from the NEXT one
 *
 *   "Period" means the month for a monthly charge and the year for a yearly
 *   one, so property tax moves a year at a time and water a month at a time.
 *
 * Why this and not "always next month"
 * ------------------------------------
 * The previous version dated every change to the first of the following month.
 * That is wrong whenever the current month has not been billed yet: an amount
 * corrected on the 5th, before August's bills go out, should go out at the
 * corrected figure. Waiting until September would send August at a figure the
 * office had already replaced.
 *
 * What does not change is the first half of the rule: a bill that exists keeps
 * its amount. house_tax_receipt stores what was charged, and nothing here
 * rewrites it.
 *
 * Effect on the data
 * ------------------
 * Existing rows are re-dated by the same rule, so they say what is actually
 * true today rather than the blanket next-month date the earlier script wrote.
 * For the rows here that generally means the start of this month, because
 * August has not been billed.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* --------------------------------------------- 1. the shared calculation */

IF OBJECT_ID('dbo.fn_house_charge_effective_from', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_house_charge_effective_from;
GO

/*
 * The first period a change can affect, for one house and one charge.
 *
 * A function rather than repeated inline SQL: the same question is asked when
 * a charge is added, when an amount is changed, and — once it exists — by bill
 * generation deciding which periods to raise.
 */
CREATE FUNCTION dbo.fn_house_charge_effective_from
(
    @house_id     INT,
    @payment_type INT
)
RETURNS DATE
AS
BEGIN
    DECLARE @today       DATE = CAST(GETDATE() AS DATE);
    DECLARE @this_month  DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    DECLARE @this_year   DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
    DECLARE @frequency   CHAR(1);

    SELECT @frequency = frequency
    FROM   dbo.Village_payment_type
    WHERE  payment_type = @payment_type;

    IF @frequency = 'Y'
    BEGIN
        -- Yearly: has this year been billed for this house and charge?
        IF EXISTS (SELECT 1 FROM dbo.house_tax_receipt
                    WHERE house_id     = @house_id
                      AND payment_type = @payment_type
                      AND bill_year    = YEAR(@today))
            RETURN DATEADD(YEAR, 1, @this_year);   -- billed: from next year

        RETURN @this_year;                          -- not billed: from this year
    END

    -- Monthly: has this month been billed?
    IF EXISTS (SELECT 1 FROM dbo.house_tax_receipt
                WHERE house_id     = @house_id
                  AND payment_type = @payment_type
                  AND bill_year    = YEAR(@today)
                  AND bill_month   = MONTH(@today))
        RETURN DATEADD(MONTH, 1, @this_month);      -- billed: from next month

    RETURN @this_month;                             -- not billed: from this month
END
GO

PRINT 'fn_house_charge_effective_from created.';
GO

/* ----------------------------------------------------- 2. the procedure */

IF OBJECT_ID('dbo.sp_house_charge', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_house_charge;
GO

CREATE PROCEDURE dbo.sp_house_charge
    @operation    NVARCHAR(50)  = NULL,
    @village_id   NVARCHAR(50)  = NULL,
    @house_id     INT           = 0,
    @payment_type INT           = 0,
    @amount       DECIMAL(18,2) = NULL,
    @applies      BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Grid_Show'
    BEGIN
        SELECT h.house_id, h.house_no, h.area, h.no_of_tab,
               t.payment_type, t.payment_type_name, t.frequency, t.basis,
               c.house_charge_id, c.amount, c.effective_from,
               CAST(CASE WHEN c.house_charge_id IS NULL OR c.active_status <> 0
                         THEN 0 ELSE 1 END AS BIT) AS applies,
               -- True while the amount is dated ahead of today, so the screen
               -- can say when it starts rather than implying it is in force.
               CAST(CASE WHEN c.effective_from > CAST(GETDATE() AS DATE)
                         THEN 1 ELSE 0 END AS BIT) AS pending
        FROM   dbo.house AS h
        CROSS  JOIN dbo.Village_payment_type AS t
        LEFT   JOIN dbo.house_charge AS c
               ON c.house_id = h.house_id AND c.payment_type = t.payment_type
        WHERE  h.village_id = @village_id
          AND  t.active_status = 0
        ORDER  BY h.house_no, t.payment_type;
    END

    IF @operation = 'Select'
    BEGIN
        SELECT c.house_charge_id, c.house_id, c.payment_type, t.payment_type_name,
               t.frequency, t.basis, c.amount, c.active_status, c.effective_from
        FROM   dbo.house_charge AS c
        JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
        WHERE  c.house_id = @house_id
        ORDER  BY c.payment_type;
    END

    IF @operation = 'Update'
    BEGIN
        -- Stands in for the foreign key house_charge cannot declare, since
        -- Village_payment_type has no key to point at.
        IF NOT EXISTS (SELECT 1 FROM dbo.Village_payment_type
                        WHERE payment_type = @payment_type AND active_status = 0)
        BEGIN
            RAISERROR('Unknown payment_type.', 16, 1);
            RETURN;
        END

        DECLARE @from DATE = dbo.fn_house_charge_effective_from(@house_id, @payment_type);

        IF @applies = 0
        BEGIN
            /*
             * Deactivated rather than deleted: the house was billed under this
             * charge historically and those bills still refer to it. The date
             * is left alone — switching a charge off changes nothing about
             * what the amount is worth if it is switched back on.
             */
            UPDATE dbo.house_charge
            SET    active_status = 1
            WHERE  house_id = @house_id AND payment_type = @payment_type;
        END
        ELSE IF EXISTS (SELECT 1 FROM dbo.house_charge
                        WHERE house_id = @house_id AND payment_type = @payment_type)
        BEGIN
            /*
             * effective_from moves only when the amount actually changes.
             * Re-saving the same figure, or switching the charge back on,
             * leaves the existing date alone — otherwise an idle save would
             * re-date a rate that is already in force.
             */
            UPDATE dbo.house_charge
            SET    amount         = COALESCE(@amount, amount),
                   active_status  = 0,
                   effective_from = CASE
                                      WHEN @amount IS NOT NULL AND @amount <> ISNULL(amount, -1)
                                      THEN @from
                                      ELSE effective_from
                                    END
            WHERE  house_id = @house_id AND payment_type = @payment_type;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.house_charge (house_id, payment_type, amount, effective_from)
            VALUES (@house_id, @payment_type, @amount, @from);
        END

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_house_charge now dates a change from the first unbilled period.';
GO

/* ------------------------------------------------------- 3. re-date rows */

/*
 * The earlier script dated everything to the first of next month. Re-state
 * each row by the rule above, so the dates describe what is actually true.
 */
UPDATE c
SET    effective_from = dbo.fn_house_charge_effective_from(c.house_id, c.payment_type)
FROM   dbo.house_charge AS c;

PRINT 'Existing charges re-dated to their first unbilled period.';
GO

/* ---------------------------------------------------------- verification */

/*
 * Water and waste were billed for December 2025 and not since, so with today
 * in August 2026 the current month is unbilled and they date from 1 August.
 * Property tax was last billed for 2025, so this year is unbilled too.
 */
SELECT h.house_no, t.payment_type_name, t.frequency, c.amount, c.effective_from,
       (SELECT COUNT(*) FROM dbo.house_tax_receipt r
         WHERE r.house_id = c.house_id AND r.payment_type = c.payment_type
           AND r.bill_year = YEAR(GETDATE())
           AND (t.frequency = 'Y' OR r.bill_month = MONTH(GETDATE()))) AS billed_this_period
FROM   dbo.house_charge AS c
JOIN   dbo.house AS h ON h.house_id = c.house_id
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
ORDER  BY h.house_no, c.payment_type;
GO
