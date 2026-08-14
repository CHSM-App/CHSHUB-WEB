using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Wing
    {
        private int wid;
        private string wname;
        private string bname;
        private int bid;
        private string societyid;
        private string Operation;
        private string Result;



        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public string W_Name
        {
            get { return wname; }
            set { wname = value; }
        }
        public string B_Name
        {
            get { return bname; }
            set { bname = value; }
        }
        public int build_id
        {
            get { return bid; }
            set { bid = value; }
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