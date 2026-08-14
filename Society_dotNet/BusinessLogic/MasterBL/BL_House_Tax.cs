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
    public class BL_House_Tax
    {
        stored st = new stored();
        DA_House_Tax dA_House = new DA_House_Tax();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_House.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable get_house_tax(House_Tax getHouse)
        {
            return dA_House.Get_House_Tax(getHouse);
        }

        public House_Tax update_house_tax(House_Tax getHouse)
        {
            return dA_House.Update_House_Tax(getHouse);
        }

        public House_Tax fetch_house_no(House_Tax getHouse)
        {
            return dA_House.Fetch_House_No(getHouse);
        }
    }
}