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
    public class DA_Flat_Master
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getflatDetails(string society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "Grid_Show"));
            data_item.Add(st.create_array("society_id", society));

            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Fill_list(string society, string type)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "Fill_list"));
            data_item.Add(st.create_array("society_id", society));
            data_item.Add(st.create_array("type", type));


            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public Flat updateflatDetails(Flat flat)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation",flat.Sql_Operation));
            data_item.Add(st.create_array("flat_id", flat.flat_id));
            if (flat.Sql_Operation== "Update")
            {
                data_item.Add(st.create_array("society_id", flat.Society_Id));
                data_item.Add(st.create_array("flat_no", flat.Flat_No));
                data_item.Add(st.create_array("wing_id", flat.wing_id));
                data_item.Add(st.create_array("flat_type_id", flat.flat_type_id));
                data_item.Add(st.create_array("usage_id", flat.Usage_Id));
                data_item.Add(st.create_array("bed_id", flat.bed_id));
                data_item.Add(st.create_array("sq_ft", flat.Sq_Ft));
                data_item.Add(st.create_array("terrace_sq_ft", flat.Terrace_Sq_Ft));
                data_item.Add(st.create_array("intercom_no", flat.Intercom_No));
            }
            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);
            flat.Sql_Result = status1;
            if (status1 == "Done")
            {
                if (flat.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  flat_id.Value = sdr["flat_id"].ToString();
                       flat.Flat_No = sdr["flat_no"].ToString();
                       flat.flat_type_id = sdr["flat_type_id"].ToString();
                       flat.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                       flat.bed_id = Convert.ToInt32(sdr["bed_id"].ToString());
                       flat.Usage_Id =Convert.ToInt32( sdr["usage_id"].ToString());
                       flat.Terrace_Sq_Ft = sdr["terrace_sq_ft"].ToString();
                       flat.Intercom_No = sdr["intercom_no"].ToString();
                       flat.Sq_Ft = sdr["sq_ft"].ToString();
                    }
                }
                else
                {
                   flat.Sql_Result = status1;
                }
            }
            return flat;
        }

        public Flat getwing(Flat flat)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataSet ds = new DataSet();
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", flat.Sql_Operation));
            data_item.Add(st.create_array("society_id", flat.Society_Id));
            data_item.Add(st.create_array("name", flat.B_Name));
            data_item.Add(st.create_array("w_name", flat.W_Name));


            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    flat.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                else
                    flat.wing_id = 0;
            return flat;
        }

        public object search_flat(Flat flat)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", flat.Sql_Operation));
            data_item.Add(st.create_array("search", flat.B_Name));
            data_item.Add(st.create_array("society_id", flat.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);

            if (status1 == "Done")
                dt.Load(sdr);
            return dt;
        }

        public Flat FlatTextChange(Flat flat)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", flat.Sql_Operation));
            data_item.Add(st.create_array("society_id", flat.Society_Id));
            data_item.Add(st.create_array("wing_id", flat.wing_id));
            data_item.Add(st.create_array("flat_no", flat.Flat_No));
            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    flat.Sql_Result = "Already exist";
                else
                    flat.Sql_Result = "";
            return flat;

        }


        public Flat delete(Flat flat)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", flat.Sql_Operation));
            data_item.Add(st.create_array("flat_id", flat.flat_id));

            status = st.run_query(data_item, "Delete", "sp_flat_master", ref sdr);
            if (status == "Done")
            {
                flat.Sql_Result = status;
            }
            return flat;

        }





    }
}