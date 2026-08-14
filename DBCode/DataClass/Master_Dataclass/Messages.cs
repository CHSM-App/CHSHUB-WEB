using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Messages
    {
        private int ownerID;
        private string societyID;
        private string message;
        private string operation;
        private string subject;


        //getter and setter methods

        public int OwnerID
        {
            get { return ownerID; }
            set { ownerID = value; }

        }

        public string SocietyID
        {
            get { return societyID; }
            set { societyID = value; }
        }

        public string Message
        {
            get { return message; }
            set { message = value; }
        }

        public string Operation
        {
            get { return operation; }
            set { operation = value; }
        }

        public string Subject
        {
            get { return subject; }
            set { subject = value; }
        }
    }
}