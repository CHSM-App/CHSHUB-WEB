using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class upload_doc
    {
        private int fileid;
        private int did;
        private string filesavepath;
        private DateTime date;
        private int bid;
        private int wid;
        private int fid;
        private int fnoid;
        private string societyid;
        private string name;
        private string flatno;
        private string bed;
        private string Operation;
        private string Result;
        private string tag;
        private string description;


        public string Tag
        {
            get { return tag; }
            set { tag = value; }
        }
        public string Description
        {
            get { return description; }
            set { description = value; }
        }
        public int File_Id
        {
            get { return fileid; }
            set { fileid = value; }
        }
        public int doc_id
        {
            get { return did; }
            set { did = value; }
        }
        public string File_Save_Path
        {
            get { return filesavepath; }
            set { filesavepath = value; }
        }
        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public int build_id
        {
            get { return bid; }
            set { bid = value; }
        }
        public int wing_id
        {
            get { return wid; }
            set { wid = value; }
        }
        public int flat_id
        {
            get { return fid; }
            set { fid = value; }
        }
        public int Fno_Id
        {
            get { return fnoid; }
            set { fnoid = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Doc_Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Flat_No
        {
            get { return flatno; }
            set { flatno = value; }
        }
        public string Bed
        {
            get { return bed; }
            set { bed = value; }
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