/*
 * Village billing — the schema billing actually needs.
 *
 * Part 1 of the billing work: schema and settings only. It adds tables and
 * columns, back-fills them from what is already recorded, and changes no
 * existing row's meaning. Bill generation itself is Part 2, so nothing here
 * raises or alters a charge.
 *
 *
 * WHY THE PRESENT SHAPE CANNOT WORK
 * ---------------------------------
 * Everything billable lives in three columns on dbo.house:
 *
 *     gharpatti_charges, water_charges, waste_charges
 *
 * Four things follow from that, and all four are wrong for a gram panchayat:
 *
 *  1. Every house is billed for everything. A house with no tap connection
 *     still gets a water bill — house 11 has no_of_tab = 0 and
 *     water_charges = 100, and bills have been raised against it. There is no
 *     way to say "this service does not apply here", because the column exists
 *     on every row.
 *
 *  2. A new charge means a schema change. Adding a street-light tax or a
 *     market fee means a new column on dbo.house, plus new SQL, new API and
 *     new UI for it. A gram panchayat levying a fourth charge is ordinary, and
 *     it should not need a developer.
 *
 *  3. Rates are frozen into each row. House tax is charged per square foot —
 *     the data says so plainly: eight of eleven houses have
 *     gharpatti_charges / area = exactly 5.00. But that multiplication was
 *     done by hand and the *result* stored, so changing the rate means editing
 *     every house. dbo.square_ft_rate exists for exactly this and is never
 *     read by anything.
 *
 *  4. There is no period. house_tax_receipt records pay_date — when the bill
 *     was raised — and nothing saying which month or year it is *for*. So
 *     "has December's water been billed?" is unanswerable, and property tax
 *     (yearly) cannot be told apart from water (monthly).
 *
 *
 * WHAT THIS SCRIPT PUTS IN PLACE
 * ------------------------------
 *   Village_payment_type.frequency  'Y' or 'M'  — how often the charge falls
 *   Village_payment_type.basis      how the amount is arrived at:
 *                                     'FLAT' a fixed amount
 *                                     'AREA' area x rate
 *                                     'TAP'  tap count x rate
 *   house_charge                    which charges apply to which house, and
 *                                   at what amount — one row per house per
 *                                   charge. No row means the charge does not
 *                                   apply, which is how "no tap connection"
 *                                   is expressed.
 *   house_tax_receipt.bill_month    the period the bill covers
 *   house_tax_receipt.bill_year
 *   village_setting                 generation and interest, per village
 *
 * With house_charge in place, generation becomes one rule — "for every active
 * house_charge whose period has not been billed, raise a bill" — instead of
 * three near-identical cursors that name their columns.
 *
 *
 * ON AMOUNTS: WHY house_charge STORES ONE
 * ---------------------------------------
 * The obvious move is to drop stored amounts and always compute area x rate.
 * The data says not to. Per-square-foot rates are not consistent even within
 * one house type:
 *
 *     house_type 1 — rates from 2.00 to 5.00
 *     house_type 2 — rates from 1.83 to 45.00
 *
 * So each house's charge is, in practice, its own figure. Recomputing them
 * from a single rate would change what people owe — house 5 would fall from
 * 90,000 to 10,000. That is not a migration, it is a decision about money.
 *
 * house_charge therefore carries an explicit `amount`, back-filled from what
 * each house is charged today, and a `basis` saying how it *should* be derived
 * going forward. Generation uses the stored amount; a later step can recompute
 * from rates deliberately, per village, once someone has decided to.
 *
 *
 * WHAT IS NOT DONE HERE
 * ---------------------
 *   - No bill is raised, changed or removed. 67 unpaid and 14 paid bills
 *     (12,150 collected) are left exactly as they are.
 *   - The 12 duplicate pairs are left in place and listed at the end.
 *   - dbo.house keeps its three columns. Nothing reads house_charge yet, so
 *     both remain true until Part 2 switches generation over. Dropping them
 *     now would break the pages that still read them.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------- 1. payment type metadata */

