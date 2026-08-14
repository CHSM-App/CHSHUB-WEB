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
    public class DA_Ledger
    {
        stored st = new stored();
        public DataTable Get_Ledger(Ledger GetLedger)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", GetLedger.Sql_Operation));
            data_item.Add(st.create_array("society_id", GetLedger.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_ledger", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Get_Print_Ledger(Ledger getLedger)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", getLedger.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable ledger_search(Ledger GetLedger)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation",   GetLedger.Sql_Operation));
            data_item.Add(st.create_array("search",   GetLedger.Search));
            data_item.Add(st.create_array("society_id", GetLedger.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_ledger", ref sdr);

            if (status1 == "Done")
                dt.Load(sdr);
            return dt;
        }

        public Ledger updateLedgerDetails(Ledger GetLedger)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation",GetLedger.Sql_Operation));
            data_item.Add(st.create_array("led_id", GetLedger.led_id));
            if (GetLedger.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", GetLedger.Society_Id));
                data_item.Add(st.create_array("led_description", GetLedger.Led_Description));
                data_item.Add(st.create_array("led_status",GetLedger.Led_Status));
               
            }
            status1 = st.run_query(data_item, "Select", "sp_ledger", ref sdr);
            GetLedger.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (GetLedger.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //evt.Event_Id = Convert.ToInt32(sdr["event_id"].ToString());
                        GetLedger.Society_Id = sdr["society_id"].ToString();
                        GetLedger.Led_Description = sdr["led_description"].ToString();
                        GetLedger.Led_Status = sdr["led_status"].ToString();
                       
                    }
                }
                else
                {
                    GetLedger.Sql_Result = status1;
                }

            }
            return GetLedger;







            //ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            //string status1 = "";
            //data_item.Add(st.create_array("operation", operation));
            //data_item.Add(st.create_array("led_id", led_id.Value == null ? (object)DBNull.Value : led_id.Value));

            //if (operation == "Update")
            //{
            //    data_item.Add(st.create_array("society_id", society_id.Value == null ? (object)DBNull.Value : society_id.Value));

            //    data_item.Add(st.create_array("led_description", string.IsNullOrWhiteSpace(txt_des.Text) ? (object)DBNull.Value : txt_des.Text));
            //    if (radiobtn1.Checked == true)
            //        data_item.Add(st.create_array("led_status", string.IsNullOrWhiteSpace("Active") ? (object)DBNull.Value : "Active"));
            //    if (radiobtn2.Checked == true)
            //        data_item.Add(st.create_array("led_status", string.IsNullOrWhiteSpace("Inactive") ? (object)DBNull.Value : "Inactive"));



            //}
            //status1 = st.run_query(data_item, operation, "sp_ledger", ref sdr);
            //if (status1 == "Done")
            //{
            //    if (operation == "Select")
            //    {
            //        while (sdr.Read())
            //        {
            //            txt_des.Text = sdr["led_description"].ToString();

            //            string led_status = sdr["led_status"].ToString();
            //            if (led_status == "Active")
            //                radiobtn1.Checked = true;
            //            else
            //                radiobtn2.Checked = true;

            //        }
            //    }
            //}
            //return status1;

        }

        public Ledger delete_ledger(Ledger GetLedger)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", GetLedger.Sql_Operation));
            data_item.Add(st.create_array("led_id", GetLedger.led_id));

            status = st.run_query(data_item, "Delete", "sp_ledger", ref sdr);
            if (status == "Done")
            {
                GetLedger.Sql_Result = status;
            }
            return GetLedger;
        }
    }
}