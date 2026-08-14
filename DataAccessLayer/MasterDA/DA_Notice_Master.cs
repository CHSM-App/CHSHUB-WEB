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
    public class DA_Notice_Master
    {
        stored st = new stored();
        public DataTable getNotice(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", notice.Sql_Operation));
            data_item.Add(st.create_array("notice_id", notice.notice_id));
            data_item.Add(st.create_array("society_id", notice.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_notice_master", ref sdr);

            if (status1 == "Done")
                if(sdr.HasRows)
                dt.Load(sdr);
            return dt;

        }

        public DataTable notice_search(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", notice.Sql_Operation));
            data_item.Add(st.create_array("Search", notice.Name));
            data_item.Add(st.create_array("society_id", notice.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_notice_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Notice Send_Notification(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation","Update"));
            data_item.Add(st.create_array("user_id", notice.User_Id));
            data_item.Add(st.create_array("society_id", notice.Society_Id));
            data_item.Add(st.create_array("user_type", notice.UserType));
            data_item.Add(st.create_array("notification_id", notice.Notification_id));
            data_item.Add(st.create_array("notification_type", notice.Notification_Type));
            data_item.Add(st.create_array("title", "New Announcement"));
            data_item.Add(st.create_array("body", notice.Body));
            data_item.Add(st.create_array("seen_status",0));

            status1 = st.run_query(data_item, "Select", "sp_notification", ref sdr);
            if (status1== "Done")
            {
                notice.Sql_Result = status1;
            }
            return notice;
        }

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down,sqlstring,text,value);
        }

        public DataTable List_Fill(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", notice.Sql_Operation));

            data_item.Add(st.create_array("society_id", notice.Society_Id));
            status = st.run_query(data_item, "Select", "sp_notice_master", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    if (sdr.HasRows == true)
                    {

                        dt.Load(sdr);


                    }
                }

            }

            return dt;
        }

        public Notice getnoticedetails(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", notice.Sql_Operation));
            data_item.Add(st.create_array("notice_id", notice.notice_id));
          
            status1 = st.run_query(data_item, "Select", "sp_notice_master", ref sdr);

            if (status1 == "Done")
            {
                if (notice.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        notice.Society_Id = sdr["society_id"].ToString();
                        notice.Name = sdr["name"].ToString();
                        notice.Recipients_id = Convert.ToInt32(sdr["recipients_id"].ToString());
                        notice.Description = sdr["description"].ToString();
                        notice.Valid_To = Convert.ToDateTime(sdr["valid_to"].ToString());

                    }
                }
                else
                {
                    notice.Sql_Result = status1;
                }
            }
            return notice;

        }
        public Notice Delete_Notice(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", notice.Sql_Operation));
            data_item.Add(st.create_array("notice_id", notice.notice_id));

            status = st.run_query(data_item, "Delete", "sp_notice_master", ref sdr);
            if (status == "Done")
            {
                notice.Sql_Result = status;
            }
            return notice;
        }

        public DataTable Notice_Save(Notice notice)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader dr = null;
            int sdr = 0;
            DataTable dt = new DataTable();
            string status1;
            //string type = "Owner";
            data_item.Add(st.create_array("operation", notice.Sql_Operation));
            data_item.Add(st.create_array("notice_id", notice.notice_id));

            if (notice.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", notice.Society_Id));
                data_item.Add(st.create_array("name", notice.Name));
                data_item.Add(st.create_array("recipients_id", notice.Recipients_id));
                data_item.Add(st.create_array("description", notice.Description));
                data_item.Add(st.create_array("valid_to", notice.Valid_To));

            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_notice_master", ref sdr);
            if (status1 == "Done")
                if (sdr != 0)
                    notice.notice_id = sdr;
            data_item.Clear();
            data_item.Add(st.create_array("society_id", notice.Society_Id));
            data_item.Add(st.create_array("operation", "get_users"));
            data_item.Add(st.create_array("recipients_id", notice.Recipients_id));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref dr);

            if (status1 == "Done")
                if(dr.HasRows)
                dt.Load(dr);


            return dt;
        }
     
    }
}
