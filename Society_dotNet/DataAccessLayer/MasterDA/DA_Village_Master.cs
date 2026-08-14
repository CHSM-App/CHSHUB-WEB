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
    public class DA_Village_Master
    {
        stored st = new stored();

        public void fill_drop(DropDownList ddl_state, string sql_query, string v1, string v2)
        {
            st.fill_drop(ddl_state, sql_query, v1, v2);
        }

        public DataTable Get_Village(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("village_id", village.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_village_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable getsquare_feet(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("village_id", village.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_square_ft_rate", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Village_Search(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Pending_Sq_ft_Rt(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Village Delete_Water_Tax(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("water_tax_id", village.Water_Tax_Id));
            status1 = st.run_query(data_item, "Select", "sp_water_tax", ref sdr);

            if (status1 == "Done")
            {
                village.Sql_Result = status1;
            }
            return village;
        }

        public Village Update_Water_Tax(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("water_tax_id", village.Water_Tax_Id));
            if (village.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("house_no", village.House_No));
                data_item.Add(st.create_array("village_id", village.Village_Id));
                data_item.Add(st.create_array("from_date", village.From_Date));
                data_item.Add(st.create_array("to_date", village.To_Date));
                data_item.Add(st.create_array("con_type_id", village.Connection_Type));
                data_item.Add(st.create_array("water_connection_size", village.Water_Connection_Size));
                data_item.Add(st.create_array("water_tax_amount", village.Water_Tax_Amount));
            }
            status1 = st.run_query(data_item, "Select", "sp_water_tax", ref sdr);

            if (status1 == "Done")
            {
                if (village.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        village.Village_Id = sdr["village_id"].ToString();
                        village.House_No = Convert.ToInt32(sdr["house_no"].ToString());
                        village.From_Date = Convert.ToDateTime(sdr["from_date"].ToString());
                        village.To_Date = Convert.ToDateTime(sdr["to_date"].ToString());
                        village.Connection_Type = sdr["con_type_id"].ToString();
                        village.Water_Connection_Size = Convert.ToInt32(sdr["water_connection_size"].ToString());
                        village.Water_Tax_Amount = Convert.ToDecimal(sdr["water_tax_amount"].ToString());
                       
                    }
                }
                else
                {
                    village.Sql_Result = status1;
                }

            }

            return village;
        }

        public DataTable Get_Water_Tax(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("village_id", village.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_water_tax", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Search_Sq_Ft_Rate(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Village Update_Sq_Ft_Rate(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("sq_rate_id", village.Sq_Rate_Id));
            if (village.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("house_type_id", village.House_Type_Id));
                data_item.Add(st.create_array("rate", village.Rate));
                data_item.Add(st.create_array("village_id", village.Village_Id));
                data_item.Add(st.create_array("applied_date", village.Applied_Date));
                data_item.Add(st.create_array("bill_gen_date", village.Bill_Generation_Date));
                data_item.Add(st.create_array("due_date", village.Due_Date));
            }
                status1 = st.run_query(data_item, "Select", "sp_square_ft_rate", ref sdr);

                if (status1 == "Done")
                {
                    if (village.Sql_Operation == "Select")
                    {
                        while (sdr.Read())
                        {

                            village.Village_Id = sdr["village_id"].ToString();
                            village.Rate = Convert.ToDecimal(sdr["rate"].ToString());
                            village.House_Type_Id = (sdr["house_type_id"].ToString());
                            village.Applied_Date = Convert.ToDateTime(sdr["applied_date"].ToString());
                            village.Bill_Generation_Date = Convert.ToDateTime(sdr["bill_gen_date"].ToString());
                            village.Due_Date = Convert.ToDateTime(sdr["due_date"].ToString());
                        }
                    }
                    else
                    {
                        village.Sql_Result = status1;
                    }

                }
            
            return village;
        }

        public Village Update_Village(Village village)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", village.Sql_Operation));
            data_item.Add(st.create_array("id", village.Village_Id));
            if (village.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("name", village.Name));
                data_item.Add(st.create_array("contact_no", village.Contact_No));
                data_item.Add(st.create_array("email", village.Email));
                data_item.Add(st.create_array("division", village.Division));
                data_item.Add(st.create_array("state_id", village.State_Id));
                data_item.Add(st.create_array("pincode", village.PinCode));
                data_item.Add(st.create_array("district_id", village.District_Id));
            }
                status1 = st.run_query(data_item, "Select", "sp_village_master", ref sdr);
            
                if (status1 == "Done")
                {
                    if (village.Sql_Operation == "Select")
                    {
                        while (sdr.Read())
                        {

                            village.Village_Id = sdr["village_id"].ToString();
                            village.Name = sdr["name"].ToString();
                            village.Contact_No = sdr["contact_no"].ToString();
                            village.Email = sdr["email"].ToString();
                            village.Division = sdr["division"].ToString();
                            village.State_Id = Convert.ToInt32(sdr["state_id"].ToString());
                            village.PinCode = Convert.ToInt32(sdr["pincode"].ToString());
                            village.District_Id = Convert.ToInt32(sdr["district_id"].ToString());
                        }
                    }
                    else
                    {
                        village.Sql_Result = status1;
                    }

                }
            
                return village;
        }
    }
}

            