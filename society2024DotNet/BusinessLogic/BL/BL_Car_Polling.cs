using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.BL
{
    public class BL_Car_Polling
    {
        DA_Car_Polling DA_Car = new DA_Car_Polling();
        public DataTable Getcarpolling(carpolling car)
        {
            return DA_Car.Get_Car_Polling(car);

        }
        public carpolling updatecarpolling(carpolling car)
        {
            return DA_Car.Update_Car_Polling(car);

        }
        public carpolling Delete_Car_Polling(carpolling car)
        {
            return DA_Car.delete(car);

        }

        public carpolling Vehical_No_Changed(carpolling car)
        {
            return DA_Car.vehical_no_changed(car);

        }

        public object search_car(carpolling car)
        {
           return DA_Car.search_car(car);
        }
    }
}