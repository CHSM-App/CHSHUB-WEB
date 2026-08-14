
using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
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
    public partial class Receipt_printreport1 : System.Web.UI.Page
    {
        //stored st = new stored();
        receipt GetReceipt = new receipt();
        BL_Receipt bL_Receipt = new BL_Receipt();
       
      

        protected void Page_Load(object sender, EventArgs e)
        {
            society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                Button1_Click(sender, e);
                // fill_dropdowns();


            }

        }
        //public void fill_dropdowns()
        //{

        //    string sql1 = "SELECT distinct Building_wing,b_id  FROM  receipt_search_vw";
        //    st.fill_drop(ddl_build, sql1, "Building_wing", "b_id");


        //}


        protected void Button1_Click(object sender, EventArgs e)
        {

            GetReceipt.Sql_Operation = "Select * from receipt_search_vw where active_status=0 and receipt_id=" + Session["receipt_no"].ToString() + "and society_id='" + society_id.Value + "'";
            var dt = bL_Receipt.get_printreceipt(GetReceipt);
            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("maintenance_receipt", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("maintenance_receipt.rdlc");
            //  ReportParameter parameter = new ReportParameter("@receipt_id",receipt_id.Value);
            // ReportViewer1.LocalReport.SetParameters(parameter);
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();

        }

    

        //protected void ddl_build_SelectedIndexChanged(object sender, EventArgs e)
        //{
        //    if (ddl_build.Text != "select")
        //    {

        //        string sql1 = "Select distinct name,owner_id from dbo.receipt_search_vw where society_id='" + society_id.Value + "'and  Building_wing='" + ddl_build.SelectedValue + "'";
        //        st.fill_drop(ddl_owner, sql1, "w_name", "w_id");




        //    }

        //}
    }
}