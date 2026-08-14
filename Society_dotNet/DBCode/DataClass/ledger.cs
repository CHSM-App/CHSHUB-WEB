using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Ledger
    {
        private int ledid;
        private string leddescription;
        private string ledstatus;
        private string societyid;
        private string Operation;
        private string Result;
        private string search;


        public int led_id
        {
            get { return ledid; }
            set { ledid = value; }
        }
        public string Led_Description
        {
            get { return leddescription; }
            set { leddescription = value; }
        }
        public string Led_Status
        {
            get { return ledstatus; }
            set { ledstatus = value; }
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
        public string Search
        {
            get { return search; }
            set { search = value; }
        }



    }
}