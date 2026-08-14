using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class house
    {
        private int houseid;
        private string house_no;
        private string house_type;
        private string area;
        
        private string Operation;
        private string Result;

        public int House_Id 
        {
            get { return houseid; }
            set { houseid = value; }
        }
        public string House_No
        {
            get { return house_no; }
            set { house_no = value; }
        }
        public string House_Type
        {
            get { return house_type; }
            set { house_type = value; }
        }
        public string Area
        {
            get { return area; }
            set { area = value; }
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