IF COL_LENGTH('dbo.Village_payment_type', 'frequency') IS NULL
BEGIN
    -- Monthly by default: a charge added later is monthly unless said
    -- otherwise, which is the commoner case.
    ALTER TABLE dbo.Village_payment_type ADD frequency CHAR(1) NOT NULL
        CONSTRAINT DF_vpt_frequency DEFAULT 'M';
    PRINT 'Village_payment_type.frequency added.';
END
ELSE
    PRINT 'Village_payment_type.frequency already present.';
GO

IF COL_LENGTH('dbo.Village_payment_type', 'basis') IS NULL
BEGIN
    ALTER TABLE dbo.Village_payment_type ADD basis VARCHAR(4) NOT NULL
        CONSTRAINT DF_vpt_basis DEFAULT 'FLAT';
    PRINT 'Village_payment_type.basis added.';
END
ELSE
    PRINT 'Village_payment_type.basis already present.';
GO

/*
 * Property Tax is yearly and scales with area — eight of eleven houses sit at
 * exactly 5.00 per square foot. Water is monthly and scales with the number of
 * taps (50.00 per tap on most rows). Waste is monthly and flat: the amounts
 * cluster on round figures (100 six times, 150 twice) with no relation to
 * area or taps.
 */
UPDATE dbo.Village_payment_type SET frequency = 'Y', basis = 'AREA' WHERE payment_type = 1;
UPDATE dbo.Village_payment_type SET frequency = 'M', basis = 'TAP'  WHERE payment_type = 2;
UPDATE dbo.Village_payment_type SET frequency = 'M', basis = 'FLAT' WHERE payment_type = 3;
GO

/* ------------------------------------------------- 2. the period columns */

IF COL_LENGTH('dbo.house_tax_receipt', 'bill_month') IS NULL
BEGIN
    ALTER TABLE dbo.house_tax_receipt ADD bill_month TINYINT NULL;
    PRINT 'house_tax_receipt.bill_month added.';
END
ELSE
    PRINT 'house_tax_receipt.bill_month already present.';
GO

IF COL_LENGTH('dbo.house_tax_receipt', 'bill_year') IS NULL
BEGIN
    ALTER TABLE dbo.house_tax_receipt ADD bill_year SMALLINT NULL;
    PRINT 'house_tax_receipt.bill_year added.';
END
ELSE
    PRINT 'house_tax_receipt.bill_year already present.';
GO

/*
 * Back-fill from each row's own pay_date. This is a reading of the data, not a
 * fact that was recorded — the period was never stored. It is sound for the
 * rows present: the monthly runs (Oct, Nov, Dec 2025) match their pay_date,
 * and the two property-tax runs read as the 2024 and 2025 charges.
 *
 * Only rows with no period yet, so a re-run cannot overwrite a period someone
 * has since corrected by hand.
 */
UPDATE r
SET    r.bill_year  = YEAR(r.pay_date),
       r.bill_month = CASE WHEN t.frequency = 'M' THEN MONTH(r.pay_date) END
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
WHERE  r.bill_year IS NULL
  AND  r.pay_date IS NOT NULL;

PRINT 'Existing bills back-filled with their period.';
GO

/* ---------------------------------------------------- 3. house_charge */

