using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DocumentFormat.OpenXml.Drawing;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;
using Utility.DataClass;
using System.IO;
using System.Web.Script.Serialization;

namespace Society
{
   

    public class MyDataModel
    {
        public Color Color { get; set; }
        public string Label { get; set; }
        public int Value { get; set; }

    }
    public partial class dashboard : System.Web.UI.Page
    {

        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();


        public string strJson;
        protected void Page_Load(object sender, System.EventArgs e)
        {
           
           
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {

                pdc_reminder_Gridbind();

                due_this_year_Click(sender, e);
                GetDataForChart1();
                get_ticket();

                fetch_defaulter();
                dashUpdates();
                GetDataForRecent();
                getResidents();
                

                
            }
        }
        //protected void CheckBoxes_CheckedChanged(object sender, EventArgs e)
        //{


        //    if (CheckBox1.Checked && CheckBox2.Checked)
        //    {
        //        details.ExpenseType = 2;
        //        GetDataForChart1();

        //    }
        //    else if (CheckBox1.Checked)
        //    {
        //        details.ExpenseType = 0;
        //        GetDataForChart1();
        //    }
        //    else if (CheckBox2.Checked)
        //    {
        //        details.ExpenseType = 1;
        //        GetDataForChart1();
        //    }


        //}
        //protected int check_checked()
        //{

        //    if (CheckBox1.Checked && CheckBox2.Checked)
        //    {
        //        Session["checked"] = 2;
        //        return 2;

        //    }
        //    else if (CheckBox1.Checked)
        //    {
        //        Session["checked"] = 0;
        //        return 0;
        //    }
        //    else if (CheckBox2.Checked)
        //    {
        //        Session["checked"] = 1;
        //        return 1;
        //    }

        //    return 0;
        //}
        protected void TimerNotif_Tick(object sender, EventArgs e)
        {
            get_ticket();
        }

        //    [System.Web.Services.WebMethod(EnableSession = true)]
        //public string getToken(string token)
        //{
        //    System.Diagnostics.Debug.WriteLine("Received token: " + token);
        //    // Now you can access HttpContext.Current.Session
        //    if (HttpContext.Current.Session["name"] == null)
        //        throw new Exception("Not authenticated");

        //    lblToken.Text = token;
           
        //    HttpContext.Current.Session["lastToken"] = token;
        //    return "OK";
        //}

        protected void dashUpdates()
        {
            

            details.Sql_Operation = "Updates";
            
            details.Society_Id = society_id.Value;
            var dt = BL_Login.dashUpdates(details);

            if (!dt.Columns.Contains("ImageUrl"))
                dt.Columns.Add("ImageUrl", typeof(string));

            foreach (DataRow row in dt.Rows)
            {
                string type = row["type"]?.ToString()?.ToLower() ?? "";
                switch (type)
                {
                    case "notice":
                        row["ImageUrl"] = "img/notice.gif";
                    
                        break;
                    case "meeting":
                        row["ImageUrl"] = "img/meeting.gif";
                       
                        break;
                    case "event":
                        row["ImageUrl"] = "img/event.gif";
                        
                        break;
                    // Add more cases as needed
                    default:
                        row["ImageUrl"] = "img/default.png";
                        
                        break;
                }
            }

            Updates.Visible = dt.Rows.Count >= 1;
            noUpdates4.Visible = dt.Rows.Count == 0;

            Updates.DataSource = dt;
            Updates.DataBind();
        }


        protected void Updates_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Redirect")
            {
                string type = e.CommandArgument.ToString().ToLower();
                switch (type)
                {
                    case "notice":
                        Response.Redirect("notice_search.aspx");
                        break;
                    case "meeting":
                        Response.Redirect("meeting_search.aspx");
                        break;
                    case "event":
                        Response.Redirect("event_search.aspx");
                        break;
                    default:
                        Response.Redirect("dashboard.aspx");
                        break;
                }
            }
        }

        public void fetch_defaulter()
        {
            details.Sql_Operation = "defaulter_show";
            details.Society_Id = society_id.Value;
            var dt = BL_Login.getdefaulter(details);
            defaulter.Text = ToShortNumber(dt.Rows.Count);
        }
        public void getResidents()
        {
            details.Sql_Operation = "getResidents";
            details.Society_Id = society_id.Value;
            var data = BL_Login.getResidents(details);
            residents.Text = data.Sql_Result;
        }
        public void GetDataForChart1()
        {
            
            //details.Sql_Operation = "ExpenseChart";
            //details.Society_Id = society_id.Value;
            //details.ExpenseType = check_checked();
            //var dt = BL_Login.get_expense_chart(details);

            //Chart2.Visible = dt.Compute("Sum(expense)", string.Empty).ToString() == "0" ? false : true;
            //lblNoDataFound2.Visible = dt.Compute("Sum(expense)", string.Empty).ToString() == "0" ? true : false;

           

            //JavaScriptSerializer serializer = new JavaScriptSerializer();
            //jsonData = serializer.Serialize(yourObject);



            //Chart2.DataSource = dt;
            //Chart2.DataBind();
            

        }
        //public string getJson()
        //{
        //    details.Sql_Operation = "ExpenseChart";
        //    details.Society_Id = society_id.Value;
        //    details.ExpenseType = check_checked();
        //    var dt = BL_Login.get_expense_chart(details);

