/*
 * Adding a charge without a developer.
 *
 * A gram panchayat levies more than the three charges this database was built
 * with. Adding a fourth — a street-light tax, a market fee — currently means
 * an INSERT run by hand, because nothing in either application can create one.
 * This adds the procedure behind a Charges screen so it can be done from the
 * app.
 *
 *
 * WHERE NEW CHARGES GO, AND WHY
 * -----------------------------
 * Into dbo.Village_payment_type — the table the three existing charges are
 * already in — rather than a second table beside it.
 *
 * The worry with that is the legacy WebForms app: a row appearing under it
 * unannounced. Checked, and it does not read this table at all. Every
 * dependency is on the SQL side:
 *
 *     House_wise_payment_vw    joins it for the charge's name
 *     sp_house_tax_receipt     joins it for the charge's name
 *     sp_house_charge          reads it to build the house x charge grid
 *
 * All three take a new row in their stride. Adding a fourth charge was tried
 * against the live schema in a rolled-back transaction: the house_charge grid
 * grew from 33 rows to 44 — a new column, applying to nobody until someone
 * says otherwise — and House_wise_payment_vw still returned its 81 rows.
 *
 * One table means one place to read. Two would mean every query that lists
 * charges having to union them, and that seam is where mistakes would live.
 *
 *
 * THE FIRST THREE ARE PROTECTED
 * -----------------------------
 * payment_type 1, 2 and 3 carry 81 bills between them and are referenced by
 * name in views and procedures. They can be renamed but not deleted, and their
 * frequency and basis cannot be changed — a bill already raised as yearly
 * cannot retroactively become monthly. The procedure enforces that; the screen
 * shows them as read-only.
 *
 *
 * A CHARGE IS NEVER DELETED
 * -------------------------
 * Deactivated instead. Bills already raised against a charge refer to it, and
 * removing the row would leave them naming nothing. A deactivated charge stops
 * appearing for new bills and stops being offered on the house grid.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------------ 1. the active flag */

IF COL_LENGTH('dbo.Village_payment_type', 'active_status') IS NULL
BEGIN
    -- 0 = active, matching the convention elsewhere in this database.
    ALTER TABLE dbo.Village_payment_type ADD active_status INT NOT NULL
        CONSTRAINT DF_vpt_active DEFAULT (0);
    PRINT 'Village_payment_type.active_status added.';
END
ELSE
    PRINT 'Village_payment_type.active_status already present.';
GO

/* ------------------------------------------------- 2. the procedure */

