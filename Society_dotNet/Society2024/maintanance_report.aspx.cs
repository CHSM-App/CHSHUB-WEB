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

namespace Society
{
    public partial class maintanance_report : System.Web.UI.Page
    {
       

        maintenance GetMaintenance = new maintenance();
        BL_Maintenance_Master maintenance_Master = new BL_Maintenance_Master();

        protected void Page_Load(object sender, EventArgs e)
        {
            society_id.Value = Session["society_id"].ToString();
        }

        protected void Button1_Click(object sender, EventArgs e)
        {

            System.Text.StringBuilder sb = new System.Text.StringBuilder();

            SqlCommand c = new SqlCommand("Select * from receipt_search_vw where society_id='" + society_id.Value + "' order by receipt_id desc");
           
            
            GetMaintenance.Sql_Operation = sb.ToString();
            var dt = maintenance_Master.Get_Maintanance_Report(GetMaintenance);

            ReportViewer1.LocalReport.DataSources.Clear();
                ReportDataSource rds = new ReportDataSource("maintenance_bill", dt);
                 ReportViewer1.LocalReport.ReportPath = Server.MapPath("maintenance_bill.rdlc");
                //ReportParameter parameter = new ReportParameter("m_id");
                //ReportViewer1.LocalReport.SetParameters(parameter);

                ReportViewer1.LocalReport.DataSources.Add(rds);
                ReportViewer1.LocalReport.Refresh();

             

        }
    }
}
