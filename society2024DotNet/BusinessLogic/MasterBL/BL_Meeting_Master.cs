using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Meeting_Master
    {
        DA_Meeting_Master dA_Meeting = new DA_Meeting_Master();
        public DataTable getMeetingDetails(Meeting meeting)
        {
          
            return dA_Meeting.get_meeting_details(meeting);
            
        }
        public DataTable MoM_Gridbind(Meeting meeting)
        {
           
            return dA_Meeting.mom_gridbind(meeting);

        }

        public DataTable updatemeetingdetails(Meeting meeting)
        {
           
            return dA_Meeting.updateMeetingDetails(meeting);
        }

        public Meeting delete(Meeting meeting)
        {
          
            return dA_Meeting.delete_meeting(meeting);

        }
        public Meeting datechanged(Meeting meeting)
        {
         
            return dA_Meeting.Date_Changed(meeting);
        }

        public object search_meeting(Meeting meeting)
        {
            
            return dA_Meeting.search_meeting(meeting);

        }

        public Meeting getMeeting(Meeting meeting)
        {
            return dA_Meeting.get_meeting(meeting);
        }

        public Meeting send_notification(Meeting meeting)
        {
            return dA_Meeting.Send_Notification(meeting);
        }
    }
}