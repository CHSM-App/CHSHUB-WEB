/* ============================================================================
   TESTING SATHI ADD-ON BILLS -- February, May, July 2026

   SSMS madhe he file ughda ani F5 dabaa.
   SEED_jan_to_jul_bills.sql AADHI chalvlela asava -- he tyavar bhar ghalte,
   junaa data kadhat nahi.

   ADD-ON REGULAR SARKHA NAHI
   --------------------------
   Regular dar mahinyala yeto. Add-on ekda-ekda -- gachchichi durusti, navin
   CCTV, rasta. Mhanun ithe teenach mahine, pratyekaat vegla kharch:

       Feb 2026  water         Rs 20,000   ->  769.23 per flat
       May 2026  Road charges  Rs 50,000   -> 1923.08 per flat
       Jul 2026  other charges Rs  4,000   ->  153.85 per flat

   Power Backup (2,50,000) ani NEW CCTV (1,00,000) muddam soalele -- te 9,615
   ani 3,846 per flat zale asate, testing sathi phaar motha.

   PRATYEK MAHINYALA CHARGE PUNHA CHALU KARAVA LAGTO
   -------------------------------------------------
   sp_new_maintenance run chya shevati aakarlele add-on heads band karto
   (status = 0) -- add-on ekdach ghyaycha asto. Mhanun script pratyek felee
   fakt tya mahinyacha charge chalu karto, baki band thevto.

   gen_bill sarkhech: SP aaj chi tarikh vaparto, mhanun bill banavun tyachi
   tarikh maage nyaavi lagte.
   ========================================================================= */

USE [society];
GO

SET NOCOUNT ON;

DECLARE @soc NVARCHAR(10) = 'C10001';

-- Kontya mahinyat konta charge
DECLARE @plan TABLE (mth INT, charge_id INT, label NVARCHAR(50));
INSERT INTO @plan (mth, charge_id, label) VALUES
    (2, 39, 'water'),
    (5,  6, 'Road charges'),
    (7, 29, 'other charges');

DECLARE @m INT, @cid INT, @label NVARCHAR(50),
        @bill_id INT, @gen DATE, @due DATE, @per DECIMAL(18,2);

DECLARE plan_cursor CURSOR FOR SELECT mth, charge_id, label FROM @plan ORDER BY mth;
OPEN plan_cursor;
FETCH NEXT FROM plan_cursor INTO @m, @cid, @label;

WHILE @@FETCH_STATUS = 0
BEGIN
    /* -- fakt hyaa mahinyacha charge chalu ------------------------------- */
    UPDATE dbo.maintenance_charges
    SET    status = CASE WHEN charge_id = @cid THEN 1 ELSE 0 END
    WHERE  society_id = @soc AND charges_type = 0;

    /* -- add-on bill banva ---------------------------------------------- */
    EXEC dbo.sp_new_maintenance
         @operation  = 'generate',
         @society_id = @soc,
         @bill_type  = 0,
         @due_period = 1,
         @interest   = 0;

    SELECT @bill_id = MAX(bill_id) FROM dbo.maintenance_cal WHERE society_id = @soc;

    /* -- tarikh tya mahinyat halva -------------------------------------- */
    -- Add-on mahinyachya 20 tarkhela, regular 1 tarkhela -- mhanun donhi
    -- ekyaach mahinyat astanahi vegle olakhata yetat.
    SET @gen = DATEFROMPARTS(2026, @m, 20);
    SET @due = DATEADD(DAY, 15, @gen);

    UPDATE dbo.maintenance_cal
    SET    gen_date = @gen, due_date = @due, m_date = @gen
    WHERE  bill_id = @bill_id AND society_id = @soc;

    SELECT @per = MIN(due) FROM dbo.maintenance_cal
    WHERE  bill_id = @bill_id AND society_id = @soc;

    PRINT CONCAT('Add-on #', @bill_id, ' -> ', FORMAT(@gen, 'MMMM yyyy'),
                 '  ', @label, '  Rs ', @per, ' per flat');

    FETCH NEXT FROM plan_cursor INTO @m, @cid, @label;
END

CLOSE plan_cursor;
DEALLOCATE plan_cursor;

-- Shevati sagle add-on band -- SP ne aapoaap kele asel, pan khatri karun.
UPDATE dbo.maintenance_charges
SET    status = 0
WHERE  society_id = @soc AND charges_type = 0;
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte
   -------------------------------------------------------------------------*/
SELECT mc.bill_id,
       FORMAT(MIN(mc.gen_date), 'MMMM yyyy')       AS period,
       CASE MIN(mc.bill_type) WHEN 1 THEN 'Regular' ELSE 'Add-on' END AS type,
       COUNT(*)                                    AS flats,
       CAST(MAX(mc.due) AS DECIMAL(18,2))          AS due_per_flat
FROM   dbo.maintenance_cal mc
WHERE  mc.society_id = 'C10001'
GROUP BY mc.bill_id
ORDER BY MIN(mc.gen_date);

-- Pratyek add-on bill var konte charge chhapel
SELECT bc.bill_Id, a.charges, a.amount
FROM   dbo.bill_charges bc
CROSS APPLY STRING_SPLIT(bc.Bill_Charges_Id, ',') s
JOIN   dbo.maintenance_charges_audit a ON a.audit_id = TRY_CAST(s.value AS INT)
WHERE  bc.Society_Id = 'C10001' AND bc.Charges_Type = 0
ORDER BY bc.bill_Id;
GO
