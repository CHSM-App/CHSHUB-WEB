/* ============================================================================
   FIX — bill_charges duplicate rows

   SSMS madhe he file ughda ani F5 dabaa. Don part aahet, kramane chaltat.

   Kaay chukat hote:
     gen_bill cha "INSERT INTO bill_charges" society-cursor chya BAAHER hota.
     Var chya guard ne bill banavne thambavle tari to insert chalatach rahila,
     mhanun ekach bill_id la don-teen rows padlya ani bill madhe pratyek charge
     donda / tinda chhaplaa (gardening x3, sinking x3 ...).

     Tyach shivay tya insert la MAX(bill_id) purnya table madhun milat hota ani
     @society_id madhe cursor chya shevatchya society chi value asaychi -- doni
     mule ekya society che charges dusrya chya bill la jodle jau shakat hote.
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   PART 1 — gen_bill durust kara
   -------------------------------------------------------------------------*/
ALTER PROCEDURE [dbo].[gen_bill]
    @bill_type INT = 0,
    @society_id NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @today INT,
        @bill_id INT,
        @last_bill_id INT = NULL,   -- last run actually created; NULL if none
        @rate FLOAT,
        @parking FLOAT,
        @due_days INT,
        @interest DECIMAL(18,2),
        @msg NVARCHAR(MAX),
        @bill_charges_ids NVARCHAR(100),
        @setting_charges_ids NVARCHAR(100);

    -- Society cursor
    DECLARE society_cursor CURSOR FOR
    SELECT
        society_id,
        CASE
            WHEN bill_gen_date BETWEEN (DATEPART(DAY, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE())))
                 AND DAY(EOMONTH(GETDATE()))
            THEN bill_gen_date
            ELSE DAY(EOMONTH(GETDATE()))
        END AS today,
        bill_due_period,
        ISNULL(interest_rate, 0)
    FROM account_setting
    WHERE (auto_bill_generation = CASE WHEN @bill_type = 0 THEN 1 ELSE 0 END)
      AND (@society_id IS NULL OR society_id = @society_id);

    OPEN society_cursor;
    FETCH NEXT FROM society_cursor INTO @society_id, @today, @due_days, @interest;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM maintenance_cal
            WHERE MONTH(gen_date) = MONTH(GETDATE())  AND YEAR(gen_date) = YEAR(GETDATE())
              AND bill_type = 1
              AND society_id = @society_id
        )
        AND (@today = DATEPART(DAY, GETDATE()) OR @bill_type = 1)
        BEGIN
            -- Held until the insert lands. gen_bill walks every society in one
            -- cursor, so two runs reading MAX at the same moment would both
            -- take the same bill_id and their bills would merge into one run.
            SELECT @bill_id = ISNULL(MAX(bill_id), 0) + 1
            FROM   maintenance_cal WITH (UPDLOCK, HOLDLOCK);

            DECLARE @flat_count INT, @total_billed DECIMAL(18,2) = 0;
            SELECT @flat_count = COUNT(DISTINCT flat_id)
            FROM flat_master
            WHERE  active_status=0 and society_id = @society_id;

            SELECT @rate = rate_per_sqfeet
            FROM account_setting
            WHERE society_id = @society_id;

            DECLARE flat_cursor CURSOR FOR
            SELECT flat_id, sq_ft
            FROM owner_search_vw
            WHERE society_id = @society_id
              AND type = 'Owner';

            DECLARE @flat_id INT, @sqft FLOAT;

            OPEN flat_cursor;
            FETCH NEXT FROM flat_cursor INTO @flat_id, @sqft;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE
                    @total_amt DECIMAL(18,2) = 0,
                    @amt_forward DECIMAL(18,2) = 0,
                    @tax_interest DECIMAL(18,2) = 0,
                    @prev_due DECIMAL(18,2) = 0,
                    @prev_tax DECIMAL(18,2) = 0,
                    @due DECIMAL(18,2) = 0;

                -- Shared maintenance per flat
                SELECT @total_amt = ISNULL(SUM(amount / NULLIF(@flat_count, 0)), 0)
                FROM maintenance_charges
                WHERE status = 1 AND charges_type = 1 AND society_id = @society_id;

                -- Add sqft and parking
                SELECT @parking = SUM(
                    CASE
                        WHEN v.vehicle_type = 0 THEN a.two_wheeler_rate
                        WHEN v.vehicle_type = 1 THEN a.four_wheeler_rate
                        ELSE 0
                    END)
                FROM Vehicle v
                INNER JOIN account_setting a ON v.society_id = a.society_id
                WHERE v.flat_id = @flat_id AND v.society_id = @society_id
                      AND ISNULL(v.park_place_id, 0) != 0;

                SET @total_amt +=  ISNULL(@parking, 0);

                -- Deduct advance
                --
                -- Not ABS(): that flips the sign, so an advance larger than the
                -- charge came back as money owed. Flat 43 holds 4,439.24 against
                -- a 1,100.00 bill -- ABS made that 3,339.24 payable when the
                -- resident is 3,339.24 in credit. Clamped at zero instead; the
                -- surplus stays where it is rather than being billed.
                --
                -- society_id matters too: flat_id is not unique across
                -- societies, so without it another society's advance could be
                -- deducted from this one's bill.
                SELECT @total_amt = @total_amt - ISNULL(SUM(advance), 0)
                FROM   maintenance_cal
                WHERE  flat_id = @flat_id AND society_id = @society_id;

                IF @total_amt < 0 SET @total_amt = 0;

                SET @due = @total_amt;

                -- Previous dues + interest
                --
                -- Scoped to the society for the same reason as the advance
                -- above: flat_id alone would pull another society's arrears
                -- onto this bill the moment two of them share a number.
                SELECT @prev_due = ISNULL(SUM(due), 0)
                FROM   maintenance_cal
                WHERE  flat_id = @flat_id
                  AND  society_id = @society_id
                  AND  due_date < DATEADD(DAY, -1, GETDATE());

                IF @prev_due > 0
                BEGIN
                    SET @amt_forward = @prev_due;
                    SET @tax_interest =round( ((@prev_due * @interest) / 100)/365* 31,2);
                END;

                -- Get last audit IDs correctly (no nested aggregates)
                ;WITH ChargesAgg AS (
                    SELECT MAX(audit_id) AS max_audit_id
                    FROM maintenance_charges_audit
                    WHERE charges_type = 1 AND society_id = @society_id
                    GROUP BY charge_id, society_id
                )
                SELECT @bill_charges_ids = STRING_AGG(CAST(max_audit_id AS NVARCHAR(10)), ',')
                FROM ChargesAgg;

                ;WITH SettingAgg AS (
                    SELECT MAX(audit_id) AS max_audit_id
                    FROM account_setting_audit
                    WHERE society_id = @society_id
                    GROUP BY acc_set_id, society_id
                )
                SELECT @setting_charges_ids = STRING_AGG(CAST(max_audit_id AS NVARCHAR(10)), ',')
                FROM SettingAgg;

                -- Insert bill
                INSERT INTO maintenance_cal
                (
                    maintenance_id, bill_id, bill_no, gen_date, due_date,
                    total_amount, due, flat_id, m_date, bill_type, society_id,
                    amt_forward, interest_forward, tax_interest_amt, advance, generate_status, status
                )
                SELECT
                    ISNULL(MAX(maintenance_id), 0) + 1, @bill_id,
                    ISNULL(MAX(bill_no), 0) + 1, CAST(GETDATE() AS DATE),
                    DATEADD(DAY, @due_days, GETDATE()),
                    @due, @due, @flat_id, GETDATE(), 1, @society_id,
                    @amt_forward, @interest, @tax_interest, 0, 1,
                   1
                FROM maintenance_cal;

                SET @total_billed += @total_amt;

                FETCH NEXT FROM flat_cursor INTO @flat_id, @sqft;
            END;

            CLOSE flat_cursor;
            DEALLOCATE flat_cursor;

            -- Charge heads for THIS society's run, written inside the society
            -- loop. Outside it this ran even when the guard above had skipped
            -- generation, so a second call on the same day appended another
            -- row and the bill printed every charge twice; a third call, three
            -- times. Inside, @society_id and @bill_id both still belong to the
            -- society just billed -- outside, @society_id holds whichever
            -- society the cursor happened to end on and MAX(bill_id) spans the
            -- whole table, so the charges could attach to another society's bill.
            IF NOT EXISTS (SELECT 1 FROM bill_charges
                           WHERE bill_Id = @bill_id AND Society_Id = @society_id)
                INSERT INTO bill_charges
                       (Bill_Charges_Id, Setting_Charges_Id, Society_Id, Charges_Type, bill_Id)
                VALUES (@bill_charges_ids, @setting_charges_ids, @society_id, @bill_type, @bill_id);

            -- Kept for the notification SELECT after the cursor closes.
            SET @last_bill_id = @bill_id;

            SET @msg = CONCAT('Bill generated for ', @flat_count,
                              ' flats @ rate ', @rate,
                              ' per sq.ft. Total billed Rs ', @total_billed);
            print 'Bill  generated Successfully';
        END
        ELSE
           print 'Bill already exists or generation skipped';

        FETCH NEXT FROM society_cursor INTO @society_id, @today, @due_days, @interest;
    END;

    CLOSE society_cursor;
    DEALLOCATE society_cursor;

    -- The bill_charges INSERT that stood here has moved inside the society
    -- loop; MAX(bill_id) over the whole table could not tell which society's
    -- run it belonged to.
    --  SELECT @bill_id = ISNULL(MAX(bill_id), 0)  FROM maintenance_cal;
    --  INSERT INTO bill_charges VALUES (@bill_charges_ids, @setting_charges_ids, @society_id, @bill_type, @bill_id);

    -- Push tokens for the run just created. Nothing was generated when
    -- @last_bill_id is still NULL, so return no rows rather than every owner.
    select bill_id as maintenance_id, token, type, owner_id
    from maintenance_cal m inner join userdata o on m.flat_id = o.flat_id
    where bill_id = @last_bill_id and token is not null and type = 'owner'
      and active_status = 0
    order by o.flat_id;
