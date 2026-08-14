using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace DataAccessLayer.MasterDA
{

    public class DA_CareTaker_Master
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getCaretakerDetails(string society)
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

        public DataTable Fill_list(string society_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("society_id", society_id));
            data_item.Add(st.create_array("operation", operation));

            status1 = st.run_query(data_item, "Select", "sp_Caretaker_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt; ; 
        }

        public Caretaker updateCaretakerDetails(Caretaker care)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", care.Sql_Operation));
            data_item.Add(st.create_array("caretaker_id", care.Caretaker_Id));
            if (care.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", care.Society_Id));
                data_item.Add(st.create_array("wing_id", care.Wing_Id));
                data_item.Add(st.create_array("flat_no", care.Flat_No));
                data_item.Add(st.create_array("c_name", care.C_Name));
                data_item.Add(st.create_array("doc_id", care.doc_id));
                data_item.Add(st.create_array("c_address", care.C_Address));
                data_item.Add(st.create_array("area", care.Area));
                data_item.Add(st.create_array("mobile_no", care.Mobile_No));
                data_item.Add(st.create_array("email", care.Email));
                data_item.Add(st.create_array("city", care.City));
                data_item.Add(st.create_array("state_id", care.State_Id));
                data_item.Add(st.create_array("pincode", care.Pincode));
                data_item.Add(st.create_array("doc_executed", care.Doc_Executed));

            }
            status1 = st.run_query(data_item, "Select", "sp_caretaker_master", ref sdr);
            care.Sql_Result = status1;

            if (status1 == "Done")
            { 
                if (care.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        care.Wing_Id = Convert.ToInt32(sdr["wing_id"].ToString());
                        care.Flat_No = sdr["flat_no"].ToString();
                        care.C_Name = sdr["c_name"].ToString();
                        care.doc_id = Convert.ToInt32(sdr["doc_id"].ToString());
                        care.C_Address = sdr["c_address"].ToString();
                        care.Area = sdr["area"].ToString();
                        care.Mobile_No = sdr["mobile_no"].ToString();
                        care.Email = sdr["email"].ToString();
                        care.City = sdr["city"].ToString();
                        care.State_Id = Convert.ToInt32(sdr["state_id"].ToString());
                        care.Pincode = sdr["pincode"].ToString();
                        care.Doc_Executed = sdr["doc_executed"].ToString();
                    }
                }
                else
                {
                    care.Sql_Result = status1;
                }
            }
            return care;

        }

        public object caretaker_search(Caretaker care)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", care.Sql_Operation));
            data_item.Add(st.create_array("search", care.C_Name));
            data_item.Add(st.create_array("society_id", care.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_caretaker_master", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Caretaker Delete_CareTaker(Caretaker care)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", care.Sql_Operation));
            data_item.Add(st.create_array("caretaker_id", care.Caretaker_Id));

            status = st.run_query(data_item, "Delete", "sp_caretaker_master", ref sdr);
            if (status == "Done")
            {
                care.Sql_Result = status;
            }
            return care;
        }

        //public Caretaker getflatno(Caretaker care)
        //{
        //    ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
        //    SqlDataReader sdr = null;
        //    string status1 = "";
        //    data_item.Add(st.create_array("operation", care.Sql_Operation));
        //    data_item.Add(st.create_array("wing_id",care.wing_id));

        //    status1 = st.run_query(data_item, "Select", "sp_party", ref sdr);

        //    if (status1 == "Done")
        //        while (sdr.Read())
        //        {
        //            care.Flat_No = sdr["flat_no"].ToString();

        //        }
        //    return care;
        //}
    }
}