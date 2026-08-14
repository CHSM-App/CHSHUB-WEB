using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class types
    {
        private int ftid;
        private string type;
        private string Operation;
        private string Result;
        public int Ft_Id
        {
            get { return ftid; }
            set { ftid = value; }
        }
        public string Type
        {
            get { return type; }
            set { type = value; }
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