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
    public class BL_Village_Owner
    {
        DA_Village_Owner dA_Village = new DA_Village_Owner();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Village.fill_drop(drp_down, sqlstring, text, value);
        }
        
        public DataTable print_house_receipt(VillageOwner village_owner)
        {
            return dA_Village.Print_House_Receipt(village_owner);
        }
        public DataTable get_tax_receipt(VillageOwner village_owner)
        {
            return dA_Village.Get_Tax_Receipt(village_owner);
        }
        public DataTable get_village_owner(VillageOwner village_owner)
        {
            return dA_Village.Get_Village_Owner(village_owner);
        }
        public object print_house_owner(VillageOwner village_owner)
        {
            return dA_Village.Print_House_Owner(village_owner);
        }
        public VillageOwner update_house_tax_receipt(VillageOwner village_owner)
        {
            return dA_Village.Update_House_Tax_Receipt(village_owner);
        }
        public VillageOwner Update_Village_Owner(VillageOwner village_owner)
        {
            return dA_Village.update_village_owner(village_owner);
        }
        public VillageOwner get_house_owner(VillageOwner village_owner)
        {
            return dA_Village.runproc_house_owner(village_owner);
        }

        public VillageOwner delete_house_tax(VillageOwner village_owner)
        {
            return dA_Village.Delete_House_Tax(village_owner);
        }
        public VillageOwner get_village_id(VillageOwner village_owner)
        {
            return dA_Village.Get_Village_Id(village_owner);
        }

        public VillageOwner fetch_House_tax_receipt(VillageOwner village_owner)
        {
            return dA_Village.Fetch_House_Tax_Receipt(village_owner);
        }

        public VillageOwner pending_house_tax_receipt(VillageOwner village_owner)
        {
            return dA_Village.Pending_House_Tax_Receipt(village_owner);
        }

        public VillageOwner fetch_house_no(VillageOwner village_owner)
        {
            return dA_Village.Fetch_House_No(village_owner);
        }

        public DataTable search_house_owner(VillageOwner village_owner)
        {
            return dA_Village.house_owner_search(village_owner);
        }
        public VillageOwner address_fetch(VillageOwner village_owner)
        {
            return dA_Village.Fetch_Address(village_owner);
        }
        public VillageOwner delete(VillageOwner owner)
        {
            return dA_Village.village_owner_delete(owner);
        }
        
        public VillageOwner check_select(VillageOwner village_owner)
        {
            return dA_Village.Check_Select(village_owner);
        }

        public DataTable search_house_tax_receipt(VillageOwner village_owner)
        {
            return dA_Village.House_Tax_Receipt_Search(village_owner);
        }
    }
}