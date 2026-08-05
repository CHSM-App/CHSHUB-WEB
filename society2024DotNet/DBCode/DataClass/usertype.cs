using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class usertype
    {
        private int usertypeid;
        private string usertypename;
        private int depid;
        private string dashboard;
        private string Operation;
        private string Result;

        public int UserTypeId
        {
            get { return usertypeid; }
            set { usertypeid = value; }
        }
        public string UserTypeName
        {
            get { return usertypename; }
            set { usertypename = value; }
        }
        public int DepID
        {
            get { return depid; }
            set { depid = value; }
        }
        public string Dashboard
        {
            get { return dashboard; }
            set { dashboard = value; }
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