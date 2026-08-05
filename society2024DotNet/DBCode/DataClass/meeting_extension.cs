using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class meeting_extension
    {
        private int meetexid;
        private int meetid;
        private string details;
        private string societyid;
        private string Operation;
        private string Result;

        public int Meet_Ex_Id
        {
            get { return meetexid; }
            set { meetexid = value; }
        }
        public int Meet_Id
        {
            get { return meetid; }
            set { meetid = value; }
        }
        public string Details
        {
            get { return details; }
            set { details = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
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