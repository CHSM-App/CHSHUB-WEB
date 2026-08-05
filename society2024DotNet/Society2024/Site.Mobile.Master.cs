using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using DocumentFormat.OpenXml.Wordprocessing;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class Site_Mobile : System.Web.UI.MasterPage
    {
        Society_Member member = new Society_Member();
        BL_Society_Member_Master bL_Society = new BL_Society_Member_Master();
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();
        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetExpires(DateTime.UtcNow.AddHours(-1));
            Response.Cache.SetNoStore();

            if (!IsPostBack)
            {
                if (Session["Name"] != null)
                {
                    string str1 = Session["user_type"].ToString();
                    society.Visible = Session["user_type"].ToString() == "Society";
                    village.Visible = Session["user_type"].ToString() == "Village";
                    Panel1.Visible = true;
                    txt_welcome.Text = "Hello,\n" + Session["Name"].ToString();
                    name_society.Text = Session["society_name"].ToString();
                    get_notificatoin();
                }
                else
                    Panel1.Visible = false;
            }
        }

        protected void TimerNotif_Tick(object sender, EventArgs e)
        {
            // Only update notifCount label
            //details.Sql_Operation = "Notification";
            //details.Society_Id = Session["society_id"].ToString();
            //details.UserLoginId = int.Parse(Session["UserId"].ToString());
            //var dt = BL_Login.get_notification(details);
            //notifCount.Text = (dt.Rows.Count > 99) ? "99+" : dt.Rows.Count.ToString();
            if (Session["society_id"] != null)
                get_notificatoin();
            upNotifList.Update();
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
            member.Password = passwordField.Text == "" ? Session["pass"].ToString() : passwordField.Text;
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
        }
    }
}