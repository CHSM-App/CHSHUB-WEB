using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Sockets;
using System.Web;

namespace DataAccessLayer.DA
{
    public class DA_Other_credits
    {
        stored st = new stored();

        public maintenance add_other_credits(maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));
            data_item.Add(st.create_array("Description", maintenance.Description));
            data_item.Add(st.create_array("Amount", maintenance.Amount));
            data_item.Add(st.create_array("payment_date", maintenance.Date));
            data_item.Add(st.create_array("id", maintenance.Bill_No));

            status1 = st.run_query(data_item, "Select", "sp_ManageOtherCredits", ref sdr);

            if (status1 == "Done")
            {     
                    while (sdr.Read())
                    {
                        maintenance.Sql_Result = sdr["Status"].ToString();
                        //maintenance. = sdr["Status"].ToString();
                    }
            }
             return maintenance;
        }

        public DataTable Get_other_credits(maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_ManageOtherCredits", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public maintenance Get_other_credits_by_Id(maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));
            data_item.Add(st.create_array("id", maintenance.Bill_No));

            status1 = st.run_query(data_item, "Select", "sp_ManageOtherCredits", ref sdr);

            if (status1 == "Done")
            {
                while (sdr.Read())
                {
                    maintenance.Amount = sdr["Amount"].ToString();
                    maintenance.Description = sdr["Description"].ToString();
                    maintenance.Date = Convert.ToDateTime(sdr["PaymentDate"]);
                    maintenance.Bill_No = Convert.ToInt32(sdr["id"]);

                }
            }
            return maintenance;
        }
    }
}