using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class agm_report : System.Web.UI.Page
    {
        Amc agm = new Amc();
        BL_Amc_Master bl_agm = new BL_Amc_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }

            if (!IsPostBack)
            {
                GridViewBind();
            }
        }

        protected void txtYearRange_TextChanged(object sender, EventArgs e)
        {
            string input = txtYearRange.Text.Trim();
            if (input.Contains("-"))
            {
                string[] parts = input.Split('-');
                if (parts.Length == 2 &&
                    int.TryParse(parts[0].Trim(), out int startYear) &&
                    int.TryParse(parts[1].Trim(), out int endYear))
                {
                    DateTime fromDate = new DateTime(startYear, 4, 1);
                    DateTime toDate = new DateTime(endYear, 3, 31);

                    lblFinancialRange.Text = $"Financial Year: {fromDate:dd MMMM yyyy} to {toDate:dd MMMM yyyy}";

                    agm.StartDate = fromDate.ToString("yyyy-MM-dd");
                    agm.EndDate = toDate.ToString("yyyy-MM-dd");
                    agm.SocietyId = Session["society_id"].ToString();
                    agm.Sql_Operation = "GetAgm";


                    DataTable dt = bl_agm.getAmcDetails(agm);
                    GridView1.DataSource = dt;
                    GridView1.DataBind();

                }
                else
                {
                    lblFinancialRange.Text = "Please select valid years (e.g. 2024 - 2025)";
                }
            }
        }

        private void GridViewBind()
        {
       
            DataTable dt = new DataTable();
            dt.Columns.Add("Details");
            dt.Rows.Add("AGM Meeting Summary");
            dt.Rows.Add("Budget Overview");
            dt.Rows.Add("Maintenance Report");
            //GridView1.DataSource = dt;
            //GridView1.DataBind();
        }
    }
}