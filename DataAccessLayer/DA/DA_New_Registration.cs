using Society;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_New_Registration
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public Login_Details update_registration(Login_Details details)                                         
        {

          ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();

            SqlDataReader sdr1 = null;
            int sdr = 0;

            string status1 = "";
            if (details.Type == "Society")
                data_item.Add(st.create_array("operation", "new_society"));
            else

                data_item.Add(st.create_array("operation", "new_village"));
            status1 = st.run_query_scalar(data_item, "Select", "sp_UserLogin", ref sdr);
            if (status1 == "Done")
                details.Id = Convert.ToInt32(sdr.ToString());
            data_item.Clear();

            data_item.Add(st.create_array("operation", "Select"));

            if (details.Type == "Society")
            {

                data_item.Add(st.create_array("society_master_id", details.Id));
                status1 = st.run_query(data_item, "Select", "sp_society_master", ref sdr1);
            }
            else
            {
                data_item.Add(st.create_array("id", details.Id));
                status1 = st.run_query(data_item, "Select", "sp_village_master", ref sdr1);
            }
            if (status1 == "Done")
                if (sdr1.Read())
                {
                    if (details.Type == "Society")
                        details.Society_Id = sdr1["society_id"].ToString();
                    else
                        details.Village_Id = sdr1["village_id"].ToString();
                }
                    data_item.Clear();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("user_id", details.UserLoginId));
           if (details.Sql_Operation == "Update")
            {
                if(details.Designation==0)
                    data_item.Add(st.create_array("user_type_id", 1));
                else
                data_item.Add(st.create_array("user_type_id", details.Designation));
                data_item.Add(st.create_array("type", details.Type));
                data_item.Add(st.create_array("society_id", details.Society_Id));
                data_item.Add(st.create_array("village_id", details.Village_Id));
                data_item.Add(st.create_array("Name", details.Name));
                data_item.Add(st.create_array("UserName", details.UserName));
                data_item.Add(st.create_array("Password", details.Password));
                data_item.Add(st.create_array("address1", details.Address));
                data_item.Add(st.create_array("contact_no", details.Mobile));
                data_item.Add(st.create_array("Email", details.Emailid));

            }
           status1 = st.run_query(data_item, "Select", "sp_UserLogin", ref sdr1);
            
                details.Sql_Result = status1;
           
            return details;
        }

        public Login_Details email_check(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            //data_item.Add(st.create_array("s_id", details.S_Id));
            data_item.Add(st.create_array("email", details.Emailid));
       
            status = st.run_query(data_item, "Select", "sp_UserLogin", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    details.Sql_Result = "Exist";
                else
                    details.Sql_Result = "";
            return details;
        }

        public Login_Details Update_Society(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            int sdr1 = 0;
            string status1 = "";

            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_master_id", details.society_master_id));

            if (details.Sql_Operation == "insert")
            {
                // BASIC INFO
                data_item.Add(st.create_array("society_id", details.society_id));
                data_item.Add(st.create_array("name", details.Name));
                data_item.Add(st.create_array("establish_date",
                    details.Establish_Date == DateTime.MinValue ? (object)DBNull.Value : details.Establish_Date));
                data_item.Add(st.create_array("registration_no", details.Registration_No));

                // Terms & Conditions
                data_item.Add(st.create_array("terms", details.Terms_Conditions));

                // CONTACT INFO
                data_item.Add(st.create_array("off_address1", details.Office_Address1));
                data_item.Add(st.create_array("off_address2", details.Office_Address2));
                data_item.Add(st.create_array("contact_no1", details.Contact_No));
                data_item.Add(st.create_array("email", details.Email));

                // LOCATION
                data_item.Add(st.create_array("city", details.City));
                data_item.Add(st.create_array("state_id", details.State_Id));
                data_item.Add(st.create_array("district_id", details.District_Id));
                data_item.Add(st.create_array("division_id", details.Division));
                data_item.Add(st.create_array("pincode", details.Pincode));
                data_item.Add(st.create_array("home_no", details.Home_No));

                // MAINTENANCE SETTINGS
                data_item.Add(st.create_array("rate_per_sqf", details.Per_Sqft_Rate));
                data_item.Add(st.create_array("two_w_rate", details.Two_Wheeler_Rate));
                data_item.Add(st.create_array("four_w_rate", details.Four_Wheeler_Rate));
                data_item.Add(st.create_array("bill_gen_date", details.Generation_Day));
                data_item.Add(st.create_array("bill_due_period", details.Due_Period_Days));
                data_item.Add(st.create_array("auto_bill_generation", details.Auto_Generation ? 1 : 0));
                data_item.Add(st.create_array("type", "New"));
                
                

                //// META
                //data_item.Add(st.create_array("created_date",
                //    details.Created_Date == DateTime.MinValue ? (object)DateTime.Now : details.Created_Date));
                //data_item.Add(st.create_array("is_active", details.Is_Active ? 1 : 0));
            }

            status1 = st.run_query_scalar(data_item, "Select", "sp_society_master", ref sdr1);
            details.Sql_Result = status1;

            return details;
        }

        public Login_Details reg_textchanged(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_master_id", details.society_master_id));
            data_item.Add(st.create_array("name", details.Name));
            data_item.Add(st.create_array("registration_no", details.Registration_No));

            status = st.run_query(data_item, "Select", "sp_society_master", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    details.Sql_Result = "Already exist";
                else
                    details.Sql_Result = "";
            return details;

        }

        public Login_Details Delete_Registration(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("event_id", details.event_id));

            status = st.run_query(data_item, "Delete", "sp_event_master", ref sdr);
            if (status == "Done")
            {
                details.Sql_Result = status;
            }
            return details;
        }

        //public object select_society(Login_Details details)
        //{

        //}
        public Login_Details Textchanged_Reg(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("id", details.Id));
            data_item.Add(st.create_array("name", details.Name));
            data_item.Add(st.create_array("registration_no", details.Registration_No));

            status = st.run_query(data_item, "Select", "sp_village_master", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    details.Sql_Result = "Already exist";
                else
                    details.Sql_Result = "";
            return details;
        }

        public Login_Details Select_Village(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("id", details.Id));
            status1 = st.run_query(data_item, "Select", "sp_village_master", ref sdr);
            if (status1 == "Done")
            {
                if (details.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        details.Village_Id = sdr["village_id"].ToString();
                        details.Contact_No1 = sdr["contact_no"].ToString();
                        details.Email = sdr["email"].ToString();
                        details.Address = sdr["address"].ToString();
                        details.State_Id = Convert.ToInt32(sdr["state_id"].ToString());
                        details.Pincode = sdr["pincode"].ToString();
                        details.Division = sdr["division"].ToString();
                        details.District_Id = Convert.ToInt32(sdr["district_id"].ToString());

                    }
                }

            }
            return details;
        }

        public Login_Details Update_Village(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            int sdr1 = 0;
            string status1 = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("id", details.Id));
            if (details.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("village_id", details.Village_Id));
                data_item.Add(st.create_array("name", details.Name));
                data_item.Add(st.create_array("contact_no", details.Contact_No1));
                data_item.Add(st.create_array("address", details.Address));
                data_item.Add(st.create_array("email", details.Email));
                data_item.Add(st.create_array("state_id", details.State_Id));
                data_item.Add(st.create_array("pincode", details.Pincode));
                data_item.Add(st.create_array("division", details.Division));
                data_item.Add(st.create_array("district_id", details.District_Id));

            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_village_master", ref sdr1);

            return details;
        }

       
        public Login_Details select_society(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_master_id", details.society_master_id));
            status1 = st.run_query(data_item, "Select", "sp_society_master", ref sdr);
            if (status1 == "Done")
            {
                if (details.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        details.Society_Id = sdr["society_id"].ToString();
                        details.Establish_Date = Convert.ToDateTime(sdr["establish_date"].ToString());
                        details.Registration_No = sdr["registration_no"].ToString();
                        details.Off_Address1 = sdr["off_address1"].ToString();
                        details.Off_Address2 = sdr["off_address2"].ToString();
                        details.Contact_No1 = sdr["contact_no1"].ToString();
                        details.Email = sdr["email"].ToString();
                        details.City = sdr["city"].ToString();
                        details.State_Id = Convert.ToInt32(sdr["state_id"].ToString());
                        details.Pincode = sdr["pincode"].ToString();
                        details.Home_No = Convert.ToInt32(sdr["home_no"].ToString());
                        details.Division = sdr["division_id"].ToString();
                        details.District_Id = Convert.ToInt32(sdr["district_id"].ToString());

                    }
                }
                
            }
            return details;

        }
        public Login_Details Delete_Village(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("id", details.Id));

            status = st.run_query(data_item, "Delete", "sp_village_master", ref sdr);
            if (status == "Done")
            {
                details.Sql_Result = status;
            }
            return details;
        }
        public Login_Details New_Society(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", "check_id"));
            data_item.Add(st.create_array("society_master_id", details.society_master_id));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_society_master", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.Read())
                {
                    details.Society_Id = sdr["society_id"].ToString();
                }
                else
                {
                    details.Sql_Result = status1;
                }
            }
            return details;
        }
    }
}

