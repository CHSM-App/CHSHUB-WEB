/* ============================================================================
   TESTING SATHI DATA -- January 2026 te July 2026 bills + kahi payments

   SSMS madhe he file ughda ani F5 dabaa.

   KASE BANAVLE JATAT
   ------------------
   gen_bill nehmi AAJCHI tarikh vaparto (CAST(GETDATE() AS DATE)); tyat
   maaghcha mahina denyachi soy nahi. Mhanun pratyek mahinyasathi:

       1. gen_bill chalva          -> to mahinyacha bill, aaj chya tarkhene
       2. tya run chi tarikh maage -> to mahina banto
       3. tya mahinyache payments  -> LAGECH, pudhcha bill banavnyaadhi

   Payment lagech ka: sp_SettleMaintenancePayment bill_no varun konte bill
   fedaayche te thravto. Sagle bills aadhi banavun mag payments kele tar
   madhlya mahinyanche bill_no badalte ani ek hi payment lagat nahi.

   Ganit SP chach rahte -- amt_forward, bill_no, due sagle SP ne mojlele.
   Rows haatane taakalya asatya tar ti saakhali aapan banavavi lagli asti,
   ani nemke tithech aadhiche dosh hote.

   KAY BANEL
   ---------
   - Jan te Jul 2026 -- 7 regular bill runs
   - Feb: 3 flats purna | Apr: 2 purna + 1 ardhe | Jun: 4 purna
   - Baki flats ni kahich bharle nahi -> thakbaki jamat jate

   AADHI SAGLA JUNA DATA JATO. Te receipts ani runs test data aahet (fakt
   3-4 flats, receipt 28 ani 29 sarkhech duplicate), mhanun kadhne surakshit.
   ========================================================================= */

USE [society];
GO

SET NOCOUNT ON;

DECLARE @soc NVARCHAR(10) = 'C10001';

/* ---------------------------------------------------------------------------
   1) Juna data kadha
   -------------------------------------------------------------------------*/
DELETE FROM dbo.bill_charges    WHERE Society_Id = @soc;
DELETE FROM dbo.maintenance_cal WHERE society_id = @soc;
DELETE FROM dbo.receipt         WHERE society_id = @soc;

PRINT 'Juna data kadhla.';


/* ---------------------------------------------------------------------------
   2) Jan te Jul 2026 -- bill + tyach mahinyache payments
   -------------------------------------------------------------------------*/
DECLARE @m INT = 1, @bill_id INT, @gen DATE, @due DATE, @paid INT = 0;
DECLARE @flat INT, @amt DECIMAL(10,2), @billno NVARCHAR(50), @ref NVARCHAR(100);
DECLARE @paydate SMALLDATETIME;
DECLARE @full INT, @half INT;

WHILE @m <= 7
BEGIN
    /* -- bill banva ---------------------------------------------------- */
    EXEC dbo.gen_bill @bill_type = 1, @society_id = @soc;

    SELECT @bill_id = MAX(bill_id) FROM dbo.maintenance_cal WHERE society_id = @soc;

    SET @gen = DATEFROMPARTS(2026, @m, 1);
    SET @due = DATEADD(DAY, 15, @gen);

    UPDATE dbo.maintenance_cal
    SET    gen_date = @gen, due_date = @due, m_date = @gen
    WHERE  bill_id = @bill_id AND society_id = @soc;

    PRINT CONCAT('Bill #', @bill_id, ' -> ', FORMAT(@gen, 'MMMM yyyy'));

    /* -- tya mahinyache payments --------------------------------------- */
    -- Feb 3 purna | Apr 2 purna + 1 ardhe | Jun 4 purna | baki mahine kahich
    SET @full = CASE @m WHEN 2 THEN 3 WHEN 4 THEN 2 WHEN 6 THEN 4 ELSE 0 END;
    SET @half = CASE @m WHEN 4 THEN 1 ELSE 0 END;

    IF @full > 0 OR @half > 0
    BEGIN
        DECLARE pay_cursor CURSOR LOCAL FOR
            SELECT flat_id, bill_no, ROUND(due * part, 2)
            FROM (
                SELECT TOP (@full) flat_id, bill_no, due, 1.00 AS part
                FROM   dbo.maintenance_cal
                WHERE  bill_id = @bill_id AND society_id = @soc AND due > 0
                ORDER BY flat_id
                UNION ALL
                SELECT TOP (@half) flat_id, bill_no, due, 0.50
                FROM   dbo.maintenance_cal
                WHERE  bill_id = @bill_id AND society_id = @soc AND due > 0
                ORDER BY flat_id DESC        -- dusrya tokakadun, overlap nako
            ) x;

        OPEN pay_cursor;
        FETCH NEXT FROM pay_cursor INTO @flat, @billno, @amt;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @paid += 1;
            SET @ref = CONCAT('SEED-', @m, '-', @flat, '-', @paid);
            -- Expressions cannot be passed straight to EXEC parameters.
            SET @paydate = DATEADD(DAY, 10, @gen);

            -- @CreatedBy ani @TransactionRef doni dyaave lagtat: created_by
            -- NULL gheto nahi, ani transaction_ref var UNIQUE constraint aahe
            -- jo don NULL suddha gheto nahi. SP donhicha default NULL aahe,
            -- mhanun tyanchya shivay dusra receipt taakalach jat nahi.
            EXEC dbo.sp_MaintenanceReceipt
                 @Action         = 'INSERT',
                 @SocietyID      = @soc,
                 @FlatID         = @flat,
                 @PayMode        = '1',                 -- cash
                 @PaidAmount     = @amt,
                 @Remarks        = 'Seeded test payment',
                 @ReceiptDate    = @paydate,
                 @CreatedBy      = '1',
                 @TransactionRef = @ref,
                 @bills          = @billno;

            FETCH NEXT FROM pay_cursor INTO @flat, @billno, @amt;
        END

        CLOSE pay_cursor;
        DEALLOCATE pay_cursor;
    END

    SET @m += 1;
END

PRINT CONCAT('Payments taakle: ', @paid);
GO


/* ---------------------------------------------------------------------------
   TAPASNEE -- fakt vaachte
   -------------------------------------------------------------------------*/
SELECT bill_id,
       FORMAT(MIN(gen_date), 'MMMM yyyy')          AS period,
       COUNT(*)                                    AS flats,
       CAST(MAX(due) AS DECIMAL(18,2))             AS due_per_flat,
       CAST(MIN(amt_forward) AS DECIMAL(18,2))     AS arrears_carried,
       SUM(CASE WHEN due = 0 THEN 1 ELSE 0 END)    AS fully_paid
FROM   dbo.maintenance_cal
WHERE  society_id = 'C10001'
GROUP BY bill_id
ORDER BY MIN(gen_date);

SELECT COUNT(*) AS receipts, SUM(paid_amount) AS collected
FROM   dbo.receipt WHERE society_id = 'C10001' AND status = 3;
GO
