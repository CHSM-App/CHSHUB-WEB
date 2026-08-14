using BusinessLogic;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using DocumentFormat.OpenXml.Drawing;
using DocumentFormat.OpenXml.Office2016.Drawing.ChartDrawing;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;
using Table = System.Web.UI.WebControls.Table;
using TableCell = System.Web.UI.WebControls.TableCell;

namespace Society
{
    public partial class Defaulter : System.Web.UI.Page
    {
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();
        private readonly IEmailService _emailService = new SendGridEmailService();

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
                due_fill(sender, e);
                btn_search_Click(sender, e);
            }
        }

        protected void gvOwners_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                // Get flat_id for this row
                int flatId = Convert.ToInt32(DataBinder.Eval(e.Row.DataItem, "flat_id"));
                e.Row.Attributes["data-flatid"] = flatId.ToString();

                // Find the LinkButton in the row and set its CommandArgument
                LinkButton btnViewDetails = (LinkButton)e.Row.FindControl("btnViewDetails");
                if (btnViewDetails != null)
                {
                    btnViewDetails.CommandArgument = flatId.ToString();
                }
            }
        }

        protected void btnViewDetails_Click(object sender, EventArgs e)
        {
            LinkButton btn = (LinkButton)sender;
            int flatId = Convert.ToInt32(btn.CommandArgument);

            DataTable dt = GetPaymentDetails(flatId);

            if (dt != null && dt.Rows.Count > 0)
            {
                DataRow firstRow = dt.Rows[0];

                lblOwnerName.Text = firstRow["name"].ToString();
                lblFlatId.Text = "Flat ID: " + firstRow["flat_id"].ToString();

                // SUM of amt_forward
                decimal totalForward = Convert.ToDecimal(
                    dt.Compute("SUM(amt_forward)", string.Empty)
                );
                decimal totalTax = Convert.ToDecimal(
                    dt.Compute("SUM(tax_interest_amt)", string.Empty)
                );

                var totalToPay = totalForward + totalTax;

                lblTotalForward.Text = "Total Amount Forward: " + totalToPay.ToString("N2");
            }
            else
            {
                lblOwnerName.Text = "—";
                lblFlatId.Text = "";
                lblTotalForward.Text = "Total Amount Forward: ₹0.00";
            }

            gvPaymentDetails.DataSource = dt;
            gvPaymentDetails.DataBind();

            detailedPay.Update();

            ScriptManager.RegisterStartupScript(
                this,
                this.GetType(),
                "ShowModal",
                "$('#paymentDetailsModal').modal('show');",
                true
            );
        }


        private DataTable GetPaymentDetails(int flatId)
        {
            details.Id = flatId;
            details.Sql_Operation = "ownerDue";
            details.society_id = Session["society_id"].ToString();

            DataTable dt = BL_Login.getOwnerDues(details);
            return dt;
        }

        protected async void btn_send_email_Click(object sender, EventArgs e)
        {
            List<(string Email, string Name)> recipients = new List<(string Email, string Name)>();

            foreach (GridViewRow row in gvOwners.Rows)
            {
                CheckBox chkBx = (CheckBox)row.FindControl("CheckBox1");
                if (chkBx != null && chkBx.Checked)
                {
                    Label emailLabel = (Label)row.FindControl("email");
                    Label nameLabel = (Label)row.FindControl("owner_name");

                    if (emailLabel != null && nameLabel != null)
                    {
                        recipients.Add((emailLabel.Text.Trim(), nameLabel.Text.Trim()));
                    }
                }
            }

            try
            {
                string subject = Session["society_name"] + " Maintenance Due reminder!";
                string htmlBody = messageContent.Text;
                string plainBody = System.Text.RegularExpressions.Regex
                    .Replace(htmlBody, "<.*?>", string.Empty);

                await _emailService.SendEmailAsync(
                    recipients, subject, plainBody, htmlBody);
            }
            catch (Exception ex)
            {
                // Log ex via your logging framework
            }
        }

        protected void btn_send_sms_Click(object sender, EventArgs e)
        {
            List<String> list = new List<string>();
            foreach (GridViewRow row in gvOwners.Rows)
            {
                CheckBox chkBx = (CheckBox)row.FindControl("CheckBox1");
                if (chkBx.Checked == true)
                {
                    Label contact_no = (Label)row.FindControl("mobile_no");
                    list.Add(contact_no.Text);
                }
            }
            messageContent.Text = string.Join(",", list);
        }

        protected void select_all_CheckedChanged(object sender, EventArgs e)
        {
            CheckBox select_all = sender as CheckBox;
            foreach (GridViewRow row in gvOwners.Rows)
            {
                CheckBox chkBx = (CheckBox)row.FindControl("CheckBox1");
                if (select_all.Checked == true)
                    chkBx.Checked = true;
                else
                    chkBx.Checked = false;
            }

            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "updateRecipientCount();", true);
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            details.Name = txt_search.Text.Trim();
            details.Sql_Operation = "defaulter_show";
            details.society_id = Session["society_id"].ToString();
            var result = BL_Login.search_defaulter(details);

            if (result != null && result.Rows.Count > 0)
            {
                ViewState["dirState"] = result;
                ViewState["sortdr"] = "Asc";
                result.Compute("Sum(due)", string.Empty).ToString();
            }

            gvOwners.DataSource = result;
            gvOwners.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void due_fill(object sender, EventArgs e)
        {
            lbl_due.Text = "0";
            details.Name = "";
            details.Sql_Operation = "defaulter_show";
            details.society_id = Session["society_id"].ToString();
            var result = BL_Login.search_defaulter(details);

            if (result != null && result.Rows.Count > 0)
            {
                lbl_due.Text = result.Compute("Sum(due)", string.Empty).ToString();
            }
        }

        protected void GridView8_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["dirState"];
            if (dtrslt != null && dtrslt.Rows.Count > 0)
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
                gvOwners.DataSource = dtrslt;
                gvOwners.DataBind();
            }
        }

        protected void GridView8_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvOwners.PageIndex = e.NewPageIndex;
            btn_search_Click(sender, e);
        }
    }
}