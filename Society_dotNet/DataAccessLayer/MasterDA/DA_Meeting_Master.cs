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
    public class DA_Meeting_Master
    {
        stored st = new stored();
        public DataTable get_meeting_details(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("society_id", meeting.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public DataTable mom_gridbind(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            //data_item.Add(st.create_array("meet_id", meeting.meet_id));
            data_item.Add(st.create_array("meet_ex_id", meeting.Meet_Ex_Id));
            data_item.Add(st.create_array("society_id", meeting.Society_Id));
            //data_item.Add(st.create_array("details", meeting.Details));
          

            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                 dt.Load(sdr);
            return dt;
        }

        public Meeting get_meeting(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("meet_id", meeting.meet_id));

            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {
                    meeting.Society_Id = sdr["society_id"].ToString();
                    meeting.Meeting_Date = Convert.ToDateTime(sdr["meeting_date"].ToString());
                    meeting.Meeting_Time= Convert.ToDateTime(sdr["meeting_time"].ToString());
                    meeting.Subject = sdr["subject"].ToString();
                    meeting.Details = sdr["details"].ToString();


                }
            }
            return meeting;
        }

        public object search_meeting(Meeting meeting)
        {
             ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("search", meeting.Title));
            data_item.Add(st.create_array("society_id", meeting.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
                return dt;
        }

        public DataTable updateMeetingDetails(Meeting meeting)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            int dr = 0;
            DataTable dt = new DataTable();
            string status1 = "";
            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("meet_id", meeting.meet_id));
            data_item.Add(st.create_array("meet_ex_id", meeting.Meet_Ex_Id));
            if (meeting.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", meeting.Society_Id));
                data_item.Add(st.create_array("meeting_date", meeting.Meeting_Date));
                data_item.Add(st.create_array("meeting_time", meeting.Meeting_Time));
                data_item.Add(st.create_array("subject", meeting.Subject));
                data_item.Add(st.create_array("details", meeting.Details));

            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_meeting_master", ref dr);
            if (status1 == "Done")
                if (dr != 0)
                    meeting.meet_id = dr;
            data_item.Clear();
            data_item.Add(st.create_array("society_id", meeting.Society_Id));
            data_item.Add(st.create_array("operation", "get_users"));
            data_item.Add(st.create_array("recipients_id", 3));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Meeting Send_Notification(Meeting evt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", "Update"));
            data_item.Add(st.create_array("user_id", evt.User_Id));
            data_item.Add(st.create_array("society_id", evt.Society_Id));
            data_item.Add(st.create_array("user_type", evt.User_Type));
            data_item.Add(st.create_array("notification_id", evt.Notification_Id));
            data_item.Add(st.create_array("notification_type", evt.Notification_Type));
            data_item.Add(st.create_array("title", "New Meeting"));
            data_item.Add(st.create_array("body", evt.Body));
            data_item.Add(st.create_array("seen_status", 0));

            status1 = st.run_query(data_item, "Select", "sp_notification", ref sdr);
            if (status1 == "Done")
            {
                evt.Sql_Result = status1;
            }
            return evt;
        }


        public Meeting delete_meeting(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("meet_id", meeting.meet_id));

            status = st.run_query(data_item, "Delete", "sp_meeting_master", ref sdr);
            if (status == "Done")
            {
                meeting.Sql_Result = status;
            }
            return meeting;
        }

        public Meeting Date_Changed(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", meeting.Sql_Operation));
            data_item.Add(st.create_array("meet_id", meeting.meet_id));
            data_item.Add(st.create_array("meeting_date", meeting.Meeting_Time));
            status1 = st.run_query(data_item, "Select", "sp_meeting_master", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.Read())
                {
                    meeting.Sql_Result = ("Already exist");
                }
                else
                    meeting.Sql_Result = "";
               

            }
            return meeting;
        }
    }
}