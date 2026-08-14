using BusinessLogic.MasterBL;
using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class village_master : System.Web.UI.Page
    {
        private Village village = new Village();
        private BL_Village_Master bL_Village = new BL_Village_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] != null)
            {
                village_id.Value = Session["village_id"].ToString();

            }
            else
                Response.Redirect("login1.aspx");

            if (!IsPostBack)
            {
                fill_drop1();
                Village_Gridbind();
            }
        }
        public void fill_drop1()
        {
            String sql_query = "Select *  from state";
            bL_Village.fill_drop(ddl_state, sql_query, "state", "state_id");
            String sql_query1 = "Select *  from district";
            bL_Village.fill_drop(ddl_district, sql_query1, "district", "district_id");
            String sql_query2 = "Select *  from division";
            bL_Village.fill_drop(ddl_division, sql_query2, "division", "division_id");
        }

        public void Village_Gridbind()
        {
            DataTable dt = new DataTable();
            village.Sql_Operation = "Grid_Show";
            village.Village_Id = village_id.Value;
            dt = bL_Village.get_village_details(village);

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
        public void runproc_save(String operation)
        {
            if (village_id.Value != "")
                village.Village_Id = village_id.Value;
            village.Sql_Operation = operation;
            village.Name = txt_name.Text;
            village.Contact_No = txt_contact_no.Text;
            village.Email = txt_email.Text;
            village.PinCode = Convert.ToInt32(txt_pincode.Text);
            village.Division = ddl_division.SelectedValue;
            village.District_Id = Convert.ToInt32(ddl_district.SelectedValue);
            village.State_Id = Convert.ToInt32(ddl_state.SelectedValue);
            bL_Village.updateVillage(village);

        }

        public void runproc(String operation, string id)
        {

            village.Village_Id = id;
            village.Sql_Operation = operation;
            var result = bL_Village.updateVillage(village);

            village_id.Value = result.Village_Id.ToString();
            txt_name.Text = result.Name;
            txt_contact_no.Text = result.Contact_No.ToString();
            txt_email.Text = result.Email.ToString();
            txt_pincode.Text = result.PinCode.ToString();
            ddl_division.SelectedValue = result.Division.ToString();
            ddl_district.SelectedValue = result.District_Id.ToString();
            ddl_state.SelectedValue = result.State_Id.ToString();

        }
        protected void btn_search_Click(object sender, EventArgs e)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("SELECT dbo.village_master.email, dbo.village_master.contact_no, dbo.division.division, dbo.division.district_id, dbo.village_master.id, dbo.village_master.name FROM dbo.village_master INNER JOIN dbo.division ON dbo.village_master.district_id = dbo.division.district_id where active_status=0 and village_id='" + village_id.Value + "'");

            if (txt_search.Text != "")
            {
                //sb.Append(" and " + search_field.SelectedValue + " like '" + txt_search.Text + "%'");
            }
            village.Sql_Operation = sb.ToString();
            var result = bL_Village.search_village(village);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
        }

        protected void btn_import_Click(object sender, EventArgs e)
        {

        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("village_master.aspx");
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();

            runproc("Select", id);
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
        }

        protected void ddl_state_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        protected void ddl_district_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Village_Gridbind();
        }
    }
}