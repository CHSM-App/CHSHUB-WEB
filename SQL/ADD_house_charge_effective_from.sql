/*
 * A changed amount takes effect next month; bills already raised keep theirs.
 *
 * The rule
 * --------
 *   A bill that has been raised keeps the amount it was raised at, even if
 *   the charge is changed afterwards.
 *
 *   A change to an amount takes effect from the start of the following month.
 *
 * The first half matters most. If house 101 was billed 100 for December's
 * water and the rate later moves to 150, that December bill stays at 100 —
 * the household was told 100, and asking for 150 afterwards is not something
 * an office can defend. Bills are a record of what was charged, not a
 * calculation to be re-run.
 *
 * The second half stops a mid-month change from being applied retroactively
 * to a month already part-way through, and from a brand-new charge sweeping
 * up every month since January the first time bills are generated.
 *
 *
 * WHAT THIS ADDS
 * --------------
 * house_charge.effective_from already exists but is never written. This puts
 * a value in it and makes sp_house_charge maintain it:
 *
 *   - a new charge for a house is effective from the first of next month
 *   - a changed amount is effective from the first of next month
 *   - switching a charge off, or back on without changing the amount, leaves
 *     the date alone: nothing about what is owed has changed
 *
 * Existing rows are back-filled to the first of the current month, so they are
 * already in force and this month's bills can be raised from them.
 *
 * Bill generation — not yet written — will read effective_from and skip any
 * period that starts before it. Until that exists this column records the
 * intent without acting on it, which is why the screen says so.
 *
 *
 * WHY NOT KEEP A HISTORY OF RATES
 * -------------------------------
 * The fuller design is one row per rate per period, so any past month can be
 * re-priced exactly. It is not what this needs: bills carry their own amount
 * once raised, so the past is already recorded in house_tax_receipt. A second
 * copy in house_charge would be one more thing to keep in step, and the two
 * would eventually disagree.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ----------------------------------------------------- 1. the back-fill */

/*
 * The first of the current month, not today: a charge already in force should
 * cover the month it is in, so this month's bills can still be raised.
 */
UPDATE dbo.house_charge
SET    effective_from = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
WHERE  effective_from IS NULL;

PRINT 'house_charge.effective_from back-filled to the start of this month.';
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

    -- The first of next month: when a change made today takes effect.
    DECLARE @next_month DATE = DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));

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
             * leaves the existing date in place — otherwise an idle save would
             * push a rate that is already in force out to next month.
             */
            UPDATE dbo.house_charge
            SET    amount         = COALESCE(@amount, amount),
                   active_status  = 0,
                   effective_from = CASE
                                      WHEN @amount IS NOT NULL AND @amount <> ISNULL(amount, -1)
                                      THEN @next_month
                                      ELSE effective_from
                                    END
            WHERE  house_id = @house_id AND payment_type = @payment_type;
        END
        ELSE
        BEGIN
            -- A charge applied to a house for the first time starts next month.
            INSERT INTO dbo.house_charge (house_id, payment_type, amount, effective_from)
            VALUES (@house_id, @payment_type, @amount, @next_month);
        END

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_house_charge now dates a changed amount from the first of next month.';
GO

/* ---------------------------------------------------------- verification */

SELECT h.house_no, t.payment_type_name, c.amount, c.effective_from, c.active_status
FROM   dbo.house_charge AS c
JOIN   dbo.house AS h ON h.house_id = c.house_id
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
ORDER  BY h.house_no, c.payment_type;
GO
