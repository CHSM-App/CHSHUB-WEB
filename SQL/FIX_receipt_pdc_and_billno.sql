/*
  sp_MaintenanceReceipt — three fixes to GetBills / GetPDCCheque.
  Read-only changes: both actions only SELECT. Nothing else in the proc is touched.

  Verified against Society on winsome before writing:
    - MAX(bill_no) = 1294, max width 4 digits -> every 4-digit bill currently
      renders as 'MBL-2026-00*'
    - pdc_reminder rows carry real che_dep / che_can / active_status values
      (one cheque already has che_dep = 1), so those flags are in live use

  ---------------------------------------------------------------------------
  1. GetBills — BillNo truncation
     RIGHT('000' + CAST(bill_no AS VARCHAR(3)), 3) casts a 4-digit bill_no into
     VARCHAR(3), which SQL Server renders as '*'. Every bill on a flat then shows
     the same 'MBL-2026-00*' and the user cannot tell them apart. Widened to
     VARCHAR(10) with 4-digit padding. Display only -- settlement matches on the
     raw bill_no, which is unchanged.

  2. GetBills — total_amount exposed
     GetBills returns only the outstanding `due`, so a bill of 8792.28 with
     769.23 left shows as a 769.23 bill. Returning total_amount lets the UI show
     "769.23 due of 8,792.28" instead. Additive: existing columns keep their
     names and meaning, so ASP.NET and the CHS app are unaffected.

  3. GetPDCCheque — stop offering a cheque that was already receipted
     The list had no used/cancelled filter, so the same post-dated cheque could
     be selected on receipt after receipt, each one settling bills again.

     NOTE ON che_dep: this deliberately does NOT set or test che_dep. In this
     system che_dep = 1 means the cheque cleared the bank, and it is owned by the
     pdc_clearing flow -- sp_pdc_reminder @operation='save_change_rem' sets it and
     raises its own receipt via sp_receipt. Setting che_dep here would make that
     flow raise a SECOND receipt for the same cheque. Receipting a PDC and
     clearing it are two different events; this filter only suppresses cheques
     that already have a receipt against them.

  ROLLBACK: re-run the original CREATE PROCEDURE body for sp_MaintenanceReceipt
  from SQL/sql_sp.txt (object 28). No data is modified by this script.
*/

