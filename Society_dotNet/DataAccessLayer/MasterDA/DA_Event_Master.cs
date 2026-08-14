using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.MasterDA
{
    public class DA_Event_Master
    {
        stored st = new stored();
        public DataTable getEventDetails(Event evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", evt.Sql_Operation));
            data_item.Add(st.create_array("society_id",evt.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_event_master", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public DataTable updateEventDetails(Event evt)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            int dr = 0;
            DataTable dt = new DataTable();
            string status1;
            data_item.Add(st.create_array("operation", evt.Sql_Operation));
            data_item.Add(st.create_array("event_id", evt.Event_Id));
            if (evt.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", evt.Society_Id));
                data_item.Add(st.create_array("event_name", evt.Event_Name));
                data_item.Add(st.create_array("from_date", evt.From_Date));
                data_item.Add(st.create_array("to_date", evt.To_Date));
                data_item.Add(st.create_array("description", evt.Description));



            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_event_master", ref dr);
            if (status1 == "Done")
                if (dr != 0)
                    evt.Event_Id = dr;
            data_item.Clear();
            data_item.Add(st.create_array("society_id", evt.Society_Id));
            data_item.Add(st.create_array("operation", "get_users"));
            data_item.Add(st.create_array("recipients_id", 3));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Event Send_Notification(Event evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", "Update"));
            data_item.Add(st.create_array("user_id", evt.User_Id));
            data_item.Add(st.create_array("society_id", evt.Society_Id));
            data_item.Add(st.create_array("user_type", evt.UserType));
            data_item.Add(st.create_array("notification_id", evt.Notification_Id));
            data_item.Add(st.create_array("notification_type", evt.Notification_Type));
            data_item.Add(st.create_array("title", "New Event"));
            data_item.Add(st.create_array("body", evt.Body));
            data_item.Add(st.create_array("seen_status", 0));

            status1 = st.run_query(data_item, "Select", "sp_notification", ref sdr);
            if (status1 == "Done")
            {
                evt.Sql_Result = status1;
            }
            return evt;
        }
        public Event getevent(Event evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", evt.Sql_Operation));
           
            data_item.Add(st.create_array("event_id", evt.Event_Id));

            status1 = st.run_query(data_item, "Select", "sp_event_master", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {
                    evt.Society_Id = sdr["society_id"].ToString();
                    evt.Event_Name = sdr["event_name"].ToString();
                    evt.From_Date = Convert.ToDateTime(sdr["from_date"].ToString());
                    evt.To_Date = Convert.ToDateTime(sdr["to_date"].ToString());
                    evt.Description = sdr["description"].ToString();


                }
            }
            return evt;
        }

        //public Event Event_Name_TextChanged(Event evt)
        //{
        //    ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
        //    SqlDataReader sdr = null;
        //    string status = "";
        //    data_item.Add(st.create_array("operation", evt.Sql_Operation));
        //    data_item.Add(st.create_array("event_id", evt.Event_Id));
        //    data_item.Add(st.create_array("event_name", evt.Event_Name));

        //    status = st.run_query(data_item, "Select", "sp_event_master", ref sdr);

        //    if (status == "Done")
        //        if (sdr.Read())
        //            evt.Sql_Result = "Already exist";
        //        else
        //            evt.Sql_Result = "";
        //    return evt;
        //}

        public DataTable search_event(Event evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
           
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", evt.Sql_Operation));
            data_item.Add(st.create_array("search", evt.Event_Name));
            data_item.Add(st.create_array("society_id", evt.Society_Id));


            status1 = st.run_query(data_item, "Select", "sp_event_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
           
            return dt;
        }

        public Event delete_event(Event evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", evt.Sql_Operation));
            data_item.Add(st.create_array("event_id", evt.Event_Id));

            status = st.run_query(data_item, "Delete", "sp_event_master", ref sdr);
            if (status == "Done")
            {
                evt.Sql_Result = status;
            }
            return evt;
        }
    }
}