using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Asset
    {
        private int aid;
        private string aname;
        private float qty;
        private float amount;
        private string Operation;
        private string Result;

        public int A_Id
        {
            get { return aid; }
            set { aid = value; }
        }
        public string A_Name
        {
            get { return aname; }
            set { aname = value; }
        }
        public float Qty
        {
            get { return qty; }
            set { qty = value; }
        }
        public float Amount
        {
            get { return amount; }
            set { amount = value; }
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