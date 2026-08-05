using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Shop_Maint
    {
        DA_Shop_Maint dA_Shop_Maint = new DA_Shop_Maint();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Shop_Maint.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable getshopmaintenance(Shop_Maintenance maintenance)
        {
            return dA_Shop_Maint.Get_Shop_Maintenance(maintenance);
        }
        public Shop_Maintenance updateshopmaintenance(Shop_Maintenance maintenance)
        {
            return dA_Shop_Maint.Update_Shop_Maintenance(maintenance);
        }
        public Shop_Maintenance delete(Shop_Maintenance maintenance)
        {
            return dA_Shop_Maint.Shop_Maint_Delete(maintenance);
        }
        public Shop_Maintenance receipt_textchanged(Shop_Maintenance maintenance)
        {
            return dA_Shop_Maint.Receipt_TextChanged(maintenance);
        }

        public object search_Shop_maint(Shop_Maintenance maintenance)
        {
            return dA_Shop_Maint.shop_maint_search(maintenance);
        }

        public DataTable get_printshop(Shop_Maintenance shop)
        {
            return dA_Shop_Maint.Get_PrintShop(shop);
        }
    }
}