using BusinessLogic.BL;
using DBCode.DataClass;
using Society2024;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class MaintenanceReceipt : System.Web.UI.Page
    {

        receipt billReceipt = new receipt();
        BL_Receipt bLreceipt = new BL_Receipt();

        private string PaymentMode
        {
            get { return ViewState["PaymentMode"]?.ToString() ?? "Cheque"; }
            set { ViewState["PaymentMode"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
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

            if (!IsPostBack)
            {

                LoadOwners();
                InitializePaymentMode();
                gridShow();
            }
        }

        protected void gvPayments_RowCommand(object sender, GridViewCommandEventArgs e)
        {

            billReceipt.Receipt_Id = Convert.ToInt32(e.CommandArgument);
            billReceipt.Sql_Operation = "getreceipt";
            DataTable dt = bLreceipt.view_bill(billReceipt);

            if (dt.Rows.Count < 1)
            {
                return;
            }
            // Bind resident info
            lblResidentName.Text = dt.Rows[0]["name"].ToString();

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

            lblPaymentMode.Text = paymentMode;
            lblChequeNumber.Text = chequeNumber;

            lblChequeDate.Text = dt.Rows[0]["date"].ToString();
            lblBankName.Text = dt.Rows[0]["bank_name"].ToString();
            lblPaymentAmount.Text = "₹ " + dt.Rows[0]["paid_amount"].ToString();

            gvSelectedBills.DataSource = dt;
            gvSelectedBills.DataBind();
            //lblRemarks.Text = remarks;

            // Show modal using Bootstrap
            ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#paymentSummaryModal').modal('show');", true);
        }

        protected void gridShow()
        {
            billReceipt.Society_Id = Session["society_id"].ToString();
            billReceipt.Sql_Operation = "Grid_Show";
            
            DataTable dt = bLreceipt.grid_show(billReceipt);
            ViewState["dirState"] = dt;
            gvPayments.DataSource = dt;
            gvPayments.DataBind();
        }
        protected void LoadOwners()
        {
            try
            {
                DataTable dt = new DataTable();
                dt = bLreceipt.fill_list("ResidentFill", 0, Session["society_id"].ToString());
                Repeater1.DataSource = dt;
                Repeater1.DataBind();
            }
            catch (Exception ex)
            {
                ShowMessage("Error loading residents: " + ex.Message, "danger");
            }
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            flat_id.Value = e.CommandArgument.ToString();
            int flatId = Convert.ToInt32(flat_id.Value);
            if (flatId != 0)
            {

                LoadOwnerBills(flatId);

                if (PaymentMode == "PDC")
                {
                    LoadPDCCheques(flatId);
                }

            }
            else
            {
                pnlBillDetails.Visible = false;
                lblTotalAmount.Text = "0.00";
            }

        }
        private void LoadOwnerBills(int flatId)
        {
            try
            {

                DataTable dt = new DataTable();
                dt = bLreceipt.fill_list("GetBills", flatId, Session["society_id"].ToString());

                rptBills.DataSource = dt;
                rptBills.DataBind();

                pnlBillDetails.Visible = dt.Rows.Count > 0;

                if (dt.Rows.Count <= 0 || dt == null)
                {
                    ShowMessage("No pending bills found for this owner.", "info");
                }

            }
            catch (Exception ex)
            {
                ShowMessage("Error loading bills: " + ex.Message, "danger");
            }
        }

        private void LoadPDCCheques(int flatId)
        {
            try
            {

                DataTable dt = new DataTable();
                dt = bLreceipt.fill_list("GetPDCCheque", flatId, Session["society_id"].ToString());


                ddlPDCCheque.Items.Clear();
                ddlPDCCheque.Items.Add(new ListItem("-- Select PDC Cheque --", "0"));

                foreach (DataRow dr in dt.Rows)
                {
                    string displayText = string.Format("Cheque: {0} - Date: {1:dd/MM/yyyy} - Amt: ₹{2:N2}",
                     dr["chqno"],
                         dr["che_date"],
                         dr["che_amount"]);

                    string value = string.Join("|",
                         dr["pdc_rem_id"],
                         dr["chqno"],
                        Convert.ToDateTime(dr["che_date"]).ToString("yyyy-MM-dd"),
                        dr["bank_name"],

                       dr["che_amount"]);

                    ListItem item = new ListItem(displayText, value);
                    ddlPDCCheque.Items.Add(item);
                }

            }
            catch (Exception ex)
            {
                ShowMessage("Error loading PDC cheques: " + ex.Message, "danger");
            }
        }


        protected void btnChequeMode_Click(object sender, EventArgs e)
        {
            PaymentMode = "Cheque";
            UpdatePaymentModeUI();
            ClearChequeDetails();
        }

        protected void btnPDCMode_Click(object sender, EventArgs e)
        {
            PaymentMode = "PDC";
            UpdatePaymentModeUI();

            if (flat_id.Value != "0")
            {
                LoadPDCCheques(Convert.ToInt32(flat_id.Value));
            }
        }

        protected void ddlPDCCheque_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddlPDCCheque.SelectedValue != "0")
            {
                // Auto-fill cheque details from PDC
                string[] parts = ddlPDCCheque.SelectedValue.Split('|');

                if (parts.Length >= 5)
                {
                    txtChequeNo.Text = parts[1];
                    txtChequeDate.Text = parts[2];
                    txtBankName.Text = parts[3];
                    txtAmt.Text = parts[4];

                    // Disable fields for PDC
                    txtChequeNo.Enabled = false;
                    txtChequeDate.Enabled = false;
                    txtBankName.Enabled = false;
                    txtAmt.Enabled = false;
                }
            }
            else
            {
                ClearChequeDetails();

                // Enable fields if in regular cheque mode
                if (PaymentMode == "Cheque")
                {
                    txtChequeNo.Enabled = true;
                    txtChequeDate.Enabled = true;
                    txtBankName.Enabled = true;
                    txtAmt.Enabled = true;
                }
            }
        }

        protected void btnSavePayment_Click(object sender, EventArgs e)
        {
            if (ValidatePayment())
            {
                var result = SavePayment();
                hfSelectedBills.Value = "";
                gridShow();
                if (result.Sql_Result == "Done")
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "SuccessEntryy();", true);

                }
                else
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "FailedEntryy();", true);

                }

            }
        }


        private void InitializePaymentMode()
        {
            PaymentMode = "Cheque";
            UpdatePaymentModeUI();
        }

        private void UpdatePaymentModeUI()
        {
            // Update button styles
            if (PaymentMode == "Cheque")
            {
                btnChequeMode.CssClass = "payment-btn active";
                btnPDCMode.CssClass = "payment-btn";
                pnlPDCSelection.Visible = false;

                // Enable manual entry
                txtChequeNo.Enabled = true;
                txtChequeDate.Enabled = true;
                txtBankName.Enabled = true;
                txtAmt.Enabled = true;
            }
            else // PDC
            {
                btnChequeMode.CssClass = "payment-btn";
                btnPDCMode.CssClass = "payment-btn active";
                pnlPDCSelection.Visible = true;

                // Disable manual entry initially
                txtChequeNo.Enabled = false;
                txtChequeDate.Enabled = false;
                txtBankName.Enabled = false;
                txtAmt.Enabled = false;
            }
        }


        private bool ValidatePayment()
        {
            if (flat_id.Value == "0")
            {
                ShowMessage("Please select an owner.", "warning");
                return false;
            }

            if (hfSelectedBills.Value == null || hfSelectedBills.Value == "")
            {
                ShowMessage("Please select at least one bill to pay.", "warning");
                return false;
            }

            if (PaymentMode == "PDC" && ddlPDCCheque.SelectedValue == "0")
            {
                ShowMessage("Please select a PDC cheque or switch to regular cheque mode.", "warning");
                return false;
            }

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

            return true;
        }

        private receipt SavePayment()
        {
            var result = new receipt();
            try
            {


                // Prepare bill details string
                billReceipt.Sql_Operation = "INSERT";
                billReceipt.Society_Id = Session["society_id"].ToString();
                billReceipt.BillDetails = hfSelectedBills.Value;
                billReceipt.Flat_Id = Convert.ToInt32(flat_id.Value);
                billReceipt.Paid_Amount = Convert.ToDecimal(txtAmt.Text);
                billReceipt.Pay_Mode = PaymentMode;
                billReceipt.Cheque_No = txtChequeNo.Text.Trim();
                billReceipt.Cheque_Date = Convert.ToDateTime(txtChequeDate.Text);
                billReceipt.Bank_Name = txtBankName.Text;
                billReceipt.Remarks = txtRemarks.Text;
                billReceipt.Created_By = Session["UserId"].ToString();
                return bLreceipt.UpdateReceipt(billReceipt);


            }
            catch (Exception ex)
            {
                ShowMessage("Error saving payment: " + ex.Message, "danger");
            }

            return result;
        }

        private void ResetForm()
        {
            flat_id.Value = "0";
            PaymentMode = "Cheque";
            ddlPDCCheque.Items.Clear();
            ClearChequeDetails();
            txtRemarks.Text = string.Empty;
            pnlBillDetails.Visible = false;

            rptBills.DataSource = null;
            rptBills.DataBind();

            UpdatePaymentModeUI();
        }

        private void ClearChequeDetails()
        {
            txtChequeNo.Text = string.Empty;
            txtChequeDate.Text = string.Empty;
            txtBankName.Text = string.Empty;
            txtAmt.Text = string.Empty;
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

        protected void gvPayments_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["dirState"];
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
                gvPayments.DataSource = dtrslt;
                gvPayments.DataBind();
            }
        }

        //protected void gvPayments_Sorting(object sender, GridViewSortEventArgs e)
        //{
        //    DataTable dt = ViewState["dirState"] as DataTable;
        //    if (dt == null || dt.Rows.Count == 0)
        //        return;

        //    string sortDir = ViewState["sortdr"]?.ToString() ?? "Asc";

        //    if (sortDir == "Asc")
        //    {
        //        dt.DefaultView.Sort = e.SortExpression + " DESC";
        //        ViewState["sortdr"] = "Desc";
        //    }
        //    else
        //    {
        //        dt.DefaultView.Sort = e.SortExpression + " ASC";
        //        ViewState["sortdr"] = "Asc";
        //    }

        //    gvPayments.DataSource = dt;
        //    gvPayments.DataBind();
        //}

    }
}