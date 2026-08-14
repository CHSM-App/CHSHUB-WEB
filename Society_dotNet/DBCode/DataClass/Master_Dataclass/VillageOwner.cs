using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class VillageOwner
    {
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

        private string Operation;

        private string Result;
        private string type;
        private string premob;
        private string altermob;
        private string name;
        private string id_proof;
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
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Id_Proof
        {
            get { return id_proof; }
            set { id_proof = value; }
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
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
    }
}