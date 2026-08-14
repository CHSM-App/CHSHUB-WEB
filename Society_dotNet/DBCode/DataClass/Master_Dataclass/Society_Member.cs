using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Society_Member
    {
        private int userid;
        private string name;
        private int designation;
        private string address1;
        private int address2;
        private string contactno;
        private string email;
        private string societyid;
        private string username;
        private string password;
        private int status;
        private string Operation;
        private string Result;
        private int approval_id;
        private string remark;

        public string Remark
        {
            get { return remark; }
            set { remark = value; }
        }
        public int Approval_id
        {
            get { return approval_id; }
            set { approval_id = value; }
        }
        public int UserId
        {
            get { return userid; }
            set { userid = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public int Designation
        {
            get { return designation; }
            set { designation = value; }
        }
        public string role
        {
            get { return address1; }
            set { address1 = value; }
        }
        public int Owner_id
        {
            get { return address2; }
            set { address2 = value; }
        }
        public string Contact_No
        {
            get { return contactno; }
            set { contactno = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public string UserName
        {
            get { return username; }
            set { username = value; }
        }
        public string Password
        {
            get { return password; }
            set { password = value; }
        }
        public int Status
        {
            get { return status; }
            set { status = value; }
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