using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class married_status
    {
        private int marriedid;
        private string marriedname;
        private string Operation;
        private string Result;


        public int Married_Id
        {
            get { return marriedid; }
            set { marriedid = value; }
        }
        public string Married_Name
        {
            get { return marriedname; }
            set { marriedname = value; }
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