/*
 * Government schemes a village runs.
 *
 * The dashboard's "Add Government Scheme" tile pointed at Announcements: a
 * scheme was posted as a notice, which is how the legacy page did it. That
 * loses everything a scheme has and a notice does not — who qualifies, what
 * they get, when applications close, and the GR the scheme comes from — and
 * those are the questions a resident actually asks at the counter.
 *
 * A table of its own rather than another category on village_announcement,
 * because a scheme is a different kind of record: an announcement is read and
 * forgotten, a scheme is looked up months later and has to answer "am I
 * eligible" and "have I missed it".
 *
 * The columns
 * -----------
 *   name            what the scheme is called
 *   description      what it is, in full
 *   eligibility      who it applies to — "BPL households", "farmers with under
 *                    2 hectares", "widowed women". Free text: a village's own
 *                    wording is what residents recognise, and no fixed list
 *                    would survive contact with a new scheme.
 *   benefit_amount   the money involved, where the scheme is a payment
 *   benefit_details  the benefit in words, for schemes that are not money —
 *                    a subsidy, materials, a waiver
 *   gr_number        the government resolution the scheme comes from, which is
 *                    what an auditor or a resident's query is traced through
 *   gr_date          that resolution's date
 *   apply_from       when applications open
 *   apply_until      when they close. Past this the scheme is closed, which
 *                    the screen shows without anyone having to deactivate it.
 *   active_status    0 = live, following the convention elsewhere here
 *
 * Everything except the name is optional: a scheme is often announced before
 * its details are settled, and a half-filled record is more useful than none.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.village_scheme', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.village_scheme (
        scheme_id       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        -- nvarchar(50) to match house.village_id and the rest; village_master
        -- declares its own as nvarchar(10), the narrowest, so this cannot
        -- truncate anything that table can hold.
        village_id      NVARCHAR(50)   NOT NULL,
        name            NVARCHAR(200)  NOT NULL,
        description     NVARCHAR(MAX)  NULL,
        eligibility     NVARCHAR(MAX)  NULL,
        benefit_amount  DECIMAL(18,2)  NULL,
        benefit_details NVARCHAR(500)  NULL,
        gr_number       NVARCHAR(100)  NULL,
        gr_date         DATE           NULL,
        apply_from      DATE           NULL,
        apply_until     DATE           NULL,
        active_status   INT            NOT NULL CONSTRAINT DF_vs_scheme_active DEFAULT (0),
        created_at      SMALLDATETIME  NOT NULL CONSTRAINT DF_vs_scheme_created DEFAULT (GETDATE()),
        CONSTRAINT CK_vs_scheme_dates CHECK (apply_until IS NULL OR apply_from IS NULL OR apply_until >= apply_from)
    );

    CREATE INDEX IX_village_scheme_village ON dbo.village_scheme (village_id, active_status);

    PRINT 'village_scheme created.';
END
ELSE
    PRINT 'village_scheme already present.';
GO

IF OBJECT_ID('dbo.sp_village_scheme', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_village_scheme;
GO

CREATE PROCEDURE dbo.sp_village_scheme
    @operation       NVARCHAR(50)  = NULL,
    @village_id      NVARCHAR(50)  = NULL,
    @scheme_id       INT           = 0,
    @name            NVARCHAR(200) = NULL,
    @description     NVARCHAR(MAX) = NULL,
    @eligibility     NVARCHAR(MAX) = NULL,
    @benefit_amount  DECIMAL(18,2) = NULL,
    @benefit_details NVARCHAR(500) = NULL,
    @gr_number       NVARCHAR(100) = NULL,
    @gr_date         DATE          = NULL,
    @apply_from      DATE          = NULL,
    @apply_until     DATE          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Grid_Show'
    BEGIN
        SELECT scheme_id, village_id, name, description, eligibility,
               benefit_amount, benefit_details, gr_number, gr_date,
               apply_from, apply_until, active_status, created_at,
               /*
                * Whether applications are open, worked out here so every
                * caller says the same thing. A scheme with no dates is open —
                * nothing has been said to close it.
                */
               CASE
                 WHEN apply_until IS NOT NULL AND apply_until < CAST(GETDATE() AS DATE) THEN 'Closed'
                 WHEN apply_from  IS NOT NULL AND apply_from  > CAST(GETDATE() AS DATE) THEN 'Upcoming'
                 ELSE 'Open'
               END AS status
        FROM   dbo.village_scheme
        WHERE  village_id = @village_id
          AND  active_status = 0
        -- Soonest closing first, so what is about to expire leads.
        ORDER  BY CASE WHEN apply_until IS NULL THEN 1 ELSE 0 END, apply_until, scheme_id DESC;
    END

    IF @operation = 'Update'
    BEGIN
        IF @name IS NULL OR LTRIM(RTRIM(@name)) = ''
        BEGIN
            RAISERROR('A scheme needs a name.', 16, 1);
            RETURN;
        END

        IF @scheme_id = 0
        BEGIN
            INSERT INTO dbo.village_scheme
                (village_id, name, description, eligibility, benefit_amount,
                 benefit_details, gr_number, gr_date, apply_from, apply_until)
            VALUES
                (@village_id, @name, @description, @eligibility, @benefit_amount,
                 @benefit_details, @gr_number, @gr_date, @apply_from, @apply_until);

            SELECT SCOPE_IDENTITY() AS scheme_id;
        END
        ELSE
        BEGIN
            UPDATE dbo.village_scheme
            SET    name            = @name,
                   description     = @description,
                   eligibility     = @eligibility,
                   benefit_amount  = @benefit_amount,
                   benefit_details = @benefit_details,
                   gr_number       = @gr_number,
                   gr_date         = @gr_date,
                   apply_from      = @apply_from,
                   apply_until     = @apply_until
            WHERE  scheme_id  = @scheme_id
              AND  village_id = @village_id;   -- one village cannot edit another's

            SELECT @scheme_id AS scheme_id;
        END
    END

    IF @operation = 'Delete'
    BEGIN
        -- Deactivated, not deleted: a scheme that ran is part of the record of
        -- what the village offered, and residents ask about closed ones.
        UPDATE dbo.village_scheme
        SET    active_status = 1
        WHERE  scheme_id  = @scheme_id
          AND  village_id = @village_id;

        SELECT 'Done' AS Sql_Result;
    END
END
GO

PRINT 'sp_village_scheme created.';
GO

/* ---------------------------------------------------------- verification */

DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC dbo.sp_village_scheme @operation = 'Grid_Show', @village_id = @v;
GO
