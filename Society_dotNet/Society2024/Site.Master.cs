using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using FirebaseAdmin.Messaging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class SiteMaster : MasterPage
    {
        Society_Member member = new Society_Member();
        BL_User_Login BL_Login = new BL_User_Login();
        BL_Society_Member_Master bL_Society = new BL_Society_Member_Master();
        Login_Details details = new Login_Details();

        public object ClientScript { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
            Response.Cache.SetNoStore();

            if (!IsPostBack)
            {

                if (Session["Name"] != null)
                {

                    //ownerH.Value = Session["userID"].ToString();
                    string str1 = Session["user_type"].ToString();
                    society.Visible = Session["user_type"].ToString() == "Society";
                    village.Visible = Session["user_type"].ToString() == "Village";
                    Panel1.Visible = true;
                    txt_welcome.Text = "Hello,\n" + Session["Name"].ToString();
                    name_society.Text = Session["society_name"].ToString();
                    get_notificatoin();

                    userID.Value = Session["userID"].ToString();
                    string ownerId = Session["userID"].ToString();  // This comes from the hidden field
                    string imagePath = $"~/img/ProfilePic/owner_{ownerId}.png";
                    string serverPath = Server.MapPath(imagePath);

                    if (File.Exists(serverPath))
                    {
                        profileImage.Src = ResolveUrl(imagePath); // Set user-specific image
                        profileImage2.Src = ResolveUrl(imagePath); // Set user-specific image
                    }
                    else
                    {
                        profileImage.Src = ResolveUrl("~/img/undraw_profile.svg"); // Set default image
                        profileImage2.Src = ResolveUrl("~/img/undraw_profile.svg"); // Set default image
                    }
                }
                else
                    Panel1.Visible = false;


            }



        }


        private void HighlightActiveMenu()
        {
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);

            //// Loop through all controls inside accordionSidebar
            //foreach (var control in accordionSidebar.Controls)
            //{
            //    HighlightIfMatch(control, currentPage);
            //}
        }

        private void HighlightIfMatch(object control, string currentPage)
        {
            if (control is HtmlAnchor link)
            {
                // Match by comparing href with current page
                if (!string.IsNullOrEmpty(link.HRef) &&
                    link.HRef.EndsWith(currentPage, StringComparison.OrdinalIgnoreCase))
                {
                    // Add "active" class
                    link.Attributes["class"] = (link.Attributes["class"] ?? "") + " active";
                }
            }

            // Recursively check nested controls (for dropdowns)
            if (control is System.Web.UI.Control c && c.HasControls())
            {
                foreach (var child in c.Controls)
                {
                    HighlightIfMatch(child, currentPage);
                }
            }
        }

        protected void TimerNotif_Tick(object sender, EventArgs e)
        {

            if (Session["society_id"] != null)
                get_notificatoin();
            upNotifList.Update();
        }
        protected void TimerNotif_Tick2(object sender, EventArgs e)
        {

            //if (Session["society_id"] != null)
                //get_notificatoin();
            //upNotifList.Update();
        }


        protected void get_notificatoin()
        {
            //Session["UserId"] = result.UserLoginId;
            details.Sql_Operation = "Notification";
            details.Society_Id = Session["society_id"].ToString();

            details.UserLoginId = int.Parse(Session["UserId"].ToString());

            var dt = BL_Login.get_notification(details);



            notifCount.Text = (dt.Rows.Count > 99) ? "99+" : dt.Rows.Count.ToString();
            badgePanel.Visible = dt.Rows.Count != 0;
            noNotif.Visible = dt.Rows.Count == 0;
            Notification_grid.DataSource = dt;
            Notification_grid.DataBind();


            details.Sql_Operation = "get_messages_count";
            details.Society_Id = Session["society_id"].ToString();
            int count = BL_Login.get_messages_count(details);

            if (count == 0)
            {
                pnlMessageCount.Visible = false;
            }
            else
            {
                lblMessageCount.Text = count.ToString();

            }


        }

        protected void Update_Notify_Status(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Redirect")
            {
                int id = Convert.ToInt32(e.CommandArgument);
                details.NoticeId = id;

                details.Society_Id = Session["society_id"].ToString();

                details.Sql_Operation = "UpdateStatus";

                BL_Login.UpdateNotifyStatus(details);

                get_notificatoin();

                Response.Redirect("support_ticket.aspx");
            }
        }

        protected void fill_data()
        {
            member.UserId = Convert.ToInt32(Session["UserId"]);
            member.Sql_Operation = "GetProfile";

            var result = bL_Society.UpdateProfile(member);
            user_Name.Text = result.Name.ToString();
            owner_id.Value = result.Owner_id.ToString();
            userNameIn.Text = result.UserName.ToString();
            designation.Text = result.role.ToString();
            Session["pass"] = result.Password.ToString();

            string fullName = result.Name.ToString();
            string[] parts = fullName.Split(' ');

            fName.Text = parts[0];
            lName.Text = parts[parts.Length - 1];

            contact.Text = result.Contact_No.ToString();
            email.Text = result.Email.ToString();

        }

        protected void logout_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
            Response.Cache.SetNoStore();
            Response.Redirect("login1.aspx", true);

        }

        protected void lnkDetails2_Click(object sender, EventArgs e)
        {
            get_notificatoin();
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            member.UserId = Convert.ToInt32(Session["UserId"]);
            member.Sql_Operation = "UpdateProfile";
            member.Society_Id = Session["society_id"].ToString();
            member.Name = fName.Text + " " + lName.Text;
            member.UserName = userNameIn.Text;
            if (passwordField.Text != "")
            {
                var oldPassword = bL_Society.getPass(Convert.ToInt32(Session["userId"]), "getPassword");
                if(!VerifyPassword(TextBox1.Text, oldPassword.Password))
                {
                    wrongPass.Text = "Wrong Password";
                    return;
                }
                else
                {
                    wrongPass.Text = "";
                }
                string hashedPassword = HashPassword(passwordField.Text);
                member.Password = hashedPassword;
            }
            else
                member.Password = "";
            member.Contact_No = contact.Text;
            member.Email = email.Text;
            member.Status = 0;
            member.Owner_id = Convert.ToInt32(owner_id.Value);
            bL_Society.UpdateProfile(member);

            // Call JS function successentry()


            ScriptManager.RegisterStartupScript(upnlCountry, upnlCountry.GetType(), "successEntry", "SuccessEntry();", true);


        }

        protected void Unnamed_ServerClick(object sender, EventArgs e)
        {
            fill_data();
            ScriptManager.RegisterStartupScript(
    upOpenButton, // The UpdatePanel that contains the button
    upOpenButton.GetType(),
    "ShowProfileModal",
    "openModalProfile();",
    true
);

        }

        protected void userNameIn_TextChanged(object sender, EventArgs e)
        {
            // 🔍 Check username
            var usernameResult = BL_Login.CheckDuplicateUsername(member);
            if (usernameResult.Sql_Result == "Exist")
            {
                //Label8.Text = "This Username is already taken.";
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "openModal();", true);
                return;
            }
        }

        private static string HashPassword(string password)
        {
            byte[] salt;
            new RNGCryptoServiceProvider().GetBytes(salt = new byte[16]);

            var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000);
            byte[] hash = pbkdf2.GetBytes(20);

            byte[] hashBytes = new byte[36];
            Array.Copy(salt, 0, hashBytes, 0, 16);
            Array.Copy(hash, 0, hashBytes, 16, 20);

            return Convert.ToBase64String(hashBytes);
        }


        private static bool VerifyPassword(string enteredPassword, string storedHash)
        {
            try
            {
                byte[] hashBytes = Convert.FromBase64String(storedHash);

                // Extract salt
                byte[] salt = new byte[16];
                Array.Copy(hashBytes, 0, salt, 0, 16);

                // Generate hash with entered password
                var pbkdf2 = new Rfc2898DeriveBytes(enteredPassword, salt, 10000);
                byte[] hash = pbkdf2.GetBytes(20);

                // Compare hash
                for (int i = 0; i < 20; i++)
                {
                    if (hashBytes[i + 16] != hash[i])
                        return false;
                }

                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}