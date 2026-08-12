/*
 * One payment, one receipt — listing every bill it settled.
 *
 * Two faults in the same path, both in sp_house_tax_receipt.
 *
 *
 * FAULT 1 — paying a bill wipes its amount
 * ----------------------------------------
 * Update_Payment reads pending_amount from House_wise_payment_vw through a
 * cursor and writes it back into Amount_paid:
 *
 *     select house_receipt_id, pending_amount from House_wise_payment_vw ...
 *     Update house_tax_receipt set amount_paid = @pending_amont ...
 *
 * House_wise_payment_vw now returns pending_amount as "the amount if unpaid,
 * otherwise 0" — the correction that made raised bills show as outstanding. A
 * cursor over a view re-reads the underlying rows as it goes, so the moment a
 * row is marked paid its pending_amount becomes 0, and the write puts 0 into
 * the very column that recorded what was charged.
 *
 * Settling two bills together demonstrates it: both go to payment_status 1
 * with Amount_paid 0. The record of how much was collected is destroyed by
 * collecting it.
 *
 * Fixed by: leaving Amount_paid alone. It already holds the bill's amount —
 * that is what generation wrote — and paying a bill does not change what it
 * was for. Only the status, date, mode and reference are set.
 *
 *
 * FAULT 2 — settling several bills issues several receipts
 * --------------------------------------------------------
 * Each row keeps its own receipt_no, so paying June and July together produces
 * two receipt numbers for one payment. A household handing over 200 gets one
 * piece of paper, not two, and get_receipt_data reads a single
 * house_receipt_id, so a receipt can only ever show one bill.
 *
 * Fixed by:
 *   - Update_Payment stamps every bill in the payment with one receipt_no,
 *     taken from the lowest bill being settled, so the payment has a single
 *     identity.
 *   - get_receipt_data returns every bill carrying that receipt_no rather than
 *     one row, so the receipt can itemise what was paid: period, charge and
 *     amount, and the total across them.
 *
 * Existing rows are not modified.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house_tax_receipt'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house_tax_receipt not found.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%one_receipt_per_payment%'
BEGIN
    PRINT 'sp_house_tax_receipt: already patched - no change made.';
    SET @stop = 1;
END

/* ------------------------------------------------- Update_Payment */

/*
 * A single line: the stored body uses CRLF and a literal written across two
 * lines here would carry whatever this file uses, so matching one line avoids
 * the question.
 */
DECLARE @oldPay NVARCHAR(MAX) = N'DECLARE @housereceipt_id        INT,';

IF @stop = 0 AND CHARINDEX(@oldPay, @body) = 0
BEGIN
    RAISERROR('Could not locate the Update_Payment declarations - apply by hand.', 16, 1);
    SET @stop = 1;
END

/*
 * The cursor is replaced with a set-based update. Nothing in the branch needs
 * row-at-a-time work, and the cursor is what exposed the re-read problem.
 */
DECLARE @newPay NVARCHAR(MAX) = N'/* one_receipt_per_payment */
            DECLARE @ids TABLE (house_receipt_id INT PRIMARY KEY);

            INSERT INTO @ids (house_receipt_id)
            SELECT DISTINCT r.house_receipt_id
            FROM   dbo.house_tax_receipt AS r
            WHERE  r.village_id = @village_id
              AND  r.payment_status = 0
              AND  r.house_receipt_id IN (SELECT value FROM STRING_SPLIT(@all_housereceipt_id, '',''));

            /* One payment, one receipt number: the lowest bill in the payment
               names it, so June and July settled together share an identity
               and the receipt can list both. */
            DECLARE @receipt NVARCHAR(50) =
                (SELECT TOP 1 r.receipt_no FROM dbo.house_tax_receipt AS r
                  JOIN @ids AS i ON i.house_receipt_id = r.house_receipt_id
                 ORDER BY r.house_receipt_id);

            /* Amount_paid is deliberately not written. It already holds what
               the bill was raised for; the old cursor overwrote it with
               pending_amount, which reads 0 once the row is marked paid. */
            UPDATE r
            SET    r.pay_date       = GETDATE(),
                   r.pay_mode       = @pay_mode,
                   r.payment_status = 1,
                   r.chqno          = @chqno,
                   r.chqdate        = @chqdate,
                   r.Transation_ref = @Transation_ref,
                   r.receipt_no     = @receipt
            FROM   dbo.house_tax_receipt AS r
            JOIN   @ids AS i ON i.house_receipt_id = r.house_receipt_id;

            SELECT @receipt AS receipt_no, @@ROWCOUNT AS bills_paid;

            /* The old cursor still follows and still fetches into these; they
               are declared so it compiles, and it reads no rows. */
            DECLARE @unused_housereceipt_id INT, @unused_pending decimal(18,2);

            DECLARE @housereceipt_id        INT,';

