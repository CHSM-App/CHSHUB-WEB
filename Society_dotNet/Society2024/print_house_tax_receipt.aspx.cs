using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Microsoft.Reporting.WebForms;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class print_house_tax_receipt : System.Web.UI.Page
    {
        BL_Village_Owner bL_Owner = new BL_Village_Owner();
        VillageOwner owner = new VillageOwner();
        protected void Page_Load(object sender, EventArgs e)
        {
            village_id.Value = Session["village_id"].ToString();
            if (!IsPostBack)
            {
                filldrop();
            }
        }

        public void filldrop()
        {
            String sql_query = "select house_no,village_owner_id from house_owner where village_id='" + village_id.Value + "'";
            bL_Owner.fill_drop(ddl_house_no, sql_query, "house_no", "house_no");
        }

        protected void ddl_house_no_SelectedIndexChanged(object sender, EventArgs e)
        {
           
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();


            if (ddl_house_no.SelectedValue == "select")
                sb.Append("Select top 1 * from house_tax where active_status=0 and village_id='" + Session["village_id"].ToString() + "'");


            else
            {
                sb.Append(" Select top 1 * from house_tax where active_status=0 and village_id='" + Session["village_id"].ToString() + "'");

                if (ddl_house_no.SelectedValue != "select")
                {
                    if (count > 0)
                    {
                        sb.Append(" AND ");
                    }
                    sb.Append(" house_no like '" + ddl_house_no.Text + "%'");
                    count++;
                }
            }
            owner.Sql_Operation = sb.ToString();
            var dt = bL_Owner.print_house_receipt(owner);


            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("Village_Receipt", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("HomeTaxRecipt.rdlc");
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();
        }
    }
}