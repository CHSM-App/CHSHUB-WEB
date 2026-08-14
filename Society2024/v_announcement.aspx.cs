using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class v_announcement : System.Web.UI.Page
    {
        private static List<Announcement> announcementsList = new List<Announcement>();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                BindGridViews();
            }
        }

        private void BindGridViews()
        {
            // Bind each GridView to its respective data source
            gvGeneral.DataSource = GetGeneralAnnouncements();
            gvGeneral.DataBind();

            gvMeeting.DataSource = GetMeetingUpdates();
            gvMeeting.DataBind();

            gvWorkBudget.DataSource = GetWorkBudgetInfo();
            gvWorkBudget.DataBind();
        }

        // Method to get General Announcements dummy data
        private DataTable GetGeneralAnnouncements()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("AnnouncementId", typeof(int));
            dt.Columns.Add("Title", typeof(string));
            dt.Columns.Add("Description", typeof(string));
            dt.Columns.Add("Date", typeof(DateTime));
            dt.Columns.Add("Category", typeof(string));

            dt.Rows.Add(1, "Office Closure Notice", "Office will be closed on December 25th for Christmas holiday.", new DateTime(2024, 12, 20), "General");
            dt.Rows.Add(2, "New Parking Policy", "New parking assignments effective from January 1st, 2025.", new DateTime(2024, 12, 15), "General");
            dt.Rows.Add(3, "Holiday Party Announcement", "Annual holiday party scheduled for December 22nd at 6 PM.", new DateTime(2024, 12, 10), "General");
            dt.Rows.Add(4, "System Maintenance", "IT systems will undergo maintenance on December 30th from 10 PM to 2 AM.", new DateTime(2024, 12, 18), "General");

            return dt;
        }

        // Method to get Meeting Updates dummy data
        private DataTable GetMeetingUpdates()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("AnnouncementId", typeof(int));
            dt.Columns.Add("Title", typeof(string));
            dt.Columns.Add("Description", typeof(string));
            dt.Columns.Add("Date", typeof(DateTime));
            dt.Columns.Add("Category", typeof(string));

            dt.Rows.Add(5, "Q4 Review Meeting", "Quarterly review meeting scheduled for December 28th at 10 AM in Conference Room A.", new DateTime(2024, 12, 22), "Meeting");
            dt.Rows.Add(6, "Team Building Session", "Monthly team building session on January 5th at 2 PM.", new DateTime(2024, 12, 28), "Meeting");
            dt.Rows.Add(7, "Project Kickoff Meeting", "New project kickoff meeting on January 8th at 9 AM.", new DateTime(2025, 1, 2), "Meeting");
            dt.Rows.Add(8, "Department Town Hall", "Department-wide town hall meeting on January 15th at 3 PM via Zoom.", new DateTime(2025, 1, 8), "Meeting");

            return dt;
        }

        // Method to get Work & Budget Information dummy data
        private DataTable GetWorkBudgetInfo()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("AnnouncementId", typeof(int));
            dt.Columns.Add("Title", typeof(string));
            dt.Columns.Add("Description", typeof(string));
            dt.Columns.Add("Date", typeof(DateTime));
            dt.Columns.Add("Category", typeof(string));

            dt.Rows.Add(9, "FY2025 Budget Approval", "Annual budget for fiscal year 2025 has been approved. Details will be shared via email.", new DateTime(2024, 12, 5), "WorkBudget");
            dt.Rows.Add(10, "Project Alpha Budget Update", "Additional funds allocated to Project Alpha. Budget increased by 15%.", new DateTime(2024, 12, 12), "WorkBudget");
            dt.Rows.Add(11, "Expense Report Deadline", "All expense reports for December must be submitted by January 5th.", new DateTime(2024, 12, 20), "WorkBudget");
            dt.Rows.Add(12, "Work From Home Policy Update", "Updated WFH policy allows 3 days per week starting January 2025.", new DateTime(2024, 12, 8), "WorkBudget");

            return dt;
        }

        // Event handler for View button in GridView rows
        protected void btnView_Click(object sender, EventArgs e)
        {
            try
            {
                Button btn = (Button)sender;
                int announcementId = Convert.ToInt32(btn.CommandArgument);

                // Find the announcement (check all data sources)
                DataTable allData = CombineAllAnnouncements();
                DataRow[] rows = allData.Select($"AnnouncementId = {announcementId}");

                if (rows.Length > 0)
                {
                    DataRow row = rows[0];
                    string details = $"ID: {row["AnnouncementId"]}\\n" +
                                   $"Title: {row["Title"]}\\n" +
                                   $"Description: {row["Description"]}\\n" +
                                   $"Date: {Convert.ToDateTime(row["Date"]):MM/dd/yyyy}\\n" +
                                   $"Category: {row["Category"]}";

                    // Log to console
                    Debug.WriteLine("=== Viewing Announcement ===");
                    Debug.WriteLine(details);
                    Debug.WriteLine("============================");

                    // Show details in alert
                    ScriptManager.RegisterStartupScript(this, GetType(), "viewDetails",
                        $"alert('{details}');", true);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Error viewing announcement: {ex.Message}");
                ScriptManager.RegisterStartupScript(this, GetType(), "error",
                    $"alert('Error: {ex.Message}');", true);
            }
        }

        // Helper method to combine all announcements for searching
        private DataTable CombineAllAnnouncements()
        {
            DataTable combined = new DataTable();
            combined.Columns.Add("AnnouncementId", typeof(int));
            combined.Columns.Add("Title", typeof(string));
            combined.Columns.Add("Description", typeof(string));
            combined.Columns.Add("Date", typeof(DateTime));
            combined.Columns.Add("Category", typeof(string));

            // Merge all data tables
            DataTable general = GetGeneralAnnouncements();
            DataTable meeting = GetMeetingUpdates();
            DataTable workBudget = GetWorkBudgetInfo();

            combined.Merge(general);
            combined.Merge(meeting);
            combined.Merge(workBudget);

            return combined;
        }

        // Event handler for Save button in modal
        protected void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                // Get values from form controls
                string category = ddlCategory.SelectedValue;
                string title = txtTitle.Text.Trim();
                string description = txtDescription.Text.Trim();
                DateTime date = DateTime.Parse(txtDate.Text);

                // Create new announcement object
                Announcement newAnnouncement = new Announcement
                {
                    AnnouncementId = announcementsList.Count + 100, // Simple ID generation
                    Category = category,
                    Title = title,
                    Description = description,
                    Date = date
                };

                // Add to in-memory list
                announcementsList.Add(newAnnouncement);

                // Log to console/debug output
                Debug.WriteLine("=== New Announcement Submitted ===");
                Debug.WriteLine($"ID: {newAnnouncement.AnnouncementId}");
                Debug.WriteLine($"Category: {newAnnouncement.Category}");
                Debug.WriteLine($"Title: {newAnnouncement.Title}");
                Debug.WriteLine($"Description: {newAnnouncement.Description}");
                Debug.WriteLine($"Date: {newAnnouncement.Date:MM/dd/yyyy}");
                Debug.WriteLine("==================================");

                // Clear form fields
                ddlCategory.SelectedIndex = 0;
                txtTitle.Text = string.Empty;
                txtDescription.Text = string.Empty;
                txtDate.Text = string.Empty;

                // Rebind grids to show updated data
                BindGridViews();

                // Optional: Show success message (you can use a Label or ClientScript)
                ScriptManager.RegisterStartupScript(this, GetType(), "success",
                    "alert('Announcement saved successfully!'); $('#addAnnouncementModal').modal('hide');", true);
            }
            catch (Exception ex)
            {
                // Log error
                Debug.WriteLine($"Error saving announcement: {ex.Message}");

                // Show error message
                ScriptManager.RegisterStartupScript(this, GetType(), "error",
                    $"alert('Error saving announcement: {ex.Message}');", true);
            }
        }

        // Helper class to represent an Announcement
        public class Announcement
        {
            public int AnnouncementId { get; set; }
            public string Category { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public DateTime Date { get; set; }
        }
    }
}