using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Notice
    {
        private int nid;
        private DateTime date;
        private string name;
        private string description;
        private DateTime validto;
        private string societyid;
        private int recipients_id;
        private int notification_id;
        private string notification_type;
        private int user_id;
        private string title;
        private string body;
        private string Operation;
        private string Result;
        private string usertype;


        public int notice_id
        {
            get { return nid; }
            set { nid = value; }
        }
        public int Recipients_id
        {
            get { return recipients_id; }
            set { recipients_id = value; }
        }
        public int Notification_id
        {
            get { return notification_id; }
            set { notification_id = value; }
        }
        public string Notification_Type
        {
            get { return notification_type; }
            set { notification_type = value; }
        }
        public string UserType
        {
            get { return usertype; }
            set { usertype = value; }
        }
        public string Title
        {
            get { return title; }
            set { title = value; }
        }
        public int User_Id
        {
            get { return user_id; }
            set { user_id = value; }
        }

        public string Body
        {
            get { return body; }
            set { body = value; }
        }

        public DateTime Date
        {
            get { return date; }
            set { date = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Description
        {
            get { return description; }
            set { description = value; }
        }
        public DateTime Valid_To
        {
            get { return validto; }
            set { validto = value; }
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