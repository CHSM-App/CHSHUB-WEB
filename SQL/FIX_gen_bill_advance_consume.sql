/*
  gen_bill -- an applied advance was never consumed, so it was re-applied on
  every run.

  THE BUG
  -------
  gen_bill deducts the flat's advance from the new monthly charge, but never
  clears the advance it just spent: the INSERT hardcodes advance = 0 on the NEW
  row while the OLD row keeps its value. SUM(advance) therefore returns the same
  figure on every subsequent run and the resident is credited month after month.

  Verified read-only against Society on winsome before writing. Six flats were
  exposed; each amount would be granted again on every run:

      flat  bill_no   advance     sitting since
        7     1287     230.77     2026-08-04
       43      878    4439.24     2025-12-18
       53      834     246.13     2025-12-18
       54      835     139.12     2025-12-18
       56      702      32.10     2025-08-20
       77      984      96.32     2026-05-21
                     --------
                      5183.68  per run

  THE FIX
  -------
  Capture the advance into @advance_used, deduct it as before, then zero the
  rows it came from -- per flat, inside the cursor, before moving on. The credit
  is spent exactly once.

  Preserved deliberately:
    - the deduction still happens BEFORE interest is computed (@prev_due and
      @tax_interest below are untouched)
    - @total_amt is still floored at 0, so a credit larger than the month's
      charge cannot produce a negative bill

  KNOWN LIMITATION, NOT ADDRESSED: when the advance exceeds the monthly charge
  the excess is discarded rather than carried forward -- unchanged from the
  existing floor-at-zero behaviour. Carrying it would change what `advance`
  means on a freshly generated bill, which is an accounting decision.

  This script alters the procedure only. It does not modify any existing
  maintenance_cal row: the six advances above stay put until the next run,
  which will apply and clear them once.

  ROLLBACK: SQL/gen_bill_BEFORE_advance_fix.sql holds the current definition.
*/

