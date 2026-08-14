using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class recent_activity : System.Web.UI.Page
    {

        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }

            if (!IsPostBack)
            {
                gridBind();
            }
        }


        protected void btn_search_Click(object sender, EventArgs e)
        {

            gridBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }

        protected void gridBind()
        {
            details.Sql_Operation = "RecentActivityAll";
            details.Society_Id = Session["society_id"].ToString();

            var dt = BL_Login.get_recent_chart(details);

            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void btnApplyFilters_Click(object sender, EventArgs e)
        {

            gridBind();


            string chipsHtml = "";

            if (!string.IsNullOrEmpty(dateFrom.Value) || !string.IsNullOrEmpty(dateTo.Value))
            {
                chipsHtml += $"<span class='filter-chip' id='chip-date'>📅 {dateFrom.Value} – {dateTo.Value} <button onclick=\"removeFilter('date')\">×</button></span>";
            }

            if (activityType.SelectedItem.Text != "All")
            {
                chipsHtml += $"<span class='filter-chip' id='chip-type'>🛠️ Type: {activityType.SelectedItem.Text} <button onclick=\"removeFilter('type')\">×</button></span>";
            }

            if (!string.IsNullOrEmpty(selectedMinPriceHidden.Value) || !string.IsNullOrEmpty(selectedMaxPriceHidden.Value))
            {
                chipsHtml += $"<span class='filter-chip' id='chip-price'>💰 ₹{selectedMinPriceHidden.Value} – ₹{selectedMaxPriceHidden.Value} <button onclick=\"removeFilter('price')\">×</button></span>";
            }

            // Assign HTML to filterChips div
            filterChips.InnerHtml = chipsHtml;

            // Close the filter sidebar after applying filters
            ScriptManager.RegisterStartupScript(this, GetType(), "hideSidebar", "document.getElementById('filterSidebar').classList.remove('show');", true);

        }

    }
}