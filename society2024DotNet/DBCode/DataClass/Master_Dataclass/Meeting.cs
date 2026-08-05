using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Meeting
    {

        private int meetid;
        private int meetexid;
        private DateTime meetingdate;
        private DateTime meetingtime;
        private string subject;
        private string details;
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

        public int meet_id
        {
            get { return meetid; }
            set { meetid = value; }
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
        public int User_Id
        {
            get { return user_id; }
            set { user_id = value; }
        }

        public string User_Type
        {
            get { return usertype; }
            set { usertype = value; }
        }
        public int Meet_Ex_Id
        {
            get { return meetexid; }
            set { meetexid = value; }
        }
        public DateTime Meeting_Date
        {
            get { return meetingdate; }
            set { meetingdate = value; }
        }
        public DateTime Meeting_Time
        {
            get { return meetingtime; }
            set { meetingtime = value; }
        }
        public string Subject
        {
            get { return subject; }
            set { subject = value; }
        }
        public string Details
        {
            get { return details; }
            set { details = value; }
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