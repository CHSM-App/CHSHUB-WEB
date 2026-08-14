using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Presentation;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class Profit_loss_report : System.Web.UI.Page
    {

        BL_Amc_Master bl_agm = new BL_Amc_Master();
        Amc audit = new Amc();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null) Response.Redirect("login1.aspx");

            if (!IsPostBack)

            {
                creditDebitGridBind();
            }
        }


        protected void creditDebitGridBind()
        {
            audit.Sql_Operation = "grid_bind_CD";
            audit.SocietyId = Session["society_id"].ToString();

            DataTable dt = bl_agm.bindIncome(audit);

            if (dt == null || dt.Rows.Count == 0)
            {
                GridView1.DataSource = null;
                GridView1.DataBind();
                return;
            }

            // Calculate totals
            decimal totalIncome = dt.AsEnumerable()
                .Where(r => !r.IsNull("current_year_income") &&
                            r["current_year_income"].ToString().Trim() != "")
                .Sum(r => Convert.ToDecimal(r["current_year_income"]));

            decimal totalExpense = dt.AsEnumerable()
                .Where(r => !r.IsNull("current_year_expense") &&
                            r["current_year_expense"].ToString().Trim() != "")
                .Sum(r => Convert.ToDecimal(r["current_year_expense"]));
            DataRow totalRow1 = dt.NewRow();
            // Create one total row
            DataRow totalRow = dt.NewRow();
            totalRow["income"] = "Total Income";
            totalRow["current_year_income"] = totalIncome;
            totalRow["expense"] = "Total Expense";
            totalRow["current_year_expense"] = totalExpense;

            dt.Rows.Add(totalRow1);
            dt.Rows.Add(totalRow);
            dt.AcceptChanges();

            GridView1.DataSource = dt;
            GridView1.DataBind();
        }

    }
}