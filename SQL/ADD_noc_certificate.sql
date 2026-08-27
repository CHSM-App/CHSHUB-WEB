/*
 * ADD: noc_certificate, the no-objection certificates a society issues.
 *
 * Why a table
 * -----------
 * A NOC is a document the society hands out and is later asked to stand
 * behind — a bank, a buyer's lawyer or a registrar asks "did you issue this,
 * and what does it say". That needs a record of what was issued, to whom, on
 * what date, and in what words. The app held them in page state, which lost
 * every certificate the moment the screen closed.
 *
 * Shape
 * -----
 * Modelled on notice_master: society-scoped, soft-deleted, id allocated by
 * MAX + 1 rather than IDENTITY, matching its neighbours in this schema.
 *
 * The wording is stored on the row, not derived from noc_type at read time.
 * A certificate is a legal statement fixed at the moment it was issued: if the
 * society later rewords its standard sale-transfer clause, the certificates
 * already handed out must still read as they did when signed. Deriving the
 * clause from the type would silently rewrite history.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.noc_certificate', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.noc_certificate (
        noc_id          INT             NOT NULL,
        society_id      NVARCHAR(10)    NULL,

        -- The running number printed on the letter, e.g. 'NOC/2026/00125'.
        -- Stored rather than formatted on read: it is quoted back to the
        -- society by whoever holds the certificate.
        serial_no       NVARCHAR(40)    NULL,

        -- 'NoDues', 'SaleTransfer', 'Renovation', 'Mortgage', 'General' or
        -- 'Other'. Kept as text, not a lookup table: the set is fixed by the
        -- app and a society cannot add to it.
        noc_type        NVARCHAR(20)    NULL,

        -- What an 'Other' certificate calls itself. NULL for the built-in
        -- types, which are titled by noc_type.
        custom_title    NVARCHAR(150)   NULL,

        -- Completes "The society has no objection ...". Always stored, for
        -- every type — see the note above on why this is not derived.
        clause          NVARCHAR(1000)  NULL,

        member_name     NVARCHAR(150)   NULL,
        flat_no         NVARCHAR(50)    NULL,
        building_name   NVARCHAR(100)   NULL,
        purpose         NVARCHAR(300)   NULL,

        -- Free text printed as a further paragraph on the letter.
        remarks         NVARCHAR(1000)  NULL,

        issued_on       DATE            NULL,
        -- NULL means the certificate does not lapse, which is a real and
        -- common choice — not a missing value.
        valid_till      DATE            NULL,

        -- 0 live, 1 deleted. Deletes are soft, as they are across this schema.
        active_status   INT             NULL,
        created_at      SMALLDATETIME   NULL,
        created_by      INT             NULL,

        CONSTRAINT PK_noc_certificate PRIMARY KEY CLUSTERED (noc_id ASC)
    );

    -- Every read is "this society's certificates, live ones only".
    CREATE INDEX IX_noc_certificate_society
        ON dbo.noc_certificate (society_id, active_status);

    -- The list is searched by member and by flat, the two things a caller
    -- asking about a certificate actually knows.
    CREATE INDEX IX_noc_certificate_flat
        ON dbo.noc_certificate (society_id, flat_no);

    PRINT 'noc_certificate created.';
END
ELSE
    PRINT 'noc_certificate already exists - no change made.';
GO

/*
 * sp_noc_certificate — the branches the app calls.
 *
 * Grid_Show   list one society's live certificates, newest first
 * Search      the same, filtered by member, flat or serial
 * Select      one row
 * Update      insert when @noc_id = 0, otherwise update
 * Delete      soft delete
 *
 * The id and the serial are both allocated here rather than by the caller, so
 * two secretaries issuing at the same moment cannot land on one number.
 */
