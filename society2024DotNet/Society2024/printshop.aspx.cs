using BusinessLogic.BL;
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
    public partial class printshop : System.Web.UI.Page
    {

        Shop_Maintenance shop = new Shop_Maintenance();
        BL_Shop_Maint bL_Shop = new BL_Shop_Maint();
        BL_FillRepeater repeater = new BL_FillRepeater();
        protected void Page_Load(object sender, EventArgs e)
        {
            society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                filldrop();
            }
        }

        public void filldrop()
        {
            string sql1 = "SELECT distinct pay_method,led_id  FROM  shop_maintenance where society_id='" + society_id.Value + "'";
            repeater.fill_list(Repeater1, sql1);

        }
        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                payment_id.Value = e.CommandArgument.ToString();

            }
        }
        protected void Button1_Click(object sender, EventArgs e)
        {

            int count = 1;

            System.Text.StringBuilder sb = new System.Text.StringBuilder();



            if (TextBox1.Text == "select" && txt_date.Text == "")
                sb.Append("Select *  from shop_vw where society_id='" + Session["Society_id"].ToString() + "'");


            else
            {
                sb.Append(" Select *  from shop_vw where society_id='" + Session["Society_id"].ToString() + "'");

                if (TextBox1.Text != "select")
                {
                    if (count > 0)
                    {
                        sb.Append(" AND ");
                    }
                    sb.Append(" pay_method like '" + TextBox1.Text + "%'");
                    count++;
                }

                if (txt_date.Text != "")
                {
                    if (count > 0)
                    {
                        sb.Append(" AND ");
                    }
                    sb.Append(" m_date =  '" + txt_date.Text + "'");
                    count++;
                }
            }

            shop.Sql_Operation = sb.ToString();
            var dt = bL_Shop.get_printshop(shop);

            ReportViewer1.LocalReport.DataSources.Clear();
            ReportDataSource rds = new ReportDataSource("ledger", dt);
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("ledger.rdlc");
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();

        }

    }
}

