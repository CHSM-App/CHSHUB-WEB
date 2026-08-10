/* ============================================================================
   FIX -- account_setting madhle dar (rates) paise sakat saathavle jaatat

   SSMS madhe he file ughda ani F5 dabaa.

   KAAY CHUKAT AAHE
   ----------------
   account_setting table madhe teenhi column paise dharun thevayla banavle
   aahet:

       rate_per_sqfeet    decimal(10, 2)
       two_wheeler_rate   decimal(10, 2)
       four_wheeler_rate  decimal(10, 2)

   Pan sp_account_setting che parameter ughade 'decimal' aahet:

       @rate_per_sqf decimal = null,
       @two_w_rate   decimal = null,
       @four_w_rate  decimal = null

   T-SQL madhe ughada 'decimal' mhanje decimal(18, 0) -- ekhi dashansh jaaga
   nahi. Mhanun 2.75 ha dar column paryant pohochaaych aadhich 3 hoto.
   Column barobar aahe; parameter chukicha aahe.

   PARINAAM
   --------
   Dar sq. feet la 2.75 thevla tar 3 saathavla jaato. Motha society sathi
   pratyek bill var farak padto -- ani to farak konalach disat nahi, karan
   page reload zalyavar 3 ch dakhavla jaato.

   He ASP.NET madhe suddha asech hote, mhanun ha junaach dosh aahe. Pan
   paisyacha vishay aahe, tyamule durust karto.
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

/* --- teenhi parameter la (10, 2) daa -------------------------------------
   Column jitka aahe titkach -- kami nahi, jaast nahi.                     */

IF CHARINDEX(N'@rate_per_sqf decimal = null', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'@rate_per_sqf decimal = null',
        N'@rate_per_sqf decimal(10, 2) = null');
    SET @n += 1;
END

IF CHARINDEX(N'@two_w_rate decimal = null', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'@two_w_rate decimal = null',
        N'@two_w_rate decimal(10, 2) = null');
    SET @n += 1;
END

IF CHARINDEX(N'@four_w_rate decimal = null', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'@four_w_rate decimal = null',
        N'@four_w_rate decimal(10, 2) = null');
    SET @n += 1;
END

IF @n < 3
BEGIN
    RAISERROR('Apekshit teenpaiki fakt %d parameter sapadle. Kahi badalle nahi.', 16, 1, @n);
    RETURN;
END

SET @sql = STUFF(@sql, CHARINDEX('CREATE', @sql), 6, 'ALTER');
EXEC sp_executesql @sql;
PRINT 'sp_account_setting che dar-parameter durust zale.';
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte. Teenhi 'YES' aale pahijet.
   -------------------------------------------------------------------------*/
SELECT
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%@rate_per_sqf decimal(10, 2)%' THEN 'YES' ELSE 'NO' END AS [1_rate_per_sqf],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%@two_w_rate decimal(10, 2)%'   THEN 'YES' ELSE 'NO' END AS [2_two_w_rate],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_account_setting'))
              LIKE '%@four_w_rate decimal(10, 2)%'  THEN 'YES' ELSE 'NO' END AS [3_four_w_rate];

/* Aata je dar saathavle aahet te. Paise gelele asleli junee nondi ithe
   distil -- tya haatane parat bharayla lagtil, kaaran juna aakda gelela
   aahe.                                                                   */
SELECT society_id, rate_per_sqfeet, two_wheeler_rate, four_wheeler_rate
FROM dbo.account_setting;
GO
