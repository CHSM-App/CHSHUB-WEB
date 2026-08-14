using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class homeModal
    {
        private int hid;
        private string owner;
        private string hno;
        private int sqft;
        private decimal sqftCharge;
        private int taps;
        private decimal tapCharge;
        private decimal wasteFee;
        private string operation;
        private string result;
        private int houseType;
        private string villageId;
        private string house_add;
        private string mobile_no;
        private int v_o_id;
        private int user_id;

        // ===========================
        //      PUBLIC PROPERTIES
        // ===========================

        //house_add, mobile_no

        public int UserId
        {
            get { return user_id; }
            set { user_id = value; }
        }

        public int village_owner_id
        {
            get { return v_o_id; }
            set { v_o_id = value; }
        }
        public string address
        {
            get { return house_add; }
            set { house_add = value; }
        }

        public string phone
        {
            get { return mobile_no; }
            set { mobile_no = value; }
        }

        public string Village_id
        {
            get { return villageId; }
            set { villageId = value; }
        }
        public int House_type
        {
            get { return houseType; }
            set { houseType = value; }
        }

        public int House_Id
        {
            get { return hid; }
            set { hid = value; }
        }

        public string Owner_Name
        {
            get { return owner; }
            set { owner = value; }
        }

        public string House_No
        {
            get { return hno; }
            set { hno = value; }
        }

        public int House_Sqft
        {
            get { return sqft; }
            set { sqft = value; }
        }

        public decimal Sqft_Charges
        {
            get { return sqftCharge; }
            set { sqftCharge = value; }
        }

        public int No_Of_Taps
        {
            get { return taps; }
            set { taps = value; }
        }

        public decimal Tap_Charges
        {
            get { return tapCharge; }
            set { tapCharge = value; }
        }

        public decimal Solid_Waste_Fee
        {
            get { return wasteFee; }
            set { wasteFee = value; }
        }

        public string Sql_Operation
        {
            get { return operation; }
            set { operation = value; }
        }

        public string Sql_Result
        {
            get { return result; }
            set { result = value; }
        }
    }
}