/* ============================================================================
   sp_UserLogin — FULL procedure, ready to execute.

   This is the live procedure exactly as it stands, with ONE block changed:
   `IF @operation = 'UpdateProfile'`. Everything else is byte-for-byte the
   version currently deployed, so running this whole file is safe.

   WHAT CHANGED AND WHY
   --------------------
   The UpdateProfile branch guarded some columns against a NULL parameter and
   not others:

       password   = case when @Password is null ... then password else ... end   -- guarded
       Name       = case when @Name     is null ... then Name     else ... end   -- guarded
       photo_path = case when @photo_path is null then photo_path ... end        -- guarded
       username   = @username        -- NOT guarded
       contact_no = @contact_no      -- NOT guarded
       email      = @email           -- NOT guarded

   /onboarding/change-password calls this branch to write only a password. It
   sends no username, email or contact_no, so those three arrived NULL and the
   unguarded assignments overwrote the stored values with NULL.

   The account then could not log in at all: login looks the user up BY
   username, and the row no longer had one. The correct new password had
   nothing to match against, so the server answered "Invalid username or
   password" — which reads as a password fault and is really a wiped identity.
   The same call emptied the email, so self-service reset was gone too.

   The fix gives those three columns the same guard the others already had:
   a NULL parameter means "not supplied, leave this column alone".

   NULL and '' are deliberately different:
     * NULL           -> keep the stored value (field was not supplied)
     * '' on email    -> clear it (the profile editor genuinely removes it)
     * '' on username -> keep it (a blank username can never be valid and
                         would lock the account out exactly as before)

   The owner_master update got the same treatment, so a password change no
   longer blanks the owner's phone and email either.

   NOTE: this repairs the procedure. It does NOT restore rows already blanked —
   the old values were overwritten and there is no history table. See
   RUN-ME-password-fix.sql STEP 3/4 for putting an affected account back.
   ============================================================================ */

