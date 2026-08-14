using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Suggestion_Request
    {
        private int sugid;
        private string details;
        private string Operation;
        private string Result;

        public int Sug_Id
        {
            get { return sugid; }
            set { sugid = value; }
        }
        public string Details
        {
            get { return details; }
            set { details = value; }
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