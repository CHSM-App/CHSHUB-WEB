/*
 * ADD: which officers sign a society's NOC certificate.
 *
 * Why a setting
 * -------------
 * The certificate carries signature lines for the secretary and the chairman,
 * because that is what most societies use. But how many officers sign, and
 * what they are called, is each society's own rule — set by its bye-laws and
 * by whoever is being asked to act on the certificate. One society signs with
 * both, another with the secretary alone, and a third calls its chairman the
 * President.
 *
 * This is a multi-society product, so none of that can be hard-coded. A sheet
 * printing a line for an officer who does not sign leaves a blank the member
 * is asked about at the bank; a sheet missing a line for one who does means
 * reprinting the letter.
 *
 * Where it lives
 * --------------
 * On account_setting, the society's existing one-row-per-society settings
 * table, rather than a new table of its own. It is read on the same screen the
 * secretary already opens to configure the society, and a table holding one
 * more column costs nothing next to a second table to join, migrate and keep
 * in step.
 *
 * Defaults
 * --------
 * 'Both', 'Secretary' and 'Chairman' — what the certificate already prints, so
 * running this changes nothing for a society that never opens the setting.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.account_setting', 'noc_signatories') IS NULL
BEGIN
    -- 'Both', 'Secretary' or 'Chairman'. Text rather than a lookup table: the
    -- set is fixed by the app and a society cannot add to it.
    ALTER TABLE dbo.account_setting
        ADD noc_signatories NVARCHAR(20) NULL;

    PRINT 'account_setting.noc_signatories added.';
END
ELSE
    PRINT 'account_setting.noc_signatories already exists - no change made.';
GO

IF COL_LENGTH('dbo.account_setting', 'noc_secretary_label') IS NULL
BEGIN
    -- What the first signing officer is called on the letter. Societies
    -- differ: "Secretary", "Hon. Secretary", "Secretary / Manager".
    ALTER TABLE dbo.account_setting
        ADD noc_secretary_label NVARCHAR(60) NULL;

    PRINT 'account_setting.noc_secretary_label added.';
END
ELSE
    PRINT 'account_setting.noc_secretary_label already exists - no change made.';
GO

IF COL_LENGTH('dbo.account_setting', 'noc_chairman_label') IS NULL
BEGIN
    -- The second officer, commonly "Chairman" but often "President".
    ALTER TABLE dbo.account_setting
        ADD noc_chairman_label NVARCHAR(60) NULL;

    PRINT 'account_setting.noc_chairman_label added.';
END
ELSE
    PRINT 'account_setting.noc_chairman_label already exists - no change made.';
GO

/*
 * sp_account_setting — the three new parameters.
 *
 * Only the 'Insert' branch writes them, which is the branch the website's save
 * calls. The older 'Update' branch is left alone: it is called by code that
 * knows nothing about these columns, and adding them there would have those
 * callers blank a society's signatory setting every time they saved a toggle.
 *
 * All three default to NULL meaning "leave unchanged", the same convention
 * @interest_rate already uses here, so a caller that does not send them cannot
 * reset what the society chose.
 *
 * Everything else is unchanged; the body is restated because ALTER PROCEDURE
 * has to carry the whole thing.
 */
ALTER PROCEDURE [dbo].[sp_account_setting]
@operation nvarchar(50)=null,
@acc_set_id int =0,
@society_id nvarchar(10)=null,
@mem_open_bal int=0,
@mem_charge_btn int=0,
@mem_charge_allocation int=0,
@receipt_btn int=0,
@bill_gen_btn int=0,
@gst_round int=0,
@charge_round int=0,
@payment_voucher int=0,
@debit_note_voucher int=0,
@credit_note_voucher int=0,
@general_voucher int=0,
@receipt_voucher int=0,
@build_wise_payment int=0,
@remainder_email_dues int=0,
@rate_per_sqf decimal(10, 2) = null,
@two_w_rate decimal(10, 2) = null,
@four_w_rate decimal(10, 2) = null,
@auto_bill_generation bit = false,
@bill_gen_date int = 0,
@bill_due_period int  = 0,
-- NULL mhanje "badalu naka" -- juna dar tasach rahto. Junya call sites la
-- ha parameter mahit nahi, tyanni chukun vyaj badalu naye mhanun.
@interest_rate decimal(18,2) = NULL,
-- Same rule: NULL leaves the society's choice alone.
@noc_signatories nvarchar(20) = NULL,
@noc_secretary_label nvarchar(60) = NULL,
@noc_chairman_label nvarchar(60) = NULL

