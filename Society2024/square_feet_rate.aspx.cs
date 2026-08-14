using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;


namespace Society2024
{
    public partial class square_feet_rate : System.Web.UI.Page
    {

        BL_FillRepeater repeater = new BL_FillRepeater();
        private Village village = new Village();
        private BL_Village_Master bL_Village = new BL_Village_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] == null)

                Response.Redirect("login1.aspx");
            village_id.Value = Session["village_id"].ToString();


            if (!IsPostBack)
            {
      
                Square_Feet_Gridbind();

                String sql_query = "Select * from house_type";
                repeater.fill_list(Repeater1, sql_query);

            }
        }

        protected void Square_Feet_Gridbind()
        {
            DataTable dt = new DataTable();
            village.Sql_Operation = "Grid_Show";
            village.Village_Id = village_id.Value;
            dt = bL_Village.GetSquare_Feet(village);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
        }

        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                house_type.Value = e.CommandArgument.ToString();

            }
        }
        public void runproc_save(String operation)
        {
            if (sq_rate_id.Value != "")
               village.Sq_Rate_Id = Convert.ToInt32(sq_rate_id.Value);
            village.Sql_Operation = operation;
            village.Village_Id = village_id.Value;
            village.House_Type_Id = house_type.Value;
            village.Rate = Convert.ToDecimal(txt_rate.Text);
            village.Applied_Date = Convert.ToDateTime(txt_applied_date.Text);
            village.Bill_Generation_Date = Convert.ToDateTime(txt_gen_date.Text);
            village.Due_Date = Convert.ToDateTime(txt_due.Text);
            bL_Village.Update_sq_ft_rate(village);

        }

        public void runproc(String operation)
        {
            if (sq_rate_id.Value != "")
                village.Sq_Rate_Id = Convert.ToInt32(sq_rate_id.Value);
            village.Sql_Operation = operation;
            var result = bL_Village.Update_sq_ft_rate(village);

            village_id.Value = result.Village_Id.ToString();
            sq_rate_id.Value = result.Sq_Rate_Id.ToString();
            house_type.Value = result.House_Type_Id;
            txt_rate.Text = result.Rate.ToString();
            village_id.Value = result.Village_Id;
            txt_applied_date.Text = result.Applied_Date.ToString("yyyy-MM-dd");
            txt_gen_date.Text = result.Bill_Generation_Date.ToString("yyyy-MM-dd");
            txt_due.Text = result.Due_Date.ToString("yyyy-MM-dd");

        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("SELECT dbo.square_ft_rate.sq_rate_id, dbo.square_ft_rate.rate, dbo.house_type.house_type, dbo.square_ft_rate.applied_date FROM dbo.square_ft_rate INNER JOIN dbo.house_type ON dbo.square_ft_rate.house_type_id = dbo.house_type.house_type_id and active_status=0");
            if (txt_search.Text != "")
            
            village.Sql_Operation = sb.ToString();
           
            var result = bL_Village.search_sq_ft_rate(village);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
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

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            Response.Redirect("square_feet_rate.aspx");
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("square_feet_rate.aspx");
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            sq_rate_id.Value = id;
            runproc("Select");
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

       
        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Square_Feet_Gridbind();
        }

        protected void ddl_house_type_SelectedIndexChanged(object sender, EventArgs e)
        {
           
        }


        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (house_type.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == house_type.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }
    }
}