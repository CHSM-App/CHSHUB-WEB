/*
 * ADD: noc_request and noc_request_approval — the NOC a member asks for,
 * and the committee's decision on it.
 *
 * Why these tables
 * ----------------
 * noc_certificate already records what the society has issued. It has no room
 * for what happens before that: a member asking, the committee deciding, and
 * the signed letter being handed over. Those steps were done off the system —
 * a phone call and a note — so nothing recorded who asked, who agreed, or who
 * collected the certificate. All three are asked about later.
 *
 * The two tables mirror vendor_bills / vendor_bill_approval, which is the
 * approval pattern already in this schema. A request carries its own status;
 * each approver gets a row of their own, and the request's status is derived
 * from them. Keeping the shape identical means the rules that govern it —
 * one rejection settles it, approval needs everybody — are the rules already
 * written for vendor bills rather than a second set to keep in step.
 *
 * Status codes are vendor_bills' own, extended at the end rather than
 * renumbered:
 *     1 Pending    the member has asked; nobody has decided
 *     2 Approved   every approver agreed; the certificate now exists
 *     4 Rejected   somebody refused; reason on the approval row
 *     5 Ready      printed and signed, waiting to be collected
 *     6 Collected  handed over
 *
 * 3 is skipped: it is Paid in bill_status and means nothing here. Sharing the
 * numbering keeps 1/2/4 reading the same way across the two features.
 *
 * Why the paper steps are in the table
 * ------------------------------------
 * A NOC is only worth anything signed. Approving it in the app does not
 * produce the document a bank will take — the secretary prints it, the
 * chairman and secretary sign it, and the member comes to the office for it.
 * Ready and Collected are those two real events. Without them the member is
 * told the certificate is approved and has no idea when to come, which is the
 * question they will otherwise ring the office to ask.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.noc_request', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.noc_request (
        request_id      INT             NOT NULL,
        society_id      NVARCHAR(10)    NULL,

        -- Who asked. flat_id identifies the home; the name and flat number are
        -- copied from the member's login at the time of asking rather than
        -- joined at read time, so a request still reads correctly after the
        -- flat changes hands.
        flat_id         INT             NULL,
        requested_by    INT             NULL,
        member_name     NVARCHAR(150)   NULL,
        flat_no         NVARCHAR(50)    NULL,
        building_name   NVARCHAR(100)   NULL,

        -- 'NoDues', 'SaleTransfer', 'Renovation', 'Mortgage', 'General' or
        -- 'Other' — the same set noc_certificate uses.
        noc_type        NVARCHAR(20)    NULL,
        custom_title    NVARCHAR(150)   NULL,
        purpose         NVARCHAR(300)   NULL,

        -- The wording the secretary settles on while reviewing. Held here
        -- until the certificate is issued, then copied onto it: a draft can
        -- be edited, an issued certificate cannot.
        clause          NVARCHAR(1000)  NULL,
        remarks         NVARCHAR(1000)  NULL,
        valid_till      DATE            NULL,

        status          INT             NULL,
        requested_on    SMALLDATETIME   NULL,

        -- Set when the last approver agrees.
        approved_on     SMALLDATETIME   NULL,

        -- The certificate this request produced. NULL until it is approved;
        -- this is the link from "what was asked" to "what was issued".
        noc_id          INT             NULL,

        -- The collection appointment the secretary gives out. collection_date
        -- is what the member is told to turn up on; collected_on is when they
        -- actually did. They are different facts and both get asked about.
        ready_on        SMALLDATETIME   NULL,
        collection_date DATE            NULL,
        collection_time NVARCHAR(60)    NULL,
        collection_note NVARCHAR(300)   NULL,

        collected_on    SMALLDATETIME   NULL,
        -- Free text, not a user id: the member often sends somebody else, and
        -- who took the certificate away is the fact worth keeping.
        collected_by    NVARCHAR(150)   NULL,

        active_status   INT             NULL,

        CONSTRAINT PK_noc_request PRIMARY KEY CLUSTERED (request_id ASC)
    );

    -- The secretary's list: this society's live requests, pending first.
    CREATE INDEX IX_noc_request_society
        ON dbo.noc_request (society_id, active_status, status);

    -- The member's own list, which their app opens on.
    CREATE INDEX IX_noc_request_flat
        ON dbo.noc_request (flat_id, active_status);

    PRINT 'noc_request created.';
END
ELSE
    PRINT 'noc_request already exists - no change made.';
GO

IF OBJECT_ID('dbo.noc_request_approval', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.noc_request_approval (
        approval_id     INT             NOT NULL,
        request_id      INT             NULL,
        user_id         INT             NULL,

        -- 1 Pending, 2 Approved, 4 Rejected — vendor_bill_approval's codes.
        approval_status INT             NULL,
        approval_date   SMALLDATETIME   NULL,

        -- Required when rejecting; the member is shown it.
        remarks         NVARCHAR(500)   NULL,

        CONSTRAINT PK_noc_request_approval PRIMARY KEY CLUSTERED (approval_id ASC)
    );

    -- Every read is "the approvals on this request".
    CREATE INDEX IX_noc_request_approval_request
        ON dbo.noc_request_approval (request_id);

    -- "What is waiting for me" on a committee member's home screen.
    CREATE INDEX IX_noc_request_approval_user
        ON dbo.noc_request_approval (user_id, approval_status);

    PRINT 'noc_request_approval created.';
END
ELSE
    PRINT 'noc_request_approval already exists - no change made.';
GO

/*
 * sp_noc_request — the branches the apps call.
 *
 * Grid_Show         the secretary's list for one society
 * MyRequests        one flat's own requests, for the member's app
 * Select            one request
 * Insert            the member asks
 * Add_Approver      the secretary names who must decide
 * Get_Approvals     who was asked, and what they said
 * Update_Draft      the secretary edits the wording before it is issued
 * Update_Status     one approver's answer, which may settle the request
 * Link_Certificate  record which certificate the request produced
 * Set_Ready         the letter is signed; give out a collection date
 * Set_Collected     it was handed over
 * Delete            soft delete
 *
 * Ids are allocated here rather than by the caller, matching the rest of this
 * schema, so two secretaries acting at once cannot land on one number.
 */
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
    -- then Approved awaiting signature (2), then Ready to be collected (5),
    -- then everything already settled.
    --------------------------------------------------
    IF @operation = 'Grid_Show'
    BEGIN
        SELECT r.*,
               c.serial_no,
               -- How far along the approvals are, so the list can say "1 of 2"
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
                 ORDER BY a.approval_date DESC)                           AS reject_reason
        FROM   dbo.noc_request r
        LEFT   JOIN dbo.noc_certificate c ON c.noc_id = r.noc_id
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
    -- Add_Approver — the secretary names one person who must decide.
    --
    -- Called once per approver. Re-adding somebody already on the request is
    -- ignored rather than treated as an error: the secretary may reopen the
    -- picker and save the same list again, and that must not wipe a decision
    -- somebody has already given.
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
               u.name
        FROM   dbo.noc_request_approval a
        INNER  JOIN dbo.UserLogin u ON u.user_id = a.user_id
        WHERE  a.request_id = @request_id
        ORDER BY a.approval_id;
        RETURN;
    END

    --------------------------------------------------
    -- Update_Draft — the secretary settles the wording.
    --
    -- Editable only while the request is still Pending. Once approved the
    -- certificate exists and carries the words that were agreed to; letting
    -- the draft move afterwards would leave the two disagreeing about what
    -- the committee actually approved.
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
    -- Update_Status — one approver answers.
    --
    -- The two blocks are ELSE IF, not two IFs. sp_vendor_bills had them as
    -- separate IFs and a rejection fell straight through into the approve
    -- test, which overwrote it with Approved — see
    -- FIX_vendor_bill_reject_overwritten_by_approve.sql. One rejection
    -- settles the request.
    --
    -- The approve test reads "every approver has approved" — approval_status
    -- <> 2 — rather than "nobody is still pending". Testing for = 1 would let
    -- a row sitting at 4 pass unseen, so a rejection could be outvoted by the
    -- approvers who answered after it.
    --------------------------------------------------
    IF @operation = 'Update_Status'
    BEGIN
        UPDATE dbo.noc_request_approval
        SET    approval_status = @status,
               approval_date   = GETDATE(),
               remarks         = @approval_remark
        WHERE  approval_id = @approval_id;

        SELECT @request_id = request_id
        FROM   dbo.noc_request_approval
        WHERE  approval_id = @approval_id;

        IF @status = 4
        BEGIN
            UPDATE dbo.noc_request
            SET    status = 4
            WHERE  request_id = @request_id;
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM dbo.noc_request_approval
                             WHERE request_id = @request_id
                               AND approval_status <> 2)
        BEGIN
            UPDATE dbo.noc_request
            SET    status      = 2,
                   approved_on = GETDATE()
            WHERE  request_id = @request_id;
        END

        -- The caller issues the certificate once this comes back Approved, so
        -- it needs to know which way the request went. The draft goes back
        -- with it: the certificate is written from these words.
        SELECT r.request_id, r.status, r.society_id, r.noc_type, r.custom_title,
               r.clause, r.member_name, r.flat_no, r.building_name, r.purpose,
               r.remarks, r.valid_till, r.noc_id
        FROM   dbo.noc_request r
        WHERE  r.request_id = @request_id;
        RETURN;
    END

    --------------------------------------------------
    -- Link_Certificate — record which certificate this request produced.
    --
    -- Separate from Update_Status because the certificate is created by
    -- sp_noc_certificate, which the caller runs once it sees the request has
    -- been approved.
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

PRINT 'sp_noc_request created.';
GO
