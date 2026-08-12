/*
 * Carry Building Name and Unit through to the helpdesk ticket list.
 *
 * The bug
 * -------
 * The Helpdesk grid shows no building, and its unit column is the bare flat
 * number. support_ticket.aspx showed both — "Building Name" and "Unit" were
 * the two columns right after the row number.
 *
 * The legacy page did not read the same query we do. It called the
 * SupportTicket operation, which joins owner_search_vw directly:
 *
 *     SELECT ... dbo.owner_search_vw.Unit, dbo.owner_search_vw.build_name ...
 *     FROM HelpdeskRequest
 *     INNER JOIN owner_search_vw ON HelpdeskRequest.flat_id = owner_search_vw.flat_id
 *
 * The website API calls GetTickets instead, and it should: SupportTicket
 * returns HelpdeskStatus.status — the status *name* — where GetTickets returns
 * hr.status, the id. The id is what the grid's status dropdown binds to and
 * what the Open/Resolved tabs count, so moving the page onto SupportTicket
 * would trade a working status control for two columns.
 *
 * GetTickets cannot supply them today because of its UserDataCombined CTE.
 * Both branches select the same five columns:
 *
 *     SELECT owner_id, name, flat_no, society_id, type AS login_type ...
 *
 * so build_name and Unit are dropped there and never reach the outer SELECT.
 *
 * The fix
 * -------
 * Add build_name and Unit to both branches of the CTE and to the outer SELECT.
 * Both sources already carry them — owner_search_vw defines them, and the
 * owner_family view is itself built on owner_search_vw and re-exposes both —
 * so this widens what is passed through rather than adding a join.
 *
 * Nothing else changes: no row is added or removed, the join keys and the
 * ORDER BY are untouched, and every column the mobile app reads is still
 * returned under the same name, so the app keeps working either way.
 *
 * How this is applied
 * -------------------
 * sp_helpdesk is one procedure holding roughly a dozen operations, and only
 * the GetTickets branch changes. Rather than restate the whole 16 KB body —
 * which would silently revert any other operation edited since — this reads
 * the current definition, replaces three exact fragments inside it, and runs
 * the result as an ALTER.
 *
 * It is idempotent and self-checking: if the fragments are not found exactly
 * once each (already applied, or the procedure has since been edited), it
 * raises an error and changes nothing.
 */

SET NOCOUNT ON;

DECLARE @body   NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_helpdesk'));
DECLARE @owner  NVARCHAR(MAX);
DECLARE @family NVARCHAR(MAX);
DECLARE @outer  NVARCHAR(MAX);

IF @body IS NULL
    THROW 50000, 'sp_helpdesk not found.', 1;

/*
 * Already done?
 *
 * Tested against the CTE, not the whole procedure. `u.build_name` occurs in
 * sp_helpdesk before this script ever runs — GetRequestById has always
 * selected it — so a search of the whole body matches on the first run and
 * reports "already applied" without changing anything. The CTE is the one
 * place the column cannot appear until this script puts it there.
 */
IF CHARINDEX('build_name', SUBSTRING(
        @body,
        CHARINDEX('UserDataCombined AS (', @body),
        CHARINDEX('FROM owner_family', @body) - CHARINDEX('UserDataCombined AS (', @body)
    )) > 0
BEGIN
    PRINT 'Already applied — the CTE already carries build_name. No change made.';
    RETURN;
END

/*
 * The three edit points.
 *
 * Anchored on short fragments rather than whole SELECT blocks. The stored text
 * has CRLF line endings and a trailing space after each `SELECT`, so a literal
 * multi-line fragment typed here matches nothing — the first version of this
 * script failed exactly that way. @nl makes the line breaks explicit instead
 * of depending on how this file happens to be saved.
 *
 * Each anchor is the last two or three lines before the insertion point, which
 * is enough to be unique within sp_helpdesk while staying short enough not to
 * depend on incidental whitespace.
 */
DECLARE @nl NVARCHAR(2) = CHAR(13) + CHAR(10);

/* ---- 1: owner branch of the CTE ----------------------------------------- */
SET @owner = N'        society_id,' + @nl + N'        type AS login_type,';

/* ---- 2: family branch of the CTE ---------------------------------------- */
SET @family = N'        society_id,' + @nl + N'        ''Family'' AS login_type,';

/* ---- 3: outer select list ----------------------------------------------- */
SET @outer = N'    u.flat_no,' + @nl + N'    u.society_id,' + @nl + N'    u.login_type,';

/*
 * Each anchor must appear exactly once. Two matches would put the columns
 * somewhere unintended; none means the procedure no longer looks the way this
 * script expects, and guessing would be worse than stopping.
 */
DECLARE @msg NVARCHAR(400);

IF (LEN(@body) - LEN(REPLACE(@body, @owner, ''))) / NULLIF(LEN(@owner), 0) <> 1
BEGIN
    SET @msg = N'Owner branch of UserDataCombined not found exactly once — not applied.';
    THROW 50001, @msg, 1;
END

IF (LEN(@body) - LEN(REPLACE(@body, @family, ''))) / NULLIF(LEN(@family), 0) <> 1
BEGIN
    SET @msg = N'Family branch of UserDataCombined not found exactly once — not applied.';
    THROW 50002, @msg, 1;
END

IF (LEN(@body) - LEN(REPLACE(@body, @outer, ''))) / NULLIF(LEN(@outer), 0) <> 1
BEGIN
    SET @msg = N'Outer select list not found exactly once — not applied.';
    THROW 50003, @msg, 1;
END

/* The two columns go in ahead of society_id, matching owner_search_vw's own
   order. Only the added lines are new; the anchor is put back unchanged. */
SET @body = REPLACE(@body, @owner,
    N'        build_name,' + @nl +
    N'        Unit,'       + @nl + @owner);

SET @body = REPLACE(@body, @family,
    N'        build_name,' + @nl +
    N'        Unit,'       + @nl + @family);

/* This anchor spans the insertion point rather than ending at it, so it is
   rewritten whole instead of being prefixed. */
SET @body = REPLACE(@body, @outer,
    N'    u.flat_no,'    + @nl +
    N'    u.build_name,' + @nl +
    N'    u.Unit,'       + @nl +
    N'    u.society_id,' + @nl +
    N'    u.login_type,');

/* CREATE PROCEDURE -> ALTER PROCEDURE, so the existing object is replaced. */
DECLARE @create INT = PATINDEX('%CREATE%PROCEDURE%', @body);
IF @create = 0
    THROW 50004, 'Could not find CREATE PROCEDURE in the definition.', 1;

SET @body = STUFF(@body, @create, 6, 'ALTER');

EXEC sp_executesql @body;

PRINT 'sp_helpdesk GetTickets now returns build_name and Unit.';
