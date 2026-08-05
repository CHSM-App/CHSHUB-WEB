using DBCode.DataClass;
using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Management;

namespace Utility.DataClass
{
    public class receipt
    {
        private string owner;
        private string Operation;
        private string Result;
        private string search;
        // 🔹 Private Fields
        private int receiptid;
        private string societyid;
        private int flatid;
        private string receiptno;
        private DateTime receiptdate;
        private string paymode;
        private string chequeno;
        private DateTime? chequedate;
        private string bankname;
        private string transactionref;
        private decimal paidamount;
        private string remarks;
        private int status;
        private int mode;
        private string createdby;
        private string billDetails;
        private string bill_status;
        private string address;
        private int payment_type;
        private int house_no;
        private string amount;
        private int bill_id;
        // 🔹 Public Properties


        public string Amount
        {
            get { return amount; }
            set { amount = value; }
        }
        public int HouseNo
        {
            get { return house_no; }
            set { house_no = value; }
        }
        public string Addresss
        {
            get { return address; }
            set { address = value; }
        }
        public int PayType
        {
            get { return payment_type; }
            set { payment_type = value; }
        }
        public string Bill_status
        {
            get { return bill_status; }
            set { bill_status = value; }
        }
        public string Owner
        {
            get { return owner; }
            set { owner = value; }
        }
        public int Receipt_Id
        {
            get { return receiptid; }
            set { receiptid = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }

        public int Flat_Id
        {
            get { return flatid; }
            set { flatid = value; }
        }
        public int Mode
        {
            get { return mode; }
            set { mode = value; }
        }

        public string Receipt_No
        {
            get { return receiptno; }
            set { receiptno = value; }
        }

        public DateTime Receipt_Date
        {
            get { return receiptdate; }
            set { receiptdate = value; }
        }

        public string Pay_Mode
        {
            get { return paymode; }
            set { paymode = value; }
        }
        public string BillDetails
        {
            get { return billDetails; }
            set { billDetails = value; }
        }
        public string Cheque_No
        {
            get { return chequeno; }
            set { chequeno = value; }
        }

        public DateTime? Cheque_Date
        {
            get { return chequedate; }
            set { chequedate = value; }
        }

        public string Bank_Name
        {
            get { return bankname; }
            set { bankname = value; }
        }

        public string Transaction_Ref
        {
            get { return transactionref; }
            set { transactionref = value; }
        }

        public decimal Paid_Amount
        {
            get { return paidamount; }
            set { paidamount = value; }
        }

        public string Remarks
        {
            get { return remarks; }
            set { remarks = value; }
        }

        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        public string Created_By
        {
            get { return createdby; }
            set { createdby = value; }
        }

        public string Sql_Operation
        {
            get { return Operation; }
            set { Operation = value; }
        }
        public string Sql_Result
        {
            get { return Result; }
            set { Result = value; }
        }
        public string Search
        {
            get { return search; }
            set { search = value; }
        }

        public int BillId
        {
            get { return bill_id; }
            set { bill_id = value; }
        }
    }
}