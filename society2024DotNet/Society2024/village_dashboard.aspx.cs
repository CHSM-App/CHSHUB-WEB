using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class village_dashboard : System.Web.UI.Page
    {
        public double WaterTaxPercentage { get; set; }
        public double HomeTaxPercentage { get; set; }
        public double WasteTaxPercentage { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                LoadDashboardData();
            }
        }

        private void LoadDashboardData()
        {
            // Set current date and time
            //lblCurrentDate.Text = DateTime.Now.ToString("dddd, MMMM dd, yyyy");
            //lblCurrentTime.Text = DateTime.Now.ToString("hh:mm:ss tt");

            // Load Water Tax Data (Monthly)
            int waterTaxPaid = 27300;
            int waterTaxTotal = 52000;
            lblWaterTaxPaid.Text = waterTaxPaid.ToString();
            lblWaterTaxTotal.Text = waterTaxTotal.ToString();
            WaterTaxPercentage = Math.Round((double)waterTaxPaid / waterTaxTotal * 100, 0);

            // Load Home Tax Data (Yearly)
            int homeTaxPaid = 356;
            int homeTaxTotal = 450;
            lblHomeTaxPaid.Text = homeTaxPaid.ToString();
            lblHomeTaxTotal.Text = homeTaxTotal.ToString();
            HomeTaxPercentage = Math.Round((double)homeTaxPaid / homeTaxTotal * 100, 0);

            // Load Waste Tax Data (Monthly)
            int wasteTaxPaid = 178;
            int wasteTaxTotal = 200;
            lblWasteTaxPaid.Text = wasteTaxPaid.ToString();
            lblWasteTaxTotal.Text = wasteTaxTotal.ToString();
            WasteTaxPercentage = Math.Round((double)wasteTaxPaid / wasteTaxTotal * 100, 0);

            // Load Population Data
            int malePopulation = 2845;
            int femalePopulation = 2623;
            int totalPopulation = malePopulation + femalePopulation;
            //lblTotalPopulation.Text = totalPopulation.ToString("N0");
            lblMalePopulation.Text = malePopulation.ToString("N0");
            lblFemalePopulation.Text = femalePopulation.ToString("N0");

            // Load Recent Activities
            LoadRecentActivities();
        }

        private void LoadRecentActivities()
        {
            List<Activity> activities = new List<Activity>
            {
                new Activity
                {
                    Title = "Water Tax Payment Received",
                    Description = "Ramesh Kumar (House No. 145) paid ₹500 for water tax",
                    Time = "2 hours ago",
                    Icon = "fa-tint",
                    IconClass = "payment",
                    Status = "Completed",
                    BadgeClass = "success"
                },
                new Activity
                {
                    Title = "Village Cleaning Drive",
                    Description = "New announcement: Community cleaning drive scheduled for 15th Dec",
                    Time = "3 hours ago",
                    Icon = "fa-bullhorn",
                    IconClass = "announcement",
                    Status = "Active",
                    BadgeClass = "warning"
                },
                new Activity
                {
                    Title = "Home Tax Payment Received",
                    Description = "Sita Devi (House No. 87) paid annual home tax of ₹1,200",
                    Time = "5 hours ago",
                    Icon = "fa-home",
                    IconClass = "payment",
                    Status = "Completed",
                    BadgeClass = "success"
                },
                new Activity
                {
                    Title = "PM Awas Yojana Enrollment",
                    Description = "25 new families successfully enrolled in housing scheme",
                    Time = "1 day ago",
                    Icon = "fa-clipboard-check",
                    IconClass = "scheme",
                    Status = "Processed",
                    BadgeClass = "info"
                },
                new Activity
                {
                    Title = "Waste Management Tax",
                    Description = "Mohan Lal paid ₹150 for monthly waste collection services",
                    Time = "1 day ago",
                    Icon = "fa-recycle",
                    IconClass = "payment",
                    Status = "Completed",
                    BadgeClass = "success"
                },
                new Activity
                {
                    Title = "Gram Sabha Meeting",
                    Description = "Meeting scheduled for 20th December at 10:00 AM in community hall",
                    Time = "2 days ago",
                    Icon = "fa-calendar-alt",
                    IconClass = "announcement",
                    Status = "Upcoming",
                    BadgeClass = "info"
                }
            };

            rptRecentActivities.DataSource = activities;
            rptRecentActivities.DataBind();
        }

        // Quick Action Button Click Events
        protected void btnAddAnnouncement_Click(object sender, EventArgs e)
        {
            Response.Redirect("v_announcement.aspx");
        }

        protected void btnGenerateTaxes_Click(object sender, EventArgs e)
        {
            Response.Redirect("v_tax_payment.aspx");
        }

        protected void btnAddScheme_Click(object sender, EventArgs e)
        {
            Response.Redirect("v_announcement.aspx");
        }

        protected void btnViewReports_Click(object sender, EventArgs e)
        {
            Response.Redirect("v_profite_loss.aspx");
        }
    }

    // Activity Model Class
    public class Activity
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string Time { get; set; }
        public string Icon { get; set; }
        public string IconClass { get; set; }
        public string Status { get; set; }
        public string BadgeClass { get; set; }
    }
}