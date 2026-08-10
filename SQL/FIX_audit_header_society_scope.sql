/* ============================================================================
   FIX -- Audit Q&A: "Unsectioned questions" madhe prashna padtaat, ani
          Delete button kaam karat nahi

   SSMS madhe he file ughda ani F5 dabaa.

   KAAY CHUKAT HOTE
   ----------------
   1) insert_header cha navin id society ne filter karat navhta:

          SELECT TOP (1) @new = audt_header_id
          FROM   dbo.audt_header_lkp
          ORDER BY audt_header_id DESC;      -- SAGLYA societies madhun!
          SET @new = @new + 1;

      Mhanun id chi shrunkhala sagl‍ya societies madhe SHARED aahe. C10001 ne
      15,16,17,20 ghetle ani C10013 ne 0..19 -- donhi ekach range madhe.

   2) 'Update' (question insert) header KONACHYA society cha aahe he taapasat
      navhta. Foreign key fakta "header asto ka" evadhach baghto, "tyach
      society cha ka" nahi. Tyamule C10013 cha prashna C10001 chya header la
      jodla gela.

      Parinam: get_questions to prashna deta (society jullto), pan
      get_main_points tyacha header det nahi (society jullat nahi). Header
      nasleli prashna page "Unsectioned questions" madhe dakhavte.

   3) Delete operation ulta lihila hota:

          Update ... set status_id=1     -- 1 mhanje ACTIVE!

      get_questions `status_id = 1` var filter karta, mhanun "Delete" ne
      prashna lapat navhta -- ulta to active thevat hota. Aaj database madhe
      status_id <> 1 asleli EKHI prashna nahi, mhanjech ha button kadhich
      chalalach nahi.

   KAAY BADALTE
   ------------
   * insert_header  -- navin id fakta tyach society chya headers madhun.
   * Update         -- header doosrya society cha asel tar prashna vachavlach
                       jaat nahi; chuk parat pathavli jaate.
   * Delete         -- status_id = 0 (lapavto), 1 nahi.

   DATA
   ----
   Khali (2) madhe aadhich chukiche jodlele 5 prashna nishkriya kele aahet.
   Te 'temp que 1/3/4', 'sdfd', 'sfsdf' -- test data aahe, khara audit nahi.
   Te kadhaycha nasel tar to bhaag comment kara.
   ========================================================================= */

USE [society];
GO

/* ---------------------------------------------------------------------------
   (1) Stored procedure durust
   ------------------------------------------------------------------------ */
ALTER PROCEDURE [dbo].[sp_auditor_question_master]
@operation NVARCHAR (MAX)=NULL,
@audt_ques_id INT=0,
@question_desc NVARCHAR (MAX)=NULL,
@answer_desc NVARCHAR (500)=NULL,
@answer_key INT=0,
@status_id INT=0,
@society_id NVARCHAR(10)=null,
@audt_header_desc NVARCHAR(100) = NULL,
@audit_header_id INT = 0,
@sequence  INT=0

