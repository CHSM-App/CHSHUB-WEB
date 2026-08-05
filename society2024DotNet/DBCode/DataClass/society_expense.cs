using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class Society_Expense
    {
        private int expenseid;
        private int approvarid;
        private int memid;
        private string invoiceno;
        private DateTime date;
        private string extype;
        private string exname;
        private string exdetails;
        private string comments;
        private string addmaintanance;
        private float amount;
        private float tax;
        private float tds;
        private float famount;
        private string societyid;
        private bool status;
        private string buildid;
        //private string vendor;
        private bool regular;
        private string Operation;
        private string Result;


        public int expense_id
        {
            get { return expenseid; }
            set { expenseid = value; }
        }
        public int Approvar_Id
        {
            get { return approvarid; }
            set { approvarid = value; }
        }
        public int User_Id
        {
            get { return memid; }
            set { memid = value; }
        }
        public string Invoice_No
        {
            get { return invoiceno; }
            set { invoiceno = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public string Ex_Type
        {
            get { return extype; }
            set { extype = value; }
        }
        public string Ex_Name
        {
            get { return exname; }
            set { exname = value; }
        }
        public string Ex_Details
        {
            get { return exdetails; }
            set { exdetails = value; }
        }
        public string Comments
        {
            get { return comments; }
            set { comments = value; }
        }
        public string Add_Maintanance
        {
            get { return addmaintanance; }
            set { addmaintanance = value; }
        }
        public float Amount
        {
            get { return amount; }
            set { amount = value; }
        }
        public float Tax
        {
            get { return tax; }
            set { tax = value; }
        }
        public float Tds
        {
            get { return tds; }
            set { tds = value; }
        }
        public float F_Amount
        {
            get { return famount; }
            set { famount = value; }
        }
      
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
       
        public bool Status
        {
            get { return status; }
            set { status = value; }
        }
        public string build_id
        {
            get { return buildid; }
            set { buildid = value; }
        }
        public bool Regular
        {
            get { return regular; }
            set { regular = value; }
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