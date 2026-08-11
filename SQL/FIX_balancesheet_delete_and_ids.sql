/* ============================================================================
   FIX -- Balance Sheet: Delete button kaam karat nahi, ani navin id
          doosrya society chi id kaadun ghete

   SSMS madhe he file ughda ani F5 dabaa.

   KAAY CHUKAT HOTE
   ----------------
   1) Delete operation ulta lihila hota:

          IF @operation = 'Delete'
              Update dbo.balancesheet_sub_point set status_id=1   -- 1 = ACTIVE!

      get_sub_point `status_id = 1` var filter karta. Mhanun "Delete" ne
      sub-point lapat navhta -- ulta to ACTIVE thevat hota. Aaj database madhe
      status_id <> 1 asleli EKHI row nahi (na head, na sub-point), mhanjech ha
      button kadhich chalalach nahi.

      Tasach, head sathi Delete cha branch mullatach nahiye -- balance sheet
      madhun ek purna head kaadhaycha marg nahi.

   2) Navin id chi shrunkhala SAGLYA societies madhun ghetli jaate:

          SELECT TOP (1) @new = bal_head_id
          FROM dbo.balancesheet_head_lkp
          ORDER BY bal_head_id DESC;      -- village_id cha filter nahi!
          SET @new = ISNULL(@new,0) + 1;

      Don societies ekach kshani head add kartil tar donhina EKACH id miळel
      ani dusri INSERT primary key var aapटel. Sub-point cha insert madhe pan
      tich chuk aahe.

      NOND: id ranges aaj tenants madhe MISHRIT aahet --
          ''        -> heads 7..30,  subs 6..34
          'V10013'  -> heads 3..6,   subs 1..5
          'C10001'  -> head 31,      subs 35..36
      Mhanun ithe society-nihay MAX+1 karta YENAR NAHI (3..6 aadhich vaparle
      aahet). Global MAX+1 tasach thevla aahe, pan to aata serializable lock
      khali aahe -- donhi session ekach id kaadhu shakat nahit.

   KAAY BADALTE
   ------------
   * Delete (sub-point) -- status_id = 0 (lapavto), 1 nahi.
   * DeleteHeader       -- NAVIN. Head ani tyachya sagl‍ya sub-points lapavto.
   * insert_header      -- id kaadhana serializable, race condition nahi.
   * Update (sub-point) -- tech, ani head doosrya tenant cha nasel he taapasto.

   DATA
   ----
   He script KONTIHI existing row badalat nahi. Fakta stored procedure badalte.
   Aaj status_id <> 1 asleli ekhi row nasl‍yamule kahihi lapnaar nahi.
   ========================================================================= */

USE [society];
GO

ALTER PROCEDURE [dbo].[sp_balancesheet]
@operation NVARCHAR (50)=NULL,
@bal_sub_id INT=0,
@bal_sub_desc NVARCHAR (50)=NULL,
@amount decimal(18,2)=0,
@status_id INT=0,
@village_id NVARCHAR(10)=null,
@bal_header_desc NVARCHAR(100) = NULL,
@bal_head_id INT = 0,
@Seq_order  INT=0,
@comp_id int=0

