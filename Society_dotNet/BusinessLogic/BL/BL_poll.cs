using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.Remoting.Messaging;
using System.Web;

namespace BusinessLogic.BL
{
   

    public class BL_poll
    {
        DA_poll polls = new DA_poll();

    DA_poll poll = new DA_poll();
        public Polls addPolls(Polls polls)
        {
            return poll.add_polls(polls);

        }
        public Polls addOptions(Polls polls)
        {
            return poll.addOptions(polls);

        }

        public DataTable getPolls(Polls polls)
        {
            DataTable dt = poll.getPolls(polls);
            return dt;
        }

        public DataTable getVotedNames(Polls polls)
        {
            DataTable dt = poll.getVotedNames(polls);
            return dt;
        }
        public void vote(Polls polls)
        {
            poll.vote(polls);
        }
        public void deletePoll(Polls polls)
        {
            poll.deletePoll(polls);
        }

        public string saveVote(Polls poll)
        {
            throw new NotImplementedException();
        }

        public DataTable getTokens(int recipients_id, string society_id)
        {
            return poll.getTokens(recipients_id, society_id);
        }
    }
}