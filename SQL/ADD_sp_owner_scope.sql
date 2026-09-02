/*
 * Per-record ownership check for the mobile API (IDOR fix).
 *
 * The problem
 * -----------
 * routes/middleware/protect.js proves *who* is calling (a valid JWT), but the
 * mobile handlers then act on whatever flat_id / owner_id / record id sits in
 * the URL. Nothing checked that the record belonged to the caller, so any
 * resident could read or write any other resident's data by changing the id.
 *
 * The fix
 * -------
 * This is additive: a single new procedure that answers one question —
 * "does record <id> of kind <kind> belong to the resident whose mobile is
 * <pre_mob>?" — without altering any existing SP signature, so the website API
 * and the legacy app are unaffected. The Express layer calls it before the
 * handler runs (routes/middleware/ownership.js) and returns 403 when it says no.
 *
 * The identity is the caller's mobile, taken from the verified JWT (never from
 * the request). owner_master maps that mobile to the caller's live flats and
 * owner_ids; every resident-owned child table carries flat_id (or, for family,
 * owner_id), so each kind resolves back to an owner_master row the caller owns.
 *
 * active_status = 0 means live (1 = soft-deleted), matching every other SP.
 * pre_mob is compared trimmed, exactly as sp_owner_master already does.
 *
 * Returns a single row: owned = 1 when the record is the caller's, else 0.
 * An unknown @kind raises, so a mis-wired route fails closed (500), not open.
 */
IF OBJECT_ID('dbo.sp_owner_scope', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_owner_scope;
GO

CREATE PROCEDURE dbo.sp_owner_scope
    @pre_mob NVARCHAR(50),
    @kind    NVARCHAR(20),
    @id      INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @owned BIT = 0;

    IF @kind = 'flat'
        IF EXISTS (SELECT 1 FROM dbo.owner_master
                   WHERE active_status = 0 AND LTRIM(RTRIM(pre_mob)) = @pre_mob
                     AND flat_id = @id)
            SET @owned = 1;

    ELSE IF @kind = 'owner'
        IF EXISTS (SELECT 1 FROM dbo.owner_master
                   WHERE active_status = 0 AND LTRIM(RTRIM(pre_mob)) = @pre_mob
                     AND owner_id = @id)
            SET @owned = 1;

    ELSE IF @kind = 'ownerext'
        -- Family member (owner_extension.o_ex_id) under an owner the caller
        -- owns; OR the fallback DeleteFamilyMember uses — an owner_master row
        -- of the caller's addressed directly by owner_id.
        IF EXISTS (SELECT 1 FROM dbo.owner_extension e
                   JOIN dbo.owner_master o ON o.owner_id = e.owner_id
                   WHERE e.o_ex_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
        OR EXISTS (SELECT 1 FROM dbo.owner_master
                   WHERE owner_id = @id AND active_status = 0
                     AND LTRIM(RTRIM(pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE IF @kind = 'vehicle'
        IF EXISTS (SELECT 1 FROM dbo.Vehicle v
                   JOIN dbo.owner_master o ON o.flat_id = v.flat_id
                   WHERE v.vehicle_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE IF @kind = 'parking'
        IF EXISTS (SELECT 1 FROM dbo.parking_master p
                   JOIN dbo.owner_master o ON o.flat_id = p.flat_id
                   WHERE p.parking_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE IF @kind = 'visitor'
        IF EXISTS (SELECT 1 FROM dbo.visitor_master vm
                   JOIN dbo.owner_master o ON o.flat_id = vm.flat_id
                   WHERE vm.visitor_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE IF @kind = 'document'
        IF EXISTS (SELECT 1 FROM dbo.owner_documents d
                   JOIN dbo.owner_master o ON o.flat_id = d.flat_id
                   WHERE d.document_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE IF @kind = 'receipt'
        IF EXISTS (SELECT 1 FROM dbo.receipt r
                   JOIN dbo.owner_master o ON o.flat_id = r.flat_id
                   WHERE r.receipt_id = @id AND o.active_status = 0
                     AND LTRIM(RTRIM(o.pre_mob)) = @pre_mob)
            SET @owned = 1;

    ELSE
        RAISERROR('sp_owner_scope: unknown @kind "%s"', 16, 1, @kind);

    SELECT @owned AS owned;
END
GO