AS
BEGIN

	If @operation='Update'
	Begin
 	select @acc_set_id=acc_set_id from account_setting where acc_set_id=@acc_set_id

	     if @acc_set_id=0
	       Begin
		   INSERT INTO account_setting(mem_open_bal,mem_charge_btn,mem_charge_allocation,receipt_btn,gst_round,charge_round,payment_voucher,debit_note_voucher,credit_note_voucher,general_voucher,receipt_voucher,build_wise_payment,remainder_email_dues,society_id,rate_per_sqfeet,two_wheeler_rate,four_wheeler_rate)values
		   (@mem_open_bal,@mem_charge_btn,@mem_charge_allocation,@receipt_btn,@gst_round,@charge_round,@payment_voucher,@debit_note_voucher,@credit_note_voucher,@general_voucher,@receipt_voucher,@build_wise_payment,@remainder_email_dues,@society_id,@rate_per_sqf,@two_w_rate,@four_w_rate)
	      End
         Else
		   Begin
		   Update account_setting set mem_open_bal=@mem_open_bal,mem_charge_btn=@mem_charge_btn,mem_charge_allocation=@mem_charge_allocation,receipt_btn=@receipt_btn,gst_round=@gst_round,charge_round=@charge_round,payment_voucher=@payment_voucher, rate_per_sqfeet=@rate_per_sqf,two_wheeler_rate=@two_w_rate,four_wheeler_rate=@four_w_rate, debit_note_voucher=@debit_note_voucher,credit_note_voucher=@credit_note_voucher,general_voucher=@general_voucher,receipt_voucher=@receipt_voucher,build_wise_payment=@build_wise_payment,remainder_email_dues=@remainder_email_dues,society_id=@society_id where acc_set_id=@acc_set_id
		   End
	End
	If @operation='select'
	   Begin
	      SELECT * from account_setting where society_id=@society_id
    	End
	If @operation='Delete'
	   Begin
	      Delete from account_setting where acc_set_id=@acc_set_id
    	End
	If @operation='getcode'
	   Begin
	      SELECT * from account_setting where society_id=@society_id
    	End


	 IF @operation = 'Insert'
BEGIN
    IF EXISTS (SELECT 1 FROM account_setting WHERE society_id = @society_id)
    BEGIN
        UPDATE account_setting
        SET
            rate_per_sqfeet = @rate_per_sqf,
            two_wheeler_rate = @two_w_rate,
            four_wheeler_rate = @four_w_rate,
            auto_bill_generation = @auto_bill_generation,
            bill_gen_date = @bill_gen_date,
            bill_due_period = @bill_due_period,
            interest_rate = ISNULL(@interest_rate, interest_rate),
            noc_signatories = ISNULL(@noc_signatories, noc_signatories),
            noc_secretary_label = ISNULL(@noc_secretary_label, noc_secretary_label),
            noc_chairman_label = ISNULL(@noc_chairman_label, noc_chairman_label)
        WHERE society_id = @society_id;
    END
    ELSE
    BEGIN
        INSERT INTO account_setting
        (
            society_id,
            rate_per_sqfeet,
            two_wheeler_rate,
            four_wheeler_rate,
            auto_bill_generation,
            bill_gen_date,
            bill_due_period,
			interest_rate,
            noc_signatories,
            noc_secretary_label,
            noc_chairman_label
        )
        VALUES
        (
            @society_id,
            @rate_per_sqf,
            @two_w_rate,
            @four_w_rate,
            @auto_bill_generation,
            @bill_gen_date,
            @bill_due_period,
			ISNULL(@interest_rate, 21),
            -- A society that has never opened the setting gets what the
            -- certificate already printed.
            ISNULL(@noc_signatories, 'Both'),
            ISNULL(@noc_secretary_label, 'Secretary'),
            ISNULL(@noc_chairman_label, 'Chairman')
        );
    END
END


END
GO

PRINT 'sp_account_setting updated.';
GO
