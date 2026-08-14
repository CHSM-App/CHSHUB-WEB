using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Wing_Master
    {
        stored st = new stored();
        DA_Wing_Master dA_Wing = new DA_Wing_Master();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getWingDetails(Wing wing)
        {
            
            DataTable wing_master =dA_Wing.getWingDetails(wing);
            return wing_master;
        }
        public Wing updateWingDetails(Wing wing)
        {
            
            return dA_Wing.updateWingDetails(wing);


        }
        public Wing Get_Building(Wing wing)
        {
            return dA_Wing.getbuilding(wing);
        }
        public Wing delete(Wing wing)
        {
            return dA_Wing.delete(wing);
        }
        public Wing WingTextChanged(Wing wing)
        {
           
           return dA_Wing.WingTextChanged(wing);

        }

        public object search_wing(Wing wing)
        {
           
            return dA_Wing.wing_search(wing);
        }
    }
}