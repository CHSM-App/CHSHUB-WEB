using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BusinessLogic.BL
{
    public class BL_Meeting_Details
    {
        DA_Meeting_Details dA_Meeting = new DA_Meeting_Details();
        public Meeting Delete_Meet(Meeting meeting)
        {
            return dA_Meeting.delete(meeting);

        }

        public object search_meeting_details(Meeting meeting)
        {
            return dA_Meeting.Search_Meeting_Details(meeting);
        }
    }
}