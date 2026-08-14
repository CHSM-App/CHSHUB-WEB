using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Office2016.Drawing.Command;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services.Description;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class InventoryMaster : System.Web.UI.Page
    {
        BL_Inventory_Master bL_Inventory = new BL_Inventory_Master();
        Inventory inventory = new Inventory();
        BL_Society_Expense bL_Society = new BL_Society_Expense();

        protected void Page_Load(object sender, System.EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {

                BindInventoryData();
                //DataTable dt = new DataTable();
                //dt = bL_Society.fill_list("vendor_fill", society_id.Value);
                //Repeater1.DataSource = dt;
                //Repeater1.DataBind();



            }

        }


        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                string[] data = e.CommandArgument.ToString().Split('|');

                // assign values
                hdnItemId.Value = data[0];
                txtItemName.Text = data[1];
                date.Text = data[2];
                txt_Cost.Text = data[3];
                txt_quantity.Text = data[4];
                //ddl_conditiond.SelectedValue = data[5];
                remark.Text = data[6];
                hdnVendorId.Value = data[7];
                txtWarrantyMonths.Text = data[8];


                // updatepanel refresh
                upnlModal.Update();


            }

        }


        private void BindInventoryData()
        {
            DataTable dt = new DataTable();
            inventory.Sql_Operation = "Grid_Show";
            inventory.Society_Id = society_id.Value;
            dt = bL_Inventory.getInventoryDetails(inventory);

            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();

            Repeater1.DataSource = dt;
            Repeater1.DataBind();
        }

        protected string GetStockStatus(decimal currentStock, decimal reorderLevel)
        {
            string cssClass, statusText;

            if (currentStock > reorderLevel * 2)
            {
                cssClass = "stock-high";
                statusText = "In Stock";
            }
            else if (currentStock > reorderLevel)
            {
                cssClass = "stock-medium";
                statusText = "Low Stock";
            }
            else
            {
                cssClass = "stock-low";
                statusText = "Reorder";
            }

            return $"<span class='stock-badge {cssClass}'>{statusText}</span>";
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            try
            {
                //int itemId = Convert.ToInt32(hdnItemId.Value);

                //inventory.Item_Id = itemId;
                inventory.Sql_Operation = "Update";
                inventory.Society_Id = society_id.Value;
                inventory.Item_Name = txtItemName.Text;
                inventory.VendorId = Convert.ToInt32(hdnVendorId.Value);
                inventory.Quantity = Convert.ToInt32(txt_quantity.Text);
                inventory.Purchase_Cost = Convert.ToDecimal(txt_Cost.Text);
                //inventory.Condition_Status = ddl_conditiond.SelectedValue;
                inventory.Warranty = Convert.ToInt32(txtWarrantyMonths.Text);
                inventory.Remarks = remark.Text;

                var result = bL_Inventory.updateInventoryDetails(inventory);


                ShowMessage( "Item added successfully!", "success");
                BindInventoryData();


            }
            catch (Exception ex)
            {
                ShowMessage("Error saving item: " + ex.Message, "error");
            }
        }

        private void LoadItemForEdit(string itemId)
        {
            try
            {
                inventory.Item_Id = Convert.ToInt32(itemId);
                inventory.Sql_Operation = "Select";
                var result = bL_Inventory.updateInventoryDetails(inventory);

      
                society_id.Value = result.Society_Id;
                TextBox1.Text = result.Item_Name;
                vendor_name_id.Value = result.VendorId.ToString();
                //category.Text = result.Category;
                //txtDescription.Text = result.Description;
                //ddlUOM.SelectedItem.Text = result.Unit;
                txt_quantity.Text = result.Quantity.ToString();
                txt_Cost.Text = result.Purchase_Cost.ToString();
                //ddl_conditiond.SelectedValue = result.Condition_Status;
                //date.Text =  result.Purchase_Date.Value.ToString("yyyy-MM-dd") ;
                remark.Text = result.Remarks;


                //DataTable dt = new DataTable();
                //dt = bL_Society.fill_list("vendor_fill", society_id.Value);
                //Repeater1.DataSource = dt;
                //Repeater1.DataBind();


                //upnlModal.Update();
                hdnItemId.Value = result.Item_Id.ToString();
                ScriptManager.RegisterStartupScript(this.upnlModal, this.GetType(), "ShowModalScript", "$('#edit_model').modal('show');", true);


                //txt_quantity.Text = result.Quantity.ToString();
                //txt.Text = result.Charges.ToString();
                //txt_slot.Text = result.Slot.ToString();


            }
            catch (Exception ex)
            {
                ShowMessage("Error loading item: " + ex.Message, "error");
            }
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            LoadItemForEdit(id);

        }
        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label item_id = (System.Web.UI.WebControls.Label)row.FindControl("item_id");
            inventory.Sql_Operation = "Delete";

            inventory.Item_Id = Convert.ToInt32(item_id.Text);
            bL_Inventory.delete(inventory);

            BindInventoryData();

        }
        private void ShowMessage(string message, string type)
        {
            string script = $@"
                var msg = document.createElement('div');
                msg.style.cssText = 'position:fixed;top:20px;right:20px;padding:15px 25px;background:{(type == "success" ? "#4CAF50" : "#f44336")};color:white;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,0.15);z-index:10000;font-weight:600;';
                msg.innerHTML = '{message}';
                document.body.appendChild(msg);
                setTimeout(function(){{ msg.remove(); }}, 3000);
            ";
            ScriptManager.RegisterStartupScript(this, GetType(), "ShowMessage", script, true);
        }


        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (vendor_name_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    //if (link.CommandArgument == vendor_name_id.Value)

                    //    TextBox1.Text = link.Text;

                }

            }

        }

        protected void txtWarrantyMonths_TextChanged(object sender, EventArgs e)
        {
                try
                {
                    if (!string.IsNullOrEmpty(date.Text) && !string.IsNullOrEmpty(txtWarrantyMonths.Text))
                    {
                        DateTime purchaseDate = DateTime.Parse(date.Text);
                        int months = int.Parse(txtWarrantyMonths.Text);

                        DateTime warrantyLastDate = purchaseDate.AddMonths(months);
                        txtWarrantyLastDate.Text = warrantyLastDate.ToString("yyyy-MM-dd");
                    }
                }
                catch (Exception ex)
                {
                    txtWarrantyLastDate.Text = "";
                }
            

        }

        protected void date_TextChanged(object sender, EventArgs e)
        {
            txtWarrantyMonths_TextChanged(sender, e);
        }

        protected void ddl_conditiond_SelectedIndexChanged(object sender, EventArgs e)
        {

            DropDownList ddl = (DropDownList)sender;
            GridViewRow row = (GridViewRow)ddl.NamingContainer;

            Label item_id = (Label)row.FindControl("lblItemId");
            inventory.Item_Id = Convert.ToInt32(item_id.Text);
            inventory.Condition_Status = ddl.SelectedValue;
            inventory.Society_Id = society_id.Value;
            inventory.Sql_Operation = "update_Condition";

            var result = bL_Inventory.updateInventoryDetails(inventory);
            ScriptManager.RegisterStartupScript(this, GetType(), "SuccessMsg", $"alert('✅ Condition Updated'); ", true);

        }
    }


}