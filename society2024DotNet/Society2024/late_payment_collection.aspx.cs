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
    public partial class LatePaymentCollection : System.Web.UI.Page
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
            audit.Sql_Operation = "ownerDue";
            audit.SocietyId = Session["society_id"].ToString();

            DataTable dt = bl_agm.latePayemnt(audit);

            if (dt == null || dt.Rows.Count == 0)
            {
                GridView1.DataSource = null;
                GridView1.DataBind();
                return;
            }

            // Calculate totals
            decimal totalIncome = dt.AsEnumerable()
                .Where(r => !r.IsNull("tax_interest_amt") &&
                            r["tax_interest_amt"].ToString().Trim() != "")
                .Sum(r => Convert.ToDecimal(r["tax_interest_amt"]));

            decimal totalExpense = dt.AsEnumerable()
                .Where(r => !r.IsNull("amt_forward") &&
                            r["amt_forward"].ToString().Trim() != "")
                .Sum(r => Convert.ToDecimal(r["amt_forward"]));
            DataRow totalRow1 = dt.NewRow();
            // Create one total row
            DataRow totalRow = dt.NewRow();
            totalRow["name"] = "Total Collection";
            totalRow["tax_interest_amt"] = totalIncome;
            //totalRow["expense"] = "Total Late Payment Collection";
            totalRow["amt_forward"] = totalExpense;

            dt.Rows.Add(totalRow1);
            dt.Rows.Add(totalRow);
            dt.AcceptChanges();

            GridView1.DataSource = dt;
            GridView1.DataBind();
        }

    }
}