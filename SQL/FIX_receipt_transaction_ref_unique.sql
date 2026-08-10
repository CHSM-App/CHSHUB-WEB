/*
  FIX: UQ_transaction_ref blocks every cheque receipt after the first.

  receipt.transaction_ref carries the gateway reference for an online payment,
  and UQ_transaction_ref exists to stop the same gateway transaction being
  recorded twice. It was created as an unfiltered UNIQUE constraint, and SQL
  Server treats NULLs as equal for uniqueness -- so it also allows only ONE row
  in the whole table with transaction_ref IS NULL.

  Cheque and PDC receipts have no gateway reference (neither maintenance_receipt.aspx
  nor the web API collects one), so they insert NULL. The first such receipt
  succeeded; every one since fails with:

      Violation of UNIQUE KEY constraint 'UQ_transaction_ref'.
      The duplicate key value is (<NULL>).

  sp_MaintenanceReceipt's INSERT then aborts, and the sp_SettleMaintenancePayment
  call that follows raises 'Invalid Receipt ID or Missing Bill Details' because
  the receipt row it expects was never written.

  The CHS mobile app never hit this: it pays through Razorpay and always supplies
  an rrn/payment_id, so its refs are non-NULL.

  Replacing the constraint with a filtered unique index keeps the real protection
  (no duplicate gateway reference) and lets any number of cheque receipts carry
  no reference at all.

  Verified before applying, against Society on winsome:
    - 30 receipt rows, 1 with transaction_ref IS NULL
    - 0 duplicate non-NULL transaction_ref values, so the index builds cleanly

  ROLLBACK (restores the previous behaviour exactly):
      DROP INDEX UQ_transaction_ref ON dbo.receipt;
      ALTER TABLE dbo.receipt ADD CONSTRAINT UQ_transaction_ref UNIQUE (transaction_ref);
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;

    -- Guard: refuse to run if duplicate non-NULL refs appeared since verification,
    -- otherwise the CREATE below fails and we would have dropped the constraint.
    IF EXISTS (
        SELECT 1 FROM dbo.receipt
        WHERE transaction_ref IS NOT NULL
        GROUP BY transaction_ref HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR('Duplicate non-NULL transaction_ref values exist; resolve them first.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM sys.key_constraints
               WHERE name = 'UQ_transaction_ref'
                 AND parent_object_id = OBJECT_ID('dbo.receipt'))
        ALTER TABLE dbo.receipt DROP CONSTRAINT UQ_transaction_ref;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE name = 'UQ_transaction_ref'
                     AND object_id = OBJECT_ID('dbo.receipt'))
        CREATE UNIQUE NONCLUSTERED INDEX UQ_transaction_ref
            ON dbo.receipt (transaction_ref)
            WHERE transaction_ref IS NOT NULL;

COMMIT TRANSACTION;
