using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Caretaker
    {
        private int caretakerid;
        private string cname;
        private int docid;
        private string caddress;
        private string area;
        private string city;
        private string pincode;
        private int stateid;
        private string mobileno;
        private string email;
        private string docexecuted;
        private string societyid;
        private int wid;
        private string flatno;
        private string Operation;
        private string Result;

        public int Caretaker_Id
        {
            get { return caretakerid; }
            set { caretakerid = value; }
        }
        public string C_Name
        {
            get { return cname; }
            set { cname = value; }
        }
        public int doc_id
        {
            get { return docid; }
            set { docid = value; }
        }
        public string C_Address
        {
            get { return caddress; }
            set { caddress = value; }
        }
        public string Area
        {
            get { return area; }
            set { area = value; }
        }
        public string City
        {
            get { return city; }
            set { city = value; }
        }
        public string Pincode
        {
            get { return pincode; }
            set { pincode = value; }
        }
        public int State_Id
        {
            get { return stateid; }
            set { stateid = value; }
        }
        public string Mobile_No
        {
            get { return mobileno; }
            set { mobileno = value; }

        }
        public string Email
        {
            get { return email; }
            set { email = value; }

        }
        public string Doc_Executed
        {
            get { return docexecuted; }
            set { docexecuted = value; }

        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }

        }
        public int Wing_Id
        {
            get { return wid; }
            set { wid = value; }

        }
        public string Flat_No
        {
            get { return flatno; }
            set { flatno = value; }

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