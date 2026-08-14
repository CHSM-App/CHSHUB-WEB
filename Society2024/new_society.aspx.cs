using BusinessLogic.BL;
using Society;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society2024
{

    public partial class society1 : System.Web.UI.Page
    {
        Login_Details Details = new Login_Details();
        BL_New_Registration new_Registration = new BL_New_Registration();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                fill_drop1();
            }
        }

        public void fill_drop1()
        {
            String sql_query = "Select *  from state";
            new_Registration.fill_drop(ddl_state, sql_query, "state", "state_id");

            String sql_query1 = "Select *  from district";
            new_Registration.fill_drop(ddl_district, sql_query1, "district", "district_id");
            String sql_query2 = "Select *  from division";
            new_Registration.fill_drop(ddl_division, sql_query2, "division", "division_id");
        }

        protected void txt_registration_TextChanged(object sender, EventArgs e)
        {
            if (!string.IsNullOrWhiteSpace(txt_registration.Text))
            {
                if (!string.IsNullOrEmpty(society_master_id.Value))
                    Details.society_master_id = Convert.ToInt32(society_master_id.Value);

                Details.Sql_Operation = "check_no";
                Details.Name = txt_name.Text;
                Details.Registration_No = txt_registration.Text;
                var result = new_Registration.Reg_Textchanged(Details);
                Label22.Text = result.Sql_Result;
            }
            else
            {
                Label22.Text = "";
            }
        }

        protected void ddl_state_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_state.Text != "select")
            {
                if (ddl_state.SelectedIndex <= 0) return;

                string sql1 = "select * from dbo.district Where state_id=" + ddl_state.SelectedValue;
                new_Registration.fill_drop(ddl_district, sql1, "district", "district_id");
                //upnlLocation.Update();

            }
        }


        protected void ddl_district_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_district.Text != "select")
            {
                if (ddl_district.SelectedIndex <= 0) return;
                string sql2 = "select * from dbo.division Where district_id=" + ddl_district.SelectedValue;
                new_Registration.fill_drop(ddl_division, sql2, "division", "division_id");

            }
        }

        protected void btn_save_Click(object sender, EventArgs e)
        
        {
            try
            {
                // Collect all form data into Details object
                Details.Sql_Operation = "insert";
                //Details.society_id = Session["society_id"].ToString();
                Details.society_id = "C10014";
                // Step 1: Basic Info
                Details.Name = txt_name.Text.Trim();
                Details.Establish_Date = !string.IsNullOrEmpty(txt_es_date.Text)
                    ? Convert.ToDateTime(txt_es_date.Text)
                    : DateTime.MinValue;
                Details.Registration_No = txt_registration.Text.Trim();
                Details.Terms_Conditions = editor1.Text; // Rich text content

                // Step 2: Contact Info
                Details.Office_Address1 = txt_off_address1.Text.Trim();
                Details.Office_Address2 = txt_off_address2.Text.Trim();
                Details.Contact_No = txt_contact_no1.Text.Trim();
                Details.Email = txt_email.Text.Trim();

                // Step 3: Location
                Details.State_Id = ddl_state.SelectedValue != "0"
                    ? Convert.ToInt32(ddl_state.SelectedValue) : 0;
                Details.State_Name = ddl_state.SelectedItem?.Text ?? "";
                Details.District_Id = ddl_district.SelectedValue != "0"
                    ? Convert.ToInt32(ddl_district.SelectedValue) : 0;
                Details.District_Name = ddl_district.SelectedItem?.Text ?? "";
                Details.Division_Id = ddl_division.SelectedValue != "0"
                    ? Convert.ToInt32(ddl_division.SelectedValue) : 0;
                Details.Division_Name = ddl_division.SelectedItem?.Text ?? "";
                Details.City = txt_city.Text.Trim();
                Details.Street_Home_No = txt_street.Text.Trim();
                Details.Pincode = txt_pincode.Text.Trim();

                // Step 4: Maintenance Settings
                Details.Per_Sqft_Rate = !string.IsNullOrEmpty(txt_per_sqft_rate.Text)
                    ? Convert.ToDecimal(txt_per_sqft_rate.Text) : 0;
                Details.Two_Wheeler_Rate = !string.IsNullOrEmpty(txt_2w_rate.Text)
                    ? Convert.ToDecimal(txt_2w_rate.Text) : 0;
                Details.Four_Wheeler_Rate = !string.IsNullOrEmpty(txt_4w_rate.Text)
                    ? Convert.ToDecimal(txt_4w_rate.Text) : 0;
                Details.Generation_Day = !string.IsNullOrEmpty(txt_gen_day.Text)
                    ? Convert.ToInt32(txt_gen_day.Text) : 1;
                Details.Due_Period_Days = !string.IsNullOrEmpty(txt_due_period.Text)
                    ? Convert.ToInt32(txt_due_period.Text) : 15;
                Details.Auto_Generation = chk_auto_gen.Checked;
                Details.Created_Date = DateTime.Now;
                Details.Is_Active = true;

                // If editing existing record
                if (!string.IsNullOrEmpty(society_master_id.Value))
                {
                    Details.society_master_id = Convert.ToInt32(society_master_id.Value);
                    Details.Sql_Operation = "update";
                }

                //Call business logic to save
               var result = new_Registration.Update_Society(Details);
                if (result.Sql_Result == "Done")
                {
                    society_master_id.Value = result.Society_Id.ToString();
                    ScriptManager.RegisterStartupScript(this, GetType(), "SuccessAlert", "SuccessEntry();", true);
                }
                else
                {
                    ShowErrorMessage("Error saving society");
                }
            }
            catch (Exception ex)
            {
                ShowErrorMessage("Error: " + ex.Message);
            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            //if (!string.IsNullOrEmpty(society_master_id.Value))
            //{
            //    try
            //    {
            //        Details.society_master_id = Convert.ToInt32(society_master_id.Value);
            //        Details.Sql_Operation = "delete";

            //        var result = new_Registration.Delete_Society(Details);

            //        if (result.Success)
            //        {
            //            ClearForm();
            //            ShowSuccessMessage("Society deleted successfully!");
            //        }
            //        else
            //        {
            //            ShowErrorMessage(result.Error_Message ?? "Error deleting society");
            //        }
            //    }
            //    catch (Exception ex)
            //    {
            //        ShowErrorMessage("Error: " + ex.Message);
            //    }
            //}
        }

        // For compatibility - not used in wizard
        protected void btnSubmit_Click(object sender, EventArgs e) { }
        protected void btnSave_Click(object sender, EventArgs e) { }

        private void ClearForm()
        {
            txt_name.Text = string.Empty;
            txt_es_date.Text = string.Empty;
            txt_registration.Text = string.Empty;
            txt_off_address1.Text = string.Empty;
            txt_off_address2.Text = string.Empty;
            txt_contact_no1.Text = string.Empty;
            txt_email.Text = string.Empty;
            txt_city.Text = string.Empty;
            txt_street.Text = string.Empty;
            txt_pincode.Text = string.Empty;
            hdnTermsContent.Value = string.Empty;
            txt_per_sqft_rate.Text = string.Empty;
            txt_2w_rate.Text = string.Empty;
            txt_4w_rate.Text = string.Empty;
            txt_gen_day.Text = string.Empty;
            txt_due_period.Text = string.Empty;
            chk_auto_gen.Checked = false;

            ddl_state.SelectedIndex = 0;
            ddl_district.Items.Clear();
            ddl_district.Items.Insert(0, new ListItem("-- Select District --", "0"));
            ddl_division.Items.Clear();
            ddl_division.Items.Insert(0, new ListItem("-- Select Division --", "0"));

            society_master_id.Value = string.Empty;
            hdnCurrentStep.Value = "1";
            Label22.Text = string.Empty;
        }

        private void ShowErrorMessage(string message)
        {
            string safeMessage = message.Replace("'", "\\'").Replace("\r\n", " ").Replace("\n", " ");
            ScriptManager.RegisterStartupScript(this, GetType(), "ErrorAlert",
                $"Swal.fire({{ title: 'Error!', text: '{safeMessage}', icon: 'error', confirmButtonColor: '#d33' }});", true);
        }

        private void ShowSuccessMessage(string message)
        {
            string safeMessage = message.Replace("'", "\\'");
            ScriptManager.RegisterStartupScript(this, GetType(), "SuccessAlert",
                $"Swal.fire({{ title: 'Success!', text: '{safeMessage}', icon: 'success', confirmButtonColor: '#3085d6' }});", true);
        }
    }
}