USE [society]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLogin]    Script Date: 27-08-2026 16:29:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_UserLogin]
@operation NVARCHAR (100)=NULL, @user_id INT=0, @user_type_id INT=0,  @Name NVARCHAR (500)=NULL, @address2 NVARCHAR (50)=NULL, @username NVARCHAR (50)=NULL,
@password NVARCHAR (200)=NULL, @address1 NVARCHAR (50)=NULL, @contact_no NVARCHAR (50)=NULL, @active_status INT=0,  @email NVARCHAR (100)=NULL,@type NVARCHAR(50)=NULL,
@join_dt SMALLDATETIME=NULL, @last_dt SMALLDATETIME=NULL, @society_id NVARCHAR (10)=NULL,@web_token NVARCHAR (MAX)=NULL,  @new  NVARCHAR (10)=null,@search nvarchar(50)=null,
                     @num AS INT=0,@village_id NVARCHAR(10)=NULL,@owner_id int=0, @v_name NVARCHAR(100) = NULL, @flat_id int = 0, @photo_path NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @operation = 'Update'
        BEGIN
            IF @user_id = 0
                BEGIN
				 DECLARE @new1 AS int =0;
                    SELECT   TOP (1) @new1 = user_id
                    FROM     dbo.UserLogin
                    ORDER BY user_id DESC;
                    IF @new1 IS NULL
                        BEGIN
                            SELECT @new1 = 0;
                        END
                    ELSE
                        BEGIN
                            SELECT @new1 = @new1 + 1;
                        END
                    INSERT  INTO dbo.UserLogin (user_id,society_id, user_type_id, Name, owner_id,email,contact_no, UserName, Password,  active_status,type,village_id)
                    VALUES                    (@new1,@society_id,@user_type_id, dbo.InitCap(@Name),@owner_id,@email,@contact_no,  @UserName, @Password,0,@type,@village_id);

                END
            ELSE
                BEGIN
                    UPDATE dbo.UserLogin
                    SET    user_type_id  = @user_type_id,
                           Name        = dbo.InitCap(@Name),
                           UserName    = @UserName,

                           Password    = case when @Password is not null or @Password !='' then @Password end,
                           email=@email,
						   contact_no=@contact_no,
                           active_status      = @active_status,
						owner_id=@owner_id,
                           type        = @type,
                           society_id  = @society_id,
						   village_id  = @village_id
                    WHERE  user_id = @user_id;

                    SELECT @user_id AS user_id;
                END
        END
    IF @operation = 'Update_Society_ID'
        BEGIN
            IF @user_id IS NOT NULL
                UPDATE dbo.UserLogin
                SET    society_id = @society_id
                WHERE  user_id = @user_id;
        END
    IF @operation = 'Select'
        BEGIN
            SELECT  dbo.UserLogin.user_id,
                    dbo.UserLogin.user_type_id,
                    dbo.UserType.UserTypeName,
                    dbo.UserLogin.name,
                    dbo.UserLogin.username,
                    dbo.UserLogin.password,
                    dbo.UserLogin.active_status,
                    dbo.UserLogin.society_id,
                    dbo.UserLogin.token,
                    dbo.society_master.name AS Society_name,
                    /* select_photo_ok */ dbo.UserLogin.photo_path,
                    dbo.UserLogin.village_id,
                    dbo.village_master.name AS village_name,
                    CASE WHEN dbo.UserLogin.[type] = 1 THEN 'Society' ELSE 'Village' END AS [type],
                    dbo.UserLogin.contact_no,
                    dbo.UserLogin.email,
                    dbo.UserLogin.owner_id
            FROM    dbo.UserLogin
                    INNER JOIN dbo.UserType
                        ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
                    LEFT OUTER JOIN dbo.society_master
                        ON dbo.UserLogin.society_id = dbo.society_master.society_id
                    LEFT OUTER JOIN dbo.village_master
                        ON dbo.UserLogin.village_id = dbo.village_master.village_id
            WHERE   dbo.UserLogin.user_id = @user_id;
        END
		IF @operation = 'new_society'
        BEGIN
                    SELECT   TOP (1) @new = society_id
                    FROM     dbo.society_master
                    ORDER BY society_id DESC;
                    IF @new IS NULL
                        BEGIN
                            SELECT @new = 'C10001';
                        END
                    ELSE
                        BEGIN
                            SELECT @num = SUBSTRING(@new, 2, 5);
                            SELECT @num = @num + 1;
                            SELECT @new = (SELECT Concat('C', @num));
                        END
             insert into society_master(society_id)values(@new)
			    SELECT   TOP (1) society_master_id
                    FROM     dbo.society_master
                    ORDER BY society_id DESC;
        END
		IF @operation = 'new_village'
        BEGIN
                    SELECT   TOP (1) @new = village_id
                    FROM     dbo.village_master
                    ORDER BY village_id DESC;
                    IF @new IS NULL
                        BEGIN
                            SELECT @new = 'V10001';
                        END
                    ELSE
                        BEGIN
                            SELECT @num = SUBSTRING(@new, 2, 5);
                            SELECT @num = @num + 1;
                            SELECT @new = (SELECT Concat('V', @num));
                        END
             insert into village_master(village_id)values(@new)
			    SELECT   TOP (1) id
                    FROM     dbo.village_master
                    ORDER BY village_id DESC;
        END
