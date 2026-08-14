using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Search_Society
    {
        private int unit;
        private int sid;
        private string name;
        private DateTime establishdate;
        private string registrationno;
        private string offaddress1;
        private string offaddress2;
        private string contactno1;
        private string email;
        private string societyid;
        private string city;
        private int stateid;
        private string pincode;
        private int homeno;
        private string division;
        private int district;
        private string tanno;
        private string gstinno;
        private string panno;
        private int charge_id;
        private string amount;
        private string Operation;
        private string Result;
        private int comment_id;
        private int owner_id;
        private int helpdesk_id;
        private string comment;
        private int status;
        private int urgent;
        private DateTime date;
        private string type;
        private int flat_id;
        private string fireToket;


        public string token
        {
            get { return fireToket; }
            set { fireToket = value; }
        }


        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
        public int urgency
        {
            get { return urgent; }
            set { urgent = value; }
        }
        public int flatId
        {
            get { return flat_id; }
            set { flat_id = value; }
        }
        public int commentId
        {
            get { return comment_id; }
            set { comment_id = value; }
        }

        public int ownerId
        {
            get { return owner_id; }
            set { owner_id = value; }
        }

        public int helpdeskId
        {
            get { return helpdesk_id; }
            set { helpdesk_id = value; }
        }
        public string Comment
        {
            get { return comment; }
            set { comment = value; }
        }

        public int Status
        {
            get { return status; }
            set { status = value; }
        }

        public int total_unit
        {
            get { return unit; }
            set { unit = value; }
        }

        public int society_master_id
        {
            get { return sid; }
            set { sid = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public int Charge_Id
        {
            get { return charge_id; }
            set { charge_id = value; }
        }
        public string Amount
        {
            get { return amount; }
            set { amount = value; }
        }
        public DateTime Establish_Date
        {
            get { return establishdate; }
            set { establishdate = value; }
        }
        public string Registration_No
        {
            get { return registrationno; }
            set { registrationno = value; }
        }
        public string Off_Address1
        {
            get { return offaddress1; }
            set { offaddress1 = value; }
        }
        public string Off_Address2
        {
            get { return offaddress2; }
            set { offaddress2 = value; }
        }
        public string Contact_No1
        {
            get { return contactno1; }
            set { contactno1 = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string City
        {
            get { return city; }
            set { city = value; }
        }
        public int State_Id
        {
            get { return stateid; }
            set { stateid = value; }
        }
        public string Pincode
        {
            get { return pincode; }
            set { pincode = value; }
        }
        public int Home_No
        {
            get { return homeno; }
            set { homeno = value; }
        }
        public string Division
        {
            get { return division; }
            set { division = value; }
        }
        public int District_Id
        {
            get { return district; }
            set { district = value; }
        }
        public string Tan_No
        {
            get { return tanno; }
            set { tanno = value; }
        }
        public string Gstin_No
        {
            get { return gstinno; }
            set { gstinno = value; }
        }
        public string Pan_No
        {
            get { return panno; }
            set { panno = value; }
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