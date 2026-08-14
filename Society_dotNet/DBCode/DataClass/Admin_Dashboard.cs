using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Admin_Dashboard
    {
        private string society_id;
        private string name;
        private string address;
        private string city;
        private string state;
        private string contact_no1;
        private string email;
        private string total_flats;
        private int chargespermonth;
        private int pending_amount;
        private string month;
        private string pincode;
      
        public string Society_Id
        {
            get { return society_id; }
            set { society_id = value; }
        }
        //public string Usage
        //{
        //    get { return usage; }
        //    set { usage = value; }
        //}
        //public string Sql_Operation
        //{
        //    get { return Operation; }
        //    set { Operation = value; }
        //}
        //public string Sql_Result
        //{
        //    get { return Result; }
        //    set { Result = value; }
        //}
    }
}