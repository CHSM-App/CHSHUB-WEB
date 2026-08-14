using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DocumentFormat.OpenXml.Bibliography;
using DocumentFormat.OpenXml.Office2010.ExcelAc;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;
using static System.Windows.Forms.AxHost;

namespace Society2024
{
    public partial class Admin_Dashboard : System.Web.UI.Page
    {
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();

        BL_FillRepeater repeater = new BL_FillRepeater();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                gridBind();

                string str = "select * from state"; 
                repeater.fill_list(Repeater1, str);
            }
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                state.Value = e.CommandArgument.ToString();

                if (!(state.Value == ""))
                {
                    string sql1 = "Select *  from district where state_id = " + state.Value; 
                    repeater.fill_list(Repeater2, sql1);
                }
            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                dist.Value = e.CommandArgument.ToString();
                string sql1 = "Select distinct city from society_master where city is not null and district_id = " + dist.Value;
                repeater.fill_list(Repeater3, sql1);
            }

        }
        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                city.Value = e.CommandArgument.ToString();

            }

        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            gridBind();

            //System.Text.StringBuilder sb = new System.Text.StringBuilder();
            // sb.Append("SELECT * FROM admin_vw WHERE (society_id = '" + society_id.Value + "')");

            //if (drp_society.SelectedValue != "select")
            //{
            //    sb.Append(" AND name = '" + drp_society.SelectedItem.Text.Replace("'", "''") + "'");
            //}

            //if (!string.IsNullOrEmpty(txt_search.Text))
            //{
            //    sb.Append(" AND (address LIKE '" + txt_search.Text.Replace("'", "''") + "%'");
            //    sb.Append(" OR pincode LIKE '" + txt_search.Text.Replace("'", "''") + "%'");

            //    // ✅ Fix: Use '=' for numeric comparison instead of 'LIKE'
            //    if (int.TryParse(txt_search.Text, out int pendingAmount))
            //    {
            //        sb.Append(" OR pending_amount = " + pendingAmount);
            //    }

            //    sb.Append(")"); // Closing parenthesis for grouped OR conditions

            //}

            //details.Sql_Operation = sb.ToString();
            //var result = BL_Login.search_admin(details);
            //GridView1.DataSource = result;
            //ViewState["dirState"] = result;
            //GridView1.DataBind();

        }
        protected void gridBind()
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            int count = 1;
            sb.Append("Select *  from admin_vw where society_id='" + Session["Society_id"].ToString() + "'");


            if (txt_search.Text != "")
            {
                if (count > 0)
                {
                    sb.Append(" or ");
                }

                sb.Append(" name like '" + txt_search.Text + "%' or address like '" + txt_search.Text +
                    "%' or email like '" + txt_search.Text + "%' or contact_no1 like '" + txt_search.Text + "%' or cast (total_unit as varchar) like '" + txt_search.Text + "%' or cast (amount as varchar) like '" + txt_search.Text + "%'");
                count++;
            }
            if (TextBox1.Text != "")
            {
                if (count > 0)
                {
                    sb.Append(" AND ");
                }
                sb.Append(" state_id = '" + state.Value + "'");
                count++;
            }
            if (TextBox2.Text != "")
            {
                if (count > 0)
                {
                    sb.Append(" AND ");
                }
                sb.Append(" district_id = '" + dist.Value + "'");
                count++;
            }
            if (TextBox3.Text != "")
            {
                if (count > 0)
                {
                    sb.Append(" AND ");
                }
                sb.Append(" city = '" + society_id.Value + "'");
                count++;
            }



            if (dateFrom.Value != "" && dateTo.Value != "")
            {
                if (count > 0)
                {
                    sb.Append(" AND ");
                }
                sb.Append(" date between cast(  '" + dateFrom.Value + "' as date) and cast('" + dateTo.Value + "' as date)");
                count++;
            }
            if (selectedMinPriceHidden.Value != "" && selectedMaxPriceHidden.Value != "")
            {
                if (count > 0)
                {
                    sb.Append(" AND ");
                }
                sb.Append(" amount between cast( '" + selectedMinPriceHidden.Value + "' as decimal) and cast ('" + selectedMaxPriceHidden.Value + "' as decimal)");
                count++;
            }
            //sb.Append(" order by date desc");
            details.Sql_Operation = "Adminsearch";
            details.Name = sb.ToString();


            var result = BL_Login.get_recent_Search(details);
            if (result.Rows.Count > 0)
            {
                maxPriceHidden.Value = result.AsEnumerable().Max(row => row.Field<decimal>("amount")).ToString();
                minPriceHidden.Value = (0).ToString();

            }

            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
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
                GridView1.DataSource = dtrslt;
                GridView1.DataBind();
            }
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }


        protected void btnApplyFilters_Click(object sender, EventArgs e)
        {
            gridBind();


            string chipsHtml = "";

            if (!string.IsNullOrEmpty(dateFrom.Value) || !string.IsNullOrEmpty(dateTo.Value))
            {
                chipsHtml += $"<span class='filter-chip' id='chip-date'>📅 {dateFrom.Value} – {dateTo.Value} <button onclick=\"removeFilter('date')\">×</button></span>";
            }

            if (TextBox1.Text != "")
            {
                chipsHtml += $"<span class='filter-chip' id='chip-type'>🛠️ State: {TextBox1.Text} <button onclick=\"removeFilter('state')\">×</button></span>";
            }
            if (TextBox2.Text != "")
            {
                chipsHtml += $"<span class='filter-chip' id='chip-type'>🛠️ District: {TextBox2.Text} <button onclick=\"removeFilter('dist')\">×</button></span>";
            }
            if (TextBox3.Text != "")
            {
                chipsHtml += $"<span class='filter-chip' id='chip-type'>🛠️ City: {TextBox3.Text} <button onclick=\"removeFilter('city')\">×</button></span>";
            }
            if (TextBox4.Text != "")
            {
                chipsHtml += $"<span class='filter-chip' id='chip-type'>🛠️ Pincode: {TextBox4.Text} <button onclick=\"removeFilter('pin')\">×</button></span>";
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