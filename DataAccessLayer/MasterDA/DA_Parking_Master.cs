using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.MasterDA
{
    public class DA_Parking_Master
    {
        stored st = new stored();
        public DataTable getParkingDetails(Parking_1 parking)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", parking.Sql_Operation));
            data_item.Add(st.create_array("society_id", parking.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_parking", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public Parking_1 updateParkingDetails(Parking_1 parking)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>(); 
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", parking.Sql_Operation));
            data_item.Add(st.create_array("place_id", parking.place_id));
            if (parking.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", parking.Society_Id));
                data_item.Add(st.create_array("parking_no", parking.Parking_No));
                data_item.Add(st.create_array("park_for", parking.Park_For));

            }
            status1 = st.run_query(data_item, "Select", "sp_parking", ref sdr);

            if (status1 == "Done")
            {
                if (parking.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        parking.Society_Id = sdr["society_id"].ToString();
                        parking.Parking_No = sdr["parking_no"].ToString();
                        parking.Park_For = sdr["park_for"].ToString();
                    }
                }
                else
                {
                    parking.Sql_Result = status1;
                }

            }
            return parking;



        }

        public DataTable park_place_search(Parking_1 parking)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", parking.Sql_Operation));
            data_item.Add(st.create_array("search", parking.Name));
            data_item.Add(st.create_array("society_id", parking.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_parking", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Parking_1 delete_parking(Parking_1 parking)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", parking.Sql_Operation));
            data_item.Add(st.create_array("place_id", parking.place_id));

            status = st.run_query(data_item, "Delete", "sp_parking", ref sdr);
            if (status == "Done")
            {
                parking.Sql_Result = status;
            }
            return parking;

            }
        public Parking_1 Number_TextChanged(Parking_1 parking)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", parking.Sql_Operation));
            data_item.Add(st.create_array("society_id", parking.Society_Id));
            data_item.Add(st.create_array("parking_no", parking.Parking_No));
            data_item.Add(st.create_array("park_for", parking.Park_For));
            status1 = st.run_query(data_item, "Select", "sp_parking", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    parking.Sql_Result = "Already exist";
                else
                    parking.Sql_Result = "";
            return parking;

        }


      

    }
}