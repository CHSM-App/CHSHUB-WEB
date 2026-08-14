using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Servent_Made
    {
        private int sid;
        private string sname;
        private string saddress1;
        private string saddress2;
        private string mobileno1;
        private string mobileno2;
        private int clothwash;
        private float clothwashcharge;
        private int bwash;
        private float bwashcharge;
        private int fwash;
        private float fwashcharge;
        private int babyset;
        private float bsetcharge;
        private int meal;
        private float mealcharge;
        private string remark;
        private string societyid;
        private string Operation;
        private string Result;



        public int servent_id
        {
            get { return sid; }
            set { sid = value; }
        }
        public string S_Name
        {
            get { return sname; }
            set { sname = value; }
        }
        public string S_Address_1
        {
            get { return saddress1; }
            set { saddress1 = value; }
        }
        public string S_Address_2
        {
            get { return saddress2; }
            set { saddress2 = value; }
        }
        public string Mobile_No1
        {
            get { return mobileno1; }
            set { mobileno1 = value; }
        }
        public string Mobile_No2
        {
            get { return mobileno2; }
            set { mobileno2 = value; }
        }
        public int Cloth_Wash
        {
            get { return clothwash; }
            set { clothwash = value; }
        }
        public float Cloth_Wash_Charge
        {
            get { return clothwashcharge; }
            set { clothwashcharge = value; }
        }
        public int B_Wash
        {
            get { return bwash; }
            set { bwash = value; }
        }
        public float B_Wash_Charge
        {
            get { return bwashcharge; }
            set { bwashcharge = value; }
        }
        public int F_Wash
        {
            get { return fwash; }
            set { fwash = value; }
        }
        public float F_Wash_Charge
        {
            get { return fwashcharge; }
            set { fwashcharge = value; }
        }
        public int Baby_Set
        {
            get { return babyset; }
            set { babyset = value; }
        }
        public float B_Set_Charge
        {
            get { return bsetcharge; }
            set { bsetcharge = value; }
        }
        public int Meal
        {
            get { return meal; }
            set { meal = value; }
        }
        public float Meal_Charge
        {
            get { return mealcharge; }
            set { mealcharge = value; }
        }
        public string Remark
        {
            get { return remark; }
            set { remark = value; }
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