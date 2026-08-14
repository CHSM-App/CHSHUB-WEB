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
using Utility.DataClass;
using BusinessLogic.BL;
using BusinessLogic.MasterBL;

namespace Society
{
    public partial class _thought : Page
    {
        Request request = new Request();
        BL_Suggestion_Request_Master BL_Suggestion = new BL_Suggestion_Request_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Suggestion_Gridbind();
                
            }
        }

        public void Suggestion_Gridbind()
        {
            DataTable ds = new DataTable();
            request.Sql_Operation = "Grid_Show";
            if (sug_id.Value != "")
                request.sug_id = Convert.ToInt32(sug_id.Value);
            request.Society_Id = society_id.Value;
            ds = BL_Suggestion.getsuggestion(request);
            GridView1.DataSource = ds;
            ViewState["dirState"] = ds;
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


        protected void btn_new_Click(object sender, EventArgs e)
        {
            Response.Redirect("suggestion_request_master.aspx");
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

            request.Search = txt_search.Text.Trim();
            request.Sql_Operation = "search";
            request.Society_Id = society_id.Value;
            var result = BL_Suggestion.search_suggestion(request);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }
    
        public void runproc(String operation)
        {

            if (sug_id.Value != "")
                request.sug_id = Convert.ToInt32(sug_id.Value);
            request.Sql_Operation = operation;
            request.Society_Id = society_id.Value;
            request.Details = txt_details.Text;
            request.Subject = txt_sub.Text;
            BL_Suggestion.updateSuggestionRequestDetails(request);


        }

        public void runproc_suggestion_request(String operation)
        {
            if (sug_id.Value != "")
                request.sug_id = Convert.ToInt32(sug_id.Value);
              //request.Society_Id = society_id.Value;
            request.Sql_Operation = operation;

            var result = BL_Suggestion.updateSuggestionRequestDetails(request);

            txt_details.Text = result.Details.ToString();
            txt_sub.Text = result.Subject.ToString();
        }



        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc("Update");
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            if (sug_id.Value != "")
              request.sug_id = Convert.ToInt32(sug_id.Value);
            request.Sql_Operation = "Delete";
            BL_Suggestion.delete_suggestion(request);
            Response.Redirect("suggestion_request.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("suggestion_request.aspx");
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            sug_id.Value = id;
            runproc_suggestion_request("Select");
            btn_delete.Visible = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }
        
        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            Label sug_id = (Label)row.FindControl("sug_id");
            request.Sql_Operation = "Delete";
            request.sug_id = Convert.ToInt32(sug_id.Text);
             var result = BL_Suggestion.delete_suggestion(request);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
           
            Suggestion_Gridbind();
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
            Suggestion_Gridbind();
        }
    }
}



    