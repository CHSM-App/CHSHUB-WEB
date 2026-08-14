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

namespace Society
{
    public partial class printowner : System.Web.UI.Page
    {
      
        Owner owner = new Owner();
        BL_Owner_Master bL_Owner = new BL_Owner_Master();
        BL_FillRepeater repeater = new BL_FillRepeater();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                filldrop();
            }
        }
        public void filldrop()
        {
            String sql_query1 = "Select distinct build_name, build_id from owner_search_vw  where society_id='" + society_id.Value + "'";
            repeater.fill_list(Repeater1, sql_query1);
            String sql_query2 = "Select  distinct w_name, wing_id from owner_search_vw where society_id='" + society_id.Value + "'";
            repeater.fill_list(Repeater2, sql_query2);

        }

        protected void CategoryRepeater1_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                building_id.Value = e.CommandArgument.ToString();
                string str = "Select distinct w_name,wing_id from dbo.flat where society_id='" + society_id.Value + "'and  build_id='" + building_id.Value + "'";
                repeater.fill_list(Repeater2, str);
            }
        }
        protected void CategoryRepeater2_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                wing_id.Value = e.CommandArgument.ToString();

            }
        }
        protected void Button1_Click(object sender, EventArgs e)
        {
            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();
           

                if (TextBox1.Text == "select" && TextBox2.Text == "select")
                    sb.Append("Select * from owner_search_vw where type='Owner' and active_status=0 and  society_id='" + Session["Society_id"].ToString() + "'");


                else
                {
                    sb.Append(" Select * from owner_search_vw where type='owner' and active_status=0 and  society_id='" + Session["Society_id"].ToString() + "'");

                    if (TextBox1.Text != "select")
                    {
                        if (count > 0)
                        {
                            sb.Append(" AND ");
                        }
                        sb.Append(" build_name like '" + TextBox1.Text + "%'");
                        count++;
                    }

                    if (TextBox2.Text != "select")
                    {
                        if (count > 0)
                        {
                            sb.Append(" AND ");
                        }
                        sb.Append(" w_name like '" + TextBox2.Text + "%'");
                        count++;
                    }
                }

                owner.Sql_Operation = sb.ToString();
                var dt = bL_Owner.get_printowner(owner);

                ReportViewer1.LocalReport.DataSources.Clear();
                ReportDataSource rds = new ReportDataSource("owner", dt);
                ReportViewer1.LocalReport.ReportPath = Server.MapPath("owner_details.rdlc");
                ReportParameter parameter = new ReportParameter("build_name", TextBox1.Text);
                ReportViewer1.LocalReport.SetParameters(parameter);
                ReportViewer1.LocalReport.DataSources.Add(rds);
                ReportViewer1.LocalReport.Refresh();



            }
        

        protected void ddl_build_SelectedIndexChanged(object sender, EventArgs e)
        {
            //if (TextBox1.Text != "select")
            //{

            //    string sql1 = "Select distinct w_name,wing_id from dbo.flat where society_id='" + society_id.Value + "'and  name='" + Repeater1.SelectedValue + "'";
            //    bL_Owner.fill_list(Repeater2, sql1)

            //}
        }
    }
}
