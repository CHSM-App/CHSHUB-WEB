using BusinessLogic.MasterBL;
using System;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society2024
{
    public partial class society_receipt : System.Web.UI.Page
    {
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                Society_id.Value = Session["Society_id"].ToString();


            if (!IsPostBack)
            {
                showData();
                showhistory();

            }
        }

        private void showData()
        {
            details.Sql_Operation = "society_receipt";
            details.Name = "";
            details.Society_Id = Society_id.Value;
            var result = BL_Login.society_receipt(details);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            if (result != null && result.Rows.Count > 0 && result.Rows.Count > 0)
            {


                lblTotalDues.Text = result.Compute("Sum(amount)", string.Empty).ToString();
                lblOverdueMonths.Text = result.Rows.Count.ToString();
            }
            else
            {
                lblTotalDues.Text = "0";
                lblOverdueMonths.Text = "0";
            }


        }
        private void showhistory()
        {
            details.Sql_Operation = "show_history";
            details.Name = "";
            details.Society_Id = Society_id.Value;
            var result = BL_Login.show_receipt(details);
            GridView2.DataSource = result;
            ViewState["dirState"] = result;
            GridView2.DataBind();
            if (result != null && result.Rows.Count > 0 && result.Rows.Count > 0)
            {


                lblPaidThisYear.Text = result.Compute("Sum(paid_amount)", string.Empty).ToString();

            }
            else
            {
                lblPaidThisYear.Text = "0";

            }

        }
        // Method to handle the payment submission
        protected void SubmitPayment(object sender, EventArgs e)
        {
            string paymentAmount = txtPaymentAmount.Text;
            string paymentMode = ddlPaymentMode?.SelectedValue ?? "";

            if (string.IsNullOrEmpty(paymentAmount) || paymentAmount == "0" || string.IsNullOrEmpty(paymentMode))
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", "alert('Please fill all required fields.');", true);
                return;
            }


            try
            {
                // Correct variable name here
                details.Amount = Convert.ToDouble(txtPaymentAmount.Text);
                details.Paymode = ddlPaymentMode.SelectedValue;
                details.City = lblTotalDues.Text;
                details.Society_Id = Society_id.Value;
                BL_Login.InsertPayment(details);

                ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", "alert('Payment submitted successfully!');", true);

                // Clear selections & total
                Session["ReceiptTotal"] = 0.0;
                TextBox1.Text = "0.00";

                showData();
                showhistory();
                // Refresh grid
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", $"alert('Error: {ex.Message}');", true);
            }
        }


        protected void CheckBox1_CheckedChanged(object sender, EventArgs e)
        {
            try
            {
                double sessionTotal = 0.0;
                bool anyChecked = false;

                foreach (GridViewRow row in GridView1.Rows)
                {
                    CheckBox chk = (CheckBox)row.FindControl("CheckBox1"); // Replace "CheckBox1" with your actual CheckBox ID
                    Label amountText = (Label)row.FindControl("amount");
                    if (chk.Checked && chk != null)
                        if (amountText != null && double.TryParse(amountText.Text, out double amount))
                        {


                            anyChecked = true;
                            sessionTotal += amount;
                        }
                }


                // Update session and UI
                if (anyChecked)
                {

                    TextBox1.Text = sessionTotal.ToString("F2");
                }
                else
                {

                    TextBox1.Text = "0.00";
                }
            }
            catch (Exception ex)
            {
                // Optionally log or handle the error
            }
        }


        [System.Web.Services.WebMethod]
        public static object GetReceiptDetails(string receiptId)
        {
            try
            {
                // Example logic to fetch the receipt details based on receipt_id
                // Replace with your actual code to fetch data from your database
                BL_User_Login BL_Login = new BL_User_Login();
                Login_Details details = new Login_Details();
                details.Sql_Operation = "show_history";
                details.Name = "";
                details.Society_Id = "C10001";
                var result = BL_Login.show_receipt(details);
                //details.Sql_Operation = "show_receipt";
                //details.Name = "";
                //details.Branch_Id = Convert.ToInt32(receiptId);
                //var result = BL_Login.show_receipt(details);// Fetch receipt from database

                if (result != null && result.Rows.Count > 0)
                {
                    var receipt = new
                    {
                        Date = Convert.ToDateTime(result.Rows[0]["date"]).ToString("dd MMM yyyy"),
                        Amount = result.Rows[0]["paid_amount"].ToString(),
                        Mode = result.Rows[0]["paymode"].ToString(),
                        TxnRef = result.Rows[0]["society_id"].ToString(),
                        UpiId = result.Rows[0]["receipt_id"].ToString()  // Adjust based on your fields
                    };

                    return receipt;  // Return as JSON
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                // Handle exception if any
                return null;
            }
        }

        protected void btnReceipt_Command(object sender, CommandEventArgs e)
        {
            BL_User_Login BL_Login = new BL_User_Login();
            Login_Details details = new Login_Details();
            details.Sql_Operation = "show_history";
            details.Name = "";
            details.Society_Id = Session["Society_id"]?.ToString() ?? "C10001"; // fallback if needed

            var result = BL_Login.show_receipt(details);

            // Optional: You could filter result by receiptId from e.CommandArgument, if needed
            // string receiptId = e.CommandArgument.ToString();

            if (result != null && result.Rows.Count > 0)
            {
                lblModalDate.Text = Convert.ToDateTime(result.Rows[0]["date"]).ToString("dd MMM yyyy");
                lblModalAmount.Text = result.Rows[0]["paid_amount"].ToString();
                lblModalMode.Text = result.Rows[0]["paymode"].ToString();
                lblModalTxnRef.Text = result.Rows[0]["society_id"].ToString();
                lblModalUpiId.Text = result.Rows[0]["receipt_id"].ToString();  // Adjust based on your fields

                // ✅ ADD THIS LINE to keep History tab active after postback
                hdnActiveTab.Value = "historyTab";

                // Show the receipt modal
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "$('#receiptModal').modal('show');", true);
            }
        }
    }
        // PaymentDetails class to capture payment information
        public class PaymentDetails
    {
        public string Amount { get; set; }
        public string Mode { get; set; }
        public string Notes { get; set; }
        public string SocietyId { get; set; }
    }


}
