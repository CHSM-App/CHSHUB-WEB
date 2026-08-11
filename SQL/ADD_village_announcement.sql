/*
 * ADD: village_announcement, a table of its own for village announcements.
 *
 * Why a separate table
 * --------------------
 * v_announcement.aspx had no table at all. Its three tabs were filled by
 * GetGeneralAnnouncements(), GetMeetingUpdates() and GetWorkBudgetInfo(),
 * each of which built a DataTable in code — the file's own comment reads
 * "Method to get General Announcements dummy data" — and anything added went
 * into
 *
 *     private static List<Announcement> announcementsList = new List<...>();
 *
 * lost on the next app restart and shared by every village at once.
 *
 * Announcements were briefly filed in notice_master, the society notice table,
 * under the village's id. This gives them their own table instead: a village
 * announcement is not a society notice — it has a category and no recipients
 * group, and nothing links it to owners or tenants.
 *
 * Shape
 * -----
 * Modelled on notice_master, less recipients_id, plus the category the three
 * tabs need. village_id is nvarchar(10), matching village_master.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.village_announcement', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.village_announcement (
        announcement_id INT             NOT NULL,
        village_id      NVARCHAR(10)    NULL,
        -- 'General', 'Meeting' or 'WorkBudget' — ddlCategory's own values.
        category        NVARCHAR(20)    NULL,
        title           NVARCHAR(150)   NULL,
        description     NVARCHAR(500)   NULL,
        [date]          DATE            NULL,
        valid_to        DATE            NULL,
        -- 0 live, 1 deleted. Deletes are soft, as they are across this schema.
        active_status   INT             NULL,
        created_at      SMALLDATETIME   NULL,
        CONSTRAINT PK_village_announcement PRIMARY KEY CLUSTERED (announcement_id ASC)
    );

    -- Every read is "this village's announcements, live ones only".
    CREATE INDEX IX_village_announcement_village
        ON dbo.village_announcement (village_id, active_status);

    PRINT 'village_announcement created.';
END
ELSE
    PRINT 'village_announcement already exists - no change made.';
GO

/*
 * sp_village_announcement — the branches the app calls.
 *
 * Grid_Show   list one village's live announcements, newest first
 * Search      the same, filtered by title or description
 * Select      one row
 * Update      insert when @announcement_id = 0, otherwise update
 * Delete      soft delete
 *
 * The id is allocated the way the rest of this schema does it: read the highest
 * and add one, rather than an IDENTITY column, so the table matches its
 * neighbours and the same insert pattern is used throughout.
 */
CREATE OR ALTER PROCEDURE dbo.sp_village_announcement
    @operation       NVARCHAR(20)  = NULL,
    @announcement_id INT           = 0,
    @village_id      NVARCHAR(10)  = NULL,
    @category        NVARCHAR(20)  = NULL,
    @title           NVARCHAR(150) = NULL,
    @description     NVARCHAR(500) = NULL,
    @date            DATE          = NULL,
    @valid_to        DATE          = NULL,
    @search          NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Grid_Show'
    BEGIN
        SELECT *
        FROM   dbo.village_announcement
        WHERE  village_id = @village_id
          AND  ISNULL(active_status, 0) = 0
        ORDER BY [date] DESC, announcement_id DESC;
    END

    IF @operation = 'Search'
    BEGIN
        SELECT *
        FROM   dbo.village_announcement
        WHERE  village_id = @village_id
          AND  ISNULL(active_status, 0) = 0
          AND (title LIKE '%' + @search + '%' OR description LIKE '%' + @search + '%')
        ORDER BY [date] DESC, announcement_id DESC;
    END

    IF @operation = 'Select'
    BEGIN
        SELECT *
        FROM   dbo.village_announcement
        WHERE  announcement_id = @announcement_id;
    END

    IF @operation = 'Update'
    BEGIN
        IF @announcement_id = 0
        BEGIN
            DECLARE @new INT = 0;

            SELECT @new = ISNULL(MAX(announcement_id), 0) + 1
            FROM   dbo.village_announcement;

            INSERT INTO dbo.village_announcement
                   (announcement_id, village_id, category, title, description,
                    [date], valid_to, active_status, created_at)
            VALUES (@new, @village_id, ISNULL(@category, 'General'),
                    dbo.InitCap(@title), @description,
                    ISNULL(@date, CAST(GETDATE() AS DATE)), @valid_to, 0, GETDATE());

            SELECT @new AS announcement_id;
        END
        ELSE
        BEGIN
            UPDATE dbo.village_announcement
            SET    category    = ISNULL(@category, category),
                   title       = dbo.InitCap(@title),
                   description = @description,
                   [date]      = ISNULL(@date, [date]),
                   valid_to    = @valid_to
            -- village_id is not reassigned: an announcement cannot move village.
            WHERE  announcement_id = @announcement_id
              AND  village_id = @village_id;

            SELECT @announcement_id AS announcement_id;
        END
    END

    IF @operation = 'Delete'
    BEGIN
        UPDATE dbo.village_announcement
        SET    active_status = 1
        WHERE  announcement_id = @announcement_id
          AND  village_id = @village_id;
    END
END
GO

PRINT 'sp_village_announcement created.';
GO

/* Verification. */
SELECT  c.name AS column_name, t.name AS type_name, c.max_length, c.is_nullable
FROM    sys.columns c
JOIN    sys.types t ON t.user_type_id = c.user_type_id
WHERE   c.object_id = OBJECT_ID('dbo.village_announcement')
ORDER BY c.column_id;

SELECT CASE WHEN OBJECT_ID('dbo.sp_village_announcement', 'P') IS NULL
            THEN 'sp_village_announcement MISSING'
            ELSE 'sp_village_announcement ready' END AS procedure_state;
GO
