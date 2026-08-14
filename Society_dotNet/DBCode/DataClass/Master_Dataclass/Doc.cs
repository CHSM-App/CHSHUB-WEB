using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Doc
    {
        private int did;
        private string docname;
        private string societyid;
        private string Operation;
        private string Result;

        public int doc_id
        {
            get { return did; }
            set { did = value; }
        }
        public string Doc_Name
        {
            get { return docname; }
            set { docname = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
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