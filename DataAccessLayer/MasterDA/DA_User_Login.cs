using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.MasterDA
{
    public class DA_User_Login
    {
        stored st = new stored();
        public Login_Details UpdateLoginDetails(Login_Details login)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            int count = 0;
            data_item.Add(st.create_array("operation", "login"));
            data_item.Add(st.create_array("UserName", login.UserName));
            data_item.Add(st.create_array("password", login.Password));
            status1 = st.run_query(data_item, "Select", "validateuser", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {

                    count++;
                    login.UserLoginId= Convert.ToInt32(sdr["user_id"].ToString());
                    login.Name = sdr["Name"].ToString();
                    login.Society_Id = sdr["society_id"].ToString();
                    login.Village_Id = sdr["village_id"].ToString();
                    login.Society_Name = sdr["Society_name"].ToString();
                    login.Type = sdr["type"].ToString();

                }
               
            }
            return login;
        }

        public DataTable single_receipt(Login_Details details)
        {
            throw new NotImplementedException();
        }

        public Login_Details generate_token(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("user_id", details.UserLoginId));
            data_item.Add(st.create_array("web_token", details.Web_Token));

            status1 = st.run_query(data_item, "Select", "sp_UserLogin", ref sdr);
            if (status1 == "Done")
            {
                details.Sql_Result = status1;
            }
            return details;
        }

        public Login_Details InsertPayment(Login_Details paymentDetails)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";

            // Add payment parameters
            data_item.Add(st.create_array("receipt_id",0));
            data_item.Add(st.create_array("operation", "UPDATE"));
            data_item.Add(st.create_array("total_amount", paymentDetails.City));

            data_item.Add(st.create_array("paid_amount", paymentDetails.Amount));
            data_item.Add(st.create_array("paymode", paymentDetails.Paymode));           
            data_item.Add(st.create_array("society_id", paymentDetails.Society_Id));

            // Execute the stored procedure (you may want to update the name accordingly)
            status = st.run_query(data_item, "Select", "sp_SocietyReceipt", ref sdr);
            if (status == "Done")
            {
                paymentDetails.Sql_Result = status;
            }

            return paymentDetails;
        }

        public DataTable show_receipt(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("Society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_SocietyReceipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }


        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable Event_Details(Login_Details details)
        {
                ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                SqlDataReader sdr = null;
                string status1;
                DataTable dt = new DataTable();
                data_item.Add(st.create_array("operation", details.Sql_Operation));
                data_item.Add(st.create_array("society_id", details.Society_Id));

                status1 = st.run_query(data_item, "Select", "sp_event_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {
                    dt.Load(sdr);
                }
                return dt;
           
        }

        public DataTable get_notification(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            data_item.Add(st.create_array("user_id", details.UserLoginId));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {
                    dt.Load(sdr);
                }
            return dt;

        }


        public DataTable Search_receipt(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("Society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }



        public DataTable Search_Admin(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("search", details.Name));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public Login_Details getResidents(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
          
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                while(sdr.Read())
                   
                details.Sql_Result = sdr["residents"].ToString();
            }
            return details;
        }

        public Login_Details Generate_Token(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("user_id", details.UserLoginId));
            data_item.Add(st.create_array("web_token", details.Web_Token));

            status1 = st.run_query(data_item, "Select", "sp_UserLogin", ref sdr);
            if (status1 == "Done")
            {
                details.Sql_Result = status1;
            }
            return details;
        }

        public Login_Details Get_Mail(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {

                    details.Open = Convert.ToInt32(sdr["opened"].ToString());
                    details.Resolve = Convert.ToInt32(sdr["resolved"].ToString());

                }

            }
            return details;
        }

        public DataTable SearchDefaulter(Login_Details details)
        {
                ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                SqlDataReader sdr = null;
                string status1 = "";

                DataTable dt = new DataTable();
                data_item.Add(st.create_array("Operation", details.Sql_Operation));
                data_item.Add(st.create_array("society_id", details.society_id));
                data_item.Add(st.create_array("search", details.Name));


                    status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

                if (status1 == "Done")
                if(sdr.HasRows)
                    dt.Load(sdr);
                return dt;
           
        }

        public DataTable Get_Recent_Search(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", details.Sql_Operation));
           
            data_item.Add(st.create_array("query", details.Name));
           
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Login_Details GetTicket(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {

                    details.Open = Convert.ToInt32(sdr["opened"].ToString());
                    details.Resolve = Convert.ToInt32(sdr["resolved"].ToString());

                }

            }
            return details;
        }

        public DataTable GetDefaulter(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    dt.Load(sdr);

            }
            return dt;
        }

        public DataTable GetMonth(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if(sdr.HasRows)
                dt.Load(sdr);

            }
            return dt;
        }

        public Login_Details UpdateNotifyStatus(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            data_item.Add(st.create_array("user_id", details.NoticeId));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);

            if (status1 == "Done")
                details.Sql_Result = status1;
            return details;

        }
        public DataTable dashUpdates(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    dt.Load(sdr);

            }
            return dt;
        }
        public DataTable Income_Chart(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable ChartData = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            data_item.Add(st.create_array("date1", details.Establish_Date));
            data_item.Add(st.create_array("date2", details.Otp_Date));
            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    ChartData.Load(sdr);
            }
            return ChartData;
        }

        public DataTable Get_Expense_Chart(Login_Details details)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable ChartData = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));
            data_item.Add(st.create_array("expense", details.ExpenseType));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    ChartData.Load(sdr);
            }
            return ChartData;
        }

        public DataTable Get_Recent_Chart(Login_Details details)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable ChartData = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_dashboard", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    ChartData.Load(sdr);
            }
            return ChartData;
        }

        public DataTable Pdc_Clear(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataSet ds = new DataSet();
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                //if (sdr.HasRows)
                {


                    dt.Load(sdr);
                    
                }
            return dt;
        }

        public DataTable Meeting_Details(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {


                    dt.Load(sdr);
                    
                }
            return dt;
        }

        public DataTable Notice_Details(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_notice_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)

                    dt.Load(sdr);
                  
            return dt;
        }

        public DataTable Maintenance_Details(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataSet ds = new DataSet();
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_maintenance_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {


                    dt.Load(sdr);

                }
            return dt;
        }

        public DataTable Receipt_Details(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_receipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {


                    dt.Load(sdr);
                    
                }
            return dt;
        }

        public Society_Member CheckDuplicateUsername(Society_Member member)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader dr = null;
            string status = "";

            data_item.Add(st.create_array("operation", "check_email"));
            data_item.Add(st.create_array("email", member.Email));
            data_item.Add(st.create_array("user_id", member.UserId));

            status = st.run_query(data_item, "Select", "sp_UserLogin", ref dr);

            member.Sql_Result = (status == "Done" && dr.Read()) ? "Exist" : "Available";
            return member;
        }

        public Login_Details GetLoginByUsername(string username)
        {
            Login_Details login = new Login_Details();
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            data_item.Add(st.create_array("operation", "login"));  // your SP should handle this
            data_item.Add(st.create_array("UserName", username));

            string status = st.run_query(data_item, "Select", "validateuser", ref sdr);
            if (status == "Done" && sdr.HasRows)
            {
                while (sdr.Read())
                {
                    login.UserLoginId = Convert.ToInt32(sdr["user_id"].ToString());
                    login.Name = sdr["Name"].ToString();
                    login.UserName = sdr["UserName"].ToString();
                    login.Password = sdr["Password"].ToString(); // This is the hashed password
                    login.Society_Id = sdr["society_id"].ToString();
                    login.Village_Id = sdr["village_id"].ToString();
                    login.Society_Name = sdr["Society_name"].ToString() == ""? sdr["village_name"].ToString(): sdr["Society_name"].ToString();
                    login.Type = sdr["type"].ToString();
                    login.User_Type_Name = sdr["UserTypeName"].ToString();
                    login.Email = sdr["Owner_id"].ToString();
                }
            }

            return login;
        }

        public int get_messages_count(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";

            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.Society_Id));

            status = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    return Convert.ToInt32(sdr["message_count"].ToString());
            return 0;
        }

        public DataTable getOwnerDues(Login_Details details)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("society_id", details.society_id));
            data_item.Add(st.create_array("flat_id", details.Id));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                {
                    dt.Load(sdr);
                }
            return dt;
        }
    }
}