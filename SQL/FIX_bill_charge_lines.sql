/* ============================================================================
   FIX -- bill var band zalele charges dista

   SSMS madhe he file ughda ani F5 dabaa. Kahihi copy-paste karaychi garaj nahi.

   KAAY CHUKAT HOTE
   ----------------
   Bill chya olee (Nature of Charges) maintenance_charges_audit madhun yetat.
   Audit mhanje ITIHAAS -- pratyek charge cha "to kadhitari chalu hota" asa
   ek tari row astoch. Doni SP tya audit var 'status = 1' lavat hote, aaj chi
   sthiti nahi. Mhanun ekda banavlela pratyek add-on charge kayamcha pratyek
   bill madhe disat hota.

   Bill 42 madhe: tumhi fakt water ani parking chalu kele hote.
     - Kharokhar aakarle       : Rs 846.15  (water + parking / 26)  <- barobar
     - PDF var chhaplya olee   : 9 charges, Rs 18,290.58 chya       <- chuk
     - Road charges 2025 pasun band, Gardaning January pasun band -- tarihi distat

   Rakkam barobar hoti kaaran ti maintenance_charges (khare table) madhun
   yete. Fakt OLEE chukichya hotya. Rahivasi vicharel "he Road charges
   kasle?" ani uttar deta yenar nahi.

   gen_bill madhe toch dosh, ajun vait: tithe 'status' chi at aahech nahi.

   DURUSTI
   -------
   Audit nivadtana live table shi join kara: audit fakt "konti aavruti"
   sangte, "kaay aakarayche" he live table thravte.
   ========================================================================= */

USE [society];
GO

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX), @n INT = 0;

/* ---------------------------------------------------------------------------
   1) sp_new_maintenance -- add-on bills. Don jaga aahet (ek mukhya, ek
      fallback jo @bill_charges_ids NULL asel tar chalto).
   -------------------------------------------------------------------------*/
SET @sql = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_new_maintenance'));

IF @sql IS NULL
BEGIN
    RAISERROR('sp_new_maintenance sapadla nahi.', 16, 1);
    RETURN;
END

-- Mukhya block
IF CHARINDEX(N'FROM maintenance_charges_audit
			WHERE charges_type=0 and status=1 and  society_id = @society_id', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'FROM maintenance_charges_audit
			WHERE charges_type=0 and status=1 and  society_id = @society_id',
        N'FROM maintenance_charges_audit a
			INNER JOIN maintenance_charges c
			        ON c.charge_id = a.charge_id AND c.society_id = a.society_id
			WHERE a.charges_type=0 and a.society_id = @society_id
			  and c.status = 1 and c.charges_type = 0');
    SET @n += 1;
END

-- Tyach block madhla column reference durust kara
SET @sql = REPLACE(@sql,
    N'SELECT MAX(audit_id) AS max_audit_id
			FROM maintenance_charges_audit a',
    N'SELECT MAX(a.audit_id) AS max_audit_id
			FROM maintenance_charges_audit a');
SET @sql = REPLACE(@sql,
    N'  and c.status = 1 and c.charges_type = 0
			GROUP BY charge_id,society_id',
    N'  and c.status = 1 and c.charges_type = 0
			GROUP BY a.charge_id, a.society_id');

-- Fallback block (IF @bill_charges_ids IS NULL chya aat)
IF CHARINDEX(N'FROM maintenance_charges_audit
        WHERE charges_type = 0 AND status = 1 AND society_id = @society_id', @sql) > 0
BEGIN
    SET @sql = REPLACE(@sql,
        N'SELECT MAX(audit_id) AS max_audit_id
        FROM maintenance_charges_audit
        WHERE charges_type = 0 AND status = 1 AND society_id = @society_id
        GROUP BY charge_id, society_id',
        N'SELECT MAX(a.audit_id) AS max_audit_id
        FROM maintenance_charges_audit a
        INNER JOIN maintenance_charges c
                ON c.charge_id = a.charge_id AND c.society_id = a.society_id
        WHERE a.charges_type = 0 AND a.society_id = @society_id
          AND c.status = 1 AND c.charges_type = 0
        GROUP BY a.charge_id, a.society_id');
    SET @n += 1;
END

IF @n < 2
BEGIN
    RAISERROR('sp_new_maintenance: apekshit olee sapadlya nahit (%d/2). Kahi badalle nahi.', 16, 1, @n);
    RETURN;
END

SET @sql = STUFF(@sql, CHARINDEX('CREATE', @sql), 6, 'ALTER');
EXEC sp_executesql @sql;
PRINT 'sp_new_maintenance durust zala.';
GO


/* ---------------------------------------------------------------------------
   2) gen_bill -- regular monthly bills. Tithe 'status' chi at aahech nahi,
      mhanun band kelela regular charge suddha bill var disat rahto.
   -------------------------------------------------------------------------*/
SET NOCOUNT ON;

DECLARE @g NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.gen_bill'));

IF @g IS NULL
BEGIN
    RAISERROR('gen_bill sapadla nahi.', 16, 1);
    RETURN;
END

IF CHARINDEX(N'SELECT MAX(audit_id) AS max_audit_id
                    FROM maintenance_charges_audit
                    WHERE charges_type = 1 AND society_id = @society_id
                    GROUP BY charge_id, society_id', @g) = 0
BEGIN
    RAISERROR('gen_bill: apekshit ol sapadli nahi. Kahi badalle nahi.', 16, 1);
    RETURN;
END

SET @g = REPLACE(@g,
    N'SELECT MAX(audit_id) AS max_audit_id
                    FROM maintenance_charges_audit
                    WHERE charges_type = 1 AND society_id = @society_id
                    GROUP BY charge_id, society_id',
    N'SELECT MAX(a.audit_id) AS max_audit_id
                    FROM maintenance_charges_audit a
                    INNER JOIN maintenance_charges c
                            ON c.charge_id = a.charge_id AND c.society_id = a.society_id
                    WHERE a.charges_type = 1 AND a.society_id = @society_id
                      AND c.status = 1 AND c.charges_type = 1
                    GROUP BY a.charge_id, a.society_id');

SET @g = STUFF(@g, CHARINDEX('CREATE', @g), 6, 'ALTER');
EXEC sp_executesql @g;
PRINT 'gen_bill durust zala.';
GO


/* ---------------------------------------------------------------------------
   3) Bill 42 kadha -- to chukichya olee dakhavto.
      Konteahi receipt yala jodlele nahi.
   -------------------------------------------------------------------------*/
DELETE FROM dbo.bill_charges    WHERE bill_Id = 42;
DELETE FROM dbo.maintenance_cal WHERE bill_id = 42 AND society_id = 'C10001';
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte.
   Doni 'YES' aale pahijet, ani teesri query rikami aali pahije.
   -------------------------------------------------------------------------*/
SELECT
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.sp_new_maintenance'))
              LIKE '%INNER JOIN maintenance_charges c%' THEN 'YES' ELSE 'NO' END AS [1_addon_joined],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.gen_bill'))
              LIKE '%INNER JOIN maintenance_charges c%' THEN 'YES' ELSE 'NO' END AS [2_regular_joined];

-- Bill 42 gela ka?
SELECT bill_id, COUNT(*) AS rows_left
FROM dbo.maintenance_cal WHERE bill_id = 42 GROUP BY bill_id;
GO
