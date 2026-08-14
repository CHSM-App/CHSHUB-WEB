using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class facility
    {
        private int pid;
        private int oid;
        private DateTime bookdate;
        private DateTime fromdate;
        private DateTime todate;
        private string name;
        private int flatno;
        private string address;
        private string contact;
        private int societyin;
        private DateTime fromtime;
        private DateTime totime;

        private int fac_id;
        private decimal cost;
        private string unit;
        private string description;
        private string note;
        private int flat_id;
        private int slot_id;
        private int slot;
        private DateTime start_time;
        private DateTime end_time;
        //private int facility_id;

        private string societyid;
        private string Operation;
        private string Result;
        private bool isActive;

        private int capacity;


        public int Flat_id
        {
            get { return flat_id; }
            set { flat_id = value; }
        }
        public bool IsActive
        {
            get { return isActive; }
            set { isActive = value; }
        }
        public int Max_capacity
        {
            get { return capacity; }
            set { capacity = value; }
        }

        public int facility_book_id
        {
            get { return pid; }
            set { pid = value; }
        }
        public int owner_id
        {
            get { return oid; }
            set { oid = value; }
        }
        public DateTime Book_Date
        {
            get { return bookdate; }
            set { bookdate = value; }
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
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public int Flat_No
        {
            get { return flatno; }
            set { flatno = value; }
        }
        public string Address
        {
            get { return address; }
            set { address = value; }
        }
        public string Contact
        {
            get { return contact; }
            set { contact = value; }
        }
        public int Society_In
        {
            get { return societyin; }
            set { societyin = value; }
        }
        public DateTime From_Time
        {
            get { return fromtime; }
            set { fromtime = value; }
        }
        public DateTime To_Time
        {
            get { return totime; }
            set { totime = value; }
        }
        public int facility_id
        {
            get { return fac_id; }
            set { fac_id = value; }
        }
        public decimal Cost
        {
            get { return cost; }
            set { cost = value; }
        }
        public string Unit
        {
            get { return unit; }
            set { unit = value; }
        }
        public string Description
        {
            get { return description; }
            set { description = value; }
        }
        public string Note
        {
            get { return note; }
            set { note = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public int Slot_Id
        {
            get { return slot_id; }
            set { slot_id = value; }
        }
        public int Slot
        {
            get { return slot; }
            set { slot = value; }
        }
        public DateTime Start_Time
        {
            get { return start_time; }
            set {start_time = value; }
        }
        public DateTime End_Time
        {
            get { return end_time; }
            set { end_time = value; }
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