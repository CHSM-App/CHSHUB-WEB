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
//using System.Windows.Controls;
//using Azure;
using System.Drawing.Drawing2D;
using Page = System.Web.UI.Page;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System.Windows.Forms;
using DBCode.DataClass;
using BusinessLogic.BL;
using System.Reflection.Emit;
//using System.IdentityModel.Metadata;

namespace Society
{
    public partial class society_charges : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        private BL_Society_Master bL_society = new BL_Society_Master();
        private Search_Society society = new Search_Society();
        

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
          
            if (!IsPostBack)
            {
                society.Sql_Operation = "fill_society";
               
                var dt = bL_society.getcharge(society);

                categoryRepeater.DataSource = dt;
                categoryRepeater.DataBind();
                Society_charges_GridBind();
                
               
            }

        }
         
        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            { 
                society_name_id.Value = e.CommandArgument.ToString();
                society.Sql_Operation = "TotalFlats";
                society.Society_Id = society_name_id.Value;
                txt_flat.Text = bL_society.getFlats(society).ToString();
                society.Society_Id = society_name_id.Value;
                society.Sql_Operation = "society_exist";

                var result = bL_society.check_society(society);
                Label2.Text = result.Sql_Result;
            }
        }
        
        public void Society_charges_GridBind()
        {
          
            DataTable dt = new DataTable();
            society.Sql_Operation = "Grid_Show";
           
            dt = bL_society.getcharge(society);
            ViewState["dirState"] = dt;
            GridView1.DataSource = dt;
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
            society.Sql_Operation = "search";
            society.Name = txt_search.Text;
            society.Society_Id = society_id.Value;
            var result = bL_society.search_society_charges(society);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }

        public void runproc_save(string operation)
        {
            if (charge_id.Value != "")
                society.Charge_Id = Convert.ToInt32(charge_id.Value);
            society.Sql_Operation = operation;
            society.Amount = txt_amount.Text;
            society.Society_Id = society_name_id.Value;
            society.total_unit = Convert.ToInt32(txt_flat.Text);
            bL_society.updatecharges(society);

        }



        public void runproc(string operation)
        {
            if (charge_id.Value != "")
                society.Charge_Id = Convert.ToInt32(charge_id.Value);
            society.Sql_Operation = operation;
            var result = bL_society.updatecharges(society);
            charge_id.Value = result.Charge_Id.ToString();
            txt_amount.Text = result.Amount.ToString();
            society_name_id.Value = result.Society_Id.ToString();

            String str = "Select *  from society_master";
            repeater.fill_list(categoryRepeater, str);

        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (charge_id.Value != "")
                society.Charge_Id = Convert.ToInt32(charge_id.Value);
            society.Sql_Operation = "Delete";
            bL_society.detete_charge(society);

            Response.Redirect("society_charges.aspx");
        }


        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label charge_id = (System.Web.UI.WebControls.Label)row.FindControl("charge_id");
            society.Sql_Operation = "Delete";

            society.Charge_Id = Convert.ToInt32(charge_id.Text);

            bL_society.detete_charge(society);

            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            Society_charges_GridBind();
        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            charge_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);

            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);


        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            if (Label2.Text == "")
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
            else
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_charges.aspx");
        }

        protected void ddl_society_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (charge_id.Value != "")
                society.Charge_Id = Convert.ToInt32(charge_id.Value);
            society.Society_Id = society_name_id.Value;
            society.Sql_Operation = "society_exist";
            
            var result=bL_society.check_society(society);
            Label2.Text =result.Sql_Result;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Society_charges_GridBind();
        }

        protected void categoryRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (society_name_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == society_name_id.Value)
                        categoryBox.Text = link.Text;
                }
            }
        }
    }
}