IF @stop = 0 SET @body = REPLACE(@body, @oldPay, @newPay);

/*
 * The old cursor body still follows. It is left in place but made harmless:
 * its SELECT is pointed at no rows, so it opens, fetches nothing and closes.
 * Cutting it out would mean matching a long run of whitespace-sensitive text.
 */
DECLARE @oldCur NVARCHAR(MAX) = N'select house_receipt_id,pending_amount from House_wise_payment_vw where house_receipt_id IN (SELECT value';

DECLARE @newCur NVARCHAR(MAX) = N'select house_receipt_id, pending_amount from House_wise_payment_vw where 1 = 0 and house_receipt_id IN (SELECT value';

IF @stop = 0 AND CHARINDEX(@oldCur, @body) = 0
BEGIN
    RAISERROR('Could not locate the payment cursor - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldCur, @newCur);

-- The cursor variables it fetches into are the unused ones declared above.
DECLARE @oldFetch NVARCHAR(MAX) = N'FETCH next FROM bill_paymentt INTO @housereceipt_id, @pending_amont;';
DECLARE @newFetch NVARCHAR(MAX) = N'FETCH next FROM bill_paymentt INTO @unused_housereceipt_id, @unused_pending;';

IF @stop = 0 SET @body = REPLACE(@body, @oldFetch, @newFetch);

DECLARE @oldUpd NVARCHAR(MAX) = N'Update house_tax_receipt set amount_paid=@pending_amont,pay_date=getdate(),pay_mode=@pay_mode, payment_status=1, chqno=@chqno,chqdate=@chqdate,Transation_ref=@Transation_ref WHERE house_receipt_id=@housereceipt_id';
DECLARE @newUpd NVARCHAR(MAX) = N'/* superseded by the set-based update above */';

IF @stop = 0 SET @body = REPLACE(@body, @oldUpd, @newUpd);

/* ------------------------------------------------ get_receipt_data */

/*
 * Read by receipt_no rather than one bill, so a receipt shows everything the
 * payment settled. house_receipt_id still identifies which payment is wanted.
 */
DECLARE @oldRcp NVARCHAR(MAX) = N'dbo.pay_mode ON dbo.house_tax_receipt.pay_mode = dbo.pay_mode.pay_id where payment_status = 1 AND dbo.house_tax_receipt.house_receipt_id = @house_receipt_id';

DECLARE @newRcp NVARCHAR(MAX) = N'dbo.pay_mode ON dbo.house_tax_receipt.pay_mode = dbo.pay_mode.pay_id where payment_status = 1 AND dbo.house_tax_receipt.receipt_no = (SELECT receipt_no FROM dbo.house_tax_receipt WHERE house_receipt_id = @house_receipt_id) AND dbo.house_tax_receipt.house_id = (SELECT house_id FROM dbo.house_tax_receipt WHERE house_receipt_id = @house_receipt_id) ORDER BY dbo.house_tax_receipt.house_receipt_id';

IF @stop = 0 AND CHARINDEX(@oldRcp, @body) = 0
BEGIN
    RAISERROR('Could not locate get_receipt_data - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldRcp, @newRcp);

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_house_tax_receipt: one receipt per payment, and amounts are no longer wiped.';
END
GO

/* ---------------------------------------------------------- verification */

SELECT COUNT(*) AS paid_bills,
       SUM(CASE WHEN ISNULL(Amount_paid, 0) = 0 THEN 1 ELSE 0 END) AS lost_their_amount
FROM   dbo.house_tax_receipt
WHERE  payment_status = 1;
GO
