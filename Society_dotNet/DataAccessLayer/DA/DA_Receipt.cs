using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Mail;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Receipt
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getreceipt(receipt Receipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Receipt.Sql_Operation));
            data_item.Add(st.create_array("society_id", Receipt.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_receipt", ref sdr);

            if (status1 == "Done")
                if(sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }

        public receipt updatereceipt(receipt Receipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("Action", "INSERT"));
            data_item.Add(st.create_array("ReceiptId", Receipt.Receipt_Id));
            
     
                data_item.Add(st.create_array("SocietyID", Receipt.Society_Id));
                data_item.Add(st.create_array("FlatID", Receipt.Flat_Id));
                data_item.Add(st.create_array("PayMode", Receipt.Pay_Mode));
                data_item.Add(st.create_array("ChequeNo", Receipt.Cheque_No));
                data_item.Add(st.create_array("ChequeDate", Receipt.Cheque_Date));
                data_item.Add(st.create_array("BankName", Receipt.Bank_Name));
                data_item.Add(st.create_array("TransactionRef", Receipt.Transaction_Ref));
                data_item.Add(st.create_array("PaidAmount", Receipt.Paid_Amount));
                data_item.Add(st.create_array("Remarks", Receipt.Remarks));
                data_item.Add(st.create_array("Status", Receipt.Status));
                data_item.Add(st.create_array("CreatedBy", Receipt.Created_By));
            data_item.Add(st.create_array("bills", Receipt.BillDetails));



            status1 = st.run_query(data_item, "Select", "sp_MaintenanceReceipt", ref sdr);
            if (status1 == "Done")
            {
               
                    Receipt.Sql_Result = status1;
               
            }
            return Receipt;
        }

        public DataTable fill_list(string operation, int flat, string society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Action", operation));
            data_item.Add(st.create_array("FlatId", flat));
            data_item.Add(st.create_array("SocietyID", society));

           

            status1 = st.run_query(data_item, "Select", "sp_MaintenanceReceipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        //public receipt Email_Send(receipt receipt)
        //{
        //    ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
        //    SqlDataReader sdr = null;
        //    string status;
        //    data_item.Add(st.create_array("operation", receipt.Sql_Operation));
        //    data_item.Add(st.create_array("receipt_id", receipt.receipt_id));
        //    data_item.Add(st.create_array("owner_id", receipt.Owner_Id));

        //    status = st.run_query(data_item, "Delete", "sp_receipt", ref sdr);
        //    if (status == "Done")
        //    {
        //        receipt.Sql_Result = status;
        //    }
        //    return receipt;
        //}



        public object Print_Receipt(receipt getReceipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", getReceipt.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public DataTable get_cashbook(Cashbook cash)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", cash.Sql_Operation));
            data_item.Add(st.create_array("build_id", cash.build_id));
            data_item.Add(st.create_array("type", cash.Type));
            data_item.Add(st.create_array("society_id", cash.Society_Id));
            if (cash.Date1 != DateTime.MinValue && cash.Date2 != DateTime.MinValue)
            {
                data_item.Add(st.create_array("date1", cash.Date1));
                data_item.Add(st.create_array("date2", cash.Date2));
            }
            status1 = st.run_query(data_item, "Select", "sp_cashbook", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public receipt receipt_exfetch(receipt Receipt)
        {
            
            string status = "", str = "";
            int val = 0;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", Receipt.Sql_Operation));
            data_item.Add(st.create_array("society_id", Receipt.Society_Id));
            status = st.run_query(data_item, "Select", "sp_receipt", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    str = sdr["receipt_no"].ToString();
                    val = int.Parse(Regex.Match(str, @"\d+").ToString()) + 1;
                    Receipt.Receipt_No = str.Replace((val - 1).ToString(), (val).ToString());
                }
                else
                {
                    Receipt.Receipt_No = "RPT0001";
                }
            }
            return Receipt;
        }

        public DataTable Get_Paid_Amount(receipt getReceipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", getReceipt.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable receipt_search(receipt receipt1)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("search", receipt1.Search));
            data_item.Add(st.create_array("operation", "search"));
            data_item.Add(st.create_array("society_id", receipt1.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_receipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

       

      

        public receipt advance_pay_settlement(receipt Receipt)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            int bal = 0;
            data_item.Add(st.create_array("operation", Receipt.Sql_Operation));
            data_item.Add(st.create_array("flat_id", Receipt.Flat_Id));

            status = st.run_query(data_item, "Select", "sp_receipt", ref sdr);
            if (status == "Done")
            {
                while (sdr.Read())
                {
                   bal += Convert.ToInt32(sdr["che_amount"].ToString());

                }
              //  Receipt.Paid_Amount = bal.ToString();
            }

            return Receipt;

        }

        public receipt delete(receipt Receipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", Receipt.Sql_Operation));
            data_item.Add(st.create_array("receipt_id", Receipt.Receipt_Id));

            status = st.run_query(data_item, "Delete", "sp_receipt", ref sdr);
            if (status == "Done")
            {
                Receipt.Sql_Result = status;
            }
            return Receipt;
        }

        public receipt Select_Cheque(receipt Receipt)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;

            data_item.Add(st.create_array("operation", Receipt.Sql_Operation));
            data_item.Add(st.create_array("cheque_NO", Receipt.Cheque_No));
            data_item.Add(st.create_array("flat_id", Receipt.Flat_Id));
            status = st.run_query(data_item, "Select", "sp_receipt", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    Receipt.Cheque_Date = Convert.ToDateTime(sdr["cheque_date"].ToString());
                    Receipt.Paid_Amount = Convert.ToInt32(sdr["paid_amount"].ToString());
                }
            }
            return Receipt;
        }

        public DataTable grid_show(receipt billReceipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Action", billReceipt.Sql_Operation));
            data_item.Add(st.create_array("SocietyID", billReceipt.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_maintenanceReceipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable view_bill(receipt billReceipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();

            data_item.Add(st.create_array("Action", billReceipt.Sql_Operation));   // INSERT / UPDATE / VIEWBYID / DELETE
            data_item.Add(st.create_array("ReceiptID", billReceipt.Receipt_Id));

            status1 = st.run_query(data_item, "Select", "sp_MaintenanceReceipt", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
            //if (status1 == "Done")
            //{
            //    while (sdr.Read())
            //    {
            //        billReceipt.Receipt_No = (sdr["receipt_no"]).ToString();
            //        billReceipt.Receipt_Id = Convert.ToInt32(sdr["receipt_id"]);
            //        billReceipt.Transaction_Ref = (sdr["transaction_ref"]).ToString();
            //        billReceipt.Owner = sdr["name"].ToString();
            //        billReceipt.Paid_Amount = Convert.ToDecimal(sdr["paid_amount"]);
            //        billReceipt.Bill_status = sdr["bill_status"].ToString();
            //        billReceipt.Receipt_Date = Convert.ToDateTime(sdr["date"]);
            //        billReceipt.Addresss = sdr["address"].ToString();
            //        billReceipt.Bank_Name = sdr["bank_name"].ToString();
            //    }
            //}

            //return billReceipt;
        }
    }
}