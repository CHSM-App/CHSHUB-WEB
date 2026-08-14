using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Configuration;
using System.Web.Configuration;
using System.Web.Services.Description;
using DBCode.DataClass;
using BusinessLogic.BL;

namespace Society
{
    public partial class meeting_details : System.Web.UI.Page
    {

        Meeting meeting = new Meeting();
        BL_Meeting_Details bL_Meeting_ = new BL_Meeting_Details();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                

            }

        }
       

        protected void btn_search_Click(object sender, EventArgs e)
        {

            search_meeting();
        }

        private void search_meeting()
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("Select * from meeting_master where active_status=0 and society_id='" + society_id.Value + "'and  meeting_date='" + txt_date.Text + "'");


            meeting.Sql_Operation = sb.ToString();
            var result = bL_Meeting_.search_meeting_details(meeting);
            GridView1.DataSource = result;
            GridView1.DataBind();
        }
        

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            Label meet_id = (Label)row.FindControl("meet_id");
            meeting.Sql_Operation = "Delete";

            meeting.meet_id = Convert.ToInt32(meet_id.Text);
            var result = bL_Meeting_.Delete_Meet(meeting);
            search_meeting();
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            btn_search_Click(sender, e);
        }
    }
}