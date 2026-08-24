/*
 * Empty the vendor module completely — every society, every row.
 *
 * DESTRUCTIVE AND IRREVERSIBLE. Take a database backup first.
 *
 * What this is for
 * ----------------
 * Starting the vendor module from nothing, so what the app does next can be
 * watched from a known empty state. Years of half-finished test rows — blank
 * vendor names, bills raised against vendors that no longer exist, approvals
 * left pending — make it impossible to tell a real fault from old debris.
 *
 * This clears C10001's own 16 vendors and its bills as well as the other
 * societies'. If any of that is real bookkeeping, do not run this: use
 * CLEAR_other_society_vendor_data.sql instead, which leaves C10001 alone.
 *
 * What it does NOT touch
 * ----------------------
 * staff_master, UserLogin, society_master, maintenance charges, resident
 * bills. Only the five vendor tables below are emptied. Staff salary bills
 * live in vendor_bills and so do go, but the staff records themselves stay.
 *
 * Order matters
 * -------------
 * Children before parents:
 *
 *     vendor_bill_approval   -> keyed by bill_id
 *     vendor_bill_payments   -> keyed by society_id
 *     inventory_master       -> keyed by vendor_bill_id
 *     vendor_bills           -> the bills
 *     vendor_master          -> the vendors
 *
 * DELETE, not TRUNCATE: inventory_master holds rows that have nothing to do
 * with vendor bills (stock entered by hand, with vendor_bill_id null), and
 * truncating it would take those too.
 */

SET NOCOUNT ON;

/* ---------------------------------------------------------------------------
 * STEP 1 — What will go. Run this much first and read it.
 * ------------------------------------------------------------------------ */
SELECT 'vendor_master' AS table_name, COUNT(*) AS rows_to_delete FROM vendor_master
UNION ALL
SELECT 'vendor_bills', COUNT(*) FROM vendor_bills
UNION ALL
SELECT 'vendor_bill_payments', COUNT(*) FROM vendor_bill_payments
UNION ALL
SELECT 'vendor_bill_approval', COUNT(*) FROM vendor_bill_approval
UNION ALL
SELECT 'inventory_master (from bills)', COUNT(*)
FROM inventory_master WHERE vendor_bill_id IS NOT NULL AND vendor_bill_id <> 0;

/* Inventory that was NOT raised against a vendor bill. These survive — shown
 * so it is clear what is being kept. */
SELECT COUNT(*) AS inventory_kept
FROM inventory_master
WHERE vendor_bill_id IS NULL OR vendor_bill_id = 0;

GO

/* ===========================================================================
 * STOP.
 *
 * Read the counts above. If you have a backup and still want an empty vendor
 * module, run the rest of this file.
 * ======================================================================== */

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Approvals. No society_id of their own; they hang off a bill, and
    --    every bill is going.
    DELETE FROM vendor_bill_approval;
    PRINT 'vendor_bill_approval: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 2. Payments.
    DELETE FROM vendor_bill_payments;
    PRINT 'vendor_bill_payments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 3. Inventory that a bill created. Stock entered by hand is left alone —
    --    it was never part of the vendor module and has its own history.
    DELETE FROM inventory_master
    WHERE vendor_bill_id IS NOT NULL AND vendor_bill_id <> 0;
    PRINT 'inventory_master: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 4. The bills.
    DELETE FROM vendor_bills;
    PRINT 'vendor_bills: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 5. The vendors.
    DELETE FROM vendor_master;
    PRINT 'vendor_master: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    COMMIT TRANSACTION;
    PRINT 'Done. The vendor module is empty.';
END TRY
BEGIN CATCH
    -- All five in one transaction: a failure part-way through would leave
    -- bills with no vendors, or approvals pointing at bills that are gone.
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT 'Rolled back — nothing was deleted.';
    THROW;
END CATCH;

GO

/* ---------------------------------------------------------------------------
 * STEP 2 — Verify. All five must be zero.
 *
 * Note on ids: sp_vendor_master and sp_vendor_bills both allocate their next
 * id with MAX(id) + 1 rather than an IDENTITY column, so an empty table
 * restarts numbering at 1 on its own. Nothing needs reseeding.
 * ------------------------------------------------------------------------ */
SELECT 'vendor_master' AS table_name, COUNT(*) AS should_be_zero FROM vendor_master
UNION ALL
SELECT 'vendor_bills', COUNT(*) FROM vendor_bills
UNION ALL
SELECT 'vendor_bill_payments', COUNT(*) FROM vendor_bill_payments
UNION ALL
SELECT 'vendor_bill_approval', COUNT(*) FROM vendor_bill_approval
UNION ALL
SELECT 'inventory_master (from bills)', COUNT(*)
FROM inventory_master WHERE vendor_bill_id IS NOT NULL AND vendor_bill_id <> 0;
