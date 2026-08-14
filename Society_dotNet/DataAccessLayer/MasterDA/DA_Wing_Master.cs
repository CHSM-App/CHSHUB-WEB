using DBCode.DataClass.Master_Dataclass;
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
    public class DA_Wing_Master
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable getWingDetails(Wing wing)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", wing.Sql_Operation));
            data_item.Add(st.create_array("society_id", wing.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public Wing getbuilding(Wing wing)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            DataSet ds = new DataSet();
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", wing.Sql_Operation));
            data_item.Add(st.create_array("society_id", wing.Society_Id));
            data_item.Add(st.create_array("build_name", wing.B_Name));
            
          
            status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    wing.build_id = Convert.ToInt32(sdr["build_id"].ToString());
                else
                    wing.build_id = 0;
            return wing;

        }

        public Wing updateWingDetails(Wing wing)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            data_item.Add(st.create_array("operation", wing.Sql_Operation));
            data_item.Add(st.create_array("wing_id", wing.wing_id));
            if (wing.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", wing.Society_Id));
                data_item.Add(st.create_array("build_id", wing.build_id));
                data_item.Add(st.create_array("w_name", wing.W_Name));
            }
            status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);
            wing.Sql_Result = status1;
            if (status1 == "Done")
            {
                if (wing.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        wing.B_Name = sdr["name"].ToString();
                        wing.build_id = Convert.ToInt32(sdr["build_id"].ToString());
                        wing.W_Name = sdr["w_name"].ToString();
                    }
                }
            }
            return wing;
        }

        public object wing_search(Wing wing)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("search", wing.B_Name));
            data_item.Add(st.create_array("Operation", wing.Sql_Operation));
            data_item.Add(st.create_array("society_id", wing.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Wing delete(Wing wing)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status ;
            data_item.Add(st.create_array("operation", wing.Sql_Operation));
            data_item.Add(st.create_array("wing_id",wing.wing_id));

            status = st.run_query(data_item, "Delete", "sp_wing_master", ref sdr);
            if (status == "Done")
            {
                wing.Sql_Result = status;
            }
             return wing;
        }

        public Wing WingTextChanged(Wing wing)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
          
            string status1 ;
           
            data_item.Add(st.create_array("operation", wing.Sql_Operation));
            data_item.Add(st.create_array("society_id", wing.Society_Id));
            data_item.Add(st.create_array("build_id", wing.build_id));
            data_item.Add(st.create_array("wing_id", wing.wing_id));
            data_item.Add(st.create_array("w_name", wing.W_Name));
            //status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);
            status1 = st.run_query(data_item, "Select", "sp_wing_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    wing.Sql_Result = "Already exist";
                else
                    wing.Sql_Result = "";
            return wing;

        }
  
    }
}