using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Servent_Maid_Master
    {
        stored st = new stored();
        public DataTable getServentDetails(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
            return dA_Servent.getServentDetails(servent);
        
        }
        public Servent_Made updateServentDetails(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
          return dA_Servent.updateServentDetails(servent);

        }
        public Servent_Made runproc(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
            return dA_Servent.updateServentDetails(servent);
        }
       
        public Servent_Made delete(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
            return dA_Servent.serventdelete(servent);

        }
        public Servent_Made mobile_no_textchanged(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
            return dA_Servent.Mobile_No_TextChanged(servent);

        }

        public object search_servent(Servent_Made servent)
        {
            DA_Servent_Maid_Master dA_Servent = new DA_Servent_Maid_Master();
            return dA_Servent.servent_search(servent);
        }
    }
}