USE [Society];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[gen_bill]
    @bill_type INT = 0,
    @society_id NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @today INT,
        @bill_id INT,
        @last_bill_id INT = NULL,
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
            --SELECT @bill_id = ISNULL(MAX(bill_id), 0) + 1 FROM maintenance_cal;
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
                    @due DECIMAL(18,2) = 0,
                    @advance_used DECIMAL(18,2) = 0;

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
                --SELECT @total_amt = ABS(@total_amt - ISNULL(SUM(advance), 0))
                --FROM maintenance_cal WHERE flat_id = @flat_id;
                -- Captured into a variable so the credit can be cleared below.
                -- Previously the rows kept their advance, so every later run
                -- deducted the same amount again.
                SELECT @advance_used = ISNULL(SUM(advance), 0)
                FROM   maintenance_cal
                WHERE  flat_id = @flat_id AND society_id = @society_id;

                SET @total_amt = @total_amt - @advance_used;

                IF @total_amt < 0 SET @total_amt = 0;

                -- Spend it: this credit has now been applied to this bill.
                IF @advance_used > 0
                    UPDATE maintenance_cal
                    SET    advance = 0
                    WHERE  flat_id = @flat_id
                      AND  society_id = @society_id
                      AND  ISNULL(advance, 0) > 0;

				 
                SET @due = @total_amt;

                -- Previous dues + interest
                --SELECT @prev_due = ISNULL(SUM(due), 0)
                --FROM maintenance_cal 
                --WHERE flat_id = @flat_id AND due_date < DATEADD(DAY, -1, GETDATE());
				                SELECT @prev_due = ISNULL(SUM(due), 0)
                FROM   maintenance_cal 
                WHERE  flat_id = @flat_id
                  AND  society_id = @society_id
                  AND  due_date < DATEADD(DAY, -1, GETDATE());

			
                IF @prev_due > 0
                BEGIN
                    SET @amt_forward = @prev_due;
                    SET @tax_interest =round( ((@prev_due * @interest) / 100)/365* 31,2);
                    --SET @total_amt += @amt_forward + @tax_interest;
				-- 	set @tax_interest= @prev_tax+@tax_interest;
                END;

                -- Get last audit IDs correctly (no nested aggregates)
                --;WITH ChargesAgg AS (
                --    SELECT MAX(audit_id) AS max_audit_id
                --    FROM maintenance_charges_audit
                --    WHERE charges_type = 1 AND society_id = @society_id
                --    GROUP BY charge_id, society_id
                --)
				                ;WITH ChargesAgg AS (
                    -- Live table shi join: audit madhe pratyek charge cha juna
                    -- row rahto, mhanun tyavar filter kelyane band kelele
                    -- charges suddha bill var yet hote. Ithe 'status' chi at
                    -- aahech navhti, mhanun ithla dosh ajun motha hota.
                    SELECT MAX(a.audit_id) AS max_audit_id
                    FROM maintenance_charges_audit a
                    INNER JOIN maintenance_charges c
                            ON c.charge_id = a.charge_id AND c.society_id = a.society_id
                    WHERE a.charges_type = 1 AND a.society_id = @society_id
                      AND c.status = 1 AND c.charges_type = 1
                    GROUP BY a.charge_id, a.society_id
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
                   1-- CASE WHEN @total_amt = @due THEN 1 ELSE 5 END          if advance payment exist then status 5 partially paid 
                FROM maintenance_cal;

                SET @total_billed += @total_amt;

                FETCH NEXT FROM flat_cursor INTO @flat_id, @sqft;
            END;

            CLOSE flat_cursor;
            DEALLOCATE flat_cursor;

            -- Charge heads for THIS society's run, written inside the society
            -- loop. Outside it this ran even when the guard above had skipped
            -- generation, so a second call the same day appended another row
            -- and the bill printed every charge twice; a third call, three
            -- times. Inside, @society_id and @bill_id both still belong to the
            -- society just billed -- outside, @society_id held whichever
            -- society the cursor ended on and MAX(bill_id) spanned the whole
            -- table, so the charges could attach to another society's bill.
            IF NOT EXISTS (SELECT 1 FROM bill_charges
                           WHERE bill_Id = @bill_id AND Society_Id = @society_id)
                INSERT INTO bill_charges
                       (Bill_Charges_Id, Setting_Charges_Id, Society_Id, Charges_Type, bill_Id)
                VALUES (@bill_charges_ids, @setting_charges_ids, @society_id, @bill_type, @bill_id);

            -- Kept for the notification SELECT after the cursor closes.
            SET @last_bill_id = @bill_id;

            SET @msg = CONCAT('Bill generated for ', @flat_count, 
                              ' flats @ rate ', @rate, 
                              ' per sq.ft. Total billed ₹', @total_billed);
print 'Bill  generated Successfully';

           
        END
        ELSE
       
           print 'Bill already exists or generation skipped';
  

        FETCH NEXT FROM society_cursor INTO @society_id, @today, @due_days, @interest;
    END;

    CLOSE society_cursor;
    DEALLOCATE society_cursor;

    -- The bill_charges INSERT that stood here has moved inside the society loop;
    -- MAX(bill_id) over the whole table could not tell which society's run it
    -- belonged to.
	--  SELECT @bill_id = ISNULL(MAX(bill_id), 0)  FROM maintenance_cal;
    --  INSERT INTO bill_charges VALUES (@bill_charges_ids, @setting_charges_ids, @society_id, @bill_type, @bill_id);

    -- Push tokens for the run just created. Nothing was generated when
    -- @last_bill_id is still NULL, so return no rows rather than every owner.
	select bill_id as maintenance_id,token,type,owner_id  from maintenance_cal m inner join userdata o on  m.flat_id=o.flat_id
	where bill_id=@last_bill_id and token is not null and type='owner' and active_status=0 order by o.flat_id ;
END;

GO
