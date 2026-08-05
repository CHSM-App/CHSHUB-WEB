using BusinessLogic.BL;
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
    public partial class printledger_details : System.Web.UI.Page
    {
        Ledger GetLedger = new Ledger();
        BL_Ledger bL_Ledger = new BL_Ledger();

        protected void Page_Load(object sender, EventArgs e)
        {
            society_id.Value = Session["society_id"].ToString();
            //if (!IsPostBack)
            //{
                
            //}
        }

        public void filldrop()
        {
           

        }
        protected void Button1_Click(object sender, EventArgs e)
        {
          

            System.Text.StringBuilder sb = new System.Text.StringBuilder();


            sb.Append("Select * from ledger_vw where active_status=0 and society_id='" + Session["Society_id"].ToString() + "'");

            GetLedger.Sql_Operation = sb.ToString();
            var dt = bL_Ledger.get_print_Ledger(GetLedger);


            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("ledger_details", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("ledger_details.rdlc");

            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();
        }
    }
           
       
    
}