AS
BEGIN
    SET NOCOUNT ON;

    IF @operation = 'Update'
        BEGIN
            /* Head jya tenant cha aahe tyachyach sub-point la jodta yeto.
               He nasel tar ek society doosrya chya head khali sub-point
               taaku shakte. */
            IF NOT EXISTS (SELECT 1 FROM dbo.balancesheet_head_lkp
                           WHERE bal_head_id = @bal_head_id
                             AND ISNULL(village_id,'') = ISNULL(@village_id,''))
                BEGIN
                    RAISERROR (N'Balance sheet head does not belong to this society', 16, 1);
                    RETURN;
                END

            IF @bal_sub_id = 0
                BEGIN
                    DECLARE @new AS int = 0;

                    /* Navin id ani INSERT ek‍aach transaction madhe. Serializable
                       mhanje dusra session tich id kaadhu shakat nahi. */
                    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
                    BEGIN TRANSACTION;

                        SELECT @new = ISNULL(MAX(bal_sub_id), 0) + 1
                        FROM   dbo.balancesheet_sub_point WITH (UPDLOCK, HOLDLOCK);

                        INSERT INTO dbo.balancesheet_sub_point
                            (bal_sub_id, village_id, bal_sub_desc, amount, status_id, bal_head_id)
                        VALUES
                            (@new, @village_id, N''+@bal_sub_desc, @amount, @status_id, @bal_head_id);

                    COMMIT TRANSACTION;
                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                END
            ELSE
                BEGIN
                    UPDATE dbo.balancesheet_sub_point
                    SET
                           village_id    = @village_id,
                           bal_sub_desc  = N''+@bal_sub_desc,
                           amount        = @amount,
                           status_id     = @status_id,
                           bal_head_id   = @bal_head_id
                    WHERE  bal_sub_id    = @bal_sub_id;
                END
        END

    IF @operation = 'insert_header'
        BEGIN
            IF @bal_head_id = 0
                BEGIN
                    DECLARE @newh AS int = 0;

                    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
                    BEGIN TRANSACTION;

                        SELECT @newh = ISNULL(MAX(bal_head_id), 0) + 1
                        FROM   dbo.balancesheet_head_lkp WITH (UPDLOCK, HOLDLOCK);

                        INSERT INTO dbo.balancesheet_head_lkp
                        (
                            bal_head_id, bal_header_desc, amount,
                            status_id, village_id, Seq_order, comp_id
                        )
                        OUTPUT INSERTED.bal_head_id
                        VALUES
                        (
                            @newh, @bal_header_desc, @amount,
                            @status_id, @village_id, @Seq_order, @comp_id
                        );

                    COMMIT TRANSACTION;
                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                END
            ELSE
                BEGIN
                    UPDATE dbo.balancesheet_head_lkp
                    SET
                        bal_header_desc = @bal_header_desc,
                        status_id       = @status_id,
                        amount          = @amount,
                        village_id      = @village_id,
                        Seq_order       = @Seq_order,
                        comp_id         = @comp_id
                    OUTPUT INSERTED.bal_head_id
                    WHERE bal_head_id = @bal_head_id;
                END
        END

    IF @operation = 'Select'
        BEGIN
            SELECT *
            FROM   dbo.balancesheet_sub_point
            WHERE  bal_sub_id = @bal_sub_id;
        END

    /* status_id = 0 -- 1 nahi. 1 mhanje ACTIVE, ani get_sub_point tyavarach
       filter karta, mhanun jhuna code "delete" karun row ULTA disat theवat hota. */
    IF @operation = 'Delete'
        BEGIN
            UPDATE dbo.balancesheet_sub_point
            SET    status_id = 0
            WHERE  bal_sub_id = @bal_sub_id;
        END

    /* NAVIN: purna head lapavto, tyachya sagl‍ya sub-points sahit. Ase kelyashivay
       balance sheet madhun ek head kaadhaycha marg navhta. */
    IF @operation = 'DeleteHeader'
        BEGIN
            UPDATE dbo.balancesheet_sub_point
            SET    status_id = 0
            WHERE  bal_head_id = @bal_head_id;

            UPDATE dbo.balancesheet_head_lkp
            SET    status_id = 0
            WHERE  bal_head_id = @bal_head_id;
        END

    IF @operation = 'get_main_points'
        BEGIN
            SELECT *
            FROM   dbo.balancesheet_head_lkp
            WHERE  status_id = 1 AND village_id = @village_id
            ORDER BY Seq_order ASC;
        END

    IF @operation = 'get_sub_point'
        BEGIN
            SELECT *
            FROM   dbo.balancesheet_sub_point
            WHERE  status_id = 1 AND village_id = @village_id
            ORDER BY bal_sub_id ASC;
        END

    IF @operation = 'Update_Seq_order'
        BEGIN
            UPDATE dbo.balancesheet_head_lkp
            SET    Seq_order = @Seq_order
            WHERE  bal_head_id = @bal_head_id;
        END
END
GO