END;
GO


/* ---------------------------------------------------------------------------
   PART 2 — jo kharaab data aadhich padla aahe to saaf kara

   Testing madhe banavlele runs. Konteahi receipt yanna jodlele nahi -- tapasle
   aahe -- mhanun payment data tutat nahi.
   -------------------------------------------------------------------------*/
DELETE FROM dbo.bill_charges    WHERE bill_Id IN (39, 41, 42);
DELETE FROM dbo.maintenance_cal WHERE bill_id IN (39, 41) AND society_id = 'C10001';

-- Junya bills madhe uralele duplicate rows: pratyek bill la ekach thevaa.
WITH d AS (
    SELECT Id,
           ROW_NUMBER() OVER (PARTITION BY bill_Id, Society_Id, Charges_Type
                              ORDER BY Id) AS rn
    FROM dbo.bill_charges)
DELETE FROM d WHERE rn > 1;
GO


/* ---------------------------------------------------------------------------
   PART 3 — tapasnee (fakt vaachte, kahi badalat nahi)

   Pratyek bill la n = 1 aala pahije. Kuthe 2 kiwa 3 disle tar Part 2 punha
   chalva.
   -------------------------------------------------------------------------*/
SELECT bill_Id, Society_Id, Charges_Type, COUNT(*) AS n
FROM dbo.bill_charges
GROUP BY bill_Id, Society_Id, Charges_Type
HAVING COUNT(*) > 1
ORDER BY bill_Id DESC;
GO