IF OBJECT_ID('dbo.sp_village_charge_type', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_charge_type;
GO

CREATE PROCEDURE dbo.sp_village_charge_type
    @operation    NVARCHAR(50) = NULL,
    @payment_type INT          = 0,
    @name         NVARCHAR(50) = NULL,
    @frequency    CHAR(1)      = NULL,   -- 'Y' yearly, 'M' monthly
    @basis        VARCHAR(4)   = NULL    -- 'AREA', 'TAP', 'FLAT'
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Grid_Show'
    BEGIN
        SELECT payment_type, payment_type_name, frequency, basis, active_status,
               -- The three the database was built with. Bills refer to them and
               -- SQL objects join them by name, so the screen locks them.
               CAST(CASE WHEN payment_type <= 3 THEN 1 ELSE 0 END AS BIT) AS is_builtin,
               (SELECT COUNT(*) FROM dbo.house_charge c
                 WHERE c.payment_type = t.payment_type AND c.active_status = 0) AS houses_charged,
               (SELECT COUNT(*) FROM dbo.house_tax_receipt r
                 WHERE r.payment_type = t.payment_type)                         AS bills_raised
        FROM   dbo.Village_payment_type AS t
        ORDER  BY payment_type;
    END

    IF @operation = 'Update'
    BEGIN
        IF @name IS NULL OR LTRIM(RTRIM(@name)) = ''
        BEGIN
            RAISERROR('A charge needs a name.', 16, 1);
            RETURN;
        END

        IF @frequency NOT IN ('Y', 'M')
        BEGIN
            RAISERROR('Frequency must be Y (yearly) or M (monthly).', 16, 1);
            RETURN;
        END

        IF @basis NOT IN ('AREA', 'TAP', 'FLAT')
        BEGIN
            RAISERROR('Basis must be AREA, TAP or FLAT.', 16, 1);
            RETURN;
        END

        -- Names are how a charge is recognised on a bill, so two the same
        -- would be unreadable.
        IF EXISTS (SELECT 1 FROM dbo.Village_payment_type
                    WHERE payment_type_name = @name AND payment_type <> @payment_type)
        BEGIN
            RAISERROR('A charge with that name already exists.', 16, 1);
            RETURN;
        END

        IF @payment_type = 0
        BEGIN
            /*
             * payment_type is assigned here rather than by IDENTITY: the
             * column has no key and the legacy rows carry hand-picked values,
             * so IDENTITY cannot be added to it without rebuilding the table.
             */
            DECLARE @next INT = (SELECT ISNULL(MAX(payment_type), 0) + 1 FROM dbo.Village_payment_type);

            INSERT INTO dbo.Village_payment_type (payment_type, payment_type_name, frequency, basis, active_status)
            VALUES (@next, @name, @frequency, @basis, 0);

            SELECT @next AS payment_type;
        END
        ELSE
        BEGIN
            IF @payment_type <= 3
            BEGIN
                /*
                 * The built-in three can be renamed but not re-shaped. Bills
                 * have already been raised under their present frequency and
                 * basis; changing either would silently reinterpret history.
                 */
                UPDATE dbo.Village_payment_type
                SET    payment_type_name = @name
                WHERE  payment_type = @payment_type;
            END
            ELSE
            BEGIN
                UPDATE dbo.Village_payment_type
                SET    payment_type_name = @name,
                       frequency         = @frequency,
                       basis             = @basis
                WHERE  payment_type = @payment_type;
            END

            SELECT @payment_type AS payment_type;
        END
    END

    IF @operation = 'Delete'
    BEGIN
        IF @payment_type <= 3
        BEGIN
            RAISERROR('The built-in charges cannot be removed.', 16, 1);
            RETURN;
        END

        /*
         * Deactivated, never deleted: bills already raised against this charge
         * refer to it, and removing the row would leave them naming nothing.
         */
        UPDATE dbo.Village_payment_type SET active_status = 1 WHERE payment_type = @payment_type;

        -- Stop offering it on the house grid too.
        UPDATE dbo.house_charge SET active_status = 1 WHERE payment_type = @payment_type;

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_village_charge_type created.';
GO

/* ------------------------------- 3. hide deactivated charges from the grid */

IF OBJECT_ID('dbo.sp_house_charge', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_house_charge;
GO

/*
 * Unchanged from ADD_village_billing_v2.sql apart from the active_status
 * filter on Village_payment_type: a charge that has been switched off should
 * not go on offering itself against every house.
 */
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
               c.house_charge_id, c.amount,
               CAST(CASE WHEN c.house_charge_id IS NULL OR c.active_status <> 0
                         THEN 0 ELSE 1 END AS BIT) AS applies
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
            -- Deactivated rather than deleted: the house was billed under this
            -- charge historically and those bills still refer to it.
            UPDATE dbo.house_charge
            SET    active_status = 1
            WHERE  house_id = @house_id AND payment_type = @payment_type;
        END
        ELSE IF EXISTS (SELECT 1 FROM dbo.house_charge
                        WHERE house_id = @house_id AND payment_type = @payment_type)
        BEGIN
            UPDATE dbo.house_charge
            SET    amount        = COALESCE(@amount, amount),
                   active_status = 0
            WHERE  house_id = @house_id AND payment_type = @payment_type;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.house_charge (house_id, payment_type, amount)
            VALUES (@house_id, @payment_type, @amount);
        END

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_house_charge updated to hide deactivated charges.';
GO

/* ---------------------------------------------------------- verification */

EXEC dbo.sp_village_charge_type @operation = 'Grid_Show';
GO
