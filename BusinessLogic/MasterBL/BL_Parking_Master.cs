using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Parking_Master
    {
        public DataTable getParkingDetails(Parking_1 parking)
        {
            DA_Parking_Master dA_Parking = new DA_Parking_Master();
            return dA_Parking.getParkingDetails(parking);
           
        }
        public Parking_1 updateParkingDetails(Parking_1 parking)
        {
            DA_Parking_Master dA_Parking = new DA_Parking_Master();
           return dA_Parking.updateParkingDetails(parking);

        }
        public Parking_1 delete(Parking_1 parking)
        {
            DA_Parking_Master dA_Parking = new DA_Parking_Master();
            return dA_Parking.delete_parking(parking);

        }
        public Parking_1 numbertextchanged(Parking_1 parking)
        {
            DA_Parking_Master dA_Parking = new DA_Parking_Master();
            return dA_Parking.Number_TextChanged(parking);

        }

        public DataTable search_park_place(Parking_1 parking)
        {
            DA_Parking_Master dA_Parking = new DA_Parking_Master();
            return dA_Parking.park_place_search(parking);

        }

       
    }
}