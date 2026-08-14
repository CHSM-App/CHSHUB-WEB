using BusinessLogic.BL;
using Microsoft.Reporting.WebForms;

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class print_expense : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Society_Expense expense = new Society_Expense();
        BL_Society_Expense bL_Expense = new BL_Society_Expense();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                //filldrop();
                string sql1 = "SELECT distinct expense_type  from society_expense_vw where society_id='" + society_id.Value + "'";
                repeater.fill_list(Repeater1, sql1);
            }
        }

        public void filldrop()
        {
            //string sql1 = "SELECT distinct expense_type  from society_expense_vw where society_id='" + society_id.Value + "'";
            //bL_Expense.fill_drop(ddl_expense, sql1, "expense_type", "expense_type");

        }

        protected void Button1_Click(object sender, EventArgs e)
        {

            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();
          

                if (TextBox1.Text == "select" &&  txt_date.Text == "" && txt_to.Text=="" )
                    sb.Append("Select *  from society_expense_vw where active_status=0 and society_id='" + Session["Society_id"].ToString() + "'");


                else
                {
                    sb.Append(" Select *  from society_expense_vw where active_status=0 and society_id='" + Session["Society_id"].ToString() + "'");

                    if (TextBox1.Text != "select")
                    {
                        if (count > 0)
                        {
                            sb.Append(" AND ");
                        }
                        sb.Append(" expense_type like '" + TextBox1.Text + "%'");
                        count++;
                    }

                    if (txt_date.Text != "" && txt_to.Text != "")
                    {
                        if (count > 0)
                        {
                            sb.Append(" AND ");
                        }
                        sb.Append(" date between  '" + txt_date.Text + "' and '" + txt_to.Text + "'");
                        count++;
                    }
                }
                expense.Sql_Operation = sb.ToString();
                var dt = bL_Expense.Get_Expense_Report(expense);

                ReportViewer1.LocalReport.DataSources.Clear();
                ReportDataSource rds = new ReportDataSource("society_expense", dt);
                ReportViewer1.LocalReport.ReportPath = Server.MapPath("society_expense.rdlc");
                ReportViewer1.LocalReport.DataSources.Add(rds);
                ReportViewer1.LocalReport.Refresh();



            }
        

        protected void ddl_expense_SelectedIndexChanged(object sender, EventArgs e)
        {
            Button1_Click(sender,e);
        }

        protected void txt_to_TextChanged(object sender, EventArgs e)
        {
            Button1_Click(sender, e);
        }

        protected void txt_date_TextChanged(object sender, EventArgs e)
        {
            Button1_Click(sender, e);
        }

    }
}
