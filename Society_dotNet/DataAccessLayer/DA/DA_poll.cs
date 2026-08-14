using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Security;

namespace DataAccessLayer.DA
{
    public class DA_poll
    {
        stored st = new stored();

        public Polls add_polls(Polls polls) 

        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;

            string status1;

            data_item.Add(st.create_array("Mode", polls.sql_operation));
            data_item.Add(st.create_array("user_id", polls.UserId));
            data_item.Add(st.create_array("Topic", polls.Topic));
            data_item.Add(st.create_array("Description", polls.Desc));
            data_item.Add(st.create_array("ExpiryDate", polls.ExpireDate));
            data_item.Add(st.create_array("AllowMultipleVotes", polls.AllowMultiple));
            data_item.Add(st.create_array("OneVotePerUnit", polls.VotePerUnit));
            data_item.Add(st.create_array("Audience", polls.Audience));
            data_item.Add(st.create_array("society_id", polls.society_id));

            status1 = st.run_query_scalar(data_item, "Select", "sp_polls", ref sdr);

            if (status1 == "Done")
                if (sdr != 0)
                    polls.Poll_id = sdr;


            return polls;

        }

        public Polls addOptions(Polls polls)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;
            string status1;
            data_item.Add(st.create_array("Operation", "INSERT"));
            data_item.Add(st.create_array("PollId", polls.Poll_id));
            data_item.Add(st.create_array("Options", polls.Option));
            status1 = st.run_query_scalar(data_item, "Select", "sp_PollOptions", ref sdr);
            if (status1 == "Done")
                if (sdr != 0)
                {
                    polls.sql_result = "Options Added Successfully";
                    polls.Poll_id = sdr;
                }
                else
                    polls.sql_result = "";
            return polls;
        }

        public DataTable getPolls(Polls polls)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("mode", polls.sql_operation));
            data_item.Add(st.create_array("society_id", polls.society_id));
            data_item.Add(st.create_array("user_id", polls.UserId));
            data_item.Add(st.create_array("user_type", polls.user_type));

            status1 = st.run_query(data_item, "Select", "sp_polls", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public void vote(Polls poll)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", "INSERT"));
            data_item.Add(st.create_array("Society_id", poll.society_id));
            data_item.Add(st.create_array("user_id", poll.UserId));
            data_item.Add(st.create_array("Poll_id", poll.Poll_id));
            data_item.Add(st.create_array("Option_id", poll.OptionId));
            data_item.Add(st.create_array("User_type", poll.user_type));
            data_item.Add(st.create_array("AllowMultipleVotes", poll.AllowMultiple));
            data_item.Add(st.create_array("OneVotePerUnit", poll.VotePerUnit));

            status1 = st.run_query(data_item, "Select", "sp_PollVoting", ref sdr);

            //if (status1 == "Done")
            //    if (sdr.HasRows)
            //        dt.Load(sdr);
        }


        public void deletePoll(Polls poll)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("Mode", poll.sql_operation));
            data_item.Add(st.create_array("Society_id", poll.society_id));
            data_item.Add(st.create_array("user_id", poll.UserId));
            data_item.Add(st.create_array("PollId", poll.Poll_id));

            status1 = st.run_query(data_item, "Select", "sp_polls", ref sdr);


        }

        public DataTable getVotedNames(Polls poll)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", poll.sql_operation));
            data_item.Add(st.create_array("society_id", poll.society_id));
            data_item.Add(st.create_array("Poll_id", poll.Poll_id));

            status1 = st.run_query(data_item, "Select", "sp_PollVoting", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public DataTable getTokens(int recipients_id, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("society_id", society_id));
            data_item.Add(st.create_array("operation", "get_users"));
            data_item.Add(st.create_array("recipients_id", recipients_id));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
    }
    }