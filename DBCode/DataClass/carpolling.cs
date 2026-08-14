using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class carpolling
    {
        private int carid;
        private string cname;
        private string vehicalno;
        private string seat;
        private DateTime time;
        private DateTime date;
        private string destination;
        private string charges;
        private string societyid;
        private string Operation;
        private string Result;



        public int Car_Id
        {
            get { return carid; }
            set { carid = value; }
        }
        public string C_Name
        {
            get { return cname; }
            set { cname = value; }
        }
        public string Vehical_No
        {
            get { return vehicalno; }
            set { vehicalno = value; }
        }
        public string Seat
        {
            get { return seat; }
            set { seat = value; }
        }
        public DateTime Time
        {
            get { return time; }
            set { time = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public string Destination
        {
            get { return destination; }
            set { destination = value; }
        }
        public string Charges
        {
            get { return charges; }
            set { charges = value; }
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