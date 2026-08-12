/*
 * Village billing: periods, per-type frequency, and per-village settings.
 *
 * Part 1 of the billing work. It adds the schema the rest depends on and does
 * NOT change any existing row's meaning — the backfill only fills the new
 * columns from each row's own pay_date.
 *
 *
 * WHY THIS IS NEEDED
 * ------------------
 * house_tax_receipt records no period. It has pay_date — the day the bill was
 * generated — and nothing that says which month or year the bill is *for*. So
 * the system cannot answer either of the two questions billing turns on:
 *
 *     "has this year's property tax been raised for house 3?"
 *     "has December's water charge been raised for house 3?"
 *
 * Property tax is charged yearly and water/waste monthly, and without a period
 * column that distinction cannot be expressed at all. The duplicate guard
 * added in FIX_village_bill_gen_and_pending.sql is the visible symptom: it
 * skips a house that has *any* unpaid bill of that type, which is right for a
 * yearly charge but wrong for a monthly one — December's water bill would
 * never be raised while November's sat unpaid.
 *
 *
 * WHAT IT ADDS
 * ------------
 *   house_tax_receipt.bill_month   1-12, NULL for a yearly charge
 *   house_tax_receipt.bill_year    the year the charge is for
 *   Village_payment_type.frequency 'Y' or 'M' — how often this type is raised
 *   village_setting                one row per village: generation and interest
 *
 * Property Tax is marked yearly; Water and Waste monthly. A new payment type
 * added later carries its own frequency, so nothing has to be special-cased.
 *
 *
 * THE BACKFILL
 * ------------
 * Existing rows get bill_year from pay_date, and bill_month from pay_date for
 * monthly types only. That is a reading of the data, not a fact recorded at the
 * time — the true period was never stored. It is right for the rows here: the
 * generated months (Oct/Nov/Dec 2025) line up with their pay_date, and the two
 * property-tax runs (Dec 2024, Oct 2025) read as the 2024 and 2025 charges.
 *
 * Duplicates are NOT touched. There are 12 pairs where the same house, type
 * and date appear twice — a bill raised twice on one day. Removing them is a
 * money decision, so it is left for a separate script once you have looked at
 * them. The verification at the end lists them.
 *
 *
 * SETTINGS DEFAULTS, and why
 * --------------------------
 *   auto_bill_generation = 0    off, so nothing is raised until you switch it
 *                               on deliberately after testing
 *   property_tax_month   = 4    April — the financial year a gram panchayat
 *                               works to
 *   bill_gen_day         = 1    first of the month
 *   due_days             = 30
 *   interest_rate        = 0    off until you set a rate
 *   interest_after_days  = 30   counted from the due date
 *
 * All of them are editable from the Village Settings page.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ---------------------------------------------- 1. the period columns */

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

/* ------------------------------------------ 2. per-type frequency */

IF COL_LENGTH('dbo.Village_payment_type', 'frequency') IS NULL
BEGIN
    -- 'Y' yearly, 'M' monthly. Defaulted to monthly, then property tax is set
    -- to yearly below, so a type added later is monthly unless said otherwise.
    ALTER TABLE dbo.Village_payment_type ADD frequency CHAR(1) NOT NULL
        CONSTRAINT DF_Village_payment_type_frequency DEFAULT 'M';
    PRINT 'Village_payment_type.frequency added.';
END
ELSE
    PRINT 'Village_payment_type.frequency already present.';
GO

UPDATE dbo.Village_payment_type SET frequency = 'Y' WHERE payment_type = 1 AND frequency <> 'Y';
UPDATE dbo.Village_payment_type SET frequency = 'M' WHERE payment_type IN (2, 3) AND frequency <> 'M';
GO

/* -------------------------------------------------- 3. the backfill */

/*
 * Only rows that have no period yet, so a re-run cannot overwrite a period set
 * deliberately afterwards.
 */
