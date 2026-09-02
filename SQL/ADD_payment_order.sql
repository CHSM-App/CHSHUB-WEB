/*
 * Online payment integrity (Razorpay) — server-authoritative order + receipt binding.
 *
 * The problem
 * -----------
 * The old flow let the client decide the money:
 *   - POST /test/create-order took `amount` from the request body,
 *   - POST /test/verify-payment only string-compared the signature and bound
 *     the payment to nothing,
 *   - POST /insert/AddReceipt took `paid_amount` from the client and settled
 *     bills with it.
 * So a resident could pay Rs.1 and mark a Rs.5000 bill settled, or pay another
 * flat's bill, or replay one payment into many receipts.
 *
 * The fix (this table + proc, plus routes/payments.js)
 * ----------------------------------------------------
 * payment_order records the relationship the server establishes BEFORE money
 * moves: which flat, which resident, which bills, and the amount the SERVER
 * computed from maintenance_cal. Razorpay is then asked for exactly that
 * amount. On the way back, the receipt is created from this row's trusted
 * amount, never from client input.
 *
 * Idempotency / anti-replay:
 *   - razorpay_order_id is UNIQUE here,
 *   - the receipt's transaction_ref (already UNIQUE via UQ_transaction_ref)
 *     holds razorpay_payment_id, so one payment can back at most one receipt,
 *   - mark_paid only moves 'created' -> 'paid', so a second verify/webhook for
 *     the same order is a no-op.
 *
 * This is additive: no existing SP signature changes. Amounts are money, so
 * all comparisons are exact (paise integers here; decimal(10,2) in receipt).
 */
