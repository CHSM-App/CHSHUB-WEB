/*
 * A profile photo for the signed-in user.
 *
 * The gap
 * -------
 * The profile editor can pick a photo and POST /uploads/profile-photos already
 * stores the file and returns its path, but there is nowhere to keep that path:
 * dbo.UserLogin has no photo column at all.
 *
 *     [user_id] [int] NOT NULL,
 *     [user_type_id] [int] NULL,
 *     [name] [nvarchar](500) NULL,
 *     ...
 *     [owner_id] [int] NULL
 *
 * GET /onboarding/profile already returns `photo_path: row.photo_path ?? null`,
 * so the API was written expecting this column — it has simply always answered
 * null, because neither the table nor sp_UserLogin's GetProfile branch has it.
 *
 * This script
 * -----------
 *   1. Adds UserLogin.photo_path — nvarchar(500), the same width the other
 *      upload paths in this database use (owner_documents.doc_path), and NULL
 *      for every existing row, which reads as "no photo".
 *   2. Adds it to sp_UserLogin's GetProfile SELECT, so reading a profile
 *      returns it.
 *   3. Writes it in the UpdateProfile branch, guarded the way @Name is: NULL
 *      means "leave the stored photo alone", so change-password (which sends no
 *      photo) cannot clear one. Clearing is done by passing the empty string,
 *      which is what the editor's "Remove photo" sends.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* ------------------------------------------------------------ 1. column -- */

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.UserLogin') AND name = 'photo_path'
)
BEGIN
    ALTER TABLE dbo.UserLogin ADD photo_path NVARCHAR(500) NULL;
    PRINT 'UserLogin: photo_path added.';
END
ELSE
    PRINT 'UserLogin: photo_path already present.';
GO

/* ----------------------------------------------------------- 2. + 3. SP -- */

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_UserLogin'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_UserLogin not found.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%photo_path_ok%'
BEGIN
    PRINT 'sp_UserLogin: photo_path already handled.';
    SET @stop = 1;
END

/*
 * The procedure has no @photo_path parameter yet. It is appended to the last
 * parameter in the signature — single-line anchors throughout, because the
 * stored body's line endings are not this file's.
 */
DECLARE @oldParams NVARCHAR(MAX) = N'@v_name NVARCHAR(100) = NULL, @flat_id int = 0';
DECLARE @newParams NVARCHAR(MAX) =
    N'@v_name NVARCHAR(100) = NULL, @flat_id int = 0, @photo_path NVARCHAR(500) = NULL';

IF @stop = 0 AND CHARINDEX(@oldParams, @body) = 0
BEGIN
    RAISERROR('Could not locate the parameter list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldParams, @newParams);

/* GetProfile's column list, so reading a profile returns the photo. */
DECLARE @oldSelect NVARCHAR(MAX) =
    N'userlogin.contact_no,userlogin.email,UserLogin.owner_id';
DECLARE @newSelect NVARCHAR(MAX) =
    N'userlogin.contact_no,userlogin.email,UserLogin.owner_id' +
    N', /* photo_path_ok */ UserLogin.photo_path';

IF @stop = 0 AND CHARINDEX(@oldSelect, @body) = 0
BEGIN
    RAISERROR('Could not locate the GetProfile column list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldSelect, @newSelect);

/*
 * UpdateProfile's SET list. NULL leaves the stored photo alone so a password
 * change cannot clear it; '' clears it, which is what "Remove photo" sends.
 */
/*
 * Anchored on the end of the Name clause rather than on the whole SET list.
 *
 * FIX_updateprofile_name.sql leaves its own marker comment inside that list —
 * `username=@username, /* updateprofile_name_ok */ Name = ...` — so matching
 * the list as one literal only worked before that script had run, which is
 * exactly backwards. This tail is stable either way: it is the end of the Name
 * clause and the WHERE that closes the statement, and it appears once.
 */
DECLARE @oldUpdate NVARCHAR(MAX) =
    N'then Name else dbo.InitCap(@Name) end where user_id=@user_id';
DECLARE @newUpdate NVARCHAR(MAX) =
    N'then Name else dbo.InitCap(@Name) end' +
    N', /* photo_path_ok */ photo_path = case when @photo_path is null then photo_path when @photo_path = '''' then null else @photo_path end' +
    N' where user_id=@user_id';

IF @stop = 0 AND CHARINDEX(@oldUpdate, @body) = 0
BEGIN
    RAISERROR('Could not locate the UpdateProfile SET list - run FIX_updateprofile_name.sql first.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldUpdate, @newUpdate);

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_UserLogin: photo_path now read and written.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * Skipped unless the patch above actually applied. GO ends the batch, so the
 * @stop flag cannot carry across — the procedure's own text is re-read instead.
 * Without this the verification ran even when the patch had failed, reporting
 * "@photo_path is not a parameter" on top of the real error and burying it.
 */
IF OBJECT_DEFINITION(OBJECT_ID('dbo.sp_UserLogin')) NOT LIKE '%photo_path_ok%'
BEGIN
    PRINT 'Verification skipped - the procedure was not patched.';
    RETURN;
END

/*
 * Every argument is read into a variable first. A subquery cannot be passed
 * directly as a procedure parameter — `EXEC p @x = (SELECT ...)` is a syntax
 * error, not a runtime one, so it takes the whole batch down with it.
 */
DECLARE @uid INT = (SELECT TOP 1 user_id FROM dbo.UserLogin ORDER BY user_id);
DECLARE @was NVARCHAR(500);
DECLARE @u NVARCHAR(50), @e NVARCHAR(100), @c NVARCHAR(50);
DECLARE @o INT;

SELECT @was = photo_path,
       @u   = username,
       @e   = email,
       @c   = contact_no,
       @o   = ISNULL(owner_id, 0)
FROM   dbo.UserLogin
WHERE  user_id = @uid;

DECLARE @now NVARCHAR(500);

PRINT 'User tested: ' + CAST(@uid AS NVARCHAR(10));

EXEC dbo.sp_UserLogin @operation = 'UpdateProfile', @user_id = @uid,
     @photo_path = N'profile-photos/probe.png',
     @username = @u, @email = @e, @contact_no = @c, @owner_id = @o;

/* PRINT takes an expression, and a subquery is not one — read it first. */
SELECT @now = photo_path FROM dbo.UserLogin WHERE user_id = @uid;
PRINT 'After set: ' + ISNULL(@now, '(null)');

/* No @photo_path — the value above must survive. */
EXEC dbo.sp_UserLogin @operation = 'UpdateProfile', @user_id = @uid,
     @username = @u, @email = @e, @contact_no = @c, @owner_id = @o;

SELECT @now = photo_path FROM dbo.UserLogin WHERE user_id = @uid;
PRINT 'After a no-photo update (should be unchanged): ' + ISNULL(@now, '(null)');

/* Empty string clears it. */
EXEC dbo.sp_UserLogin @operation = 'UpdateProfile', @user_id = @uid,
     @photo_path = N'',
     @username = @u, @email = @e, @contact_no = @c, @owner_id = @o;

SELECT @now = photo_path FROM dbo.UserLogin WHERE user_id = @uid;
PRINT 'After clear (should be null): ' + ISNULL(@now, '(null)');

UPDATE dbo.UserLogin SET photo_path = @was WHERE user_id = @uid;
PRINT 'Restored.';
GO
