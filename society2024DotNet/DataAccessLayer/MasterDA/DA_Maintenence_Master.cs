using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Principal;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace DataAccessLayer.MasterDA
{
    public class DA_Maintenence_Master
    {
        stored st = new stored();
        DataTable dt1 = new DataTable();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }


        public void fill_drop_1(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop_1(drp_down, sqlstring, text, value);
        }
        public DataTable get_maintenance_details(maintenance Maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", Maintenance1.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_maintanance_cal", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Get_Monthwise_Charges(maintenance_cal maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_Society_Charges_monthwise", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public maintenance Update_Maintenance_Details(maintenance Maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;
            string status1;
            int i = 1;
            dt1 = btn_add_click(Maintenance1);
            data_item.Add(st.create_array("operation", Maintenance1.Sql_Operation));
            if (Maintenance1.Sql_Operation == "Update")
            {
                foreach (DataRow row in dt1.Rows)
                {
                    data_item.Add(st.create_array("col" + i + "_name", string.IsNullOrWhiteSpace(row["charges"].ToString()) ? (object)DBNull.Value : row["charges"].ToString()));
                    data_item.Add(st.create_array("col" + i + "_amount", string.IsNullOrWhiteSpace((float.Parse(row["amount"].ToString()) / Maintenance1.Flat).ToString()) ? (object)DBNull.Value : (float.Parse(row["amount"].ToString()) / Maintenance1.Flat).ToString()));
                    i++;
                }

                data_item.Add(st.create_array("m_date", Maintenance1.M_Date));
                data_item.Add(st.create_array("society_id", Maintenance1.Society_Id));
                data_item.Add(st.create_array("m_total", Maintenance1.M_Total));

            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_new_maintenance", ref sdr);
            if (status1 == "Done")
            {
                if (sdr != 0)

                    Maintenance1.n_m_id = sdr;
            }
            return Maintenance1;



        }

        public maintenance_cal Remaining_Due(maintenance_cal maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
           

            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_Society_Charges_monthwise", ref sdr);

            if (status1 == "Done")
            {
                if (sdr.Read())
                {
                    maintenance1.Amount = Convert.ToDecimal(sdr["amount"].ToString());
                    maintenance1.Pending_Amount = Convert.ToDecimal(sdr["due"].ToString());

                }
                  
            }
            return maintenance1;
        }

        public maintenance_cal Delete_Monthwise_Charges(maintenance_cal maintenance1)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", "Delete"));
            data_item.Add(st.create_array("mon_charge_id", maintenance1.mon_charge_id));
            status1 = st.run_query(data_item, "Select", "sp_society_charges_monthwise", ref sdr);

            if (status1 == "Done")
            {
                maintenance1.Sql_Result = status1;
            }
            return maintenance1;
        }

        public maintenance_cal Update_monthwise_charges(maintenance_cal Maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", Maintenance1.Sql_Operation));
            data_item.Add(st.create_array("mon_charge_id", Maintenance1.mon_charge_id));
            if (Maintenance1.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", Maintenance1.Society_Id));
                
                
                data_item.Add(st.create_array("amount", Maintenance1.Amount));
            }
            status1 = st.run_query(data_item, "Select", "sp_Society_Charges_monthwise", ref sdr);
            if (status1 == "Done")
            {
                if (Maintenance1.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        Maintenance1.mon_charge_id = Convert.ToInt32(sdr["mon_charge_id"].ToString());
                        Maintenance1.Amount = Convert.ToDecimal(sdr["amount"].ToString());

                        Maintenance1.Date = Convert.ToDateTime(sdr["date"].ToString());
                    }
                }
            }
            return Maintenance1;
        }

        public DataTable 
            Print_maintanance(maintenance Maintanance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Maintanance.Sql_Operation));
            data_item.Add(st.create_array("society_Id", Maintanance.Society_Id));
            data_item.Add(st.create_array("bill_id", Maintanance.n_m_id));

                status1 = st.run_query(data_item, "Select", "sp_maintanance_cal", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public DataTable ownerwise_maintenance(maintenance getMaintenance)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", getMaintenance.Sql_Operation));
            
            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
            

        public DataTable get_maintenance_report(maintenance getMaintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", getMaintenance.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public maintenance getflats(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            int i = 1;        
            string status1 = "";        
                data_item.Add(st.create_array("operation", "check_count"));
                data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
         

            status1 = st.run_query(data_item, "Select", "sp_flat_master", ref sdr);
            if (status1 == "Done")
                if (sdr.Read())

                    maintenance1.Flat = int.Parse(sdr["flat"].ToString());

            return maintenance1;
        }
        public maintenance Check_Already(maintenance maintenance1)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));

            data_item.Add(st.create_array("build_id", maintenance1.build_id));
            data_item.Add(st.create_array("m_date", maintenance1.M_Date));

            status = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);
            if (status == "Done")
            {

                if (sdr.Read())
                {

               
                    maintenance1.n_m_id = Convert.ToInt32(sdr["n_m_id"].ToString());
                    maintenance1.Sql_Result = "Exist";
                }
            }


            return maintenance1;

        }



        public DataTable btn_add_click(maintenance Maintenance1)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            //int i = 1;
            //int total = 0;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "exfetch"));
            data_item.Add(st.create_array("society_id", Maintenance1.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
            {
                if (sdr.HasRows)
                    dt.Load(sdr);
              

            }
            return dt;
        }

        public maintenance Maintenance_Delete(maintenance Maintenance1)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", Maintenance1.Sql_Operation));
            data_item.Add(st.create_array("n_m_id", Maintenance1.n_m_id));

            status = st.run_query(data_item, "Delete", "sp_new_maintenance", ref sdr);
            if (status == "Done")
            {
                Maintenance1.Sql_Result = status;
            }
            return Maintenance1;


        }


        public maintenance Select_Maintenance_Details(maintenance maintenance1) //--------------------------------------------------------------------------------------------------------------------------
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("n_m_id", maintenance1.n_m_id));
            status1 = st.run_query(data_item, "Select", "sp_maintanance_cal", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {

                    //maintenance1.build_id = Convert.ToInt32(sdr["build_id"].ToString());
                    maintenance1.M_Date = Convert.ToDateTime(sdr["gen_date"].ToString());
                    // drp_flat_type.SelectedValue = sdr["facility_id"].ToString();

                    //maintenance1.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                    maintenance1.M_Total = Convert.ToDecimal(sdr["total_amount"].ToString());
                    maintenance1.n_m_id = Convert.ToInt32(sdr["bill_id"].ToString());
                    maintenance1.Status = Convert.ToBoolean(sdr["status"]);

                }
            }

            return maintenance1;
        }


        public maintenance Check_Date(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));

            data_item.Add(st.create_array("build_id", maintenance1.build_id));
            data_item.Add(st.create_array("m_date", maintenance1.M_Date));
            status = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);

            if (sdr.Read())
        { 
                maintenance1.Sql_Result = "Exist";
                maintenance1.n_m_id = Convert.ToInt32(sdr["n_m_id"].ToString());

        }

            return maintenance1;

        }

        public maintenance Bill_Exist(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));

            data_item.Add(st.create_array("n_m_id", maintenance1.n_m_id));
            status = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);

            if (sdr.Read())
            {
                maintenance1.Sql_Result = "Bill_Exist";

            }

            return maintenance1;

        }
        public object search_maintenance(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("search", maintenance1.Name));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Genrate_Bill(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            DataTable dt = new DataTable();
            string status;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            data_item.Add(st.create_array("due_period", maintenance1.due_period));

            status = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);

            if (status == "Done")
            {
                if (sdr.HasRows)
                {
                    dt.Load(sdr);
                }
            }

            return dt;

        }


        public DataTable List_Fill(maintenance maintenance1)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            data_item.Add(st.create_array("build_id", maintenance1.build_id));
            status = st.run_query(data_item, "Select", "sp_new_maintenance", ref sdr);
            if (status == "Done")
            {
                if (sdr.HasRows)
                {
                    
                        dt.Load(sdr);
                  
                   
                }

            }

            return dt;
        }

        public void updateSettings(maintenance maintenance1) //-------------------------------------------------------------------------------------------------------------------------------
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("rate_per_sqf", maintenance1.Per_Sqf_Rate));
            data_item.Add(st.create_array("two_w_rate", maintenance1.Two_W_Rate));
            data_item.Add(st.create_array("four_w_rate", maintenance1.Four_W_Rate));

            data_item.Add(st.create_array("auto_bill_generation", maintenance1.Auto_Gen));
            data_item.Add(st.create_array("bill_gen_date", maintenance1.Gen_Date_Int));
            data_item.Add(st.create_array("bill_due_period", maintenance1.due_period));


            status = st.run_query(data_item, "Select", "sp_account_setting", ref sdr);
            
        }

        public maintenance selectSettings(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_account_setting", ref sdr);
            if (status1 == "Done")
            {
                if (sdr.Read())
                {
                    maintenance1.Per_Sqf_Rate = Convert.ToInt32(sdr["rate_per_sqfeet"]);
                    maintenance1.Two_W_Rate = Convert.ToInt32(sdr["two_wheeler_rate"]);
                    maintenance1.Four_W_Rate = Convert.ToInt32(sdr["four_wheeler_rate"]);

                    maintenance1.Auto_Gen = Convert.ToBoolean(sdr["auto_bill_generation"]);
                    maintenance1.Gen_Date_Int = Convert.ToInt32(sdr["bill_gen_date"]);
                    maintenance1.due_period = Convert.ToInt32(sdr["bill_due_period"]);

                }
            }

            return maintenance1;
        }

        public DataTable executeMaintanence(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            data_item.Add(st.create_array("bill_type", maintenance1.Bill_No));

            status = st.run_query(data_item, "Select", "gen_bill", ref sdr);


            if (status == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);

            return dt;



        }

        public void add_charges(maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("society_id", maintenance.Society_Id));
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("charge_id", maintenance.Charges_id));
            data_item.Add(st.create_array("user_id", maintenance.Creator));
            data_item.Add(st.create_array("charges", maintenance.Nature_Of_Charge));
            data_item.Add(st.create_array("status", maintenance.Status));
            data_item.Add(st.create_array("amount", maintenance.Amount));
            data_item.Add(st.create_array("charges_type", maintenance.BillType));

            status = st.run_query(data_item, "Select", "sp_maintenance_charges", ref sdr);
        }

        public DataTable getCharges(maintenance maintenance)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", maintenance.Sql_Operation));
            data_item.Add(st.create_array("society_id", maintenance.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_maintenance_charges", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public maintenance selectCharges(maintenance maintenance1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", maintenance1.Sql_Operation));
            data_item.Add(st.create_array("charge_id", maintenance1.Charges_id));
            data_item.Add(st.create_array("society_id", maintenance1.Society_Id));
            status1 = st.run_query(data_item, "Select", "sp_maintenance_charges", ref sdr);
            if (status1 == "Done")
            {
                while (sdr.Read())
                {

                    maintenance1.Nature_Of_Charge = sdr["charges"].ToString();
                    maintenance1.Amount = sdr["amount"].ToString();
                    maintenance1.Status = Convert.ToBoolean(sdr["status"]);
                    maintenance1.BillType = Convert.ToBoolean(sdr["charges_type"]);


                }
            }

            return maintenance1;
        }

        public DataTable getToken(int id, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("society_id", society_id));
            data_item.Add(st.create_array("operation", "get_users"));
            data_item.Add(st.create_array("recipients_id", id));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
    }
}