CREATE OR ALTER PROCEDURE dbo.sp_noc_certificate
    @operation      NVARCHAR(20)   = NULL,
    @noc_id         INT            = 0,
    @society_id     NVARCHAR(10)   = NULL,
    @noc_type       NVARCHAR(20)   = NULL,
    @custom_title   NVARCHAR(150)  = NULL,
    @clause         NVARCHAR(1000) = NULL,
    @member_name    NVARCHAR(150)  = NULL,
    @flat_no        NVARCHAR(50)   = NULL,
    @building_name  NVARCHAR(100)  = NULL,
    @purpose        NVARCHAR(300)  = NULL,
    @remarks        NVARCHAR(1000) = NULL,
    @issued_on      DATE           = NULL,
    @valid_till     DATE           = NULL,
    @created_by     INT            = NULL,
    @search         NVARCHAR(200)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Grid_Show'
    BEGIN
        SELECT *
        FROM   dbo.noc_certificate
        WHERE  society_id = @society_id
          AND  ISNULL(active_status, 0) = 0
        ORDER BY issued_on DESC, noc_id DESC;
    END

    IF @operation = 'Search'
    BEGIN
        SELECT *
        FROM   dbo.noc_certificate
        WHERE  society_id = @society_id
          AND  ISNULL(active_status, 0) = 0
          AND (member_name LIKE '%' + @search + '%'
            OR flat_no     LIKE '%' + @search + '%'
            OR serial_no   LIKE '%' + @search + '%')
        ORDER BY issued_on DESC, noc_id DESC;
    END

    IF @operation = 'Select'
    BEGIN
        SELECT *
        FROM   dbo.noc_certificate
        WHERE  noc_id = @noc_id
          AND  society_id = @society_id;
    END

    IF @operation = 'Update'
    BEGIN
        IF @noc_id = 0
        BEGIN
            DECLARE @new    INT = 0;
            DECLARE @year   NVARCHAR(4);
            DECLARE @seq    INT = 0;
            DECLARE @serial NVARCHAR(40);

            SELECT @new = ISNULL(MAX(noc_id), 0) + 1
            FROM   dbo.noc_certificate;

            SET @year = CAST(YEAR(ISNULL(@issued_on, GETDATE())) AS NVARCHAR(4));

            /*
             * The serial restarts each calendar year, so it is counted within
             * this society and this year rather than taken from @new. Deleted
             * rows still count: a number that was handed out on paper must not
             * be reissued to someone else.
             */
            SELECT @seq = ISNULL(COUNT(*), 0) + 1
            FROM   dbo.noc_certificate
            WHERE  society_id = @society_id
              AND  YEAR(issued_on) = YEAR(ISNULL(@issued_on, GETDATE()));

            SET @serial = 'NOC/' + @year + '/'
                        + RIGHT('00000' + CAST(@seq AS NVARCHAR(5)), 5);

            INSERT INTO dbo.noc_certificate
                   (noc_id, society_id, serial_no, noc_type, custom_title,
                    clause, member_name, flat_no, building_name, purpose,
                    remarks, issued_on, valid_till, active_status,
                    created_at, created_by)
            VALUES (@new, @society_id, @serial, ISNULL(@noc_type, 'General'),
                    @custom_title, @clause, @member_name, @flat_no,
                    @building_name, @purpose, @remarks,
                    ISNULL(@issued_on, CAST(GETDATE() AS DATE)), @valid_till,
                    0, GETDATE(), @created_by);

            SELECT @new AS noc_id, @serial AS serial_no;
        END
        ELSE
        BEGIN
            UPDATE dbo.noc_certificate
            SET    noc_type      = ISNULL(@noc_type, noc_type),
                   custom_title  = @custom_title,
                   clause        = @clause,
                   member_name   = @member_name,
                   flat_no       = @flat_no,
                   building_name = @building_name,
                   purpose       = @purpose,
                   remarks       = @remarks,
                   issued_on     = ISNULL(@issued_on, issued_on),
                   valid_till    = @valid_till
            -- society_id and serial_no are not reassigned: a certificate
            -- cannot move society, and its number is already on paper.
            WHERE  noc_id = @noc_id
              AND  society_id = @society_id;

            SELECT @noc_id AS noc_id,
                   (SELECT serial_no FROM dbo.noc_certificate
                     WHERE noc_id = @noc_id) AS serial_no;
        END
    END

    IF @operation = 'Delete'
    BEGIN
        UPDATE dbo.noc_certificate
        SET    active_status = 1
        WHERE  noc_id = @noc_id
          AND  society_id = @society_id;

        SELECT @noc_id AS noc_id;
    END
END
GO

PRINT 'sp_noc_certificate created.';
GO
