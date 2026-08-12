/*
 * The Paid Bills tab lists receipts, not the bills inside them.
 *
 * The problem
 * -----------
 * Settling June and July together now writes one receipt number across both
 * bills — the payment has a single identity, as it should. But Grid_paid_charges
 * returns a row per bill, so that one payment still appears twice:
 *
 *     2062   102   Water Charges   150
 *     2062   102   Water Charges   150
 *
 * Two lines, the same receipt number, and a total that has to be added up by
 * eye. A payment is one event; the list of payments should show it once.
 *
 * The fix
 * -------
 * Group by receipt_no and house, so each payment is one row carrying what it
 * came to and how many bills it covered:
 *
 *     receipt_no, house, owner, pay_date, pay_mode
 *     bills_paid   how many bills the payment settled
 *     charges      the charge names, comma-separated
 *     Amount_paid  the total across them
 *
 * Amount_paid keeps its name because the screen and the exports already read
 * it; it now means the payment's total rather than one bill's share.
 *
 * house_receipt_id is the lowest id in the payment, so opening a receipt from
 * the list still resolves — get_receipt_data looks the payment up by that id
 * and returns every bill under it.
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

IF @stop = 0 AND @body LIKE '%paid_grouped_by_receipt%'
BEGIN
    PRINT 'sp_house_tax_receipt: Paid Bills already grouped - no change made.';
    SET @stop = 1;
END

/*
 * Matched from the branch's SELECT to the end of its WHERE. Anchored on two
 * short single-line fragments rather than the whole block: the stored body
 * uses CRLF and mixes tabs with spaces, so a long literal would not match.
 */
DECLARE @from INT = CASE WHEN @stop = 0
                         THEN CHARINDEX(N'If @operation=''Grid_paid_charges''', @body)
                         ELSE 0 END;

IF @stop = 0 AND @from = 0
BEGIN
    RAISERROR('Could not locate the Grid_paid_charges branch - apply by hand.', 16, 1);
    SET @stop = 1;
END

-- The branch runs to the next one; get_receipt_data follows it.
DECLARE @to INT = CASE WHEN @stop = 0
                       THEN CHARINDEX(N'If @operation = ''get_receipt_data''', @body, @from)
                       ELSE 0 END;

IF @stop = 0 AND @to = 0
BEGIN
    RAISERROR('Could not locate the end of Grid_paid_charges - apply by hand.', 16, 1);
    SET @stop = 1;
END

DECLARE @new NVARCHAR(MAX) = N'If @operation=''Grid_paid_charges''
	Begin
	  /* paid_grouped_by_receipt — one row per payment, not per bill. Settling
	     June and July together shares a receipt number, and this listed that
	     one payment twice. */
	SELECT   MIN(dbo.house_owner.address)                       AS address,
	         MIN(dbo.house_owner.name)                          AS name,
	         MIN(dbo.house_owner.pre_mob)                       AS pre_mob,
	         MIN(dbo.house_tax_receipt.house_receipt_id)        AS house_receipt_id,
	         dbo.house_tax_receipt.receipt_no,
	         dbo.house_tax_receipt.house_id,
	         MIN(dbo.house_tax_receipt.payment_type)            AS payment_type,
	         MAX(dbo.house_tax_receipt.pay_date)                AS pay_date,
	         SUM(dbo.house_tax_receipt.Amount_paid)             AS Amount_paid,
	         MAX(dbo.house_tax_receipt.chqdate)                 AS chqdate,
	         MAX(dbo.house_tax_receipt.chqno)                   AS chqno,
	         MIN(dbo.house_owner.village_id)                    AS village_id,
	         MIN(dbo.house.house_no)                            AS house_no,
	         MIN(dbo.pay_mode.pay_mode)                         AS pay_mode,
	         COUNT(*)                                           AS bills_paid,
	         /* The charges the payment covered, so one line still says what was
	            settled. */
	         STUFF((SELECT DISTINCT '', '' + t2.payment_type_name
	                FROM   dbo.house_tax_receipt AS r2
	                JOIN   dbo.Village_payment_type AS t2 ON t2.payment_type = r2.payment_type
	                WHERE  r2.receipt_no = dbo.house_tax_receipt.receipt_no
	                  AND  r2.house_id   = dbo.house_tax_receipt.house_id
	                  AND  r2.payment_status = 1
	                FOR XML PATH('''')), 1, 2, '''')          AS payment_type_name
	FROM     dbo.house_owner INNER JOIN
	         dbo.house_tax_receipt ON dbo.house_owner.house_id = dbo.house_tax_receipt.house_id INNER JOIN
	         dbo.house ON dbo.house_tax_receipt.house_id = dbo.house.house_id INNER JOIN
	         dbo.pay_mode ON dbo.house_tax_receipt.pay_mode = dbo.pay_mode.pay_id INNER JOIN
	         dbo.Village_payment_type ON dbo.house_tax_receipt.payment_type = dbo.Village_payment_type.payment_type
	WHERE    (dbo.house_tax_receipt.payment_status = 1) AND dbo.house_owner.village_id = @village_id
	GROUP BY dbo.house_tax_receipt.receipt_no, dbo.house_tax_receipt.house_id

	End

	';

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, @from, @to - @from, @new);
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_house_tax_receipt: Paid Bills now lists one row per payment.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * A payment that settled two bills should appear once, with bills_paid = 2 and
 * the total across them.
 */
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC dbo.sp_house_tax_receipt @operation = 'Grid_paid_charges', @village_id = @v;
GO
