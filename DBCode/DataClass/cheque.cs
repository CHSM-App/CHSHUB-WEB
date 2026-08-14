using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class cheque
    {
        private int chqid;
        private int oid;
        private string oname;
        private int bid;
        private int wid;
        private string chqno;
        private float cheamount;
        private DateTime chedate;
        private DateTime chedue;
        private string chestatus;
        private string Operation;
        private string Result;


        public int Chq_Id
        {
            get { return chqid; }
            set { chqid = value; }
        }
        public int O_Id
        {
            get { return oid; }
            set { oid = value; }
        }
        public string O_Name
        {
            get { return oname; }
            set { oname = value; }
        }
        public int B_Id
        {
            get { return bid; }
            set { bid = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public string Chqno
        {
            get { return chqno; }
            set { chqno = value; }
        }
        public float Che_Amount
        {
            get { return cheamount; }
            set { cheamount = value; }
        }
        public DateTime Che_Date
        {
            get { return chedate; }
            set { chedate = value; }
        }
        public DateTime Che_Due
        {
            get { return chedue; }
            set { chedue = value; }

        }
        public string Che_Status
        {
            get { return chestatus; }
            set { chestatus = value; }

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