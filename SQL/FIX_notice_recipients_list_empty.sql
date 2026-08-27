/*
 * The Recipients dropdown on a notice is empty.
 *
 * The bug
 * -------
 * Publishing a notice — from the website's Announcements page or the
 * secretary app — offers a "Recipients" picker that opens with nothing in
 * it but "Select…". Nothing errors; the list is simply empty, so a notice
 * gets published with no audience chosen.
 *
 * The picker is filled by GET /community/notices/recipients, which runs
 * sp_notice_master with @operation = 'GetAllRecipients':
 *
 *     SELECT * FROM notice_recipients;
 *
 * That is correct SQL against a table that was never populated.
 * notice_recipients is a static lookup — two columns, no society_id:
 *
 *     CREATE TABLE [dbo].[notice_recipients](
 *         [recipients_id] [int] NULL,
 *         [recipients]    [nvarchar](50) NULL
 *     )
 *
 * It holds the fixed set of audience groups the product ships with, the same
 * for every society. Nothing in the application ever inserts into it — there
 * is no screen to manage recipient groups, and the schema script creates the
 * table without seeding it. So on any database built from Sql_table.txt the
 * table exists and is empty, and every notice form that reads it shows an
 * empty list.
 *
 * Why the notice still sends
 * --------------------------
 * The push does not depend on this table. web/lib/notify.js resolves the
 * audience from its own GROUPS map, keyed by the same ids:
 *
 *     1 Owners · 2 Tenants · 3 Owners and Tenants · 4 Members · 5 Everyone
 *
 * and looks the people up in owner_master and UserLogin. So the ids below are
 * not free to choose: they are the contract between this table and that map.
 * Seeding a different id — or renumbering these — would put a label in the
 * picker that resolves to the wrong people, or to nobody.
 *
 * With the picker empty, recipientsId arrives as 0, which is in neither the
 * table nor GROUPS. findRecipients falls back to `GROUPS[3]` — owners and
 * tenants — so notices have been going out to residents but never to the
 * committee, whatever the secretary meant to pick. That is the second half of
 * the bug and it is fixed by the same seed: once the picker has options, the
 * chosen id is sent and honoured.
 *
 * The fix
 * -------
 * Seed the five groups. Idempotent — safe to run against a database where
 * some or all of them already exist, and it repairs a drifted label rather
 * than duplicating the row.
 *
 * Group 5 ("All Members") is included because notify.js already implements
 * it and the legacy Vote.aspx used it; without it there is no way to address
 * a notice to residents and committee together.
 */

USE [society];
GO

SET NOCOUNT ON;
GO

/*
 * The table ships with no key and both columns nullable, so a bad or repeated
 * run could otherwise leave duplicate ids behind — which would show the same
 * group twice in the picker. MERGE on recipients_id keeps one row per id.
 */
MERGE [dbo].[notice_recipients] AS target
USING (VALUES
    (1, N'Owners'),
    (2, N'Tenants'),
    (3, N'Owners and Tenants'),
    (4, N'Members'),
    (5, N'All Members')
) AS source (recipients_id, recipients)
    ON target.recipients_id = source.recipients_id
WHEN MATCHED AND ISNULL(target.recipients, N'') <> source.recipients THEN
    UPDATE SET recipients = source.recipients
WHEN NOT MATCHED BY TARGET THEN
    INSERT (recipients_id, recipients)
    VALUES (source.recipients_id, source.recipients);
GO

/*
 * Clear out any row with no id. One would render as an option the form cannot
 * submit — <option value=""> is indistinguishable from "Select…" — and it can
 * only have come from a hand-edit, since nothing in the app writes here.
 */
DELETE FROM [dbo].[notice_recipients]
WHERE recipients_id IS NULL;
GO

-- What the picker will now show.
SELECT recipients_id, recipients
FROM   [dbo].[notice_recipients]
ORDER  BY recipients_id;
GO
