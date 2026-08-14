using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DataAccessLayer.DA;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Bibliography;
using DocumentFormat.OpenXml.Office2010.Excel;
using Society2024;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using ListItem = System.Web.UI.WebControls.ListItem;

//using CrystalDecisions.CrystalReports.Engine;
//using CrystalDecisions.Windows.Forms;

namespace Society
{
    public partial class maintenance_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        maintenance Maintenance1 = new maintenance();
        BL_Maintenance_Master bL_Maintenance = new BL_Maintenance_Master();

        BL_Notice_Master bL_Notice = new BL_Notice_Master();
        Notice notice = new Notice();

        DataTable dt1 = new DataTable();
        public class BillCharge
        {
            public int SrNo { get; set; }
            public string ChargeName { get; set; }
            public decimal Amount { get; set; }
        }



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

                maintenance_Gridbind();
                showHideGenerateBillBtn();

                Maintenance1.Society_Id = Session["society_id"].ToString();
                Maintenance1.Sql_Operation = "select";
                var result = bL_Maintenance.select_settings(Maintenance1);

                if (result.Gen_Date_Int.ToString() == "" && result.Per_Sqf_Rate.ToString() == "")
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "openSettingModal();", true);
                }


                if (Request.QueryString["id"] != null)
                {
                    //cust_id.Value = Request.QueryString["id"].ToString();

                }


            }

        }


        public void maintenance_Gridbind()
        {
            DataTable dt = new DataTable();
            Maintenance1.Sql_Operation = "Grid_Show";
            Maintenance1.Society_Id = society_id.Value;
            dt = bL_Maintenance.getMaintenanceDetails(Maintenance1);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            ViewState["BillData1"] = dt;

            GridView1.DataBind();
            GridView3.DataSource = dt;
            GridView3.DataBind();
        }

        //public void building_fill()
        //{
        //    DataTable dt = new DataTable();
        //    Maintenance1.Sql_Operation = "FillBuild";
        //    Maintenance1.Society_Id = society_id.Value;
        //    dt = bL_Maintenance.list_Fill(Maintenance1);
        //    //Repeater1.DataSource = dt;
        //    //Repeater1.DataBind();

        //}

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["BillData1"];
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


        protected void btn_new_Click(object sender, EventArgs e)
        {
            Response.Redirect("new_maintenance.aspx");
        }


        public string runproc_save(string operation)
        {
            Maintenance1.Sql_Operation = "exfetch";
            Maintenance1.Date = Convert.ToDateTime(txt_date.Text == "" ? DateTime.Now.ToString("yyyy-MM-dd") : txt_date.Text);
            Maintenance1.due_period = Convert.ToInt32(txt_period.Text);
            Maintenance1.BillType = false;
            bL_Maintenance.Add_Click(Maintenance1);

            Maintenance1.Sql_Operation = operation;
            Maintenance1.Society_Id = society_id.Value;
            var flat = Label4.Text.Split(':');

            if (flat.Length > 1)
                Maintenance1.Flat = Convert.ToInt32(flat[1]);

            var result = bL_Maintenance.updateMaintenanceDetails(Maintenance1);
            n_m_id.Value = result.n_m_id.ToString();

            return result.Sql_Result;
        }

        public void final_total()
        {

            int sum = Convert.ToInt32(dt1.Compute("SUM(f_amount)", string.Empty));
            txt_amount.Text = sum.ToString();

        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            n_m_id.Value = id;
            Session["n_m_id"] = n_m_id.Value;
            runproc("Select");
            btnAdd_Click(sender, e);
            list_fill();

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);

        }

        protected void btn_save_Click(object sender, EventArgs e) // Method to save the bill
        {

            if (txt_amount.Text != "0")
            {
                Maintenance1.Sql_Operation = "check_already";
                Maintenance1.M_Date = Convert.ToDateTime(txt_date.Text);
                Maintenance1.due_period = Convert.ToInt32(txt_period);
                var result = bL_Maintenance.check_already(Maintenance1);
                if (result.Sql_Result == "Exist")
                {


                    ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Maintenance Already Exist For This Month..!!!');", true);
                }

                else
                {

                    var str = runproc_save("Update");
                    if (str == "Done")
                    {
                        ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Maintenance Bill Only Save Not Generate Maintenance Bill..!!!');", true);
                        ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
                    }
                    else
                    {
                        ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

                    }
                }

            }
            else
                Response.Redirect("maintenance_search.aspx");


        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            if (n_m_id.Value != "")
                Maintenance1.n_m_id = Convert.ToInt32(n_m_id.Value);
            Maintenance1.Sql_Operation = "Delete";
            bL_Maintenance.delete(Maintenance1);
            Response.Redirect("maintenance_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            dt1 = null;
        }


        protected void btn_print_Click(object sender, EventArgs e)
        {
            Maintenance1.Sql_Operation = "GetBills";  // 👉 Replace with your actual operation name
            Maintenance1.Society_Id = society_id.Value;
            Maintenance1.n_m_id = Convert.ToInt32(n_m_id.Value); // If you're filtering by n_m_id = 1

            DataTable dt = bL_Maintenance.get_maintanance(Maintenance1);

            ViewState["bill"] = dt;
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "$('#printModal').modal('show');", true);
        }

        protected async void btn_bill_Click(object sender, EventArgs e)  //method to generate add-on bill
        {
            Maintenance1.Sql_Operation = "checkBill";
            Maintenance1.M_Date = Convert.ToDateTime(txt_date.Text == "" ? DateTime.Now.ToString("yyyy-MM-dd") : txt_date.Text);
            var result = bL_Maintenance.check_date(Maintenance1);
            n_m_id.Value = result.n_m_id.ToString();
            if (result.Sql_Result == "Exist")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Maintenance Already Exist For This Month..!!!');", true);

            }
            else
            {

                if (txt_amount.Text != "0")
                {
                    Maintenance1.Sql_Operation = "check_already";
                    Maintenance1.M_Date = Convert.ToDateTime(txt_date.Text == "" ? DateTime.Now.ToString("yyyy-MM-dd") : txt_date.Text);
                    var data = bL_Maintenance.check_already(Maintenance1);
                    n_m_id.Value = data.n_m_id.ToString();
                    if (data.Sql_Result != "Exist")
                        runproc_save("Update");
                }

                Maintenance1.Sql_Operation = "generate";
                Maintenance1.Society_Id = Session["society_id"].ToString();
                Maintenance1.due_period = Convert.ToInt32(txt_period.Text);
                dt1 = (DataTable)ViewState["expenseData"];

                var dt = bL_Maintenance.genrate_bill(Maintenance1);
                maintenance_Gridbind();
                if (dt.Rows.Count > 0)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        notice.User_Id = Convert.ToInt32(row["owner_id"].ToString());
                        notice.UserType = row["type"].ToString();
                        notice.Notification_id = Convert.ToInt32(row["maintenance_id"].ToString());
                        notice.Notification_Type = "Maintenance";
                        notice.Body = "New Maintenance Added";
                        notice.Society_Id = Session["society_id"].ToString();
                        bL_Notice.send_notification(notice);
                        generate_notification(row["token"].ToString());
                    }

                    ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "SuccessEntry()", true);
                }
                else
                    ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Maintenance not generated');", true);
                Response.Redirect("maintenance_search.aspx");
            }
            btnAdd_Click(sender, e);
        }

        public void list_fill()
        {

            Maintenance1.Sql_Operation = "owner_select";
            //Maintenance1.build_id = Convert.ToInt32(building_id.Value);
            var result4 = bL_Maintenance.list_Fill(Maintenance1);


            CheckBoxList1.DataSource = result4;
            CheckBoxList1.DataTextField = "owner_name";
            CheckBoxList1.DataValueField = "owner_id";
            CheckBoxList1.DataBind();


        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            Label n_m_id = (Label)row.FindControl("n_m_id");
            Maintenance1.Sql_Operation = "Delete";

            Maintenance1.n_m_id = Convert.ToInt32(n_m_id.Text);
            var result = bL_Maintenance.delete(Maintenance1);

            maintenance_Gridbind();

            if (result.Sql_Result == "Done")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "Popup", "Delete()", true);
                Response.Redirect("maintenance_search.aspx");
            }


        }


        protected void btn_search_Click(object sender, EventArgs e)
        {

            Maintenance1.Name = txt_search.Text.Trim();
            Maintenance1.Sql_Operation = "search";
            Maintenance1.Society_Id = society_id.Value;
            var result = bL_Maintenance.search_maintenance1(Maintenance1);
            GridView1.DataSource = result;
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);


        }

        protected void Print_Click(object sender, EventArgs e)
        {

            //showreport();
            Response.Redirect("printreport.aspx");
        }

        protected void CheckAll_CheckedChanged(object sender, EventArgs e)
        {
            foreach (ListItem item in CheckBoxList1.Items)
            {
                item.Selected = CheckAll.Checked;
            }
        }

        protected void CheckBoxList1_SelectedIndexChanged(object sender, EventArgs e)
        {
            bool isAllChecked = true;
            foreach (ListItem item in CheckBoxList1.Items)
            {
                if (!item.Selected)
                {
                    isAllChecked = false;
                    break;
                }
            }

            CheckAll.Checked = isAllChecked;
        }

        //protected void drp_flat_type_SelectedIndexChanged(object sender, EventArgs e)
        //{
        //    btnAdd_Click(sender, e);
        //}

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            maintenance_Gridbind();
        }

        protected void btnAdd_Click(object sender, EventArgs e)  //method to Open the modal and bind grid of bills in add modal
        {
            // Set today's date to txt_date
            txt_date.Text = DateTime.Now.ToString("yyyy-MM-dd");
            {
                BtnPanel.Visible = true;

                int i = 1;
                float total = 0;
                Maintenance1.Sql_Operation = "exfetch";
                Maintenance1.Society_Id = society_id.Value;

                var result = bL_Maintenance.Add_Click(Maintenance1);
                if (result != null)
                {
                    if (result.Rows.Count > 0)
                    {
                        BtnPanel.Visible = true;
                    }
                    else
                    {
                        BtnPanel.Visible = false;
                        lblMsg.Text = "No maintanance Added!";
                    }
                    dt1 = result;
                    ViewState["expenseData"] = dt1;
                    var flat = bL_Maintenance.getflat(Maintenance1);
                    dt1.Columns.Add("amount_per_flat", typeof(decimal));

                    foreach (DataRow row in dt1.Rows)
                    {
                        int count = flat.Flat == 0 ? 1 : flat.Flat;
                        row["amount_per_flat"] = Math.Round(Convert.ToDecimal(row["amount"].ToString()) / count, 2);
                    }

                    dt1.AcceptChanges();

                    expenseGrid.DataSource = dt1;
                    expenseGrid.DataBind();

                }
            }
        }

        //public static class NumberToWords
        //{
        //    private static string[] units = { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" };
        //    private static string[] teens = { "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen" };
        //    private static string[] tens = { "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety" };

        //    public static string ConvertToWords(int number)
        //    {
        //        if (number == 0) return "Zero";
        //        if (number < 0) return "Minus " + ConvertToWords(Math.Abs(number));

        //        string words = "";

        //        if ((number / 1000) > 0)
        //        {
        //            words += ConvertToWords(number / 1000) + " Thousand ";
        //            number %= 1000;
        //        }

        //        if ((number / 100) > 0)
        //        {
        //            words += ConvertToWords(number / 100) + " Hundred ";
        //            number %= 100;
        //        }

        //        if (number > 0)
        //        {
        //            if (words != "") words += "and ";
        //            if (number < 10)
        //                words += units[number];
        //            else if (number < 20)
        //                words += teens[number - 10];
        //            else
        //            {
        //                words += tens[number / 10];
        //                if ((number % 10) > 0)
        //                    words += " " + units[number % 10];
        //            }
        //        }

        //        return words;
        //    }
        //}
        [System.Web.Services.WebMethod]
        public static string GetBillHtml(string billId)
        {
            int id = Convert.ToInt32(billId);
            var bL_Maintenance = new BL_Maintenance_Master();
            var Maintenance1 = new maintenance
            {
                Sql_Operation = "Select",
                n_m_id = id
            };

            var result = bL_Maintenance.select_maintenance_details(Maintenance1);
             
            // Get Charges for this Bill
            Maintenance1.Sql_Operation = "exfetch";
            Maintenance1.build_id = result.build_id;
            Maintenance1.Date = result.M_Date;

            DataTable charges = bL_Maintenance.Add_Click(Maintenance1);

            // Build the HTML string
            decimal total = 0;
            string rows = "";

            for (int i = 0; i < charges.Rows.Count; i++)
            {
                decimal amount = Convert.ToDecimal(charges.Rows[i]["f_amount"]);
                total += amount;

                rows += $"<tr>" +
                        $"<td style='padding:5px'>{i + 1}</td>" +
                        $"<td style='padding:5px'>{charges.Rows[i]["ex_details"]}</td>" +
                        $"<td style='padding:5px'>₹ {amount}</td>" +
                        $"</tr>";
            }

            string totalInWords = NumberToWords(total);

            string html = $@"
        <div style='padding:20px; font-family:sans-serif;'>
        <h3 style='text-align:center;'>MAINTENANCE BILL</h3>
        <p><strong>Owner Name:</strong> {result.owner_name}</p>
        <p><strong>Flat No:</strong> {result.flat_no} | <strong>Wing:</strong> {result.wing_name}</p>
        <p><strong>Bill Date:</strong> {result.M_Date:dd MMM yyyy} | <strong>Due Date:</strong> {result.Due_Date:dd MMM yyyy}</p>
        
        <table border='1' width='100%' cellpadding='5' cellspacing='0' style='border-collapse: collapse;'>
            <thead>
                <tr>
                    <th>Sr. No</th>
                    <th>Nature of Charges</th>
                    <th>Amount</th>
                </tr>
            </thead>
            <tbody>
                {rows}
                <tr>
                    <td colspan='2' style='text-align:right'><strong>Total</strong></td>
                    <td><strong>₹ {total}</strong></td>
                </tr>
            </tbody>
        </table>

        <p><strong>Amount in Words:</strong> {totalInWords} rupees</p>
        <p><em>Do follow rules and regulations.</em></p>
        <p style='text-align:right;'>For Gokuldham<br/><strong>HON-SECRETARY</strong></p>
    </div>";

            return html;
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                var lblAmtForward = (Label)e.Item.FindControl("Label11");
                var trAmtForward = (HtmlTableRow)e.Item.FindControl("trAmtForward");

                decimal amtForward = 0;

                if (lblAmtForward != null)
                    decimal.TryParse(lblAmtForward.Text, out amtForward);

                if (amtForward == 0)
                    trAmtForward.Visible = false;


                DataRowView row = (DataRowView)e.Item.DataItem;

                // Convert col1_name...col30_name into a new table
                DataTable chargesTable = new DataTable();
                //chargesTable.Columns.Add("SrNO");
                chargesTable.Columns.Add("ChargeName");
                chargesTable.Columns.Add("Amount");

                string tax_interest_amt = row["tax_interest_amt"]?.ToString();

                

                for (int i = 1; i <= 30; i++)
                {

                    string nameCol = $"col{i}_name";
                    string amtCol = $"col{i}_amount";

                    if (row.DataView.Table.Columns.Contains(nameCol))
                    {
                        string chargeName = row[nameCol]?.ToString();
                        string amount = row[amtCol]?.ToString();
                        
                     

                        if (!string.IsNullOrWhiteSpace(chargeName)) // Only add if name exists
                        {
                            chargesTable.Rows.Add(chargeName, amount);
                        }

                      

                    }
                }

                if (tax_interest_amt != "0")
                {
                    chargesTable.Rows.Add("Late Interest Fees", tax_interest_amt);
                }

                // Bind nested Repeater
                Repeater rptCharges = (Repeater)e.Item.FindControl("billCharges");
                rptCharges.DataSource = chargesTable;
                rptCharges.DataBind();
            }
        }

        protected void btnViewBill_Command(object sender, CommandEventArgs e)
        {
            Maintenance1.n_m_id = Convert.ToInt32(e.CommandArgument.ToString());
            Maintenance1.Sql_Operation = "Select";
            Maintenance1.Society_Id = society_id.Value;
            // If you're filtering by n_m_id = 1

            DataTable dt = bL_Maintenance.get_maintanance(Maintenance1);
            ViewState["bill"] = dt;
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            //  bill.Update();
            ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "$('#printModal').modal('show');", true);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (txt_per_sqft_rate.Text.Trim() == "" || txt_2w_rate.Text.Trim() == "" || txt_4w_rate.Text.Trim() == "" || txt_gen_day.Text.Trim() == "" || txt_due_period.Text.Trim() == "")
            {
                return;
            }

            runprocSettings("insert");
            ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "SuccessEntry()", true);
            ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "$('#settingModal').modal('hide');", true);


        }
        protected async void generate_regular_Click(object sender, EventArgs e)  //method to generate regular bill
        {
            Maintenance1.Society_Id = Session["society_id"].ToString();
            Maintenance1.Bill_No = 1;
            DataTable dt = bL_Maintenance.executeMaintanence(Maintenance1);
            maintenance_Gridbind();

            if (dt.Rows.Count < 1)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "FailedEntry()", true);
                return;

            }

            ScriptManager.RegisterStartupScript(this, GetType(), "showPrintModal", "SuccessEntryy()", true);

            //DataTable dt = bL_Maintenance.getTokens(1, Session["society_id"].ToString());

            foreach (DataRow row in dt.Rows)
            {
                notice.User_Id = Convert.ToInt32(row["owner_id"].ToString());
                notice.UserType = row["type"].ToString();
                notice.Notification_id = Convert.ToInt32(row["maintenance_id"].ToString());
                notice.Notification_Type = "Maintenance";
                notice.Body = "New Maintenance Added";
                notice.Society_Id = Session["society_id"].ToString();
                bL_Notice.send_notification(notice);
                generate_notification(row["token"].ToString());
            }
        }


        protected async void generate_notification(string token)
        {
            var Fcm = new FirebaseCloudMessaging();
            string result1 = await Fcm.SendNotificationAsync(token, "Maintenance", "New Maintenance Added");
        }


        public void runproc(String operation)
        {

            if (n_m_id.Value != "")
                Maintenance1.n_m_id = Convert.ToInt32(n_m_id.Value);
            Maintenance1.Sql_Operation = operation;
            var result = bL_Maintenance.select_maintenance_details(Maintenance1);

            n_m_id.Value = result.n_m_id.ToString();
            //building_id.Value = result.build_id.ToString();
            txt_date.Text = result.M_Date.ToString("yyyy-MM-dd");

            //wing_id.Value = result.wing_id.ToString();
            txt_amount.Text = result.M_Total.ToString();

            m_bill_status.Value = result.Status.ToString();

            if (result.Status)
            {
                Panel1.Enabled = false;

            }
            else
                Panel1.Enabled = true;

        }

        protected void runprocSettings(String operation)
        {
            if (operation == "insert")
            {
                Maintenance1.Society_Id = Session["society_id"].ToString();
                Maintenance1.Sql_Operation = "insert";
                Maintenance1.Per_Sqf_Rate = Convert.ToInt32(txt_per_sqft_rate.Text.Trim());
                Maintenance1.Two_W_Rate = Convert.ToInt32(txt_2w_rate.Text.Trim());
                Maintenance1.Four_W_Rate = Convert.ToInt32(txt_4w_rate.Text.Trim());

                Maintenance1.Gen_Date_Int = Convert.ToInt32(txt_gen_day.Text.Trim());
                Maintenance1.due_period = Convert.ToInt32(txt_due_period.Text.Trim());
                Maintenance1.Auto_Gen = chk_auto_gen.Checked;
                bL_Maintenance.updateSettings(Maintenance1);
            }

            if (operation == "select")
            {
                Maintenance1.Society_Id = Session["society_id"].ToString();
                Maintenance1.Sql_Operation = "select";
                var result = bL_Maintenance.select_settings(Maintenance1);

                txt_per_sqft_rate.Text = result.Per_Sqf_Rate.ToString();
                txt_2w_rate.Text = result.Two_W_Rate.ToString();
                txt_4w_rate.Text = result.Four_W_Rate.ToString();
                txt_gen_day.Text = result.Gen_Date_Int.ToString();
                txt_due_period.Text = result.due_period.ToString();
                chk_auto_gen.Checked = result.Auto_Gen;
            }
        }

        protected void showHideGenerateBillBtn()
        {
            Maintenance1.Society_Id = Session["society_id"].ToString();
            Maintenance1.Sql_Operation = "select";
            var result = bL_Maintenance.select_settings(Maintenance1);
            generateBill.Visible = !result.Auto_Gen;
        }

        protected void Unnamed_ServerClick(object sender, EventArgs e)
        {
            runprocSettings("select");
        }


        public static string NumberToWords(decimal number)
        {
            if (number == 0)
                return "Zero Rupees Only";

            string words = "";

            // Split into rupees and paise
            int rupees = (int)Math.Floor(number);
            int paise = (int)Math.Round((number - rupees) * 100);

            words = ConvertNumberToWords(rupees) + " Rupees";

            if (paise > 0)
            {
                words += " and " + ConvertNumberToWords(paise) + " Paise";
            }

            words += " Only";

            return words.Trim();
        }

        private static string ConvertNumberToWords(int number)
        {
            if (number == 0)
                return "Zero";

            if (number < 0)
                return "Minus " + ConvertNumberToWords(Math.Abs(number));

            string words = "";

            if ((number / 10000000) > 0)
            {
                words += ConvertNumberToWords(number / 10000000) + " Crore ";
                number %= 10000000;
            }

            if ((number / 100000) > 0)
            {
                words += ConvertNumberToWords(number / 100000) + " Lakh ";
                number %= 100000;
            }

            if ((number / 1000) > 0)
            {
                words += ConvertNumberToWords(number / 1000) + " Thousand ";
                number %= 1000;
            }

            if ((number / 100) > 0)
            {
                words += ConvertNumberToWords(number / 100) + " Hundred ";
                number %= 100;
            }

            if (number > 0)
            {
                if (words != "")
                    words += "and ";

                string[] unitsMap = { "Zero", "One", "Two", "Three", "Four", "Five", "Six",
                      "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve",
                      "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
                      "Eighteen", "Nineteen" };

                string[] tensMap = { "Zero", "Ten", "Twenty", "Thirty", "Forty", "Fifty",
                     "Sixty", "Seventy", "Eighty", "Ninety" };

                if (number < 20)
                    words += unitsMap[number];
                else
                {
                    words += tensMap[number / 10];
                    if ((number % 10) > 0)
                        words += " " + unitsMap[number % 10];
                }
            }

            return words.Trim();
        }

        protected void billCharges_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                object amount = DataBinder.Eval(e.Item.DataItem, "Amount");
                if (amount == DBNull.Value || amount == null)
                {
                    HtmlTableRow row = (HtmlTableRow)e.Item.FindControl("trItem");
                    row.Visible = false; // Hide the row
                }
            }
        }
    }
}
