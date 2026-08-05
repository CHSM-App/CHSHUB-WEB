using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class Cashbook
    {
        private int bid;
        private DateTime date1;
        private DateTime date2;
        private string SocietyId;
        private string Operation;
        private string Result;
        private int type;



        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }
        public int Type
        {
            get { return type; }
            set { type = value; }
        }
        public DateTime Date1
        {
            get { return date1; }
            set { date1 = value; }
        }
        public DateTime Date2
        {
            get { return date2; }
            set { date2 = value; }
        }
        public string Society_Id
        {
            get { return SocietyId; }
            set { SocietyId = value; }
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