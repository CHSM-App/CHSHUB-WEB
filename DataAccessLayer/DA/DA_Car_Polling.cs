using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.DA
{
    public class DA_Car_Polling
    {
        stored st = new stored();
        public DataTable Get_Car_Polling(carpolling car)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", car.Sql_Operation));
            data_item.Add(st.create_array("society_id", car.Society_Id));


            status1 = st.run_query(data_item, "Select", "sp_car_polling", ref sdr);

            if (status1 == "Done")
                if(sdr.HasRows)
                dt.Load(sdr);
            return dt;
        }

        public DataTable search_car(carpolling car)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
           
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", car.Sql_Operation));
            data_item.Add(st.create_array("search", car.C_Name));
            data_item.Add(st.create_array("society_id", car.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_car_polling", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);

            return dt;
        }

        public carpolling Update_Car_Polling(carpolling car)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", car.Sql_Operation));
            data_item.Add(st.create_array("car_id", car.Car_Id));
            if (car.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", car.Society_Id));
                data_item.Add(st.create_array("c_name", car.C_Name));
                data_item.Add(st.create_array("vehical_no", car.Vehical_No));
                data_item.Add(st.create_array("seat", car.Seat));
                data_item.Add(st.create_array("time", car.Time));
                data_item.Add(st.create_array("date", car.Date));
                data_item.Add(st.create_array("destination", car.Destination));
                data_item.Add(st.create_array("charges", car.Charges));
            }
            status1 = st.run_query(data_item, "Select", "sp_car_polling", ref sdr);

            car.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (car.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  facility_id.Value = sdr["facility_id"].ToString();
                        car.Society_Id = sdr["society_id"].ToString();
                        car.C_Name = sdr["c_name"].ToString();
                        car.Vehical_No = sdr["vehical_no"].ToString();
                        car.Seat = sdr["seat"].ToString();
                        car.Time = Convert.ToDateTime(sdr["time"].ToString());
                        car.Date = Convert.ToDateTime(sdr["date"].ToString());
                        car.Destination = sdr["destination"].ToString();
                        car.Charges = sdr["charges"].ToString();
                    
                    }
                }
                
            }
            else
            {
                car.Sql_Result = status1;
            }
            return car;

        }
        public carpolling delete(carpolling car)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", car.Sql_Operation));
            data_item.Add(st.create_array("car_id", car.Car_Id));

            status = st.run_query(data_item, "Delete", "sp_car_polling", ref sdr);
            if (status == "Done")
            {
                car.Sql_Result = status;
            }
            return car;


        }
        public carpolling vehical_no_changed(carpolling car)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", car.Sql_Operation));
            data_item.Add(st.create_array("car_id", car.Car_Id));
            data_item.Add(st.create_array("vehical_no ",car.Vehical_No));
            data_item.Add(st.create_array("society_id", car.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_car_polling", ref sdr);
            if (status1 == "Done")
                if (sdr.Read())
                    car.Sql_Result = "Already exist";
                else
                    car.Sql_Result = "";

            return car;

        }

    }
}