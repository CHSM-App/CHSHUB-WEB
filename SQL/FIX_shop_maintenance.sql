/* ============================================================================
   FIX -- Shop Maintenance: Delete does nothing, new entries hit a PK error,
          and duplicate receipt numbers save silently

   Open this file in SSMS and press F5.

   WHAT IS WRONG
   -------------
   1) DELETE -- the procedure wrote to shop_vw:

          Update shop_vw set active_status=1 where shop_maint_id=@shop_maint_id

      shop_vw joins three tables (shop_maintenance + ledger + society_master).
      SQL Server refuses to update a view like that:
      "View or function 'shop_vw' is not updatable because the modification
      affects multiple base tables."

      So delete never worked in the legacy app either. The web app has
      canDelete={false} -- a fair call at the time, since no DELETE route
      existed on the backend.

   2) THE NEW-ROW ID -- two faults at once:

          SELECT TOP (1) @new = shop_maint_id
          FROM   dbo.shop_maintenance
          ORDER BY shop_maint_id DESC;      -- across ALL societies!
          IF @new IS NULL SELECT @new = 0;  -- empty table => 0
          ELSE SELECT @new = @new + 1;

      (a) shop_maint_id has no IDENTITY (see Sql_table.txt -- it is just
          "[int] NOT NULL" plus a PRIMARY KEY), so the procedure has to
          supply the value itself.

      (b) @new is declared as 0, and on an empty table the SELECT never
          assigns it -- so @new stays 0 rather than becoming NULL, the
          IS NULL branch never fires, and the +1 never happens. The first
          insert gets id 0 and the second computes 0 again => PK violation.

      (c) As with ledger and audit, the id sequence is SHARED across every
          society instead of being per-society.

   3) check_no (the duplicate receipt-number check) -- dead logic:

          Select * ... Where mrep_no=@mrep_no
            AND shop_maint_id=@shop_maint_id
            AND shop_maint_id<>@shop_maint_id     -- never true!

      So editing an entry never found a duplicate. It was not filtered by
      society either, meaning one society's receipt number would have been
      reported as a duplicate of another's.

      The Node API does not call this branch at all (the legacy .aspx used
      it from txt_recipt_TextChanged), so today duplicate receipt numbers
      save without complaint.

   WHAT THIS CHANGES
   -----------------
   * Delete   -- writes to the base table (shop_maintenance), not the view.
   * Update   -- takes the next id from that society's own rows and skips to
                 a free one; rejects a duplicate mrep_no or a ledger that
                 belongs to another society.
   * check_no -- filters by society and excludes the row being edited.

   CHECKS
   ------
   Section (2) at the bottom lists duplicate receipt numbers that already
   exist. Review those first -- once this fix is applied they can no longer
   be saved.
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   (1) Correct the stored procedure
   ------------------------------------------------------------------------ */
ALTER procedure [dbo].[sp_shop_maintenance]
@operation nvarchar(50)=null,
@shop_maint_id int=0,
@mrep_no nvarchar(200)=null,
@m_date smalldatetime=null,
@led_id int=0,
@other_details nvarchar(MAX)=null,
@amt int=0,
@pay_method nvarchar(50)=null,
@cheq_no nvarchar(50)=null,
@cheq_date smalldatetime=null,
@active_status int=0,
@society_id nvarchar(50)=null,
@search  nvarchar(50)=null

