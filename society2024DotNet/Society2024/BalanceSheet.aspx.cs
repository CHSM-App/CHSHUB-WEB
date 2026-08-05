using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class BalanceSheet : System.Web.UI.Page
    {
        bl_v_resident bl_balSheet = new bl_v_resident();
        AmcBalanceSheet balanceEntry = new AmcBalanceSheet();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null) Response.Redirect("login1.aspx");

            if (!IsPostBack)
            {
                BindBalanceSheet();
            }
        }

        private void BindBalanceSheet()
        {
            DataTable dtHeaders = GetBalanceHeaders();

            var headers = dtHeaders.AsEnumerable()
                .Where(r => r["comp_id"] != DBNull.Value)
                .Select(r => new
                {
                    Row = r,
                    CompId = Convert.ToInt32(r["comp_id"]),
                    Seq = Convert.ToInt32(r["seq_order"])
                })
                .ToList();

            var liabilities = headers
                .Where(x => x.CompId == 2)
                .OrderBy(x => x.Seq)
                .Select(x => x.Row);

            var assets = headers
                .Where(x => x.CompId == 1)
                .OrderBy(x => x.Seq)
                .Select(x => x.Row);

            rptLiabilities.DataSource = liabilities.Any()
                ? liabilities.CopyToDataTable()
                : CreateEmptyHeaderTable();

            rptAssets.DataSource = assets.Any()
                ? assets.CopyToDataTable()
                : CreateEmptyHeaderTable();

            rptLiabilities.DataBind();
            rptAssets.DataBind();
        }

        private DataTable CreateEmptyHeaderTable()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("bal_head_id", typeof(int));
            dt.Columns.Add("bal_header_desc", typeof(string));
            dt.Columns.Add("comp_id", typeof(string));
            dt.Columns.Add("amount", typeof(decimal));
            dt.Columns.Add("total_amount", typeof(decimal));
            dt.Columns.Add("seq_order", typeof(int));
            return dt;
        }

        private DataTable GetBalanceHeaders()
        {
            // Hardcore sample data
            balanceEntry.SocietyID = Session["village_id"].ToString();
            balanceEntry.Operation = "get_main_points";
            DataTable dt = bl_balSheet.getPoints(balanceEntry);

            return dt;
        }

        private DataTable GetBalanceSubpoints()
        {
            // Hardcore sample data
            balanceEntry.SocietyID = Session["village_id"].ToString();
            balanceEntry.Operation = "get_sub_point";
            DataTable dt = bl_balSheet.getPoints(balanceEntry);

            return dt;
        }

        protected void btnAddNew_Click(object sender, EventArgs e)
        {
            hdHeaderId.Value = "0";
            txtHeaderTitle.Text = "";
            txtHeaderAmount.Text = "0";
            rbLiability.Checked = true;
            rbAsset.Checked = false;

            rptModalSubpoints.DataSource = null;
            rptModalSubpoints.DataBind();

            upnEdit.Update();

            ScriptManager.RegisterStartupScript(this, GetType(), "openModalAdd", @"
                $('#subpointsContainer').html('');
                var tpl = $('#subpointTemplate').html();
                $('#subpointsContainer').append(tpl);
                reIndexSubpoints();
                $('.type-option').removeClass('selected');
                $('.type-option[data-type=""liability""]').addClass('selected');
                $('#balanceModal').modal('show');", true);
        }

        protected void rptBalance_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "EditHeader")
            {
                int headerId = Convert.ToInt32(e.CommandArgument);
                LoadModal(headerId);
                upnEdit.Update();

                ScriptManager.RegisterStartupScript(this, GetType(), "showModal", @"
                    $('#balanceModal').modal('show');
                    setTimeout(function() {
                        var selectedType = $('#<%= hdEntryType.ClientID %>').val();
                        $('.type-option').removeClass('selected');
                        $('.type-option[data-type=""' + selectedType + '""]').addClass('selected');
                    }, 100);", true);
            }
        }

        private void LoadModal(int headerId)
         {
            DataTable headers = GetBalanceHeaders();
            var header = headers.AsEnumerable().FirstOrDefault(r => r.Field<int>("bal_head_id") == headerId);

            if (header != null)
            {
                hdHeaderId.Value = headerId.ToString();
                txtHeaderTitle.Text = header["bal_header_desc"].ToString();
                txtHeaderAmount.Text = header["amount"].ToString();

                string entryType = header["comp_id"].ToString();
                hdEntryType.Value = entryType;

                rbLiability.Checked = (entryType == "2");
                rbAsset.Checked = (entryType == "1");

                // Load subpoints
                DataTable subpoints = GetBalanceSubpoints();
                var headerSubpoints = subpoints.AsEnumerable()
                    .Where(r => r.Field<int>("bal_head_id") == headerId)
                    .Select(r => new
                    {
                        balance_subpoint_id = r["bal_sub_id"].ToString(),
                        subpoint_desc = r["bal_sub_desc"].ToString(),
                        amount = r["amount"].ToString()
                    })
                    .ToList();

                rptModalSubpoints.DataSource = headerSubpoints;
                rptModalSubpoints.DataBind();
            }
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            string json = hdSubpointsJson.Value;
            if (string.IsNullOrEmpty(json))
            {
                BindBalanceSheet();
                ScriptManager.RegisterStartupScript(this, GetType(), "closeModalEmpty", "$('#balanceModal').modal('hide');", true);
                return;
            }

            SubpointPayload payload = null;
            try
            {
                payload = JsonConvert.DeserializeObject<SubpointPayload>(json);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Invalid JSON payload: " + ex.Message);
                BindBalanceSheet();
                ScriptManager.RegisterStartupScript(this, GetType(), "closeModalErr", "$('#balanceModal').modal('hide');", true);
                return;
            }

            int headerId = int.Parse(hdHeaderId.Value ?? "0");

            // Insert or update header
            if (headerId == 0)
            {
                // Insert new header
                balanceEntry.MainPointText = payload.headerTitle;
                balanceEntry.EntryCategory = payload.entryType;  // 
                balanceEntry.Amount = string.IsNullOrEmpty(payload.headerAmount) ? 0 : decimal.Parse(payload.headerAmount);
                balanceEntry.Status = 1;
                balanceEntry.SocietyID = Session["village_id"].ToString();
                balanceEntry.Operation = "insert_header";

                //int newHeaderId = 1;
                int newHeaderId = bl_balSheet.InsertBalanceHeader(balanceEntry);
                if (newHeaderId > 0)
                    headerId = newHeaderId;
            }
            else
            {
                // Update existing header
                balanceEntry.BalanceHeaderID = headerId;
                balanceEntry.MainPointText = payload.headerTitle;
                balanceEntry.EntryCategory = payload.entryType;
                balanceEntry.Amount = string.IsNullOrEmpty(payload.headerAmount) ? 0 : decimal.Parse(payload.headerAmount);
                balanceEntry.Status = 1;
                balanceEntry.SocietyID = Session["village_id"].ToString();
                balanceEntry.Operation = "insert_header";

                bl_balSheet.InsertBalanceHeader(balanceEntry);
            }

            // Process subpoints
            var incoming = payload.subpoints ?? new List<SubpointDto>();

            foreach (var sp in incoming)
            {
                if (string.IsNullOrWhiteSpace(sp.subpoint_desc))
                    continue;

                balanceEntry.BalanceHeaderID = headerId;
                balanceEntry.SocietyID = Session["village_id"].ToString();
                balanceEntry.SubpointText = sp.subpoint_desc;
                balanceEntry.Amount = string.IsNullOrEmpty(sp.amount) ? 0 : decimal.Parse(sp.amount);
                balanceEntry.Operation = "Update";
                balanceEntry.Status = 1; 

                if (!string.IsNullOrEmpty(sp.balance_subpoint_id))
                {
                    balanceEntry.BalanceSubpointID = int.Parse(sp.balance_subpoint_id);
                }
                else
                {
                    balanceEntry.BalanceSubpointID = 0;
                }

                bl_balSheet.InsertBalanceSubpoint(balanceEntry);
            }

            BindBalanceSheet();
            ScriptManager.RegisterStartupScript(this, GetType(), "closeModal", "$('#balanceModal').modal('hide');", true);
        }

        protected void rptBalance_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem)
                return;

            var row = (DataRowView)e.Item.DataItem;

            int headerId = row.Row.Field<int>("bal_head_id");
            decimal headerAmount = row.Row.Field<decimal>("amount");

            Repeater rptSubpoints = (Repeater)e.Item.FindControl("rptSubpoints");

            // Get subpoints once per request if possible
            DataTable subpointsTable = GetBalanceSubpoints();

            // Proper filtering using DataTable
            var filteredRows = subpointsTable.AsEnumerable()
                .Where(r => r.Field<int>("bal_head_id") == headerId)
                .Select(r => new
                {
                    subpoint_desc = r.Field<string>("bal_sub_desc"),
                    amount = r.Field<decimal>("amount")
                })
                .ToList();

            rptSubpoints.DataSource = filteredRows;
            rptSubpoints.DataBind();

            // Correct total calculation
            decimal subpointsTotal = filteredRows.Sum(r => r.amount);
            decimal totalAmount = headerAmount + subpointsTotal;
             
            // If you need to display total, bind it to a Label
            Label lblTotal = (Label)e.Item.FindControl("lblTotal");
            if (lblTotal != null)
            {
                lblTotal.Text = totalAmount.ToString("N2");
            }
        }


        protected void btnSaveSequence_Click(object sender, EventArgs e)
        {
            string json = hfSequenceData.Value;

            if (!string.IsNullOrEmpty(json))
            {
                JavaScriptSerializer serializer = new JavaScriptSerializer();
                var items = serializer.Deserialize<List<ItemSequence>>(json);
                var result = "Done";

                foreach (var item in items)
                {
                    balanceEntry.BalanceHeaderID = item.Id;
                    balanceEntry.SequenceOrder = item.SequenceOrder;
                    balanceEntry.Operation = "Update_Seq_order";

                    result = bl_balSheet.UpdateBalanceSequence(balanceEntry);

                    if (result != "Done")
                    {
                        ScriptManager.RegisterStartupScript(this, GetType(), "alert", "alert('Failed to update sequence');", true);
                        return;
                    }  
                }  

                btnSaveSequence.Style["display"] = "none";
                BindBalanceSheet();
                ScriptManager.RegisterStartupScript(this, GetType(), "alert", "alert('Sequence updated successfully');", true);
            }
        }

        // DTOs for JSON payload
        public class SubpointDto
        {
            public string balance_subpoint_id { get; set; }
            public string subpoint_desc { get; set; }
            public string amount { get; set; }
        }

        public class SubpointPayload
        {
            public string headerTitle { get; set; }
            public string headerAmount { get; set; }
            public string entryType { get; set; }
            public List<SubpointDto> subpoints { get; set; }
        }

        public class ItemSequence
        {
            public int Id { get; set; }
            public string Type { get; set; }
            public int SequenceOrder { get; set; }
        }
    }
}