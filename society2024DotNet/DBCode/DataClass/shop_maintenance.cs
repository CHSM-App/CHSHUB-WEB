using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class Shop_Maintenance
    {
        private int mid;
        private string mrepno;
        private DateTime mdate;
        private int ledid;
        private string otherdetails;
        private int amt;
        private string paymethod;
        private string cheqno;
        private DateTime cheqdate;
        private string societyid;
        private string Operation;
        private string Result;
        private string search;


        public int shop_maint_id
        {
            get { return mid; }
            set { mid = value; }
        }
        public string Mrep_No
        {
            get { return mrepno; }
            set { mrepno = value; }
        }
        public DateTime M_Date
        {
            get { return mdate; }
            set { mdate = value; }
        }
        public int led_id
        {
            get { return ledid; }
            set { ledid = value; }
        }
        public string Other_Details
        {
            get { return otherdetails; }
            set { otherdetails = value; }
        }
        public int Amt
        {
            get { return amt; }
            set { amt = value; }
        }
        public string Pay_Method
        {
            get { return paymethod; }
            set { paymethod = value; }
        }
        public string Cheq_No
        {
            get { return cheqno; }
            set { cheqno = value; }
        }
        public DateTime Cheq_Date
        {
            get { return cheqdate; }
            set { cheqdate = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
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

    }
}