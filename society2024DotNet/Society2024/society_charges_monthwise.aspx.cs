using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Bibliography;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Reflection.Emit;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;

namespace Society
{
    public partial class society_charges_monthwise : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        maintenance_cal Maintenance1 = new maintenance_cal();
        BL_Maintenance_Master bL_Maintenance = new BL_Maintenance_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }

            if (!IsPostBack)
            {               
                monthwise_charges_Gridbind();
                String str = "Select *  from society_master";
                repeater.fill_list(categoryRepeater, str);
            }

        }

        private void ClearFormFields()
        {
            txt_amt.Text = "";
            txt_total.Text = "";
            txt_total.Text = "";

          
        }
        public void monthwise_charges_Gridbind()
        {
            DataTable dt = new DataTable();
            Maintenance1.Sql_Operation = "Charges_Show";
            dt = bL_Maintenance.get_monthwise_charges(Maintenance1);
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
        public void runproc_save(string operation)
        {
            if (mon_charge_id.Value != "")
                Maintenance1.mon_charge_id = Convert.ToInt32(mon_charge_id.Value);
            Maintenance1.Sql_Operation = operation;
            Maintenance1.Society_Id = society_id.Value;
           
            Maintenance1.Pending_Amount = (Convert.ToDecimal(txt_pen_amt.Text) + Convert.ToDecimal(txt_amt.Text))-Convert.ToDecimal(txt_total.Text);
            Maintenance1.Amount = Convert.ToDecimal(txt_amt.Text);
            bL_Maintenance.update_monthwise_charges_details(Maintenance1);
         
        }

        public void runproc(string operation)
        {
            if (mon_charge_id.Value != "")
                Maintenance1.mon_charge_id = Convert.ToInt32(mon_charge_id.Value);
            Maintenance1.Sql_Operation = operation;
            var result = bL_Maintenance.update_monthwise_charges_details(Maintenance1);
            mon_charge_id.Value = result.maint_cal_id.ToString();
            txt_amt.Text = result.Amount.ToString();
            txt_pen_amt.Text = result.Pending_Amount.ToString();
            txt_total.Text = result.Total_Amount.ToString();


        }
        protected void categoryRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (society_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == society_id.Value)
                        categoryBox.Text = link.Text;
                    //remaining_due();
                }
            }
        }
        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                society_id.Value = e.CommandArgument.ToString();
                remaining_due();
            }
        }

        public void remaining_due()
        {
            Maintenance1.Sql_Operation = "Remaining_due";
            Maintenance1.Society_Id = society_id.Value;
   
            var result=bL_Maintenance.due_remaining(Maintenance1);
            txt_amt.Text = result.Amount.ToString();
            txt_pen_amt.Text = result.Pending_Amount.ToString();
            txt_total.Text = (result.Amount + result.Pending_Amount).ToString();

        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
         
                runproc_save("Update");
                   
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            
            

        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (mon_charge_id.Value != "")
                    Maintenance1.mon_charge_id = Convert.ToInt32(mon_charge_id.Value);
                Maintenance1.Sql_Operation = "Delete";
                bL_Maintenance.Monthwise_Charges_delete(Maintenance1);
           
            Response.Redirect("society_charges_monthwise.aspx");
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_charges_monthwise.aspx");
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string chargesociety_master_id = e.CommandArgument.ToString();
            mon_charge_id.Value = chargesociety_master_id;
            runproc("Select");
            btn_delete.Visible = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label chargesociety_master_id = (System.Web.UI.WebControls.Label)row.FindControl("mon_charge_id");
                Maintenance1.Sql_Operation = "Delete";

                Maintenance1.mon_charge_id = Convert.ToInt32(chargesociety_master_id.Text);
                bL_Maintenance.Monthwise_Charges_delete(Maintenance1);
           
            monthwise_charges_Gridbind();
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            monthwise_charges_Gridbind();
        }

        protected void Unnamed_Click(object sender, EventArgs e)
        {
            //remaining_due();
           
        }
    }
}