using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class usefull_Contact
    {
        private int id;
        private string pname;
        private int ptype;
        private string orgname;
        private string contactno;
        private string contactaddress;
        private string address2;
        private string email;
        private string remark;
        private string societyid;
        private string Operation;
        private string Result;
        private string idPath;


        public int usefull_contact_id
        {
            get { return id; }
            set { id = value; }
        }
        public string P_Name
        {
            get { return pname; }
            set { pname = value; }
        }
        public string id_path
        {
            get { return idPath; }
            set { idPath = value; }
        }
        public int P_Type
        {
            get { return ptype; }
            set { ptype = value; }
        }
        public string Org_Name
        {
            get { return orgname; }
            set { orgname = value; }
        }
        public string Contact_No
        {
            get { return contactno; }
            set { contactno = value; }
        }
        public string Contact_Address
        {
            get { return contactaddress; }
            set { contactaddress = value; }
        }
        public string Address2
        {
            get { return address2; }
            set { address2 = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public string Remark
        {
            get { return remark; }
            set { remark = value; }
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