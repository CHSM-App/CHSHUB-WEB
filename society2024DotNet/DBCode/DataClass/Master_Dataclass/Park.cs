using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Park
    {
        private int alloid;
        private DateTime date;
        private string p3;
        private string g1;
        private string p1;
        private string p2;
        private string p4;
        private string p7;
        private string p6;
        private string g2;
        private string g3;
        private string g4;
        private string p9;
        private string Operation;
        private string Result;



        public int Allo_Id
        {
            get { return alloid; }
            set { alloid = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }

        public string P3
        {
            get { return p3; }
            set { p3 = value; }
        }

        public string G1
        {
            get { return g1; }
            set { g1 = value; }
        }

        public string P1
        {
            get { return p1; }
            set { p1 = value; }
        }
        public string P2
        {
            get { return p2; }
            set { p2 = value; }
        }
        public string P4
        {
            get { return p4; }
            set { p4 = value; }
        }
        public string P7
        {
            get { return p7; }
            set { p7 = value; }
        }
        public string P6
        {
            get { return p6; }
            set { p6 = value; }
        }
        public string G2
        {
            get { return g2; }
            set { g2 = value; }
        }
        public string G3
        {
            get { return g3; }
            set { g3 = value; }
        }
        public string G4
        {
            get { return g4; }
            set { g4 = value; }
        }
        public string P9
        {
            get { return p9; }
            set { p9 = value; }
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