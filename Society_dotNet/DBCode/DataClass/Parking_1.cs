using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Parking_1
    {
        private int placeid;
        private string parkfor;
        private string parkingno;
        private string societyid;
        private string Operation;
        private string Result;
        private string name;


        public int place_id
        {
            get { return placeid; }
            set { placeid = value; }
        }
        public string Park_For
        {
            get { return parkfor; }
            set { parkfor = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Parking_No
        {
            get { return parkingno; }
            set { parkingno = value; }
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