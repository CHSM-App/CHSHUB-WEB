using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using DocumentFormat.OpenXml.Drawing.Diagrams;
using DocumentFormat.OpenXml.Office2016.Drawing.Command;
using DocumentFormat.OpenXml.Wordprocessing;
using Newtonsoft.Json;
using Society2024;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Interop;
using Utility.DataClass;
using static System.Windows.Forms.VisualStyles.VisualStyleElement;
using Button = System.Web.UI.WebControls.Button;
using WebListItem = System.Web.UI.WebControls.ListItem;
using WebCheckBox = System.Web.UI.WebControls.CheckBox;
using System.Globalization;


namespace Society
{
    public class BillItem
    {
        public string Description { get; set; }
        public decimal Quantity { get; set; }
        public decimal unit_price { get; set; }
        public decimal tax_percent { get; set; }
        public decimal Amount { get; set; }
        public int Warranty { get; set; }

    }


    public partial class VendorBill : System.Web.UI.Page
    {
        Vendor vendor = new Vendor();
        BL_Vendor_Master bL_Vendor = new BL_Vendor_Master();
        Inventory inventory = new Inventory();
        Society_Expense society = new Society_Expense();
        Society_Member member = new Society_Member();
        BL_Society_Expense bL_Society = new BL_Society_Expense();
        BL_Vendor_bill bL_vendor_bill = new BL_Vendor_bill();
        BL_Society_Member_Master bL_Society_member = new BL_Society_Member_Master();
        DataTable approverdt = new DataTable();
        BL_Inventory_Master bL_Inventory = new BL_Inventory_Master();
        Notice notice = new Notice();
        BL_Society_Master bl_support = new BL_Society_Master();
        BL_Notice_Master bL_Notice = new BL_Notice_Master();
        BL_Staff bL_Staff = new BL_Staff();
        receipt billReceipt = new receipt();
        BL_Receipt bLreceipt = new BL_Receipt();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }

