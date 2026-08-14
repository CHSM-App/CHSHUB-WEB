using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Parking
    {
        private int pid;
        private string name;
        private string parkfor;
        private string parktype;
        private int placeid;
        private DateTime fromdate;
        private DateTime todate;
        private string societyid;
        private string contactno;
        private string vehicleno;
        private string Operation;
        private string Result;
        private int vehicle_id;
        private int flat_id;


        public int flat_Id
        {
            get { return flat_id; }
            set { flat_id = value; }
        }

        public int vehicle_Id
        {
            get { return vehicle_id; }
            set { vehicle_id = value;  }
        }


        public int VehicleTypeID
        {
            get { return pid; }
            set { pid = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public string Park_For
        {
            get { return parkfor; }
            set { parkfor = value; }
        }

        public string Park_Type
        {
            get { return parktype; }
            set { parktype = value; }
        }

        public int place_id
        {
            get { return placeid; }
            set { placeid = value; }
        }
        public DateTime From_Date
        {
            get { return fromdate; }
            set { fromdate = value; }
        }
        public DateTime To_Date
        {
            get { return todate; }
            set { todate = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Contact_No
        {
            get { return contactno; }
            set { contactno = value; }
        }
        public string Vehicle_No
        {
            get { return vehicleno; }
            set { vehicleno = value; }
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