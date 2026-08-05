using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.MasterDA
{
    public class DA_Inventory_Master
    {
        stored st = new stored();
        public DataTable GetInventoryDetails(Inventory inventory)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", inventory.Sql_Operation));   // e.g., VIEW
            data_item.Add(st.create_array("society_id", inventory.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_inventory_master", ref sdr);

            if (status1 == "Done" && sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }

        // 🔹 Search inventory (optional custom operation)
        public DataTable Inventory_Search(Inventory inventory)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", inventory.Sql_Operation));  // e.g., SEARCH
            data_item.Add(st.create_array("search", inventory.Item_Name));
            data_item.Add(st.create_array("society_id", inventory.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_inventory_master", ref sdr);

            if (status1 == "Done" && sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }

        // 🔹 Insert / Update / ViewById (based on operation)
        public Inventory UpdateInventoryDetails(Inventory inventory)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", inventory.Sql_Operation));   // INSERT / UPDATE / VIEWBYID / DELETE
            data_item.Add(st.create_array("item_id", inventory.Item_Id));
            if (inventory.Sql_Operation == "update_Condition")
            {
                data_item.Add(st.create_array("condition_status", inventory.Condition_Status));

            }
            // Common for insert/update
            if (inventory.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("item_name", inventory.Item_Name));
                data_item.Add(st.create_array("warranty", inventory.Warranty));
                //data_item.Add(st.create_array("category", inventory.Category));
                //data_item.Add(st.create_array("description", inventory.Description));
                data_item.Add(st.create_array("quantity", inventory.Quantity));
                data_item.Add(st.create_array("tax", inventory.Tax));
                data_item.Add(st.create_array("total_amount", inventory.Total_Amount));
                data_item.Add(st.create_array("unit", inventory.Unit));
                data_item.Add(st.create_array("society_id", inventory.Society_Id));
                data_item.Add(st.create_array("purchase_date", inventory.Purchase_Date));
                data_item.Add(st.create_array("purchase_cost", inventory.Purchase_Cost));
                data_item.Add(st.create_array("vendor_id", inventory.VendorId));
                data_item.Add(st.create_array("condition_status", inventory.Condition_Status));
                data_item.Add(st.create_array("last_audit_date", inventory.Last_Audit_Date));
                data_item.Add(st.create_array("vendor_bill_id", inventory.Vendor_bill_ID));

              //  data_item.Add(st.create_array("warranty_last_date", inventory.Warranty_last_date));
                data_item.Add(st.create_array("remarks", inventory.Remarks));
            }

            status1 = st.run_query(data_item, "Select", "sp_inventory_master", ref sdr);
            inventory.Result = status1;

            if (status1 == "Done" && inventory.Sql_Operation == "Select")
            {
                while (sdr.Read())
                {
                    inventory.Item_Id = Convert.ToInt32(sdr["item_id"]);
                    inventory.Item_Name = sdr["item_name"].ToString();
                    //inventory.Category = sdr["category"].ToString();
                    //inventory.Description = sdr["description"].ToString();
                    inventory.Quantity = Convert.ToInt32(sdr["quantity"]);
                    inventory.Warranty = Convert.ToInt32(sdr["warranty"]);
                    inventory.Unit = sdr["unit"].ToString();
                    inventory.Society_Id = sdr["society_id"].ToString();
                    inventory.Purchase_Date = sdr["purchase_date"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(sdr["purchase_date"]);
                    inventory.Purchase_Cost = sdr["purchase_cost"] == DBNull.Value ? 0 : Convert.ToDecimal(sdr["purchase_cost"]);
                    inventory.VendorId = sdr["vendor_id"] == DBNull.Value ? 0 : Convert.ToInt32(sdr["vendor_id"]);
                    inventory.Condition_Status = sdr["condition_status"] == DBNull.Value ? "0" : (sdr["condition_status"]).ToString();
                    inventory.Last_Audit_Date = sdr["last_audit_date"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(sdr["last_audit_date"]);
                    inventory.Remarks = sdr["remarks"].ToString();
                }
            }

            return inventory;
        }

        // 🔹 Delete Inventory
        public Inventory Delete_Inventory(Inventory inventory)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";

            data_item.Add(st.create_array("operation", inventory.Sql_Operation));   // DELETE
            data_item.Add(st.create_array("item_id", inventory.Item_Id));

            status = st.run_query(data_item, "Delete", "sp_inventory_master", ref sdr);

            inventory.Result = status;
            return inventory;
        }

    }
}