/* ============================================================================
   RUN ME — password change wiped usernames. Fix, then recover.

   Run the STEPs below in order, in SQL Server Management Studio, against the
   `society` database. Each step says whether it only reads or actually writes.

   Background: sp_UserLogin's UpdateProfile branch writes
   `username = @username` with no null-guard, while the password and name
   beside it are guarded. /onboarding/change-password sends only a password, so
   username, email and contact_no arrived NULL and were overwritten. The
   account then cannot log in — the correct password no longer has a username
   to match against — and cannot self-reset, because the email is gone too.
   ============================================================================ */

USE [society];
GO


/* ===========================================================================
   STEP 1 — READ ONLY. Who is affected?

   Run this first. It changes nothing. Keep the output: step 3 needs the
   user_id, and the values it cannot show you are the ones you must retype.
   =========================================================================== */

SELECT user_id,
       name,
       username,
       email,
       contact_no,
       user_type_id,
       society_id,
       CASE WHEN username IS NULL OR username = '' THEN 'CANNOT LOG IN' ELSE 'ok' END AS login_state,
       CASE WHEN email    IS NULL OR email    = '' THEN 'CANNOT RESET'  ELSE 'ok' END AS reset_state
FROM dbo.UserLogin
WHERE username   IS NULL OR username   = ''
   OR email      IS NULL OR email      = ''
   OR contact_no IS NULL OR contact_no = ''
ORDER BY user_id DESC;
GO


/* ===========================================================================
   STEP 2 — WRITES (the stored procedure). Stop it happening again.

   This replaces the UpdateProfile branch's UPDATE so that a NULL parameter
   means "leave this column alone", which is what every caller already assumes.

   Note the asymmetry, which is deliberate:
     * NULL            -> keep the stored value (the field was not supplied)
     * '' on email     -> clear it (the profile editor genuinely removes it)
     * '' on username  -> keep it (a blank username could never be valid, and
                          would lock the account out exactly as now)

   Run STEP 2 even if STEP 1 returned no rows — it is the actual bug fix.

   This one is a hand edit, not a script to execute: sp_UserLogin is a very
   large procedure with dozens of unrelated branches, and reproducing all of it
   here to change two statements would risk shipping a stale copy of the rest.

   In SSMS: Object Explorer -> Programmability -> Stored Procedures ->
   sp_UserLogin -> right-click -> Modify. Locate:

       IF @operation = 'UpdateProfile'
       BEGIN
           Update UserLogin set contact_no =@contact_no, ... where user_id=@user_id
           update owner_master set pre_mob=@contact_no ,email=@email where owner_id=@owner_id
       END

   and replace the two Update statements inside it with these two, then hit
   Execute to ALTER the procedure:
   --------------------------------------------------------------------------- */

/*
           UPDATE UserLogin
           SET contact_no = CASE WHEN @contact_no IS NULL THEN contact_no ELSE @contact_no END,
               email      = CASE WHEN @email      IS NULL THEN email      ELSE @email      END,
               password   = CASE WHEN @Password IS NULL OR @Password = '' THEN password ELSE @Password END,
               username   = CASE WHEN @username IS NULL OR @username = '' THEN username ELSE @username END,
               Name       = CASE WHEN @Name     IS NULL OR @Name     = '' THEN Name     ELSE dbo.InitCap(@Name) END,
               photo_path = CASE WHEN @photo_path IS NULL THEN photo_path
                                 WHEN @photo_path = ''    THEN NULL
                                 ELSE @photo_path END
           WHERE user_id = @user_id;

           UPDATE owner_master
           SET pre_mob = CASE WHEN @contact_no IS NULL THEN pre_mob ELSE @contact_no END,
               email   = CASE WHEN @email      IS NULL THEN email   ELSE @email      END
           WHERE owner_id = @owner_id;
*/


/* ===========================================================================
   STEP 3 — READ ONLY. What can still be recovered automatically?

   Nothing in the database holds the old username: it was overwritten and there
   is no history table, so it has to be retyped. The phone and email may have
   survived in owner_master — the blanking call passed owner_id = 0 for most
   accounts, which spared that row.

   Put your user_id from STEP 1 in both places.
   =========================================================================== */

DECLARE @user_id INT = 0;   -- <<< from STEP 1

SELECT u.user_id,
       u.name,
       u.username    AS username_now,
       u.email       AS email_now,
       u.contact_no  AS contact_now,
       o.owner_id,
       o.pre_mob     AS phone_in_owner_master,
       o.email       AS email_in_owner_master
FROM dbo.UserLogin u
LEFT JOIN dbo.owner_master o ON o.owner_id = u.owner_id
WHERE u.user_id = @user_id;
GO


/* ===========================================================================
   STEP 4 — WRITES. Put the identity back.

   Fill in the three values, set the user_id, then run.

   Do NOT touch the password. The change the user made did go through — it was
   only the username that went missing — so their NEW password is the one that
   works the moment the username is back.
   =========================================================================== */

/*
UPDATE dbo.UserLogin
SET username   = N'the_username',        -- <<< the username they log in with
    email      = N'user@example.com',    -- <<< from STEP 3, or retyped
    contact_no = N'9876543210'           -- <<< from STEP 3, or retyped
WHERE user_id = 0;                       -- <<< from STEP 1

-- Confirm:
SELECT user_id, name, username, email, contact_no
FROM dbo.UserLogin
WHERE user_id = 0;
*/


/* ===========================================================================
   STEP 5 — WRITES (the stored procedure). Optional, but do it before the
   backend deploy that ends other sessions on a password change.

   Adds 'revoke_all_for_user' to ManageRefreshToken, so changing a password
   actually signs the account out of its other devices. Without it a session
   opened under the old password keeps refreshing for its full 7 days.

   The whole ALTER is in the companion file — run that file as-is:
       docs/proposed-sql/03-ManageRefreshToken-revoke_all_for_user.sql

   Deploy it BEFORE the backend change: an unknown @operation falls through to
   the proc's 'Invalid operation' SELECT rather than raising, so the old proc
   with the new backend would report success and revoke nothing.
   =========================================================================== */
