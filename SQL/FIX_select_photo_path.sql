/*
 * /auth/me returns the profile photo.
 *
 * The bug
 * -------
 * ADD_userlogin_photo_path.sql put photo_path into sp_UserLogin's GetProfile
 * branch, which is what the website's profile dialog reads. But the signed-in
 * user is re-read somewhere else entirely:
 *
 *     // backend/web/routes/auth.js
 *     async function findUserById(userId) {
 *       const rows = await query('sp_UserLogin', { operation: 'Select', ... });
 *
 * GET /auth/me, POST /auth/login and POST /auth/refresh all go through that
 * function, and the 'Select' branch has no photo_path in its column list. So
 * publicUser() reads `row.photo_path` as undefined and answers null every time.
 *
 * The effect is that a photo saves correctly and displays in the one place that
 * calls GetProfile — the website's profile dialog — and nowhere else. The app's
 * profile screen, the app bar avatar and the website's header avatar all read
 * the session built from /auth/me, so all three keep showing initials no matter
 * what is stored.
 *
 * The fix
 * -------
 * Add UserLogin.photo_path to the 'Select' branch's column list, beside
 * owner_id. Nothing else changes: it is one more column on a SELECT, and every
 * caller already passes the row through publicUser(), which picks fields by
 * name and ignores the rest.
 *
 * Requires ADD_userlogin_photo_path.sql to have run first — that is what
 * creates the column this selects.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_UserLogin'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_UserLogin not found.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.UserLogin') AND name = 'photo_path'
)
BEGIN
    RAISERROR('UserLogin.photo_path does not exist - run ADD_userlogin_photo_path.sql first.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%select_photo_ok%'
BEGIN
    PRINT 'sp_UserLogin: Select already returns photo_path.';
    SET @stop = 1;
END

/*
 * The owner_id line in the Select branch. Anchored on the two lines together
 * because `dbo.UserLogin.owner_id` alone appears in other branches too — this
 * pairing, with the tenant CASE that follows it, is unique to Select.
 *
 * The stored body uses LF here; matching a single line rather than a span keeps
 * this independent of that.
 */
DECLARE @old NVARCHAR(MAX) = N'dbo.UserLogin.village_id,';
DECLARE @new NVARCHAR(MAX) =
    N'/* select_photo_ok */ dbo.UserLogin.photo_path,' + CHAR(10) +
    N'                    dbo.UserLogin.village_id,';

DECLARE @branchAt INT = CASE WHEN @stop = 0
                             THEN CHARINDEX(N'@operation = ''Select''', @body)
                             ELSE 0 END;

IF @stop = 0 AND @branchAt = 0
BEGIN
    RAISERROR('Could not locate the Select branch - apply by hand.', 16, 1);
    SET @stop = 1;
END

/* Replace by position, from the branch onwards — the text repeats elsewhere. */
DECLARE @colAt INT = CASE WHEN @stop = 0
                          THEN CHARINDEX(@old, @body, @branchAt)
                          ELSE 0 END;

IF @stop = 0 AND @colAt = 0
BEGIN
    RAISERROR('Could not locate the Select column list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = STUFF(@body, @colAt, LEN(@old), @new);

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_UserLogin: Select now returns photo_path.';
END
GO

/* ---------------------------------------------------------- verification */

IF OBJECT_DEFINITION(OBJECT_ID('dbo.sp_UserLogin')) NOT LIKE '%select_photo_ok%'
BEGIN
    PRINT 'Verification skipped - the procedure was not patched.';
    RETURN;
END

/*
 * Runs the exact call /auth/me makes. photo_path must appear as a column; if it
 * does not, the session the app and website build will keep showing initials.
 */
DECLARE @uid INT = (SELECT TOP 1 user_id FROM dbo.UserLogin
                    WHERE photo_path IS NOT NULL AND photo_path <> ''
                    ORDER BY user_id);

IF @uid IS NULL
    SET @uid = (SELECT TOP 1 user_id FROM dbo.UserLogin ORDER BY user_id);

PRINT 'Select for user ' + CAST(@uid AS NVARCHAR(10))
    + ' - photo_path should be among the columns below:';

EXEC dbo.sp_UserLogin @operation = 'Select', @user_id = @uid;
GO
