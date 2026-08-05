using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class bedroom
    {
        private int bedid;
        private string bed;
        private string Operation;
        private string Result;
        public int Bed_Id
        {
            get { return bedid; }
            set { bedid = value; }
        }

        public string Bed
        {
            get { return bed; }
            set { bed = value; }
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