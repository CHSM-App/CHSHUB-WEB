using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class terms_condition
    {
        private int Tid;
        private string SocietyId;
        private string terms;
        private string Operation;
        private string Result;

        public int term_id
        {
            get { return Tid; }
            set { Tid = value; }
        }
        public string Society_Id
        {
            get { return SocietyId; }
            set { SocietyId = value; }
        }
        public string Terms
        {
            get { return terms; }
            set { terms = value; }
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