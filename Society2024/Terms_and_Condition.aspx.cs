using BusinessLogic.BL;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;
using Utility.DataClass;

namespace Society2024
{
    public partial class Terms_and_Condition : System.Web.UI.Page
    {
        terms_condition Terms = new terms_condition();
        BL_Terms bL_Terms = new BL_Terms();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();


            if (!IsPostBack)
            {
                terms_Gridbind();
            }
        }

        public void save_ckdata(string terms)
        {

        }

        public void terms_Gridbind()
        {
            DataTable dt = new DataTable();
            Terms.Sql_Operation = "Grid_Show";
            Terms.Society_Id = society_id.Value;
            dt = bL_Terms.getTermsDetails(Terms);
            if (dt.Rows.Count != 0)
                add_new.Visible = false;
            else
                add_new.Visible = true;
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            // string terms = Request.Form["editor2"].ToString();
            if (term_id.Value != "")
                Terms.term_id = Convert.ToInt32(term_id.Value);
            Terms.Sql_Operation = "Update";
            Terms.Society_Id = society_id.Value;
            Terms.Terms = editor1.Text;
            bL_Terms.getupdate_details(Terms);

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        public void runproc(string operation)
        {
            if (term_id.Value != "")
                Terms.term_id = Convert.ToInt32(term_id.Value);
            Terms.Sql_Operation = operation;
            var result = bL_Terms.getupdate_details(Terms);
            editor1.Text = result.Terms.ToString();




        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("Terms_and_Condition.aspx");
        }
        protected void btnDelete_Click(object sender, EventArgs e)
        {
            if (term_id.Value != "")
                Terms.term_id = Convert.ToInt32(term_id.Value);
            Terms.Sql_Operation = "Delete";
            bL_Terms.delete(Terms);

            Response.Redirect("Terms_and_Condition.aspx");
        }



        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            term_id.Value = id;
            runproc("Select");
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label term_id = (System.Web.UI.WebControls.Label)row.FindControl("t_id");
            Terms.Sql_Operation = "Delete";

            Terms.term_id = Convert.ToInt32(term_id.Text);
            bL_Terms.delete(Terms);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);

            terms_Gridbind();
        }

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

      

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            terms_Gridbind();
        }
    }
}