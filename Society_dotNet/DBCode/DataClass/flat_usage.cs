using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class flat_usage
    {
        private int usageid;
        private string usage;
        private string Operation;
        private string Result;

        public int Usage_Id
        {
            get { return usageid; }
            set { usageid = value; }
        }
        public string Usage        {
            get { return usage; }
            set { usage = value; }
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