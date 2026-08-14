using BusinessLogic.BL;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society2024
{
    public partial class new_village : System.Web.UI.Page
    {
        Login_Details Details = new Login_Details();
        BL_New_Registration new_Registration = new BL_New_Registration();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] == null || string.IsNullOrEmpty(Session["village_id"].ToString()))
            {
                Response.Redirect("login1.aspx");
            }
            village_id.Value = Session["village_id"].ToString();
            if (!IsPostBack)
            {
                fill_drop1();
        
            }
        }
        public void fill_drop1()
        {
            String sql_query1 = "Select *  from state";
            new_Registration.fill_drop(ddl_state, sql_query1, "state", "state_id");
            String sql_query2 = "Select *  from district";
            new_Registration.fill_drop(ddl_district, sql_query2, "district", "district_id");
            String sql_query3 = "Select *  from division";
            new_Registration.fill_drop(ddl_division, sql_query3, "division", "division_id");
        }

        public void runproc_save(String operation)
        {

            if (id.Value != "")
                Details.Id = Convert.ToInt32(id.Value.ToString());
            Details.Sql_Operation = "Update";
            Details.Village_Id = village_id.Value;

            Details.Name = txt_village.Text;
            Details.Contact_No1 = txt_contact_no1.Text;
            Details.Address = txt_address.Text;
            Details.Email = txt_email.Text;
            Details.State_Id = Convert.ToInt32(ddl_state.SelectedValue);
            Details.Pincode = txt_pincode.Text;
            Details.Division = ddl_division.SelectedValue;
            Details.District_Id = Convert.ToInt32(ddl_district.SelectedValue);
            new_Registration.update_village(Details);

        }

        public void runproc(String operation)
        {
            if (id.Value != "")
                Details.Id = Convert.ToInt32(id.Value);
            Details.Sql_Operation = "Select";
            var result = new_Registration.select_village(Details);

            village_id.Value = result.Village_Id;
            txt_village.Text = result.Name;
            txt_contact_no1.Text = result.Contact_No1;
            txt_email.Text = result.Email;
            txt_address.Text = result.Address;
            ddl_state.SelectedValue = result.State_Id.ToString();
            txt_pincode.Text = result.Pincode.ToString();
            ddl_division.SelectedValue = result.Division.ToString();
            ddl_district.SelectedValue = result.District_Id.ToString();
            Session["village_id"] = village_id.Value;
        }



        protected void btn_save_Click(object sender, EventArgs e)
        {
            if (Label22.Text == "")
            {
                runproc_save("Update");
                Response.Redirect("login1.aspx");
            }
            else
            {

                Response.Redirect("new_village.aspx");
            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            if (id.Value != "")
                Details.Id = Convert.ToInt32(id.Value);
            Details.Sql_Operation = "Delete";
            new_Registration.delete_village(Details);
            Response.Redirect("new_village.aspx");
        }
        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("new_village.aspx");
        }
        protected void ddl_state_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_state.Text != "select")
            {

                string sql2 = "select * from dbo.district Where state_id=" + ddl_state.SelectedValue;
                new_Registration.fill_drop(ddl_district, sql2, "district", "district_id");

            }
        }
        protected void ddl_district_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_district.Text != "select")
            {

                string sql1 = "select * from dbo.division Where district_id=" + ddl_district.SelectedValue;
                new_Registration.fill_drop(ddl_division, sql1, "division", "division_id");

            }
        }

        protected void txt_registration_TextChanged(object sender, EventArgs e)
        {
            if (id.Value != "")
                Details.Id = Convert.ToInt32(id.Value);
            Details.Sql_Operation = "check_no";
            Details.Name = txt_village.Text;
            Details.Registration_No = txt_registration.Text;
            var result = new_Registration.reg_textchanged(Details);
            Label22.Text = result.Sql_Result;
        }
    }
}