using BusinessLogic.BL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class VendorBillPayments : System.Web.UI.Page
    {
        BL_Society_Expense bL_Society = new BL_Society_Expense();
        Vendor vendor = new Vendor();
        BL_Vendor_bill bL_vendor_bill = new BL_Vendor_bill();

        receipt billReceipt = new receipt();
        BL_Receipt bLreceipt = new BL_Receipt();

        // Store payment mode in ViewState
        private string PaymentMode
        {
            get { return ViewState["PaymentMode"]?.ToString() ?? "Cheque"; }
            set { ViewState["PaymentMode"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {

                if (Session["name"] == null)
                {
                    Response.Redirect("login1.aspx");
                }

                fill_repeater();
                grid_show();
            }

            if (ScriptManager.GetCurrent(this.Page) != null)
            {
                if (ScriptManager.GetCurrent(this.Page).IsInAsyncPostBack)
                {
                    System.Diagnostics.Debug.WriteLine("✅ ASYNC POSTBACK");
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("❌ FULL POSTBACK");
                }
            }
        }

        protected void grid_show()
        {
            vendor.Society_Id = Session["society_id"].ToString();
            vendor.Sql_Operation = "Grid_Show";
            DataTable dt = bL_vendor_bill.grid_show(vendor);
            gvPayments.DataSource = dt;
            gvPayments.DataBind();
        }
        protected void fill_repeater()
        {
            //pnlBillDetails.Visible = false;
            DataTable dt = new DataTable();
            dt = bL_Society.fill_list("vendor_fill", Session["society_id"].ToString());
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            vendor_id.Value = e.CommandArgument.ToString();

            DataTable dt = new DataTable();
            dt = bL_vendor_bill.fill_bills("fill_bills", Convert.ToInt32(vendor_id.Value));

            temp.DataSource = dt;
            temp.DataBind();

            divBillDetails.Attributes["class"] = "d-block";

            //var classes = divBillDetails.Attributes["class"].Split(' ')
            //                                    .Where(c => c != "d-none");
            //divBillDetails.Attributes["class"] = string.Join(" ", classes);

            //if (!divBillDetails.Attributes["class"].Contains("d-block"))
            //{
            //    divBillDetails.Attributes["class"] += " d-block";
            //}

            //pnlBillDetails.Visible = dt.Rows.Count > 0;

        }

        protected void btnChequeMode_Click(object sender, EventArgs e)
        {
            PaymentMode = "Cheque";
            pnlCheque.Visible = true;
            pnlOnline.Visible = false;
            UpdatePaymentModeUI();
        }

        protected void btnPDCMode_Click(object sender, EventArgs e)
        {
            PaymentMode = "PDC";
            UpdatePaymentModeUI();
            pnlCheque.Visible = false;
            pnlOnline.Visible = true;
        }

        protected void btnSavePayment_Click(object sender, EventArgs e)
        {
            if (ValidatePayment())
            {
                SavePayment();
                grid_show();
                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#paymentModal').modal('hide');", true);
            }
            else
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#paymentModal').modal('show');", true);

            }
        }

        private void UpdatePaymentModeUI()
        {
            // Update button styles
            if (PaymentMode == "Cheque")
            {
                btnChequeMode.CssClass = "payment-btn active";
                btnPDCMode.CssClass = "payment-btn";

            }
            else // PDC
            {
                btnChequeMode.CssClass = "payment-btn";
                btnPDCMode.CssClass = "payment-btn active";

            }
        }


        private bool ValidatePayment()
        {
            if (pnlCheque.Visible)
            {

                if (string.IsNullOrWhiteSpace(txtChequeNo.Text))
                {
                    ShowMessage("Please enter cheque number.", "warning");
                    return false;
                }

                if (string.IsNullOrWhiteSpace(txtChequeDate.Text))
                {
                    ShowMessage("Please enter cheque date.", "warning");
                    return false;
                }

                if (string.IsNullOrWhiteSpace(txtBankName.Text))
                {
                    ShowMessage("Please enter bank name.", "warning");
                    return false;
                }

                

            }

            if (pnlOnline.Visible)
            {
                if (string.IsNullOrWhiteSpace(txtTransactionRef.Text))
                {
                    ShowMessage("Please enter Transaction ID.", "warning");
                    return false;
                }
                if (string.IsNullOrWhiteSpace(txtAmtOl.Text))
                {
                    ShowMessage("Please enter Amount", "warning");
                    return false;
                }
            }
            if (vendor_id.Value == "0")
            {
                ShowMessage("Please select an owner.", "warning");
                return false;
            }

            if (!FileUpload1.HasFile)
            {
                ShowMessage("Please select Bill Proof", "warning");
                return false;
            }




            return true;
        }

        private void SavePayment()
        {
            try
            {
                // 1. Vendor ID
                vendor.FilePath = UploadId();
                vendor.vendor_id =Convert.ToString(vendor_id.Value);
                vendor.BillIds = hfSelectedBills.Value;
                vendor.Sql_Operation = "INSERT";
                vendor.Society_Id = Session["society_id"].ToString();

                //if (btnChequeMode.CssClass.Contains("active"))
                //else if (btnPDCMode.CssClass.Contains("active"))

                if (pnlCheque.Visible)
                {
                    vendor.PayMode = "Cheque";
                    vendor.ChequeNo = txtChequeNo.Text.Trim();
                    vendor.ChequeDate = txtChequeDate.Text.Trim();
                    vendor.BankName = txtBankName.Text.Trim();

                }
                if (pnlOnline.Visible)
                {
                    vendor.PayMode = "Online";
                    vendor.TransactionRef = txtTransactionRef.Text.Trim() == "" ? null : txtTransactionRef.Text.Trim();

                }
                vendor.User_id = Convert.ToInt32(Session["UserId"]);
                vendor.Remark = txtRemarks.Text.Trim();
                //vendor.TotalAmount = txtAmtOl.Text.Trim() == "" ? txtAmtCqu.Text.Trim() : txtAmtOl.Text.Trim();
                decimal totalAmount = 0m;

                // Try to parse txtAmtOl; if empty or invalid, fallback to txtAmtCqu
                if (!decimal.TryParse(txtAmtOl.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                {
                    decimal.TryParse(txtAmtCqu.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount);
                }

                // Assign decimal value as string in invariant culture
              //  vendor.TotalAmount = totalAmount.ToString(CultureInfo.InvariantCulture);



                var result = bL_vendor_bill.saveVendorBill(vendor);
                // Example: Log or save data
                // SavePayment(vendorId, selectedBills, paymentMode, ...);

                if (result.Sql_Result == "Done")
                {
                    lblMessage.Text = "Payment saved successfully.";
                    lblMessage.CssClass = "alert alert-success";
                    lblMessage.Visible = true;

                }
                else
                {
                    lblMessage.Text = "Error saving payment.";
                    lblMessage.CssClass = "alert alert-danger";
                    lblMessage.Visible = true;
                }
                }
            catch (Exception ex)
            {
                lblMessage.Text = "Error: " + ex.Message;
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
            }
        }

        protected void gvPayments_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if(e.CommandName.ToString() == "ViewDetails")
            {

                billReceipt.Receipt_Id = Convert.ToInt32(e.CommandArgument);
                billReceipt.Sql_Operation = "getreceipt";
                billReceipt.Society_Id = Session["society_id"].ToString();
                DataTable dt = bL_vendor_bill.view_bill(billReceipt);

                if (dt.Rows.Count < 1)
                {
                    return;
                }
                // Bind resident info
                lblResidentName.Text = dt.Rows[0]["vendor_name"].ToString();

                string paymentMode = string.Empty;
                string chequeNumber = string.Empty;
                if (!string.IsNullOrEmpty(dt.Rows[0]["transaction_ref"].ToString()) && dt.Rows[0]["transaction_ref"].ToString().Contains(":"))
                {
                    var parts = dt.Rows[0]["transaction_ref"].ToString().Split(':');
                    if (parts.Length >= 2)
                    {
                        paymentMode = parts[0];
                        chequeNumber = parts[1];
                    }
                }

                if (paymentMode == "Online")
                {
                    pnlTransactionRef.Visible = true;
                    pnlBankPayInfo.Visible = false;
                }
                else
                {
                    pnlTransactionRef.Visible = false;
                    pnlBankPayInfo.Visible = true;
                }
                    lblPaymentMode.Text = paymentMode;
                lblChequeNumber.Text = chequeNumber;
                lblTransaction.Text = chequeNumber;
                lblChequeDate.Text = dt.Rows[0]["payment_date"].ToString();
                lblBankName.Text = dt.Rows[0]["bank_name"].ToString();
                lblPaymentAmount.Text = "₹ " + dt.Rows[0]["paid_amount"].ToString();

                gvSelectedBills.DataSource = dt;
                gvSelectedBills.DataBind();
                //lblRemarks.Text = remarks;

                // Show modal using Bootstrap
                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#paymentSummaryModal').modal('show');", true);
            }

        }

        private void ResetForm()
        {
            lblTotalAmount.Text = "0.00";
            PaymentMode = "Cheque";

            txtRemarks.Text = string.Empty;
            pnlBillDetails.Visible = false;

            //rptBills.DataSource = null;
            //rptBills.DataBind();

            UpdatePaymentModeUI();
        }


        private void ShowMessage(string message, string type)
        {
            lblMessage.Text = message;
            lblMessage.CssClass = "alert alert-" + type;
            lblMessage.Visible = true;

            // Auto-hide message after 5 seconds
            ScriptManager.RegisterStartupScript(this, GetType(), "hideMessage",
                "setTimeout(function() { $('.alert').fadeOut('slow'); }, 5000);", true);
        }

        protected string UploadId()
        {
             string relativeFolder = "/Documents/" + Session["society_name"] + "/vendor_bills/";
            string folderPath = Server.MapPath(relativeFolder);

            // Ensure folder exists
            System.IO.Directory.CreateDirectory(folderPath);

            if (FileUpload1.HasFile)
            {
                string originalFileName = System.IO.Path.GetFileName(FileUpload1.FileName);
                string extension = System.IO.Path.GetExtension(originalFileName);
                string baseName = System.IO.Path.GetFileNameWithoutExtension(originalFileName);

                string fileName = originalFileName;
                string filePath = System.IO.Path.Combine(folderPath, fileName);

                int count = 1;

                while (System.IO.File.Exists(filePath))
                {
                    fileName = $"{baseName}({count}){extension}";
                    filePath = System.IO.Path.Combine(folderPath, fileName);
                    count++;
                }

                FileUpload1.SaveAs(filePath);
                return relativeFolder + fileName;

            }

               return string.Empty; // return empty if no file uploaded 
        }

        protected void btnViewFile_Command(object sender, CommandEventArgs e)
        {
            try
            {
                string rawPath = e.CommandArgument?.ToString()?.Trim();

                // Validate path first
                if (string.IsNullOrEmpty(rawPath))
                {
                    iframeFile.Attributes["src"] = "";
                    lblFileMessage.Text = "No file path found or file not uploaded.";
                    lblFileMessage.Visible = true;

                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
                    return;
                }

                // Extract relative path starting from ~/Documents/
                string filePath = Regex.Replace(rawPath, @"^.*(?=Documents)", "~/");

                string physicalPath = Server.MapPath(filePath);

                // Check if file exists
                if (!System.IO.File.Exists(physicalPath))
                {
                    iframeFile.Attributes["src"] = "";
                    lblFileMessage.Text = "File not found or path is invalid.";
                    lblFileMessage.Visible = true;

                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
                    return;
                }

                // If file exists, show it in iframe
                iframeFile.Attributes["src"] = ResolveUrl(filePath);
                lblFileMessage.Visible = false;

                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
            }
            catch
            {
                iframeFile.Attributes["src"] = "";
                lblFileMessage.Text = "An error occurred while loading the document.";
                lblFileMessage.Visible = true;

                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
            }
        }

    }
}