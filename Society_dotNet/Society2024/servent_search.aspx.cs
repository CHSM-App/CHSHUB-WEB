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
//using System.Windows.Controls;
//using Azure;
using System.Drawing.Drawing2D;
using Page = System.Web.UI.Page;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System.Windows.Forms;
//using System.IdentityModel.Metadata



namespace Society
{
    public partial class servent_search : System.Web.UI.Page
    {

        Servent_Made servent = new Servent_Made();
        BL_Servent_Maid_Master bL_Servent = new BL_Servent_Maid_Master();


        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            society_id.Value = Session["society_id"].ToString();
           
            if (!IsPostBack)
            {
                ToggleTextboxes();

                Servent_Gridbind();


                if (Request.QueryString["id"] != null)
                {
                    servent_id.Value = Request.QueryString["ID"];
                    runproc_save("Select");
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
                }

            }

        }
        public void Servent_Gridbind()
        {
            DataTable dt = new DataTable();
            servent.Sql_Operation = "Grid_Show";
            servent.Society_Id = society_id.Value;
            dt = bL_Servent.getServentDetails(servent);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
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






        public string runproc_save(string operation)
        {
            if (servent_id.Value != "")
                servent.servent_id = Convert.ToInt32(servent_id.Value);
            servent.Sql_Operation = operation;
            servent.Society_Id = society_id.Value;
            servent.S_Name = txt_p_name.Text;
            servent.S_Address_1 = txt_org_addr1.Text;
            servent.S_Address_2 = txt_org_addr2.Text;
            servent.Mobile_No1 = txt_mobile_no1.Text;
            servent.Mobile_No2 = txt_mobile_no2.Text;
            servent.Remark = txt_remark.Text;
            servent.Cloth_Wash = chk_c_wash.Checked == true ? 1 : 0;
            if (txt_c_wash.Text != "")
                servent.Cloth_Wash_Charge = float.Parse(txt_c_wash.Text);
            servent.B_Wash = chk_p_wash.Checked == true ? 1 : 0;
            if (txt_p_wash.Text != "")
                servent.B_Wash_Charge = float.Parse(txt_p_wash.Text);
            servent.F_Wash = chk_f_wash.Checked == true ? 1 : 0;
            if (txt_f_wash.Text != "")
                servent.F_Wash_Charge = float.Parse(txt_f_wash.Text);
            servent.Baby_Set = chk_b_set.Checked == true ? 1 : 0;
            if (txt_b_set.Text != "")
                servent.B_Set_Charge = float.Parse(txt_b_set.Text);
            servent.Meal = chk_meal.Checked == true ? 1 : 0;
            if (txt_meal.Text != "")
                servent.Meal_Charge = float.Parse(txt_meal.Text);
            var result = bL_Servent.updateServentDetails(servent);

            return result.Sql_Result;
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            if (Label11.Text == "")
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (servent_id.Value != "")
                    servent.servent_id = Convert.ToInt32(servent_id.Value);
                servent.Sql_Operation = "Delete";
                bL_Servent.delete(servent);
                Response.Redirect("servent_search.aspx");
           
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("servent_search.aspx");
        }

        public void runproc(string operation)
        {
            if (servent_id.Value != "")
                servent.servent_id = Convert.ToInt32(servent_id.Value);
            servent.Sql_Operation = operation;

            var result = bL_Servent.runproc(servent);
       

            (servent_id.Value) = result.servent_id.ToString();
            society_id.Value = result.Society_Id;
            txt_p_name.Text = result.S_Name.ToString();
            txt_org_addr1.Text = result.S_Address_1;
            txt_org_addr2.Text = result.S_Address_2;
            txt_mobile_no1.Text = result.Mobile_No1;
            txt_mobile_no2.Text = result.Mobile_No2;
            txt_remark.Text = result.Remark;
            if (result.Cloth_Wash != 0)
            {
                chk_c_wash.Checked = true;
            }

            txt_c_wash.Text = result.Cloth_Wash_Charge.ToString();

            if (result.B_Wash != 0)
            {
                chk_p_wash.Checked = true;
            }

            txt_p_wash.Text = result.B_Wash_Charge.ToString();

            if (result.F_Wash != 0)
            {
                chk_f_wash.Checked = true;
            }

            txt_f_wash.Text = result.F_Wash_Charge.ToString();

            if (result.Baby_Set != 0)
            {
                chk_b_set.Checked = true;
            }

            txt_b_set.Text = result.B_Set_Charge.ToString();

            if (result.Meal != 0)
            {
                chk_meal.Checked = true;
            }

            txt_meal.Text = result.Meal_Charge.ToString();

        }

        private void ToggleTextboxes()
        {
            txt_meal.Enabled = chk_meal.Checked;
            txt_c_wash.Enabled = chk_c_wash.Checked;
            txt_p_wash.Enabled = chk_p_wash.Checked;
            txt_f_wash.Enabled = chk_f_wash.Checked;
            txt_b_set.Enabled = chk_b_set.Checked;
        }



        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label servent_id = (System.Web.UI.WebControls.Label)row.FindControl("servent_id");
            servent.Sql_Operation = "Delete";
            servent.servent_id = Convert.ToInt32(servent_id.Text);
            bL_Servent.delete(servent);

            Servent_Gridbind();
        }



        protected void txt_mobile_no1_TextChanged(object sender, EventArgs e)
        {
          
            
                if (servent_id.Value != "")
                servent.servent_id = Convert.ToInt32(servent_id.Value);
            servent.Sql_Operation = "check_no";
            servent.Mobile_No1 = txt_mobile_no1.Text;
            var result = bL_Servent.mobile_no_textchanged(servent);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            Label11.Text = result.Sql_Result;

        }

        protected void chk_c_wash_CheckedChanged(object sender, EventArgs e)
        {
          
            txt_c_wash.Enabled = chk_c_wash.Checked;
            if (!chk_c_wash.Checked) txt_c_wash.Text = "";

        }

        protected void chk_meal_CheckedChanged(object sender, EventArgs e)
        {
            txt_meal.Enabled = chk_meal.Checked;
            if (!chk_meal.Checked) txt_meal.Text = "";
        }

        protected void chk_p_wash_CheckedChanged(object sender, EventArgs e)
        {
            txt_p_wash.Text = "";

            txt_p_wash.Enabled = chk_p_wash.Checked;
            if (!chk_p_wash.Checked) txt_p_wash.Text = "";
        }

        protected void chk_f_wash_CheckedChanged(object sender, EventArgs e)
        {
            txt_f_wash.Text = "";

            txt_f_wash.Enabled = chk_f_wash.Checked;
            if (!chk_f_wash.Checked) txt_f_wash.Text = "";
        }

        protected void chk_b_set_CheckedChanged(object sender, EventArgs e)
        {
            txt_b_set.Text = "";

            txt_b_set.Enabled = chk_b_set.Checked;
            if (!chk_b_set.Checked) txt_b_set.Text = "";
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            servent.S_Name = txt_search.Text.Trim();
            servent.Sql_Operation = "search";
            servent.Society_Id = society_id.Value;
            var result = bL_Servent.search_servent(servent);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            servent_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);

        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Servent_Gridbind();
        }
    }
}


