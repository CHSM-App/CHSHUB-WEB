using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class State
    {
        private int stateid;
        private string state;
        private string Operation;
        private string Result;
        public int State_Id
        {
            get { return stateid; }
            set { stateid = value; }
        }
        public string States
        {
            get { return state; }
            set { state = value; }
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