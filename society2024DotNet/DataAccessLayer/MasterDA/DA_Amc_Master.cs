using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Services.Description;

namespace DataAccessLayer.MasterDA
{
    public class DA_Amc_Master
    {
        stored st = new stored();



        public DataTable geAmcDetails(int amc_id, string society_id)
        {
            DataTable ds = new DataTable();
            return ds;
        }

        public DataTable GetAmcDetails(Amc agm)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Action", agm.Sql_Operation));
            data_item.Add(st.create_array("SocietyID", agm.SocietyId));
            data_item.Add(st.create_array("start_date", agm.StartDate));
            data_item.Add(st.create_array("end_date", agm.EndDate));

            status1 = st.run_query(data_item, "Select", "sp_MaintenanceReceipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public void updateAmcDetails(DataTable amcmaster)
        {

        }

        //------------------------Audit Page methods-----------------------

        public Amc audit_que(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("Operation", audit.Sql_Operation));
            data_item.Add(st.create_array("society_id", audit.SocietyId));
            data_item.Add(st.create_array("question_desc", audit.AuditQue));
            data_item.Add(st.create_array("answer_desc", audit.AuditAns));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            if (status1 == "Done")
                audit.Sql_Result = status1;

            return audit;
        }

        public DataTable fetchSocietyData(string operation, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("society_id", society_id)); 

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public int InsertAuditMainPoint(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;
            string status1 = "";
            data_item.Add(st.create_array("operation", audit.Sql_Operation));
            data_item.Add(st.create_array("audit_header_id", audit.M_Point_Id));
            data_item.Add(st.create_array("audt_header_desc", audit.MainPoint));
            data_item.Add(st.create_array("status_id", audit.Status));
            data_item.Add(st.create_array("society_id", audit.SocietyId));

            status1 = st.run_query_scalar(data_item, "Select", "sp_auditor_question_master", ref sdr);

            return sdr;
        }

        public void InsertAuditSubPoint(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("Operation", audit.Sql_Operation));
            data_item.Add(st.create_array("society_id", audit.SocietyId));
            data_item.Add(st.create_array("question_desc", audit.AuditQue));
            data_item.Add(st.create_array("answer_desc", audit.AuditAns));
            data_item.Add(st.create_array("audt_ques_id", audit.Audt_Ques_Id));
            data_item.Add(st.create_array("status_id", audit.Status));
            data_item.Add(st.create_array("audit_header_id", audit.M_Point_Id));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

        }

        public DataTable getHeaders(string society_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", operation));
            data_item.Add(st.create_array("society_id", society_id));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable getQuestions(string society_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", operation));
            data_item.Add(st.create_array("society_id", society_id));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable bindIncome(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", audit.Sql_Operation));
            data_item.Add(st.create_array("society_id", audit.SocietyId));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public DataTable latePayment(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", audit.Sql_Operation));
            data_item.Add(st.create_array("society_id", audit.SocietyId));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public string updateSeq(Amc audit)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", audit.Sql_Operation));
            data_item.Add(st.create_array("sequence", audit.Sequence));
            data_item.Add(st.create_array("audit_header_id", audit.Amc_Id));

            status1 = st.run_query(data_item, "Select", "sp_auditor_question_master", ref sdr);

            return status1;
        }
    }
}