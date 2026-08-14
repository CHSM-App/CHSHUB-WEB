using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace DataAccessLayer.DA
{
    public class DA_Facility
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getparty(facility party)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", party.Sql_Operation));
            data_item.Add(st.create_array("society_id", party.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable GetFacility(facility getFacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", getFacility.Sql_Operation));
            data_item.Add(st.create_array("society_id", getFacility.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_facility", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Get_Slot(facility getFacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", getFacility.Sql_Operation));
            data_item.Add(st.create_array("facility_id", getFacility.facility_id));
            if (getFacility.From_Date != DateTime.MinValue)
                data_item.Add(st.create_array("from_date", getFacility.From_Date));
            data_item.Add(st.create_array("society_id", getFacility.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_facility", ref sdr);

            if (status1 == "Done")
                if(sdr.HasRows)
                dt.Load(sdr);
            return dt;
        }

        public DataTable Fill_list(string operation, string society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            
            data_item.Add(st.create_array("society_id", society));

            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public facility Delete_Slot(facility getFacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", getFacility.Sql_Operation));
            data_item.Add(st.create_array("slot_id", getFacility.Slot_Id));

            status = st.run_query(data_item, "Delete", "sp_facility", ref sdr);
            if (status == "Done")
            {
                getFacility.Sql_Result = status;
            }
            return getFacility;
        }

        public facility Runproc_Save(facility getFacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            //int sdr = 0;
            string status = "";
            data_item.Add(st.create_array("operation", getFacility.Sql_Operation));
            data_item.Add(st.create_array("slot_id", getFacility.Slot_Id));

            data_item.Add(st.create_array("facility_id", getFacility.facility_id));
            data_item.Add(st.create_array("society_id", getFacility.Society_Id));
           
            data_item.Add(st.create_array("start_time", getFacility.Start_Time));
            data_item.Add(st.create_array("end_time", getFacility.To_Time));


            status = st.run_query(data_item, "Select", "sp_facility", ref sdr);
            if (status == "Done")
                
            {
                getFacility.Sql_Result = status;
            }
            return getFacility;
        }

        public facility Delete_Facility(facility getFacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", getFacility.Sql_Operation));
            data_item.Add(st.create_array("facility_id", getFacility.facility_id));

            status = st.run_query(data_item, "Delete", "sp_facility", ref sdr);
            if (status == "Done")
            {
                getFacility.Sql_Result = status;
            }
            return getFacility;
        }

        public DataTable Search_Facility(facility getfacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", getfacility.Sql_Operation));
            data_item.Add(st.create_array("search", getfacility.Name));
            data_item.Add(st.create_array("society_id", getfacility.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_facility", ref sdr);

            if (status1 == "Done")
                dt.Load(sdr);
            return dt;
        }
         
        public facility Update_Facility(facility getfacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            int sdr = 0;
            string status1 = "";
            data_item.Add(st.create_array("operation", getfacility.Sql_Operation));
            data_item.Add(st.create_array("facility_id", getfacility.facility_id));
            if (getfacility.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", getfacility.Society_Id));
               
                data_item.Add(st.create_array("description", getfacility.Description));
                data_item.Add(st.create_array("cost", getfacility.Cost));
                data_item.Add(st.create_array("name", getfacility.Name));
                data_item.Add(st.create_array("slot", getfacility.Slot));
                data_item.Add(st.create_array("capacity", getfacility.Max_capacity));
                data_item.Add(st.create_array("isActive", getfacility.IsActive));

            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_facility", ref sdr);
            getfacility.Sql_Result = status1;
            if (sdr != 0)
                getfacility.facility_id = sdr;
           
            return getfacility; 
        }

        public facility select_facility(facility getfacility)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", getfacility.Sql_Operation));
            data_item.Add(st.create_array("facility_id", getfacility.facility_id));
            status1 = st.run_query(data_item, "Select", "sp_facility", ref sdr);
            if (status1 == "Done")
            {
               if(sdr.Read())
                {
                    getfacility.Society_Id = sdr["society_id"].ToString();
                    getfacility.Max_capacity = Convert.ToInt32(sdr["capacity"]);
                    getfacility.Description = sdr["description"].ToString();
                    getfacility.Cost = Convert.ToDecimal(sdr["cost"].ToString());
                    getfacility.Name = sdr["name"].ToString();
                    getfacility.Slot = Convert.ToInt32(sdr["slot"].ToString());
                }
            }
            
            return getfacility;
        }

        public DataTable party_search(facility party)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", party.Sql_Operation));
            data_item.Add(st.create_array("search", party.Name));
            data_item.Add(st.create_array("society_id", party.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public facility getflatno(facility party)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", party.Sql_Operation));
            data_item.Add(st.create_array("owner_id", party.owner_id));

            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
                while (sdr.Read())
                {
                   party.Flat_No = Convert.ToInt32(sdr["flat_no"].ToString());
                    party.Flat_id = Convert.ToInt32(sdr["flat_id"].ToString());

                }
            return party;
        }

        public facility getcharges(facility party)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", party.Sql_Operation));
            data_item.Add(st.create_array("facility_id", party.facility_id));

            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
                while (sdr.Read())
                {
                    party.Cost = Convert.ToDecimal(sdr["cost"].ToString());
                    party.Slot = Convert.ToInt32(sdr["slot"].ToString());
                }
            return party;
        }

        public facility updateparty(facility party)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", party.Sql_Operation));
            data_item.Add(st.create_array("facility_book_id", party.facility_book_id));
            if (party.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", party.Society_Id));
                data_item.Add(st.create_array("note", party.Note));
                data_item.Add(st.create_array("from_date", party.From_Date));
                if (party.To_Date != DateTime.MinValue)
                    data_item.Add(st.create_array("to_date", party.To_Date));
                //if (society_in.Checked == true)
                data_item.Add(st.create_array("name", party.Name));
                //else
                //    data_item.Add(st.create_array("name", party.Name));
                data_item.Add(st.create_array("facility_id", party.facility_id));
                data_item.Add(st.create_array("flat_no", party.Flat_No));
                data_item.Add(st.create_array("address", party.Address));
                data_item.Add(st.create_array("contact", party.Contact));
                data_item.Add(st.create_array("from_time", party.From_Time));
                data_item.Add(st.create_array("to_time", party.To_Time));
                data_item.Add(st.create_array("society_in", party.Society_In));
                data_item.Add(st.create_array("amount", party.Cost));
            }
            status1 = st.run_query(data_item, "Select", "sp_facility_booking", ref sdr);

            if (status1 == "Done")
            {
                if (party.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  facility_id.Value = sdr["facility_id"].ToString();
                        party.Society_Id = sdr["society_id"].ToString();
                        party.Note =sdr["note"].ToString();
                        party.From_Date = Convert.ToDateTime(sdr["from_date"].ToString());
                        if(sdr["to_date"].ToString()!="")
                        party.To_Date = Convert.ToDateTime(sdr["to_date"].ToString());
                        party.Name = sdr["name"].ToString();
                        party.Flat_No = Convert.ToInt32(sdr["flat_no"].ToString());
                        party.Address = sdr["address"].ToString();
                        party.Contact = sdr["contact"].ToString();
                        party.From_Time = Convert.ToDateTime(sdr["from_time"].ToString());
                        party.To_Time = Convert.ToDateTime(sdr["to_time"].ToString());
                        party.Society_In = Convert.ToInt32(sdr["society_in"].ToString());
                        party.facility_id = Convert.ToInt32(sdr["facility_id"].ToString());
                        party.Cost = Convert.ToDecimal(sdr["amount"].ToString());
                    }
                }
                else
                {
                    party.Sql_Result = status1;
                }
            }
            return party;

        }

        public facility delete(facility party)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", party.Sql_Operation));
            data_item.Add(st.create_array("facility_book_id", party.facility_book_id));

            status = st.run_query(data_item, "Delete", "sp_facility_booking", ref sdr);
            if (status == "Done")
            {
                party.Sql_Result = status;
            }
            return party;


        }

    }
}