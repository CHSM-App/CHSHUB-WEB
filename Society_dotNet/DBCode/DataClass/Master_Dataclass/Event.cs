using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Event
    {
        private int eventid;
        private DateTime fromdate;
        private DateTime todate;
        private string eventname;
        private string description;
        private string societyid;
        private string Operation;
        private string Result;
        private string title;
        private string body;
        private int recipients_id;
        private int notification_id;
        private string notification_type;
        private int user_id;
        private string usertype;

        public int Event_Id
        {
            get { return eventid; }
            set { eventid = value; }
        }
        public int Recipients_Id
        {   
            get { return recipients_id; }
            set { recipients_id = value; }
        }
        public int Notification_Id
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
        public int User_Id
        {
            get { return user_id; }
            set { user_id = value; }
        }
        public DateTime From_Date
        {
            get { return fromdate; }
            set { fromdate = value; }
        }
        public DateTime To_Date
        {
            get { return todate; }
            set { todate = value; }
        }
        public string Event_Name
        {
            get { return eventname; }
            set { eventname = value; }
        }
        public string Description
        {
            get { return description; }
            set { description = value; }
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
        public string Title
        {
            get { return title; }
            set { title = value; }
        }
        public string Body
        {
            get { return body; }
            set { body = value; }
        }
    }
}