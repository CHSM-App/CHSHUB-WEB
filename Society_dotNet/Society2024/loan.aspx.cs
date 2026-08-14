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
using BusinessLogic.BL;
using DBCode.DataClass;
using System.Windows.Forms;

namespace Society
{
    public partial class loan : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Loan GetLoan = new Loan();
        BL_Loan l_Loan = new BL_Loan();
       
        protected void Page_Load(object sender, EventArgs e)
        {
            
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Loan_GridBind();
                //fill_drop();
                allBinds();
                
            }

        }

      



        protected void allBinds()
        {
            DataTable dt = new DataTable();
            dt = l_Loan.fill_list("flat_master", society_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = l_Loan.fill_list("loan_type", society_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = l_Loan.fill_list("certificate", society_id.Value);
            Repeater3.DataSource = dt;
            Repeater3.DataBind();


        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                flat_no_id.Value = e.CommandArgument.ToString();

            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                loan_type_id.Value = e.CommandArgument.ToString();

            }
        }

        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                share_id.Value = e.CommandArgument.ToString();

            }
        }
        public void fill_drop()
        {
            //String sql_query = "Select *  from flat_master where society_id='" + society_id.Value + "'";
            //l_Loan.fill_drop(ddl_flat, sql_query, "flat_no", "flat_id");

            //String sql_query1 = "Select *  from loan_type";
            //l_Loan.fill_drop(ddl_loan, sql_query1, "loan_type", "type_id");

            //String sql_query2 = "Select *  from certificate";
            //l_Loan.fill_drop(ddl_certificate, sql_query2, "c_name", "cert_id");
        }


        public void Loan_GridBind()
        {
            DataTable dt = new DataTable();
            GetLoan.Sql_Operation = "Grid_Show";
            GetLoan.Society_Id = society_id.Value;
            dt = l_Loan.GetLoan(GetLoan);

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
            if (loan_id.Value != "")
                GetLoan.loan_id = Convert.ToInt32(loan_id.Value);
            GetLoan.Sql_Operation = operation;
            GetLoan.Society_Id = society_id.Value;
            GetLoan.flat_id = Convert.ToInt32(flat_no_id.Value);
            GetLoan.Bank = txt_bank.Text;
            GetLoan.Type_Id = Convert.ToInt32(loan_type_id.Value);
            GetLoan.Noc_Issued = ddl_noc.SelectedValue;
            GetLoan.cert_id = Convert.ToInt32(share_id.Value);
            GetLoan.Society_Noc = Convert.ToDateTime(txt_noc_society.Text);
            if(txt_loan_clear.Text != "")
            GetLoan.Loan_Clearance = Convert.ToDateTime(txt_loan_clear.Text);
            var result = l_Loan.Update_Loan(GetLoan);
        }


        public void runproc(string operation)
        {

            if (loan_id.Value != "")
                GetLoan.loan_id = Convert.ToInt32(loan_id.Value);
            GetLoan.Sql_Operation = operation;

            var result1 = l_Loan.Update_Loan(GetLoan);


            //loan_id.Value = result1.Loanotice_id.ToString();
            society_id.Value = result1.Society_Id;
            txt_bank.Text = result1.Bank;
            flat_no_id.Value = result1.flat_id.ToString();
            loan_type_id.Value = result1.Type_Id.ToString();
            ddl_noc.SelectedValue = result1.Noc_Issued.ToString();
            share_id.Value = result1.cert_id.ToString();
            txt_noc_society.Text = result1.Society_Noc.ToString("yyyy-MM-dd");
            txt_loan_clear.Text = result1.Loan_Clearance.ToString("yyyy-MM-dd");

            allBinds();


        }




       
        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                runproc("Delete");
           
            Response.Redirect("loan.aspx");
        }
        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

            GetLoan.Name = txt_search.Text.Trim();
            GetLoan.Sql_Operation = "search";
            GetLoan.Society_Id = society_id.Value;
            var result = l_Loan.search_loan(GetLoan);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void edit_Click(object sender, EventArgs e)
        {
            txt_bank.Text = "Bhushan";
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            loan_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;
            Panel1.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }
        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void close_Click(object sender, EventArgs e)
        {
            Response.Redirect("loan.aspx");
        }

        protected void ddl_loan_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TextBox2.Text == "Other")
                Panel2.Visible = true;
            else
                Panel2.Visible = false;
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label loan_id = (System.Web.UI.WebControls.Label)row.FindControl("loan_id");
                GetLoan.Sql_Operation = "Delete";

                GetLoan.loan_id = Convert.ToInt32(loan_id.Text);
                l_Loan.delete(GetLoan);
            
            Loan_GridBind();

        }

     

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Loan_GridBind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            //flat_no_id.Value
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (flat_no_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == flat_no_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (loan_type_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == loan_type_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (share_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == share_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }
    }
}

    

