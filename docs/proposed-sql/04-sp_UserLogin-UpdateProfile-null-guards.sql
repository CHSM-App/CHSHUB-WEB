/* ============================================================================
   sp_UserLogin — UpdateProfile: stop NULLs from wiping username/email/contact

   THE BUG
   -------
   The UpdateProfile branch guards some columns against a NULL parameter and
   not others:

       password   = case when @Password is null or @Password = '' then password else @Password end   -- guarded
       Name       = case when @Name     is null or @Name     = '' then Name     else ... end          -- guarded
       photo_path = case when @photo_path is null then photo_path ... end                             -- guarded
       username   = @username        -- NOT guarded
       contact_no = @contact_no      -- NOT guarded
       email      = @email           -- NOT guarded

   /onboarding/change-password calls this branch to write only the password. It
   sends no username, email or contact_no, so those three arrive NULL and the
   unguarded assignments overwrite the stored values with NULL.

   The account is then unreachable: `validateuser` looks the user up by
   username, and the row no longer has one. Login answers "Invalid username or
   password" for the correct password, which reads as a password problem and is
   really a wiped identity. The same call also empties the address and phone
   number used for password reset, so the usual self-service recovery is gone
   too.

   Anyone who changed their password through the app or the website is
   affected. See the recovery section at the bottom — the code fix stops new
   damage but does not restore rows already blanked.

   THE FIX
   -------
   Give the three unguarded columns the same treatment the others already have:
   a NULL parameter means "leave this column alone". That is what every caller
   already assumes — change-password omits them expecting them to be untouched,
   and the profile editor always sends them, so it is unaffected.

   Empty string is deliberately NOT treated as "leave alone" for email and
   contact_no: clearing an address or a phone number is a legitimate edit, and
   the profile editor sends '' to mean exactly that. Only NULL — "I did not
   supply this field" — preserves. `username` preserves on '' as well, since a
   blank username can never be valid and would lock the account out again.

   DEPLOY
   ------
   Safe on a live database: it only narrows when a write happens. Deploy this
   BEFORE or WITH the backend change; it is independent of
   03-ManageRefreshToken-revoke_all_for_user.sql and can go first.
   ============================================================================ */

USE [society]
GO

/* ---------------------------------------------------------------------------
   1. THE FIX — replace the UpdateProfile branch's UPDATE with this one.

   This is the single statement to change inside sp_UserLogin's
   `IF @operation = 'UpdateProfile'` block. The rest of the proc is untouched.
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

           -- Same guard here: change-password sends no contact_no or email, and
           -- must not blank the owner's record either.
           UPDATE owner_master
           SET pre_mob = CASE WHEN @contact_no IS NULL THEN pre_mob ELSE @contact_no END,
               email   = CASE WHEN @email      IS NULL THEN email   ELSE @email      END
           WHERE owner_id = @owner_id;
*/


/* ---------------------------------------------------------------------------
   2. ASSESS THE DAMAGE — run this first, before repairing anything.

   Lists every account the bug has already blanked. An account with no username
   cannot log in at all; one with no email cannot use the password-reset flow.
   --------------------------------------------------------------------------- */

SELECT user_id,
       name,
       username,
       email,
       contact_no,
       user_type_id,
       society_id,
       CASE WHEN username IS NULL OR username = '' THEN 'CANNOT LOG IN' ELSE '' END AS login_state,
       CASE WHEN email    IS NULL OR email    = '' THEN 'CANNOT RESET'  ELSE '' END AS reset_state
FROM dbo.UserLogin
WHERE username   IS NULL OR username   = ''
   OR email      IS NULL OR email      = ''
   OR contact_no IS NULL OR contact_no = ''
ORDER BY user_id DESC;
GO


/* ---------------------------------------------------------------------------
   3. RECOVER ONE ACCOUNT — the values are gone, so they must be re-supplied.

   Nothing in the database holds the old username: the UPDATE overwrote it and
   there is no history table. owner_master may still carry the phone and email
   if the account is linked to an owner (@owner_id was 0 for the blanking call,
   so that row was often spared) — check there before typing values in by hand.
   --------------------------------------------------------------------------- */

-- 3a. What owner_master still knows, if the account is linked to an owner:
/*
SELECT u.user_id, u.name, u.username, o.owner_id, o.pre_mob, o.email
FROM dbo.UserLogin u
LEFT JOIN dbo.owner_master o ON o.owner_id = u.owner_id
WHERE u.user_id = @user_id;
*/

-- 3b. Put the identity back. Set the three values, then run.
--     Password is NOT touched here: the change the user made did go through,
--     so their new password is the one that works once the username is back.
/*
UPDATE dbo.UserLogin
SET username   = N'the_username',
    email      = N'user@example.com',
    contact_no = N'9876543210'
WHERE user_id = 0;   -- <- the user_id from step 2
*/

-- 3c. Confirm the account is reachable again:
/*
SELECT user_id, name, username, email, contact_no
FROM dbo.UserLogin
WHERE user_id = 0;
*/
GO
