using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class house_tax_receipt : System.Web.UI.Page
    {
        BL_Village_Owner bL_Owner = new BL_Village_Owner();
        VillageOwner owner = new VillageOwner();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] == null)

                Response.Redirect("login1.aspx");
           else
                village_id.Value = Session["village_id"].ToString();


            if (!IsPostBack)
            {
               
                house_tax_receipt_gridbind();
                fetch_receipt();
                  panel2.Visible = false;
                fill_drop();
            }
            txt_date.Text= DateTime.Now.ToShortDateString();
        }

        public void fill_drop()
        {
            String sql_query = "select house_no,village_owner_id from house_owner where village_id='" + village_id.Value + "'";
            bL_Owner.fill_drop(ddl_house_no, sql_query, "house_no", "house_no");
            string sql1 = "SELECT * FROM dbo.pay_mode";
            bL_Owner.fill_drop(drp_pay_status, sql1, "pay_mode", "pay_id");
        }
        public void house_tax_receipt_gridbind()
        {
            DataTable dt = new DataTable();
            owner.Sql_Operation = "Grid_Show";
            owner.Village_Id = village_id.Value;
            dt = bL_Owner.get_tax_receipt(owner);

            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
        }

        public void runproc_save(String operation)
        {

            if (house_receipt_id.Value != "")
                owner.House_Receipt_Id = Convert.ToInt32(house_receipt_id.Value.ToString());
            owner.Sql_Operation = operation;
            owner.Village_Id = village_id.Value;
            owner.Receipt_No = receipt_no.Text;
            owner.House_No = Convert.ToInt32(ddl_house_no.SelectedValue.ToString());
            owner.House_Tax = Convert.ToDecimal(txt_house_tax.Text);
            owner.Paid_Amount = Convert.ToDecimal(txt_paid_amt.Text);
            owner.Type = ddl_type.SelectedValue;
            owner.Pay_Mode = Convert.ToInt32(drp_pay_status.SelectedValue);
            owner.Balance = Convert.ToDecimal(txt_balance.Text);
            if (drp_pay_status.SelectedValue == "3")
            {
                owner.Chqno = ddl_chq.SelectedValue;
                owner.Chqdate = Convert.ToDateTime(txt_chqdate.Text);
            }
            if (drp_pay_status.SelectedValue == "2")
            {
                owner.Chqdate = Convert.ToDateTime(txt_chqdate.Text);
                owner.Chqno = txt_chqno.Text;
            }
            bL_Owner.update_house_tax_receipt(owner);

        }
        public void runproc(string operation)
        {
            if (house_receipt_id.Value != "")
                owner.House_Receipt_Id = Convert.ToInt32(house_receipt_id.Value.ToString());
            owner.Sql_Operation = operation;

            var result = bL_Owner.update_house_tax_receipt(owner);
            if (operation == "Select")
            {

                (house_receipt_id.Value) = result.House_Receipt_Id.ToString();
                village_id.Value = result.Village_Id;
                receipt_no.Text = result.Receipt_No;
                ddl_house_no.SelectedValue = result.House_No.ToString();
                txt_house_tax.Text = result.House_Tax.ToString();
                txt_paid_amt.Text = result.Paid_Amount.ToString();
                drp_pay_status.SelectedValue = result.Pay_Mode.ToString();
                if (result.Pay_Mode == 3)
                    ddl_chq.SelectedValue = result.Chqno;
                txt_chqdate.Text = result.Chqdate.ToString("yyyy-MM-dd");
                if (result.Pay_Mode == 2)
                    txt_chqno.Text = result.Chqno;
                txt_balance.Text = result.Balance.ToString();
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            }
        }
        public void fetch_receipt()
        {
            owner.Sql_Operation = "receipt_fetch";
            owner.Village_Id = village_id.Value;
            var result = bL_Owner.fetch_House_tax_receipt(owner);
            receipt_no.Text = result.Receipt_No.ToString();
            txt_date.Text = result.Pay_Date.ToString("yyyy-MM-dd");
        }

        protected void ddl_chq_SelectedIndexChanged(object sender, EventArgs e)
        {
            owner.Sql_Operation = "cheque_select";
            owner.Chqno = ddl_chq.SelectedValue;
            owner.House_No = Convert.ToInt32(ddl_house_no.SelectedValue);
            var result = bL_Owner.check_select(owner);

            txt_chqdate.Text = result.Chqdate.ToString("yyyy-MM-dd");
            che_amount.Text = result.Chq_Amount.ToString();


        }

        public void paystatus_check()
        {
            if (Decimal.Parse(drp_pay_status.SelectedValue) == 1)
            {
                panel2.Visible = false;
                panel3.Visible = false;
                // adv_pay_settlement();
            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 2)
            {
                // panel1.Visible = False
                panel2.Visible = true;
                panel3.Visible = false;
                txt_chqno.Visible = true;
                ddl_chq.Visible = false;
                txt_chqdate.Enabled = true;
                che_amount.Enabled = true;


            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 3)
            {
                // panel1.Visible = True
                panel2.Visible = true;
                panel3.Visible = false;
                txt_chqno.Visible = false;
                ddl_chq.Visible = true;
                txt_chqdate.Enabled = false;
                che_amount.Enabled = false;


            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 4)
            {
                panel2.Visible = false;
                panel3.Visible = true;
                //adv_pay_settlement();
            }
        }

        protected void drp_pay_status_SelectedIndexChanged(object sender, EventArgs e)
        {
            paystatus_check1();
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            house_tax_receipt_gridbind();
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

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {
          
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("Select * from house_tax_receipt where active_status=0 and village_id='" + village_id.Value + "'");
            if (txt_search.Text != "")
            {
                sb.Append(" and " + search_field.SelectedValue + " like '" + txt_search.Text + "%'");
            }
            owner.Sql_Operation = sb.ToString();
            var result = bL_Owner.search_house_tax_receipt(owner);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            runproc_save("pending_dues");
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("house_tax_receipt.aspx");
        }

        public void paystatus_check1()
        {
            if (Decimal.Parse(drp_pay_status.SelectedValue) == 1)
            {
                panel2.Visible = false;
                panel3.Visible = false;
                // adv_pay_settlement();
            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 2)
            {
                //panel1.Visible = False
                panel2.Visible = true;
                panel3.Visible = false;
                txt_chqno.Visible = true;
                ddl_chq.Visible = false;
                txt_chqdate.Enabled = true;
                che_amount.Enabled = true;


            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 3)
            {
                //panel1.Visible = True
                panel2.Visible = true;
                panel3.Visible = false;
                txt_chqno.Visible = false;
                ddl_chq.Visible = true;
                txt_chqdate.Enabled = false;
                che_amount.Enabled = false;


            }
            else if (Decimal.Parse(drp_pay_status.SelectedValue) == 4)
            {
                panel2.Visible = false;
                panel3.Visible = true;
                //adv_pay_settlement();
            }
        }
        protected void btn_print_Click(object sender, EventArgs e)
        {
            Response.Redirect("Paid_amountreport.aspx");
        }

        protected void Delete_Command(object sender, CommandEventArgs e)
        {

        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            house_receipt_id.Value = id;
            runproc("Select");
            paystatus_check();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
        }

        protected void ddl_house_no_SelectedIndexChanged(object sender, EventArgs e)
        {
           if(ddl_house_no.SelectedItem.Text!="select")
           {
                owner.Sql_Operation = "house_tax_fetch";
                owner.House_No = Convert.ToInt32(ddl_house_no.SelectedValue);
                owner.Type = ddl_type.SelectedValue;
                var result= bL_Owner.pending_house_tax_receipt(owner);
                txt_house_tax.Text = result.House_Tax.ToString();
           }
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label house_receipt_id = (System.Web.UI.WebControls.Label)row.FindControl("house_receipt_id");
            owner.Sql_Operation = "Delete";

            owner.House_Receipt_Id = Convert.ToInt32(house_receipt_id.Text);
            bL_Owner.delete_house_tax(owner);
            house_tax_receipt_gridbind();
        }
        protected void txt_paid_amt_TextChanged(object sender, EventArgs e)
        {
            txt_balance.Text = (Decimal.Parse(txt_house_tax.Text) - Decimal.Parse(txt_paid_amt.Text)).ToString();
        }
        protected void Print_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            house_receipt_id.Value = id;
            Session["receipt_no"] = id;
            Response.Redirect("Paid_amountreport.aspx");
        }

        protected void search_field_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (search_field.SelectedValue == "pay_date")
            {
                txt_search.TextMode = TextBoxMode.Date;
            }
            else
                txt_search.TextMode = TextBoxMode.SingleLine;
            txt_search.Text = "";
        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }
    }
}