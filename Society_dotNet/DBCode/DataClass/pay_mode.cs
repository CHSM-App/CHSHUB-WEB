using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class pay_mode
    {
        private int payid;
        private string paymode;
        private string Operation;
        private string Result;

        public int Pay_Id
        {
            get { return payid; }
            set { payid = value; }
        }
        public string Pay_Mode
        {
            get { return paymode; }
            set { paymode = value; }
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