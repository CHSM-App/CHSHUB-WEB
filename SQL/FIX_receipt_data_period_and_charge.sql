/*
 * A receipt must name the period and the charge it settled.
 *
 * The problem
 * -----------
 * The receipt lists the bills a payment covered, but the Period column is
 * blank and the charge shows nothing. get_receipt_data returns:
 *
 *     address, name, pre_mob, house_receipt_id, receipt_no, house_id,
 *     payment_type, pay_date, Transation_ref, Amount_paid, chqdate, chqno,
 *     village_id, house_no, pay_mode
 *
 * payment_type is the number, not the name, and there is no bill_month or
 * bill_year at all — so nothing on the receipt can say "June 2026, Water
 * Charges". The columns were never selected because a receipt only ever showed
 * one bill and its type was assumed known.
 *
 * The fix
 * -------
 * Three columns added to the projection:
 *
 *   payment_type_name   the charge's name, joined from Village_payment_type
 *   Month               the month the bill covers, or blank for a yearly
 *                       charge, which belongs to the year rather than a month
 *   year                the year the bill covers
 *
 * Named to match House_wise_payment_vw, which the pending list already reads,
 * so the receipt and the pending screen describe a period the same way.
 *
 * Nothing is removed or renamed, so anything selecting the existing columns is
 * unaffected.
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

IF @stop = 0 AND @body LIKE '%receipt_period_named%'
BEGIN
    PRINT 'sp_house_tax_receipt: get_receipt_data already names the period.';
    SET @stop = 1;
END

/* -------------------------------------------- the projection */

/*
 * Single-line anchors throughout. The stored body uses CRLF, and a literal
 * written across two lines here would carry whatever this file uses — the
 * mismatch that made an earlier version of this script find nothing.
 *
 * This text appears twice, in get_receipt_data and Grid_paid_charges, so it is
 * rewritten by position: the one that follows the get_receipt_data marker.
 */
DECLARE @oldCols NVARCHAR(MAX) =
    N'dbo.house_owner.village_id, dbo.house.house_no, dbo.pay_mode.pay_mode';

DECLARE @newCols NVARCHAR(MAX) =
    N'dbo.house_owner.village_id, dbo.house.house_no, dbo.pay_mode.pay_mode, ' +
    N'/* receipt_period_named */ dbo.Village_payment_type.payment_type_name, ' +
    N'CASE WHEN dbo.house_tax_receipt.bill_month IS NOT NULL ' +
    N'THEN DATENAME(MONTH, DATEFROMPARTS(2000, dbo.house_tax_receipt.bill_month, 1)) ' +
    -- A yearly charge covers the year; naming a month would misdescribe it.
    N'ELSE '''' END AS Month, ' +
    N'ISNULL(dbo.house_tax_receipt.bill_year, YEAR(dbo.house_tax_receipt.pay_date)) AS year';

/*
 * Only the occurrence inside get_receipt_data. Grid_paid_charges was rewritten
 * by an earlier script and groups by receipt; rewriting its projection too
 * would break that grouping.
 */
DECLARE @branchAt INT = CASE WHEN @stop = 0
                             THEN CHARINDEX(N'If @operation = ''get_receipt_data''', @body)
                             ELSE 0 END;

IF @stop = 0 AND @branchAt = 0
BEGIN
    RAISERROR('Could not locate the get_receipt_data branch - apply by hand.', 16, 1);
    SET @stop = 1;
END

DECLARE @colsAt INT = CASE WHEN @stop = 0
                           THEN CHARINDEX(@oldCols, @body, @branchAt)
                           ELSE 0 END;

IF @stop = 0 AND @colsAt = 0
BEGIN
    RAISERROR('Could not locate the get_receipt_data projection - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = STUFF(@body, @colsAt, LEN(@oldCols), @newCols);

/* -------------------------------------------- the join it needs */

DECLARE @oldJoin NVARCHAR(MAX) =
    N'dbo.pay_mode ON dbo.house_tax_receipt.pay_mode = dbo.pay_mode.pay_id where payment_status = 1 AND dbo.house_tax_receipt.receipt_no';

DECLARE @newJoin NVARCHAR(MAX) =
    N'dbo.pay_mode ON dbo.house_tax_receipt.pay_mode = dbo.pay_mode.pay_id INNER JOIN
                  dbo.Village_payment_type ON dbo.house_tax_receipt.payment_type = dbo.Village_payment_type.payment_type where payment_status = 1 AND dbo.house_tax_receipt.receipt_no';

IF @stop = 0 AND CHARINDEX(@oldJoin, @body) = 0
BEGIN
    RAISERROR('Could not locate the get_receipt_data joins - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldJoin, @newJoin);

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_house_tax_receipt: get_receipt_data now returns the period and charge name.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * A payment that settled two bills should come back as two rows, each naming
 * its own month and charge.
 */
DECLARE @id INT = (
    SELECT TOP 1 MIN(house_receipt_id)
    FROM   dbo.house_tax_receipt
    WHERE  payment_status = 1
    GROUP  BY receipt_no, house_id
    ORDER  BY COUNT(*) DESC
);

EXEC dbo.sp_house_tax_receipt @operation = 'get_receipt_data', @house_receipt_id = @id;
GO
