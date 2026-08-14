using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class file_upload
    {
        private int ufid;
        private int fid;
        private string filesave;
        private DateTime date;
        private string Operation;
        private string Result;

        public int U_F_Id
        {
            get { return ufid; }
            set { ufid = value; }
        }
        public int F_Id
        {
            get { return fid; }
            set { fid = value; }
        }
        public string File_Save
        {
            get { return filesave; }
            set { filesave = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
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