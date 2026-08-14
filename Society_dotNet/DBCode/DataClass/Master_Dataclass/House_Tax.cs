using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class House_Tax
    {
        private int housetaxid;
        private int houseno;
        private int housetype;
        private DateTime from_date;
        private DateTime to_date;
        private decimal house_tax_amount;
        private string village_id;
        private string Operation;
        private string Result;


        public int House_Tax_Id
        {
            get { return housetaxid; }
            set { housetaxid = value; }
        }
        public int House_No
        {
            get { return houseno; }
            set { houseno = value; }
        }
        public int House_Type
        {
            get { return housetype; }
            set { housetype = value; }
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
        public decimal House_Tax_Amount
        {
            get { return house_tax_amount; }
            set { house_tax_amount = value; }
        }
        public string Village_Id
        {
            get { return village_id; }
            set { village_id = value; }
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
