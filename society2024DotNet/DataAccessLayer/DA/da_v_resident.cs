using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Sockets;
using System.Web;
using System.Web.Services.Description;
using Utility.DataClass;

namespace DataAccessLayer.DA
{

    public class da_v_resident
    {
        stored st = new stored();

        public void insertOwner(homeModal house)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", house.Sql_Operation));
            data_item.Add(st.create_array("village_owner_id", house.village_owner_id));
            data_item.Add(st.create_array("village_id", house.Village_id));
            data_item.Add(st.create_array("name", house.Owner_Name));
            data_item.Add(st.create_array("house_id", house.House_Id));
            data_item.Add(st.create_array("address", house.address));
            data_item.Add(st.create_array("pre_mob", house.phone));

            status1 = st.run_query(data_item, "Select", "sp_house_owner", ref sdr);
        }


        public DataTable gridBindHistory(string village_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("village_id", village_id));

            status1 = st.run_query(data_item, "Select", "sp_house", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }


        public DataTable gridBind(string village_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("village_id", village_id));

            status1 = st.run_query(data_item, "Select", "sp_house", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public int InsertHouse(homeModal house)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;
            string status = "";
            data_item.Add(st.create_array("operation", "Update" ));
            data_item.Add(st.create_array("house_id", house.House_Id ));
            data_item.Add(st.create_array("house_no", house.House_No));
            data_item.Add(st.create_array("house_type", house.House_type));
            data_item.Add(st.create_array("AREA", house.House_Sqft));
            data_item.Add(st.create_array("village_id", house.Village_id));
            data_item.Add(st.create_array("gharpatti_charges", house.Sqft_Charges));
            data_item.Add(st.create_array("no_of_tab", house.No_Of_Taps));
            data_item.Add(st.create_array("water_charges", house.Tap_Charges));
            data_item.Add(st.create_array("waste_charges", house.Solid_Waste_Fee));
            data_item.Add(st.create_array("audt_modify_id", house.UserId));


            status = st.run_query_scalar(data_item, "Select", "sp_house", ref sdr);
            if (status == "Done")
            {
                house.Sql_Result = status;
            }

            return sdr;
        }

        public DataTable gridbind_pending(string village_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("village_id", village_id));

            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable gridbind_pending_specific_tax(string operation,string village_id, int type, int house_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("village_id", village_id));
            data_item.Add(st.create_array("house_id", house_id));

            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public void makePayment(receipt payment)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", payment.Sql_Operation));
            data_item.Add(st.create_array("village_id", payment.Society_Id));
            data_item.Add(st.create_array("all_housereceipt_id", payment.Receipt_No));
            data_item.Add(st.create_array("Transation_ref", payment.Transaction_Ref));
            data_item.Add(st.create_array("pay_mode", payment.Mode));
            data_item.Add(st.create_array("remark", payment.Remarks));
            data_item.Add(st.create_array("chqno", payment.Cheque_No));
            data_item.Add(st.create_array("chqdate", payment.Cheque_Date));

            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);
        }

        public receipt getReceiptData(int receipt_id, string operation)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            receipt payment = new receipt();
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("house_receipt_id", receipt_id));

            status1 = st.run_query(data_item, "Select", "sp_house_tax_receipt", ref sdr);

            if (status1 == "Done")
            {
                //dt.Load(sdr);
                while (sdr.Read())
                {
                    payment.Society_Id = sdr["village_id"].ToString();
                    payment.Owner = sdr["name"].ToString();
                    payment.Receipt_No = sdr["receipt_no"].ToString();
                    payment.Amount = sdr["Amount_paid"].ToString();
                    payment.Addresss = sdr["address"].ToString();
                    if (sdr["chqno"].ToString() !="")
                        payment.Cheque_No = sdr["chqno"].ToString();
                    if (sdr["chqdate"].ToString() != "")
                        payment.Cheque_Date = Convert.ToDateTime(sdr["chqdate"].ToString());
                    if (sdr["Transation_ref"].ToString() != "")
                        payment.Transaction_Ref = sdr["Transation_ref"].ToString();
                    payment.Pay_Mode = sdr["pay_mode"].ToString();
                    payment.HouseNo = Convert.ToInt32(sdr["house_no"].ToString());
                    payment.PayType = Convert.ToInt32(sdr["payment_type"].ToString());
                }


            }

            return payment;
        }

        public int InsertBalanceHeader(AmcBalanceSheet balanceEntry)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            int sdr = 0;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", balanceEntry.Operation));
            data_item.Add(st.create_array("bal_head_id", balanceEntry.BalanceHeaderID));
            data_item.Add(st.create_array("village_id", balanceEntry.SocietyID));
            data_item.Add(st.create_array("bal_header_desc", balanceEntry.MainPointText));
            data_item.Add(st.create_array("amount", balanceEntry.Amount));
            data_item.Add(st.create_array("status_id", balanceEntry.Status));
            data_item.Add(st.create_array("comp_id", balanceEntry.EntryCategory=="asset" ? 1:2));


            status1 = st.run_query_scalar(data_item, "Select", "sp_balancesheet", ref sdr);

            return sdr;
        }

        public AmcBalanceSheet InsertBalanceSubpoint(AmcBalanceSheet balanceEntry)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", balanceEntry.Operation));
            data_item.Add(st.create_array("village_id", balanceEntry.SocietyID));
            data_item.Add(st.create_array("bal_sub_desc", balanceEntry.SubpointText));
            data_item.Add(st.create_array("amount", balanceEntry.Amount));
            data_item.Add(st.create_array("status_id", balanceEntry.Status));
            data_item.Add(st.create_array("bal_head_id", balanceEntry.BalanceHeaderID));
            data_item.Add(st.create_array("bal_sub_id", balanceEntry.BalanceSubpointID));

            status1 = st.run_query(data_item, "Select", "sp_balancesheet", ref sdr);
               
            if(status1 !="Done")
            {
                balanceEntry.Remarks = status1;
            }

            return balanceEntry;
        }

        public DataTable getPoints(AmcBalanceSheet balanceEntry)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", balanceEntry.Operation));
            data_item.Add(st.create_array("village_id", balanceEntry.SocietyID));

            status1 = st.run_query(data_item, "Select", "sp_balancesheet", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public string UpdateBalanceSequence(AmcBalanceSheet balanceEntry)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", balanceEntry.Operation));
            data_item.Add(st.create_array("Seq_order ", balanceEntry.SequenceOrder));
            data_item.Add(st.create_array("bal_head_id ", balanceEntry.BalanceHeaderID));

            status1 = st.run_query(data_item, "Select", "sp_balancesheet", ref sdr);

            return status1;
        }
    }
}