AS
BEGIN

    If @operation='Update'
	Begin
	    /* Does this receipt number already exist in this society?
	       When editing, the row itself is excluded. */
	    IF EXISTS (SELECT 1 FROM dbo.shop_maintenance
	               WHERE mrep_no       = @mrep_no
	                 AND society_id    = @society_id
	                 AND active_status = 0
	                 AND shop_maint_id <> @shop_maint_id)
	        BEGIN
	            RAISERROR (N'Receipt no. already exists for this society', 16, 1);
	            RETURN;
	        END

	    /* The ledger must belong to this society -- otherwise shop_vw's join
	       still returns the row but it shows under the wrong society. */
	    IF NOT EXISTS (SELECT 1 FROM dbo.ledger
	                   WHERE led_id     = @led_id
	                     AND society_id = @society_id
	                     AND active_status = 0)
	        BEGIN
	            RAISERROR (N'Ledger does not belong to this society', 16, 1);
	            RETURN;
	        END

	If @shop_maint_id=0
	Begin
	 DECLARE @new AS int =0;

                    /* Next id from THIS society's rows only. Previously this
                       scanned every society's rows. */
                    SELECT   TOP (1) @new = shop_maint_id
                    FROM     dbo.shop_maintenance
                    WHERE    society_id = @society_id
                    ORDER BY shop_maint_id DESC;

                    /* On an empty table the SELECT above leaves @new alone, so
                       it keeps the declared 0 and the IS NULL test never fires.
                       COALESCE + 1 here means the first id is always 1, not 0. */
                    SET @new = COALESCE(@new, 0) + 1;

                    /* shop_maint_id is the primary key across all societies,
                       so if another society already took this id, move on to
                       the next free one. */
                    WHILE EXISTS (SELECT 1 FROM dbo.shop_maintenance
                                  WHERE shop_maint_id = @new)
                        BEGIN
                            SET @new = @new + 1;
                        END

	     Insert into shop_maintenance(shop_maint_id,society_id,mrep_no,m_date,led_id,other_details,amt,pay_method,cheq_no,cheq_date,active_status)values(@new,@society_id,@mrep_no,@m_date,@led_id,@other_details,@amt,@pay_method,@cheq_no,@cheq_date,0)

	     /* The web app needs the new id back (POST /shop-maintenance). */
	     SELECT @new AS shop_maint_id;
		 end
    else

	     /* society_id is deliberately not set here -- it must not change.
	        Keeping it in the WHERE clause stops one society from editing
	        another society's row. */
	     Update shop_maintenance set mrep_no=@mrep_no,m_date=@m_date,led_id=@led_id,other_details=@other_details,amt=@amt,pay_method=@pay_method,cheq_no=@cheq_no,cheq_date=@cheq_date where shop_maint_id=@shop_maint_id and society_id=@society_id
	End

	 If @operation='Delete'
	Begin

	/* This used to read "Update shop_vw ..." -- shop_vw joins three tables
	   and cannot be updated. Writing to the base table instead. The
	   society_id condition stops another society's row being hidden. */
	Update dbo.shop_maintenance set active_status=1
	where shop_maint_id=@shop_maint_id and society_id=@society_id

	End
		If @operation='Grid_Show'
	   Begin
	     select * from shop_vw where active_status=0 and society_id=@society_id  ORDER BY shop_maint_id DESC
	   End
	 If @operation='Select'
	Begin

	  Select * from shop_maintenance where shop_maint_id=@shop_maint_id and society_id=@society_id

	End

	If @operation='check_no'
	   Begin
	    /* This used to read "shop_maint_id=@shop_maint_id AND
	       shop_maint_id<>@shop_maint_id" -- a condition that is never true,
	       so editing never turned up a duplicate. There was no society
	       filter either. */
	    Select * from dbo.shop_maintenance
	    Where mrep_no=@mrep_no
	      and society_id=@society_id
	      and active_status=0
	      and shop_maint_id<>@shop_maint_id
	   End

	   If @operation='Search'
	   Begin
	     select * from shop_vw where active_status=0 and society_id=@society_id and( led_description like @search+'%' or mrep_no like @search+'%' or cast (m_date as varchar) like @search+'%')  ORDER BY shop_maint_id DESC
	   End

	   If @operation='fill_list'
	   begin
	   SELECT  * FROM  ledger where society_id =@society_id
	   end

END
GO


/* ---------------------------------------------------------------------------
   (2) Review receipt numbers that are already duplicated

   Once the fix is applied new duplicates cannot be saved, but existing rows
   stay as they are. This lists them -- correct any that turn up from the app.
   ------------------------------------------------------------------------ */
SELECT   society_id, mrep_no, COUNT(*) AS row_count,
         MIN(shop_maint_id) AS first_id, MAX(shop_maint_id) AS last_id
FROM     dbo.shop_maintenance
WHERE    active_status = 0
GROUP BY society_id, mrep_no
HAVING   COUNT(*) > 1
ORDER BY society_id, mrep_no;
GO

/* Rows tied to a ledger from another society, if any -- these appear in
   shop_vw but carry another society's ledger name. */
SELECT sm.shop_maint_id, sm.mrep_no, sm.society_id AS row_society,
       sm.led_id, l.society_id AS ledger_society, l.led_description
FROM   dbo.shop_maintenance sm
JOIN   dbo.ledger l ON l.led_id = sm.led_id
WHERE  sm.active_status = 0
  AND  l.society_id <> sm.society_id;
GO

PRINT 'Shop maintenance fix complete.';
GO
