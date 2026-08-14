using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class Request
    {
        private int reqid;
        private int sugid;
        private string details;
        private string request;
        private string society_id;
        private DateTime reqdate;
        private string reply;
        private DateTime replydate;
        private int requestby;
        private int replyby;
        private string subject;
        private string Operation;
        private string Result;
        private string search;


        public int Req_Id
        {
            get { return reqid; }
            set { reqid = value; }
        }
        public int sug_id
        {
            get { return sugid; }
            set { sugid = value; }
        }
        public string Requests
        {
            get { return request; }
            set { request = value; }
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
            get { return society_id; }
            set { society_id = value; }
        }
        public DateTime Req_Date
        {
            get { return reqdate; }
            set { reqdate = value; }
        }
        public string Reply
        {
            get { return reply; }
            set { reply = value; }
        }
        public DateTime Reply_Date
        {
            get { return replydate; }
            set { replydate = value; }
        }
        public int Request_By
        {
            get { return requestby; }
            set { requestby = value; }
        }
        public int Reply_By
        {
            get { return replyby; }
            set { replyby = value; }
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
        public string Search
        {
            get { return search; }
            set { search = value; }
        }

    }
}