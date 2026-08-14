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
using System.IO;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.Windows.Forms;
using System.Web.Services.Description;
using BusinessLogic.BL;

namespace Society
{
    public partial class flat_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Flat flat = new Flat();
        BL_Flat_Master bL_Flat = new BL_Flat_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx"); 
            }
            else 
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {

                Allbound();

                Flat_Gridbind();
            }
        }


        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = bL_Flat.Fill_list(Session["society_id"].ToString(), "wing");
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Flat.Fill_list(Session["society_id"].ToString(), "flat_types");
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = bL_Flat.Fill_list(Session["society_id"].ToString(), "flat_usage");
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            dt = bL_Flat.Fill_list(Session["society_id"].ToString(), "flat_bedroom");
            Repeater4.DataSource = dt;
            Repeater4.DataBind();


        }
        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                Building_id.Value = e.CommandArgument.ToString();
                building_lbl.Text = e.CommandArgument.ToString();
            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                flat_type_id.Value = e.CommandArgument.ToString();

            }
        }

        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                usage_id.Value = e.CommandArgument.ToString();

            }
        }

        protected void CategoryRepeater_ItemCommand4(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                Bedroom_id.Value = e.CommandArgument.ToString();

            }
        }
       


        public void Flat_Gridbind()
        {
            DataTable dt = new DataTable();
            dt = bL_Flat.getFlatDetails(society_id.Value);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            GridView2.DataSource = dt;
            GridView2.DataBind();
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

            flat.B_Name = txt_search.Text;
            flat.Sql_Operation = "search";
            flat.Society_Id = society_id.Value;
            var result = bL_Flat.search_flat(flat);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView2.DataSource = result;
            GridView2.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }


        public string runproc_save(string operation)
        {
            if (flat_id.Value != "")
                flat.flat_id = Convert.ToInt32(flat_id.Value);
            flat.Sql_Operation = operation;
            flat.Society_Id = society_id.Value;
            flat.Flat_No = txt_no.Text;
            flat.wing_id = Convert.ToInt32(Building_id.Value.ToString());
            flat.flat_type_id = flat_type_id.Value;
            flat.Usage_Id = Convert.ToInt32(usage_id.Value.ToString());
            flat.bed_id = Convert.ToInt32(Bedroom_id.Value.ToString());
            flat.Sq_Ft = txt_feet.Text;
            flat.Terrace_Sq_Ft = txt_terrace.Text;
            flat.Intercom_No = txt_intercom.Text;
            var result  = bL_Flat.updateFlatDetails(flat);

            return result.Sql_Result;

            
           
        }

        public void runproc(string operation)
        {

            if (flat_id.Value != "")
                flat.flat_id = Convert.ToInt32(flat_id.Value);
            flat.Sql_Operation = operation;

            var result1 = bL_Flat.updateFlatDetails(flat);
            flat_id.Value = result1.flat_id.ToString();
            society_id.Value = result1.Society_Id;
            txt_no.Text = result1.Flat_No;
            Building_id.Value = result1.wing_id.ToString();
            flat_type_id.Value = result1.flat_type_id.ToString();
            usage_id.Value = result1.Usage_Id.ToString();
            Bedroom_id.Value = result1.bed_id.ToString();
            txt_feet.Text = result1.Sq_Ft;
            txt_terrace.Text = result1.Terrace_Sq_Ft;
            txt_intercom.Text = result1.Intercom_No;
            Allbound();
        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            flat_id.Value = id;
            runproc("Select");

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }
        protected void btn_save_Click(object sender, EventArgs e)
        {

        
                // btn_save.Visible = false;
                string str = runproc_save("Update");
                if (str == "Done")
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
                else
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);
                    ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);

                }
            
            
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (flat_id.Value != "")
                flat.flat_id = Convert.ToInt32(flat_id.Value);
            flat.Sql_Operation = "Delete";
            bL_Flat.FlatDelete(flat);

            Response.Redirect("flat_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("flat_search.aspx");
        }


        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void txt_no_TextChanged(object sender, EventArgs e)
        {
            if (txt_no.Text.Trim() != "")
            {

                if (flat_id.Value != "")
                    flat.flat_id = Convert.ToInt32(flat_id.Value);
                flat.Society_Id = society_id.Value;
                flat.wing_id = Convert.ToInt32(Building_id.Value);
                flat.Sql_Operation = "check_no";
                flat.Flat_No = txt_no.Text;
                var result = bL_Flat.FlatTextChange(flat);
                Label20.Text = result.Sql_Result;
            }
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label flat_id = (System.Web.UI.WebControls.Label)row.FindControl("flat_id");
            flat.Sql_Operation = "Delete";

            flat.flat_id = Convert.ToInt32(flat_id.Text);
            bL_Flat.FlatDelete(flat);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);

            Flat_Gridbind();

        }

        protected void search_field_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Flat_Gridbind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {

                var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == Building_id.Value.ToString())
                        TextBox1.Text = link.Text;
                
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (flat_type_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == flat_type_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (usage_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == usage_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }

        protected void Repeater4_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (Bedroom_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == Bedroom_id.Value)
                        TextBox4.Text = link.Text;
                }
            }
        }
    }
}


