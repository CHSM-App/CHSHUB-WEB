using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Building
    {
        private int buildid;
        private string name;
        private string address1;
        private string address2;
        private int nooffloore;
        private string printname;
        private string registrationno;
        private string societyid;
        private string bankname;
        private string bankadd;
        private string branch;
        private string ifsccode;
        private string accno;
        private string email;
        private string Operation;
        private string Result;

        public int build_id
        {
            get { return buildid; }
            set { buildid = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Address1
        {
            get { return address1; }
            set { address1 = value; }
        }
        public string Address2
        {
            get { return address2; }
            set { address2 = value; }
        }
        public int No_Of_Floore
        {
            get { return nooffloore; }
            set { nooffloore = value; }
        }
        public string Print_Name
        {
            get { return printname; }
            set { printname = value; }
        }
        public string Registration_No
        {
            get { return registrationno; }
            set { registrationno = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Bank_Name
        {
            get { return bankname; }
            set { bankname = value; }
        }
        public string Bank_Add
        {
            get { return bankadd; }
            set { bankadd = value; }
        }
        public string Branch
        {
            get { return branch; }
            set { branch = value; }
        }
        public string Ifsc_Code
        {
            get { return ifsccode; }
            set { ifsccode = value; }
        }
             public string Acc_No
        {
            get { return accno; }
            set { accno = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
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
