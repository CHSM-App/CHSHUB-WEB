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
    public partial class staff_role : System.Web.UI.Page
    {
        staff getstaff = new staff();
        BL_Staff bL_Staff = new BL_Staff();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Role_GridBind();

            }

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            var str = runproc_save("Role_Update");
            if (str == "Done")
             

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            else
            {
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

            }

        }

        public void Role_GridBind()
        {
            DataTable dt = new DataTable();
            getstaff.Sql_Operation = "Role_Show";
            getstaff.Society_Id = society_id.Value;
            dt = bL_Staff.getrole(getstaff);
            ViewState["dirState"] = dt;
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }
        public string runproc_save (string operation)
        {
            if (role_id.Value != "")
                getstaff.role_id = Convert.ToInt32(role_id.Value);
            getstaff.Sql_Operation = operation;
            getstaff.Society_Id = society_id.Value;
            getstaff.role = txt_role.Text;
            var result = bL_Staff.role_update(getstaff);

            return result.Sql_Result;
        }

        public void runproc(string operation)
        {
            if (role_id.Value != "")
                getstaff.role_id = Convert.ToInt32(role_id.Value);
            getstaff.Sql_Operation = operation;
            var result = bL_Staff.role_update(getstaff);
            txt_role.Text = result.role.ToString();
        }
        protected void btn_delete_Click(object sender, EventArgs e)
        {

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("staff_role.aspx");
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            getstaff.Name = txt_search.Text.Trim();
            getstaff.Sql_Operation = "search_role";
            getstaff.Society_Id = society_id.Value;
            var result = bL_Staff.search_staff(getstaff);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

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

        protected void edit1_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            role_id.Value = id;
            runproc("Role_Select");
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
 
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label role_id = (System.Web.UI.WebControls.Label)row.FindControl("role_id");
            getstaff.Sql_Operation = "Role_Delete";

            getstaff.role_id = Convert.ToInt32(role_id.Text);
           bL_Staff.role_delete(getstaff);
           Role_GridBind();

        }

        protected void txt_role_TextChanged(object sender, EventArgs e)
        {
            if (txt_role.Text.Trim() != "")
            {
                if (role_id.Value != "")
                    getstaff.role_id = Convert.ToInt32(role_id.Value);
                getstaff.Sql_Operation = "check_role";
                getstaff.role = txt_role.Text;
                getstaff.Society_Id = society_id.Value;
                var result = bL_Staff.RoleTextChanged(getstaff);
                Label4.Text = result.Sql_Result;
            }
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Role_GridBind();
        }
    }
}