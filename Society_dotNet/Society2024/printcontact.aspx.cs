using BusinessLogic.BL;
using Microsoft.Reporting.WebForms;
using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class printcontact : System.Web.UI.Page
    {
        usefull_Contact Usefull = new usefull_Contact();
        BL_PrintContact bL_printContact = new BL_PrintContact();
        BL_FillRepeater repeater = new BL_FillRepeater();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
            {
                society_id.Value = Session["society_id"].ToString();
                if (!IsPostBack)
                {
                    filldrop();
                }
            }
        }

        public void filldrop()
        {
            string sql_query = "SELECT * FROM person_type";
            repeater.fill_list(Repeater1, sql_query);
        }

        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                person_id.Value = e.CommandArgument.ToString();

                string query = $"SELECT * FROM usefull_contact_vw WHERE active_status = 0 AND society_id ='{society_id.Value}' AND usefull_contact_id = {e.CommandArgument}";
                Usefull.Sql_Operation = query;
                ViewState["LastQuery"] = query;

                var dt = bL_printContact.button_click(Usefull);

                if (dt.Rows.Count > 0)
                {
                    LoadReport(dt);
                }
                else
                {
                    ReportViewer1.Visible = false;
                }
            }
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            ddl_per_type_SelectedIndexChanged(sender, e); // Trigger report load
        }

        protected void ddl_per_type_SelectedIndexChanged(object sender, EventArgs e)
        {
            string query = $"SELECT * FROM usefull_contact_vw WHERE active_status=0 AND society_id='{Session["society_id"]}'";

            if (!string.IsNullOrWhiteSpace(TextBox1.Text) && TextBox1.Text != "select")
            {
                query += $" AND p_type_name LIKE '{TextBox1.Text}%'";
            }

            Usefull.Sql_Operation = query;
            ViewState["LastQuery"] = query; // Save last query for download
            var dt = bL_printContact.button_click(Usefull);

            if (dt.Rows.Count > 0)
            {
                LoadReport(dt);
            }
            else
            {
                ReportViewer1.Visible = false;
            }
        }

        private void LoadReport(DataTable dt)
        {
            ReportViewer1.Visible = true;
            ReportViewer1.LocalReport.ReportPath = Server.MapPath("~/usefull_contact.rdlc");
            ReportViewer1.LocalReport.DataSources.Clear();

            ReportDataSource rds = new ReportDataSource("usefull_contact", dt);
            ReportViewer1.LocalReport.DataSources.Add(rds);
            ReportViewer1.LocalReport.Refresh();
        }

        protected void btnDownloadPdf_Click(object sender, EventArgs e)
        {
            if (ViewState["LastQuery"] == null)
            {
                // No report loaded yet
                return;
            }

            string lastQuery = ViewState["LastQuery"].ToString();
            Usefull.Sql_Operation = lastQuery;
            var dt = bL_printContact.button_click(Usefull);

            LocalReport report = new LocalReport
            {
                ReportPath = Server.MapPath("~/usefull_contact.rdlc")
            };
            report.DataSources.Add(new ReportDataSource("usefull_contact", dt));

            string mimeType, encoding, fileNameExtension;
            string[] streams;
            Warning[] warnings;

            byte[] renderedBytes = report.Render("PDF", null, out mimeType, out encoding, out fileNameExtension, out streams, out warnings);

            Response.Clear();
            Response.ContentType = "application/pdf";
            Response.AddHeader("Content-Disposition", "attachment; filename=HelperContacts.pdf");
            Response.BinaryWrite(renderedBytes);
            Response.End();
        }
    }
}
