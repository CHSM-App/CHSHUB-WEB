using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Visitor
    {

        private int vid;
        private string vname;
        private string vtype;
        private string orgname;
        private string orgaddr1;
        private string orgaddr2;
        private string contact_no;
        private int fid;
        private string vpername;
        private DateTime indate;
        private DateTime outdate;
        private DateTime intime;
        private DateTime outtime;
        private string societyid;
        private int bid;
        private string vehical_no;
        private string visiting_purpose;
        private string preference;
        private string image;
        private string Operation;
        private string Result;
        private string Company;
        private string Location;
        private string Imgpath;



        public int visitor_id
        {
            get { return vid; }
            set { vid = value; }
        }
        public string V_Name
        {
            get { return vname; }
            set { vname = value; }
        }
        public string V_Type
        {
            get { return vtype; }
            set { vtype = value; }
        }  
        public string company
        {
            get { return Company; }
            set { Company = value; }
        }
        public string location
        {
            get { return Location; }
            set { Location = value; }
        }
        public string imgpath
        {
            get { return Imgpath; }
            set { Imgpath = value; }
        }
        public string Org_Name
        {
            get { return orgname; }
            set { orgname = value; }
        }
        public string Org_Addr1
        {
            get { return orgaddr1; }
            set { orgaddr1 = value; }
        }
        public string Org_Addr2
        {
            get { return orgaddr2; }
            set { orgaddr2 = value; }
        }
        public string Contact_No
        {
            get { return contact_no; }
            set { contact_no = value; }
        }
        public int flat_id
        {
            get { return fid; }
            set { fid = value; }
        }
        public string V_Per_Name
        {
            get { return vpername; }
            set { vpername = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public DateTime In_Date
        {
            get { return indate; }
            set { indate = value; }
        }
        public DateTime Out_Date
        {
            get { return outdate; }
            set { outdate = value; }
        }
        public DateTime In_Time
        {
            get { return intime; }
            set { intime = value; }
        }
        public DateTime Out_Time
        {
            get { return outtime; }
            set { outtime = value; }
        }
        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }

        public string Vehical_No
        {
            get { return vehical_no; }
            set { vehical_no = value; }
        }
        public string Visiting_Purpose
        {
            get { return visiting_purpose; }
            set { visiting_purpose = value; }
        }
        public string Preference
        {
            get { return preference; }
            set { preference = value; }
        }

        public string Image
        {
            get { return image; }
            set { image = value; }
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