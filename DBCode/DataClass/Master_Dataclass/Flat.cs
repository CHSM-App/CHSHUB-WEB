using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Flat
    {
        private int fid;
        private int b_id;
        private string societyid;
        private int wid;
        private int usageid;
        private int bedid;
        private int bed;
        private string flattype;
        private string b_name;
        private string w_name;
        private string flatno;
        private string sqft;
        private string usage;
        private string terracesqft;
        private string intercomno;
        private string flatstatus;
        private string Operation;
        private string Result;

        public int flat_id
        {
            get { return fid; }
            set { fid = value; }
        }
        public int build_id
        {
            get { return b_id; }
            set { b_id = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string W_Name
        {
            get { return w_name; }
            set { w_name = value; }
        }
        public string B_Name
        {
            get { return b_name; }
            set { b_name = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public int Usage_Id
        {
            get { return usageid; }
            set { usageid = value; }
        }
        public int bed_id
        {
            get { return bedid; }
            set { bedid= value; }
        }
        public int Bed
        {
            get { return bed; }
            set { bed = value; }
        }

        public string flat_type_id
        {
            get { return flattype; }
            set { flattype= value; }
        }
        public string Flat_No        
        {
            get { return flatno; }
            set { flatno = value; }
        }
        public string Sq_Ft
        {
            get { return sqft; }
            set { sqft = value; }
        }
        public string Usage
        {
            get { return usage; }
            set { usage = value; }
        }
        public string Terrace_Sq_Ft
        {
            get { return terracesqft; }
            set { terracesqft = value; }
        }
        public string Intercom_No
        {
            get { return intercomno; }
            set { intercomno = value; }
        }
        public string Flat_Status
        {
            get { return flatstatus; }
            set { flatstatus = value; }
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