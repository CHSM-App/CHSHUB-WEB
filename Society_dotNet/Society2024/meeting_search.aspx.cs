using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Web.Configuration;
using DBCode.DataClass;
using BusinessLogic.MasterBL;
using System.Windows.Forms;
using Society2024;

namespace Society
{
    public partial class meeting_search : System.Web.UI.Page
    {
        private Meeting meeting = new Meeting();
        private BL_Meeting_Master bL_Meeting = new BL_Meeting_Master();
       

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {


                Meeting_Gridbind();
               
               //runproc("Select");

                txt_date.Text = DateTime.Now.ToString("yyyy-MM-dd");
               // txt_time.Text = DateTime.Now.ToString("hh:mm tt");

            }

        }
        protected void Meeting_Gridbind()
        {
            DataTable dt = new DataTable();
            meeting.Sql_Operation = "Grid_Show";
            meeting.Society_Id = society_id.Value;
            dt = bL_Meeting.getMeetingDetails(meeting);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
        }


        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["dirState"];
            if (dtrslt.Rows.Count > 0)
            {
                if (Convert.ToString(ViewState["sortdr"]) == "Asc")
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Desc";
                    ViewState["sortdr"] = "Desc";
                }
                else
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Asc";
                    ViewState["sortdr"] = "Asc";
                }
                GridView1.DataSource = dtrslt;
                GridView1.DataBind();


            }

        }


      
        protected void btn_search_Click(object sender, EventArgs e)
        {

            meeting.Title = txt_search.Text.Trim();
            meeting.Sql_Operation ="search";
            meeting.Society_Id = society_id.Value;
            var result = bL_Meeting.search_meeting(meeting);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        public void runproc_save(String operation)
        {

            if (meet_id.Value != "")
                meeting.meet_id = Convert.ToInt32(meet_id.Value);
            meeting.Sql_Operation = operation;
            meeting.Society_Id = society_id.Value;
            meeting.Meeting_Date = Convert.ToDateTime(txt_date.Text);
            meeting.Meeting_Time = Convert.ToDateTime(txt_time.Text);
            meeting.Subject = txt_sub.Text;
            meeting.Details = editor1.Text;
            var result = bL_Meeting.updatemeetingdetails(meeting);
            
            foreach (DataRow row in result.Rows)
            {
                meeting.User_Id = Convert.ToInt32(row["user_id"].ToString());
                meeting.User_Type = row["type"].ToString();
                meeting.Notification_Id = meeting.meet_id;
                meeting.Notification_Type = "Meeting";
                meeting.Body = txt_sub.Text;
                bL_Meeting.send_notification(meeting);
                generate_notification(row["token"].ToString());
            }
        }

        protected async void generate_notification(string token)
        {
            var Fcm = new FirebaseCloudMessaging();
            string result1 = await Fcm.SendNotificationAsync(token, "New Meeting", txt_sub.Text);
        }
        public void runproc(string operation)
        {
            if (meet_id.Value!= "")
                meeting.meet_id = Convert.ToInt32(meet_id.Value);
            meeting.Sql_Operation = operation;

            var result1 = bL_Meeting.getMeeting(meeting);

            meet_id.Value = result1.meet_id.ToString();
            society_id.Value = result1.Society_Id;
            txt_date.Text = result1.Meeting_Date.ToString("yyyy-MM-dd");
            txt_time.TextMode = TextBoxMode.SingleLine;
            txt_time.Text = result1.Meeting_Time.ToString("hh:mm tt");
            txt_sub.Text = result1.Subject;
            editor1.Text = result1.Details;
        }



        protected void btn_save_Click(object sender, EventArgs e)
        {
            if (Label10.Text == "")
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (meet_id.Value != "")
                    meeting.meet_id = Convert.ToInt32(meet_id.Value);
                meeting.Sql_Operation = "Delete";
                bL_Meeting.delete(meeting);
           
            Response.Redirect("meeting_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("meeting_search.aspx");
        }

        protected void btn_mom_Click(object sender, EventArgs e)
        {

            //runproc("Update");
            //MoM_Gridbind();
            //Response.Redirect("meeting_search.aspx");


            if (Label10.Text == "")
            {
                runproc_save("Update");
                //MoM_Gridbind();
                Response.Redirect("meeting_search.aspx");
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }

        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            meet_id.Value = id;
            //Meeting_Gridbind();
            runproc("Select");
            //upnlCountry.Update();
            btn_delete.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label meet_id = (System.Web.UI.WebControls.Label)row.FindControl("meet_id");
                meeting.Sql_Operation = "Delete";

                meeting.meet_id = Convert.ToInt32(meet_id.Text);
                bL_Meeting.delete(meeting);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
           
            Meeting_Gridbind();

        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

       
        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Meeting_Gridbind();

        }


    }
}
    
