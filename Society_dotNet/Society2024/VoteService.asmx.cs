using BusinessLogic.BL;
using DBCode.DataClass;
using Microsoft.Reporting.Map.WebForms.BingMaps;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;

namespace Society2024
{
    /// <summary>
    /// Summary description for VoteService
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    [ScriptService]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    //[System.Web.Script.Services.ScriptService]
    public class VoteService : System.Web.Services.WebService
    {

        Polls polls = new Polls();
        BL_poll bL_Poll = new BL_poll();
        BL_Staff bL_Staff = new BL_Staff();
        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public string SaveVote(int OneVotePerUnit, int AllowMultipleVotes, int userId, int pollId, int optionId, String SocietyID, String userType)
        {
            try
            {
                polls.UserId = userId;
                polls.Poll_id = pollId;
                polls.OptionId = optionId;
                polls.society_id = SocietyID;
                polls.user_type = userType;
                polls.AllowMultiple = AllowMultipleVotes;
                polls.VotePerUnit = OneVotePerUnit;
                bL_Poll.vote(polls);

                return "Vote saved successfully";

            }
            catch (Exception ex)
            {
                // Log error
                return "Error saving vote: " + ex.Message;
            }
        }




        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
       
        public List<CalendarEvent> GetAttendance(int staff_id)
        {
            string society_id = Session["society_id"].ToString();

            // This returns DataTable
            DataTable dt = bL_Staff.getAttendance(staff_id, society_id);

            List<CalendarEvent> events = new List<CalendarEvent>();

            foreach (DataRow row in dt.Rows)
            {
                int status = Convert.ToInt32(row["status"]);
                DateTime inDate = Convert.ToDateTime(row["in_date"]);

                string title = "";
                string color = "";

                switch (status)
                {
                    case 1:
                        title = "Present";
                        color = "green";
                        break;

                    case 2:
                        title = "Absent";
                        color = "red";
                        break;

                    case 3:
                        title = "Leave";
                        color = "gold";
                        break;
                }

                events.Add(new CalendarEvent
                {
                    title = title,
                    start = inDate.ToString("yyyy-MM-dd"),
                    color = color
                });
            }

            return events;
        }


        public class CalendarEvent
        {
            public string title { get; set; }
            public string start { get; set; }
            public string color { get; set; }

        }
    }
}