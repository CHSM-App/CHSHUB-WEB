/*
 * Editing your profile can change your name.
 *
 * The bug
 * -------
 * PUT /onboarding/profile builds the display name from the first/last name
 * fields and passes it to sp_UserLogin as @Name:
 *
 *     await exec('sp_UserLogin', {
 *       operation: 'UpdateProfile',
 *       Name: { type: sql.NVarChar(500), value: name },
 *       ...
 *
 * The UpdateProfile branch never reads it:
 *
 *     Update UserLogin
 *     set contact_no = @contact_no, email = @email,
 *         password = case when @Password is null or @Password = '' then password else @Password end,
 *         username = @username
 *     where user_id = @user_id
 *
 * There is no Name column in the SET list, so the parameter is accepted and
 * discarded. The route then re-reads the row and returns the *stored* name, so
 * the client's own refresh quietly puts the old name back — the edit looks like
 * it was rejected rather than ignored. Every caller is affected: the web
 * profile dialog and the Secretary app's profile editor both send a name here.
 *
 * The fix
 * -------
 * Add Name to the SET list, guarded the same way the password already is:
 *
 *     Name = case when @Name is null or @Name = '' then Name else dbo.InitCap(@Name) end
 *
 * The guard is what keeps the other caller safe. POST /onboarding/change-password
 * goes through this same branch and passes no @Name at all, so without it a
 * password change would blank the account's name. NULL and '' both mean "leave
 * it alone", which is the convention @Password already uses here.
 *
 * dbo.InitCap matches how the 'Update' branch writes names, so a name saved
 * from the profile editor is cased the same as one saved from the committee
 * member editor.
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

IF @stop = 0 AND @body LIKE '%updateprofile_name_ok%'
BEGIN
    PRINT 'sp_UserLogin: UpdateProfile already writes the name.';
    SET @stop = 1;
END

/*
 * A single-line anchor: the stored body mixes tabs with spaces and its line
 * endings are not the ones this file is saved with, so a literal spanning
 * lines would not match. This text is unique to the UpdateProfile branch —
 * it is the only UPDATE in the procedure that sets username without also
 * setting user_type_id.
 */
DECLARE @old NVARCHAR(MAX) =
    N'password= case when @Password is  null or @Password ='''' then password else @Password end,username=@username where user_id=@user_id';

DECLARE @new NVARCHAR(MAX) =
    N'password= case when @Password is  null or @Password ='''' then password else @Password end,username=@username' +
    N', /* updateprofile_name_ok */ Name = case when @Name is null or @Name = '''' then Name else dbo.InitCap(@Name) end' +
    N' where user_id=@user_id';

IF @stop = 0 AND CHARINDEX(@old, @body) = 0
BEGIN
    RAISERROR('Could not locate the UpdateProfile statement - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0
BEGIN
    SET @body = REPLACE(@body, @old, @new);
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_UserLogin: UpdateProfile now writes the name.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * Round-trips one account: rename it, confirm the new name came back, then put
 * the original name back. The second call passes no @Name and must leave the
 * name it just wrote alone — that is the case a password change exercises.
 */
/*
 * Every argument is read into a variable first. A subquery cannot be passed
 * directly as a procedure parameter — `EXEC p @x = (SELECT ...)` is a syntax
 * error, not a runtime one, so it takes the whole batch down with it.
 */
DECLARE @uid INT = (SELECT TOP 1 user_id FROM dbo.UserLogin ORDER BY user_id);
DECLARE @was NVARCHAR(500);
DECLARE @u NVARCHAR(50), @e NVARCHAR(100), @c NVARCHAR(50);
DECLARE @o INT;

SELECT @was = Name,
       @u   = username,
       @e   = email,
       @c   = contact_no,
       @o   = ISNULL(owner_id, 0)
FROM   dbo.UserLogin
WHERE  user_id = @uid;

DECLARE @now NVARCHAR(500);

PRINT 'User tested: ' + CAST(@uid AS NVARCHAR(10)) + ', name was: ' + ISNULL(@was, '(null)');

EXEC dbo.sp_UserLogin @operation = 'UpdateProfile', @user_id = @uid, @Name = N'Zzz Rename Probe',
     @username = @u, @email = @e, @contact_no = @c, @owner_id = @o;

/* PRINT takes an expression, and a subquery is not one — read it first. */
SELECT @now = Name FROM dbo.UserLogin WHERE user_id = @uid;
PRINT 'After rename: ' + ISNULL(@now, '(null)');

/* No @Name — the name above must survive this. */
EXEC dbo.sp_UserLogin @operation = 'UpdateProfile', @user_id = @uid,
     @username = @u, @email = @e, @contact_no = @c, @owner_id = @o;

SELECT @now = Name FROM dbo.UserLogin WHERE user_id = @uid;
PRINT 'After a no-name update (should be unchanged): ' + ISNULL(@now, '(null)');

UPDATE dbo.UserLogin SET Name = @was WHERE user_id = @uid;
PRINT 'Restored to: ' + ISNULL(@was, '(null)');
GO
