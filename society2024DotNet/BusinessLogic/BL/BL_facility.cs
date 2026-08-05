using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.BL
{
    public class BL_facility
    {
        DA_Facility dA_facility = new DA_Facility();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_facility.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable GetPartyDetails(facility Facility)
        {
            return dA_facility.getparty(Facility);

        }
        public facility UpdateParty(facility Facility)
        {
            return dA_facility.updateparty(Facility);

        }
        public facility Party_Delete(facility Facility)
        {
            return dA_facility.delete(Facility);

        }

        public facility get_charges(facility Facility)
        {
            return dA_facility.getcharges(Facility);
        }
        public facility getflatno(facility Facility)
        {
            return dA_facility.getflatno(Facility);
        }

        public DataTable getfacility(facility getFacility)
        {
            return dA_facility.GetFacility(getFacility);
        }

        public DataTable search_party(facility Facility)
        {
            return dA_facility.party_search(Facility);
        }

        public facility update_facility(facility getFacility)
        {
            return dA_facility.Update_Facility(getFacility); 
        }

        public DataTable search_facility(facility getFacility)
        {
            return dA_facility.Search_Facility(getFacility);
        }

        public facility delete(facility getFacility)
        {
            return dA_facility.Delete_Facility(getFacility);
        }

        public facility runproc_slot(facility getFacility)
        {
            return dA_facility.Runproc_Save(getFacility);
        }

        public DataTable getslot(facility getFacility)
        {
            return dA_facility.Get_Slot(getFacility);
        }

        public facility select_facility(facility getFacility)
        {
            return dA_facility.select_facility(getFacility);
        }

        public  DataTable Fill_list(string v, string v2)
        {
            return dA_facility.Fill_list(v, v2);
        }

        public facility delete_slot(facility getFacility)
        {
            return dA_facility.Delete_Slot(getFacility);
        }



        //public Parking Vehicle_No_Textchanged(Parking parking)
        //{
        //    return parking_Allotment.vehicle_no_textchanged(parking);

        //}
    }
}