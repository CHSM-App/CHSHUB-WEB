using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Staff
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sql, string text, string value)
        {
            st.fill_drop(drp_down, sql, text, value);
        }
        public DataTable GetStaff_Details(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("society_id", Staff.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public DataTable GetStaff_Data(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("society_id", Staff.Society_Id));
            data_item.Add(st.create_array("role_id", Staff.role_id));
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public bool StaffExist(string staffName, string soceityID, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("society_id", soceityID));
            data_item.Add(st.create_array("name", staffName));
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    return false;
            return true;

        }

        public DataTable getAtteandance(int staff_id, String society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "GetAttendace"));
          
            data_item.Add(st.create_array("staff_id", staff_id));
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public staff Role_Update(staff getstaff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", getstaff.Sql_Operation));
            data_item.Add(st.create_array("role_id", getstaff.role_id));

            if (getstaff.Sql_Operation == "Role_Update")
            {
                data_item.Add(st.create_array("society_id", getstaff.Society_Id));
                data_item.Add(st.create_array("role", getstaff.role));


            }
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);
            getstaff.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (getstaff.Sql_Operation == "Role_Select")
                {
                    while (sdr.Read())
                    {

                        getstaff.Society_Id = sdr["society_id"].ToString();
                        getstaff.role_id = Convert.ToInt32(sdr["role_id"].ToString());
                        getstaff.role = sdr["role"].ToString();



                    }
                }
                else
                {
                    getstaff.Sql_Result = status1;
                }
            }
            return getstaff;
        }

        public staff Role_Change(staff getstaff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1;

            data_item.Add(st.create_array("operation", getstaff.Sql_Operation));
            data_item.Add(st.create_array("society_id", getstaff.Society_Id));
            data_item.Add(st.create_array("role_id", getstaff.role_id));
            data_item.Add(st.create_array("role", getstaff.role));
            //status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    getstaff.Sql_Result = "Already exist";
                else
                    getstaff.Sql_Result = "";
            return getstaff;
        }

        public staff Role_Delete(staff getstaff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", getstaff.Sql_Operation));
            data_item.Add(st.create_array("role_id", getstaff.role_id));

            status = st.run_query(data_item, "Delete", "sp_staff_master", ref sdr);
            if (status == "Done")
            {
                getstaff.Sql_Result = status;
            }
            return getstaff;
        }

        public DataTable Get_Role(staff getstaff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", getstaff.Sql_Operation));
            data_item.Add(st.create_array("society_id", getstaff.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public staff Contact_TextChanged(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("staff_id", Staff.staff_id));
            data_item.Add(st.create_array("contact_no", Staff.Contact_No));

            status = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    Staff.Sql_Result = "Already exist";
                else
                    Staff.Sql_Result = "";
            return Staff;
        }

        public DataTable Staff_Search(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("search", Staff.Name));
            data_item.Add(st.create_array("society_id", Staff.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public staff Delete_Staff(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("staff_id", Staff.staff_id));

            status = st.run_query(data_item, "Delete", "sp_staff_master", ref sdr);
            if (status == "Done")
            {
                Staff.Sql_Result = status;
            }
            return Staff;
        }

        public staff Update_Staff(staff Staff)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", Staff.Sql_Operation));
            data_item.Add(st.create_array("staff_id", Staff.staff_id));
            if (Staff.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", Staff.Society_Id));

                data_item.Add(st.create_array("name", Staff.Name));
                data_item.Add(st.create_array("address", Staff.Address));
                data_item.Add(st.create_array("contact_no", Staff.Contact_No));
                data_item.Add(st.create_array("email", Staff.Email));
                data_item.Add(st.create_array("date_of_join", Staff.Date_Of_Join));
                data_item.Add(st.create_array("role", Staff.role));
                data_item.Add(st.create_array("id_proof", Staff.id_proof));
                data_item.Add(st.create_array("role_id", Staff.role_id));
                data_item.Add(st.create_array("salary", Staff.Salary));
            }
            status1 = st.run_query(data_item, "Select", "sp_staff_master", ref sdr);
            Staff.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (Staff.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        Staff.Society_Id = sdr["society_id"].ToString();

                        Staff.Name = sdr["name"].ToString();
                        Staff.Address = sdr["address"].ToString();
                        Staff.Contact_No = sdr["contact_no"].ToString();
                        Staff.Email = sdr["email"].ToString();
                        Staff.Date_Of_Join = Convert.ToDateTime(sdr["date_of_join"]);
                        Staff.role_id = Convert.ToInt32(sdr["role_id"].ToString());

                    }
                }
                else
                {
                    Staff.Sql_Result = status1;
                }
            }
            return Staff;
        }


    }
}