/*
 * A rejected vendor bill comes back approved.
 *
 * The bug
 * -------
 * Reject a vendor bill and it lands in the grid as Approved. With a single
 * approver on the bill it happens every time; with several it happens as soon
 * as the last of them answers.
 *
 * sp_vendor_bills @operation = 'UPDATE_STATUS' writes the approver's own row
 * and then runs two blocks in sequence:
 *
 *     IF @status = 4
 *     BEGIN
 *         UPDATE vendor_bills SET status = 4 WHERE bill_id = @bill_id;
 *     END
 *
 *     IF NOT EXISTS (SELECT 1 FROM vendor_bill_approval
 *                    WHERE approval_status = 1 AND bill_id = @bill_id)
 *     BEGIN
 *         UPDATE vendor_bills SET status = 2 WHERE bill_id = @bill_id;
 *     END
 *
 * The first block has no ELSE, so both run. A rejection sets the bill to 4,
 * and the second block then asks "is anyone still pending?" — nobody is, the
 * rejecter was the last to answer — and overwrites it with 2. The rejection is
 * recorded on the approval row and lost on the bill.
 *
 * The second block is wrong on its own terms too. It tests for "everyone has
 * answered", not "everyone said yes": approval_status = 1 is Pending, so a row
 * sitting at 4 (Rejected) does not match and the bill is treated as fully
 * approved. Three approvers where the first rejects and the other two approve
 * ends up Approved — the rejection is outvoted, which is not how this is meant
 * to work. One rejection stops the bill.
 *
 * The fix
 * -------
 * Two changes to that pair of blocks:
 *
 *   1. ELSE IF, so a rejection ends the decision rather than falling through
 *      into the approve test.
 *
 *   2. `approval_status <> 2` in place of `= 1`, so the test reads "every
 *      approver has approved" rather than "nobody is still pending". A row at
 *      4 now blocks approval instead of being invisible to it.
 *
 * Both are needed. ELSE alone still lets a later approver's call — which
 * arrives with @status = 2 and so skips the first block entirely — approve a
 * bill that someone has already rejected.
 *
 * Everything else in the procedure is unchanged; it is reproduced below
 * because ALTER PROCEDURE has to restate the whole body.
 *
 * Status codes, from bill_status: 1 Pending, 2 Approved, 3 Paid, 4 Rejected.
 * vendor_bill_approval.approval_status uses the same three: 1 Pending,
 * 2 Approved, 4 Rejected.
 */

/* ---------------------------------------------------------------------------
 * Before running: what the fix will change
 *
 * Bills marked Approved that in fact carry a rejection. Review these — the
 * procedure fix does not correct rows already written.
 * ------------------------------------------------------------------------ */
SELECT
    vb.bill_id,
    vb.society_id,
    vb.bill_number,
    vb.bill_date,
    vb.total_amount,
    vb.status                AS bill_status_code,
    bs.bill_status           AS bill_status_now,
    rejections.rejected_by,
    rejections.rejected_on
FROM vendor_bills vb
INNER JOIN bill_status bs ON bs.status_id = vb.status
CROSS APPLY (
    SELECT
        STRING_AGG(ul.name, ', ') AS rejected_by,
        MAX(vba.approval_date)    AS rejected_on
    FROM vendor_bill_approval vba
    INNER JOIN UserLogin ul ON ul.user_id = vba.user_id
    WHERE vba.bill_id = vb.bill_id
      AND vba.approval_status = 4
) rejections
WHERE vb.status = 2                    -- the bill says Approved
  AND rejections.rejected_by IS NOT NULL   -- but somebody rejected it
ORDER BY vb.bill_id DESC;
GO

