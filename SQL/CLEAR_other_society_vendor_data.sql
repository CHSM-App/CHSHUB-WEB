/*
 * Remove the vendor data belonging to societies other than C10001.
 *
 * DESTRUCTIVE AND IRREVERSIBLE. Take a database backup first.
 *
 * What this is for
 * ----------------
 * vendor_master carried rows for C10009 and C10013 alongside C10001's own.
 * Those were never visible to C10001 — sp_vendor_bills' vendor_fill has
 * always scoped by society, and the vendor list route now does the same — so
 * nothing here is required to make the app behave. This deletes them because
 * the data is unwanted, not because it is in the way.
 *
 * If C10009 or C10013 are real societies with real books, do not run this.
 * Their bills, approvals and payments go with their vendors.
 *
 * Order matters
 * -------------
 * Children before parents, or the deletes strand rows that nothing points at
 * any more:
 *
 *     vendor_bill_approval   -> keyed by bill_id
 *     vendor_bill_payments   -> keyed by society_id, links bills via bill_details
 *     inventory_master       -> keyed by vendor_bill_id
 *     vendor_bills           -> keyed by society_id
 *     vendor_master          -> keyed by society_id
 *
 * Scoped by society_id throughout, never by a vendor_id list: vendor_bills
 * stores vendor_id as a comma-separated string, so matching on it would need
 * string splitting and would quietly miss multi-vendor rows.
 */

SET NOCOUNT ON;

-- The societies being cleared. Everything below reads from this.
DECLARE @Doomed TABLE (society_id NVARCHAR(10) PRIMARY KEY);
INSERT INTO @Doomed (society_id) VALUES ('C10009'), ('C10013');

/* ---------------------------------------------------------------------------
 * STEP 1 — What will go. Read this before running anything else.
 *
 * Run the file down to the "STOP" marker first, check the numbers, and only
 * then run the deletes.
 * ------------------------------------------------------------------------ */
SELECT 'vendor_master' AS table_name, society_id, COUNT(*) AS rows_to_delete
FROM vendor_master
WHERE society_id IN (SELECT society_id FROM @Doomed)
GROUP BY society_id

UNION ALL

SELECT 'vendor_bills', society_id, COUNT(*)
FROM vendor_bills
WHERE society_id IN (SELECT society_id FROM @Doomed)
GROUP BY society_id

UNION ALL

SELECT 'vendor_bill_payments', society_id, COUNT(*)
FROM vendor_bill_payments
WHERE society_id IN (SELECT society_id FROM @Doomed)
GROUP BY society_id

UNION ALL

SELECT 'vendor_bill_approval', vb.society_id, COUNT(*)
FROM vendor_bill_approval vba
INNER JOIN vendor_bills vb ON vb.bill_id = vba.bill_id
WHERE vb.society_id IN (SELECT society_id FROM @Doomed)
GROUP BY vb.society_id

UNION ALL

SELECT 'inventory_master', vb.society_id, COUNT(*)
FROM inventory_master im
INNER JOIN vendor_bills vb ON vb.bill_id = im.vendor_bill_id
WHERE vb.society_id IN (SELECT society_id FROM @Doomed)
GROUP BY vb.society_id

ORDER BY table_name, society_id;

/* Confirm C10001 is untouched by the filter — this must list only C10001. */
SELECT DISTINCT society_id AS societies_that_survive
FROM vendor_master
WHERE society_id NOT IN (SELECT society_id FROM @Doomed);

GO

/* ===========================================================================
 * STOP.
 *
 * Read the counts above. If they are what you expect, and you have a backup,
 * run the rest of this file.
 * ======================================================================== */

SET NOCOUNT ON;

DECLARE @Doomed TABLE (society_id NVARCHAR(10) PRIMARY KEY);
INSERT INTO @Doomed (society_id) VALUES ('C10009'), ('C10013');

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Approvals. Reached through their bill, which is what carries the
    --    society — vendor_bill_approval has no society_id of its own.
    DELETE vba
    FROM vendor_bill_approval vba
    INNER JOIN vendor_bills vb ON vb.bill_id = vba.bill_id
    WHERE vb.society_id IN (SELECT society_id FROM @Doomed);

    PRINT 'vendor_bill_approval: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 2. Payments. These do carry society_id, so they are matched on it
    --    directly rather than through bill_details, which is a delimited
    --    string and would need splitting.
    DELETE FROM vendor_bill_payments
    WHERE society_id IN (SELECT society_id FROM @Doomed);

    PRINT 'vendor_bill_payments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 3. Inventory raised against those bills. An inventory row outliving its
    --    bill would sit in the stock register with nothing explaining where
    --    it came from.
    DELETE im
    FROM inventory_master im
    INNER JOIN vendor_bills vb ON vb.bill_id = im.vendor_bill_id
    WHERE vb.society_id IN (SELECT society_id FROM @Doomed);

    PRINT 'inventory_master: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 4. The bills themselves.
    DELETE FROM vendor_bills
    WHERE society_id IN (SELECT society_id FROM @Doomed);

    PRINT 'vendor_bills: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    -- 5. The vendors last, once nothing points at them.
    DELETE FROM vendor_master
    WHERE society_id IN (SELECT society_id FROM @Doomed);

    PRINT 'vendor_master: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' deleted';

    COMMIT TRANSACTION;
    PRINT 'Done. All five deletes committed together.';
END TRY
BEGIN CATCH
    -- One transaction for all five: a failure part-way through would
    -- otherwise leave bills whose vendors are gone, or approvals pointing at
    -- bills that no longer exist.
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    PRINT 'Rolled back — nothing was deleted.';
    THROW;
END CATCH;

GO

/* ---------------------------------------------------------------------------
 * STEP 2 — Verify. Every count below should be zero, and C10001's own rows
 * should be exactly what they were before.
 * ------------------------------------------------------------------------ */
SELECT 'vendor_master left'  AS check_name, COUNT(*) AS should_be_zero
FROM vendor_master  WHERE society_id IN ('C10009', 'C10013')
UNION ALL
SELECT 'vendor_bills left',  COUNT(*)
FROM vendor_bills   WHERE society_id IN ('C10009', 'C10013')
UNION ALL
SELECT 'payments left',      COUNT(*)
FROM vendor_bill_payments WHERE society_id IN ('C10009', 'C10013');

/* C10001 should still show its 16 vendors and all of its bills. */
SELECT society_id, COUNT(*) AS vendors FROM vendor_master GROUP BY society_id;
SELECT society_id, COUNT(*) AS bills   FROM vendor_bills  GROUP BY society_id;

/* Any bill left whose vendor is missing — should return nothing at all. */
SELECT vb.bill_id, vb.society_id, vb.bill_number, vb.vendor_id
FROM vendor_bills vb
WHERE vb.service_type <> 0
  AND NOT EXISTS (
      SELECT 1 FROM vendor_master vm
      WHERE vm.vendor_id = TRY_CAST(vb.vendor_id AS INT)
  );