--    IF @operation = 'all_Select'
--        BEGIN
--           SELECT        dbo.UserLogin.user_id, dbo.UserType.UserTypeName, dbo.UserLogin.user_type_id, dbo.UserLogin.name, dbo.UserLogin.username, dbo.UserLogin.password, dbo.UserLogin.address1, dbo.UserLogin.address2,
--                         dbo.UserLogin.contact_no, dbo.UserLogin.email, dbo.UserLogin.active_status, dbo.UserLogin.join_dt, dbo.UserLogin.last_dt, dbo.UserLogin.society_id, dbo.UserLogin.token
--FROM            dbo.UserLogin INNER JOIN
--                         dbo.UserType ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
--            WHERE  (UserLogin.user_id = @user_id) and active_status=0;
--        END
    IF @operation = 'Delete'
        BEGIN
            Update dbo.UserLogin set active_status=1
            WHERE  user_id = @user_id;
        END
    IF @operation = 'check_delete'
        BEGIN
            SELECT *
            FROM   dbo.UserLogin
           WHERE  user_id = @user_id and active_status=0;
        END
  IF @operation = 'chk_name'
        BEGIN
            IF @user_id <> 0
                SELECT owner_id
                FROM   dbo.owner_master
                WHERE  name = @Name and pre_mob=@contact_no and  active_status=0

            ELSE
                SELECT email
                FROM   dbo.UserLogin
                WHERE  email = @email and active_status=0;
        END

    IF @operation = 'check_email'
        BEGIN
            IF @user_id <> 0
                SELECT email
                FROM   dbo.UserLogin
                WHERE  email = @email and active_status=0
                       AND user_id <> @user_id;
            ELSE
                SELECT email
                FROM   dbo.UserLogin
                WHERE  email = @email and active_status=0;
        END
    IF @operation = 'check_UserName'
        BEGIN
            IF @user_id <> 0
                SELECT *
                FROM   dbo.UserLogin
                WHERE  UserName = @UserName
                       AND user_id <> @user_id and active_status=0;
            ELSE
                SELECT *
                FROM   dbo.UserLogin
                WHERE  UserName = @UserName and active_status=0;
        END
--    IF @operation = 'Select_all'
--        BEGIN
--           SELECT        dbo.UserLogin.user_id, dbo.UserType.UserTypeName, dbo.UserLogin.user_type_id, dbo.UserLogin.name, dbo.UserLogin.username, dbo.UserLogin.password, dbo.UserLogin.address1, dbo.UserLogin.address2,
--                         dbo.UserLogin.contact_no, dbo.UserLogin.email, dbo.UserLogin.active_status, dbo.UserLogin.join_dt, dbo.UserLogin.last_dt, dbo.UserLogin.society_id, dbo.UserLogin.token
--FROM            dbo.UserLogin INNER JOIN
--                         dbo.UserType ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
--          WHERE  user_id = @user_id and active_status=0;
--        END

		 If @operation='Grid_Show'
	   Begin
	   SELECT        dbo.UserLogin.user_id, dbo.UserLogin.user_type_id, dbo.UserType.UserTypeName, dbo.UserLogin.name, dbo.UserLogin.username, dbo.UserLogin.password,
                         dbo.UserLogin.active_status,dbo.UserLogin.society_id, dbo.UserLogin.token,dbo.society_master.name AS Society_name,userlogin.contact_no,userlogin.email
FROM            dbo.UserLogin INNER JOIN

                         dbo.UserType ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
						 INNER JOIN
                         dbo.society_master ON dbo.UserLogin.society_id = dbo.society_master.society_id where userlogin.society_id=@society_id and Userlogin.active_status=0
	   End
	   		 If @operation='Search'
	   Begin
	   SELECT        dbo.UserLogin.user_id, dbo.UserLogin.user_type_id, dbo.UserType.UserTypeName, dbo.UserLogin.name, dbo.UserLogin.username, dbo.UserLogin.password,
                         dbo.UserLogin.active_status,dbo.UserLogin.society_id, dbo.UserLogin.token,dbo.society_master.name AS Society_name