/* To correct those bills, run this after the procedure is altered. Left
 * commented out: it changes financial records, so it should be run only once
 * the list above has been read and agreed.
 *
 * UPDATE vb
 * SET vb.status = 4,
 *     vb.updated_date = GETDATE()
 * FROM vendor_bills vb
 * WHERE vb.status = 2
 *   AND EXISTS (
 *       SELECT 1 FROM vendor_bill_approval vba
 *       WHERE vba.bill_id = vb.bill_id AND vba.approval_status = 4
 *   );
 */

ALTER PROCEDURE [dbo].[sp_vendor_bills]
    @operation NVARCHAR(20),                 -- INSERT, UPDATE, DELETE, VIEW, VIEWBYID, APPROVE, REJECT, PAY
    @bill_id INT = 0,
    @society_id NVARCHAR(10) = NULL,
    @bill_number NVARCHAR(50) = NULL,
    @bill_date DATE = NULL,
    @vendor_id NVARCHAR(50) = NULL,
    @subtotal DECIMAL(12,2) = 0,
    @tax_amount DECIMAL(12,2) = 0,
    @total_amount DECIMAL(12,2) = 0,
    @status INT = NULL,
    @user_id INT = 0,
    @notes NVARCHAR(500) = NULL,
    @created_by INT = 0,
    @result NVARCHAR(200) = NULL,
    @service INT = NULL,
    @desc NVARCHAR(MAX) = NULL,
    @approval_id INT = 0,
    @salary NVARCHAR(MAX) = NULL,
    @bill_details NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------
    -- INSERT
    --------------------------------------------------
    IF UPPER(@operation) = 'INSERT'
    BEGIN
        -- CHECK IF ANY STAFF MEMBER ALREADY HAS SALARY BILL FOR THIS MONTH
        IF @service = 0 -- Staff Payment
        BEGIN
            DECLARE @MonthName NVARCHAR(20);
            DECLARE @YearValue INT;
            DECLARE @DuplicateStaffNames NVARCHAR(MAX) = '';
            DECLARE @DuplicateBillNumbers NVARCHAR(MAX) = '';

            SET @MonthName = DATENAME(MONTH, @bill_date);
            SET @YearValue = YEAR(@bill_date);

            -- Check each staff ID in the comma-separated list
            DECLARE @StaffId INT;
            DECLARE @CurrentStaffIds TABLE (staff_id INT);

            -- Split the comma-separated staff IDs
            INSERT INTO @CurrentStaffIds (staff_id)
            SELECT CAST(value AS INT)
            FROM STRING_SPLIT(@vendor_id, ',')
            WHERE RTRIM(value) <> '';

            -- Check for duplicates for each staff member
            DECLARE staff_cursor CURSOR FOR
            SELECT staff_id FROM @CurrentStaffIds;

            OPEN staff_cursor;
            FETCH NEXT FROM staff_cursor INTO @StaffId;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Check if this staff member already has a bill for this month
                IF EXISTS (
                    SELECT 1
                    FROM vendor_bills vb
                    WHERE vb.society_id = @society_id
                      AND vb.service_type = 0
                      AND YEAR(vb.bill_date) = @YearValue
                      AND MONTH(vb.bill_date) = MONTH(@bill_date)
                      AND vb.status <> 4 -- Exclude rejected bills
                      AND EXISTS (
                          SELECT 1
                          FROM STRING_SPLIT(vb.vendor_id, ',')
                          WHERE CAST(value AS INT) = @StaffId
                      )
                )
                BEGIN
                    -- Get staff name and existing bill number
                    DECLARE @StaffName NVARCHAR(100);
                    DECLARE @ExistingBillNo NVARCHAR(50);

                    SELECT TOP 1
                        @StaffName = sm.name,
                        @ExistingBillNo = vb.bill_number
                    FROM vendor_bills vb
                    INNER JOIN staff_master sm ON sm.staff_id = @StaffId
                    WHERE vb.society_id = @society_id
                      AND vb.service_type = 0
                      AND YEAR(vb.bill_date) = @YearValue
                      AND MONTH(vb.bill_date) = MONTH(@bill_date)
                      AND vb.status <> 4
                      AND EXISTS (
                          SELECT 1
                          FROM STRING_SPLIT(vb.vendor_id, ',')
                          WHERE CAST(value AS INT) = @StaffId
                      );

                    -- Add to duplicate list
                    IF @DuplicateStaffNames = ''
                    BEGIN
                        SET @DuplicateStaffNames = @StaffName;
                        SET @DuplicateBillNumbers = @ExistingBillNo;
                    END
                    ELSE
                    BEGIN
                        SET @DuplicateStaffNames = @DuplicateStaffNames + ', ' + @StaffName;
                        SET @DuplicateBillNumbers = @DuplicateBillNumbers + ', ' + @ExistingBillNo;
                    END
                END

                FETCH NEXT FROM staff_cursor INTO @StaffId;
            END

            CLOSE staff_cursor;
            DEALLOCATE staff_cursor;

            -- If duplicates found, return error
            IF @DuplicateStaffNames <> ''
            BEGIN
                SELECT
                    bill_id = -1,
                    error_message = 'Salary already paid for ' + @MonthName + ' ' + CAST(@YearValue AS VARCHAR) +
                                    ' to: ' + @DuplicateStaffNames +
                                    ' (Bill: ' + @DuplicateBillNumbers + ')',
                    duplicate_staff = @DuplicateStaffNames,
                    existing_bill_numbers = @DuplicateBillNumbers;
                RETURN;
            END
        END

        -- PROCEED WITH INSERT IF NO DUPLICATE
        DECLARE @NewBillId INT;
        SET @NewBillId = (SELECT ISNULL(MAX(bill_id), 0) + 1 FROM vendor_bills);

        INSERT INTO dbo.vendor_bills
        (
            bill_id,
            society_id,
            bill_number,
            bill_date,
            vendor_id,
            subtotal,
            tax_amount,
            total_amount,
            status,
            notes,
            created_date,
            created_by,
            service_type,
            description,
            due
        )
        VALUES
        (
            @NewBillId,
            @society_id,
            @bill_number,
            @bill_date,
            @vendor_id,
            @subtotal,
            @tax_amount,
            @total_amount,
            ISNULL(@status, 1),
            @notes,
            GETDATE(),
            @created_by,
            @service,
            @desc,
            @total_amount
        );

        -- Return success with new bill ID
        SELECT
            bill_id = @NewBillId,
            error_message = NULL,
            duplicate_staff = NULL,
            existing_bill_numbers = NULL;

        RETURN;
    END;

    --------------------------------------------------
    -- Get Charges for Maintenance Bill
    --------------------------------------------------
    IF @operation = 'exfetch'
    BEGIN
        SELECT *
        FROM maintenance_charges
        WHERE charges_type = 0
          AND status = 1
          AND society_id = @society_id;
        RETURN;
    END;

    --------------------------------------------------
    -- GetApprover List Except Current User
    --------------------------------------------------
    IF @operation = 'add_approver'
    BEGIN
        SELECT
            user_id,
            name,
            '2' AS status,
            GETDATE() AS date,
            'add' AS type
        FROM UserLogin
        WHERE user_id != @user_id
          AND active_status = 0
          AND society_id = @society_id;
        RETURN;
    END;

    --------------------------------------------------
    -- Fill Vendor List
    --------------------------------------------------
    IF @operation = 'vendor_fill'
    BEGIN
        SELECT
            vendor_id,
            vendor_name,
            gst_no,
            service_type
        FROM vendor_master
        WHERE society_id = @society_id;
        RETURN;
    END;

    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------
    IF UPPER(@operation) = 'UPDATE'
    BEGIN
        UPDATE dbo.vendor_bills
        SET
            society_id   = @society_id,
            bill_number  = @bill_number,
            bill_date    = @bill_date,
            vendor_id    = @vendor_id,
            subtotal     = @subtotal,
            tax_amount   = @tax_amount,
            total_amount = @total_amount,
            status       = @status,
            notes        = @notes,
            updated_date = GETDATE(),
            service_type = @service
        WHERE bill_id = @bill_id;

        RETURN;
    END;

    --------------------------------------------------
    -- Get Bills Items
    --------------------------------------------------
    IF UPPER(@operation) = 'GETBILLITEMS'
    BEGIN
        SELECT *
        FROM dbo.inventory_master
        WHERE vendor_id = @vendor_id
          AND society_id = @society_id;
        RETURN;
    END;

    --------------------------------------------------
    -- DELETE
    --------------------------------------------------
    IF UPPER(@operation) = 'DELETE'
    BEGIN
        DELETE FROM dbo.vendor_bills
        WHERE bill_id = @bill_id;
        RETURN;
    END;

    --------------------------------------------------
    -- VIEW ALL - Grid Show
    --------------------------------------------------
    IF UPPER(@operation) = 'Grid_Show'
    BEGIN
        SELECT
            vb.bill_id,
            vb.society_id,
            vb.bill_number,
            vb.bill_date,
            vb.vendor_id,
            names.vendor_name,
            vb.subtotal,
            vb.tax_amount,
            vb.total_amount,
            ISNULL(SUM(TRY_CAST(vp.bill_paid_amount AS DECIMAL(18,2))), 0) AS paid_amount,
            vb.total_amount - ISNULL(SUM(TRY_CAST(vp.bill_paid_amount AS DECIMAL(18,2))), 0) AS remaining_amount,
            CASE
                WHEN vb.total_amount - ISNULL(SUM(TRY_CAST(vp.bill_paid_amount AS DECIMAL(18,2))), 0) = 0
                    THEN 'Paid'
                WHEN ISNULL(SUM(TRY_CAST(vp.bill_paid_amount AS DECIMAL(18,2))), 0) = 0
                    THEN 'Unpaid'
                ELSE 'Partially Paid'
            END AS payment_status,
            vb.status,
            bs.bill_status,
            vb.notes,
            vb.created_date,
            vb.created_by,
            vb.service_type
        FROM vendor_bills vb
        OUTER APPLY (
            SELECT STRING_AGG(t.name, ', ') AS vendor_name
            FROM (
                -- Vendors
                SELECT vm.vendor_name AS name
                FROM STRING_SPLIT(vb.vendor_id, ',') s
                JOIN vendor_master vm ON vm.vendor_id = TRY_CAST(s.value AS INT)
                WHERE vb.service_type <> 0

                UNION ALL

                -- Staff
                SELECT sm.name
                FROM STRING_SPLIT(vb.vendor_id, ',') s
                JOIN staff_master sm ON sm.staff_id = TRY_CAST(s.value AS INT)
                WHERE vb.service_type = 0
            ) t
        ) names
        INNER JOIN bill_status bs ON bs.status_id = vb.status
        LEFT JOIN vendor_bill_payments vp
            ON vp.society_id = vb.society_id
           AND vp.status = 1
           AND EXISTS (
                SELECT 1
                FROM STRING_SPLIT(vp.bill_details, ',') s
                WHERE TRY_CAST(s.value AS INT) = vb.bill_id
           )
        WHERE vb.society_id = @society_id
        GROUP BY
            vb.bill_id,
            vb.society_id,
            vb.bill_number,
            vb.bill_date,
            vb.vendor_id,
            names.vendor_name,
            vb.subtotal,
            vb.tax_amount,
            vb.total_amount,
            vb.status,
            bs.bill_status,
            vb.notes,
            vb.created_date,
            vb.created_by,
            vb.service_type
        ORDER BY vb.bill_id DESC;

        RETURN;
    END;

    --------------------------------------------------
    -- VIEW BY ID
    --------------------------------------------------
    IF UPPER(@operation) = 'VIEWBYID'
    BEGIN
        SELECT
            vb.bill_id,
            vb.society_id,
            sm.name AS society_name,
            vb.bill_number,
            vb.bill_date,
            vb.vendor_id,
            vm.vendor_name,
            vb.subtotal,
            vb.tax_amount,
            vb.total_amount,
            vb.status,
            vb.notes,
            vb.created_date,
            vb.updated_date,
            vb.created_by,
            vb.description
        FROM dbo.vendor_bills vb
        INNER JOIN dbo.vendor_master vm ON vb.vendor_id = vm.vendor_id
        INNER JOIN dbo.society_master sm ON vb.society_id = sm.society_id
        WHERE vb.bill_id = @bill_id;

        RETURN;
    END;

    --------------------------------------------------
    -- APPROVE
    --------------------------------------------------
    IF UPPER(@operation) = 'APPROVE'
    BEGIN
        UPDATE dbo.vendor_bills
        SET status = 2, -- Approved
            updated_date = GETDATE()
        WHERE bill_id = @bill_id;

        RETURN;
    END;

    --------------------------------------------------
    -- REJECT
    --------------------------------------------------
    IF UPPER(@operation) = 'REJECT'
    BEGIN
        UPDATE dbo.vendor_bills
        SET status = 4, -- Rejected
            updated_date = GETDATE()
        WHERE bill_id = @bill_id;

        RETURN;
    END;

    --------------------------------------------------
    -- MARK AS PAID
    --------------------------------------------------
    IF UPPER(@operation) = 'PAY'
    BEGIN
        UPDATE dbo.vendor_bills
        SET status = 3, -- Paid
            updated_date = GETDATE()
        WHERE bill_id = @bill_id;

        RETURN;
    END;

    --------------------------------------------------
    -- SELECT - Get Bill Details
    --------------------------------------------------
    IF UPPER(@operation) = 'SELECT'
    BEGIN
        -- Step 1: Compute payments per bill
        WITH BillPayments AS (
            SELECT
                vb.bill_id,
                SUM(
                    CAST(
                        TRY_CAST(vp.bill_paid_amount AS DECIMAL(18,2))
                        / NULLIF(splits.NumBills, 0)
                    AS DECIMAL(18,2))
                ) AS paid_amount
            FROM vendor_bills vb
            LEFT JOIN vendor_bill_payments vp
                ON vp.society_id = vb.society_id
               AND vp.status = 1
            CROSS APPLY (
                SELECT COUNT(*) AS NumBills
                FROM dbo.SplitString(vp.bill_details, ',') s
                WHERE TRY_CAST(s.Value AS INT) = vb.bill_id
            ) splits
            WHERE (@bill_id IS NULL OR vb.bill_id = @bill_id)
            GROUP BY vb.bill_id
        ),
        -- Step 2: Get all vendor names concatenated per bill
        VendorNames AS (
            SELECT
                vb.bill_id,
                STRING_AGG(
                    CASE
                        WHEN vb.service_type <> 0 THEN vm.vendor_name
                        ELSE sm.name
                    END,
                    ', '
                ) AS vendor_names,
                MAX(CASE WHEN vb.service_type <> 0 THEN vm.gst_no END) AS gst_no
            FROM vendor_bills vb
            CROSS APPLY (
                SELECT TRY_CAST(Value AS INT) AS vendor_split_id
                FROM dbo.SplitString(vb.vendor_id, ',')
                WHERE TRY_CAST(Value AS INT) IS NOT NULL
            ) AS split_row
            LEFT JOIN vendor_master vm
                ON vm.vendor_id = split_row.vendor_split_id AND vb.service_type <> 0
            LEFT JOIN staff_master sm
                ON sm.staff_id = split_row.vendor_split_id AND vb.service_type = 0
            WHERE (@bill_id IS NULL OR vb.bill_id = @bill_id)
            GROUP BY vb.bill_id
        )
        SELECT
            vb.bill_id,
            vb.society_id,
            vb.bill_number,
            vb.bill_date,
            vb.vendor_id AS original_vendor_ids,
            vn.vendor_names AS vendor_name,
            vn.gst_no,
            vb.subtotal,
            vb.tax_amount,
            vb.total_amount,
            ISNULL(CAST(bp.paid_amount AS DECIMAL(18,2)), 0) AS paid_amount,
            CAST(vb.total_amount - ISNULL(bp.paid_amount, 0) AS DECIMAL(18,2)) AS remaining_amount,
            CASE
                WHEN vb.total_amount - ISNULL(bp.paid_amount, 0) = 0 THEN 'Paid'
                WHEN ISNULL(bp.paid_amount, 0) = 0 THEN 'Unpaid'
                ELSE 'Partially Paid'
            END AS payment_status,
            vb.status,
            bs.bill_status,
            vb.notes AS description,
            vb.created_date,
            vb.created_by,
            vb.service_type
        FROM vendor_bills vb
        INNER JOIN bill_status bs ON bs.status_id = vb.status
        LEFT JOIN BillPayments bp ON vb.bill_id = bp.bill_id
        LEFT JOIN VendorNames vn ON vn.bill_id = vb.bill_id
        WHERE (@bill_id IS NULL OR vb.bill_id = @bill_id)
        ORDER BY vb.bill_id DESC;

        RETURN;
    END;

    --------------------------------------------------
    -- GET_BILL_ITEMS
    --------------------------------------------------
    IF UPPER(@operation) = 'GET_BILL_ITEMS'
    BEGIN
        SELECT *
        FROM inventory_master
        WHERE vendor_bill_id = @bill_id;
        RETURN;
    END;

    --------------------------------------------------
    -- GET_APPROVALS
    --------------------------------------------------
    IF UPPER(@operation) = 'GET_APPROVALS'
    BEGIN
        SELECT
            approval_id,
            vendor_bill_approval.user_id,
            bill_id,
            vendor_bill_approval.approval_status,
            approval_date,
            remarks,
            name,
            'get' AS type
        FROM vendor_bill_approval
        INNER JOIN UserLogin ON UserLogin.user_id = vendor_bill_approval.user_id
        WHERE bill_id = @bill_id;
        RETURN;
    END;

    --------------------------------------------------
    -- UPDATE_STATUS
    --------------------------------------------------
    IF UPPER(@operation) = 'UPDATE_STATUS'
    BEGIN
        UPDATE vendor_bill_approval
        SET approval_status = @status,
            approval_date = GETDATE(),
            remarks = @notes
        WHERE approval_id = @approval_id;

        SELECT @bill_id = bill_id
        FROM vendor_bill_approval
        WHERE approval_id = @approval_id;

        -- A rejection settles the bill on its own: one approver saying no is
        -- enough to stop it, and there is nothing further to decide. ELSE IF,
        -- not a second IF — without it the approve test below ran straight
        -- afterwards and overwrote the rejection with Approved.
        IF @status = 4
        BEGIN
            UPDATE vendor_bills
            SET status = 4,
                updated_date = GETDATE()
            WHERE bill_id = @bill_id;
        END
        -- Approved only once every approver has approved.
        --
        -- `<> 2` rather than `= 1`: the old test asked whether anyone was
        -- still Pending, which a row sitting at 4 (Rejected) does not answer
        -- to. A bill one approver had rejected therefore turned Approved as
        -- soon as the others answered — the rejection outvoted, which is not
        -- how this works. Any row that is not an approval now blocks it.
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM vendor_bill_approval
            WHERE bill_id = @bill_id
              AND approval_status <> 2
        )
        BEGIN
            UPDATE vendor_bills
            SET status = 2,
                updated_date = GETDATE()
            WHERE bill_id = @bill_id;
        END

        RETURN;
    END;

    --------------------------------------------------
    -- INVALID OPERATION
    --------------------------------------------------
    SELECT 'Invalid operation specified.' AS error_message;
    RETURN;
END;
GO
