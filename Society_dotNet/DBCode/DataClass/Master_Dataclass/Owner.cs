using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Owner
    {
        private int oid;
        private string societyid;
        private string type;
        private DateTime possdate;
        private string name;
        private string w_name;
        private string preaddr1;
        private string preadd2;
        private string premob;
        private string altermob;
        private string email;
        private int age;
        private int marriedid;
        private int ftid;
        private DateTime? dob;
        private int fid;
        private string occup;
        private string monthlyincome;
        private string offaddr1;
        private string offaddr2;
        private string offtel;
        private string idproof;
        private string photoname;
        private int wid;
        private DateTime aggrementdate;
        private DateTime aggrementperiodfrom;
        private DateTime aggrementperiodto;
        private DateTime policeverificationdate;
        private string flatno;
        private string Operation;
        private string Result;


        //runproc_F

        private int oexid;
        private string fname;
        private string relation;
        private string foccu;
        private string fdob;
        private int docid;


         //Village_Owner

        private int village_owner_id;
        private int houseno;
        private string housetype;
        private decimal sq_ft;
        private string address;
        private int state_id;
        private int district_id;
        private int taluka_id;
        private string village_id;
        private string address_line1;


        //house_tax_receipt

        private int house_receipt_id;
        private DateTime pay_date;
        private Decimal house_tax;
        private Decimal paid_amount;
        private int pay_mode;
        private Decimal balance;
        private string chqno;
        private DateTime chqdate;
        private Decimal chqamount;
        private string receipt_no;
        private float advance;

        private String police_verification_path;
        private String agreement_latter_path;


    public int owner_id
        {
            get { return oid; }
            set { oid = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Police_ver_path
        {
            get { return police_verification_path; }
            set { police_verification_path = value; }
        }
        public string Aggreement_path
        {
            get { return agreement_latter_path; }
            set { agreement_latter_path = value; }
        }
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
        public DateTime Poss_Date
        {
            get { return possdate; }
            set { possdate = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string W_Name
        {
            get { return w_name; }
            set { w_name = value; }
        }
        public string Pre_Addr1
        {
            get { return preaddr1; }
            set { preaddr1 = value; }
        }
        public string Pre_Addr2
        {
            get { return preadd2; }
            set { preadd2 = value; }
        }
        public string Pre_Mob
        {
            get { return premob; }
            set { premob = value; }
        }
        public string Alter_Mob
        {
            get { return altermob; }
            set { altermob = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public int Age
        {
            get { return age; }
            set { age = value; }
        }
        public int married_id
        {
            get { return marriedid; }
            set { marriedid = value; }
        }
        public int Flat_type_Id
        {
            get { return ftid; }
            set { ftid = value; }
        }
        public DateTime? Dob
        {
            get { return dob; }
            set { dob = value; }
        }
        public int flat_id
        {
            get { return fid; }
            set { fid = value; }
        }
        public string Occup
        {
            get { return occup; }
            set { occup = value; }
        }
        public string Monthly_Income
        {
            get { return monthlyincome; }
            set { monthlyincome = value; }
        }
        public string Off_Addr1
        {
            get { return offaddr1; }
            set { offaddr1 = value; }
        }
        public string Off_Addr2
        {
            get { return offaddr2; }
            set { offaddr2 = value; }
        }
        public string Off_Tel
        {
            get { return offtel; }
            set { offtel = value; }
        }
        public string Id_Proof
        {
            get { return idproof; }
            set { idproof = value; }
        }
        public string Photo_Name
        {
            get { return photoname; }
            set { photoname = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public DateTime Aggrement_Date
        {
            get { return aggrementdate; }
            set { aggrementdate = value; }
        }
        public DateTime Aggrement_Period_From
        {
            get { return aggrementperiodfrom; }
            set { aggrementperiodfrom = value; }
        }
             public DateTime Aggrement_Period_To
        {
            get { return aggrementperiodto; }
            set { aggrementperiodto = value; }
        }
        public DateTime Police_Verification_Date
        
        {
            get { return policeverificationdate; }
            set { policeverificationdate = value; }
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


        //runproc F

        public int O_Ex_Id
        {
            get { return oexid; }
            set { oexid = value; }
        }
        public string F_Name
        {
            get { return fname; }
            set { fname = value; }
        }
        public string Relation
        {
            get { return relation; }
            set { relation = value; }
        }
        public string F_Occu
        {
            get { return foccu; }
            set { foccu = value; }
        }
        public string F_Dob
        {
            get { return fdob; }
            set { fdob = value; }
        }

        public int Doc_Id
        {
            get { return docid; }
            set { docid = value; }
        }

        //Village_Owner

        public int Village_Owner_id
        {
            get { return village_owner_id; }
            set { village_owner_id = value; }
        }
        public int House_No
        {
            get { return houseno; }
            set { houseno = value; }
        }
        public string House_Type
        {
            get { return housetype; }
            set { housetype = value; }
        }
        public decimal Sq_Ft
        {
            get { return sq_ft; }
            set { sq_ft = value; }
        }
        public string Address
        {
            get { return address; }
            set { address = value; }
        }
        public int State_Id
        {
            get { return state_id; }
            set { state_id = value; }
        }
        public int District_Id
        {
            get { return district_id; }
            set { district_id = value; }
        }
        public int Taluka_Id
        {
            get { return taluka_id; }
            set { taluka_id = value; }
        }
        public string Village_Id
        {
            get { return village_id; }
            set { village_id = value; }
        }
        public string Address_Line1
        {
            get { return address_line1; }
            set { address_line1 = value; }
        }


        //house_tax_receipt
        public int House_Receipt_Id
        {
            get { return house_receipt_id; }
            set { house_receipt_id = value; }
        }
        public DateTime Pay_Date
        {
            get { return pay_date; }
            set { pay_date = value; }
        }
        public Decimal House_Tax
        {
            get { return house_tax; }
            set { house_tax = value; }
        }
        public Decimal Paid_Amount
        {
            get { return paid_amount; }
            set { paid_amount = value; }
        }
        public int Pay_Mode
        {
            get { return pay_mode; }
            set { pay_mode = value; }
        }
        public Decimal Balance
        {
            get { return balance; }
            set { balance = value; }
        }
        public string Chqno
        {
            get { return chqno; }
            set { chqno = value; }
        }
        public Decimal Chq_Amount
        {
            get { return chqamount; }
            set { chqamount = value; }
        }
        public DateTime Chqdate
        {
            get { return chqdate; }
            set { chqdate = value; }
        }
        public string Receipt_No
        {
            get { return receipt_no; }
            set { receipt_no = value; }
        }
        public float Advance
        {
            get { return advance; }
            set { advance = value; }
        }
    }
}