FROM            dbo.UserLogin INNER JOIN

                         dbo.UserType ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
						 INNER JOIN
                         dbo.society_master ON dbo.UserLogin.society_id = dbo.society_master.society_id where userlogin.society_id=@society_id and Userlogin.active_status=0 and ( dbo.UserLogin.name like @search+'%' or dbo.UserType.UserTypeName like @search+'%')
	   End
	   IF @operation = 'Insert_Token'
        BEGIN
           Update UserLogin set web_token = @web_token where user_id=@user_id
        END

		IF @operation = 'UpdateProfile'
        BEGIN
           -- Every column here treats a NULL parameter as "not supplied, leave
           -- it alone". That has to hold for ALL of them, not just some:
           -- change-password calls this branch to write only the password, so
           -- any column without the guard is overwritten with NULL. username,
           -- email and contact_no previously lacked it, which wiped the
           -- account's identity — the correct password then had no username to
           -- match against, and the account could neither log in nor self-reset.
           --
           -- '' is not the same as NULL: it means "clear this", which is what
           -- the profile editor sends to remove an email or a photo. username
           -- preserves on '' too, since a blank username can never be valid.
           Update UserLogin set
               contact_no = case when @contact_no is null then contact_no else @contact_no end,
               email      = case when @email is null then email else @email end,
               password   = case when @Password is  null or @Password ='' then password else @Password end,
               username   = case when @username is null or @username = '' then username else @username end,
               /* updateprofile_name_ok */
               Name       = case when @Name is null or @Name = '' then Name else dbo.InitCap(@Name) end,
               /* photo_path_ok */
               photo_path = case when @photo_path is null then photo_path when @photo_path = '' then null else @photo_path end
           where user_id=@user_id

           -- Same guard: a password change sends no contact_no or email, and
           -- must not blank the owner's record either.
		  update owner_master set
               pre_mob = case when @contact_no is null then pre_mob else @contact_no end,
               email   = case when @email is null then email else @email end
           where owner_id=@owner_id
        END
		IF @operation = 'ResetPass'
        BEGIN
           Update UserLogin set password= case when @Password is  null or @Password ='' then password else @Password end where email=@email

        END
		IF @operation = 'GetProfile'
        BEGIN
             SELECT        dbo.UserLogin.user_id, dbo.UserLogin.user_type_id, dbo.UserType.UserTypeName, dbo.UserLogin.name, dbo.UserLogin.username, dbo.UserLogin.password,
                         dbo.UserLogin.active_status,dbo.UserLogin.society_id, dbo.UserLogin.token,dbo.society_master.name AS Society_name,userlogin.contact_no,userlogin.email,UserLogin.owner_id, /* photo_path_ok */ UserLogin.photo_path, /* getprofile_village_ok */ dbo.UserLogin.village_id, dbo.village_master.name AS Village_name
FROM            dbo.UserLogin INNER JOIN

                         dbo.UserType ON dbo.UserLogin.user_type_id = dbo.UserType.UserTypeId
						 LEFT JOIN
                         dbo.society_master ON dbo.UserLogin.society_id = dbo.society_master.society_id LEFT JOIN dbo.village_master ON dbo.UserLogin.village_id = dbo.village_master.village_id
           WHERE  user_id = @user_id;
        END


			if @operation = 'fill_owner'
		begin
		SELECT * FROM owner_master WHERE  login_status=0 and active_status=0 and type = 'owner' AND society_id=@society_id
		end

		if @operation = 'fill_type'
		begin
		Select *  from UserType where type=1
		end


		    IF @operation = 'GetCommitteeDirectory'
    BEGIN
        SELECT
            name,
            contact_no AS contact,
            email,
            society_id
        FROM userlogin
        WHERE active_status = 0
          AND society_id = @society_id;
    END

	 --IF @operation = 'GetTokensByUnit'
  --  BEGIN
  --      SELECT *
  --      FROM userdata
  --      WHERE active_status = 0
  --        AND unit IN (
  --            SELECT unit
  --            FROM helperWorkDetails
  --            WHERE p_name = @v_name
  --              AND society_id = @society_id
  --        );
  --  END

     IF @operation = 'GetTokensByFlat'
    BEGIN
        SELECT token
        FROM userdata
        WHERE active_status = 0
          AND flat_id = @flat_id and token is not null

    END


	if @operation ='getPassword'
		BEGIN
			select password from UserLogin where user_id = @user_id
		END

	if @operation = 'ResetForgotPassword'
		BEGIN
			UPDATE UserLogin set password = @password where email = @email
		END


END
GO
