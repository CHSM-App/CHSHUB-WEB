using BusinessLogic.BL;
using Microsoft.Reporting.WebForms;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society2024
{
    public partial class Paid_amount : System.Web.UI.Page
    {
        receipt GetReceipt = new receipt();
        BL_Receipt bL_Receipt = new BL_Receipt();
        protected void Page_Load(object sender, EventArgs e)
        {
            village_id.Value = Session["village_id"].ToString();

            if (!IsPostBack)
            {
                Button1_Click(sender, e);
                // fill_dropdowns();


            }
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            GetReceipt.Sql_Operation = "Select * from village_receipt where active_status=0 and house_receipt_id=" + Session["receipt_no"].ToString() + "and village_id='" + village_id.Value + "'";
            var dt = bL_Receipt.get_paid_amount(GetReceipt);
            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("villageReceipt", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("paid_amount.rdlc");
            //  ReportParameter parameter = new ReportParameter("@receipt_id",receipt_id.Value);
            // ReportViewer1.LocalReport.SetParameters(parameter);
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();
        }
    }
}