            if (!IsPostBack)
            {

                ViewState["SelectedStaff"] = CreateSelectedStaffTable();
                ViewState["SelectedItems"] = CreateBillItemsTable();
                gridBind();
                list_fill();
                txtBillDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
                txtPaymentMonth.Text = DateTime.Now.ToString("yyyy-MM-dd");
                txtcheqdate.Text = DateTime.Now.ToString("yyyy-MM-dd");

                fill_repeater();
                FillStaffType();


                string target = Request["__EVENTTARGET"];
                string argument = Request["__EVENTARGUMENT"];


            }
            else
            {
                string target = Request["__EVENTTARGET"];
                string argument = Request["__EVENTARGUMENT"];
                if (ViewState["IsApproved"] != null && (bool)ViewState["IsApproved"])
                {
                    if (paymentSection != null)
                    {
                        paymentSection.Style["display"] = "none";
                    }
                    ViewState["IsApproved"] = false; // Reset flag
                }
            }

        }
        private void HideAllBillSections()
        {
            // Basic fields hide
            if (billNumberDiv != null) billNumberDiv.Style["display"] = "none";
            if (billDateDiv != null) billDateDiv.Style["display"] = "none";
            if (paymentMonthDiv != null) paymentMonthDiv.Style["display"] = "none";

            // All sections hide
            if (staff != null) staff.Style["display"] = "none";
            if (vendorSection != null) vendorSection.Style["display"] = "none";
            if (itemSection != null) itemSection.Style["display"] = "none";
            if (approvelSection != null) approvelSection.Style["display"] = "none";
            if (paymentSection != null) paymentSection.Style["display"] = "none";
            if (serviceSection != null) serviceSection.Style["display"] = "none";
        }


        private void FillStaffType()
        {
            staff Staff = new staff();

            Staff.Sql_Operation = "fill_staff";
            Staff.Society_Id = society_id.Value;

            DataTable dt = bL_Staff.getstaffdetails(Staff);

            ddlStaffType.DataSource = dt;
            ddlStaffType.DataTextField = "role";
            ddlStaffType.DataValueField = "role_id";
            ddlStaffType.DataBind();
            ddlStaffType.Items.Insert(0, new WebListItem("Select Staff Type", ""));

        }
        protected void fill_repeater()
        {

            DataTable dt = new DataTable();
            dt = bL_Society.fill_list("vendor_fill", Session["society_id"].ToString());
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
        }
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            // Vendor ID save
            vendor_name_id.Value = e.CommandArgument.ToString();

            // Vendor Name TextBox
            TextBox2.Text = ((LinkButton)e.CommandSource).Text;

            // GST Number TextBox
            TextBox1.Text = e.CommandName.ToString();

            // Hide dropdown after selection
            drp_Container.Style["display"] = "none";
        }

      

        protected void GridView3_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Approve")
            {
                string userId = e.CommandArgument.ToString();
               
            }
            else if (e.CommandName == "Reject")
            {
                string userId = e.CommandArgument.ToString();
              
            }
        }


        protected void gridBind()
        {
            DataTable dt = new DataTable();
            vendor.Sql_Operation = "Grid_Show";
            vendor.Society_Id = Session["society_id"].ToString();
            dt = bL_vendor_bill.getVendorBill(vendor);
            gvBills.DataSource = dt;
            ViewState["dirState"] = dt;
            gvBills.DataBind();
        }


        protected void GridView3_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {

                GridView3.ShowHeader = false;
                GridView3.GridLines = GridLines.None;
                DataTable dt = (DataTable)ViewState["user_data"];
                System.Web.UI.WebControls.Label status = (System.Web.UI.WebControls.Label)e.Row.FindControl("status");
                System.Web.UI.WebControls.Button btn_approve = (System.Web.UI.WebControls.Button)e.Row.FindControl("btn_approved");
                System.Web.UI.WebControls.Label user_id = (System.Web.UI.WebControls.Label)e.Row.FindControl("user_id");



            }

        }
        protected void GridView3_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            if (ViewState["user_data"] != null)
            {
                DataTable approverdt = (DataTable)ViewState["user_data"];

                // Safety check: Ensure index is within range
                if (e.RowIndex >= 0 && e.RowIndex < approverdt.Rows.Count)
                {
                    approverdt.Rows.RemoveAt(e.RowIndex); // Remove the row from the DataTable
                    ViewState["user_data"] = approverdt; // Save the updated DataTable in ViewState
                }

                // Rebind GridView3 to reflect the deletion
                ViewState["user_data"] = approverdt;
                GridView3.DataSource = approverdt;
                GridView3.DataBind();
                list_fill();

                // Hide payment section server-side
                paymentSection.Style["display"] = "block";

                ViewState["IsApproved"] = false;
                UpdatePanel2.Update();

                // ✅ MAIN FIX: Set JavaScript flag to keep payment hidden
                string script = @"
                keepPaymentHidden = false;
                hideModal('approversModal');
                var paySection = document.getElementById('" + paymentSection.ClientID + @"');
        if (paySection) {
            paySection.style.display = 'block';
        }
    ";
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowPaymentSection", script, true);
            }
        }


        protected string GetStatusBadge(string status)
        {
            string cssClass, statusText;

            switch (status.ToLower())
            {
                case "pending":
                    cssClass = "status-pending";
                    statusText = "Pending";
                    break;
                case "approved":
                    cssClass = "status-approved";
                    statusText = "Approved";
                    break;
                case "rejected":
                    cssClass = "status-rejected";
                    statusText = "Rejected";
                    break;
                case "paid":
                    cssClass = "status-paid";
                    statusText = "Paid";
                    break;
                default:
                    cssClass = "status-pending";
                    statusText = status;
                    break;
            }

            return $"<span class='status-badge {cssClass}'>{statusText}</span>";
        }

        // ✅ NEW METHOD: Clear Payment Mode Selection
        private void ClearPaymentModeSelection()
        {
            try
            {
                // Hide all payment panels
                if (Panelcheque != null) Panelcheque.Visible = false;
                if (panelonline != null) panelonline.Visible = false;
                if (Panelcash != null) Panelcash.Visible = false;

                // Clear payment textboxes
                if (txtcheqno != null) txtcheqno.Text = "";
                if (txtcheqdate != null) txtcheqdate.Text = DateTime.Now.ToString("yyyy-MM-dd");
                if (txtbank != null) txtbank.Text = "";
                if (txtcheqamount != null) txtcheqamount.Text = "";

                if (txttrasaction != null) txttrasaction.Text = "";
                if (txtonlineamount != null) txtonlineamount.Text = "";

                if (txtcashamount != null) txtcashamount.Text = "";

                if (txtre != null) txtre.Text = "";

                // Clear active payment hidden field
                if (hdnActivePayment != null) hdnActivePayment.Value = "";

                // Update the UpdatePanel
                if (UpdatePanel2 != null) UpdatePanel2.Update();

                System.Diagnostics.Debug.WriteLine("✅ Payment mode selection cleared");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"⚠️ Error clearing payment mode: {ex.Message}");
            }
        }
        private Tuple<bool, string, List<string>> SaveStaffPaymentBillsWithValidation()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("=== SaveStaffPaymentBills STARTED ===");

                // ✅ 1. Validate Staff Type
                if (string.IsNullOrEmpty(ddlStaffType.SelectedValue))
                {
                    return Tuple.Create(false, "Please select Staff Type", new List<string>());
                }

                // ✅ 2. Collect Selected Staff
                List<int> staffIds = new List<int>();
                List<string> staffNames = new List<string>();
                List<decimal> salaries = new List<decimal>();

                foreach (GridViewRow row in gvStaffList.Rows)
                {
                    WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");

                    if (chkStaff != null && chkStaff.Checked)
                    {
                        Label lblStaffId = (Label)row.FindControl("lblStaffId");
                        Label lblStaffName = (Label)row.FindControl("lblStaffName");
                        System.Web.UI.WebControls.TextBox txtSalary =
                            (System.Web.UI.WebControls.TextBox)row.FindControl("txtSalary");

                        if (lblStaffId != null && lblStaffName != null && txtSalary != null)
                        {
                            decimal salary = 0;
                            if (!decimal.TryParse(txtSalary.Text, out salary) || salary <= 0)
                            {
                                return Tuple.Create(false, $"Please enter valid salary for {lblStaffName.Text}", new List<string>());
                            }

                            staffIds.Add(Convert.ToInt32(lblStaffId.Text));
                            staffNames.Add(lblStaffName.Text);
                            salaries.Add(salary);
                        }
                    }
                }

                // ✅ 3. Validate Selection
                if (staffIds.Count == 0)
                {
                    return Tuple.Create(false, "Please select at least one staff member", new List<string>());
                }

                // ✅ 4. Get Payment Month
                DateTime paymentMonth;
                if (string.IsNullOrWhiteSpace(txtPaymentMonth.Text))
                {
                    paymentMonth = DateTime.Now;
                }
                else if (!DateTime.TryParse(txtPaymentMonth.Text, out paymentMonth))
                {
                    return Tuple.Create(false, "Invalid Payment Month", new List<string>());
                }

                // ✅ 5. Calculate Total
                decimal totalSalary = salaries.Sum();

                // ✅ 6. Create Bill
                int roleId = Convert.ToInt32(ddlStaffType.SelectedValue);
                string roleName = ddlStaffType.SelectedItem.Text;
                string billNumber = $"STAFF-{roleId}-{paymentMonth:yyyyMM}-{DateTime.Now:HHmmss}";

                string staffIdsStr = string.Join(",", staffIds);
                string salariesStr = string.Join(",", salaries.Select(s => s.ToString("0.00")));
                string staffNamesStr = string.Join(", ", staffNames);

                // ✅ 7. Format staff list for display
                string staffListDisplay = FormatStaffListForDisplay(staffNames, salaries);

                vendor.BillNo = billNumber;
                vendor.Sql_Operation = "INSERT";
                vendor.BillDate = paymentMonth;
                vendor.Service = 0; // Staff Payment
                vendor.vendor_id = staffIdsStr;
                vendor.Note = $"STAFF_IDS:{staffIdsStr}|SALARIES:{salariesStr}";
                vendor.SubTotal = totalSalary;
                vendor.TaxAmount = 0m;
                vendor.TotalAmount = totalSalary;
                vendor.Society_Id = Session["society_id"].ToString();
                vendor.User_id = Convert.ToInt32(Session["UserId"]);
                vendor.Description = $"Salary Payment | Role: {roleName} | Staff: {staffNamesStr} | Month: {paymentMonth:MMM-yyyy}";

                // ✅ 8. Call Business Logic
                var resultBill = bL_vendor_bill.createBill(vendor);

                // ✅ 9. CHECK FOR DUPLICATE - Show which staff members have duplicates
                if (resultBill.Sql_Result == "DUPLICATE" || resultBill.Bill_id == -1)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ DUPLICATE BILL: {resultBill.Message}");

                    // ✅ Get list of duplicate staff names
                    List<string> duplicateStaff = new List<string>();
                    if (!string.IsNullOrEmpty(resultBill.DuplicateStaffNames))
                    {
                        duplicateStaff = resultBill.DuplicateStaffNames.Split(',')
                            .Select(s => s.Trim())
                            .ToList();
                    }

                    // ✅ Enhanced error message
                    string errorMsg = resultBill.Message;

                    return Tuple.Create(false, errorMsg, duplicateStaff);
                }

                // ✅ 10. Check for other failures
                if (resultBill == null || resultBill.Bill_id <= 0)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Bill creation failed");

                    string errorMsg = $"❌ Bill creation failed - Database returned no Bill ID\n\n📋 Attempted for Staff:\n{staffListDisplay}";

                    return Tuple.Create(false, errorMsg, new List<string>());
                }

                System.Diagnostics.Debug.WriteLine($"✅ Bill created successfully - Bill ID: {resultBill.Bill_id}");

                // ✅ 11. Store for payment processing
                hfPayBillId.Value = resultBill.Bill_id.ToString();
                hfPayVendorId.Value = staffIdsStr;

                // ✅ 12. Process Payment
                bool paymentSectionVisible = paymentSection.Style["display"] != "none";

                if (paymentSectionVisible)
                {
                    if (SavePaymentIfValid())
                    {
                        System.Diagnostics.Debug.WriteLine("   ✅ Payment saved successfully");
                    }
                }

                // ✅ 13. Clear Form
                ClearStaffPaymentForm();

                System.Diagnostics.Debug.WriteLine("=== SaveStaffPaymentBills COMPLETED ===");

                return Tuple.Create(true, "Success", new List<string>());
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ ERROR: {ex.Message}");
                return Tuple.Create(false, $"Error: {ex.Message}", new List<string>());
            }
        }
      
        private string FormatStaffListForDisplay(List<string> staffNames, List<decimal> salaries)
        {
            if (staffNames == null || salaries == null || staffNames.Count == 0)
            {
                return "No staff selected";
            }

            List<string> formattedList = new List<string>();

            for (int i = 0; i < staffNames.Count; i++)
            {
                string name = staffNames[i];
                decimal salary = i < salaries.Count ? salaries[i] : 0;

                formattedList.Add($"  • {name} - ₹{salary:N2}");
            }

            return string.Join("\n", formattedList);
        }
        private void UncheckDuplicateStaff(List<string> duplicateStaffNames)
        {
            foreach (GridViewRow row in gvStaffList.Rows)
            {
                Label lblStaffName = (Label)row.FindControl("lblStaffName");
                WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");

                if (lblStaffName != null && chkStaff != null)
                {
                    string staffName = lblStaffName.Text.Trim();

                    if (duplicateStaffNames.Any(d => d.Equals(staffName, StringComparison.OrdinalIgnoreCase)))
                    {
                        chkStaff.Checked = false;
                    }
                }
            }

            // Recalculate total
            CalculateSelectedTotal();
        }
        protected async void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
               

                // ✅ Convert dropdown value to int
                int paymentType = Convert.ToInt32(ddlSevice.SelectedValue);
                if (paymentType == 0)
                {
                    if (!IsPaymentDataFilled())
                    {
                        throw new Exception("⚠️ Payment is mandatory for Staff Payment. Please enter payment details.");
                    }

                    System.Diagnostics.Debug.WriteLine("→ Processing STAFF PAYMENT");

                    // ✅ Call SaveStaffPaymentBills and check result
                    var result = SaveStaffPaymentBillsWithValidation();
                    if (result.Item1 == false) // Duplicate detected or error
                    {
                        string alertMsg = result.Item2
                            .Replace("\n", "<br/>")
                            .Replace("'", "\\'");

                        ScriptManager.RegisterStartupScript(this, GetType(),
                            "DuplicateError",
                            $@"
        Swal.fire({{
            icon: 'warning',
            title: 'Salary Already Paid',
            html: '{alertMsg}',
            confirmButtonText: 'OK'
        }}).then(() => {{
            $('#billModal').modal('show'); // ✅ modal stays open
        }});
        ",
                            true);

                        // ✅ Duplicate staff uncheck
                        if (result.Item3 != null && result.Item3.Count > 0)
                        {
                            UncheckDuplicateStaff(result.Item3);
                        }

                        return; // ❌ modal close nahi honar
                    }


                    // ✅ Success
                    gridBind();
                    ClearBillForm();
                    ClearPaymentModeSelection();
                    HideAllBillSections();

                    ScriptManager.RegisterStartupScript(this, GetType(),
                        "StaffSuccess",
                        "alert('✅ Staff Payment Bill Created Successfully!'); " +
                        "$('#billModal').modal('hide'); " +
                        "clearBillModal(); " +
                        "hideAllSections();",
                        true);
                    return;
                }
                // ========================================
                // CASE 2, 3 & 4: DAILY EXPENSE (1), VENDOR PAYMENT (2), SERVICE PAYMENT (3)
                // ========================================
                if (paymentType >= 1 && paymentType <= 3)
                {
                    string paymentTypeText = paymentType == 1 ? "DAILY EXPENSE" :
                                             paymentType == 2 ? "VENDOR PAYMENT" :
                                             "SERVICE PAYMENT";
                    System.Diagnostics.Debug.WriteLine($"→ Processing {paymentTypeText}");

                    // ============ VALIDATION ============
                    // ⚠️ For Service Payment (3), vendor validation is OPTIONAL
                    if ((paymentType == 1 || paymentType == 2) &&
                        (string.IsNullOrEmpty(vendor_name_id.Value) || vendor_name_id.Value == "0"))
                    {
                        throw new Exception("Please select a valid vendor");
                    }

                    // ✅ Parse values with proper error handling
                    decimal subTotal = 0m;
                    decimal taxAmount = 0m;
                    decimal totalAmount = 0m;

                    if (!decimal.TryParse(hdnSubtotal.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out subTotal))
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠️ Failed to parse Subtotal: {hdnSubtotal.Value}");
                    }

                    if (!decimal.TryParse(hdnTax.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out taxAmount))
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠️ Failed to parse Tax: {hdnTax.Value}");
                    }

                    // ✅ For Service Payment, use txtServiceCost instead of hdnGrandTotal
                    if (paymentType == 3)
                    {
                        if (!decimal.TryParse(txtServiceCost.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                        {
                            throw new Exception("Invalid Service Cost");
                        }
                    }
                    else
                    {
                        // For Daily Expense & Vendor Payment
                        if (!decimal.TryParse(hdnGrandTotal.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                        {
                            System.Diagnostics.Debug.WriteLine($"⚠️ Failed to parse Grand Total: {hdnGrandTotal.Value}");
                        }
                    }

                 

                    // ============ BILL DATA ============
                    vendor.BillNo = txtBillNumber.Text.Trim();
                    vendor.Sql_Operation = "INSERT";
                    vendor.BillDate = Convert.ToDateTime(txtBillDate.Text);

                    // ✅ SET SERVICE TYPE DIRECTLY TO PAYMENT TYPE (0, 1, 2, 3)
                    vendor.Service = paymentType;

                    // ✅ Handle vendor_id - for Service Payment it might be NULL
                    vendor.vendor_id = string.IsNullOrEmpty(vendor_name_id.Value) || vendor_name_id.Value == "0"
                        ? null
                        : vendor_name_id.Value;

                    vendor.Note = txtNotes.Text.Trim();
                    vendor.SubTotal = subTotal;
                    vendor.TaxAmount = taxAmount;
                    vendor.TotalAmount = totalAmount;
                    vendor.Society_Id = Session["society_id"].ToString();
                    vendor.User_id = Convert.ToInt32(Session["UserId"]);
                    // Map service type name
                    string paytype = paymentType == 0 ? "STAFF PAYMENT" :
                                             paymentType == 1 ? "Daily Expense" :
                                             paymentType == 2 ? "Vendor Inventory Payment" :
                                             "Vendor service Payment";

                    // Get vendor name if exists
                    string vendorName = TextBox2.Text; 


                    // Assign description
                    if (paymentType == 3) // Service Payment
                    {
                        vendor.Description = $"{paytype} - Vendor: {vendorName}";
                    }
                    else
                    {
                        vendor.Description = $"{paytype} - Vendor: {vendorName}";
                    }

                    // ============ SAVE BILL ============
                    var resultBill = bL_vendor_bill.createBill(vendor);

                    if (resultBill == null || resultBill.Bill_id <= 0)
                    {
                        throw new Exception("❌ Bill creation failed - Database returned no Bill ID");
                    }

                    System.Diagnostics.Debug.WriteLine($"✅ Bill created successfully - Bill ID: {resultBill.Bill_id}");

                    // Store for payment processing
                    hfPayBillId.Value = resultBill.Bill_id.ToString();
                    hfPayVendorId.Value = vendor_name_id.Value;

                    // ============ SAVE ITEMS (Only for Daily Expense & Vendor Payment) ============
                    // ⚠️ Skip items for Service Payment (type 3)
                    if ((paymentType == 1 || paymentType == 2) &&
                        !string.IsNullOrEmpty(hdnItemsData.Value) && hdnItemsData.Value != "[]")
                    {
                        System.Diagnostics.Debug.WriteLine("→ Processing Bill Items");
                        System.Diagnostics.Debug.WriteLine($"Items JSON: {hdnItemsData.Value}");

                        try
                        {
                            var items = JsonConvert.DeserializeObject<List<BillItem>>(hdnItemsData.Value);
                            System.Diagnostics.Debug.WriteLine($"   Deserialized {items?.Count ?? 0} items");

                            if (items != null && items.Count > 0)
                            {
                                int savedCount = 0;
                                foreach (var item in items)
                                {
                                    try
                                    {
                                        System.Diagnostics.Debug.WriteLine($"   Processing item: {item.Description} | Qty: {item.Quantity} | Price: {item.unit_price} | Tax: {item.tax_percent}% | Amount: {item.Amount}");

                                        inventory.Sql_Operation = "Update";
                                        inventory.Society_Id = Session["society_id"].ToString();
                                        inventory.Item_Name = item.Description;
                                        inventory.VendorId = Convert.ToInt32(vendor_name_id.Value);
                                        inventory.Tax = Convert.ToInt32(item.tax_percent);
                                        inventory.Total_Amount = Convert.ToInt32(item.Amount);
                                        inventory.Quantity = Convert.ToInt32(item.Quantity);
                                        inventory.Purchase_Cost = Convert.ToDecimal(item.unit_price);
                                        inventory.Vendor_bill_ID = resultBill.Bill_id;
                                        inventory.Purchase_Date = Convert.ToDateTime(txtBillDate.Text);
                                        inventory.Warranty = item.Warranty;

                                        bL_Inventory.updateInventoryDetails(inventory);
                                        savedCount++;
                                        System.Diagnostics.Debug.WriteLine($"   ✅ Item saved: {item.Description}");
                                    }
                                    catch (Exception itemEx)
                                    {
                                        System.Diagnostics.Debug.WriteLine($"   ⚠️ Error saving item '{item.Description}': {itemEx.Message}");
                                        System.Diagnostics.Debug.WriteLine($"   Stack Trace: {itemEx.StackTrace}");
                                    }
                                }
                                System.Diagnostics.Debug.WriteLine($"   📊 Total items saved: {savedCount} out of {items.Count}");
                            }
                            else
                            {
                                System.Diagnostics.Debug.WriteLine("   ℹ️ Items list is empty after deserialization");
                            }
                        }
                        catch (JsonException jsonEx)
                        {
                            System.Diagnostics.Debug.WriteLine($"❌ JSON Deserialization Error: {jsonEx.Message}");
                            System.Diagnostics.Debug.WriteLine($"   Raw JSON: {hdnItemsData.Value}");
                            throw new Exception("Invalid items data format");
                        }
                    }
                    else
                    {
                        if (paymentType == 3)
                        {
                            System.Diagnostics.Debug.WriteLine("   ℹ️ Service Payment - No items to process");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("   ℹ️ No items data found in hdnItemsData (empty or [])");
                        }
                    }

                    // ============ SAVE APPROVERS (Skip for Service Payment) ============
                    if (paymentType != 3 && GridView3.Rows.Count > 0)
                    {
                        System.Diagnostics.Debug.WriteLine("→ Saving Approvers");
                        int approverCount = 0;

                        foreach (GridViewRow row in GridView3.Rows)
                        {
                            Label lblUserId = row.FindControl("user_id") as Label;
                            if (lblUserId != null && int.TryParse(lblUserId.Text, out int uid))
                            {
                                try
                                {
                                    society.expense_id = resultBill.Bill_id;
                                    society.User_Id = uid;
                                    society.Sql_Operation = "Update";
                                    bL_Society.updateApprover(society);
                                    approverCount++;

                                    System.Diagnostics.Debug.WriteLine($"   ✅ Approver added: User ID {uid}");
                                }
                                catch (Exception appEx)
                                {
                                    System.Diagnostics.Debug.WriteLine($"   ⚠️ Error adding approver {uid}: {appEx.Message}");
                                }
                            }
                        }

                        System.Diagnostics.Debug.WriteLine($"   📊 Total approvers saved: {approverCount}");
                    }
                    else
                    {
                        if (paymentType == 3)
                        {
                            System.Diagnostics.Debug.WriteLine("   ℹ️ Service Payment - No approvers required");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("   ℹ️ No approvers to save");
                        }
                    }

                    decimal dummy;
                    bool isPaymentDataFilled =
                        (decimal.TryParse(txtcashamount.Text, out dummy) && dummy > 0) ||
                        (decimal.TryParse(txtcheqamount.Text, out dummy) && dummy > 0) ||
                        (decimal.TryParse(txtonlineamount.Text, out dummy) && dummy > 0);

                    if (isPaymentDataFilled)
                    {
                      
                        SavePaymentIfValid();
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("ℹ️ No payment data filled. Skipping SavePaymentIfValid()");
                    }


                    // ============ REFRESH GRID ============
                    gridBind();
                     ClearBillForm();
                    ClearPaymentModeSelection();

                    // ============ SUCCESS MESSAGE ============
                    string successMsg = paymentType == 1 ? "Daily Expense Bill created successfully!" :
                                        paymentType == 2 ? "Vendor Payment Bill created successfully!" :
                                        "Service Payment Bill created successfully!";

                   
                    ScriptManager.RegisterStartupScript(this, GetType(),
                        "SuccessMsg",
                        $"alert('✅ {successMsg}'); " +
                        "$('#billModal').modal('hide'); " +
                        "clearBillModal(); " +  // Client-side clear
                        "hideAllSections();",
                        true);

               
                    return; 
                }
                else
                {
                    // Invalid payment type
                    throw new Exception("Please select a valid Payment Type");
                }
            }
            catch (Exception ex)
            {

                ScriptManager.RegisterStartupScript(this, GetType(),
                    "ErrorMsg",
                    $"alert('❌ Error: {ex.Message.Replace("'", "\\'")}');",
                    true);
            }
        }
    

    // ✅ ADD THIS METHOD in your code-behind
    private void ClearBillForm()
        {
            // Clear textboxes
            txtBillNumber.Text = "";
            txtBillDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            txtPaymentMonth.Text = DateTime.Now.ToString("yyyy-MM-dd");
            txtNotes.Text = "";
            txtDesc.Text = "";
            txtServiceCost.Text = "";
            txtServiceDescription.Text = "";
            TextBox2.Text = "";
            TextBox1.Text = "";

            // Clear hidden fields
            hdnItemsData.Value = "";
            hdnSubtotal.Value = "0";
            hdnTax.Value = "0";
            hdnGrandTotal.Value = "0";
            hdnBillId.Value = "0";
            vendor_name_id.Value = "0";

            // Reset dropdown
            ddlSevice.SelectedIndex = 0;

            // Clear payment fields
            txtcheqno.Text = "";
            txtcheqdate.Text = "";
            txtbank.Text = "";
            txtcheqamount.Text = "";
            txttrasaction.Text = "";
            txtonlineamount.Text = "";
            txtcashamount.Text = "";
            txtre.Text = "";

            panelonline.Visible = false;
            Panelcheque.Visible = false;
            Panelcash.Visible = false;

            // Hide all sections
            HideAllBillSections();

            // Clear ViewState
            ViewState["SelectedStaff"] = CreateSelectedStaffTable();
            ViewState["SelectedItems"] = CreateBillItemsTable();
            ViewState["IsApproved"] = false;

            System.Diagnostics.Debug.WriteLine("✅ Form cleared on server-side");
        }
        protected async void generate_notification(string token)
        {
            var Fcm = new FirebaseCloudMessaging();
            string result1 = await Fcm.SendNotificationAsync(token, "Approval", "Action needed to the bill");
        }

        protected void btn_confirm_Click(object sender, EventArgs e)
        {
            DataTable ds = new DataTable();
            member.Sql_Operation = "add_approver";
            member.Society_Id = Session["society_id"].ToString();
            member.UserId = Convert.ToInt32(Session["UserId"].ToString());
            ds = bL_Society_member.add_approver(member);
            approverdt = ds;

            foreach (GridViewRow row in GridView2.Rows)
            {
                System.Web.UI.WebControls.Label user_id = (System.Web.UI.WebControls.Label)row.FindControl("user_id");
                System.Web.UI.WebControls.CheckBox chkBx = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                if (!chkBx.Checked)
                {
                    List<DataRow> rowsToDelete = new List<DataRow>();
                    foreach (DataRow dataRow in approverdt.Rows)
                    {
                        if (dataRow.RowState != DataRowState.Deleted && dataRow["user_id"].ToString() == user_id.Text)
                        {
                            rowsToDelete.Add(dataRow);
                        }
                    }
                    foreach (DataRow rowToDelete in rowsToDelete)
                    {
                        rowToDelete.Delete();
                    }
                }
            }

            approverdt.AcceptChanges();
            ViewState["user_data"] = approverdt;
            GridView3.DataSource = approverdt;
            GridView3.DataBind();

            // Hide payment section server-side
            paymentSection.Style["display"] = "none";

            ViewState["IsApproved"] = true;
            UpdatePanel2.Update();

            // ✅ MAIN FIX: Set JavaScript flag to keep payment hidden
            string script = @"
        keepPaymentHidden = true;
            hideModal('approversModal');
        var paySection = document.getElementById('" + paymentSection.ClientID + @"');
        if (paySection) {
            paySection.style.display = 'none';
        }
    ";

            ScriptManager.RegisterStartupScript(this, this.GetType(), "HidePaymentSection", script, true);
        }
        private DataTable CreateBillItemsTable()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("item_id");
            dt.Columns.Add("item_name");
            dt.Columns.Add("quantity");
            dt.Columns.Add("unit_price");
            dt.Columns.Add("tax_percent");
            dt.Columns.Add("warranty");
            dt.Columns.Add("Amount");
            return dt;
        }


        protected void name_CheckedChanged(object sender, EventArgs e)
        {
            System.Web.UI.WebControls.CheckBox activeCheckBox = sender as System.Web.UI.WebControls.CheckBox;
            GridViewRow Row = (GridViewRow)activeCheckBox.NamingContainer;

            bool isAllChecked = true;
            foreach (GridViewRow row in GridView2.Rows)
            {
                System.Web.UI.WebControls.CheckBox chkBx = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                if (!chkBx.Checked)
                {
                    isAllChecked = false;
                    break;
                }
            }
            CheckAll.Checked = isAllChecked;

        }
        protected void CheckAll_CheckedChanged(object sender, EventArgs e)
        {

            bool isAllChecked;
            if (CheckAll.Checked)
                isAllChecked = true;
            else
                isAllChecked = false;
            foreach (GridViewRow row in GridView2.Rows)
            {
                System.Web.UI.WebControls.CheckBox chkBx = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                chkBx.Checked = isAllChecked;
            }

        }
        public void list_fill()
        {
            DataTable dt = new DataTable();
            member.Sql_Operation = "add_approver";
            member.Society_Id = Session["society_id"].ToString();
            member.UserId = Convert.ToInt32(Session["UserId"].ToString());
            dt = bL_Society_member.add_approver(member);


            GridView2.DataSource = dt;

            GridView2.DataBind();


        }


        protected void GridView2_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            DataTable dt = (DataTable)ViewState["user_data"];
            if (dt != null)
                foreach (GridViewRow row in GridView2.Rows)
                {
                    System.Web.UI.WebControls.Label user_id = (System.Web.UI.WebControls.Label)row.FindControl("user_id");
                    System.Web.UI.WebControls.CheckBox chkBx = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                    foreach (DataRow dataRow in dt.Rows)
                    {
                        if (dataRow["user_id"].ToString() == user_id.Text)
                        {
                            chkBx.Checked = true;
                            break;
                        }
                        else
                        {
                            chkBx.Checked = false;
                            CheckAll.Checked = false;
                        }


                    }
                }
        }


        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (vendor_name_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    if (link.CommandArgument == vendor_name_id.Value)

                        TextBox2.Text = link.Text;

                }

            }

        }

        // For Items Grid
        protected void gvItems_RowDataBound(object sender, GridViewRowEventArgs e)
        {

        }
        protected void chkSelectAllItems_CheckedChanged(object sender, EventArgs e) { }
        protected void chkItem_CheckedChanged(object sender, EventArgs e) { }


        protected void btnSaveVendor_Click(object sender, EventArgs e)
        {
            vendor.Sql_Operation = "INSERT";
            vendor.Society_Id = Session["society_id"].ToString();
            vendor.VendorName = txtNewVendorName.Text;
            vendor.Address = txtNewVendorAddress.Text;
            vendor.GstNo = txtNewVendorGST.Text;
            vendor.ServiceType = txtServiceType.Text;
            vendor.Contact = txtNewVendorContact.Text;
            vendor.ContactPerson = txtContactPerson.Text;
            vendor.Email = txtNewVendorEmail.Text;
            var result = bL_Vendor.updatevendorDetails(vendor);
            //return result.Sql_Result;
            ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "hideModal('addVendorModal');", true);
            fill_repeater();
        }
        protected void ddlSevice_SelectedIndexChanged(object sender, EventArgs e)
        {
            HideAllBillSections();
            SetStaffAmountReadonly(false);

            if (ddlSevice.SelectedValue == "0")
            {
                // ✅ Staff Payment
                if (paymentMonthDiv != null) paymentMonthDiv.Style["display"] = "block";
                if (paymentSection != null) paymentSection.Style["display"] = "block";
                if (staff != null) staff.Style["display"] = "block";
                SetStaffAmountReadonly(true);
            }
            else if (ddlSevice.SelectedValue == "1" || ddlSevice.SelectedValue == "2")
            {
                // ✅ Daily Expense (1) OR Vendor Payment (2)
                if (billNumberDiv != null) billNumberDiv.Style["display"] = "block";
                if (billDateDiv != null) billDateDiv.Style["display"] = "block";
                if (vendorSection != null) vendorSection.Style["display"] = "block";
                if (itemSection != null) itemSection.Style["display"] = "block";
                if (approvelSection != null) approvelSection.Style["display"] = "block";

                // ✅ Payment section show (unless approvers added)
                bool isApproved = ViewState["IsApproved"] != null && (bool)ViewState["IsApproved"];
                if (paymentSection != null && !isApproved)
                {
                    paymentSection.Style["display"] = "block";
                }
            }
            else if (ddlSevice.SelectedValue == "3")
            {
                // ✅ Service Payment
                if (billNumberDiv != null) billNumberDiv.Style["display"] = "block";
                if (billDateDiv != null) billDateDiv.Style["display"] = "block";
                if (serviceSection != null) serviceSection.Style["display"] = "block";
                if (vendorSection != null) vendorSection.Style["display"] = "block";
                if (paymentSection != null) paymentSection.Style["display"] = "block";

                // ✅ Explicitly HIDE vendor, items, approvers

                if (itemSection != null) itemSection.Style["display"] = "none";
                if (approvelSection != null) approvelSection.Style["display"] = "none";
            }
            // No else needed - HideAllBillSections already handles empty/invalid values
        }
        private void SetStaffAmountReadonly(bool isReadonly)
        {
            txtcashamount.ReadOnly = isReadonly;
            txtcheqamount.ReadOnly = isReadonly;
            txtonlineamount.ReadOnly = isReadonly;
        }

        protected void viewBill(object sender, CommandEventArgs e)
        {
            int billId = Convert.ToInt32(e.CommandArgument);
            LoadBillDetails(billId); // ✅ This will now load payment data too
            ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "showModal('billModal2');", true);
        }
     
        private void LoadBillDetails(int billId)
        {
            // Load Bill Header Information
            int serviceType = LoadBillHeader(billId);

            // ✅ Handle different payment types
            switch (serviceType)
            {
                case 0: // Staff Payment
                    servicePanel.Visible = false;
                    billItems.Visible = false;  // ✅ No items for staff payment
                                                // Don't load items or approvals
                    break;

                case 1: // Daily Expense
                case 2: // Vendor Payment
                    servicePanel.Visible = false;
                    billItems.Visible = true;
                    LoadBillItems(billId);
                    LoadApprovals(billId);
                    break;

                case 3: // Service Payment
                    servicePanel.Visible = true;  // ✅ Show service details
                    billItems.Visible = false;     // ✅ No items for service
                                                   // Don't load items or approvals
                    break;

                default:
                    servicePanel.Visible = false;
                    billItems.Visible = false;
                    break;
            }
            LoadPaymentSummary(billId);
        }
        private void LoadPaymentSummary(int billId)
        {
            try
            {
                // ✅ Get payment receipt data
                billReceipt.BillId = billId;
                billReceipt.Sql_Operation = "getreceipt";
                billReceipt.Society_Id = Session["society_id"].ToString();

                DataTable dt = bL_vendor_bill.view_bill(billReceipt);

                if (dt.Rows.Count > 0)
                {
                    // ✅ Show payment summary panel
                    pnlPaymentSummary.Visible = true;

                    // Bind vendor info
                    Label2.Text = dt.Rows[0]["vendor_name"].ToString();

                    // Parse payment mode
                    string paymentMode = string.Empty;
                    string chequeNumber = string.Empty;

                    if (!string.IsNullOrEmpty(dt.Rows[0]["transaction_ref"].ToString()) &&
                        dt.Rows[0]["transaction_ref"].ToString().Contains(":"))
                    {
                        var parts = dt.Rows[0]["transaction_ref"].ToString().Split(':');
                        if (parts.Length >= 2)
                        {
                            paymentMode = parts[0];
                            chequeNumber = parts[1];
                        }
                    }

                    // Show/hide panels based on payment mode
                    if (paymentMode == "Online" || paymentMode == "UPI")
                    {
                        Panel1.Visible = true;
                        Panel2.Visible = false;
                        Label4.Text = chequeNumber;
                    }
                    else if (paymentMode == "Cheque")
                    {
                        Panel1.Visible = false;
                        Panel2.Visible = true;
                        Label5.Text = chequeNumber;
                        Label6.Text = Convert.ToDateTime(dt.Rows[0]["payment_date"]).ToString("dd-MMM-yyyy");
                        Label7.Text = dt.Rows[0]["bank_name"].ToString();
                    }
                    else if (paymentMode == "Cash")
                    {
                        Panel1.Visible = false;
                        Panel2.Visible = false;
                    }

                    Label3.Text = paymentMode;
                    Label8.Text = "₹ " + Convert.ToDecimal(dt.Rows[0]["paid_amount"]).ToString("N2");

                    // Get remarks
                    if (dt.Columns.Contains("remarks") && dt.Rows[0]["remarks"] != DBNull.Value)
                    {
                        Label9.Text = dt.Rows[0]["remarks"].ToString();
                    }
                    else
                    {
                        Label9.Text = "No remarks";
                    }

                    // ✅ Bind ALL bills from this payment
                    GridView1.DataSource = dt;
                    GridView1.DataBind();
                }
                else
                {
                    // ✅ Hide payment summary if no payment exists
                    pnlPaymentSummary.Visible = false;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading payment summary: {ex.Message}");
                pnlPaymentSummary.Visible = false;
            }
        }
       

        private int LoadBillHeader(int billId)
        {
            vendor.Sql_Operation = "select";
            vendor.Bill_id = billId;

            var result = bL_vendor_bill.getVendorBillDetails(vendor);

            lblBillNumber.Text = result.BillNo;
            lblBillDate.Text = result.BillDate.ToString("dd-MMM-yyyy");

            // ✅ Set service type label
            lblServiceType.Text = result.Service == 0 ? "Staff Payment" :
                                  result.Service == 1 ? "Daily Expense" :
                                  result.Service == 2 ? "Vendor Payment" :
                                  result.Service == 3 ? "Service Payment" : "Unknown";

            lblVendorName.Text = result.VendorName ?? "N/A";
            lblGSTNumber.Text = result.GstNo ?? "N/A";

            // ✅ Service-specific fields
            lblServiceDescription.Text = result.Description ?? "N/A";
            lblServiceCost.Text = result.TotalAmount.ToString("0.00");

            // ✅ Totals
            lblSubtotal.Text = result.SubTotal.ToString("0.00");
            lblTax.Text = result.TaxAmount.ToString("0.00");
            lblGrandTotal.Text = result.TotalAmount.ToString("0.00");

            // ✅ Return service type as integer
            return result.Service;
        }

        private void LoadBillItems(int billId)
        {
            DataTable dt = new DataTable();
            vendor.Sql_Operation = "get_bill_items";
            vendor.BillNo = billId.ToString();
            dt = bL_vendor_bill.getBillItems_ApprovalList(vendor);

            gvBillItems.DataSource = dt;
            gvBillItems.DataBind();

        }

        private void LoadApprovals(int billId)
        {

            DataTable dt = new DataTable();
            vendor.Sql_Operation = "get_Approvals";
            vendor.BillNo = billId.ToString();
            dt = bL_vendor_bill.getBillItems_ApprovalList(vendor);
            gvApprovals.DataSource = dt;
            gvApprovals.DataBind();
        }


        protected void GridView1_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            // Check if the current row is a data row (not header/footer)
            if (e.Row.RowType == DataControlRowType.DataRow)
            {

                int sessionUserId = Convert.ToInt32(Session["UserId"]);


                int rowUserId = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "user_id"));
                int status = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "approval_status"));

                // Find the buttons in the GridView template
                Button btnApprove = (Button)e.Row.FindControl("btnApprove");
                Button btnReject = (Button)e.Row.FindControl("btnReject");
                Label lblStatus = (Label)e.Row.FindControl("lblStatus");

                //if Status is 1 means Pending then only check user id and show hide buttons
                if (status == 1)
                {
                    // Compare the session user ID with the row's user ID
                    if (sessionUserId == rowUserId)
                    {
                        btnApprove.Visible = true;
                        btnReject.Visible = true;
                        lblStatus.Visible = false;
                    }
                    else
                    {
                        btnApprove.Visible = false;
                        btnReject.Visible = false;
                        lblStatus.Visible = true;
                    }

                }
            }
        }

        protected void gvApprovals_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string argument = e.CommandArgument.ToString();
            string[] args = argument.Split('%');


            int approvalId = Convert.ToInt32(args[0]);
            int billId = Convert.ToInt32(args[1]);




            if (e.CommandName == "Reject")
            {
                // Trigger JS to open modal for that ID

                approval_id_hd.Value = approvalId.ToString();
                bill_id_hd.Value = billId.ToString();
                ScriptManager.RegisterStartupScript(this, GetType(), "showRejectModal", $"openRejectModal('{approvalId}, {billId}');", true);
            }

            if (e.CommandName == "Approve")
            {
                member.Sql_Operation = "update_status";
                member.Approval_id = approvalId;
                member.Status = 2;

                bL_vendor_bill.Update_status(member);
                LoadApprovals(billId);
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "SuccessEntryy();", true);

            }
        }

        protected void btnSubmitReject_Click(object sender, EventArgs e)
        {
            var btn = sender as Button;
            int id = Convert.ToInt32(approval_id_hd.Value);
            member.Sql_Operation = "update_status";
            member.Approval_id = id;
            member.Status = 4;
            member.Remark = txtRemark.Text;

            bL_vendor_bill.Update_status(member);
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "FailedEntryy();", true);
            ScriptManager.RegisterStartupScript(this, GetType(), "hideRejectModal", $"closeRejectModal();", true);
            ScriptManager.RegisterStartupScript(this, GetType(), "hideRejectModal", $"closeBillModal();", true);
            LoadApprovals(Convert.ToInt32(bill_id_hd.Value));
        }


        protected void btnPay_Click(object sender, EventArgs e)
        {
            try
            {
                Button btn = (Button)sender;
                string[] args = btn.CommandArgument.Split(',');
                if (args.Length < 2)
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "ErrorAlert",
                        "alert('Invalid bill data');", true);
                    return;
                }

                int billId = Convert.ToInt32(args[0]);

                // FIX: Handle comma-separated vendor IDs - take first one
                string vendorIdString = args[1];
                int vendorId;

                if (vendorIdString.Contains(","))
                {
                    // Multiple vendors - take the first one
                    vendorId = Convert.ToInt32(vendorIdString.Split(',')[0].Trim());
                }
                else
                {
                    vendorId = Convert.ToInt32(vendorIdString);
                }

                hfPayBillId.Value = billId.ToString();
                hfPayVendorId.Value = vendorId.ToString();

                vendor.Sql_Operation = "select";
                vendor.Bill_id = billId;
                vendor.vendor_id = vendorId.ToString();

                var billDetails = bL_vendor_bill.getVendorBillDetails(vendor);

                if (billDetails != null)
                {
                    lblPayVendorName.Text = billDetails.VendorName ?? "N/A";
                    switch (billDetails.Service)
                    {
                        case 0:
                            lblPayServiceType.Text = "👥 Staff Payment";
                            lblPayBillType.Text = "Staff Payment";
                            break;
                        case 1:
                            lblPayServiceType.Text = "💰 Daily Expense";
                            lblPayBillType.Text = "Daily Expense";
                            break;
                        case 2:
                            lblPayServiceType.Text = "🏢 Vendor Payment";
                            lblPayBillType.Text = "Vendor Payment";
                            break;
                        case 3:
                            lblPayServiceType.Text = "🔧 Service Payment";
                            lblPayBillType.Text = "Service Payment";
                            break;
                        default:
                            lblPayServiceType.Text = "❓ Unknown";
                            lblPayBillType.Text = "Unknown";
                            break;
                    }
                    lblPayBillNumber.Text = "Bill #" + (billDetails.BillNo ?? "N/A");
                    lblPayBillDate.Text = billDetails.BillDate.ToString("dd-MMM-yyyy");
                    //lblPayBillType.Text = billDetails.Service ? "Service" : "Inventory";

                    // --- Decimal-safe display ---
                    lblPayBillAmount.Text = billDetails.TotalAmount.ToString("0.00");
                    lblRemainingAmount.Text = billDetails.RemainingAmount ?? "0.00";
                    lblPaidAmount.Text = billDetails.PaidAmount ?? "0.00";
                    decimal remainingAmount = 0m;

                    if (!string.IsNullOrEmpty(billDetails.RemainingAmount))
                    {
                        decimal.TryParse(billDetails.RemainingAmount, out remainingAmount);
                    }

                    if (remainingAmount <= 0)
                    {
                        remainingAmount = billDetails.TotalAmount;
                    }

                    string payAmount = remainingAmount.ToString("0.00");

                    // --- Status ---
                    string status = billDetails.Status1 ?? "1";
                    switch (status)
                    {
                        case "1":
                            lblPayBillStatus.Text = "Pending";
                            lblPayBillStatus.CssClass = "status-badge pending";
                            break;
                        case "2":
                            lblPayBillStatus.Text = "Approved";
                            lblPayBillStatus.CssClass = "status-badge approved";
                            break;
                        case "3":
                            lblPayBillStatus.Text = "Paid";
                            lblPayBillStatus.CssClass = "status-badge paid";
                            break;
                        case "4":
                            lblPayBillStatus.Text = "Rejected";
                            lblPayBillStatus.CssClass = "status-badge rejected";
                            break;
                        case "5":
                            lblPayBillStatus.Text = "Partially Paid";
                            lblPayBillStatus.CssClass = "status-badge partial";
                            break;
                        default:
                            lblPayBillStatus.Text = "Unknown";
                            lblPayBillStatus.CssClass = "status-badge unknown";
                            break;
                    }

                    // --- Payment textboxes ---
                    txtAmtCqu.Text = billDetails.RemainingAmount.ToString();
                    txtAmtOl.Text = billDetails.RemainingAmount.ToString();
                    txtamtcash.Text = billDetails.RemainingAmount.ToString();

                    // Default payment mode
                    pnlPayCheque.Visible = true;
                    pnlPayOnline.Visible = false;
                    pnlCash.Visible = false;

                    // Reset other fields
                    txtChequeDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
                    txtChequeNo.Text = "";
                    txtBankName.Text = "";
                    txtPayTransactionRef.Text = "";
                    txtPayRemarks.Text = "";
                    lblPayMessage.Visible = false;
                }
                else
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "ErrorAlert",
                        "alert('Bill details not found');", true);
                    return;
                }

                UpdatePanelPayment.Update();

                ScriptManager.RegisterStartupScript(this, GetType(), "OpenPayModal",
                    @"setTimeout(function() { 
                $('#paymentModal').modal({
                    backdrop: 'static',
                    keyboard: false
                }); 
                $('#paymentModal').modal('show');
            }, 200);", true);
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "ErrorAlert",
                    $"alert('Error: {ex.Message}');", true);
            }
        }


        protected void btnPayChequeMode_Click(object sender, EventArgs e)
        {
            pnlPayCheque.Visible = true;
            pnlPayOnline.Visible = false;
            pnlCash.Visible = false;

            decimal amount = 0;
            if (decimal.TryParse(lblRemainingAmount.Text, out amount))
            {
                txtAmtCqu.Text = amount.ToString("0.00");
            }

            UpdatePanelPayment.Update();
        }

        protected void btnPayOnlineMode_Click(object sender, EventArgs e)
        {
            pnlPayOnline.Visible = true;
            pnlPayCheque.Visible = false;
            pnlCash.Visible = false;

            decimal amount = 0;
            if (decimal.TryParse(lblRemainingAmount.Text, out amount))
            {
                txtAmtOl.Text = amount.ToString("0.00");
            }

            UpdatePanelPayment.Update();
        }

        protected void btnCashMode_Click(object sender, EventArgs e)
        {

            pnlPayOnline.Visible = false;
            pnlPayCheque.Visible = false;
            pnlCash.Visible = true;

            decimal amount = 0;
            if (decimal.TryParse(lblRemainingAmount.Text, out amount))
            {
                txtamtcash.Text = amount.ToString("0.00");
            }

            UpdatePanelPayment.Update();
        }

        protected void btnSavePayment_Click(object sender, EventArgs e)
        {
            if (ValidatePayment())
            {
                SavePayment();

                // ✅ Close modal and force full page refresh
                ScriptManager.RegisterStartupScript(this, GetType(), "RefreshPage",
                    @"$('#paymentModal').modal('hide');
              setTimeout(function() { 
                  window.location.href = window.location.href; 
              }, 300);",
                    true);
            }
            else
            {
                UpdatePanelPayment.Update();
                ScriptManager.RegisterStartupScript(this, GetType(), "KeepModalOpen",
                    "$('#paymentModal').modal('show');", true);
            }
        }


        private bool ValidatePayment()
        {
            if (pnlPayCheque.Visible)
            {
                // ✅ Validate cheque number
                if (string.IsNullOrWhiteSpace(txtChequeNo.Text))
                {
                    ShowPaymentMessage("⚠️ Cheque number is mandatory. Please enter cheque number.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayChequeNo",
                        "setTimeout(function(){ $('#" + txtChequeNo.ClientID + "').focus(); }, 300);", true);

                    return false;
                }

                // ✅ Validate cheque date
                if (string.IsNullOrWhiteSpace(txtChequeDate.Text))
                {
                    ShowPaymentMessage("⚠️ Cheque date is mandatory. Please select cheque date.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayChequeDate",
                        "setTimeout(function(){ $('#" + txtChequeDate.ClientID + "').focus(); }, 300);", true);

                    return false;
                }

                // ✅ Validate cheque date is not in future
                DateTime chequeDate;
                if (DateTime.TryParse(txtChequeDate.Text, out chequeDate))
                {
                    if (chequeDate > DateTime.Now.Date)
                    {
                        ShowPaymentMessage("⚠️ Cheque date cannot be in the future.", "warning");
                        return false;
                    }
                }

                // ✅ Validate bank name
                if (string.IsNullOrWhiteSpace(txtBankName.Text))
                {
                    ShowPaymentMessage("⚠️ Bank name is mandatory. Please enter bank name.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayBankName",
                        "setTimeout(function(){ $('#" + txtBankName.ClientID + "').focus(); }, 300);", true);

                    return false;
                }

                // ✅ Validate amount
                if (string.IsNullOrWhiteSpace(txtAmtCqu.Text) || Convert.ToDecimal(txtAmtCqu.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayAmount",
                        "setTimeout(function(){ $('#" + txtAmtCqu.ClientID + "').focus(); }, 300);", true);

                    return false;
                }
            }

            if (pnlPayOnline.Visible)
            {
                if (string.IsNullOrWhiteSpace(txtPayTransactionRef.Text))
                {
                    ShowPaymentMessage("⚠️ Transaction reference is mandatory. Please enter transaction ID.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayTransaction",
                        "setTimeout(function(){ $('#" + txtPayTransactionRef.ClientID + "').focus(); }, 300);", true);

                    return false;
                }

                if (string.IsNullOrWhiteSpace(txtAmtOl.Text) || Convert.ToDecimal(txtAmtOl.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayOnlineAmount",
                        "setTimeout(function(){ $('#" + txtAmtOl.ClientID + "').focus(); }, 300);", true);

                    return false;
                }
            }

            if (pnlCash.Visible)
            {
                if (string.IsNullOrWhiteSpace(txtamtcash.Text) || Convert.ToDecimal(txtamtcash.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid cash amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusPayCashAmount",
                        "setTimeout(function(){ $('#" + txtamtcash.ClientID + "').focus(); }, 300);", true);

                    return false;
                }
            }

            return true;
        }

        private void ShowPaymentMessage(string message, string type)
        {
            lblPayMessage.Text = message;
            lblPayMessage.CssClass = "alert alert-" + type;
            lblPayMessage.Visible = true;
        }

        private void SavePayment()
        {
            try
            {
                decimal amount = 0m;
                vendor.FilePath = UploadId();
                vendor.BillIds = hfPayBillId.Value;
                vendor.Sql_Operation = "INSERT";
                vendor.Society_Id = Session["society_id"].ToString();
                vendor.vendor_id = Convert.ToString(hfPayVendorId.Value);
                if (pnlPayCheque.Visible)
                {
                    vendor.PayMode = "Cheque";
                    vendor.ChequeNo = txtChequeNo.Text.Trim();
                    vendor.ChequeDate = txtChequeDate.Text.Trim();
                    vendor.BankName = txtBankName.Text.Trim();

                    decimal.TryParse(txtAmtCqu.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out amount);
                    vendor.TotalAmount = amount;

                }

                if (pnlPayOnline.Visible)
                {
                    vendor.PayMode = "Online";
                    vendor.TransactionRef = txtPayTransactionRef.Text.Trim();
                    decimal.TryParse(txtAmtOl.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out amount);
                    vendor.TotalAmount = amount;
                }
                if (pnlCash.Visible)
                {
                    vendor.PayMode = "Cash";

                    decimal.TryParse(txtamtcash.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out amount);
                    vendor.TotalAmount = amount;
                }

                vendor.User_id = Convert.ToInt32(Session["UserId"]);
                vendor.Remark = txtPayRemarks.Text.Trim();

                var result = bL_vendor_bill.saveVendorBill(vendor);

                if (result.Sql_Result == "Done")
                {
                    ShowPaymentMessage("Payment saved successfully!", "success");

                    // Clear form
                    txtChequeNo.Text = "";
                    txtChequeDate.Text = "";
                    txtBankName.Text = "";
                    txtAmtCqu.Text = "";
                    txtPayTransactionRef.Text = "";
                    txtAmtOl.Text = "";
                    txtPayRemarks.Text = "";
                    txtamtcash.Text = "";
                }
                else
                {
                    ShowPaymentMessage("Error saving payment. Please try again.", "danger");
                }
            }
            catch (Exception ex)
            {
                ShowPaymentMessage("Error: " + ex.Message, "danger");
            }
        }

        protected string UploadId()
        {
            string relativeFolder = "/Documents/" + Session["society_name"] + "/vendor_bills/";
            string folderPath = Server.MapPath(relativeFolder);

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

            return string.Empty;
        }
        protected string UploadFile()
        {
            string relativeFolder = "/Documents/" + Session["society_name"] + "/vendor_bills/";
            string folderPath = Server.MapPath(relativeFolder);

            System.IO.Directory.CreateDirectory(folderPath);

            if (FileUpload2.HasFile)
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

            return string.Empty;
        }
        protected void lnkCategory_Click(object sender, EventArgs e)
        {
            LinkButton btn = (LinkButton)sender;
            vendor_name_id.Value = btn.CommandArgument;
            TextBox1.Text = btn.CommandName;
            TextBox2.Text = btn.Text;

            // Hide the dropdown
            ScriptManager.RegisterStartupScript(this, GetType(), "HideDropdown",
                "document.getElementById('RepeaterContainer1').style.display = 'none';", true);
        }

        protected void gvBills_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName.ToString() == "ViewDetails")
            {
                int billId = Convert.ToInt32(e.CommandArgument);

                billReceipt.BillId = billId;
                billReceipt.Sql_Operation = "getreceipt";
                billReceipt.Society_Id = Session["society_id"].ToString();

                DataTable dt = bL_vendor_bill.view_bill(billReceipt);

                if (dt.Rows.Count < 1)
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "NoDataAlert",
                        "alert('No payment details found');", true);
                    return;
                }

                // Bind vendor info
                lblResidentName.Text = dt.Rows[0]["vendor_name"].ToString();

                // Parse payment mode
                string paymentMode = string.Empty;
                string chequeNumber = string.Empty;

                if (!string.IsNullOrEmpty(dt.Rows[0]["transaction_ref"].ToString()) &&
                    dt.Rows[0]["transaction_ref"].ToString().Contains(":"))
                {
                    var parts = dt.Rows[0]["transaction_ref"].ToString().Split(':');
                    if (parts.Length >= 2)
                    {
                        paymentMode = parts[0];
                        chequeNumber = parts[1];
                    }
                }

                // Show/hide panels
                if (paymentMode == "Online" || paymentMode == "UPI")
                {
                    pnlTransactionRef.Visible = true;
                    pnlBankPayInfo.Visible = false;
                    lblTransaction.Text = chequeNumber;
                }
                else if (paymentMode == "Cheque")
                {
                    pnlTransactionRef.Visible = false;
                    pnlBankPayInfo.Visible = true;
                    lblChequeNumber.Text = chequeNumber;
                    lblChequeDate.Text = Convert.ToDateTime(dt.Rows[0]["payment_date"]).ToString("dd-MMM-yyyy");
                    lblBankName.Text = dt.Rows[0]["bank_name"].ToString();
                }
                else if (paymentMode == "Cash")
                {
                    pnlTransactionRef.Visible = false;
                    pnlBankPayInfo.Visible = false;
                }

                lblPaymentMode.Text = paymentMode;
                lblPaymentAmount.Text = "₹ " + Convert.ToDecimal(dt.Rows[0]["paid_amount"]).ToString("N2");

                if (dt.Columns.Contains("remarks") && dt.Rows[0]["remarks"] != DBNull.Value)
                {
                    Label1.Text = dt.Rows[0]["remarks"].ToString();
                }
                else
                {
                    Label1.Text = "No remarks";
                }

                // ✅ Bind bills
                gvSelectedBills.DataSource = dt;
                gvSelectedBills.DataBind();

                // ✅ Show the payment summary modal
                ScriptManager.RegisterStartupScript(
                    this,
                    this.GetType(),
                    "ShowPaymentModal",
                    "setTimeout(function(){ $('#paymentSummaryModal').modal('show'); }, 300);",
                    true
                );
            }
        }
        private void HideAllPaymentPanels()
        {
            if (Panelcheque != null) Panelcheque.Visible = false;
            if (panelonline != null) panelonline.Visible = false;
            if (Panelcash != null) Panelcash.Visible = false;

            UpdatePanel2.Update();
        }

        protected void btncheque_Click(object sender, EventArgs e)
        {
            Panelcheque.Visible = true;
            panelonline.Visible = false;
            Panelcash.Visible = false;

            // ✅ Use GetPaymentAmountByType() instead of GetValidGrandTotal()
            string totalAmount = GetPaymentAmountByType();

            System.Diagnostics.Debug.WriteLine($"=== btncheque_Click ===");
            System.Diagnostics.Debug.WriteLine($"Payment Type: {ddlSevice.SelectedValue}");
            System.Diagnostics.Debug.WriteLine($"Service Cost: {txtServiceCost.Text}");
            System.Diagnostics.Debug.WriteLine($"Grand Total: {hdnGrandTotal.Value}");
            System.Diagnostics.Debug.WriteLine($"Calculated Amount: {totalAmount}");

            if (!string.IsNullOrEmpty(totalAmount))
            {
                txtcheqamount.Text = totalAmount;
                System.Diagnostics.Debug.WriteLine($"✅ Cheque amount set: {totalAmount}");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine("⚠️ Amount is empty or 0");
            }

            UpdatePanel2.Update();
        }

        protected void btnonline_Click(object sender, EventArgs e)
        {
            panelonline.Visible = true;
            Panelcheque.Visible = false;
            Panelcash.Visible = false;

            // ✅ Use GetPaymentAmountByType() instead of GetValidGrandTotal()
            string totalAmount = GetPaymentAmountByType();

            System.Diagnostics.Debug.WriteLine($"=== btnonline_Click ===");
            System.Diagnostics.Debug.WriteLine($"Payment Type: {ddlSevice.SelectedValue}");
            System.Diagnostics.Debug.WriteLine($"Service Cost: {txtServiceCost.Text}");
            System.Diagnostics.Debug.WriteLine($"Grand Total: {hdnGrandTotal.Value}");
            System.Diagnostics.Debug.WriteLine($"Calculated Amount: {totalAmount}");

            if (!string.IsNullOrEmpty(totalAmount))
            {
                txtonlineamount.Text = totalAmount;
                System.Diagnostics.Debug.WriteLine($"✅ Online amount set: {totalAmount}");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine("⚠️ Amount is empty or 0");
            }

            UpdatePanel2.Update();
        }

        protected void btncash_Click(object sender, EventArgs e)
        {

            Panelcash.Visible = true;
            Panelcheque.Visible = false;
            panelonline.Visible = false;

            // ✅ Use GetPaymentAmountByType() instead of GetValidGrandTotal()
            string totalAmount = GetPaymentAmountByType();

            System.Diagnostics.Debug.WriteLine($"=== btncash_Click ===");
            System.Diagnostics.Debug.WriteLine($"Payment Type: {ddlSevice.SelectedValue}");
            System.Diagnostics.Debug.WriteLine($"Service Cost: {txtServiceCost.Text}");
            System.Diagnostics.Debug.WriteLine($"Grand Total: {hdnGrandTotal.Value}");
            System.Diagnostics.Debug.WriteLine($"Calculated Amount: {totalAmount}");

            if (!string.IsNullOrEmpty(totalAmount))
            {
                txtcashamount.Text = totalAmount;
                System.Diagnostics.Debug.WriteLine($"✅ Cash amount set: {totalAmount}");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine("⚠️ Amount is empty or 0");
            }

            UpdatePanel2.Update();
        }

        private string GetValidGrandTotal()
        {
            decimal grandTotal = 0m;

            if (!string.IsNullOrEmpty(hdnGrandTotal.Value))
            {
                decimal.TryParse(hdnGrandTotal.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out grandTotal);
            }

            System.Diagnostics.Debug.WriteLine($"📊 GetValidGrandTotal: {grandTotal}");
            return grandTotal > 0 ? grandTotal.ToString("0.00") : "";
        }
        private bool ValidatePay()
        {
            if (Panelcheque.Visible)
            {
                // ✅ Enhanced validation for cheque number
                if (string.IsNullOrWhiteSpace(txtcheqno.Text))
                {
                    ShowPaymentMessage("⚠️ Cheque number is mandatory. Please enter cheque number.", "warning");

                    // ✅ Add client-side focus for better UX
                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusChequeNo",
                        "$('#" + txtcheqno.ClientID + "').focus();", true);

                    return false;
                }

                // ✅ Validate cheque date
                if (string.IsNullOrWhiteSpace(txtcheqdate.Text))
                {
                    ShowPaymentMessage("⚠️ Cheque date is mandatory. Please select cheque date.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusChequeDate",
                        "$('#" + txtcheqdate.ClientID + "').focus();", true);

                    return false;
                }

                // ✅ Validate cheque date is not in future
                DateTime chequeDate;
                if (DateTime.TryParse(txtcheqdate.Text, out chequeDate))
                {
                    if (chequeDate > DateTime.Now.Date)
                    {
                        ShowPaymentMessage("⚠️ Cheque date cannot be in the future.", "warning");
                        return false;
                    }
                }

                // ✅ Validate bank name
                if (string.IsNullOrWhiteSpace(txtbank.Text))
                {
                    ShowPaymentMessage("⚠️ Bank name is mandatory. Please enter bank name.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusBankName",
                        "$('#" + txtbank.ClientID + "').focus();", true);

                    return false;
                }

                // ✅ Validate amount
                if (string.IsNullOrWhiteSpace(txtcheqamount.Text) || Convert.ToDecimal(txtcheqamount.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusChequeAmount",
                        "$('#" + txtcheqamount.ClientID + "').focus();", true);

                    return false;
                }
            }

            if (panelonline.Visible)
            {
                if (string.IsNullOrWhiteSpace(txttrasaction.Text))
                {
                    ShowPaymentMessage("⚠️ Transaction reference is mandatory. Please enter transaction ID.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusTransaction",
                        "$('#" + txttrasaction.ClientID + "').focus();", true);

                    return false;
                }

                if (string.IsNullOrWhiteSpace(txtonlineamount.Text) || Convert.ToDecimal(txtonlineamount.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusOnlineAmount",
                        "$('#" + txtonlineamount.ClientID + "').focus();", true);

                    return false;
                }
            }

            if (Panelcash.Visible)
            {
                if (string.IsNullOrWhiteSpace(txtcashamount.Text) || Convert.ToDecimal(txtcashamount.Text) <= 0)
                {
                    ShowPaymentMessage("⚠️ Please enter valid cash amount.", "warning");

                    ScriptManager.RegisterStartupScript(this, GetType(), "FocusCashAmount",
                        "$('#" + txtcashamount.ClientID + "').focus();", true);

                    return false;
                }
            }

            return true;
        }


        
        private void UpdateSelectedStaffDisplay()
        {
            try
            {
                DataTable selectedDt = (DataTable)ViewState["SelectedStaff"];

                if (selectedDt != null && selectedDt.Rows.Count > 0)
                {
                    // Calculate total salary
                    decimal totalSalary = 0;
                    foreach (DataRow dr in selectedDt.Rows)
                    {
                        if (dr["salary"] != DBNull.Value)
                        {
                            totalSalary += Convert.ToDecimal(dr["salary"]);
                        }
                    }

                    // Update only the label that exists
                    lblSelectedTotal.Text = totalSalary.ToString("N2");
                    hdnGrandTotal.Value = totalSalary.ToString("0.00");
                }
                else
                {
                    lblSelectedTotal.Text = "0.00";
                    hdnGrandTotal.Value = "0.00";
                }
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "UpdateError",
                    $"console.log('Error: {ex.Message}');", true);
            }
        }

        // ✅ ddlStaffType_SelectedIndexChanged
        protected void ddlStaffType_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(ddlStaffType.SelectedValue))
            {
                LoadStaffByRole(Convert.ToInt32(ddlStaffType.SelectedValue));
                pnlStaffList.Visible = true;
              //  chkSelectAllStaff.Checked = false;
                upStaffList.Update();
            }
            else
            {
                pnlStaffList.Visible = false;
                lblSelectedTotal.Text = "0.00";
            }
        }







        // ✅ CRITICAL FIX #1: Individual Staff Checkbox Changed
        protected void chkStaff_CheckedChanged(object sender, EventArgs e)
        {
            WebCheckBox chk = (WebCheckBox)sender;
            GridViewRow row = (GridViewRow)chk.NamingContainer;

            Label lblStaffId = (Label)row.FindControl("lblStaffId");
            Label lblStaffName = (Label)row.FindControl("lblStaffName");
            System.Web.UI.WebControls.TextBox txtSalary = (System.Web.UI.WebControls.TextBox)row.FindControl("txtSalary");

            DataTable selectedDt = (DataTable)ViewState["SelectedStaff"];
            if (selectedDt == null)
            {
                selectedDt = CreateSelectedStaffTable();
                ViewState["SelectedStaff"] = selectedDt;
            }

            if (chk.Checked)
            {
                // ✅ FIX: Check if already exists before adding
                bool exists = false;
                foreach (DataRow dr in selectedDt.Rows)
                {
                    if (dr.RowState != DataRowState.Deleted &&
                        dr["staff_id"].ToString() == lblStaffId.Text)
                    {
                        exists = true;
                        // Update salary if it changed
                        decimal salary = 0;
                        if (txtSalary != null && decimal.TryParse(txtSalary.Text, out salary))
                        {
                            dr["salary"] = salary;
                        }
                        break;
                    }
                }

                if (!exists)
                {
                    DataRow newRow = selectedDt.NewRow();
                    newRow["staff_id"] = Convert.ToInt32(lblStaffId.Text);
                    newRow["name"] = lblStaffName.Text;

                    decimal salary = 0;
                    if (txtSalary != null && decimal.TryParse(txtSalary.Text, out salary))
                    {
                        newRow["salary"] = salary;
                    }
                    else
                    {
                        newRow["salary"] = 0;
                    }

                    newRow["role_id"] = Convert.ToInt32(ddlStaffType.SelectedValue);
                    selectedDt.Rows.Add(newRow);
                }
            }
            else
            {
                // ✅ FIX: Remove ONLY the specific staff that was unchecked
                for (int i = selectedDt.Rows.Count - 1; i >= 0; i--)
                {
                    if (selectedDt.Rows[i].RowState != DataRowState.Deleted &&
                        selectedDt.Rows[i]["staff_id"].ToString() == lblStaffId.Text)
                    {
                        selectedDt.Rows.RemoveAt(i);
                        break; // ✅ IMPORTANT: Break after removing
                    }
                }
            }

            // ✅ Accept changes to properly update the DataTable
            selectedDt.AcceptChanges();
            ViewState["SelectedStaff"] = selectedDt;

            CalculateSelectedTotal();
            UpdateSelectAllCheckbox();
        }
        private void UpdateSelectAllCheckbox()
        {
            if (gvStaffList.Rows.Count == 0)
            {
              //  chkSelectAllStaff.Checked = false;
                return;
            }

            bool allChecked = true;
            foreach (GridViewRow row in gvStaffList.Rows)
            {
                WebCheckBox chk = (WebCheckBox)row.FindControl("chkStaff");
                if (chk != null && !chk.Checked)
                {
                    allChecked = false;
                    break;
                }
            }

            //chkSelectAllStaff.Checked = allChecked;
        }

        // ✅ CRITICAL FIX #4: Calculate Selected Total (Only from CHECKED rows)
        private void CalculateSelectedTotal()
        {
            decimal totalSalary = 0;

            // ✅ Loop through GridView rows, NOT ViewState
            foreach (GridViewRow row in gvStaffList.Rows)
            {
                WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");
                System.Web.UI.WebControls.TextBox txtSalary = (System.Web.UI.WebControls.TextBox)row.FindControl("txtSalary");

                // ✅ Only count CHECKED rows
                if (chkStaff != null && chkStaff.Checked && txtSalary != null)
                {
                    decimal salary = 0;
                    if (decimal.TryParse(txtSalary.Text, out salary))
                    {
                        totalSalary += salary;
                    }
                }
            }

            lblSelectedTotal.Text = totalSalary.ToString("N2");
            hdnGrandTotal.Value = totalSalary.ToString("0.00");

            // Update payment amount field if exists
            if (txtcheqamount != null)
            {
                txtcheqamount.Text = totalSalary.ToString("0.00");
            }
            if (txtonlineamount != null)
            {
                txtonlineamount.Text = totalSalary.ToString("0.00");
            }
            if (txtcashamount != null)
            {
                txtcashamount.Text = totalSalary.ToString("0.00");
            }
            upStaffList.Update();
        }

        // ✅ CRITICAL FIX #5: Salary Text Changed
        protected void txtSalary_TextChanged(object sender, EventArgs e)
        {
            System.Web.UI.WebControls.TextBox txt = (System.Web.UI.WebControls.TextBox)sender;
            GridViewRow row = (GridViewRow)txt.NamingContainer;

            Label lblStaffId = (Label)row.FindControl("lblStaffId");
            WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");

            // Validate and format
            decimal salary = 0;
            if (decimal.TryParse(txt.Text, out salary))
            {
                txt.Text = salary.ToString("0.00");

                // ✅ Update in ViewState if checkbox is checked
                if (chkStaff != null && chkStaff.Checked)
                {
                    DataTable selectedDt = (DataTable)ViewState["SelectedStaff"];
                    if (selectedDt != null)
                    {
                        foreach (DataRow dr in selectedDt.Rows)
                        {
                            if (dr.RowState != DataRowState.Deleted &&
                                dr["staff_id"].ToString() == lblStaffId.Text)
                            {
                                dr["salary"] = salary;
                                break;
                            }
                        }
                        selectedDt.AcceptChanges();
                        ViewState["SelectedStaff"] = selectedDt;
                    }
                }
            }
            else
            {
                txt.Text = "0.00";
            }

            CalculateSelectedTotal();
        }

        // ✅ CRITICAL FIX #6: Row Data Bound (Restore checkbox state)
        protected void gvStaffList_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                DataTable selectedDt = (DataTable)ViewState["SelectedStaff"];

                Label lblStaffId = (Label)e.Row.FindControl("lblStaffId");
                WebCheckBox chkStaff = (WebCheckBox)e.Row.FindControl("chkStaff");
                System.Web.UI.WebControls.TextBox txtSalary = (System.Web.UI.WebControls.TextBox)e.Row.FindControl("txtSalary");

                if (txtSalary != null)
                {
                    txtSalary.Attributes.Add("onkeypress", "return isNumberKey(event)");
                    txtSalary.Attributes.Add("placeholder", "Enter amount");

                    decimal salary = 0;
                    if (decimal.TryParse(txtSalary.Text, out salary))
                    {
                        txtSalary.Text = salary.ToString("0.00");
                    }
                }

                // ✅ Restore checkbox state from ViewState
                if (selectedDt != null && lblStaffId != null && chkStaff != null)
                {
                    foreach (DataRow dr in selectedDt.Rows)
                    {
                        if (dr.RowState != DataRowState.Deleted &&
                            dr["staff_id"].ToString() == lblStaffId.Text)
                        {
                            chkStaff.Checked = true;

                            if (txtSalary != null && dr["salary"] != DBNull.Value)
                            {
                                txtSalary.Text = Convert.ToDecimal(dr["salary"]).ToString("0.00");
                            }
                            break;
                        }
                    }
                }
            }
        }

        // ✅ CRITICAL FIX #7: Load Staff By Role (Clear old selections)
        private void LoadStaffByRole(int roleId)
        {
            try
            {
                staff Staff = new staff();
                Staff.Sql_Operation = "FetchStaffData";
                Staff.Society_Id = Session["society_id"].ToString();
                Staff.role_id = roleId;

                DataTable dt = bL_Staff.getstaffdata(Staff);

                if (dt != null && dt.Rows.Count > 0)
                {
                    gvStaffList.DataSource = dt;
                    gvStaffList.DataBind();

                    // ✅ Clear selections from different roles
                    DataTable selectedDt = (DataTable)ViewState["SelectedStaff"];
                    if (selectedDt != null)
                    {
                        for (int i = selectedDt.Rows.Count - 1; i >= 0; i--)
                        {
                            if (selectedDt.Rows[i].RowState != DataRowState.Deleted &&
                                selectedDt.Rows[i]["role_id"].ToString() != roleId.ToString())
                            {
                                selectedDt.Rows.RemoveAt(i);
                            }
                        }
                        selectedDt.AcceptChanges();
                        ViewState["SelectedStaff"] = selectedDt;
                    }

                    // Restore checkboxes for current role
                    foreach (GridViewRow row in gvStaffList.Rows)
                    {
                        Label lblStaffId = (Label)row.FindControl("lblStaffId");
                        WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");
                        System.Web.UI.WebControls.TextBox txtSalary = (System.Web.UI.WebControls.TextBox)row.FindControl("txtSalary");

                        if (selectedDt != null && lblStaffId != null && chkStaff != null)
                        {
                            foreach (DataRow dr in selectedDt.Rows)
                            {
                                if (dr.RowState != DataRowState.Deleted &&
                                    dr["staff_id"].ToString() == lblStaffId.Text &&
                                    dr["role_id"].ToString() == roleId.ToString())
                                {
                                    chkStaff.Checked = true;

                                    if (txtSalary != null && dr["salary"] != DBNull.Value)
                                    {
                                        txtSalary.Text = Convert.ToDecimal(dr["salary"]).ToString("0.00");
                                    }
                                    break;
                                }
                            }
                        }
                    }

                    CalculateSelectedTotal();
                    UpdateSelectAllCheckbox();
                }
                else
                {
                    gvStaffList.DataSource = null;
                    gvStaffList.DataBind();
                    ScriptManager.RegisterStartupScript(this, GetType(), "NoStaffAlert",
                        "alert('No staff found for selected type');", true);
                }
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "ErrorAlert",
                    $"alert('Error loading staff: {ex.Message}');", true);
            }
        }

        // ✅ Helper Methods
        private DataTable CreateSelectedStaffTable()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("staff_id", typeof(int));
            dt.Columns.Add("name", typeof(string));
            dt.Columns.Add("salary", typeof(decimal));
            dt.Columns.Add("role_id", typeof(int));
            return dt;
        }

        private void ClearStaffPaymentForm()
        {
            ddlStaffType.SelectedIndex = 0;
            pnlStaffList.Visible = false;
            txtcashamount.Text = "";
            txtcheqamount.Text = "";
            txtcheqdate.Text = "";
            txtcheqno.Text = "";
            txttrasaction.Text = "";
            txtonlineamount.Text = "";
            txttrasaction.Text = "";

            ViewState["SelectedStaff"] = CreateSelectedStaffTable();
            lblSelectedTotal.Text = "0.00";
            hdnGrandTotal.Value = "0.00";
        }

        private void SaveStaffPaymentBills()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("=== SaveStaffPaymentBills STARTED ===");
                
                // ✅ 1. Validate Staff Type
                if (string.IsNullOrEmpty(ddlStaffType.SelectedValue))
                {
                    throw new Exception("Please select Staff Type");
                }

                // ✅ 2. Collect Selected Staff
                List<int> staffIds = new List<int>();
                List<string> staffNames = new List<string>();
                List<decimal> salaries = new List<decimal>();

                foreach (GridViewRow row in gvStaffList.Rows)
                {
                    WebCheckBox chkStaff = (WebCheckBox)row.FindControl("chkStaff");

                    if (chkStaff != null && chkStaff.Checked)
                    {
                        Label lblStaffId = (Label)row.FindControl("lblStaffId");
                        Label lblStaffName = (Label)row.FindControl("lblStaffName");
                        System.Web.UI.WebControls.TextBox txtSalary =
                            (System.Web.UI.WebControls.TextBox)row.FindControl("txtSalary");

                        if (lblStaffId != null && lblStaffName != null && txtSalary != null)
                        {
                            decimal salary = 0;
                            if (!decimal.TryParse(txtSalary.Text, out salary) || salary <= 0)
                            {
                                throw new Exception($"Please enter valid salary for {lblStaffName.Text}");
                            }

                            staffIds.Add(Convert.ToInt32(lblStaffId.Text));
                            staffNames.Add(lblStaffName.Text);
                            salaries.Add(salary);
                        }
                    }
                }

                // ✅ 3. Validate Selection
                if (staffIds.Count == 0)
                {
                    throw new Exception("Please select at least one staff member");
                }


                // ✅ 4. Get Payment Month
                DateTime paymentMonth;
                if (string.IsNullOrWhiteSpace(txtPaymentMonth.Text))
                {
                    paymentMonth = DateTime.Now;
                }
                else if (!DateTime.TryParse(txtPaymentMonth.Text, out paymentMonth))
                {
                    throw new Exception("Invalid Payment Month");
                }

                // ✅ 5. Calculate Total
                decimal totalSalary = salaries.Sum();

                // ✅ 6. Create Bill (WITHOUT Payment Details)
                int roleId = Convert.ToInt32(ddlStaffType.SelectedValue);
                string roleName = ddlStaffType.SelectedItem.Text;
                string billNumber = $"STAFF-{roleId}-{paymentMonth:yyyyMM}-{DateTime.Now:HHmmss}";

                string staffIdsStr = string.Join(",", staffIds);
                string salariesStr = string.Join(",", salaries.Select(s => s.ToString("0.00")));
                string staffNamesStr = string.Join(", ", staffNames);

                vendor.BillNo = billNumber;
                vendor.Sql_Operation = "INSERT";
                vendor.BillDate = paymentMonth;
                vendor.Service = 0; // Staff Payment
                vendor.vendor_id = staffIdsStr; // Store all staff IDs
                vendor.Note = $"STAFF_IDS:{staffIdsStr}|SALARIES:{salariesStr}";
                vendor.SubTotal = totalSalary;
                vendor.TaxAmount = 0m;
                vendor.TotalAmount = totalSalary;
                vendor.Society_Id = Session["society_id"].ToString();
                vendor.User_id = Convert.ToInt32(Session["UserId"]);
                vendor.Description = $"Salary Payment | Role: {roleName} | Staff: {staffNamesStr} | Month: {paymentMonth:MMM-yyyy}";

                var resultBill = bL_vendor_bill.createBill(vendor);

                if (resultBill == null || resultBill.Bill_id <= 0)
                {
                    throw new Exception("Bill creation failed");
                }

                System.Diagnostics.Debug.WriteLine($"✅ Bill created: ID = {resultBill.Bill_id}");

                // ✅ 7. Store bill details for payment processing
                hfPayBillId.Value = resultBill.Bill_id.ToString();
                hfPayVendorId.Value = staffIdsStr; // Store all staff IDs

                // ✅ 8. Check if payment section is visible
                bool paymentSectionVisible = paymentSection.Style["display"] != "none";
                System.Diagnostics.Debug.WriteLine($"💳 Payment section visible: {paymentSectionVisible}");

                if (paymentSectionVisible)
                {
                    System.Diagnostics.Debug.WriteLine("→ Processing Staff Payment");

                    // Process payment using the common payment panel
                    if (SavePaymentIfValid())
                    {
                        System.Diagnostics.Debug.WriteLine("   ✅ Payment saved successfully");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("   ⚠️ Payment validation failed or skipped");
                    }
                }

                // ✅ 9. Clear Form
                ClearStaffPaymentForm();

                System.Diagnostics.Debug.WriteLine("=== SaveStaffPaymentBills COMPLETED ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ ERROR: {ex.Message}");
                throw;
            }
        }

     
        private bool SavePaymentIfValid()
        {
            if (!ValidatePay())
            {
                UpdatePanel2.Update();
                ScriptManager.RegisterStartupScript(this, GetType(),
                    "KeepModalOpen", "$('#paymentModal').modal('show');", true);
                return false;
            }

            SavePaymentClick();
            return true;
        }

        private void SavePaymentClick()
        {
            try
            {
                // ✅ STEP 1: Validate Bill ID
                if (string.IsNullOrWhiteSpace(hfPayBillId.Value))
                {
                  
                    ShowPaymentMessage("Bill ID not found", "danger");
                    return;
                }
                System.Diagnostics.Debug.WriteLine($"✓ Bill ID: {hfPayBillId.Value}");

                // ✅ STEP 2: Get Bill Details to retrieve salary information
                vendor.Sql_Operation = "select";
                vendor.Bill_id = Convert.ToInt32(hfPayBillId.Value);
                var billDetails = bL_vendor_bill.getVendorBillDetails(vendor);

                if (billDetails == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ ERROR: Bill details not found");
                    ShowPaymentMessage("Bill information not found", "danger");
                    return;
                }

                // 🔥 CRITICAL: Parse STAFF IDs and ACTUAL SALARIES from Note
                string[] vendorStaffIds = null;
                decimal[] salaryAmounts = null;

                // ✅ Check if this is a Staff Payment (Service = 0)
                if (billDetails.Service == 0 && !string.IsNullOrEmpty(billDetails.Note))
                {
                    System.Diagnostics.Debug.WriteLine("→ This is a STAFF PAYMENT");
                    System.Diagnostics.Debug.WriteLine($"   Note: {billDetails.Note}");

                    try
                    {
                        // Parse Note: "STAFF_IDS:1,2|SALARIES:5000.00,6000.00"
                        string[] noteParts = billDetails.Note.Split('|');

                        if (noteParts.Length >= 2)
                        {
                            string staffIdsStr = noteParts[0].Replace("STAFF_IDS:", "").Trim();
                            string salariesStr = noteParts[1].Replace("SALARIES:", "").Trim();

                            vendorStaffIds = staffIdsStr.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                            string[] salariesStrArray = salariesStr.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);

                            if (vendorStaffIds.Length != salariesStrArray.Length)
                            {
                                System.Diagnostics.Debug.WriteLine("❌ ERROR: Staff IDs and Salaries count mismatch");
                                ShowPaymentMessage("Data mismatch error", "danger");
                                return;
                            }

                            // Convert salary strings to decimal array
                            salaryAmounts = new decimal[salariesStrArray.Length];
                            for (int i = 0; i < salariesStrArray.Length; i++)
                            {
                                if (!decimal.TryParse(salariesStrArray[i].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out salaryAmounts[i]))
                                {
                                    System.Diagnostics.Debug.WriteLine($"❌ ERROR: Invalid salary at index {i}: {salariesStrArray[i]}");
                                    ShowPaymentMessage("Invalid salary data", "danger");
                                    return;
                                }
                            }

                            System.Diagnostics.Debug.WriteLine($"✓ Parsed {vendorStaffIds.Length} staff members with salaries:");
                            for (int i = 0; i < vendorStaffIds.Length; i++)
                            {
                                System.Diagnostics.Debug.WriteLine($"   Staff ID {vendorStaffIds[i].Trim()} → Salary: ₹{salaryAmounts[i]:N2}");
                            }
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("⚠️ WARNING: Note format incorrect, falling back to equal division");
                        }
                    }
                    catch (Exception parseEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠️ WARNING: Error parsing Note: {parseEx.Message}");
                        System.Diagnostics.Debug.WriteLine("   Falling back to hfPayVendorId.Value");
                    }
                }

                // ✅ FALLBACK: If not staff payment OR parsing failed, use hfPayVendorId
                if (vendorStaffIds == null || salaryAmounts == null)
                {

                    if (string.IsNullOrWhiteSpace(hfPayVendorId.Value))
                    {
                        ShowPaymentMessage("Vendor/Staff IDs not found", "danger");
                        return;
                    }

                    vendorStaffIds = hfPayVendorId.Value.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                   
                }

                // ✅ STEP 3: Get Total Amount from Payment Panel
                decimal totalAmount = 0m;
                string paymentPanel = "";

                if (Panelcheque != null && Panelcheque.Visible)
                {
                    paymentPanel = "Cheque";
                    if (!decimal.TryParse(txtcheqamount.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                    {
                        ShowPaymentMessage("Invalid cheque amount", "danger");
                        return;
                    }
                }
                else if (panelonline != null && panelonline.Visible)
                {
                    paymentPanel = "Online";
                    if (!decimal.TryParse(txtonlineamount.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                    {
                        ShowPaymentMessage("Invalid online amount", "danger");
                        return;
                    }
                }
                else if (Panelcash != null && Panelcash.Visible)
                {
                    paymentPanel = "Cash";
                    if (!decimal.TryParse(txtcashamount.Text.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out totalAmount))
                    {
                        ShowPaymentMessage("Invalid cash amount", "danger");
                        return;
                    }
                }
                else
                {
                    ShowPaymentMessage("Please select payment mode", "danger");
                    return;
                }

             

                if (totalAmount <= 0)
                {
                    ShowPaymentMessage("Amount must be greater than 0", "danger");
                    return;
                }

                // ✅ STEP 4: Upload File (ONCE)
                string filePath = string.Empty;
                if (FileUpload2 != null && FileUpload2.HasFile)
                {
                    try
                    {
                        filePath = UploadFile();
                        System.Diagnostics.Debug.WriteLine($"✓ File Uploaded: {filePath}");
                    }
                    catch (Exception fileEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠ File Upload Warning: {fileEx.Message}");
                    }
                }

                // ✅ STEP 5: Get Common Payment Details
                string payMode = string.Empty;
                string chequeNo = string.Empty;
                string chequeDate = string.Empty;
                string bankName = string.Empty;
                string transactionRef = string.Empty;

                if (paymentPanel == "Cheque")
                {
                    payMode = "Cheque";
                    chequeNo = txtcheqno?.Text.Trim() ?? "";
                    chequeDate = txtcheqdate?.Text.Trim() ?? "";
                    bankName = txtbank?.Text.Trim() ?? "";
                }
                else if (paymentPanel == "Online")
                {
                    payMode = "Online";
                    transactionRef = txttrasaction?.Text.Trim() ?? "";
                }
                else if (paymentPanel == "Cash")
                {
                    payMode = "Cash";
                }

                string remarks = txtre?.Text.Trim() ?? "";

                int successCount = 0;
                int failCount = 0;
                decimal totalPaidAmount = 0m;

                for (int i = 0; i < vendorStaffIds.Length; i++)
                {
                    string currentId = vendorStaffIds[i].Trim();

                    if (string.IsNullOrWhiteSpace(currentId))
                    {
                       
                        continue;
                    }

                    // 🔥 GET ACTUAL SALARY for this staff member
                    decimal paymentAmount;

                    if (salaryAmounts != null && i < salaryAmounts.Length)
                    {
                        // ✅ USE ACTUAL SALARY from Note
                        paymentAmount = salaryAmounts[i];
                   
                    }
                    else
                    {
                        // ✅ FALLBACK: Equal division (for non-staff payments)
                        paymentAmount = Math.Round(totalAmount / vendorStaffIds.Length, 2);
                      
                    }

                    try
                    {
                        Vendor payVendor = new Vendor();

                        payVendor.Sql_Operation = "INSERT";
                        payVendor.BillIds = hfPayBillId.Value;
                        payVendor.vendor_id = currentId;
                        payVendor.Society_Id = Session["society_id"]?.ToString() ?? "";
                        payVendor.User_id = Convert.ToInt32(Session["UserId"]);
                        payVendor.TotalAmount = paymentAmount; // 🔥 ACTUAL SALARY
                        payVendor.PayMode = payMode;
                        payVendor.Remark = remarks;
                        payVendor.FilePath = filePath;

                        if (payMode == "Cheque")
                        {
                            payVendor.ChequeNo = chequeNo;
                            payVendor.ChequeDate = chequeDate;
                            payVendor.BankName = bankName;
                        }
                        else if (payMode == "Online")
                        {
                            payVendor.TransactionRef = transactionRef;
                        }


                        var result = bL_vendor_bill.saveVendorBill(payVendor);

                        if (result != null && result.Sql_Result == "Done")
                        {
                            successCount++;
                            totalPaidAmount += paymentAmount;
                           
                        }
                        else
                        {
                            failCount++;
                            string errorMsg = result?.Sql_Result ?? "Unknown error";
                         
                        }
                    }
                    catch (Exception idEx)
                    {
                        failCount++;
                       
                    }
                }


                if (successCount > 0)
                {
                    ShowPaymentMessage($"✅ {successCount} payment(s) saved successfully!", "success");

                    // Clear form
                    if (txtcheqno != null) txtcheqno.Text = "";
                    if (txtcheqdate != null) txtcheqdate.Text = "";
                    if (txtbank != null) txtbank.Text = "";
                    if (txtcheqamount != null) txtcheqamount.Text = "";
                    if (txttrasaction != null) txttrasaction.Text = "";
                    if (txtonlineamount != null) txtonlineamount.Text = "";
                    if (txtcashamount != null) txtcashamount.Text = "";
                    if (txtre != null) txtre.Text = "";
                }

                if (failCount > 0)
                {
                    ShowPaymentMessage($"⚠️ Warning: {failCount} payment(s) failed.", "warning");
                }

            }
            catch (Exception ex)
            {
                ShowPaymentMessage($"Error: {ex.Message}", "danger");
            }
        }
        // ✅ REPLACE existing GetPaymentAmountByType() method with this:
        private string GetPaymentAmountByType()
        {
            decimal amount = 0m;

            if (ddlSevice.SelectedValue == "3")
            {
                // ✅ Service Payment - use txtServiceCost
                if (!string.IsNullOrEmpty(txtServiceCost.Text))
                {
                    decimal.TryParse(txtServiceCost.Text, NumberStyles.Any, CultureInfo.InvariantCulture, out amount);
                    System.Diagnostics.Debug.WriteLine($"📊 Service Payment - Service Cost: ₹{amount}");
                }
            }
            else
            {
                // ✅ All other types (Staff=0, Daily=1, Vendor=2) - use hdnGrandTotal
                if (!string.IsNullOrEmpty(hdnGrandTotal.Value))
                {
                    decimal.TryParse(hdnGrandTotal.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out amount);
                    System.Diagnostics.Debug.WriteLine($"📊 Other Payment Type - Grand Total: ₹{amount}");
                }
            }

            return amount > 0 ? amount.ToString("0.00") : "";
        }

  
        // ✅✅✅ ADD NEW HELPER METHOD to check if payment data is filled
        private bool IsPaymentDataFilled()
        {
            decimal dummy;

            bool hasCashAmount = !string.IsNullOrWhiteSpace(txtcashamount.Text) &&
                                 decimal.TryParse(txtcashamount.Text, out dummy) && dummy > 0;

            bool hasChequeAmount = !string.IsNullOrWhiteSpace(txtcheqamount.Text) &&
                                   decimal.TryParse(txtcheqamount.Text, out dummy) && dummy > 0;

            bool hasOnlineAmount = !string.IsNullOrWhiteSpace(txtonlineamount.Text) &&
                                   decimal.TryParse(txtonlineamount.Text, out dummy) && dummy > 0;

            return hasCashAmount || hasChequeAmount || hasOnlineAmount;
        }
    }
}