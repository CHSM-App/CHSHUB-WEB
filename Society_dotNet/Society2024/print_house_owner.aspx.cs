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

namespace Society
{
    public partial class print_house_owner : System.Web.UI.Page
    {
        BL_Village_Owner bL_Owner = new BL_Village_Owner();
        VillageOwner owner = new VillageOwner();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] == null)

                Response.Redirect("login1.aspx");
              village_id.Value = Session["village_id"].ToString();

            if (!IsPostBack)
            {
                filldrop();
            }
        }

        public void filldrop()
        {
            String sql_query1 = "Select *  from house_type";
            bL_Owner.fill_drop(ddl_house_type, sql_query1, "house_type", "house_type_id");
        }


        protected void Button1_Click(object sender, EventArgs e)
        {
            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();


            if (ddl_house_type.SelectedValue == "select")
                sb.Append("Select * from house_owner_vw where active_status=0 and village_id='" + Session["village_id"].ToString() + "'");


            else
            {
                sb.Append(" Select * from house_owner_vw where active_status=0 and village_id='" + Session["village_id"].ToString() + "'");

                if (ddl_house_type.SelectedValue != "select")
                {
                    if (count > 0)
                    {
                        sb.Append(" AND ");
                    }
                    sb.Append(" house_type_id like '" + ddl_house_type.Text + "%'");
                    count++;
                }
            }

            owner.Sql_Operation = sb.ToString();
            var dt = bL_Owner.print_house_owner(owner);

            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("house_owner", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("village_owner.rdlc");
            //ReportParameter parameter = new ReportParameter("village_address", ddl_build.Text);
            //ReportViewer1.LocalReport.SetParameters(parameter);
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();



        }
    }
}