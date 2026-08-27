/*
 * Show a registered visitor in the gate log.
 *
 * The bug
 * -------
 * A visitor registered from the website or the secretary app is written to
 * Visitor_master — the row is there in the table — but the list comes back
 * without it. Nothing errors, so the save looks like it worked and the entry
 * has simply vanished.
 *
 * Two independent causes, both on the read path. sp_Visitor's Grid_Show reads
 * the `visitor` view:
 *
 *     SELECT * FROM visitor
 *     WHERE active_status = 0 AND society_id = @society_id
 *       AND in_date >= DATEADD(DAY, -30, GETDATE())
 *
 * 1. The view is two INNER JOINs onto owner_search_vw, UNIONed — the first
 *    matching on owner_id, the second on flat_id:
 *
 *        FROM visitor_master vm INNER JOIN owner_search_vw ow
 *          ON vm.society_id = ow.society_id AND vm.owner_id = ow.owner_id
 *        UNION
 *        FROM visitor_master vm INNER JOIN owner_search_vw ow
 *          ON vm.society_id = ow.society_id AND vm.flat_id  = ow.flat_id
 *
 *    A visitor with neither — a contractor for the society itself, or one
 *    saved before the unit picker existed, where both columns default to 0 —
 *    matches no branch of either join and is dropped by the view entirely.
 *    A flat with nobody on record against it does the same to a visitor who
 *    does have a flat.
 *
 * 2. `in_date >= DATEADD(DAY, -30, GETDATE())` hides most of the log from the
 *    people who are meant to hold it. Two ways:
 *
 *      - It is not null-safe. A visitor registered ahead of arrival has no
 *        in_date yet — that is what makes them expected rather than inside —
 *        and NULL >= anything is UNKNOWN, so every pre-registered visitor is
 *        dropped and the "Expected" tab can never show anything.
 *
 *      - Anything older than a month is gone. The gate log is the society's
 *        record of who entered, kept by the secretary and the admin; a flat
 *        with 41 visitors against it showed 0 to both, while the resident app
 *        — which reads visitor_master_vw and has no such window — showed all
 *        41. The committee saw less of its own register than a resident did.
 *
 * The fix
 * -------
 * The view keeps every column it has, but finds its resident through an
 * OUTER APPLY, so a visitor survives with those columns null rather than
 * being dropped. Both ways of attaching a visitor are kept — by owner, else
 * by flat — folded into one pass that returns at most one resident, which
 * also removes the duplicate row the UNION produced when both matched.
 *
 * Grid_Show drops the 30-day window entirely and returns the society's whole
 * register, newest first. The committee holds this record and should see all
 * of it; narrowing to a period is the caller's job — the API already accepts a
 * search, and a date filter belongs there rather than baked into the only
 * branch that lists visitors at all.
 *
 * Safe to re-run.
 */

USE [society]
GO

/* ---------------------------------------------------------------- view --- */

ALTER VIEW [dbo].[visitor]
AS
SELECT  vm.visitor_id,
        vm.v_name,
        vm.flat_id,
        CONVERT(varchar, vm.in_date, 106)                    AS in_date,
        CONVERT(varchar, vm.out_date, 106)                   AS out_date,
        CONVERT(varchar(15), CAST(vm.in_time AS TIME), 100)  AS in_time,
        CONVERT(varchar(15), CAST(vm.out_time AS TIME), 100) AS out_time,
        vm.society_id,
        vm.type,
        vm.pre_date,
        vm.vehicle_no,
        vm.preference,
        vm.image,
        vm.contact_no,
        vm.in_user_id,
        vm.out_user_id,
        vm.purpose,
        ow.w_name + ' ' + ow.flat_no                         AS unit,
        ow.name                                              AS UserName,
        ow.build_name,
        ow.society_name,
        vm.active_status,
        vm.Approver_Name,
        vm.status,
        ow.build_id,
        vm.gateOtp,
        vm.company,
        ow.is_rented,
        ow.type                                              AS owner_type,
        vm.owner_id,
        vm.location
FROM    dbo.visitor_master vm
/*
 * OUTER APPLY rather than the previous UNION of two INNER JOINs: it keeps the
 * "by owner, else by flat" preference explicit, returns at most one resident
 * per visitor, and — being an outer apply — never drops the visitor when
 * there is no resident to find.
 *
 * The <> 0 guards matter: both columns default to 0 rather than NULL, and
 * without them a visitor attached to neither would match any resident whose
 * own id happened to be 0.
 */
OUTER APPLY (
    SELECT  TOP (1) o.*
    FROM    dbo.owner_search_vw o
    WHERE   o.society_id = vm.society_id
      AND   (
                (vm.owner_id <> 0 AND o.owner_id = vm.owner_id)
             OR (vm.flat_id  <> 0 AND o.flat_id  = vm.flat_id)
            )
    -- The owner match wins where both are set: it names the person the visitor
    -- actually came for, where the flat match only names whoever lives there.
    ORDER BY CASE WHEN o.owner_id = vm.owner_id THEN 0 ELSE 1 END
) ow;
GO

/* ------------------------------------------------------------ Grid_Show --- */

/*
 * sp_Visitor is one 200-line procedure with sixteen branches, and only
 * Grid_Show is wrong. Rather than reproduce the whole body here — which would
 * make this script the authority on the other fifteen and quietly revert any
 * change made to them since — the branch is rewritten in place.
 *
 * The search-and-replace is exact and idempotent: it looks for the old
 * predicate, and does nothing if it is already gone.
 */
DECLARE @body nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'dbo.sp_Visitor'));

/*
 * Both shapes the window has taken: the original, and the null-safe form an
 * earlier run of this script left behind. Matching either means the script can
 * be run again over a half-applied database and still finish the job.
 */
DECLARE @original nvarchar(max) = N'AND in_date >= DATEADD(DAY, -30, GETDATE())';
DECLARE @nullSafe nvarchar(max) = N'AND (in_date IS NULL OR in_date >= DATEADD(DAY, -30, GETDATE()))';

/*
 * Replaced by a comment rather than deleted, so anyone reading the procedure
 * later sees that the window was removed on purpose and does not restore it.
 */
DECLARE @replacement nvarchar(max) =
      N'-- No date window: this is the society''s own register of who came in,' + CHAR(13) + CHAR(10)
    + N'			  -- and the committee holds it. A 30-day cut hid all but the last' + CHAR(13) + CHAR(10)
    + N'			  -- month from the secretary and the admin, and — not being null-' + CHAR(13) + CHAR(10)
    + N'			  -- safe — every pre-registered visitor as well. Narrowing to a' + CHAR(13) + CHAR(10)
    + N'			  -- period is the caller''s job.';

IF @body IS NULL
BEGIN
    RAISERROR('dbo.sp_Visitor not found — nothing to patch.', 16, 1);
END
ELSE IF CHARINDEX(@original, @body) = 0 AND CHARINDEX(@nullSafe, @body) = 0
BEGIN
    PRINT 'Grid_Show already returns the whole register; view updated only.';
END
ELSE
BEGIN
    -- The null-safe form first: it contains the original as a substring, so
    -- replacing the original first would leave a broken fragment behind.
    SET @body = REPLACE(@body, @nullSafe, @replacement);
    SET @body = REPLACE(@body, @original, @replacement);
    -- CREATE -> ALTER, so the existing procedure is replaced in place.
    SET @body = STUFF(@body, CHARINDEX(N'CREATE', @body), 6, N'ALTER');
    EXEC sp_executesql @body;
    PRINT 'Grid_Show patched: the full visitor register is returned.';
END
GO
