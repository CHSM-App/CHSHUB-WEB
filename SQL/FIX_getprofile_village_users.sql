/*
 * A village account can open its own profile.
 *
 * The bug
 * -------
 * Signing in as a village user and opening Profile reports "Account no longer
 * exists". The account is there — sp_UserLogin's GetProfile branch cannot see
 * it:
 *
 *     FROM       dbo.UserLogin
 *     INNER JOIN dbo.UserType      ON ...
 *     INNER JOIN dbo.society_master ON UserLogin.society_id = society_master.society_id
 *     WHERE      user_id = @user_id
 *
 * A village user has society_id NULL — it belongs to a village, not a society —
 * so the INNER JOIN drops the row and the procedure returns nothing. The API
 * reads that as the account having been deleted.
 *
 * Every village user is affected: all five in this database have a NULL
 * society_id, so none of them can open Profile at all.
 *
 * The fix
 * -------
 *   - LEFT JOIN society_master, so a user with no society keeps their row.
 *   - LEFT JOIN village_master alongside it and return village_id and
 *     Village_name, so a village account's profile can name where it belongs
 *     the way a society account's does.
 *   - UserType stays an INNER JOIN: every account has a type, and one without
 *     is broken in a way that should not be papered over.
 *
 * Society_name keeps its name and position, so anything reading it is
 * unaffected; it is simply NULL for a village user, as it always logically was.
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

IF @stop = 0 AND @body LIKE '%getprofile_village_ok%'
BEGIN
    PRINT 'sp_UserLogin: GetProfile already serves village accounts.';
    SET @stop = 1;
END

/*
 * Single-line anchors: the stored body uses CRLF and mixes tabs with spaces,
 * so a literal spanning lines would not match.
 */
DECLARE @oldCols NVARCHAR(MAX) =
    N'dbo.society_master.name AS Society_name,userlogin.contact_no,userlogin.email,UserLogin.owner_id';

DECLARE @newCols NVARCHAR(MAX) =
    N'dbo.society_master.name AS Society_name,userlogin.contact_no,userlogin.email,UserLogin.owner_id' +
    N', /* getprofile_village_ok */ dbo.UserLogin.village_id, dbo.village_master.name AS Village_name';

IF @stop = 0 AND CHARINDEX(@oldCols, @body) = 0
BEGIN
    RAISERROR('Could not locate the GetProfile column list - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = REPLACE(@body, @oldCols, @newCols);

/*
 * The join that drops village accounts. This text appears once — other
 * branches join society_master differently — but it is replaced by position
 * from the GetProfile marker anyway, so a later branch cannot be caught by it.
 */
/*
 * One line, so the file's own line endings cannot matter — the stored body
 * uses LF here while other procedures in this database use CRLF, and a literal
 * spanning lines would only match one of them.
 *
 * The text appears three times across the procedure, so it is replaced by
 * position from the GetProfile marker rather than with REPLACE.
 */
DECLARE @oldJoin NVARCHAR(MAX) =
    N'dbo.society_master ON dbo.UserLogin.society_id = dbo.society_master.society_id';

DECLARE @newJoin NVARCHAR(MAX) =
    N'dbo.society_master ON dbo.UserLogin.society_id = dbo.society_master.society_id ' +
    N'LEFT JOIN dbo.village_master ON dbo.UserLogin.village_id = dbo.village_master.village_id';

DECLARE @branchAt INT = CASE WHEN @stop = 0 THEN CHARINDEX(N'GetProfile''', @body) ELSE 0 END;

IF @stop = 0 AND @branchAt = 0
BEGIN
    RAISERROR('Could not locate the GetProfile branch - apply by hand.', 16, 1);
    SET @stop = 1;
END

DECLARE @joinAt INT = CASE WHEN @stop = 0
                           THEN CHARINDEX(@oldJoin, @body, @branchAt)
                           ELSE 0 END;

IF @stop = 0 AND @joinAt = 0
BEGIN
    RAISERROR('Could not locate the GetProfile society join - apply by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 SET @body = STUFF(@body, @joinAt, LEN(@oldJoin), @newJoin);

/*
 * The INNER that precedes it. Searched backwards from the join just rewritten:
 * it is the last "INNER JOIN" before it, and turning that one into a LEFT is
 * what stops a village account being dropped.
 */
DECLARE @innerAt INT = 0;

IF @stop = 0
BEGIN
    DECLARE @scan INT = @branchAt;
    WHILE 1 = 1
    BEGIN
        DECLARE @next INT = CHARINDEX(N'INNER JOIN', @body, @scan);
        IF @next = 0 OR @next > @joinAt BREAK;
        SET @innerAt = @next;
        SET @scan = @next + 1;
    END

    IF @innerAt = 0
    BEGIN
        RAISERROR('Could not locate the INNER before the society join - apply by hand.', 16, 1);
        SET @stop = 1;
    END
END

IF @stop = 0 SET @body = STUFF(@body, @innerAt, LEN(N'INNER JOIN'), N'LEFT JOIN');

IF @stop = 0
BEGIN
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');
    EXEC sp_executesql @body;
    PRINT 'sp_UserLogin: GetProfile now returns village accounts too.';
END
GO

/* ---------------------------------------------------------- verification */

/*
 * Every active account should come back. Before this, the ones with a village
 * and no society returned nothing at all.
 */
DECLARE @uid INT = (SELECT TOP 1 user_id FROM dbo.UserLogin
                     WHERE village_id IS NOT NULL AND village_id <> '' ORDER BY user_id);

PRINT 'Village user tested: ' + CAST(@uid AS NVARCHAR(10));
EXEC dbo.sp_UserLogin @operation = 'GetProfile', @user_id = @uid;

DECLARE @sid INT = (SELECT TOP 1 user_id FROM dbo.UserLogin
                     WHERE society_id IS NOT NULL AND society_id <> '' ORDER BY user_id);

PRINT 'Society user tested: ' + CAST(@sid AS NVARCHAR(10));
EXEC dbo.sp_UserLogin @operation = 'GetProfile', @user_id = @sid;
GO