        //    strJson = JsonConvert.SerializeObject(dt, Formatting.Indented);
        //    return strJson;

        //}

        public void GetDataForRecent()
        {

            details.Sql_Operation = "RecentActivity";
            details.Society_Id = society_id.Value;

            var dt = BL_Login.get_recent_chart(details);
            
            Recent_activity.DataSource = dt;
            Recent_activity.DataBind();


        }

        public void GetDataForPieChart(DateTime date1, DateTime date2)
        {

            details.Sql_Operation = "IncomeChart";
            details.Society_Id = society_id.Value;
            details.Establish_Date = date1;
            details.Otp_Date = date2;
            var dt = BL_Login.income_chart(details);  // Fetch data from DAL
            Chart1.Visible = dt.Rows.Count > 0;
            lblNoData.Visible = dt.Rows.Count == 0;
            chartDots.Visible = dt.Rows.Count > 0;


            Chart1.Series["Default"].Points.Clear();
            string[] XPointMember = new string[dt.Rows.Count];
            int[] YPointMember = new int[dt.Rows.Count];

            for (int count = 0; count < dt.Rows.Count; count++)
            {
                XPointMember[count] = dt.Rows[count]["category"].ToString();
                YPointMember[count] = Convert.ToInt32(dt.Rows[count]["amount"]);
                //lblDue.Text = YPointMember[0].ToString();
            }

            String dueAmt = lblDue.Text = dt.Rows.Count > 1 ? ToShortNumber(YPointMember[0]) : "0";

            Chart1.Series["Default"].Points.DataBindXY(XPointMember, YPointMember);
            foreach (Series charts in Chart1.Series)
            {
                foreach (DataPoint point in charts.Points)
                {
                    switch (point.AxisLabel)
                    {
                        case "Due":  point.Color = System.Drawing.ColorTranslator.FromHtml("#6266F1"); break;
                        case "Collection": point.Color = System.Drawing.ColorTranslator.FromHtml("#A6B4FD"); break;
                    }
                  //  point.ToolTip = $"{point.AxisLabel}: {point.YValues[0]:N2}";
                }
            }
            
          
        }


        private string ToShortNumber(long num) // on dimand of Bhushan
        {
            if (num >= 1_000_000_000)
                return Math.Floor(num / 1_000_000_000D * 10) / 10 + "B";
            if (num >= 1_000_000)
                return Math.Floor(num / 1_000_000D * 10) / 10 + "M";
            if (num >= 1_000)
                return Math.Floor(num / 1_000D * 10) / 10 + "k";

            return num.ToString();
        }



        public void get_ticket()
        {
            details.Sql_Operation = "Get_Ticket";
            details.Society_Id = society_id.Value;
            var dt = BL_Login.getticket(details);

            open.Text =Convert.ToInt32(dt.Open).ToString();
            resolved.Text = Convert.ToInt32(dt.Resolve).ToString();
          
        }
       

        public void pdc_reminder_Gridbind()
        {

            details.Sql_Operation = "Grid_Show";
            details.Society_Id = society_id.Value;
            var dt = BL_Login.Get_Pdc_Clearing(details);
            GridView1.DataSource = dt;
            ViewState["pdc_remainder"] = dt;
            GridView1.DataBind();
            GridView1.Visible = dt.Rows.Count >= 1;
            lblNoDataFound3.Visible = dt.Rows.Count == 0;
        }


        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["pdc_remainder"];
            if (dtrslt.Rows.Count > 0)
            {
                if (Convert.ToString(ViewState["sortdr"]) == "Asc")
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Desc";
                    ViewState["sortdr"] = "Desc";
                }
                else
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Asc";
                    ViewState["sortdr"] = "Asc";
                }
                GridView1.DataSource = dtrslt;
                GridView1.DataBind();


            }
            
        }
   
    


        protected void defaulter_Click(object sender, EventArgs e)
        {
            Response.Redirect("Defaulter.aspx");
          
        }

        protected void btn_mom_Click(object sender, EventArgs e)
        {
            //runproc("Update");
            //gridshow();

            // Response.Redirect("meeting_search.aspx");


            Response.Redirect("meeting_search.aspx");

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);



        }

        protected void due_amt_Click(object sender, EventArgs e)
        {
            Response.Redirect("Defaulter.aspx");
        }

        protected void due_bal_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_expense.aspx");
        }

        protected void fin_statement_Click(object sender, EventArgs e)
        {
            Response.Redirect("ledger_form.aspx");
        }

      
        protected void due_this_month_Click(object sender, EventArgs e)
        {
            GetDataForPieChart(new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1), new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1).AddMonths(1).AddDays(-1));
           
        }

        protected void due_last_month_Click(object sender, EventArgs e)
        {
            GetDataForPieChart(new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1).AddMonths(-1).AddDays(-1), new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1).AddMonths(1).AddDays(-1));
           
        }

        protected void due_this_year_Click(object sender, EventArgs e)
        {
            GetDataForPieChart(new DateTime(DateTime.Now.Year, 1, 1), new DateTime(DateTime.Now.Year, 12, 31));
           
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            pdc_reminder_Gridbind();

            due_this_month_Click(sender, e);
            GetDataForChart1();
        }

    }
}


