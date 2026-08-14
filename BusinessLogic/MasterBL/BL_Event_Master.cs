using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Event_Master
    {
        DA_Event_Master dA_Event = new DA_Event_Master();
        public DataTable getEventDetails(Event evt)
        {
          
            return dA_Event.getEventDetails(evt);
           
        }
        public DataTable updateEventDetails(Event evt)
        {
           
            return dA_Event.updateEventDetails(evt);

        }
        public Event delete(Event evt)
        {
          
            return dA_Event.delete_event(evt);

        }
      
        public DataTable search_event(Event evt)
        {
          
            return dA_Event.search_event(evt);
        }

        public Event getevent(Event evt)
        {
          
            return dA_Event.getevent(evt);
        }

        public Event send_notification(Event evt)
        {
            return dA_Event.Send_Notification(evt);
        }
    }
}