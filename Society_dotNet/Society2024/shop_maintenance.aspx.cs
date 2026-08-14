using BusinessLogic.BL;
using DocumentFormat.OpenXml.Wordprocessing;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;
using Utility.DataClass;

namespace Society

{
    public partial class shop_maintenance : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Shop_Maintenance maintenance = new Shop_Maintenance();
        BL_Shop_Maint bL_Shop = new BL_Shop_Maint();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                //filldrop();

               
                maintenance.Sql_Operation = "Fill_list";
                maintenance.Society_Id = society_id.Value;
                var dt = bL_Shop.getshopmaintenance(maintenance);

                Repeater1.DataSource = dt;
                Repeater1.DataBind();

                shop_maintenance_GridBind();
                panel2.Visible = false;
                panel3.Visible = false;
            }
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                ledger_id.Value = e.CommandArgument.ToString();
            }

        }

        public void filldrop()
        {
            //string sql1 = "SELECT  * FROM  ledger";
            //bL_Shop.fill_drop(ddl_ledger, sql1, "led_description", "led_id");
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            shop_maint_id.Value = id;
            runproc("Select");
            ddl_method_SelectedIndexChanged(sender, e);
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }
        public void shop_maintenance_GridBind()
        {
            DataTable dt = new DataTable();
            maintenance.Sql_Operation = "Grid_Show";
            maintenance.Society_Id = society_id.Value;
            dt = bL_Shop.getshopmaintenance(maintenance);

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

            maintenance.Search = txt_search.Text.Trim();
            maintenance.Sql_Operation = "search";
            maintenance.Society_Id = society_id.Value;
            var result = bL_Shop.search_Shop_maint(maintenance);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }
        protected void btn_save_Click(object sender, EventArgs e)

        {
            string str = runproc_save("Update");

            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            else
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

            }
        }
        protected void btn_delete_Click(object sender, EventArgs e)
        {
            
                runproc_save("delete");
          
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("shop_maintenance.aspx");
        }
        public string runproc_save(String operation)
        {
            if (shop_maint_id.Value != "")
                maintenance.shop_maint_id = Convert.ToInt32(shop_maint_id.Value.ToString());
            maintenance.Sql_Operation = operation;
            maintenance.Society_Id = society_id.Value;
            maintenance.Mrep_No = txt_recipt.Text;
            if (txt_date.Text != "")
                maintenance.M_Date = Convert.ToDateTime(txt_date.Text);
            maintenance.led_id = Convert.ToInt32(ledger_id.Value);
            maintenance.Amt = Convert.ToInt32(txt_amt.Text);
            maintenance.Other_Details = txt_details.Text;
            maintenance.Pay_Method = ddl_method.SelectedValue;
            if (txt_chqno.Text != "")
                maintenance.Cheq_No = txt_chqno.Text;
            if (txt_chqdate.Text != "")
                maintenance.Cheq_Date = Convert.ToDateTime(txt_chqdate.Text);
            if (txt_upi.Text != "")
                maintenance.Cheq_No = txt_upi.Text;
            var result = bL_Shop.updateshopmaintenance(maintenance);
            return result.Sql_Result;

        }


        public void runproc(String operation)
        {
            if (shop_maint_id.Value != "")
                maintenance.shop_maint_id = Convert.ToInt32(shop_maint_id.Value);
            maintenance.Sql_Operation = operation;
            var result = bL_Shop.updateshopmaintenance(maintenance);

            shop_maint_id.Value = result.shop_maint_id.ToString();
            society_id.Value = result.Society_Id;
            txt_recipt.Text = result.Mrep_No;
            txt_date.Text = result.M_Date.ToString("yyyy-MM-dd");
            ledger_id.Value = result.led_id.ToString();
            txt_amt.Text = result.Amt.ToString();
            txt_details.Text = result.Other_Details;
            ddl_method.SelectedValue = result.Pay_Method;
            txt_chqno.Text = result.Cheq_No;
            txt_chqdate.Text = result.Cheq_Date.ToString("yyyy-MM-dd");
            txt_upi.Text = result.Cheq_No;
            String str1 = "SELECT  * FROM  ledger";
            repeater.fill_list(Repeater1, str1);
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label shop_maint_id = (System.Web.UI.WebControls.Label)row.FindControl("shop_maint_id");
                maintenance.Sql_Operation = "Delete";

                maintenance.shop_maint_id = Convert.ToInt32(shop_maint_id.Text);
                bL_Shop.delete(maintenance);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                shop_maintenance_GridBind();
           
            Response.Redirect("shop_maintenance.aspx");
        }
        public void paystatus_check()
        {
            if ((ddl_method.SelectedValue) == "Cash")
            {
                panel2.Visible = false;
                panel3.Visible = false;


            }
            else if ((ddl_method.SelectedValue) == "UPI Payment")
            {


                panel3.Visible = true;
                panel2.Visible = false;
            }
            else if ((ddl_method.SelectedValue) == "Cheque No")
            {

                panel2.Visible = true;
                panel3.Visible = false;
            }

        }

        protected void ddl_method_SelectedIndexChanged(object sender, EventArgs e)
        {
            paystatus_check();
        }

        protected void txt_recipt_TextChanged(object sender, EventArgs e)
        {
            if (txt_recipt.Text.Trim() != "")
            {
                if (shop_maint_id.Value != "")
                    maintenance.shop_maint_id = Convert.ToInt32(shop_maint_id.Value);
                maintenance.Sql_Operation = "check_no";
                maintenance.Society_Id = society_id.Value;
                maintenance.Mrep_No = txt_recipt.Text;
                var result = bL_Shop.receipt_textchanged(maintenance);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                Label14.Text = result.Sql_Result;

            }
        }


        protected void btn_print_Click(object sender, EventArgs e)
        {
            Response.Redirect("printshop.aspx");
        }


        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            shop_maintenance_GridBind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (ledger_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    if (link.CommandArgument == ledger_id.Value)

                        TextBox1.Text = link.Text;

                }

            }

        }
    }
}
