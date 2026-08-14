using BusinessLogic.BL;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class v_history_table : System.Web.UI.Page
    {
        bl_v_resident bL_House = new bl_v_resident();
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

        protected void gridBind()
        {
            string operation = "house_history";
            string village_id = Session["village_id"].ToString();
            DataTable dt = bL_House.gridBindHistory(operation, village_id);
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {

        }
    }
} 