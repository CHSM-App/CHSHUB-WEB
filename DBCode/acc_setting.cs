using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode
{
    public class acc_setting
    {
        private int sid;
        private int societyid;
        private int memopenbal;
        private int memchargebtn;
        private int memchargeallocation;
        private int receiptbtn;
        private int billgenbtn;
        private int gstround;
        private int chargeround;
        private int paymentvoucher;
        private int debitnotevoucher;
        private int creditnotevoucher;
        private int generalvoucher;
        private int receiptvoucher;
        private int buildwisepayment;
        private int remainderemaildues;
        private string Operation;
        private string Result;


        public int S_Id
        {
            get { return sid; }
            set { sid = value; }
        }
        public int Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }

        public int Mem_Open_Bal
        {
            get { return memopenbal; }
            set { memopenbal = value; }
        }

        public int Mem_Charge_Btn
        {
            get { return memchargebtn; }
            set { memchargebtn = value; }
        }

        public int Mem_Charge_Allocation
        {
            get { return memchargeallocation; }
            set { memchargeallocation = value; }
        }
        public int Receipt_Btn
        {
            get { return receiptbtn; }
            set { receiptbtn = value; }
        }
        public int Bill_Gen_Btn
        {
            get { return billgenbtn; }
            set { billgenbtn = value; }
        }
        public int Gst_Round
        {
            get { return gstround; }
            set { gstround = value; }
        }
        public int Charge_Round
        {
            get { return chargeround; }
            set { chargeround = value; }
        }
        public int Payment_Voucher
        {
            get { return paymentvoucher; }
            set { paymentvoucher = value; }
        }
        public int Debit_Note_Voucher
        {
            get { return debitnotevoucher; }
            set { debitnotevoucher = value; }
        }
        public int Credit_Note_Voucher
        {
            get { return creditnotevoucher; }
            set { creditnotevoucher = value; }
        }
        public int General_Voucher
        {
            get { return generalvoucher; }
            set { generalvoucher = value; }
        }
        public int Receipt_Voucher
        {
            get { return receiptvoucher; }
            set { receiptvoucher = value; }
        }
        public int Build_Wise_Payment
        {
            get { return buildwisepayment; }
            set { buildwisepayment = value; }
        }
        public int Remainder_Email_Dues
        {
            get { return remainderemaildues; }
            set { remainderemaildues = value; }
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
    }
}
