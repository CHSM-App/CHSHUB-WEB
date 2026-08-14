using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Adv_Payment
    {
        private int payid;
        private string payno;
        private DateTime paydate;
        private int oid;
        private string ownername;
        private int bid;
        private int wid;
        private float amount;
        private string remark;
        private string Operation;
        private string Result;

        public int Pay_Id
        {
            get { return payid; }
            set { payid = value; }
        }
        public string Pay_No
        {
            get { return payno; }
            set { payno = value; }
        }

        public DateTime Pay_Date
        {
            get { return paydate; }
            set { paydate = value; }
        }

        public int O_Id
        {
            get { return oid; }
            set { oid = value; }
        }

        public string Owner_Name
        {
            get { return ownername; }
            set { ownername = value; }
        }

        public int B_Id
        {
            get { return bid; }
            set { bid = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public float Amount
        {
            get { return amount; }
            set { amount = value; }
        }
        public string Remark
        {
            get { return remark; }
            set { remark = value; }
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