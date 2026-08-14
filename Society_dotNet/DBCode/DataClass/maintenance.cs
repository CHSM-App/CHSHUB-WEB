using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class maintenance
    {
        private int mid;
        private int Flag;
        private string SocietyId;
        private string mname;
        private string name;
        private string wname;
        private float mamount;
        private bool status;
        private int bid;
        private int buildid;
        private decimal mtotal;
        private string flatno;
        private int flat;
        private string Operation;
        private string Result;
        private int id;
        private int billno;
        private int nmid;
        private DateTime gendate;
        private DateTime duedate;
        private decimal totalamount;
        private decimal amount_per_flat;
        private string nature_of_charge;
        private int oid;
        private string ownername;
        private int amountpaid;
        private string paymentmethod;
        private int wid;
        private DateTime mdate;
        private DateTime date;
        private DateTime date1;
        private DateTime date2;
        private decimal due;
        private int Type;
        private int period;

        private int per_sqf_rate;
        private int two_w_rate;
        private int fourf_w_rate;
        private int gen_date;
        private int due_dat;
        private bool auto_gen;

        private String amount;
        private int creater_id;
        private bool bill_type;
        private int charges_id;
        
        private string description;


        public string Description
        {
            get { return description; }
            set { description = value; }
        }


        public string owner_name
        {
            get { return ownername; }
            set { ownername = value; }
        }

        
        

        public int due_period
        {
            get { return period; }
            set { period = value; }
        }
        public int Charges_id
        {
            get { return charges_id; }
            set { charges_id = value; }
        }
        public bool BillType
        {
            get { return bill_type; }
            set { bill_type = value; }
        }
        public int Creator
        {
            get { return creater_id; }
            set { creater_id = value; }
        }

        public int type
        {
            get { return Type; }
            set { Type = value; }
        }

        public string flat_no
        {
            get { return flatno; }
            set { flatno = value; }
        }

        public string wing_name
        {
            get { return wname; }
            set { wname = value; }
        }

        public int mon_charge_id
        {
            get { return id; }
            set { id = value; }
        }
        public int flag
        {
            get { return Flag; }
            set { Flag = value; }
        }
        public int n_m_id
        {
            get { return nmid; }
            set { nmid = value; }
        }
        public int Bill_No
        {
            get { return billno; }
            set { billno = value; }
        }
      
        public DateTime Gen_Date
        {
            get { return gendate; }
            set { gendate = value; }
        }
        public DateTime Due_Date
        {
            get { return duedate; }
            set { duedate = value; }
        }
        public decimal Add_OnAmount
        {
            get { return totalamount; }
            set { totalamount = value; }
        }
        public decimal RegularAmount
        {
            get { return amount_per_flat; }
            set { amount_per_flat = value; }
        }
        public string Nature_Of_Charge
        {
            get { return nature_of_charge; }
            set { nature_of_charge = value; }
        }
        public int owner_id
        {
            get { return oid; }
            set { oid = value; }
        }
        public string Owner_Name
        {
            get { return ownername; }
            set { ownername = value; }
        }
        public int Amount_Paid
        {
            get { return amountpaid; }
            set { amountpaid = value; }
        }
        public string Payment_Method
        {
            get { return paymentmethod; }
            set { paymentmethod = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }

        public int Flat
        {
            get { return flat; }
            set { flat = value; }
        }
        public DateTime M_Date
        {
            get { return mdate; }
            set { mdate = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public DateTime Date_1
        {
            get { return date1; }
            set { date1 = value; }
        }
        public DateTime Date_2
        {
            get { return date2; }
            set { date2 = value; }
        }
        public decimal Due
        {
            get { return due; }
            set { due = value; }
        }


        public int shop_maint_id
        {
            get { return mid; }
            set { mid = value; }
        }
        public string Society_Id
        {
            get { return SocietyId; }
            set { SocietyId = value; }
        }
       
        public string M_Name
        {
            get { return mname; }
            set { mname = value; }
        }

        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string W_Name
        {
            get { return wname; }
            set { wname = value; }
        }

        public float M_Amount
        {
            get { return mamount; }
            set { mamount = value; }
        }
        public bool Status
        {
            get { return status; }
            set { status = value; }
        }
        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }

        public decimal M_Total
        {
            get { return mtotal; }
            set { mtotal = value; }
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

        public int Per_Sqf_Rate
        {
            get { return per_sqf_rate; }
            set { per_sqf_rate = value; }
        }

        public int Two_W_Rate
        {
            get { return two_w_rate; }
            set { two_w_rate = value; }
        }

        public int Four_W_Rate
        {
            get { return fourf_w_rate; }
            set { fourf_w_rate = value; }
        }

        public int Gen_Date_Int
        {
            get { return gen_date; }
            set { gen_date = value; }
        }

        public int Due_Dat
        {
            get { return due_dat; }
            set { due_dat = value; }
        }

        public bool Auto_Gen
        {
            get { return auto_gen; }
            set { auto_gen = value; }
        }

        public string Amount
        {
            get { return amount; }
            set { amount = value; }
        }
    }
}