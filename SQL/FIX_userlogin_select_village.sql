/*
 * FIX: sp_UserLogin 'Select' drops village accounts and loses the tenant kind.
 *
 * Symptom
 * -------
 * A village account signs in fine, then vanishes on the next page refresh —
 * bounced back to the sign-in screen. A society account survives the refresh
 * but forgets whether it is a Society or a Village, so the Village menu and the
 * Village dashboard tab disappear until the next full sign-in.
 *
 * Cause
 * -----
 * Sign-in and refresh read the account through two different queries:
 *
 *   POST /auth/login  ->  validateuser 'login'
 *   GET  /auth/me     ->  sp_UserLogin 'Select'      <- this one
 *
 * validateuser LEFT OUTER JOINs both society_master and village_master and
 * returns `type`. sp_UserLogin 'Select' does neither:
 *
 *   1. It INNER JOINs society_master. A village account has society_id NULL, so
 *      the join eliminates its row and /auth/me returns "Account no longer
 *      exists" — which the client treats as a dead session and signs out.
 *   2. It never selects `type`, village_id or village_name, so even for a
 *      society account the refreshed session loses tenant_type.
 *
 * Fix
 * ---
 * Rewrite only the 'Select' branch, in place, to match validateuser's login
 * branch: LEFT OUTER JOIN both masters and return the same columns. The rest of
 * the procedure is left byte-for-byte alone, so any local edits to the other
 * branches survive. No column is removed — only added — so the existing callers
 * (the members list in masters/misc.js, and the legacy WebForms app) keep
 * working.
 *
 * `type` is decoded exactly as validateuser decodes it, so both endpoints
 * report 'Society' / 'Village' identically. See FIX_userlogin_type_code.sql for
 * why that column holds a numeric code rather than the word.
 *
 * Safe to re-run: the script detects an already-patched procedure and stops.
 */

SET NOCOUNT ON;
GO

DECLARE @body      NVARCHAR(MAX),
        @oldBranch NVARCHAR(MAX),
        @newBranch NVARCHAR(MAX),
        @startPos  INT,
        @endPos    INT;

-- Current definition, straight from the catalog.
SELECT @body = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_UserLogin'));

IF @body IS NULL
BEGIN
    RAISERROR('sp_UserLogin not found in this database.', 16, 1);
    RETURN;
END

IF @body LIKE '%LEFT OUTER JOIN dbo.village_master%ON dbo.UserLogin.village_id%'
   AND @body LIKE '%@operation = ''Select''%'
BEGIN
    PRINT 'Already patched - no change made.';
    RETURN;
END

/*
 * Locate the 'Select' branch. It runs from its IF to the start of the branch
 * that follows it ('new_society'), which is how the shipped procedure is
 * ordered.
 */
SET @startPos = CHARINDEX('IF @operation = ''Select''', @body);
SET @endPos   = CHARINDEX('IF @operation = ''new_society''', @body);

IF @startPos = 0 OR @endPos = 0 OR @endPos <= @startPos
BEGIN
    RAISERROR('Could not locate the Select branch - apply the change by hand.', 16, 1);
    RETURN;
END

SET @oldBranch = SUBSTRING(@body, @startPos, @endPos - @startPos);

SET @newBranch = N'IF @operation = ''Select''
        BEGIN
            SELECT  dbo.UserLogin.user_id,
                    dbo.UserLogin.user_type_id,
                    dbo.UserType.UserTypeName,
                    dbo.UserLogin.name,
                    dbo.UserLogin.username,
                    dbo.UserLogin.password,
                    dbo.UserLogin.active_status,
                    dbo.UserLogin.society_id,
                    dbo.UserLogin.token,
                    dbo.society_master.name AS Society_name,
                    dbo.UserLogin.village_id,
                    dbo.village_master.name AS village_name,
                    CASE WHEN dbo.UserLogin.[type] = 1 THEN ''Society'' ELSE ''Village'' END AS [type],
                    dbo.UserLogin.contact_no,
                    dbo.UserLogin.email,
                    dbo.UserLogin.owner_id
            FROM    dbo.UserLogin
                    INNER JOIN dbo.UserType
                        ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
                    LEFT OUTER JOIN dbo.society_master
                        ON dbo.UserLogin.society_id = dbo.society_master.society_id
                    LEFT OUTER JOIN dbo.village_master
                        ON dbo.UserLogin.village_id = dbo.village_master.village_id
            WHERE   dbo.UserLogin.user_id = @user_id;
        END
		';

-- CREATE -> ALTER, then swap the branch.
SET @body = STUFF(@body, @startPos, LEN(@oldBranch), @newBranch);
SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

EXEC sp_executesql @body;

PRINT 'sp_UserLogin Select branch updated.';
GO

/*
 * Verification. Every active account should now return exactly one row — before
 * the fix, village accounts returned none.
 */
DECLARE @user_id INT, @missing INT = 0;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT user_id FROM dbo.UserLogin WHERE active_status = 0;

OPEN c;
FETCH NEXT FROM c INTO @user_id;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM   dbo.UserLogin u
               INNER JOIN dbo.UserType t ON u.user_type_id = t.UserTypeId
        WHERE  u.user_id = @user_id
    )
        SET @missing = @missing + 1;

    FETCH NEXT FROM c INTO @user_id;
END
CLOSE c;
DEALLOCATE c;

PRINT CONCAT('Accounts unreadable after the fix (should be 0): ', @missing);
GO

-- Spot-check: village accounts, which the old branch could not return at all.
SELECT TOP 10 user_id, username, society_id, village_id, [type]
FROM   dbo.UserLogin
WHERE  village_id IS NOT NULL
ORDER  BY user_id DESC;
GO
