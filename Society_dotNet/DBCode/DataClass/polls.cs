using System;

namespace DBCode.DataClass
{
    public class Polls
    {
        private int userId;
        private string userType;
        private string topic;
        private string desc;
        private DateTime expireDate;
        private int allowMultiple;
        private int votePerUnit;
        private int pollId;
        private string audience;
        private string option;
        private string sqlOperation;
        private string sqlResult;
        private string societyId;
        private int option_id;



        public int UserId
        {
            get { return userId; }
            set { userId = value; }
        }
        public int OptionId
        {
            get { return option_id; }
            set { option_id = value; }
        }

        public int Poll_id
        {
            get { return pollId; }
            set { pollId = value; }
        }

        public string sql_operation
        {
            get { return sqlOperation; }
            set { sqlOperation = value; }
        }
        public string user_type
        {
            get { return userType; }
            set { userType = value; }
        }
        public string sql_result
        {
            get { return sqlResult; }
            set { sqlResult = value; }
        }
        public string society_id
        {
            get { return societyId; }
            set { societyId = value; }
        }
        public string Topic
        {
            get { return topic; }
            set { topic = value; }
        }

        public string Desc
        {
            get { return desc; }
            set { desc = value; }
        }

        public DateTime ExpireDate
        {
            get { return expireDate; }
            set { expireDate = value; }
        }

        public int AllowMultiple
        {
            get { return allowMultiple; }
            set { allowMultiple = value; }
        }

        public int VotePerUnit
        {
            get { return votePerUnit; }
            set { votePerUnit = value; }
        }

        public string Audience
        {
            get { return audience; }
            set { audience = value; }
        }

        public string Option
        {
            get { return option; }
            set { option = value; }
        }
    }
}
