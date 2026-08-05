using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class rights_details_
    {
        private int rightid;
        private int departmentno;
        private int userid;
        private int activityid;
        private int addcheck;
        private int modifycheck;
        private int deletecheck;
        private int viewcheck;
        private string activityname;
        private string Operation;
        private string Result;


        public int Right_Id
        {
            get { return rightid; }
            set { rightid = value; }
        }
        public int Department_No
        {
            get { return departmentno; }
            set { departmentno = value; }
        }
        public int User_Id
        {
            get { return userid; }
            set { userid = value; }
        }
        public int Activity_Id
        {
            get { return activityid; }
            set { activityid = value; }
        }
        public int Add_Check
        {
            get { return addcheck; }
            set { addcheck = value; }
        }
        public int Modify_Check
        {
            get { return modifycheck; }
            set { modifycheck = value; }
        }
        public int Delete_Check
        {
            get { return deletecheck; }
            set { deletecheck = value; }
        }
        public int View_Check
        {
            get { return viewcheck; }
            set { viewcheck = value; }
        }
        public string Activity_Name
        {
            get { return activityname; }
            set { activityname = value; }
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