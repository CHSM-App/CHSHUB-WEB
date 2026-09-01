/*
 * ADD: who decided a NOC request, on the list itself.
 *
 * Why
 * ---
 * A request goes to every office the society has and any one of them can
 * settle it. So "approved" on its own does not say what the committee needs to
 * know: which of them approved it, and when. Somebody asked about a
 * certificate three months later has to be able to answer that, and a member
 * told their request was refused should see who refused it.
 *
 * It was readable, but only by opening the request and reading the approvals
 * list — and an approved request no longer opens: its row carries a NOC button
 * that goes straight to the certificate form. So the answer moves onto the
 * row.
 *
 * What is added to Grid_Show
 * --------------------------
 *   decided_by   the officer's name
 *   decided_on   when they answered
 *
 * Both read from the one approval that settled it: the rejection if there is
 * one, otherwise the first approval. That matches how the request itself was
 * settled — a rejection ends it whoever else has agreed, so it is the
 * rejection that answers "what happened to this".
 *
 * Everything else in the procedure is unchanged; the body is restated because
 * ALTER PROCEDURE has to carry the whole thing.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_noc_request
    @operation       NVARCHAR(20)   = NULL,
    @request_id      INT            = 0,
    @society_id      NVARCHAR(10)   = NULL,
    @flat_id         INT            = NULL,
    @requested_by    INT            = NULL,
    @member_name     NVARCHAR(150)  = NULL,
    @flat_no         NVARCHAR(50)   = NULL,
    @building_name   NVARCHAR(100)  = NULL,
    @noc_type        NVARCHAR(20)   = NULL,
    @custom_title    NVARCHAR(150)  = NULL,
    @purpose         NVARCHAR(300)  = NULL,
    @clause          NVARCHAR(1000) = NULL,
    @remarks         NVARCHAR(1000) = NULL,
    @valid_till      DATE           = NULL,
    @status          INT            = NULL,
    @approval_id     INT            = 0,
    @user_id         INT            = NULL,
    @approval_remark NVARCHAR(500)  = NULL,
    @noc_id          INT            = NULL,
    @collection_date DATE           = NULL,
    @collection_time NVARCHAR(60)   = NULL,
    @collection_note NVARCHAR(300)  = NULL,
    @collected_by    NVARCHAR(150)  = NULL,
    @search          NVARCHAR(200)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------
    -- Grid_Show — the secretary's list.
    --
    -- Ordered by status so what needs an answer is at the top: Pending (1),
    -- then Approved awaiting the certificate (2), then Ready to be collected
    -- (5), then everything already settled.
    --------------------------------------------------
    IF @operation = 'Grid_Show'
    BEGIN
        SELECT r.*,
               c.serial_no,
               -- How far along the approvals are, so the list can say "1 of 3"
               -- without a second round trip per row.
               (SELECT COUNT(*) FROM dbo.noc_request_approval a
                 WHERE a.request_id = r.request_id)                       AS approver_count,
               (SELECT COUNT(*) FROM dbo.noc_request_approval a
                 WHERE a.request_id = r.request_id
                   AND a.approval_status = 2)                             AS approved_count,
               -- Why it was refused. The member is shown this, so it is read
               -- back with the request rather than fetched separately.
               (SELECT TOP 1 a.remarks FROM dbo.noc_request_approval a
                 WHERE a.request_id = r.request_id
                   AND a.approval_status = 4
                 ORDER BY a.approval_date DESC)                           AS reject_reason,
               -- Who settled it, and when. A rejection first: it ends the
               -- request whoever else has agreed, so it is the answer to
               -- "what happened to this one".
               decision.name                                              AS decided_by,
               decision.approval_date                                     AS decided_on
        FROM   dbo.noc_request r
        LEFT   JOIN dbo.noc_certificate c ON c.noc_id = r.noc_id
        OUTER  APPLY (
            SELECT TOP 1 u.name, a.approval_date
            FROM   dbo.noc_request_approval a
            INNER  JOIN dbo.UserLogin u ON u.user_id = a.user_id
            WHERE  a.request_id = r.request_id
              AND  a.approval_status IN (2, 4)
            ORDER BY CASE a.approval_status WHEN 4 THEN 0 ELSE 1 END,
                     a.approval_date
        ) decision
        WHERE  r.society_id = @society_id
          AND  ISNULL(r.active_status, 0) = 0
          AND (@search IS NULL
            OR r.member_name LIKE '%' + @search + '%'
            OR r.flat_no     LIKE '%' + @search + '%'
            OR c.serial_no   LIKE '%' + @search + '%')
        ORDER BY CASE r.status WHEN 1 THEN 0 WHEN 2 THEN 1 WHEN 5 THEN 2 ELSE 3 END,
                 r.requested_on DESC;
        RETURN;
    END

    --------------------------------------------------
    -- MyRequests — one flat's requests, for the member's app.
    --------------------------------------------------
    IF @operation = 'MyRequests'
    BEGIN
        SELECT r.*,
               c.serial_no,
               (SELECT TOP 1 a.remarks FROM dbo.noc_request_approval a
                 WHERE a.request_id = r.request_id
                   AND a.approval_status = 4
                 ORDER BY a.approval_date DESC)                           AS reject_reason
        FROM   dbo.noc_request r
        LEFT   JOIN dbo.noc_certificate c ON c.noc_id = r.noc_id
        WHERE  r.flat_id = @flat_id
          AND  ISNULL(r.active_status, 0) = 0
        ORDER BY r.requested_on DESC;
        RETURN;
    END

    IF @operation = 'Select'
    BEGIN
        SELECT r.*,
               c.serial_no,
               (SELECT TOP 1 a.remarks FROM dbo.noc_request_approval a
                 WHERE a.request_id = r.request_id
                   AND a.approval_status = 4
                 ORDER BY a.approval_date DESC)                           AS reject_reason
        FROM   dbo.noc_request r
        LEFT   JOIN dbo.noc_certificate c ON c.noc_id = r.noc_id
        WHERE  r.request_id = @request_id
          AND (@society_id IS NULL OR r.society_id = @society_id);
        RETURN;
    END

    --------------------------------------------------
    -- Insert — the member asks.
    --
    -- Only the member's own words are taken here. The wording, the approvers
    -- and the collection date are all the society's to set later.
    --------------------------------------------------
    IF @operation = 'Insert'
    BEGIN
        DECLARE @new_request INT;
        SELECT @new_request = ISNULL(MAX(request_id), 0) + 1 FROM dbo.noc_request;

        INSERT INTO dbo.noc_request
               (request_id, society_id, flat_id, requested_by, member_name,
                flat_no, building_name, noc_type, custom_title, purpose,
                status, requested_on, active_status)
        VALUES (@new_request, @society_id, @flat_id, @requested_by, @member_name,
                @flat_no, @building_name, ISNULL(@noc_type, 'General'),
                @custom_title, @purpose,
                1, GETDATE(), 0);

        SELECT @new_request AS request_id;
        RETURN;
    END

    --------------------------------------------------
    -- Add_Approver — put one office on the request.
    --
    -- Called once per officer. Re-adding somebody already on the request is
    -- ignored rather than treated as an error: the request may be re-sent, and
    -- that must not wipe a decision somebody has already given.
    --------------------------------------------------
    IF @operation = 'Add_Approver'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.noc_request_approval
                        WHERE request_id = @request_id AND user_id = @user_id)
        BEGIN
            DECLARE @new_approval INT;
            SELECT @new_approval = ISNULL(MAX(approval_id), 0) + 1
            FROM   dbo.noc_request_approval;

            INSERT INTO dbo.noc_request_approval
                   (approval_id, request_id, user_id, approval_status)
            VALUES (@new_approval, @request_id, @user_id, 1);

            SELECT @new_approval AS approval_id;
            RETURN;
        END

        SELECT approval_id
        FROM   dbo.noc_request_approval
        WHERE  request_id = @request_id AND user_id = @user_id;
        RETURN;
    END

    IF @operation = 'Get_Approvals'
    BEGIN
        SELECT a.approval_id,
               a.request_id,
               a.user_id,
               a.approval_status,
               a.approval_date,
               a.remarks,
               u.name,
               -- Which office they hold, so the list reads "Priya Sharma,
               -- Secretary" rather than a bare name the reader has to place.
               t.UserTypeName AS role
        FROM   dbo.noc_request_approval a
        INNER  JOIN dbo.UserLogin u ON u.user_id = a.user_id
        LEFT   JOIN dbo.UserType t ON t.UserTypeId = u.user_type_id
        WHERE  a.request_id = @request_id
        ORDER BY a.approval_id;
        RETURN;
    END

    --------------------------------------------------
    -- Update_Draft — the secretary settles the wording.
    --
    -- Editable only while the request is still Pending. Once approved the
    -- certificate is written from these words, and letting the draft move
    -- afterwards would leave the two disagreeing about what the committee
    -- actually approved.
    --------------------------------------------------
    IF @operation = 'Update_Draft'
    BEGIN
        UPDATE dbo.noc_request
        SET    noc_type     = ISNULL(@noc_type, noc_type),
               custom_title = @custom_title,
               clause       = @clause,
               purpose      = ISNULL(@purpose, purpose),
               remarks      = @remarks,
               valid_till   = @valid_till
        WHERE  request_id = @request_id
          AND  society_id = @society_id
          AND  status = 1;

        SELECT @@ROWCOUNT AS updated;
        RETURN;
    END

    --------------------------------------------------
    -- Update_Status — one officer answers.
    --
    -- How many answers settle it is the society's own rule, read from
    -- account_setting.noc_approval_mode:
    --
    --   'All' — every officer the request went to has to approve.
    --   'Any' — the first approval settles it. The default, and what a
    --           society that has not chosen gets: it is the rule that always
    --           terminates, and several societies here carry three admin and
    --           three secretary accounts held by the same few people.
    --
    -- One rejection settles it either way, which is why that branch sits
    -- outside the setting: an officer who says no has raised an objection the
    -- others agreeing cannot answer.
    --
    -- ELSE IF, not a second IF: sp_vendor_bills had them as separate IFs and a
    -- rejection fell straight through into the approve test, which overwrote
    -- it with Approved — see FIX_vendor_bill_reject_overwritten_by_approve.sql.
    --------------------------------------------------
    IF @operation = 'Update_Status'
    BEGIN
        UPDATE dbo.noc_request_approval
        SET    approval_status = @status,
               approval_date   = GETDATE(),
               remarks         = @approval_remark
        WHERE  approval_id = @approval_id;

        DECLARE @req_society NVARCHAR(10);

        SELECT @request_id  = a.request_id,
               @req_society = r.society_id
        FROM   dbo.noc_request_approval a
        INNER  JOIN dbo.noc_request r ON r.request_id = a.request_id
        WHERE  a.approval_id = @approval_id;

        DECLARE @mode NVARCHAR(10);

        SELECT TOP 1 @mode = noc_approval_mode
        FROM   dbo.account_setting
        WHERE  society_id = @req_society;

        -- Anything that is not exactly 'All' is treated as 'Any', so a NULL,
        -- a missing settings row or a typo cannot leave a society unable to
        -- approve anything.
        SET @mode = CASE WHEN @mode = 'All' THEN 'All' ELSE 'Any' END;

        IF @status = 4
        BEGIN
            UPDATE dbo.noc_request
            SET    status = 4
            WHERE  request_id = @request_id;
        END
        ELSE IF (
            (@mode = 'Any'
              AND EXISTS (SELECT 1 FROM dbo.noc_request_approval
                           WHERE request_id = @request_id
                             AND approval_status = 2))
            OR
            (@mode = 'All'
              AND NOT EXISTS (SELECT 1 FROM dbo.noc_request_approval
                               WHERE request_id = @request_id
                                 AND approval_status <> 2))
        )
        BEGIN
            UPDATE dbo.noc_request
            SET    status      = 2,
                   approved_on = GETDATE()
            WHERE  request_id = @request_id
              -- Only from Pending: a request already settled must not be
              -- moved back by another officer answering afterwards.
              AND  status = 1;
        END

        -- The caller reads the certificate's wording off this to open the
        -- issue form, so the draft goes back with the status.
        SELECT r.request_id, r.status, r.society_id, r.noc_type, r.custom_title,
               r.clause, r.member_name, r.flat_no, r.building_name, r.purpose,
               r.remarks, r.valid_till, r.noc_id, r.flat_id
        FROM   dbo.noc_request r
        WHERE  r.request_id = @request_id;
        RETURN;
    END

    --------------------------------------------------
    -- Link_Certificate — record which certificate this request produced.
    --
    -- Separate from Update_Status because the certificate is created by
    -- sp_noc_certificate, which the caller runs from the issue form once the
    -- request has been approved.
    --------------------------------------------------
    IF @operation = 'Link_Certificate'
    BEGIN
        UPDATE dbo.noc_request
        SET    noc_id = @noc_id
        WHERE  request_id = @request_id
          AND  society_id = @society_id;

        SELECT @@ROWCOUNT AS updated;
        RETURN;
    END

    --------------------------------------------------
    -- Set_Ready — the letter is signed; tell the member when to come.
    --
    -- Allowed from Approved (2) and from Ready (5): the secretary may move an
    -- appointment they have already given out, and the member is told again
    -- when they do.
    --------------------------------------------------
    IF @operation = 'Set_Ready'
    BEGIN
        UPDATE dbo.noc_request
        SET    status          = 5,
               ready_on        = ISNULL(ready_on, GETDATE()),
               collection_date = @collection_date,
               collection_time = @collection_time,
               collection_note = @collection_note
        WHERE  request_id = @request_id
          AND  society_id = @society_id
          AND  status IN (2, 5);

        SELECT @@ROWCOUNT AS updated;
        RETURN;
    END

    --------------------------------------------------
    -- Set_Collected — it was handed over.
    --------------------------------------------------
    IF @operation = 'Set_Collected'
    BEGIN
        UPDATE dbo.noc_request
        SET    status       = 6,
               collected_on = GETDATE(),
               collected_by = @collected_by
        WHERE  request_id = @request_id
          AND  society_id = @society_id
          AND  status = 5;

        SELECT @@ROWCOUNT AS updated;
        RETURN;
    END

    IF @operation = 'Delete'
    BEGIN
        UPDATE dbo.noc_request
        SET    active_status = 1
        WHERE  request_id = @request_id
          AND  society_id = @society_id;

        SELECT @request_id AS request_id;
        RETURN;
    END

    SELECT 'Invalid operation specified.' AS error_message;
END
GO

PRINT 'sp_noc_request updated - the list now carries who decided each request.';
GO
