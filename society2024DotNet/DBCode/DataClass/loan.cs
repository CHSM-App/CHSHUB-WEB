using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Loan
    {
        private int loanid;
        private int fid;
        private string bank;
        private string nocissued;
        private int typeid;
        private DateTime societynoc;
        private DateTime loanclearance;
        private int cid;
        private string societyid;
        private string loantype;
        private string Operation;
        private string Result;
        private string name;


        public int loan_id
        {
            get { return loanid; }
            set { loanid = value; }
        }
        public int flat_id
        {
            get { return fid; }
            set { fid = value; }
        }
        public string Bank
        {
            get { return bank; }
            set { bank = value; }
        }
        public string Noc_Issued
        {
            get { return nocissued; }
            set { nocissued = value; }
        }
        public int Type_Id
        {
            get { return typeid; }
            set { typeid = value; }
        }
        public DateTime Society_Noc
        {
            get { return societynoc; }
            set { societynoc = value; }
        }
        public DateTime Loan_Clearance
        {
            get { return loanclearance; }
            set { loanclearance = value; }
        }
        public int cert_id
        {
            get { return cid; }
            set { cid = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        //Loan Type
        public string Loan_Type
        {
            get { return loantype; }
            set { loantype = value; }
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

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

    }
}