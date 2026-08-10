/* ============================================================================
   FIX -- vyaj cha dar (interest_rate) app madhun badalta yeto

   SSMS madhe he file ughda ani F5 dabaa.

   KAAY CHUKAT HOTE
   ----------------
   Bill var thakbaki var vyaj lagte -- gen_bill madhe:

       SET @tax_interest = round(((@prev_due * @interest) / 100) / 365 * 31, 2)

   @interest account_setting.interest_rate madhun yeto, ani to 21 aahe.
   Pan to dar KONALACH badalta yet navhta:

       sp_account_setting     -- @interest_rate parameter nahich
       tyacha UPDATE          -- interest_rate column lihitach nahi
       tyacha INSERT          -- 21 haardcode kelela
       backend route          -- pathvat nahi
       Settings modal         -- field nahi

   Mhanje navin society la kayamcha 21% milto, ani asalelya society la to
   badalayla SQL shivay marg nahi. ASP.NET madhe suddha he navhte, mhanun ha
   junaach dosh aahe -- pan paisyacha vishay aahe, tyamule durust karto.

   Society ne 0% thravle tar te tyanchya haati asayla have.
   ========================================================================= */

USE [society];
GO

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'));
DECLARE @n INT = 0;

IF @sql IS NULL
BEGIN
    RAISERROR('sp_account_setting sapadla nahi.', 16, 1);
    RETURN;
END

/* --- 1) parameter jodaa ------------------------------------------------- */
IF CHARINDEX(N'@bill_due_period int  = 0', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'@bill_due_period int  = 0',
        N'@bill_due_period int  = 0,
-- NULL mhanje "badalu naka" -- juna dar tasach rahto. Junya call sites la
-- ha parameter mahit nahi, tyanni chukun vyaj badalu naye mhanun.
@interest_rate decimal(18,2) = NULL');
    SET @n += 1;
END

/* --- 2) UPDATE madhe column lihaa --------------------------------------- */
IF CHARINDEX(N'bill_due_period = @bill_due_period', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'bill_due_period = @bill_due_period',
        N'bill_due_period = @bill_due_period,
            interest_rate = ISNULL(@interest_rate, interest_rate)');
    SET @n += 1;
END

/* --- 3) INSERT madhla haardcode 21 kadha --------------------------------

   Line endings CHAR(13)+CHAR(10) ne banavle aahet: he file kuthlya editor ne
   save kele tari shodh julto. Sadha multi-line string vaparla asta tar file
   CRLF ki LF yavar julane avlambun rahile aste -- ani nemke tyamulech pahilya
   veles ha bhaag sapadla navhta.                                            */
DECLARE @nl NVARCHAR(2) = CHAR(13) + CHAR(10);
DECLARE @tab NVARCHAR(3) = CHAR(9) + CHAR(9) + CHAR(9);
DECLARE @old3 NVARCHAR(200) = N'@bill_due_period,' + @nl + @tab + N'21';
DECLARE @new3 NVARCHAR(200) = N'@bill_due_period,' + @nl + @tab + N'ISNULL(@interest_rate, 21)';

IF CHARINDEX(@old3, @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql, @old3, @new3);
    SET @n += 1;
END

IF @n < 3
BEGIN
    RAISERROR('Apekshit teenpaiki fakt %d jaga sapadlya. Kahi badalle nahi.', 16, 1, @n);
    RETURN;
END

SET @sql = STUFF(@sql, CHARINDEX('CREATE', @sql), 6, 'ALTER');
EXEC sp_executesql @sql;
PRINT 'sp_account_setting durust zala.';
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte. Teenhi 'YES' aale pahijet.
   -------------------------------------------------------------------------*/
SELECT
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%@interest_rate decimal%'            THEN 'YES' ELSE 'NO' END AS [1_parameter],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%interest_rate = ISNULL(@interest_rate%' THEN 'YES' ELSE 'NO' END AS [2_update],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%ISNULL(@interest_rate, 21)%'        THEN 'YES' ELSE 'NO' END AS [3_insert];

SELECT society_id, interest_rate FROM dbo.account_setting;
GO
