using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{ 
    public class pdc_reminder
    {
        private int pid;
        private int oid;
        private string oname;
        private int bid;
        private int wid;
        private int chqno;
        private float cheamount;
        private DateTime chedate;
        private int chedep;
        private int cheret;
        private int checan;
        private string societyid;
        private float ownerdue;
        private string preaddr1;
        private string preaddr2;
        private string premob;
        private string altermob;
        private string email;
        private DateTime startdate;
        private DateTime enddate;
        private string Operation;
        private string Result;
        private string search;

        public int pdc_rem_id
        {
            get { return pid; }
            set { pid = value; }
        }
        public int owner_id
        {
            get { return oid; }
            set { oid = value; }
        }

        public string O_Name
        {
            get { return oname; }
            set { oname = value; }
        }

        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }

        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public int Chq_No
        {
            get { return chqno; }
            set { chqno = value; }
        }
        public float Che_Amount
        {
            get { return cheamount; }
            set { cheamount = value; }
        }
        public DateTime Che_Date
        {
            get { return chedate; }
            set { chedate = value; }
        }
        public int Che_Dep
        {
            get { return chedep; }
            set { chedep = value; }
        }
        public int Che_Ret
        {
            get { return cheret; }
            set { cheret = value; }
        }
        public int Che_Can
        {
            get { return checan; }
            set { checan = value; }
        }
        public String Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public float Owner_Due
        {
            get { return ownerdue; }
            set { ownerdue = value; }
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
        public string Pre_Mob
        {
            get { return premob; }
            set { premob = value; }
        }
        public string Alter_Mob
        {
            get { return altermob; }
            set { altermob = value; }
        }
        public string Pre_Addr1
        {
            get { return preaddr1; }
            set { preaddr1 = value; }
        }
        public string Pre_Addr2
        {
            get { return preaddr2; }
            set { preaddr2 = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public DateTime Start_Date
        {
            get { return startdate; }
            set { startdate = value; }
        }
        public DateTime End_Date
        {
            get { return enddate; }
            set { enddate = value; }
        }
        public String Search
        {
            get { return search; }
            set { search = value; }
        }
    }
}