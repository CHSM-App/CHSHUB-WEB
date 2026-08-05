using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Shop_Maint
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable Get_Shop_Maintenance(Shop_Maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_shop_maintenance", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Shop_Maintenance Update_Shop_Maintenance(Shop_Maintenance maintenance)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("shop_maint_id", maintenance.shop_maint_id));
            if (maintenance.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", maintenance.Society_Id)); 
                data_item.Add(st.create_array("mrep_no", maintenance.Mrep_No));
                data_item.Add(st.create_array("m_date", maintenance.M_Date));
                data_item.Add(st.create_array("led_id", maintenance.led_id));
                data_item.Add(st.create_array("amt", maintenance.Amt));
                data_item.Add(st.create_array("other_details", maintenance.Other_Details));
                data_item.Add(st.create_array("pay_method", maintenance.Pay_Method));
                data_item.Add(st.create_array("cheq_no", maintenance.Cheq_No));
                if(maintenance.Cheq_Date != DateTime.MinValue)
                data_item.Add(st.create_array("cheq_date", maintenance.Cheq_Date));
                
            }
            status1 = st.run_query(data_item, "Select", "sp_shop_maintenance", ref sdr);
            maintenance.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (maintenance.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  facility_id.Value = sdr["facility_id"].ToString();
                        maintenance.Society_Id = sdr["society_id"].ToString();
                        maintenance.Mrep_No = sdr["mrep_no"].ToString();
                        maintenance.M_Date = Convert.ToDateTime(sdr["m_date"].ToString());
                        maintenance.led_id = Convert.ToInt32(sdr["led_id"].ToString());
                        maintenance.Amt = Convert.ToInt32(sdr["amt"].ToString());
                        maintenance.Other_Details = sdr["other_details"].ToString();
                        maintenance.Pay_Method = sdr["pay_method"].ToString();
                        maintenance.Cheq_No = sdr["cheq_no"].ToString();
                        if(sdr["cheq_date"].ToString() != "")
                        maintenance.Cheq_Date = Convert.ToDateTime(sdr["cheq_date"].ToString());
                        
                    }
                }
                else
                {
                    maintenance.Sql_Result = status1;
                }
            }
            return maintenance;

        }

        public DataTable Get_PrintShop(Shop_Maintenance shop)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", shop.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public object shop_maint_search(Shop_Maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("search", maintenance.Search));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_shop_maintenance", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Shop_Maintenance Shop_Maint_Delete(Shop_Maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("shop_maint_id", maintenance.shop_maint_id));

            status = st.run_query(data_item, "Delete", "sp_shop_maintenance", ref sdr);
            if (status == "Done")
            {
                maintenance.Sql_Result = status;
            }
            return maintenance;
        }
        public Shop_Maintenance Receipt_TextChanged(Shop_Maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));
            data_item.Add(st.create_array("shop_maint_id", maintenance.shop_maint_id));
            data_item.Add(st.create_array("mrep_no", maintenance.Mrep_No));
            
            status = st.run_query(data_item, "Select", "sp_shop_maintenance", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    maintenance.Sql_Result = "Already exist";
                else
                    maintenance.Sql_Result = "";
            return maintenance;


        }
    }
}