using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Web.Configuration;
using System.Drawing.Drawing2D;
using Page = System.Web.UI.Page;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System.Windows.Forms;
using BusinessLogic.BL;
using DBCode.DataClass;
namespace Society
{
    public partial class wing_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Wing wing = new Wing();
        BL_Wing_Master bL_Wing = new BL_Wing_Master();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Building_fill();    
                Wing_GridBind();  
            }

        }

        protected override void Render(HtmlTextWriter writer)
        {
            ClientScript.RegisterForEventValidation(wing_id.UniqueID);
            base.Render(writer);
        }


        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
          {
            if (e.CommandName == "SelectCategory")
            {
                ddl_build_name.Value = e.CommandArgument.ToString();

                if (txt_w_name.Text !="")
                {
                    txt_w_name_TextChanged(source, e);
                }

            }
        }
        public void Wing_GridBind()
        {
            DataTable dt = new DataTable();
            wing.Sql_Operation = "Grid_Show"; 
            wing.Society_Id = society_id.Value;
            dt = bL_Wing.getWingDetails(wing);
            ViewState["dirState"] = dt;
            GridView1.DataSource = dt;
            GridView1.DataBind();

        } 
        public void Building_fill()
        {
            DataTable dt = new DataTable();
            wing.Sql_Operation = "FillList";
            wing.Society_Id = society_id.Value;
            dt = bL_Wing.getWingDetails(wing);
            categoryRepeater.DataSource = dt;
            categoryRepeater.DataBind();    

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

        protected void btn_search_Click(object sender, EventArgs e)
        {
            

            wing.Sql_Operation = "search";
            wing.B_Name = txt_search.Text;
            wing.Society_Id = society_id.Value;
            var result = bL_Wing.search_wing(wing);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }


        protected void btn_save_Click(object sender, EventArgs e)
        {
            if (Label4.Text == "")
            {
                 string str = runproc_save("Update");

                if (str == "Done")
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
                else
                {
                    ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

                }

            }

        }

        public string runproc_save(string operation)
        {
            if (wing_id.Value != "")
                wing.wing_id = Convert.ToInt32(wing_id.Value);
            wing.Sql_Operation = operation;
            wing.Society_Id = society_id.Value;
            wing.build_id = Convert.ToInt32(ddl_build_name.Value);
            wing.W_Name = txt_w_name.Text;
            var result = bL_Wing.updateWingDetails(wing);

            return result.Sql_Result;

        }

        public void runproc(string operation)
        {
            if (wing_id.Value != "")
              wing.wing_id = Convert.ToInt32(wing_id.Value);
            wing.Sql_Operation = operation;
            var result = bL_Wing.updateWingDetails(wing);
            categoryBox.Text = result.B_Name;
            wing_id.Value = result.wing_id.ToString();
            ddl_build_name.Value = result.build_id.ToString();
            txt_w_name.Text = result.W_Name;

        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (wing_id.Value != "")
                    wing.wing_id = Convert.ToInt32(wing_id.Value);
                wing.Sql_Operation = "Delete";

                bL_Wing.delete(wing);
           
            Response.Redirect("wing_search.aspx");
        }


        protected void txt_w_name_TextChanged(object sender, EventArgs e)
        {
            if (txt_w_name.Text.Trim() != "")
            {
                if (wing_id.Value != "")
                    wing.wing_id = Convert.ToInt32(wing_id.Value);
                wing.W_Name = txt_w_name.Text;
                if(ddl_build_name.Value !="")
                    wing.build_id = Convert.ToInt32(ddl_build_name.Value);
                wing.Sql_Operation = "check_name";
                wing.Society_Id = society_id.Value;
                var result = bL_Wing.WingTextChanged(wing);
                Label4.Text = result.Sql_Result;
               // ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
            }
        }

      

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label wing_id = (System.Web.UI.WebControls.Label)row.FindControl("wing_id");
                wing.Sql_Operation = "Delete";

                wing.wing_id = Convert.ToInt32(wing_id.Text);

                bL_Wing.delete(wing);
           
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            Wing_GridBind();
        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            wing_id.Value = id;
            runproc("Select");
            
            ScriptManager.RegisterStartupScript(this, wings.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);

            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);

        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Wing_GridBind();
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "resetForm();", true);

        }

        protected void categoryRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (ddl_build_name.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == ddl_build_name.Value)
                        categoryBox.Text = link.Text;
                }
            }
        }
    } 
}


    
