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
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.Windows.Forms;
using System.Security.Principal;

namespace Society
{
    public partial class building_search : System.Web.UI.Page
    {
        Building building = new Building();
        BL_Building_Master bL_Building = new BL_Building_Master();
        string path, upfilename;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                Building_Gridbind();
                txt_email.Attributes.Add("onclientclick", "handleTyping('txt_email', /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/)");
                txt_ifsc.Attributes.Add("onkeyup", "handleTyping('txt_ifsc', /^[A-Z]{4}0[A-Z0-9]{6}$/)");
                txt_acc_no.Attributes.Add("onkeyup", "handleTyping('txt_acc_no', /^\\d{9,18}$/)");

            }

        }

        public void Building_Gridbind()
        {
            DataTable dt = new DataTable();
            building.Sql_Operation = "Grid_Show";
            building.Society_Id = society_id.Value;
            dt = bL_Building.getBuildingDetails(building);
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

            if (build_id.Value != "")
                building.build_id = Convert.ToInt32(build_id.Value);
            building.Sql_Operation = operation;
            building.Name = txt_name.Text;
            building.Society_Id = society_id.Value;
            building.Address1 = txt_add1.Text;
            building.Address2 = txt_add2.Text;
            building.Registration_No = txt_reg.Text;

            int noOfFloors;
            if (int.TryParse(txt_floore.Text, out noOfFloors))
            {
                building.No_Of_Floore = noOfFloors;
            }
            else
            {
                
                building.No_Of_Floore = 0; 
            }

            building.Print_Name = txt_print_name.Text;
            building.Bank_Name = txt_bank.Text;
            building.Bank_Add = txt_bank_add.Text;
            building.Branch = txt_branch.Text;
            building.Ifsc_Code = txt_ifsc.Text;
            building.Acc_No = txt_acc_no.Text;
            building.Email = txt_email.Text;
           var result =  bL_Building.updateBuildingDetails(building);
            return result.Sql_Result;

        }

        public void runproc(string operation)
        {
            if (build_id.Value != "")
                building.build_id = Convert.ToInt32(build_id.Value);
            building.Sql_Operation = operation;
            var result = bL_Building.updateBuildingDetails(building);

            (build_id.Value) = result.build_id.ToString();
            society_id.Value = result.Society_Id;
            txt_name.Text = result.Name;
            txt_add1.Text = result.Address1;
            txt_add2.Text = result.Address2;
            txt_reg.Text = result.Registration_No;
            txt_floore.Text = result.No_Of_Floore.ToString();
            txt_print_name.Text = result.Print_Name;
            txt_bank.Text = result.Bank_Name;
            txt_bank_add.Text = result.Bank_Add;
            txt_branch.Text = result.Branch;
            txt_ifsc.Text = result.Ifsc_Code;
            txt_acc_no.Text = result.Acc_No;
            txt_email.Text = result.Email;

            
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            txt_email.Attributes.Add("onkeyup", "validateEmail(this)");
            if (Label13.Text == "")
            {
                var str = runproc_save("Update");
                if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
                else
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);
                    
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (build_id.Value != "")
                    building.build_id = Convert.ToInt32(build_id.Value);
                building.Sql_Operation = "Delete";
                bL_Building.delete(building);
          
            Response.Redirect("building_search.aspx");

        }



        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("building_search.aspx");
        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            build_id.Value = id;
            runproc("Select");
           
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }


        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label build_id = (System.Web.UI.WebControls.Label)row.FindControl("build_id");
                building.Sql_Operation = "Delete";

                building.build_id = Convert.ToInt32(build_id.Text);
                bL_Building.GridViewDelete1(building);
          
                Building_Gridbind();
            
        }
        protected void btn_search_Click(object sender, EventArgs e)
        {

            building.Sql_Operation = "search";
            building.Name = txt_search.Text;
            building.Society_Id = society_id.Value;
            var result = bL_Building.search_building(building);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
          
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Building_Gridbind();
        }

        protected void txt_reg_TextChanged(object sender, EventArgs e)
        {
            if (txt_reg.Text.Trim() != "")
            {
                if (build_id.Value != "")
                    building.build_id = Convert.ToInt32(build_id.Value);
                building.Registration_No = txt_reg.Text;
                building.Sql_Operation = "check_no";
                var result = bL_Building.BuildingTextchange(building);
                Label13.Text = result.Sql_Result;
            }
        }

    }
}
