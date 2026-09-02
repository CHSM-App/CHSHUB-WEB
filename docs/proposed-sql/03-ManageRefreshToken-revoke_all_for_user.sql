/* ============================================================================
   ManageRefreshToken — add 'revoke_all_for_user'

   WHY
   ---
   Changing a password did not end any existing session. The website's
   /onboarding/change-password and /onboarding/forgot-password updated the
   password hash and stopped there, so every refresh token issued under the old
   password stayed valid for its full 7 days. A session started with a password
   the user has just replaced kept renewing itself every 15 minutes, which is
   exactly the session a password change is meant to destroy — the phone that
   was stolen, or the account someone else had got into.

   Access tokens are stateless JWTs and cannot be recalled; that is deliberate
   and safe because they expire in 15 minutes. The refresh token is the part
   that lives in this table, and it is therefore the part that has to be
   revoked. Revoking it bounds the old session to at most one access-token
   lifetime (15 minutes) instead of 7 days.

   The existing 'revoke' operation takes a single token string, which is the
   right shape for a logout but cannot express "every session this person has".
   Hence a second operation rather than a change to the first.

   KEYING — the reason @user_mobile is not enough on its own
   ---------------------------------------------------------
   RefreshTokens.user_mobile holds two different kinds of identity, because two
   APIs share this table:

     mobile API  (backend/routes/login.js)      '9876543210'   — the phone number
     website API (backend/web/lib/tokens.js)    'web:1739'     — the user id

   A password belongs to the person, not to one of their apps, so revoking only
   the caller's own kind would leave the same human signed in on the other one.
   That is why the callers pass both keys and the proc accepts either or both:
   @user_mobile for the website row, @contact_no for the mobile row. Passing
   NULL for one skips it, so a caller that genuinely has only one identity — a
   web-only account with no phone number on file — still works.

   IDEMPOTENT: `AND revoked = 0` means re-running this revokes nothing extra and
   the reported count is the number of sessions actually ended by this call.

   DEPLOY
   ------
   Safe to run on a live database: it adds a branch and touches no existing one.
   Deploy this BEFORE the backend change that calls it — an unknown @operation
   falls through to the 'Invalid operation' SELECT rather than erroring, so the
   old proc with the new backend would silently revoke nothing.
   ============================================================================ */

USE [society]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ManageRefreshToken]
    @operation       NVARCHAR(30),       -- 'insert', 'get', 'revoke', 'revoke_all_for_user', 'AutoTask'

    -- Insert fields
    @user_mobile     NVARCHAR(50)  = NULL,
    @refresh_token   NVARCHAR(MAX) = NULL,
    @device_info     NVARCHAR(500) = NULL,
    @ip_address      NVARCHAR(100) = NULL,
    @expires_at      DATETIME2     = NULL,

    -- revoke_all_for_user: the same person's other identity in this table.
    -- See KEYING above.
    @contact_no      NVARCHAR(50)  = NULL,

    -- revoke_all_for_user: the session doing the changing, spared so the user
    -- is not signed out of the device they are typing on. NULL revokes all.
    @except_token    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert Operation --------------------------------------------
    IF @operation = 'insert'
    BEGIN
        INSERT INTO dbo.RefreshTokens (user_mobile, refresh_token, device_info,  expires_at)
        VALUES (@user_mobile, @refresh_token, @device_info, @expires_at);

        SELECT SCOPE_IDENTITY() AS id;
        RETURN;
    END


    -- Get Operation ------------------------------------------------
    IF @operation = 'get'
    BEGIN
        SELECT TOP 1 *
        FROM dbo.RefreshTokens
        WHERE refresh_token = @refresh_token
          AND revoked = 0
          AND expires_at >   SYSUTCDATETIME();
        RETURN;
    END


    -- Revoke Operation ---------------------------------------------
    IF @operation = 'revoke'
    BEGIN
        UPDATE dbo.RefreshTokens
        SET revoked = 1
        WHERE refresh_token = @refresh_token;

        SELECT @@ROWCOUNT AS revoked_count;  -- Optional feedback
        RETURN;
    END


    -- Revoke every live session for one person ---------------------
    -- Called after a password change or reset.
    IF @operation = 'revoke_all_for_user'
    BEGIN
        -- Refuse to revoke the whole table if the caller passed neither key.
        -- Without this guard a bug that produced two NULLs would sign out
        -- every user of the system, and it would look like a successful call.
        IF @user_mobile IS NULL AND @contact_no IS NULL
        BEGIN
            SELECT CAST(0 AS INT) AS revoked_count,
                   'revoke_all_for_user needs @user_mobile or @contact_no' AS error_message;
            RETURN;
        END

        UPDATE dbo.RefreshTokens
        SET revoked = 1
        -- RefreshTokens.revoked is nullable (it only carries a DEFAULT of 0),
        -- so `revoked = 0` alone would skip any legacy row holding NULL and
        -- quietly leave that session alive — the one outcome this operation
        -- exists to prevent. ISNULL treats an unset flag as not-revoked.
        WHERE ISNULL(revoked, 0) = 0
          AND (
                (@user_mobile IS NOT NULL AND user_mobile = @user_mobile)
             OR (@contact_no  IS NOT NULL AND user_mobile = @contact_no)
              )
          -- Spare the caller's own session when one was named.
          AND (@except_token IS NULL OR refresh_token <> @except_token);

        SELECT @@ROWCOUNT AS revoked_count;
        RETURN;
    END


	IF @operation = 'AutoTask'
    BEGIN
	  DELETE FROM RefreshTokens
      WHERE expires_at < SYSUTCDATETIME();
        DELETE FROM RefreshTokens
      WHERE id IN (
          SELECT id FROM (
              SELECT id,
                     ROW_NUMBER() OVER (
                       PARTITION BY user_mobile ORDER BY created_at DESC
                     ) AS rn
              FROM RefreshTokens
          ) t
          WHERE t.rn > 5
      )

    END

    -- Invalid Operation --------------------------------------------
    SELECT 'Invalid operation. Use insert, get, revoke, revoke_all_for_user or AutoTask.' AS error_message;
END
GO
