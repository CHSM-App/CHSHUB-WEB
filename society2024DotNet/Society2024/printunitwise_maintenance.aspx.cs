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
    public partial class printunitwise_maintenance : System.Web.UI.Page
    {
        Owner owner = new Owner();
        BL_Owner_Master bL_Owner = new BL_Owner_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            //society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                filldrop();
            }
        }
        public void filldrop()
        {
            //String sql_query = "Select distinct month_name from unitwise_maintenance_vw";
            //st.fill_drop(ddl_month, sql_query, "month_name", "month_name");


        }


        protected void Button1_Click(object sender, EventArgs e)
        {
            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            
               
                if (txt_to.Text == "" && txt_from.Text == "")
                    sb.Append("Select * from sm ");


                else
                {
                    sb.Append(" Select * from sm");


                    if (txt_from.Text != "" && txt_to.Text != "")
                    {
                        if (count > 0)
                        {
                            sb.Append(" where ");
                        }
                        sb.Append(" m_date between  '" + txt_from.Text + "' and '" + txt_to.Text + "'");
                        count++;
                    }
                }
            //con.Open();
            //if (ddl_month.SelectedItem.Text == "select")
            //    sb.Append("Select * from unitwise_maintenance_vw where society_id='" + Session["Society_id"].ToString() + "'");


            //else
            //{
            //    sb.Append(" Select * from unitwise_maintenance_vw where society_id='" + Session["Society_id"].ToString() + "'");

            //    if (ddl_month.SelectedItem.Text != "select")
            //    {
            //        if (count > 0)
            //        {
            //            sb.Append(" AND ");
            //        }
            //        sb.Append(" month_name like '" + ddl_month.SelectedItem.Text + "%'");
            //        count++;
            //    }

            //}

                owner.Sql_Operation = sb.ToString();
                var dt = bL_Owner.get_printunitwise_maintenance(owner);

                ReportViewer1.LocalReport.DataSources.Clear();
                ReportDataSource rds = new ReportDataSource("unitwise_maintenance", dt);
                ReportViewer1.LocalReport.ReportPath = Server.MapPath("unitwise_maintenance1.rdlc");
                //ReportParameter parameter = new ReportParameter("build", ddl_build.Text);
                //ReportViewer1.LocalReport.SetParameters(parameter);
                ReportViewer1.LocalReport.DataSources.Add(rds);
                ReportViewer1.LocalReport.Refresh();



            
        }
    }
}
