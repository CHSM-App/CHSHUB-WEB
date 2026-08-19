/*
 * Server-side OTP for the mobile login.
 *
 * Why this exists
 * ---------------
 * POST /login/Createlogin used to take a mobile number and return a signed
 * access token — no password, no OTP, no check that the number belonged to
 * anyone. Any caller who knew or guessed a resident's number received a valid
 * token for the whole mobile API.
 *
 * The app did show an OTP screen, but the OTP was generated in the app, sent
 * through POST /login/send-sms, and compared in the app. Nothing on the server
 * took part, so the check could be skipped by calling Createlogin directly.
 *
 * This table moves that check to the server: the code is generated here, sent
 * here, and verified here before any token is issued.
 *
 * What is stored
 * --------------
 * Never the code itself. `otp_hash` is a SHA-256 of the code salted with the
 * mobile number and OTP_PEPPER, so a leaked table cannot be replayed and two
 * people who happen to draw the same code hash differently.
 *
 *   mobile        the number the code was sent to, as dialled
 *   otp_hash      SHA-256(mobile + ':' + code + ':' + pepper), 64 hex chars
 *   expires_at    codes are short-lived; past this the row cannot verify
 *   attempts      failed verifies against this row, capped to stop guessing
 *                 a 6-digit code by brute force
 *   consumed_at   set on success — a code verifies exactly once
 *   created_at    also the rate-limit clock for 'issue'
 *
 * Rows are not kept: 'issue' clears anything older than a day for the number,
 * and 'purge' clears the table's tail for a scheduled task to call.
 */

IF OBJECT_ID('dbo.login_otp', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.login_otp (
        otp_id      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        mobile      NVARCHAR(20)  NOT NULL,
        otp_hash    CHAR(64)      NOT NULL,
        expires_at  DATETIME2(0)  NOT NULL,
        attempts    INT           NOT NULL CONSTRAINT DF_login_otp_attempts DEFAULT (0),
        consumed_at DATETIME2(0)  NULL,
        created_at  DATETIME2(0)  NOT NULL CONSTRAINT DF_login_otp_created  DEFAULT (SYSUTCDATETIME())
    );

    -- Both lookups are by mobile, newest first.
    CREATE INDEX IX_login_otp_mobile ON dbo.login_otp (mobile, created_at DESC);
END
GO

IF OBJECT_ID('dbo.sp_login_otp', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_login_otp;
GO

/*
 * Operations
 * ----------
 *   issue    record a freshly generated code. Returns `recent_count`: how many
 *            codes went to this number in the last hour, so the API can refuse
 *            to keep sending. The caller sends the SMS only after this returns.
 *
 *   verify   check a presented code. Returns `result`:
 *              'ok'        matched, in date, unused — and now consumed
 *              'expired'   matched a row past its expiry
 *              'used'      matched a row already consumed
 *              'attempts'  too many failures against the outstanding code
 *              'invalid'   no such code for this number
 *            Consuming inside the proc keeps check-and-consume in one
 *            statement, so two simultaneous requests cannot both succeed with
 *            the same code.
 *
 *   purge    delete expired and consumed rows older than a day.
 */
CREATE PROCEDURE dbo.sp_login_otp
    @operation   NVARCHAR(20),
    @mobile      NVARCHAR(20)  = NULL,
    @otp_hash    CHAR(64)      = NULL,
    @expires_at  DATETIME2(0)  = NULL,
    @max_attempts INT          = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'issue'
    BEGIN
        -- Anything still outstanding for this number is void: requesting a new
        -- code must invalidate the old one, or both stay usable.
        UPDATE dbo.login_otp
           SET consumed_at = SYSUTCDATETIME()
         WHERE mobile = @mobile
           AND consumed_at IS NULL;

        DELETE FROM dbo.login_otp
         WHERE mobile = @mobile
           AND created_at < DATEADD(DAY, -1, SYSUTCDATETIME());

        INSERT INTO dbo.login_otp (mobile, otp_hash, expires_at)
        VALUES (@mobile, @otp_hash, @expires_at);

        SELECT COUNT(*) AS recent_count
          FROM dbo.login_otp
         WHERE mobile = @mobile
           AND created_at > DATEADD(HOUR, -1, SYSUTCDATETIME());
        RETURN;
    END

    IF @operation = 'verify'
    BEGIN
        DECLARE @otp_id BIGINT, @expires DATETIME2(0), @consumed DATETIME2(0), @attempts INT;

        SELECT TOP 1
               @otp_id   = otp_id,
               @expires  = expires_at,
               @consumed = consumed_at,
               @attempts = attempts
          FROM dbo.login_otp
         WHERE mobile = @mobile
           AND otp_hash = @otp_hash
         ORDER BY created_at DESC;

        IF @otp_id IS NULL
        BEGIN
            -- Charge the failure against the code currently outstanding, so a
            -- run of wrong guesses burns the attempt budget rather than
            -- leaving it untouched because none of them matched a row.
            UPDATE dbo.login_otp
               SET attempts = attempts + 1
             WHERE mobile = @mobile
               AND consumed_at IS NULL;

            SELECT 'invalid' AS result;
            RETURN;
        END

        IF @attempts >= @max_attempts
        BEGIN
            SELECT 'attempts' AS result;
            RETURN;
        END

        IF @consumed IS NOT NULL
        BEGIN
            SELECT 'used' AS result;
            RETURN;
        END

        IF @expires < SYSUTCDATETIME()
        BEGIN
            SELECT 'expired' AS result;
            RETURN;
        END

        -- Consume and confirm in one statement: the row count tells us whether
        -- this request was the one that claimed it.
        UPDATE dbo.login_otp
           SET consumed_at = SYSUTCDATETIME()
         WHERE otp_id = @otp_id
           AND consumed_at IS NULL;

        IF @@ROWCOUNT = 1
            SELECT 'ok' AS result;
        ELSE
            SELECT 'used' AS result;   -- another request got there first
        RETURN;
    END

    IF @operation = 'purge'
    BEGIN
        DELETE FROM dbo.login_otp
         WHERE created_at < DATEADD(DAY, -1, SYSUTCDATETIME());
        RETURN;
    END

    RAISERROR('sp_login_otp: unknown @operation "%s"', 16, 1, @operation);
END
GO
