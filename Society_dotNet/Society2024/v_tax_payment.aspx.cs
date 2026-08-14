 using BusinessLogic.BL;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Wordprocessing;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using Utility.DataClass;
using CheckBox = System.Web.UI.WebControls.CheckBox;

namespace Society
{
    public partial class waste_tax_v : System.Web.UI.Page
    {

        bl_v_resident bL_House = new bl_v_resident();
        receipt payment = new receipt();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                BindData();
            }
        }


        protected void gvPending_Sorting(object sender, GridViewSortEventArgs e)
        {
            //DataTable dt = ViewState["PendingTable"] as DataTable;
            //if (dt == null) return;

            //string direction = GetSortDirection(e.SortExpression);

            //dt.DefaultView.Sort = e.SortExpression + " " + direction;
            //gvPending.DataSource = dt;
            //gvPending.DataBind();

            DataTable dtrslt = (DataTable)ViewState["PendingState"];
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
                gvPending.DataSource = dtrslt;
                gvPending.DataBind();
            }
        }

        private string GetSortDirection(string column)
        {
            string direction = "ASC";

            string lastColumn = ViewState["SortColumn"] as string;
            string lastDirection = ViewState["SortDirection"] as string;

            if (lastColumn == column && lastDirection == "ASC")
            {
                direction = "DESC";
            }

            ViewState["SortColumn"] = column;
            ViewState["SortDirection"] = direction;

            return direction;
        }



        private void BindData()
        {
            DataTable dtPending = bL_House.gridbind_pending(Session["village_id"].ToString(), "Grid_pending_charges");
            ViewState["PendingState"] = dtPending;
            gvPending.DataSource = dtPending;
            gvPending.DataBind();

            // Bind paid table (unchanged)
            DataTable dtPaid = bL_House.gridbind_pending(Session["village_id"].ToString(), "Grid_paid_charges");
            ViewState["PaidState"] = dtPaid;
            gvPaid.DataSource = dtPaid;
            gvPaid.DataBind();
    
        }



        protected void btnSendSMS_Click(object sender, EventArgs e)
        {
            List<homeModal> selectedUsers = new List<homeModal>();

            foreach (GridViewRow row in gvPending.Rows)
            {
                CheckBox chk = row.FindControl("chkSelect") as CheckBox;

                if (chk != null && chk.Checked)
                {
                    var hfOwner = row.FindControl("hfOwner") as HiddenField;
                    var hfMobile = row.FindControl("hfMobile") as HiddenField;
                    var hfWater = row.FindControl("hfWater") as HiddenField;
                    var hfProperty = row.FindControl("hfProperty") as HiddenField;
                    var hfWaste = row.FindControl("hfWaste") as HiddenField;
                    homeModal house = new homeModal();

                    house.Owner_Name = hfOwner?.Value;
                    house.phone = hfMobile?.Value;
                    house.Tap_Charges = Convert.ToDecimal(hfWater?.Value);
                    house.Sqft_Charges = Convert.ToDecimal(hfProperty?.Value);
                    house.Solid_Waste_Fee = Convert.ToDecimal(hfWaste?.Value);
                    selectedUsers.Add(house);
                    
                }
            }

            if (selectedUsers.Count == 0)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "alertNoSelect",
                    "alert('Please select at least one user.');", true);
                return;
            }

            // selectedUsers now contains everything you need for each selected row
            // Process the data here...
        }

        protected void gvPending_RowCommand(object sender, GridViewCommandEventArgs e)
        {

            int house_id;
            if (!int.TryParse(e.CommandArgument?.ToString(), out house_id))
            {
                // Log it so you know what's actually coming in
                // Or show a message, or ignore silently
                return;
            }

            PopulateModal(house_id, e.CommandName);
            ScriptManager.RegisterStartupScript(this, GetType(), "showModal", "$('#taxModal').modal('show');", true);
        }

        private void PopulateModal(int house_id, string taxType)
        {
            DataTable dt = new DataTable();
            hfUser.Value = house_id.ToString();
                
            if (taxType == "ViewWater")
            {
                dt = bL_House.gridbind_pending_specific_tax("Grid_not_paid_W", Session["village_id"].ToString(), 2, house_id);
            }
            else if (taxType == "ViewProperty")
            {
                dt = bL_House.gridbind_pending_specific_tax("Grid_not_paid_p", Session["village_id"].ToString(), 1, house_id);
            }
            else if (taxType == "ViewWaste")
            {
                dt = bL_House.gridbind_pending_specific_tax("Grid_not_paid_m", Session["village_id"].ToString(), 3, house_id);
            }

            if (dt != null && dt.Rows.Count > 0)
            {
                DataRow row = dt.Rows[0];

                // Get owner name
                string ownerName = row.Table.Columns.Contains("owner_name")
                    ? row["owner_name"].ToString()
                    : "Owner";

                // Determine tax type by payment_type column
                if (row.Table.Columns.Contains("payment_type"))
                {
                    string pType = row["payment_type"].ToString();
                    hfTaxType.Value = pType;
                    switch (pType)
                    {
                        case "1":
                            taxType = "Property";
                            break;
                        case "2":
                            taxType = "Water";
                            break;
                        case "3":
                            taxType = "Waste";
                            break;
                    }
                }

                lblModalTitle.Text = $"{ownerName}'s Pending {taxType} Tax";
            }

            rptModalItems.DataSource = dt;
            rptModalItems.DataBind();
        }


        protected void btnPayModal_Click(object sender, EventArgs e)
        {
            string selectedStr = Request.Form["selectedItems"];      // house_receipt_id of a selected bills, comma-separated
            if (string.IsNullOrEmpty(selectedStr))
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "noSelection",
                    "alert('Please select at least one item to pay.'); $('#taxModal').modal('show');", true);
                return;
            }
            payment.Sql_Operation = "Update_Payment";
            payment.Society_Id = Session["village_id"].ToString();
            payment.Receipt_No = selectedStr;
            payment.Mode = Convert.ToInt32(ddlPaymentMethod.SelectedValue);
            payment.Transaction_Ref = txtTransactionRef.Text;
            payment.Remarks = txtRemarks.Text;
            payment.Cheque_No = chequeNo.Text;
            if (!string.IsNullOrWhiteSpace(chequeDate.Text))
            {
                payment.Cheque_Date = DateTime.Parse(chequeDate.Text);
            }


            //var selected = selectedStr.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            bL_House.makePayment(payment);

            ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "SuccessEntry();", true);
        }
        private void ShowDiv(HtmlGenericControl div)
        {
            string css = div.Attributes["class"] ?? "";

            css = css.Replace("d-none", "").Replace("  ", " ").Trim();

            if (!css.Contains("d-flex"))
                css += " d-flex";

            div.Attributes["class"] = css.Trim();
        }

        private void HideDiv(HtmlGenericControl div)
        {
            string css = div.Attributes["class"] ?? "";

            css = css.Replace("d-flex", "").Replace("  ", " ").Trim();

            if (!css.Contains("d-none"))
                css += " d-none";

            div.Attributes["class"] = css.Trim();
        }



        protected void gvPaid_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "ViewReceipt")
            {
                int receipt_id = Convert.ToInt32(e.CommandArgument);
                var payment = bL_House.getReceiptData(receipt_id, "get_receipt_data");

                if (payment != null)
                {
                    lblReceiptNo.Text = payment.Receipt_No;
                    lblReceiptDate.Text = payment.Receipt_Date.ToString("MM-dd-yyyy");
                    lblReceiptOwner.Text = payment.Owner;
                    lblReceiptHouse.Text = payment.HouseNo.ToString();
                    lblReceiptMethod.Text = payment.Pay_Mode;
                    lblReceiptTxn.Text = payment.Transaction_Ref;
                    lblChequeNoTxn.Text = payment.Cheque_No;
                    lblChequeDateTxn.Text = payment.Cheque_Date.ToString();
                    lblReceiptAmount.Text = $"₹{payment.Amount:N2}";

                    // Default: hide everything
                    HideDiv(divTran);
                    HideDiv(divChequeNo);
                    HideDiv(divChequeDate);

                    if (payment.Pay_Mode == "Cheque")
                    {
                        ShowDiv(divChequeNo);
                        ShowDiv(divChequeDate);
                    }
                    else if (payment.Pay_Mode == "UPI")
                    {
                        ShowDiv(divTran);
                    }


                    switch (payment.PayType)
                    {
                        case 1:
                            lblTaxType.Text = "Property";
                            break;
                        case 2:
                            lblTaxType.Text = "Water";
                            break;
                        case 3:
                            lblTaxType.Text = "Waste";
                            break;
                        default:
                            lblTaxType.Text = "House";
                            break;
                    }

                    //lblReceiptItems.Text = payment.PaidItems;
                    BindData();
                    ScriptManager.RegisterStartupScript(this, GetType(), "showReceiptModal",
                        "$('#receiptModal').modal('show');", true);
                }
            }
        }

        protected void gvPaid_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["PaidState"];
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
                gvPaid.DataSource = dtrslt;
                gvPaid.DataBind();
            }
        }
    }

    
}