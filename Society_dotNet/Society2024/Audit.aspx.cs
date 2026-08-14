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
    public partial class Audit : System.Web.UI.Page
    {
        // your existing BL objects
        BL_Amc_Master bl_agm = new BL_Amc_Master();
        Amc audit = new Amc();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null) Response.Redirect("login1.aspx");

            if (!IsPostBack)
            {
                BindMainHeaders();
            }
        }

        private DataTable BindMainHeaders()
        {
            DataTable headers = GetHeaders();
            rptMain.DataSource = headers;
            rptMain.DataBind();

            // Also bind rptHeaders for the PDF modal (optional)
            rptHeaders.DataSource = headers;
            rptHeaders.DataBind();

            return headers;
        }

        private DataTable GetHeaders()
        {
            return bl_agm.getHeaders(Session["society_id"].ToString(), "get_main_points");
        }

        private DataTable GetQuestions()
        {
            return bl_agm.getQestions(Session["society_id"].ToString(), "get_questions");
        }

        // Add new button clicked -> open modal in "Add" mode
        protected void btnAddNew_Click(object sender, EventArgs e)
        {
            hdHeaderId.Value = "0";
            txtHeaderTitle.Text = "";
            rptModalSubpoints.DataSource = null;
            rptModalSubpoints.DataBind();

            // Ensure server-side update panel refresh
            upnEdit.Update();

            // Add one empty subpoint row client-side after opening modal
            ScriptManager.RegisterStartupScript(this, GetType(), "openModalAdd", @"
                $('#subpointsContainer').html('');
                var tpl = $('#subpointTemplate').html();
                $('#subpointsContainer').append(tpl);
                reIndexSubpoints();
                $('#auditModal').modal('show');", true);
        }

        // Parent repeater edit click
        protected void rptMain_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "EditHeader")
            {
                int headerId = Convert.ToInt32(e.CommandArgument);
                LoadModal(headerId);
                // ensure upnEdit updated so server-rendered subpoints are visible
                upnEdit.Update();
                ScriptManager.RegisterStartupScript(this, GetType(), "showModal", "$('#auditModal').modal('show');", true);
            }
        }

        // Load single header + its subpoints into modal server-side
        private void LoadModal(int headerId)
        {
            DataTable headers = GetHeaders();
            var header = headers.AsEnumerable().FirstOrDefault(r => r.Field<int>("audt_header_id") == headerId);

            hdHeaderId.Value = headerId.ToString();
            txtHeaderTitle.Text = header != null ? header["audt_header_desc"].ToString() : "";

            // subpoints for header
            DataTable questions = GetQuestions();
            var subpoints = questions.AsEnumerable()
                .Where(r => r.Field<int>("audt_header_id") == headerId)
                .Select(r => new
                {
                    audt_ques_id = r["audt_ques_id"].ToString(),
                    question_desc = r["question_desc"].ToString(),
                    answer_desc = r["answer_desc"].ToString()
                })
                .ToList();

            rptModalSubpoints.DataSource = subpoints;
            rptModalSubpoints.DataBind();
        }

        // Save button in modal
        protected void btnSaveAudit_Click(object sender, EventArgs e)
        {
            string json = hdSubpointsJson.Value;
            if (string.IsNullOrEmpty(json))
            {
                // Nothing to save, rebind to refresh UI
                BindMainHeaders();
                ScriptManager.RegisterStartupScript(this, GetType(), "closeModalEmpty", "$('#auditModal').modal('hide');", true);
                return;
            }

            SubpointPayload payload = null;
            try
            {
                payload = JsonConvert.DeserializeObject<SubpointPayload>(json);
            }
            catch (Exception ex)
            {
                // log and return
                System.Diagnostics.Debug.WriteLine("Invalid JSON payload: " + ex.Message);
                BindMainHeaders();
                ScriptManager.RegisterStartupScript(this, GetType(), "closeModalErr", "$('#auditModal').modal('hide');", true);
                return;
            }

            int headerId = int.Parse(hdHeaderId.Value ?? "0");

            // Insert or update header
            if (headerId == 0)
            {
                audit.MainPoint = payload.headerTitle;
                audit.Status = 1;
                audit.SocietyId = Session["society_id"].ToString();
                audit.Sql_Operation = "insert_header";

                int newHeaderId = bl_agm.InsertAuditMainPoint(audit);
                if (newHeaderId > 0)
                    headerId = newHeaderId;
            }
            else
            {
                audit.M_Point_Id = headerId;
                audit.MainPoint = payload.headerTitle;
                audit.Status = 1;
                audit.SocietyId = Session["society_id"].ToString();
                audit.Sql_Operation = "update_header";

                bl_agm.InsertAuditMainPoint(audit); // assuming this updates when Sql_Operation set to update_header
            }

            // incoming subpoints
            var incoming = payload.subpoints ?? new List<SubpointDto>();

            foreach (var sp in incoming)
            {
                // ignore blank rows
                if (string.IsNullOrWhiteSpace(sp.question_desc) && string.IsNullOrWhiteSpace(sp.answer_desc))
                    continue;

                audit.M_Point_Id = headerId;
                audit.AuditQue = sp.question_desc;
                audit.AuditAns = sp.answer_desc;
                audit.Sql_Operation = "update";

                if (!string.IsNullOrEmpty(sp.audt_ques_id))
                {
                    audit.Audt_Ques_Id = int.Parse(sp.audt_ques_id);
                }
                else
                {
                    audit.Audt_Ques_Id = 0;
                }

                bl_agm.InsertAuditSubPoint(audit);
            }

            // Optionally: delete removed questions here by comparing DB list vs incoming keepIds
            // (Left as placeholder: implement BL delete method if required.)

            BindMainHeaders();
            ScriptManager.RegisterStartupScript(this, GetType(), "closeModal", "$('#auditModal').modal('hide');", true);
        }

        // Delete header clicked in modal (if you decide to enable)
        protected void btnDeleteHeader_Click(object sender, EventArgs e)
        {
            int headerId = int.Parse(hdHeaderId.Value ?? "0");
            if (headerId > 0)
            {
                // Implement deletion in BL if desired, e.g. bl_agm.DeleteAuditMainPoint(headerId);
            }

            BindMainHeaders();
            ScriptManager.RegisterStartupScript(this, GetType(), "closeModalDel", "$('#auditModal').modal('hide');", true);
        }

        protected void rptMain_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            DataRowView row = (DataRowView)e.Item.DataItem;
            int headerId = Convert.ToInt32(row["audt_header_id"]);

            Repeater rptSub = (Repeater)e.Item.FindControl("rptSub");
            DataTable questions = GetQuestions();

            var subRows = questions.AsEnumerable()
                .Where(r => r.Field<int>("audt_header_id") == headerId)
                .Select(r => new
                {
                    question_desc = r["question_desc"].ToString(),
                    answer_desc = r["answer_desc"].ToString()
                }).ToList();

            rptSub.DataSource = subRows;
            rptSub.DataBind();
        }

        private void LoadAuditForm()
        {
            LoadSocietyInfo();
            LoadAuditPeriod();
            BindHeadersAndQuestions();
        }

        private void LoadSocietyInfo()
        {
            //societyName.InnerText = "श्री. सिद्धीविनायक गृहनिर्माण सहकारी";
            //societyAddress.InnerText = "गृहनिर्माण संस्था मर्यादित, वेंगुर्ला ";
            //societyPhone.InnerText = "मु.पो.ता:- वेंगुर्ली जिल्हा:- सिंधुदुर्ग";

            //societyFullName.InnerText = "श्री. सिद्धीविनायक गृहनिर्माण सहकारी संस्था मर्यादित";
            //societyFullAddress.InnerText = "वेंगुर्ला, जिल्हा सिंधुदुर्ग";
            //societyContactPhone.InnerText = "0234-XXXXXXX";
            //societyDistrict.InnerText = "सिंधुदुर्ग";

            var dt = bl_agm.fetchSocietyData("get_Society_Info", Session["society_id"].ToString());
            // Assuming dt is your DataTable and it has at least 1 row
            if (dt != null && dt.Rows.Count > 0)
            {
                DataRow row = dt.Rows[0];

                // Society Name
                societyName.InnerText = row["name"]?.ToString().Trim();
                societyFullName.InnerText = row["name"]?.ToString().Trim();
                // Contact Number
                societyContactPhone.InnerText = row["contact_no1"]?.ToString().Trim();

                

                // Address parts
                string address1 = row["off_address1"]?.ToString().Trim();
                string address2 = row["off_address2"]?.ToString().Trim();
                string city = row["city"]?.ToString().Trim();
                string pincode = row["pincode"]?.ToString().Trim();

                // Location parts to concatenate            
                string division = row["division"]?.ToString().Trim();
                string district = row["district"]?.ToString().Trim();
                string state = row["state"]?.ToString().Trim();
                societyDistrict.InnerText = district;
                // Concatenate full address
                societyAddress.InnerText = string.Join(", ",
                    new[] { address1, address2, city, division, district, state, pincode }
                    .Where(x => !string.IsNullOrEmpty(x))
                );

                societyFullAddress.InnerText = string.Join(", ",
                    new[] { address1, address2, city, division, district, state, pincode }
                    .Where(x => !string.IsNullOrEmpty(x)));
            }

        }



        private void LoadAuditPeriod()
        {
            auditPeriod.InnerText = "दि.०१-०४-२०२४ ते दि. ३१-०३-२०२५ अखेरचे";
            auditDate.InnerText = DateTime.Now.ToString("dd/MM/yyyy");
        }

        private void BindHeadersAndQuestions()
        {
            try
            {
                DataTable dtHeaders = GetHeaders();
                if (dtHeaders != null && dtHeaders.Rows.Count > 0)
                {
                    rptHeaders.DataSource = dtHeaders;
                    rptHeaders.DataBind();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error binding headers: " + ex.Message);
            }
        }

        protected void rptHeaders_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                Repeater rptQuestions = (Repeater)e.Item.FindControl("rptQuestions");
                DataRowView drv = (DataRowView)e.Item.DataItem;
                int auditHeaderId = Convert.ToInt32(drv["audt_header_id"]);

                DataTable questions = GetQuestions();

                var subRows = questions.AsEnumerable()
                    .Where(r => r.Field<int>("audt_header_id") == auditHeaderId)
                    .Select(r => new
                    {
                        question_desc = r["question_desc"].ToString(),
                        answer_desc = r["answer_desc"].ToString()
                    }).ToList();

                if (subRows.Count == 0)
                {
                    e.Item.Visible = false;
                    return;
                }

                rptQuestions.DataSource = subRows;
                rptQuestions.DataBind();
            }
        }

        protected void delete_SubPoint(object sender, EventArgs e)
        {
            // Not used - deletions are performed client-side and then sent to server on Save.
            // If you want server-side immediate delete, implement BL delete call here and rebind.
        }

        protected void rptModalSubpoints_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // placeholder - currently we handle deletions client-side
        }

        protected void btnSaveSequence_Click(object sender, EventArgs e)
        {
            string json = hfSequenceData.Value;

            if (!string.IsNullOrEmpty(json))
            {
                JavaScriptSerializer serializer = new JavaScriptSerializer();
                var items = serializer.Deserialize<List<ItemSequence>>(json);
                var result = "";
                foreach (var item in items)
                {
                    audit.Amc_Id = item.Id;
                    audit.Sequence = item.SequenceOrder;
                    audit.Sql_Operation = "Update_Sequence";
                    result = bl_agm.updateSeq(audit);
                    if (result != "Done")
                    {
                        ScriptManager.RegisterStartupScript(this, GetType(), "alert", "FailedEntry();", true);
                        return;
                    }
                }

                btnSaveSequence.Style["display"] = "none";
                BindMainHeaders();
                ScriptManager.RegisterStartupScript(this, GetType(), "alert", "SuccessEntry();", true);
            }
        }

        public class ItemSequence
        {
            public int Id { get; set; }
            public int SequenceOrder { get; set; }
        }

        // DTOs for JSON payload
        public class SubpointDto
        {
            public string audt_ques_id { get; set; }
            public string question_desc { get; set; }
            public string answer_desc { get; set; }
        }

        public class SubpointPayload
        {
            public string headerTitle { get; set; }
            public List<SubpointDto> subpoints { get; set; }
        }

        protected void viewAudit(object sender, EventArgs e)
        {
            LoadAuditForm();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#auditFormModal').modal('show');", true);
        }
    }
}
