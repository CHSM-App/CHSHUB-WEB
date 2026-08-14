using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class owner_extension
    {
        private int oexid;
        private int oid;
        private string fname;
        private string relation;
        private string foccu;
        private DateTime fdob;
        private string societyid;
        private string Operation;
        private string Result;


        public int O_Ex_Id
        {
            get { return oexid; }
            set { oexid = value; }
        }
        public int O_Id
        {
            get { return oid; }
            set { oid = value; }
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
        public DateTime F_Dob
        {
            get { return fdob; }
            set { fdob = value; }
        }
        public String Society_Id
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