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
    public class DA_Meeting_Details
    {
        stored st = new stored();
        public Meeting delete(Meeting meeting)
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

        public object Search_Meeting_Details(Meeting meeting)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", meeting.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
    }
}