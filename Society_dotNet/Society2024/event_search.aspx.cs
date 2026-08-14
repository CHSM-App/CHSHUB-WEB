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
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.Windows.Forms;
using Society2024;

namespace Society
{

    public partial class event_search : System.Web.UI.Page
    {
        Event evt = new Event();
        BL_Event_Master bL_Event = new BL_Event_Master();


        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                Event_Gridbind();
                
            }

        }

        public void Event_Gridbind()
        {
            DataTable dt = new DataTable();
            evt.Sql_Operation = "Grid_Show";
            evt.Society_Id = society_id.Value;
            dt = bL_Event.getEventDetails(evt);
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
            evt.Event_Name = txt_search.Text.Trim();
            evt.Sql_Operation = "search";
            evt.Society_Id = society_id.Value;
           var result = bL_Event.search_event(evt);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }


        public async void runproc_save(string operation)
        {
            
            if (event_id.Value != "")
                evt.Event_Id = Convert.ToInt32(event_id.Value.ToString());
            evt.Sql_Operation = operation;
            evt.Society_Id = society_id.Value;
            evt.Event_Name = txt_sub.Text;
            evt.From_Date = Convert.ToDateTime(txt_from_date.Text.ToString());
            evt.To_Date = Convert.ToDateTime(txt_to_date.Text.ToString());
            evt.Description = txt_desc.Text;
           var result = bL_Event.updateEventDetails(evt);
            foreach (DataRow row in result.Rows)   
            {
                evt.User_Id = Convert.ToInt32(row["user_id"].ToString());
                evt.UserType = row["type"].ToString();
                evt.Notification_Id = evt.Event_Id;
                evt.Notification_Type = "Event";
                evt.Body = txt_sub.Text;
                bL_Event.send_notification(evt);
                generate_notification(row["token"].ToString());

            }

        }

        protected async void generate_notification(string token)
        {
            var Fcm = new FirebaseCloudMessaging();
            string result1 = await Fcm.SendNotificationAsync(token, "New Event", txt_sub.Text);
        }

        public void runproc(string operation)
        {
            if (event_id.Value != "")
                evt.Event_Id = Convert.ToInt32(event_id.Value);
            evt.Sql_Operation = operation;
            var result = bL_Event.getevent(evt);

            event_id.Value = result.Event_Id.ToString();
            society_id.Value = result.Society_Id;
            txt_sub.Text = result.Event_Name;
            txt_from_date.Text = result.From_Date.ToString("yyyy-MM-dd");
            txt_to_date.Text = result.To_Date.ToString("yyyy-MM-dd");
            txt_desc.Text = result.Description;

        }
        protected async  void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);


        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (event_id.Value != "")
                    evt.Event_Id = Convert.ToInt32(event_id.Value);
                evt.Sql_Operation = "Delete";
                bL_Event.delete(evt);
            
            Response.Redirect("event_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("event_search.aspx");

        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            event_id.Value = id;
            runproc("Select");
            
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
   
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label event_id = (System.Web.UI.WebControls.Label)row.FindControl("event_id");
                evt.Sql_Operation = "Delete";

                evt.Event_Id = Convert.ToInt32(event_id.Text);
                bL_Event.delete(evt);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            
            Event_Gridbind();

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }



        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Event_Gridbind();
        }
    }
}