USE [Society];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[sp_MaintenanceReceipt]
    @Action NVARCHAR(20),
    @ReceiptID INT = NULL,
    @SocietyID NVARCHAR(10) = NULL,
    @FlatID INT = NULL,
    @owner_id INT = 0,
    @PayMode NVARCHAR(20) = NULL,
    @ChequeNo NVARCHAR(30) = NULL,
    @ChequeDate DATE = NULL,
    @BankName NVARCHAR(100) = NULL,
    @TransactionRef NVARCHAR(100) = NULL,
    @PaidAmount DECIMAL(10,2) = NULL,
    @Remarks NVARCHAR(255) = NULL,
    @Status INT = 1,
    @CreatedBy NVARCHAR(50) = NULL,
    @MaintenanceType NVARCHAR(20) = NULL,
    @bills NVARCHAR(20) = NULL,
    @ReceiptDate SMALLDATETIME = NULL,
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'INSERT'
    BEGIN
        DECLARE @NewReceiptNo NVARCHAR(50);
        DECLARE @NextNum INT;

        SELECT @NextNum = ISNULL(MAX(receipt_id), 0) + 1 FROM dbo.receipt;

        SET @NewReceiptNo = 'RCPT-' + CAST(YEAR(GETDATE()) AS NVARCHAR(4)) + '-' + RIGHT('0000' + CAST(@NextNum AS NVARCHAR(4)), 4);

        IF @ReceiptDate IS NULL
            SET @ReceiptDate = GETDATE();

        INSERT INTO dbo.receipt (
            receipt_id, society_id, flat_id, receipt_no, receipt_date,
            pay_mode, cheque_no, cheque_date, bank_name, transaction_ref,
            bill_details, paid_amount, remarks, status, created_by
        )
        VALUES (
            @NextNum, @SocietyID, @FlatID, @NewReceiptNo, @ReceiptDate,
            @PayMode, @ChequeNo, @ChequeDate, @BankName, @TransactionRef,
            @bills, @PaidAmount, @Remarks, 3, @CreatedBy
        );

        UPDATE notify_status
        SET seen_status = 1
        WHERE user_id = @CreatedBy;

        EXEC sp_SettleMaintenancePayment @ReceiptID = @NextNum;

        SELECT @NextNum AS receipt_id;
    END

    ELSE IF @Action = 'UPDATE'
    BEGIN
        UPDATE dbo.receipt
        SET
            pay_mode = @PayMode,
            cheque_no = @ChequeNo,
            cheque_date = @ChequeDate,
            bank_name = @BankName,
            transaction_ref = @TransactionRef,
            paid_amount = @PaidAmount,
            remarks = @Remarks,
            status = @Status
        WHERE receipt_id = @ReceiptID;
    END

    ELSE IF @Action = 'CANCEL'
    BEGIN
        UPDATE dbo.receipt
        SET status = 2, remarks = ISNULL(@Remarks, 'Cancelled'), cheque_no = NULL
        WHERE receipt_id = @ReceiptID;
    END

    ELSE IF @Action = 'GETRECEIPT'
    BEGIN
        SELECT *
        FROM receipt_search_vw
        WHERE receipt_id = @ReceiptID
        ORDER BY date DESC;
    END

    IF @Action = 'ResidentFill'
    BEGIN
        SELECT flat_id, Name + ' ( ' + Unit + ')' AS resident_name
        FROM owner_search_vw
        WHERE type = 'Owner' AND society_id = @SocietyID
        ORDER BY Name
    END

    IF @Action = 'GetBills'
    BEGIN
        SELECT
            bill_id AS BillId,
            bill_type AS BillType,
            due + tax_interest_amt AS Amount,
            total_amount AS TotalAmount,          -- FIX 2: full bill, so the UI can
                                                  -- show what is outstanding *of* what
            due_date AS DueDate,
            CASE
                WHEN GETDATE() > due_date THEN 'Overdue'
                WHEN total_amount = due THEN 'Pending'
                ELSE 'Partially Paid'
            END AS Status,
            -- FIX 1: VARCHAR(3) truncated any bill_no >= 1000 to '*'
            'MBL-' + CAST(YEAR(gen_date) AS VARCHAR(4)) + '-' +
            RIGHT('0000' + CAST(bill_no AS VARCHAR(10)), 4) AS BillNo,
            bill_no
        FROM maintenance_cal
        WHERE due > 0 AND flat_id = @FlatId
        ORDER BY due_date
    END

    IF @Action = 'GetPDCCheque'
    BEGIN
        SELECT @owner_id = owner_id
        FROM owner_master
        WHERE type = 'Owner' AND flat_id = @FlatId AND society_id = @SocietyID

        -- FIX 3: hide cancelled/deleted cheques, and any cheque that has already
        -- been receipted, so the same PDC cannot settle bills twice.
        SELECT p.pdc_rem_id, p.chqno, p.che_date, p.bank_name, p.che_amount
        FROM pdc_reminder p
        WHERE p.owner_id = @owner_id
          AND ISNULL(p.che_can, 0) = 0
          AND ISNULL(p.active_status, 0) = 0
          AND NOT EXISTS (
                SELECT 1
                FROM dbo.receipt r
                WHERE r.flat_id = @FlatId
                  AND r.pay_mode = 'PDC'
                  AND r.status <> 2                      -- a cancelled receipt frees the cheque
                  AND r.cheque_no = CAST(p.chqno AS NVARCHAR(60))
          )
        ORDER BY p.che_date
    END

    IF @Action = 'Grid_Show'
    BEGIN
        SELECT receipt_id, receipt_no, receipt_date, paid_amount, bill_status,
               ISNULL(transaction_ref, cheque_no) AS transaction_ref,
               name + ' (' + unit + ')' AS owner
        FROM receipt AS r
        INNER JOIN owner_search_vw AS ow ON ow.flat_id = r.flat_id
        INNER JOIN bill_status AS bs ON bs.status_id = r.status
        WHERE ow.type = 'owner' AND r.society_id = @SocietyID
        ORDER BY receipt_date DESC
    END

    IF @Action = 'GetAgm'
    BEGIN
        SELECT SUM(total) AS total, charges, NULL AS gen_date1
        FROM agm_bill_cal
        WHERE gen_date BETWEEN @start_date AND @end_date AND society_id = @SocietyID
        GROUP BY charges;
    END

END;
GO
