using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class staff
    {
        private int staffid;
        private string societyname;
        private string name;
        private string address;
        private string contactno;
        private string buildingname;
        private string email;
        private DateTime dateofjoin;
        private string societyid;
        private int bid;
        private int roleid;
        private string Role;
        private string terms;
        private int tid;
        private string Operation;
        private string Result;
        private string id;
        private Decimal salary;




        public Decimal Salary
        {
            get { return salary; }
            set { salary = value; }
        }
        public int staff_id
        {
            get { return staffid; }
            set { staffid = value; }
        }
        public int role_id
        {
            get { return roleid; }
            set { roleid = value; }
        }
        public string role
        {
            get { return Role; }
            set { Role = value; }
            
        }
        public string id_proof
        {
            get { return id; }
            set { id = value; }
            
        }
        public string Society_Name
        {
            get { return societyname; }
            set { societyname = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Address
        {
            get { return address; }
            set { address = value; }
        }
        public string Contact_No
        {
            get { return contactno; }
            set { contactno = value; }
        }
        public string Building_Name
        {
            get { return buildingname; }
            set { buildingname = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public DateTime Date_Of_Join
        {
            get { return dateofjoin; }
            set { dateofjoin = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }
      
        public int term_id
        {
            get { return tid; }
            set { tid = value; }
        }
        public string Terms
        {
            get { return terms; }
            set { terms = value; }
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