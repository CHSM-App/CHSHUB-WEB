using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI.WebControls;

namespace DataAccessLayer.MasterDA
{
    public class DA_House_Tax
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable Get_House_Tax(House_Tax getHouse)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", getHouse.Sql_Operation));
            data_item.Add(st.create_array("village_id", getHouse.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_house_tax", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public House_Tax Fetch_House_No(House_Tax getHouse)
        {
            string status = "", str = "";
            int val = 0;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", getHouse.Sql_Operation));
            data_item.Add(st.create_array("village_id", getHouse.Village_Id));
            status = st.run_query(data_item, "Select", "sp_house_tax", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    str = sdr["house_no"].ToString();
                    val = int.Parse(Regex.Match(str, @"\d+").ToString()) + 1;
                    getHouse.House_No = Convert.ToInt32(str.Replace((val - 1).ToString(), (val).ToString()));
                }
                else
                {
                    getHouse.House_No = 001;
                }
            }
            return getHouse;
        }

        public House_Tax Update_House_Tax(House_Tax getHouse)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", getHouse.Sql_Operation));
            data_item.Add(st.create_array("house_tax_id", getHouse.House_Tax_Id));
            if (getHouse.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("village_id", getHouse.Village_Id));
                data_item.Add(st.create_array("house_no", getHouse.House_No));
                data_item.Add(st.create_array("house_type", getHouse.House_Type));
                data_item.Add(st.create_array("from_date", getHouse.From_Date));
                data_item.Add(st.create_array("to_date", getHouse.To_Date));
                data_item.Add(st.create_array("house_tax_amount", getHouse.House_Tax_Amount));

            }

            status1 = st.run_query(data_item, "Select", "sp_house_tax", ref sdr);

            if (status1 == "Done")
            {
                if (getHouse.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        getHouse.Village_Id = sdr["village_id"].ToString();
                        getHouse.House_No = Convert.ToInt32(sdr["house_no"].ToString());
                        getHouse.House_Type = Convert.ToInt32(sdr["house_type"].ToString());
                        getHouse.From_Date = Convert.ToDateTime(sdr["from_date"].ToString());
                        getHouse.To_Date = Convert.ToDateTime(sdr["to_date"].ToString());
                        getHouse.House_Tax_Amount = Convert.ToDecimal(sdr["house_tax_amount"].ToString());

                    }
                }

                else
                {
                    getHouse.Sql_Result = status1;
                }
               
            }
            return getHouse;

        }
    }
}
