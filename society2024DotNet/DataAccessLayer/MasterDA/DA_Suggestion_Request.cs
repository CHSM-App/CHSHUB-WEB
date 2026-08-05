using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace DataAccessLayer.MasterDA
{
    public class DA_Suggestion_Request
    {
        stored st = new stored();
        public DataTable Get_Suggestion(Request request)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", request.Sql_Operation));
            data_item.Add(st.create_array("sug_id", request.sug_id));
            data_item.Add(st.create_array("society_id", request.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_suggestion_request_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Request Suggestion_delete(Request request)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", request.Sql_Operation));
            data_item.Add(st.create_array("sug_id", request.sug_id));

            status = st.run_query(data_item, "Delete", "sp_suggestion_request_master", ref sdr);
            if (status == "Done")
            {
                request.Sql_Result = status;
            }
            return request;
        }

        public DataTable Suggestion_Search(Request request)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", request.Sql_Operation));
            data_item.Add(st.create_array("search", request.Search));
            data_item.Add(st.create_array("society_id", request.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_suggestion_request_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Request Update_Suggestion(Request request)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", request.Sql_Operation));
            data_item.Add(st.create_array("sug_id", request.sug_id));
            data_item.Add(st.create_array("society_id", request.Society_Id));

            if (request.Sql_Operation == "Update")
            {
              
                data_item.Add(st.create_array("details", request.Details));
                data_item.Add(st.create_array("subject", request.Subject));

            }
            status1 = st.run_query(data_item, "Select", "sp_suggestion_request_master", ref sdr);

            if (status1 == "Done")
            {
                if (request.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        
                        request.Details = sdr["details"].ToString();
                        request.Subject = sdr["subject"].ToString();
                    }
                }
                else
                {
                    request.Sql_Result = status1;
                }
            }
            return request;
        }
    }
}