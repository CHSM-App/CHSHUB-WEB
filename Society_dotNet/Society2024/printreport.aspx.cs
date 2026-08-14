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
    public partial class printreport : System.Web.UI.Page
    {
       
        maintenance Maintnance = new maintenance();
        BL_Maintenance_Master bL_Maintenance = new BL_Maintenance_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            society_id.Value = Session["society_id"].ToString();
           
            //Session["n_m_id"]=Request.QueryString["n_m_id"];
            if (!IsPostBack)
            {
                if (Session["n_m_id"] != null)
                    Button1_Click(sender, e);

            }
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            Maintnance.Sql_Operation = "Select  * from maintainance where active_status=0  and n_m_id = " + Session["n_m_id"].ToString() + " and society_id='" + society_id.Value + "'";
            var dt = bL_Maintenance.get_maintanance(Maintnance);
            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("maintenance_bill", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("maintenance_bill.rdlc");

            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();

        }
    }
}
