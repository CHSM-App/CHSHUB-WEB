using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Inventory_Master
    {
        DA_Inventory_Master dA_Inventory = new DA_Inventory_Master();
        public DataTable getInventoryDetails(Inventory inventory)
        {
            return dA_Inventory.GetInventoryDetails(inventory);
        }
        public Inventory updateInventoryDetails(Inventory inventory)
        {
           return dA_Inventory.UpdateInventoryDetails(inventory);
        }
        public Inventory delete(Inventory inventory)
        {
            return dA_Inventory.Delete_Inventory(inventory);
        }

        public object search_inventory(Inventory inventory)
        {
            return dA_Inventory.Inventory_Search(inventory);
        }


    }
}