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
    public class BL_Village_Master
    {
        stored st = new stored();
        DA_Village_Master dA_Village = new DA_Village_Master();

        public void fill_drop(DropDownList ddl_state, string sql_query, string v1, string v2)
        {
            dA_Village.fill_drop(ddl_state, sql_query, v1, v2);
        }
        public DataTable get_village_details(Village village)
        {
            return dA_Village.Get_Village(village);
        }
        public Village updateVillage(Village village)
        {
           return dA_Village.Update_Village(village);
        }

        public Village Update_sq_ft_rate(Village village)
        {
            return dA_Village.Update_Sq_Ft_Rate(village);
        }
        public DataTable GetSquare_Feet(Village village)
        {
            return dA_Village.getsquare_feet(village);
        }

        public DataTable search_sq_ft_rate(Village village)
        {
            return dA_Village.Search_Sq_Ft_Rate(village);
        }

        public DataTable get_water_tax(Village village)
        {
           return dA_Village.Get_Water_Tax(village);
        }

        public Village update_water_tax(Village village)
        {
            return dA_Village.Update_Water_Tax(village);
        }

        public Village delete_water_tax(Village village)
        {
            return dA_Village.Delete_Water_Tax(village);
        }

        public DataTable search_village(Village village)
        {
            return dA_Village.Village_Search(village);
        }

        public DataTable pending_sq_ft_rate(Village village)
        {
            return dA_Village.Pending_Sq_ft_Rt(village);
        }
    }
}