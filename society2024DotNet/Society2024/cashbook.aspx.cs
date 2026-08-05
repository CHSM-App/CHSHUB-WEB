using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Web.Configuration;
//using System.Windows.Controls;
//using Azure;
using System.Drawing.Drawing2D;
using Page = System.Web.UI.Page;
using Microsoft.Reporting.WebForms;
using Utility.DataClass;
using BusinessLogic.BL;
using Microsoft.Ajax.Utilities;
//using System.IdentityModel.Metadata


namespace Society
{
    public partial class cashbook : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Cashbook cash = new Cashbook();
        BL_Receipt bL_Receipt = new BL_Receipt();

        int dropValue = -1;
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
               


                txt_from.Text = new DateTime(DateTime.Now.Year, 4, 1).ToString("yyyy-MM-dd");
                txt_to.Text = DateTime.Now.ToString("yyyy-MM-dd");

            }

        }

       
       

        protected void Cashbook_GridBind()
        {

            cash.Sql_Operation = "cashbook";
            cash.Type = Convert.ToInt32(ddlTransactionType.SelectedValue);
            cash.Society_Id = Session["society_id"].ToString();
            if (dropValue != -1)
            {

                cash.Type = dropValue;
            }
            if (txt_from.Text != "" && txt_to.Text != "")
            {
                cash.Date1 = Convert.ToDateTime(txt_from.Text.ToString());
                cash.Date2 = Convert.ToDateTime(txt_to.Text.ToString());
            }
            var dt = bL_Receipt.Get_CashBook(cash);
            DataRow totalRow1 = dt.NewRow();
            totalRow1["seq"] = (dt.Rows.Count - 1).ToString();
            dt.Rows.InsertAt(totalRow1, dt.Rows.Count - 1);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();


        }


        protected void btn_search_Click(object sender, EventArgs e)
        {
            Cashbook_GridBind();

            GridView1.Visible = true;



        }
    }
}





