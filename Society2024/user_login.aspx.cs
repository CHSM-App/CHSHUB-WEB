using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Configuration;
using System.Web.Configuration;


namespace Society
{
    public partial class user_login : Page
    {
       
           
            protected void Page_Load(object sender, EventArgs e)
            {

                if (!IsPostBack)
                fill_drop1();
            {
                    if (Request.QueryString["UserLoginId"] != null)
                    {
                        UserLoginId.Value = Request.QueryString["UserLoginId"].ToString();

                    }
                }
            
        }

        public void fill_drop1()
        {
            String sql_query = "Select *  from UserType";
            st.fill_drop(drp_UserTypeId, sql_query, "UserTypeName", "UserTypeId");

            
        }

            public string runproc(String operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("UserLoginId", UserLoginId.Value == null ? (object)DBNull.Value : UserLoginId.Value));
            if (operation == "Update")
            {

                data_item.Add(st.create_array("UserTypeId", string.IsNullOrWhiteSpace(drp_UserTypeId.SelectedValue) ? (object)DBNull.Value : drp_UserTypeId.SelectedValue));
                data_item.Add(st.create_array("Name", string.IsNullOrWhiteSpace(txt_Name.Text) ? (object)DBNull.Value : txt_Name.Text));
                data_item.Add(st.create_array("short_name", string.IsNullOrWhiteSpace(txt_short_name.Text) ? (object)DBNull.Value : txt_short_name.Text));

                data_item.Add(st.create_array("UserName", string.IsNullOrWhiteSpace(txt_UserName.Text) ? (object)DBNull.Value : txt_UserName.Text));
                data_item.Add(st.create_array("Password", string.IsNullOrWhiteSpace(txt_Password.Text) ? (object)DBNull.Value : txt_Password.Text));
                data_item.Add(st.create_array("Address", string.IsNullOrWhiteSpace(txt_Address.Text) ? (object)DBNull.Value : txt_Address.Text));
                data_item.Add(st.create_array("Mobile", string.IsNullOrWhiteSpace(txt_Mobile.Text) ? (object)DBNull.Value : txt_Mobile.Text));

               data_item.Add(st.create_array("Status", RadioButton1.Checked == true ? 1 : 0));
                data_item.Add(st.create_array("TelNo", string.IsNullOrWhiteSpace(txt_TelNo.Text) ? (object)DBNull.Value : txt_TelNo.Text));

                data_item.Add(st.create_array("Emailid", string.IsNullOrWhiteSpace(txt_Emailid.Text) ? (object)DBNull.Value : txt_Emailid.Text));
                data_item.Add(st.create_array("join_dt", string.IsNullOrWhiteSpace(txt_join_dt.Text) ? (object)DBNull.Value : txt_join_dt.Text));
                data_item.Add(st.create_array("last_dt", string.IsNullOrWhiteSpace(txt_last_dt.Text) ? (object)DBNull.Value : txt_last_dt.Text));
                //data_item.Add(st.create_array("designation", string.IsNullOrWhiteSpace(drp_designation.SelectedValue) ? (object)DBNull.Value : drp_designation.SelectedValue));
                //data_item.Add(st.create_array("manager", string.IsNullOrWhiteSpace(drp_manager.SelectedValue) ? (object)DBNull.Value : drp_manager.SelectedValue));
                //data_item.Add(st.create_array("branch_id", string.IsNullOrWhiteSpace(drp_branch.SelectedValue) ? (object)DBNull.Value : drp_branch.SelectedValue));
                data_item.Add(st.create_array("designation", string.IsNullOrWhiteSpace(txt_designation.Text) ? (object)DBNull.Value : txt_designation.Text));
               // data_item.Add(st.create_array("manager", string.IsNullOrWhiteSpace(txt_manager.Text) ? (object)DBNull.Value : txt_manager.Text));
              //  data_item.Add(st.create_array("branch_id", string.IsNullOrWhiteSpace(txt_branch.Text) ? (object)DBNull.Value : txt_branch.Text));

            }
            status1 = st.run_query(data_item, operation, "sp_UserLogin", ref sdr);

            
                return status1;
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc("Update");
        }
    }
}

