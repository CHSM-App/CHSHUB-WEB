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
    public class DA_Contact_Master
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }


        public DataTable Get_usefull_contact(string society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "Grid_Show"));
            data_item.Add(st.create_array("society_id", society));

            status1 = st.run_query(data_item, "Select", "sp_Caretaker_master", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }


        public usefull_Contact Update_Contact_Details(usefull_Contact contact)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", contact.Sql_Operation));
            data_item.Add(st.create_array("usefull_contact_id", contact.usefull_contact_id));
            if (contact.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", contact.Society_Id));
                data_item.Add(st.create_array("p_name", contact.P_Name));
                data_item.Add(st.create_array("p_type", contact.P_Type));
                data_item.Add(st.create_array("org_name", contact.Org_Name));
                data_item.Add(st.create_array("contact_address", contact.Contact_Address));
                data_item.Add(st.create_array("address2", contact.Address2));
                data_item.Add(st.create_array("contact_no", contact.Contact_No));
                data_item.Add(st.create_array("email", contact.Email));
                data_item.Add(st.create_array("id_path", contact.id_path));
                data_item.Add(st.create_array("remark", contact.Remark));

            }
            status1 = st.run_query(data_item, "Select", "sp_usefull_contact", ref sdr);
            contact.Sql_Result = status1;

            if (status1 == "Done") 
            {
                if (contact.Sql_Operation == "select")
                {
                    while (sdr.Read())
                    {
                        //evt.Event_Id = Convert.ToInt32(sdr["event_id"].ToString());
                        contact.Society_Id = sdr["society_id"].ToString();
                        contact.P_Name = sdr["p_name"].ToString();
                        contact.P_Type = Convert.ToInt32(sdr["p_type"].ToString());
                        contact.Org_Name = sdr["org_name"].ToString();
                        contact.Contact_Address = sdr["contact_address"].ToString();
                        contact.Address2 = sdr["address2"].ToString();
                        contact.Contact_No = sdr["contact_no"].ToString();
                        contact.Email = sdr["email"].ToString();
                        contact.Remark = sdr["remark"].ToString();

                    }
                }
                else
                {
                    contact.Sql_Result = status1;
                }

            }
            return contact;


        }

        public DataTable usefull_contact_search(usefull_Contact usefull)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", usefull.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public usefull_Contact Delete_Contact(usefull_Contact contact)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", contact.Sql_Operation));
            data_item.Add(st.create_array("usefull_contact_id", contact.usefull_contact_id));

            status = st.run_query(data_item, "Delete", "sp_usefull_contact", ref sdr);
            if (status == "Done")
            {
                contact.Sql_Result = status;
            }
            return contact;
        }

        public usefull_Contact per_type_selectIndexChanged(usefull_Contact contact)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", contact.Sql_Operation));
            data_item.Add(st.create_array("usefull_contact_id", contact.usefull_contact_id));
            data_item.Add(st.create_array("p_name", contact.P_Name));
            data_item.Add(st.create_array("p_type", contact.P_Type));
            status1 = st.run_query(data_item, "Select", "sp_usefull_contact", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    contact.Sql_Result = "Already exist";
                else
                    contact.Sql_Result = "";
            return contact;

        }
        public DataTable get_contact_details_1(usefull_Contact contact)
        {
                ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                SqlDataReader sdr = null;
                string status1 = "";
                DataTable dt = new DataTable();
                data_item.Add(st.create_array("operation",contact.Sql_Operation));
                data_item.Add(st.create_array("society_id", contact.Society_Id));
                data_item.Add(st.create_array("p_type", contact.P_Type));
            data_item.Add(st.create_array("search", contact.P_Name));

            status1 = st.run_query(data_item, "Select", "sp_usefull_contact", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
                return dt;
           
        }

      
    }
}