/* ============================================================================
   sp_suggestion_request_master — 'Update' branch: save the edited subject

   THE BUG
   -------
   The 'Update' operation serves both an insert and an edit, keyed on whether
   @sug_id is 0. The insert writes every column:

       INSERT INTO dbo.suggestion_request_master
           (sug_id, details, society_id, subject, active_status)
       VALUES (@new, dbo.InitCap(@details), @society_id, @subject, 0)

   The edit does not:

       UPDATE dbo.suggestion_request_master
       SET    details = dbo.InitCap(@details),
              society_id = @society_id
       WHERE  sug_id = @sug_id

   `subject` is missing from the SET list. Editing a suggestion saves the new
   details and silently keeps the old subject — the caller gets a 200, the
   grid redraws, and the one field the user changed is the one that did not
   take. Nothing errors, so it reads as the edit having worked.

   `society_id` being in the SET list is its own oddity: an edit cannot move a
   suggestion between societies, and the value is only ever rewritten to what
   it already was. It is left alone here — it is harmless, and narrowing it is
   a separate change from fixing what is broken.

   HOW IT SURFACES
   ---------------
   backend/web/routes/community/index.js PUT /suggestions/:id sends both
   fields, so the route is already correct and needs no change. The web page
   (suggestion_request.aspx) and the secretary app's suggestion form both send
   a subject the proc then discards.

   THE FIX
   -------
   Add the column to the SET list. dbo.InitCap is applied to details on both
   the insert and the update; subject is stored as typed on the insert, so it
   is stored as typed here too — the two paths should not disagree about the
   casing of the same column.

   DEPLOY
   ------
   Safe on a live database. It only widens what one UPDATE writes, and that
   UPDATE already runs on every edit. No data is migrated: rows whose subject
   was lost to an earlier edit cannot be recovered from here — the old value
   is what is stored, and it is the *new* one that was dropped.

   Independent of the other scripts here; order does not matter.

   >>> TO ACTUALLY APPLY THIS, RUN:
   >>>     07-sp_suggestion_request_master-FULL-ready-to-execute.sql
   >>>
   >>> That file is the whole procedure with this fix already in it, and can
   >>> be executed as-is. THIS file explains the bug and offers the by-hand
   >>> route below; nothing it executes changes anything.
   ============================================================================ */

USE [society]
GO

/* ---------------------------------------------------------------------------
   BY HAND, if you would rather not run the full procedure:

   Open sp_suggestion_request_master for ALTER (Object Explorer ->
   Programmability -> Stored Procedures -> sp_suggestion_request_master ->
   Modify), find the 'Update' branch's ELSE block, and replace this line:

       Update dbo.suggestion_request_master set details=dbo.InitCap(@details),society_id=@society_id where sug_id=@sug_id

   with this one:

       Update dbo.suggestion_request_master set subject=@subject,details=dbo.InitCap(@details),society_id=@society_id where sug_id=@sug_id

   Leave every other line in that branch alone. Then Execute.
   --------------------------------------------------------------------------- */

/* For reference, the branch reads like this once fixed:

    If @operation='Update'
    Begin
         if @sug_id=0
           Begin
                ... unchanged INSERT ...
           End
     Else
           Begin
           Update dbo.suggestion_request_master set subject=@subject,details=dbo.InitCap(@details),society_id=@society_id where sug_id=@sug_id
           End
    End
*/


/* ---------------------------------------------------------------------------
   VERIFY — edit a suggestion's subject and confirm it sticks.

   Run against a suggestion you do not mind changing. Before the fix the
   second SELECT still shows the original subject; after it, the new one.
   --------------------------------------------------------------------------- */

-- Pick any live row to test with.
SELECT TOP (5) sug_id, subject, details, society_id
FROM dbo.suggestion_request_master
WHERE active_status = 0
ORDER BY sug_id DESC;
GO

/*
DECLARE @id int = <sug_id from above>;

EXEC sp_suggestion_request_master
     @operation  = 'Update',
     @sug_id     = @id,
     @subject    = 'Subject edited by verify script',
     @details    = 'Details edited by verify script',
     @society_id = '<that row''s society_id>';

SELECT sug_id, subject, details
FROM dbo.suggestion_request_master
WHERE sug_id = @id;
-- subject should now read 'Subject Edited By Verify Script'... as typed:
-- 'Subject edited by verify script'.
*/