IF OBJECT_ID('dbo.payment_order', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.payment_order (
        payment_order_id    BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        razorpay_order_id   NVARCHAR(64)  NOT NULL,
        razorpay_payment_id NVARCHAR(64)  NULL,
        receipt_id          INT           NULL,
        flat_id             INT           NOT NULL,
        pre_mob             NVARCHAR(50)  NOT NULL,   -- resident who owns the order (from JWT)
        society_id          NVARCHAR(10)  NULL,
        amount_paise        BIGINT        NOT NULL,   -- server-computed; Razorpay charges exactly this
        bill_details        NVARCHAR(20)  NULL,       -- same 20-char cap as receipt.bill_details
        status              NVARCHAR(12)  NOT NULL CONSTRAINT DF_payment_order_status DEFAULT ('created'),
        created_at          DATETIME2(0)  NOT NULL CONSTRAINT DF_payment_order_created DEFAULT (SYSUTCDATETIME()),
        paid_at             DATETIME2(0)  NULL,
        CONSTRAINT UQ_payment_order_rzp_order UNIQUE (razorpay_order_id)
    );
    CREATE INDEX IX_payment_order_status ON dbo.payment_order (status, created_at);
END
GO

IF OBJECT_ID('dbo.sp_payment_order', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_payment_order;
GO

/*
 * Operations
 *   quote      given @flat_id (+ optional @bill_details CSV of bill_no), return
 *              the server-computed { amount, society_id, bill_count } from
 *              maintenance_cal. amount uses the SAME due + tax_interest_amt that
 *              sp_SettleMaintenancePayment settles with, so order == settlement.
 *   create     insert a 'created' order row for a razorpay_order_id.
 *   get        fetch one order row by razorpay_order_id.
 *   mark_paid  move 'created' -> 'paid', binding payment_id + receipt_id.
 *              Returns `updated` (1 = this call claimed it, 0 = already done).
 *   fail       move 'created' -> 'failed'.
 */
CREATE PROCEDURE dbo.sp_payment_order
    @operation           NVARCHAR(20),
    @razorpay_order_id   NVARCHAR(64)  = NULL,
    @razorpay_payment_id NVARCHAR(64)  = NULL,
    @receipt_id          INT           = NULL,
    @flat_id             INT           = NULL,
    @pre_mob             NVARCHAR(50)  = NULL,
    @society_id          NVARCHAR(10)  = NULL,
    @amount_paise        BIGINT        = NULL,
    @bill_details        NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'quote'
    BEGIN
        IF @bill_details IS NULL OR LTRIM(RTRIM(@bill_details)) = ''
            SELECT CONVERT(DECIMAL(10,2), ISNULL(SUM(ISNULL(due,0) + ISNULL(tax_interest_amt,0)), 0)) AS amount,
                   MAX(society_id) AS society_id,
                   COUNT(*)        AS bill_count
              FROM dbo.maintenance_cal
             WHERE flat_id = @flat_id AND due > 0;
        ELSE
            SELECT CONVERT(DECIMAL(10,2), ISNULL(SUM(ISNULL(due,0) + ISNULL(tax_interest_amt,0)), 0)) AS amount,
                   MAX(society_id) AS society_id,
                   COUNT(*)        AS bill_count
              FROM dbo.maintenance_cal
             WHERE flat_id = @flat_id AND due > 0
               AND CAST(bill_no AS NVARCHAR(50)) IN
                   (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@bill_details, ','));
        RETURN;
    END

    IF @operation = 'create'
    BEGIN
        INSERT INTO dbo.payment_order
            (razorpay_order_id, flat_id, pre_mob, society_id, amount_paise, bill_details, status)
        VALUES
            (@razorpay_order_id, @flat_id, @pre_mob, @society_id, @amount_paise, @bill_details, 'created');

        SELECT razorpay_order_id, amount_paise, status
          FROM dbo.payment_order WHERE razorpay_order_id = @razorpay_order_id;
        RETURN;
    END

    IF @operation = 'get'
    BEGIN
        SELECT payment_order_id, razorpay_order_id, razorpay_payment_id, receipt_id,
               flat_id, pre_mob, society_id, amount_paise, bill_details, status, created_at, paid_at
          FROM dbo.payment_order WHERE razorpay_order_id = @razorpay_order_id;
        RETURN;
    END

    IF @operation = 'mark_paid'
    BEGIN
        UPDATE dbo.payment_order
           SET status = 'paid',
               razorpay_payment_id = @razorpay_payment_id,
               receipt_id = @receipt_id,
               paid_at = SYSUTCDATETIME()
         WHERE razorpay_order_id = @razorpay_order_id
           AND status = 'created';
        SELECT @@ROWCOUNT AS updated;
        RETURN;
    END

    IF @operation = 'fail'
    BEGIN
        UPDATE dbo.payment_order
           SET status = 'failed'
         WHERE razorpay_order_id = @razorpay_order_id
           AND status = 'created';
        RETURN;
    END

    RAISERROR('sp_payment_order: unknown @operation "%s"', 16, 1, @operation);
END
GO

/*
 * Reconciliation — read-only. Flags online-payment inconsistencies without
 * touching a single financial row. See docs/PAYMENTS-REMEDIATION.md for the
 * orphan-receipt and duplicate-payment queries that live outside this view.
 */
IF OBJECT_ID('dbo.payment_reconciliation_vw', 'V') IS NOT NULL
    DROP VIEW dbo.payment_reconciliation_vw;
GO
CREATE VIEW dbo.payment_reconciliation_vw AS
SELECT
    po.razorpay_order_id,
    po.razorpay_payment_id,
    po.status,
    po.amount_paise,
    po.receipt_id,
    r.receipt_id      AS receipt_found,
    r.paid_amount     AS receipt_amount,
    r.transaction_ref,
    po.created_at,
    CASE
        WHEN po.status = 'paid'   AND po.receipt_id IS NULL                                   THEN 'paid_without_receipt'
        WHEN po.status = 'paid'   AND r.receipt_id  IS NULL                                   THEN 'receipt_missing'
        WHEN po.status = 'paid'   AND ABS(r.paid_amount - (po.amount_paise / 100.0)) > 0.01   THEN 'amount_mismatch'
        WHEN po.status = 'paid'   AND r.transaction_ref <> po.razorpay_payment_id             THEN 'payment_id_unbound'
        WHEN po.status = 'failed' AND po.receipt_id IS NOT NULL                               THEN 'failed_but_settled'
        WHEN po.status = 'created' AND DATEDIFF(HOUR, po.created_at, SYSUTCDATETIME()) > 24    THEN 'stale_unpaid'
        ELSE 'ok'
    END AS issue
FROM dbo.payment_order po
LEFT JOIN dbo.receipt r ON r.receipt_id = po.receipt_id;
GO
