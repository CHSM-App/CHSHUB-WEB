using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class person_type
    {
        private int tid;
        private string tname;
        private string Operation;
        private string Result;

        public int T_Id
        {
            get { return tid; }
            set { tid = value; }
        }

        public string T_Name
        {
            get { return tname; }
            set { tname = value; }
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