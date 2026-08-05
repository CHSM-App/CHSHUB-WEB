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
    public class DA_Village_Owner
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable Get_Tax_Receipt(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Get_Village_Owner(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public VillageOwner village_owner_delete(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_owner_id", village_owner.Village_Owner_id));
            status1 = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);

            if (status1 == "Done")
            {
                village_owner.Sql_Result = status1;
            }
            return village_owner;
        }
      
        public DataTable house_owner_search(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village_owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public VillageOwner Fetch_House_No(VillageOwner village_owner)
        {
            string status = "", str = "";
            int val = 0;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));
            status = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    str = sdr["house_no"].ToString();
                    val = int.Parse(Regex.Match(str, @"\d+").ToString()) + 1;
                    village_owner.House_No = Convert.ToInt32(str.Replace((val - 1).ToString(), (val).ToString()));
                }
                else
                {
                    village_owner.House_No = 001;
                }
            }
            return village_owner;
        }

        public VillageOwner Get_Village_Id(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_owner_id", village_owner.Village_Owner_id));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));

            status1 = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    village_owner.Village_Id = sdr["village_id"].ToString();
                else
                    village_owner.Village_Id = "V10001";

            return village_owner;
        }
        public DataTable Print_House_Receipt(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village_owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public VillageOwner Check_Select(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;

            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("chqno", village_owner.Chqno));
            data_item.Add(st.create_array("house_no", village_owner.House_No));
            status = st.run_query(data_item, "Select", "sp_receipt", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    village_owner.Chqdate = Convert.ToDateTime(sdr["che_date"].ToString());
                    village_owner.Chq_Amount = Convert.ToDecimal(sdr["che_amount"].ToString());
                }
            }
            return village_owner;
        }

        public VillageOwner runproc_house_owner(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_owner_id", village_owner.Village_Owner_id));


            status1 = st.run_query(data_item, village_owner.Sql_Operation, "sp_house_owner", ref sdr);
            if (status1 == "Done")
            {
                if (village_owner.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        village_owner.Name = sdr["name"].ToString();
                        village_owner.House_No = Convert.ToInt32(sdr["house_no"].ToString());
                        village_owner.House_Type = sdr["house_type"].ToString();
                        village_owner.Sq_Ft = Convert.ToDecimal(sdr["sq_ft"].ToString());
                        village_owner.Address = sdr["address"].ToString();
                        village_owner.Pre_Mob = sdr["pre_mob"].ToString();
                        village_owner.Village_Id = sdr["village_id"].ToString();
                        village_owner.Alter_Mob = sdr["alter_mob"].ToString();
                        village_owner.Id_Proof = sdr["id_proof"].ToString();
                        //village_owner.Address_Line1 = sdr["address_Line1"].ToString();
                    }
                }
            }
            return village_owner;
        }

        public VillageOwner update_village_owner(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            //int sdr = 0;
            string status1;
            //string type = "village_owner";
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_owner_id", village_owner.Village_Owner_id));
            if (village_owner.Sql_Operation == "Update")
            {

                data_item.Add(st.create_array("village_id", village_owner.Village_Id));
                data_item.Add(st.create_array("house_no", village_owner.House_No));
                data_item.Add(st.create_array("house_type", village_owner.House_Type));
                data_item.Add(st.create_array("sq_ft", village_owner.Sq_Ft));
                data_item.Add(st.create_array("address", village_owner.Address));
                data_item.Add(st.create_array("pre_mob", village_owner.Pre_Mob));
                data_item.Add(st.create_array("alter_mob", village_owner.Alter_Mob));
                data_item.Add(st.create_array("name", village_owner.Name));
                data_item.Add(st.create_array("id_proof", village_owner.Id_Proof));

            }
            status1 = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);
            if (status1 == "Done")
                village_owner.Sql_Result = status1;
            return village_owner;
        }

        public VillageOwner Update_House_Tax_Receipt(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("house_receipt_id", village_owner.House_Receipt_Id));
            if (village_owner.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("village_id", village_owner.Village_Id));
                data_item.Add(st.create_array("pay_mode", village_owner.Pay_Mode));
                data_item.Add(st.create_array("house_no", village_owner.House_No));
                data_item.Add(st.create_array("receipt_no", village_owner.Receipt_No));
                //data_item.Add(st.create_array("date", village_owner.Date));
                data_item.Add(st.create_array("house_tax", village_owner.House_Tax));
                if (village_owner.Type == "1")
                    data_item.Add(st.create_array("house_amount", village_owner.Paid_Amount));
                if (village_owner.Type == "2")
                    data_item.Add(st.create_array("water_amount", village_owner.Paid_Amount));


                if (village_owner.Pay_Mode == 2 || village_owner.Pay_Mode == 3)
                {
                    data_item.Add(st.create_array("chqno", village_owner.Chqno));
                    data_item.Add(st.create_array("chqdate", village_owner.Chqdate));
                }
            }
            if (village_owner.Sql_Operation == "pending_dues")
            {
                data_item.Add(st.create_array("house_amount", village_owner.Paid_Amount));
                data_item.Add(st.create_array("house_no", village_owner.House_No));
                data_item.Add(st.create_array("pay_for", village_owner.Type));
            }
            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
            {
                if (village_owner.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        village_owner.Village_Id = sdr["village_id"].ToString();
                        village_owner.Pay_Mode = Convert.ToInt32(sdr["pay_mode"].ToString());
                        //village_owner.Date = Convert.ToDateTime(sdr["date"].ToString());
                        village_owner.Receipt_No = sdr["receipt_no"].ToString();
                        village_owner.House_Tax = Convert.ToDecimal(sdr["house_tax"].ToString());
                        village_owner.House_No = Convert.ToInt32(sdr["house_no"].ToString());
                        if (sdr["house_amount"].ToString() != "0.00")
                            village_owner.Paid_Amount = Convert.ToDecimal(sdr["house_amount"].ToString());
                        else
                            village_owner.Paid_Amount = Convert.ToDecimal(sdr["water_amount"].ToString());
                        village_owner.Balance = Convert.ToDecimal(sdr["house_tax"].ToString()) - village_owner.Paid_Amount;
                        village_owner.Chqno = sdr["chqno"].ToString();
                        if (sdr["chqdate"].ToString() != "")
                        {
                            village_owner.Chqdate = Convert.ToDateTime(sdr["chqdate"]);
                        }
                    }
                }
                else
                {
                    village_owner.Sql_Result = status1;
                }
            }
            return village_owner;
        }

        public VillageOwner Pending_House_Tax_Receipt(VillageOwner village_owner)
        {

            SqlDataReader sdr = null;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("house_no", village_owner.House_No));
            data_item.Add(st.create_array("pay_for", village_owner.Type));
            string status = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                {
                    village_owner.House_Tax = Convert.ToDecimal(sdr["due"]);
                    village_owner.Advance = float.Parse((sdr["advance"]).ToString());
                    village_owner.Balance = Convert.ToDecimal(sdr["balance"]);
                }

            return village_owner;
        }

        public VillageOwner Fetch_House_Tax_Receipt(VillageOwner village_owner)
        {
            string status = "", str = "";
            int val = 0;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));
            status = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    str = sdr["receipt_no"].ToString();
                    val = int.Parse(Regex.Match(str, @"\d+").ToString()) + 1;
                    village_owner.Receipt_No = str.Replace((val - 1).ToString(), (val).ToString());
                }
                else
                {
                    village_owner.Receipt_No = "RPT0001";
                }

            }
            return village_owner;
        }

        public VillageOwner Delete_House_Tax(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("house_receipt_id", village_owner.House_Receipt_Id));
            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
            {
                village_owner.Sql_Result = status1;
            }
            return village_owner;
        }

        public object Print_House_Owner(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village_owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                dt.Load(sdr);
            return dt;
        }
        public DataTable House_Tax_Receipt_Search(VillageOwner village_owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", village_owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public VillageOwner Fetch_Address(VillageOwner village_owner)
        {
            string status = "";

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", village_owner.Sql_Operation));
            data_item.Add(st.create_array("village_id", village_owner.Village_Id));
            status = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    //str = sdr["address_line1"].ToString();
                    village_owner.Address_Line1 = sdr["address_line1"].ToString();
                }

            }
            return village_owner;
        }
    }
}