AS
BEGIN
    IF @operation = 'Update'
        BEGIN
            /* Header jya society cha aahe tyachyach prashnala jodta yeto.
               He nasel tar prashna disto pan tyacha header disat nahi, ani
               to "Unsectioned questions" madhe padto. */
            /* audt_header_id = 0 ha kharokhar aslela header aahe (C10013 kade
               to aahe), mhanun "0 mhanje dilela nahi" asa gruhit dharat nahi --
               pratyek veles society jullte ka evadhach taapasto. */
            IF NOT EXISTS (SELECT 1 FROM dbo.audt_header_lkp
                           WHERE audt_header_id = @audit_header_id
                             AND society_id     = @society_id)
                BEGIN
                    RAISERROR (N'Audit header does not belong to this society', 16, 1);
                    RETURN;
                END

            IF @audt_ques_id = 0
                BEGIN
				 DECLARE @new AS int =0;

                    SELECT   TOP (1) @new = audt_ques_id
                    FROM     dbo.auditor_question_master
                    ORDER BY audt_ques_id DESC;
                    IF @new IS NULL
                        BEGIN
                            SELECT @new = 0;
                        END
                    ELSE
                        BEGIN
                            SELECT @new = @new + 1;
                        END
                    INSERT  INTO dbo.auditor_question_master (audt_ques_id,society_id,question_desc,answer_desc, status_id, audt_header_id)
                    VALUES                      (@new,@society_id,N''+@question_desc,N''+@answer_desc, @status_id, @audit_header_id);
                END
            ELSE
                BEGIN
                    UPDATE dbo.auditor_question_master
                    SET
                           society_id    = @society_id,
                           question_desc = @question_desc,
                           answer_desc   = @answer_desc,
						   status_id     = @status_id,
						   audt_header_id= @audit_header_id
                    WHERE  audt_ques_id  = @audt_ques_id;
                END
        END

	IF @operation = 'insert_header'
		BEGIN
			IF @audit_header_id = 0
				BEGIN
                    /* Navin id FAKTA tyach society chya headers madhun.
                       Aadhi he sagl‍ya societies madhun ghetla jaat hota,
                       mhanun donhi societies ekach id range vaparat hotya. */
                    SELECT   TOP (1) @new = audt_header_id
                    FROM     dbo.audt_header_lkp
                    WHERE    society_id = @society_id
                    ORDER BY audt_header_id DESC;
                    IF @new IS NULL
                        BEGIN
                            SELECT @new = 0;
                        END
                    ELSE
                        BEGIN
                            SELECT @new = @new + 1;
                        END

                    /* audt_header_id ha primary key aahe, mhanun doosrya
                       society ne toch id aadhich ghetla asel tar pudhcha
                       mokla id ghyava lagto. */
                    WHILE EXISTS (SELECT 1 FROM dbo.audt_header_lkp
                                  WHERE audt_header_id = @new)
                        BEGIN
                            SET @new = @new + 1;
                        END

					INSERT INTO audt_header_lkp (audt_header_id, audt_header_desc, status_id,society_id)
					OUTPUT INSERTED.audt_header_id
					Values (@new,@audt_header_desc, @status_id,@society_id);
			END
		ELSE
			BEGIN
				UPDATE dbo.audt_header_lkp
				SET
					audt_header_desc = @audt_header_desc,
					status_id = @status_id,
					society_id = @society_id where audt_header_id = @audit_header_id;
			END
		END

    IF @operation = 'Select'
        BEGIN
            SELECT *
            FROM   dbo.auditor_question_master
            WHERE  audt_ques_id = @audt_ques_id;
        END
    IF @operation = 'Delete'
        BEGIN
            /* 0 = lapavlela. Aadhi ithe 1 lihila hota -- to ACTIVE aahe,
               mhanun Delete ne kahich lapat navhte. */
            Update dbo.auditor_question_master set status_id=0
            WHERE  audt_ques_id = @audt_ques_id;
        END


    /* Ha branch audit shi sambandhit nahi -- income vs expense report
       (/reports/income-expense) to vaparto. Jasa aahe tasach thevla aahe. */
    IF @operation = 'Grid_Bind_CD'
        BEGIN
		WITH inc AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
        prev_year_income,
        description AS income_description,
        current_year_income
    FROM yearwise_income  WHERE  society_id = @society_id
),
exp AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
        prev_year_expense,
        description AS expense_description,
        current_year_expense
    FROM yearwise_expense  WHERE  society_id = @society_id
)
SELECT
    COALESCE(inc.prev_year_income, NULL) AS prev_year_income,
    inc.income_description AS INCOME,
    COALESCE(inc.current_year_income, NULL) AS current_year_income,
    COALESCE(exp.prev_year_expense, NULL) AS prev_year_expense,
    exp.expense_description AS EXPENSE,
    COALESCE(exp.current_year_expense, NULL) AS current_year_expense
FROM inc
FULL OUTER JOIN exp
    ON inc.rn = exp.rn
ORDER BY inc.rn;

        END

		 IF @operation = 'get_main_points'
        BEGIN
            SELECT *
            FROM   dbo.audt_header_lkp where status_id=1 and society_id=@society_id  order by SequenceOrder asc ;
        END
		 IF @operation = 'get_questions'
        BEGIN
            SELECT *
            FROM   dbo.auditor_question_master
            WHERE  status_id = 1 and society_id=@society_id order by audt_ques_id asc ;
        END

		IF @operation='Update_Sequence'
		BEGIN

		 UPDATE audt_header_lkp set SequenceOrder=@sequence where audt_header_id=@audit_header_id;
		END

		IF @operation='get_Society_Info'
		Begin
			select * from society_info where society_id=@society_id
			END

 END
GO


/* ---------------------------------------------------------------------------
   (2) Chukiche jodlele test prashna nishkriya kara

   He 5 prashna C10013 che aahet pan C10001 chya headers la jodle gele --
   mhanunach te "Unsectioned questions" madhe distaat.

   Aadhi baghun ghya:
   ------------------------------------------------------------------------ */
SELECT qm.audt_ques_id, qm.question_desc, qm.society_id AS prashna_society,
       qm.audt_header_id, h.society_id AS header_society
FROM   dbo.auditor_question_master qm
JOIN   dbo.audt_header_lkp h ON h.audt_header_id = qm.audt_header_id
WHERE  qm.status_id = 1
  AND  h.society_id <> qm.society_id;
GO

/* Var dislelya rows barobar astil tar khalcha UPDATE chalva.
   (status_id = 0 -- row kadhat nahi, fakta lapavto.) */
UPDATE qm
SET    qm.status_id = 0
FROM   dbo.auditor_question_master qm
JOIN   dbo.audt_header_lkp h ON h.audt_header_id = qm.audt_header_id
WHERE  qm.status_id = 1
  AND  h.society_id <> qm.society_id;
GO

PRINT 'Audit fix laagu zala.';
GO
