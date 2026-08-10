/* ============================================================================
   FIX -- sp_new_maintenance, 'generate' block (add-on bills)

   SSMS madhe he file ughda ani F5 dabaa.

   Ha SP mothaa aahe, mhanun purna script paste karnyapeksha he script fakt
   je chukale aahe tya doni olee shodhun badalte. Baaki SP la haat lavat nahi.

   Don dosh:

   1) L87 -- prev_due la society_id nahi:
        WHERE flat_id = @flat_id and due_date < ... and bill_type = 0
      flat_id ek society purta unique nahi. Aata don societies madhe same
      flat_id nahi (tapasle), mhanun ajun kahi bighadle nahi -- pan dusri
      society aali ki tichi thakbaki hya bill var yeil. Haach dosh gen_bill
      madhe aapan aadhich durust kela.

   2) L89 -- IF (@prev_due IS NOT NULL) kadhich khota hot nahi:
        SELECT @prev_due = ISNULL(Sum(due), 0) ...
      ISNULL mule @prev_due nehmi 0 kiwa jaast -- kadhich NULL nahi. Mhanun
      'else set @interest = 0' ha bhaag kadhich chalat nahi, ani thakbaki
      nastanahi vyaj-ganit chalte (0 var, mhanun paise chukiche jaat nahit,
      pan interest column 0 na hota rate cha value gheun basto).
      Tapasni '> 0' pahije, jashi gen_bill madhe aahe.
   ========================================================================= */

USE [society];
GO

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_new_maintenance'));

IF @sql IS NULL
BEGIN
    RAISERROR('sp_new_maintenance sapadla nahi.', 16, 1);
    RETURN;
END

DECLARE @old1 NVARCHAR(400) =
    N'SELECT   @prev_due = ISNULL(Sum(due), 0) FROM maintenance_cal WHERE flat_id = @flat_id and due_date <  DATEADD(day,-1, GETDATE()) and bill_type=0';

DECLARE @new1 NVARCHAR(400) =
    N'SELECT   @prev_due = ISNULL(Sum(due), 0) FROM maintenance_cal WHERE flat_id = @flat_id and society_id = @society_id and due_date <  DATEADD(day,-1, GETDATE()) and bill_type=0';

DECLARE @old2 NVARCHAR(100) = N'IF (@prev_due IS NOT NULL)';
DECLARE @new2 NVARCHAR(100) = N'IF (@prev_due > 0)';

/* --- tapasni: doni olee sapadlya ka? ----------------------------------- */
IF CHARINDEX(@old1, @sql) = 0 AND CHARINDEX(@new1, @sql) = 0
BEGIN
    RAISERROR('prev_due chi ol sapadli nahi -- SP aadhich badalla asel. Kahi kele nahi.', 16, 1);
    RETURN;
END

IF CHARINDEX(@old2, @sql) = 0 AND CHARINDEX(@new2, @sql) = 0
BEGIN
    RAISERROR('IS NOT NULL chi ol sapadli nahi -- SP aadhich badalla asel. Kahi kele nahi.', 16, 1);
    RETURN;
END

/* --- badal karaa ------------------------------------------------------- */
SET @sql = REPLACE(@sql, @old1, @new1);
SET @sql = REPLACE(@sql, @old2, @new2);

-- CREATE -> ALTER, jenekarun ahe to SP badalel, navin banavnar nahi.
SET @sql = STUFF(@sql, CHARINDEX('CREATE', @sql), 6, 'ALTER');

EXEC sp_executesql @sql;
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte, kahi badalat nahi.
   Doni olee 'YES' aalya pahijet.
   -------------------------------------------------------------------------*/
SELECT
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_new_maintenance'))
              LIKE '%society_id = @society_id and due_date%'
         THEN 'YES' ELSE 'NO' END  AS [1_prev_due_society_scoped],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_new_maintenance'))
              LIKE '%IF (@prev_due > 0)%'
         THEN 'YES' ELSE 'NO' END  AS [2_prev_due_greater_than_zero];
GO
