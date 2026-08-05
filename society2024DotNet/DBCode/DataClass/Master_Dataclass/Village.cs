using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Village
    {
        private string name;
        private string contact_no;
        private string email;
        private string village_id;
        private int id;
        private int state_id;
        private int pincode;
        private int district_id;
        private string division;
        private DateTime enrolment_date;
        private DateTime termination_date;
        private DateTime bill_generation_date;
        private string Operation;
        private string Result;
        private int sq_rate_id;
        private int house_no;
        private string house_type_id;
        private string house_type;
        private decimal rate;
        private int modified_u_id;
        private DateTime modified_date;
        private DateTime applied_date;
        private DateTime date;


        //Water Tax DBCode Parameters
        private int water_tax_id;
        private DateTime from_date;
        private DateTime to_date;
        private string connection_type;
        private int water_connection_size;
        private decimal water_tax_amount;
        

        public int Water_Tax_Id
        {
            get { return water_tax_id; }
            set { water_tax_id = value; }
        }

        public DateTime From_Date
        {
            get { return from_date; }
            set { from_date = value; }
        }

        public DateTime To_Date
        {
            get { return to_date; }
            set { to_date = value; }
        }
        public string Connection_Type
        {
            get { return connection_type; }
            set { connection_type = value; }
        }
        public int Water_Connection_Size
        {
            get { return water_connection_size; }
            set { water_connection_size = value; }
        }

        public decimal Water_Tax_Amount
        {
            get { return water_tax_amount; }
            set { water_tax_amount = value; }
        }


        //Village Master DBCode Parameters
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public string Contact_No
        {
            get { return contact_no; }
            set { contact_no = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }

        public int Id
        {
            get { return id; }
            set { id = value; }
        }
        public string Village_Id
        {
            get { return village_id; }
            set { village_id = value; }
        }
        public int State_Id
        {
            get { return state_id; }
            set { state_id = value; }
        }

        public int PinCode
        {
            get { return pincode; }
            set { pincode = value; }
        }

        public int District_Id
        {
            get { return district_id; }
            set { district_id = value; }
        }

        public string Division
        {
            get { return division; }
            set { division = value; }
        }

        public DateTime Enrolment_Date
        {
            get { return enrolment_date; }
            set { enrolment_date = value; }
        }

        public DateTime Termination_Date
        {
            get { return termination_date; }
            set { termination_date = value; }
        }
        public DateTime Bill_Generation_Date
        {
            get { return bill_generation_date; }
            set { bill_generation_date = value; }
        }
        public DateTime Due_Date
        {
            get { return date; }
            set { date = value; }
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
        public int Sq_Rate_Id
        {
            get { return sq_rate_id; }
            set { sq_rate_id = value; }
        }
        public int House_No
        {
            get { return house_no; }
            set { house_no = value; }
        }
        public string House_Type_Id
        {
            get { return house_type_id; }
            set { house_type_id = value; }
        }
        public string House_Type
        {
            get { return house_type; }
            set { house_type = value; }
        }
        public decimal Rate
        {
            get { return rate; }
            set { rate = value; }
        }
        public int Modified_U_Id
        {
            get { return modified_u_id; }
            set { modified_u_id = value; }
        }
        public DateTime Modified_Date
        {
            get { return modified_date; }
            set { modified_date = value; }
        }
        public DateTime Applied_Date
        {
            get { return applied_date; }
            set { applied_date = value; }
        }
    }
}