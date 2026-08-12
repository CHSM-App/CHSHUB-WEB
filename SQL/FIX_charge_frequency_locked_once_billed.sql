/*
 * A charge that has been billed cannot change how often it falls.
 *
 * The bug
 * -------
 * House 0 shows 500 outstanding for "other charges" — a charge whose amount is
 * 100, and which the user had not knowingly generated.
 *
 * What happened:
 *
 *   1. "other charges" was created as a YEARLY charge, at 500.
 *   2. A bill was raised for it: bill_year 2026, bill_month NULL — the shape a
 *      yearly charge is stored in.
 *   3. The charge was then edited to MONTHLY, and its amount to 100.
 *
 * Step 3 orphaned the bill. sp_village_bill_run asks "has this been billed for
 * this period?" and, for a monthly charge, that means bill_month = 8. The
 * existing row has bill_month NULL, so it matches nothing — the charge looks
 * unbilled and comes up for billing again, this time at 100. The household
 * ends up owing 500 + 100 for one charge.
 *
 * The 500 was real: it was billed. The mistake is that changing the frequency
 * silently reinterpreted every bill already raised under it.
 *
 * Why the existing guard did not catch it
 * ---------------------------------------
 * sp_village_charge_type refuses to re-shape payment_type 1-3, on the grounds
 * that bills exist against them. That test is the wrong one: it protects the
 * three built-ins by number rather than protecting whatever has been billed.
 * A charge a village adds is exposed the moment its first bill goes out.
 *
 * The fix
 * -------
 * Frequency and basis are locked once any bill exists for the charge,
 * whichever charge it is. Renaming stays allowed — a name is a label, not a
 * claim about periods. The built-in three keep their existing protection,
 * since they carry bills regardless.
 *
 * A village that needs a charge to fall differently can deactivate it and add
 * a new one, which leaves the old bills describing what they always did.
 *
 * The orphaned bill
 * -----------------
 * Not touched here. Receipt 4001 for 500 was genuinely raised and may have
 * been shown to the household; deciding whether it stands is not something a
 * schema script should do. It is listed at the end so it can be settled or
 * removed deliberately.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

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
               CAST(CASE WHEN payment_type <= 3 THEN 1 ELSE 0 END AS BIT) AS is_builtin,
               (SELECT COUNT(*) FROM dbo.house_charge c
                 WHERE c.payment_type = t.payment_type AND c.active_status = 0) AS houses_charged,
               (SELECT COUNT(*) FROM dbo.house_tax_receipt r
                 WHERE r.payment_type = t.payment_type)                         AS bills_raised,
               /*
                * True once the charge cannot be re-shaped: either it is one of
                * the built-ins, or a bill has been raised against it. The
                * screen disables the frequency and basis fields on this.
                */
               CAST(CASE WHEN payment_type <= 3
                          OR EXISTS (SELECT 1 FROM dbo.house_tax_receipt r
                                      WHERE r.payment_type = t.payment_type)
                         THEN 1 ELSE 0 END AS BIT) AS is_locked
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

        IF EXISTS (SELECT 1 FROM dbo.Village_payment_type
                    WHERE payment_type_name = @name AND payment_type <> @payment_type)
        BEGIN
            RAISERROR('A charge with that name already exists.', 16, 1);
            RETURN;
        END

        IF @payment_type = 0
        BEGIN
            DECLARE @next INT = (SELECT ISNULL(MAX(payment_type), 0) + 1 FROM dbo.Village_payment_type);

            INSERT INTO dbo.Village_payment_type (payment_type, payment_type_name, frequency, basis, active_status)
            VALUES (@next, @name, @frequency, @basis, 0);

            SELECT @next AS payment_type;
        END
        ELSE
        BEGIN
            /*
             * Locked once billed, not merely for the built-in three.
             *
             * Bills record their period in the shape the charge had when they
             * were raised — a month for a monthly charge, NULL for a yearly
             * one. Changing the frequency afterwards leaves those bills
             * matching no period at all, so the charge reads as unbilled and
             * is billed again. That is what put 500 and 100 against one
             * household for the same charge.
             */
            DECLARE @locked BIT =
                CASE WHEN @payment_type <= 3
                      OR EXISTS (SELECT 1 FROM dbo.house_tax_receipt
                                  WHERE payment_type = @payment_type)
                     THEN 1 ELSE 0 END;

            IF @locked = 1
            BEGIN
                -- A name is a label; renaming cannot misdescribe a period.
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

        -- Deactivated, never deleted: bills already raised refer to it.
        UPDATE dbo.Village_payment_type SET active_status = 1 WHERE payment_type = @payment_type;
        UPDATE dbo.house_charge SET active_status = 1 WHERE payment_type = @payment_type;

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_village_charge_type: frequency and basis are locked once a charge has been billed.';
GO

/* ---------------------------------------------------------- verification */

SELECT payment_type, payment_type_name, frequency, basis,
       (SELECT COUNT(*) FROM dbo.house_tax_receipt r WHERE r.payment_type = t.payment_type) AS bills_raised
FROM   dbo.Village_payment_type AS t
ORDER  BY payment_type;

/*
 * Bills whose stored period no longer matches their charge's frequency —
 * raised before the frequency was changed. Each of these will be billed a
 * second time, because the run cannot see them as covering the period.
 *
 * Decide on them: settle them, or remove them if they were never issued.
 * Nothing here does it automatically — they are real amounts against real
 * households.
 */
SELECT r.house_receipt_id, h.house_no, o.name AS owner_name,
       t.payment_type_name, t.frequency AS charge_is_now,
       r.bill_year, r.bill_month, r.receipt_no, r.Amount_paid, r.payment_status
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
LEFT   JOIN dbo.house AS h ON h.house_id = r.house_id
LEFT   JOIN dbo.house_owner AS o ON o.house_id = r.house_id
WHERE  (t.frequency = 'M' AND r.bill_month IS NULL)
   OR  (t.frequency = 'Y' AND r.bill_month IS NOT NULL);
GO
