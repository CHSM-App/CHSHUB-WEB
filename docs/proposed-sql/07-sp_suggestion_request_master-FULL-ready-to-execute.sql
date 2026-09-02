/* ============================================================================
   sp_suggestion_request_master — FULL, ready to execute

   The whole procedure with the one-line fix already applied, so this can be
   run as-is rather than hand-edited. 07-...-Update-subject.sql explains WHY;
   this is the WHAT to run.

   THE ONE CHANGE, and nothing else:

       Update dbo.suggestion_request_master
       set    subject=@subject,                     <-- added
              details=dbo.InitCap(@details),
              society_id=@society_id
       where  sug_id=@sug_id

   Every other branch — Select, Delete, check_delete, check_name, Grid_Show,
   Search — and the INSERT are byte-for-byte what is on the server today.

   WHY IT IS NEEDED
   ----------------
   'Update' serves both insert and edit, keyed on @sug_id = 0. The INSERT
   writes `subject`; the UPDATE did not. Editing a suggestion saved the new
   details and silently kept the old subject — a 200, a redrawn grid, and the
   one field the user changed not taking. The @subject parameter already
   exists on the procedure, so nothing but this SET list needs to change.

   DEPLOY
   ------
   Safe on a live database. ALTER swaps the definition in place; no rows are
   touched, no permissions are reset, and nothing is dropped. Existing rows
   whose subject was lost to an earlier edit cannot be recovered from here —
   the stored value IS the old one; it was the new one that was discarded.

   Independent of scripts 01-06; order does not matter.
   ============================================================================ */

USE [society]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_suggestion_request_master]
@operation nvarchar(50)=null,
@sug_id int=0,
@details nvarchar(500)=null,
@society_id nvarchar(10)=null,
@para nvarchar(100)=Null,
@subject nvarchar(250)=null,
@search nvarchar(50)=null
AS
BEGIN

	If @operation='Update'
	Begin
	     if @sug_id=0
	       Begin
		    DECLARE @new AS int =0;

                    SELECT   TOP (1) @new = sug_id
                    FROM     dbo.suggestion_request_master
                    ORDER BY sug_id DESC;
                    IF @new IS NULL
                        BEGIN
                            SELECT @new = 0;
                        END
                    ELSE
                        BEGIN
                            SELECT @new = @new + 1;
                        END
		    INSERT INTO dbo.suggestion_request_master(sug_id,details,society_id,subject,active_status)values(@new,dbo.InitCap(@details),@society_id,@subject,0)
	       End
         Else
		   Begin
		   -- subject=@subject added: the edit path dropped it, so a changed
		   -- subject was silently discarded while details saved fine.
		   Update dbo.suggestion_request_master set subject=@subject,details=dbo.InitCap(@details),society_id=@society_id where sug_id=@sug_id
		   End
	End
	If @operation='Select'
	   Begin
	      SELECT * from dbo.suggestion_request_master where sug_id=@sug_id
    	End
	If @operation='Delete'
	   Begin
	      Update dbo.suggestion_request_master set active_status=1 where sug_id=@sug_id
    	End

    If @operation='check_delete'
	   Begin
          SELECT *  FROM dbo.suggestion_request_master Where sug_id=@sug_id
	   End
	   If @operation='check_name'
	   Begin
	    If @sug_id=0
		Select * from dbo.suggestion_request_master Where lower(trim(details))=lower(trim(@details))
		ElSE
		Select * from dbo.suggestion_request_master Where details=@details AND sug_id=@sug_id AND sug_id<>@sug_id
	   End
	  If @operation='Grid_Show'
	   Begin
	     select * from dbo.suggestion_request_master where active_status=0 and society_id= @society_id  ORDER BY sug_id DESC
    	End
		 If @operation='Search'
	   Begin
	     select * from dbo.suggestion_request_master where active_status=0 and society_id= @society_id and( subject like @search +'%' or details like @search +'%') ORDER BY sug_id DESC
    	End

END
GO


/* ---------------------------------------------------------------------------
   VERIFY — confirm the edit path now writes the subject.

   Run this block on its own AFTER the ALTER above has succeeded. It edits a
   real row, so pick one you do not mind changing, and note its original
   subject and details first if you want to put them back.
   --------------------------------------------------------------------------- */

/*
-- 1. Pick a row to test with.
SELECT TOP (5) sug_id, subject, details, society_id
FROM dbo.suggestion_request_master
WHERE active_status = 0
ORDER BY sug_id DESC;

-- 2. Fill in the two values from a row above, then run.
DECLARE @id  int           = <sug_id>;
DECLARE @soc nvarchar(10)  = '<society_id>';

EXEC sp_suggestion_request_master
     @operation  = 'Update',
     @sug_id     = @id,
     @subject    = 'VERIFY new subject',
     @details    = 'VERIFY new details',
     @society_id = @soc;

-- 3. subject should read 'VERIFY new subject'.
--    Before the fix it still showed the row's original subject.
--    (details comes back InitCap'd as 'Verify New Details' — that is the
--    procedure's existing behaviour on both paths, not part of this change.)
SELECT sug_id, subject, details
FROM dbo.suggestion_request_master
WHERE sug_id = @id;
*/
