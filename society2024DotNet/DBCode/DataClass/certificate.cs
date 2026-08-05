using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class certificate
    {
        private int cid;
        private string cname;
        private string Operation;
        private string Result;

        public int C_Id
        {
            get { return cid; }
            set { cid = value; }

        }
        public string C_Name
        {
            get { return cname; }
            set { cname = value; }

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