UPDATE r
SET    r.bill_year  = YEAR(r.pay_date),
       r.bill_month = CASE WHEN t.frequency = 'M' THEN MONTH(r.pay_date) END
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
WHERE  r.bill_year IS NULL
  AND  r.pay_date IS NOT NULL;

PRINT 'Existing bills back-filled from pay_date.';
GO

/* ------------------------------------------------ 4. village_setting */

IF OBJECT_ID('dbo.village_setting', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.village_setting (
        village_setting_id   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        /*
         * nvarchar(50), matching house.village_id and house_tax_receipt.
         * village_master declares its own as nvarchar(10), which is the
         * narrowest in the database — the wider column here accepts anything
         * that table can hold, so the INSERT below cannot truncate.
         */
        village_id           NVARCHAR(50) NOT NULL,
        auto_bill_generation BIT           NOT NULL CONSTRAINT DF_vs_auto     DEFAULT (0),
        bill_gen_day         TINYINT       NOT NULL CONSTRAINT DF_vs_genday   DEFAULT (1),
        property_tax_month   TINYINT       NOT NULL CONSTRAINT DF_vs_ptmonth  DEFAULT (4),
        due_days             SMALLINT      NOT NULL CONSTRAINT DF_vs_duedays  DEFAULT (30),
        interest_rate        DECIMAL(5,2)  NOT NULL CONSTRAINT DF_vs_intrate  DEFAULT (0),
        interest_after_days  SMALLINT      NOT NULL CONSTRAINT DF_vs_intafter DEFAULT (30),
        active_status        INT           NOT NULL CONSTRAINT DF_vs_active   DEFAULT (0),
        CONSTRAINT UQ_village_setting_village UNIQUE (village_id),
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
 * bill_gen_day is capped at 28 on purpose: a 29th, 30th or 31st would skip
 * February, or a short month, and the bill for that month would never be
 * raised.
 */

-- A default row for every village that does not have one yet.
INSERT INTO dbo.village_setting (village_id)
SELECT v.village_id
FROM   dbo.village_master AS v
WHERE  NOT EXISTS (SELECT 1 FROM dbo.village_setting AS s WHERE s.village_id = v.village_id);

PRINT 'Default settings row ensured for every village.';
GO

/* --------------------------------------------------- 5. the procedure */

IF OBJECT_ID('dbo.sp_village_setting', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_setting;
GO

/*
 * Select and Update, in the shape the other procedures here use: one
 * @operation parameter, named parameters for the rest.
 */
CREATE PROCEDURE dbo.sp_village_setting
    @operation           NVARCHAR(50)  = NULL,
    @village_id          NVARCHAR(50)  = NULL,
    @auto_bill_generation BIT          = NULL,
    @bill_gen_day        TINYINT       = NULL,
    @property_tax_month  TINYINT       = NULL,
    @due_days            SMALLINT      = NULL,
    @interest_rate       DECIMAL(5,2)  = NULL,
    @interest_after_days SMALLINT      = NULL
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
        -- writing NULL over a setting the caller did not mean to change.
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

/* ---------------------------------------------------------- verification */

SELECT payment_type, payment_type_name, frequency
FROM   dbo.Village_payment_type
ORDER  BY payment_type;

SELECT village_id, auto_bill_generation, bill_gen_day, property_tax_month,
       due_days, interest_rate, interest_after_days
FROM   dbo.village_setting
ORDER  BY village_id;

-- Every bill should now carry a period: a year, and a month for monthly types.
SELECT t.payment_type_name, t.frequency,
       COUNT(*)                                              AS bills,
       SUM(CASE WHEN r.bill_year  IS NULL THEN 1 ELSE 0 END) AS missing_year,
       SUM(CASE WHEN t.frequency = 'M' AND r.bill_month IS NULL THEN 1 ELSE 0 END) AS missing_month
FROM   dbo.house_tax_receipt AS r
JOIN   dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
GROUP  BY t.payment_type_name, t.frequency;

/*
 * The 12 duplicate pairs, left in place deliberately — the same house, type
 * and period billed twice. Deleting them changes what people owe, so decide
 * on them before anything is removed.
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
