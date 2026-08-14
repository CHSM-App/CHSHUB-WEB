using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class visiting_type
    {
        private int vtypeid;
        private string vtypename;
        private string Operation;
        private string Result;

        public int V_Type_Id
        {
            get { return vtypeid; }
            set { vtypeid = value; }
        }
        public string V_Type_Name
        {
            get { return vtypename; }
            set { vtypename = value; }
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