IF OBJECT_ID('dbo.house_charge', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.house_charge (
        house_charge_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        house_id        INT           NOT NULL,
        payment_type    INT           NOT NULL,
        -- What this house is charged. NULL means "derive it from the type's
        -- basis and the village rate" — not used by the back-fill, which
        -- records today's figures explicitly, but available once rates are
        -- managed centrally.
        amount          DECIMAL(18,2) NULL,
        -- 0 = active. Follows active_status elsewhere in this database, where
        -- 0 is the live row.
        active_status   INT           NOT NULL CONSTRAINT DF_hc_active DEFAULT (0),
        effective_from  DATE          NULL,
        /*
         * house_id gets a foreign key; payment_type does not.
         *
         * dbo.Village_payment_type has no primary key and its payment_type
         * column is nullable, so SQL Server will not accept it as the target
         * of a reference. Adding a key to it would fix that, but it is a
         * shared table — the legacy WebForms app reads it too — and changing
         * a column to NOT NULL there is a bigger decision than this script
         * should take on its own. The values are a fixed set of three that
         * sp_house_charge validates against on write, so the risk of an
         * orphan row is small. Worth revisiting if that table is ever
         * given a key.
         */
        CONSTRAINT FK_hc_house FOREIGN KEY (house_id) REFERENCES dbo.house (house_id),
        -- One row per house per charge: two would double every bill raised.
        CONSTRAINT UQ_hc_house_type UNIQUE (house_id, payment_type)
    );
    PRINT 'house_charge created.';
END
ELSE
    PRINT 'house_charge already present.';
GO

/*
 * Back-fill from dbo.house, preserving each house's present figures.
 *
 * A charge is recorded only where it genuinely applies:
 *   - property tax: where there is an amount above zero
 *   - water:        where the house has at least one tap AND an amount. This
 *                   is what stops house 11 (no_of_tab = 0) from being billed
 *                   for water it has no connection for.
 *   - waste:        where there is an amount above zero
 *
 * A house missing from house_charge for a type is not billed for it. That is
 * the whole point of the table.
 */
INSERT INTO dbo.house_charge (house_id, payment_type, amount)
SELECT h.house_id, 1, h.gharpatti_charges
FROM   dbo.house AS h
WHERE  ISNULL(h.gharpatti_charges, 0) > 0
  AND  NOT EXISTS (SELECT 1 FROM dbo.house_charge c
                   WHERE c.house_id = h.house_id AND c.payment_type = 1);

INSERT INTO dbo.house_charge (house_id, payment_type, amount)
SELECT h.house_id, 2, h.water_charges
FROM   dbo.house AS h
WHERE  ISNULL(h.water_charges, 0) > 0
  AND  ISNULL(h.no_of_tab, 0) > 0
  AND  NOT EXISTS (SELECT 1 FROM dbo.house_charge c
                   WHERE c.house_id = h.house_id AND c.payment_type = 2);

INSERT INTO dbo.house_charge (house_id, payment_type, amount)
SELECT h.house_id, 3, h.waste_charges
FROM   dbo.house AS h
WHERE  ISNULL(h.waste_charges, 0) > 0
  AND  NOT EXISTS (SELECT 1 FROM dbo.house_charge c
                   WHERE c.house_id = h.house_id AND c.payment_type = 3);

PRINT 'house_charge back-filled from dbo.house.';
GO

/* -------------------------------------------------- 4. village_setting */

IF OBJECT_ID('dbo.village_setting', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.village_setting (
        village_setting_id   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        /*
         * nvarchar(50), matching house.village_id and house_tax_receipt.
         * village_master declares its own as nvarchar(10) — the narrowest in
         * the database — so a wider column here cannot truncate.
         */
        village_id           NVARCHAR(50)  NOT NULL,
        auto_bill_generation BIT           NOT NULL CONSTRAINT DF_vs_auto     DEFAULT (0),
        bill_gen_day         TINYINT       NOT NULL CONSTRAINT DF_vs_genday   DEFAULT (1),
        property_tax_month   TINYINT       NOT NULL CONSTRAINT DF_vs_ptmonth  DEFAULT (4),
        due_days             SMALLINT      NOT NULL CONSTRAINT DF_vs_duedays  DEFAULT (30),
        interest_rate        DECIMAL(5,2)  NOT NULL CONSTRAINT DF_vs_intrate  DEFAULT (0),
        interest_after_days  SMALLINT      NOT NULL CONSTRAINT DF_vs_intafter DEFAULT (30),
        active_status        INT           NOT NULL CONSTRAINT DF_vs_active   DEFAULT (0),
        CONSTRAINT UQ_village_setting_village UNIQUE (village_id),
        -- Capped at 28: a 29th, 30th or 31st would skip February and that
        -- month's bills would never be raised.
        CONSTRAINT CK_vs_genday   CHECK (bill_gen_day BETWEEN 1 AND 28),
        CONSTRAINT CK_vs_ptmonth  CHECK (property_tax_month BETWEEN 1 AND 12),
        CONSTRAINT CK_vs_duedays  CHECK (due_days BETWEEN 0 AND 365),
        CONSTRAINT CK_vs_intrate  CHECK (interest_rate BETWEEN 0 AND 100),
        CONSTRAINT CK_vs_intafter CHECK (interest_after_days BETWEEN 0 AND 365)
    );
    PRINT 'village_setting created.';
END
ELSE
    PRINT 'village_setting already present.';
GO

/*
 * Defaults, and the reasoning:
 *   auto off        — nothing is raised until switched on deliberately
 *   April           — the financial year a gram panchayat works to
 *   day 1, 30 days  — first of the month, a month to pay
 *   interest 0      — off until a rate is set; charging by accident is worse
 *                     than charging late
 */
INSERT INTO dbo.village_setting (village_id)
SELECT v.village_id
FROM   dbo.village_master AS v
WHERE  NOT EXISTS (SELECT 1 FROM dbo.village_setting AS s WHERE s.village_id = v.village_id);

PRINT 'Default settings row ensured for every village.';
GO

/* --------------------------------------------------- 5. sp_village_setting */

IF OBJECT_ID('dbo.sp_village_setting', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_setting;
GO

CREATE PROCEDURE dbo.sp_village_setting
    @operation            NVARCHAR(50) = NULL,
    @village_id           NVARCHAR(50) = NULL,
    @auto_bill_generation BIT          = NULL,
    @bill_gen_day         TINYINT      = NULL,
    @property_tax_month   TINYINT      = NULL,
    @due_days             SMALLINT     = NULL,
    @interest_rate        DECIMAL(5,2) = NULL,
    @interest_after_days  SMALLINT     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Select'
    BEGIN
        -- A village with no row yet still gets its defaults, so the settings
        -- page always has something to show.
        IF NOT EXISTS (SELECT 1 FROM dbo.village_setting WHERE village_id = @village_id)
            INSERT INTO dbo.village_setting (village_id) VALUES (@village_id);

        SELECT village_setting_id, village_id, auto_bill_generation, bill_gen_day,
               property_tax_month, due_days, interest_rate, interest_after_days
        FROM   dbo.village_setting
        WHERE  village_id = @village_id;
    END

    IF @operation = 'Update'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.village_setting WHERE village_id = @village_id)
            INSERT INTO dbo.village_setting (village_id) VALUES (@village_id);

        -- COALESCE so an omitted parameter leaves its column alone rather than
        -- writing NULL over a setting the caller never meant to touch.
        UPDATE dbo.village_setting
        SET    auto_bill_generation = COALESCE(@auto_bill_generation, auto_bill_generation),
               bill_gen_day         = COALESCE(@bill_gen_day,         bill_gen_day),
               property_tax_month   = COALESCE(@property_tax_month,   property_tax_month),
               due_days             = COALESCE(@due_days,             due_days),
               interest_rate        = COALESCE(@interest_rate,        interest_rate),
               interest_after_days  = COALESCE(@interest_after_days,  interest_after_days)
        WHERE  village_id = @village_id;

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_village_setting created.';
GO

/* --------------------------------------------------- 6. sp_house_charge */

IF OBJECT_ID('dbo.sp_house_charge', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_house_charge;
GO

/*
 * Reads and edits which charges apply to a house. The screen behind it answers
 * "what is this house billed for?" — the question the present schema cannot
 * express at all.
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

    -- Every house against every charge type, with the amount where it applies
    -- and NULL where it does not, so a screen can show the full grid.
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
        ORDER  BY h.house_no, t.payment_type;
    END

    -- What one house is billed for.
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
        /*
         * Stands in for the foreign key house_charge cannot declare, since
         * Village_payment_type has no key to point at. Without this a typo in
         * payment_type would file a charge against a type that does not exist,
         * and it would simply never be billed.
         */
        IF NOT EXISTS (SELECT 1 FROM dbo.Village_payment_type WHERE payment_type = @payment_type)
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

PRINT 'sp_house_charge created.';
GO

/* ---------------------------------------------------------- verification */

SELECT payment_type, payment_type_name, frequency, basis
FROM   dbo.Village_payment_type
ORDER  BY payment_type;

/*
 * Charges per house. House 11 should appear WITHOUT a water row — it has no
 * tap connection, and under the old shape it was being billed for water
 * anyway.
 */
SELECT h.house_no, h.area, h.no_of_tab,
       MAX(CASE WHEN c.payment_type = 1 THEN c.amount END) AS property_tax,
       MAX(CASE WHEN c.payment_type = 2 THEN c.amount END) AS water,
       MAX(CASE WHEN c.payment_type = 3 THEN c.amount END) AS waste
FROM   dbo.house AS h
LEFT   JOIN dbo.house_charge AS c ON c.house_id = h.house_id
GROUP  BY h.house_no, h.area, h.no_of_tab
ORDER  BY h.house_no;

-- Totals must match dbo.house exactly: nothing has been re-priced.
SELECT (SELECT SUM(gharpatti_charges) FROM dbo.house WHERE ISNULL(gharpatti_charges,0) > 0)                     AS house_property_total,
       (SELECT SUM(amount) FROM dbo.house_charge WHERE payment_type = 1)                                        AS charge_property_total,
       (SELECT SUM(water_charges) FROM dbo.house WHERE ISNULL(water_charges,0) > 0 AND ISNULL(no_of_tab,0) > 0)  AS house_water_total,
       (SELECT SUM(amount) FROM dbo.house_charge WHERE payment_type = 2)                                        AS charge_water_total,
       (SELECT SUM(waste_charges) FROM dbo.house WHERE ISNULL(waste_charges,0) > 0)                             AS house_waste_total,
       (SELECT SUM(amount) FROM dbo.house_charge WHERE payment_type = 3)                                        AS charge_waste_total;

SELECT village_id, auto_bill_generation, bill_gen_day, property_tax_month,
       due_days, interest_rate, interest_after_days
FROM   dbo.village_setting
ORDER  BY village_id;

-- Every bill should now carry a period.
SELECT t.payment_type_name, t.frequency,
       COUNT(*)                                                                    AS bills,
       SUM(CASE WHEN r.bill_year IS NULL THEN 1 ELSE 0 END)                        AS missing_year,
       SUM(CASE WHEN t.frequency = 'M' AND r.bill_month IS NULL THEN 1 ELSE 0 END) AS missing_month
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
GROUP  BY t.payment_type_name, t.frequency;

/*
 * Duplicate bills — the same house, charge and period raised more than once.
 * Left in place deliberately: removing one changes what a household owes.
 * Decide on these before anything is deleted.
 */
SELECT r.house_id, h.house_no, t.payment_type_name,
       r.bill_year, r.bill_month, COUNT(*) AS times_billed,
       SUM(CASE WHEN r.payment_status = 1 THEN 1 ELSE 0 END) AS already_paid
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
LEFT   JOIN dbo.house AS h ON h.house_id = r.house_id
GROUP  BY r.house_id, h.house_no, t.payment_type_name, r.bill_year, r.bill_month
HAVING COUNT(*) > 1
ORDER  BY r.house_id, t.payment_type_name, r.bill_year, r.bill_month;
GO
