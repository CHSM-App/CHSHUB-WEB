/* ============================================================================
   sp_UserLogin — 'Update' branch: stop a missing password from wiping it

   THE BUG
   -------
   The 'Update' branch (used when an admin edits another user's account) writes
   the password like this:

       Password = case when @Password is not null or @Password != '' then @Password end

   Two faults in one line:

   1. `or` should be `and`. As written, supplying a password satisfies the first
      test and skips the second, which happens to work — but see below for what
      happens when one is NOT supplied.

   2. There is no ELSE. A CASE with no matching WHEN and no ELSE evaluates to
      NULL, so any call that fails the condition sets Password = NULL.

   Together, a NULL @Password gives:
       (NULL IS NOT NULL)  -> false
       (NULL != '')        -> UNKNOWN            (NULL compares to nothing)
       false OR UNKNOWN    -> UNKNOWN            (not true)
   The WHEN does not match, there is no ELSE, and the password becomes NULL.
   The account can no longer log in, exactly as the UpdateProfile bug did to
   the username.

   Empty string is the same story:
       ('' IS NOT NULL)    -> true
       -> WHEN matches, and Password is set to ''.
   An empty password is stored, which no login can ever match.

   IS THIS CURRENTLY BITING?
   -------------------------
   Not from the website. backend/web/routes/masters/misc.js reads the existing
   row first and passes `current.password` back when the form left the field
   blank, so the proc always receives a real value. The guard below is what
   makes that defensive read unnecessary rather than load-bearing — any other
   caller, or a future one that forgets, would silently destroy an account.

   THE FIX
   -------
   The same shape UpdateProfile and ResetPass already use: NULL or '' means
   "not supplied, keep what is stored".

   DEPLOY
   ------
   Safe on a live database — it only narrows when a write happens. Independent
   of the other scripts here; order does not matter.
   ============================================================================ */

USE [society]
GO

/* ---------------------------------------------------------------------------
   Open sp_UserLogin for ALTER (Object Explorer -> Programmability ->
   Stored Procedures -> sp_UserLogin -> Modify), find the 'Update' branch's
   ELSE block, and replace this line:

       Password    = case when @Password is not null or @Password !='' then @Password end,

   with this one:

       Password    = case when @Password is null or @Password = '' then Password else @Password end,

   Leave every other line in that UPDATE alone. Then Execute.
   --------------------------------------------------------------------------- */

/* For reference, the branch reads like this once fixed:

    IF @operation = 'Update'
        BEGIN
            IF @user_id = 0
                BEGIN
                    ... unchanged INSERT ...
                END
            ELSE
                BEGIN
                    UPDATE dbo.UserLogin
                    SET    user_type_id  = @user_type_id,
                           Name        = dbo.InitCap(@Name),
                           UserName    = @UserName,
                           Password    = case when @Password is null or @Password = '' then Password else @Password end,
                           email=@email,
                           contact_no=@contact_no,
                           active_status      = @active_status,
                           owner_id=@owner_id,
                           type        = @type,
                           society_id  = @society_id,
                           village_id  = @village_id
                    WHERE  user_id = @user_id;

                    SELECT @user_id AS user_id;
                END
        END
*/


/* ---------------------------------------------------------------------------
   VERIFY — accounts with no usable password.

   Run after deploying. Rows here cannot log in whatever password is typed.
   Recover them the same way as the username case: set a known password hash
   through the app's own change-password flow, or have the user reset.
   --------------------------------------------------------------------------- */

SELECT user_id, name, username, email, contact_no, society_id
FROM dbo.UserLogin
WHERE (password IS NULL OR password = '')
  AND active_status = 0
ORDER BY user_id DESC;
GO
