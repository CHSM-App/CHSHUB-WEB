using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class house_tax : System.Web.UI.Page
    {
        House_Tax GetHouse = new House_Tax();
        BL_House_Tax bL_House = new BL_House_Tax();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["village_id"] == null)

            Response.Redirect("login1.aspx");
            village_id.Value = Session["village_id"].ToString();

            if (!IsPostBack)
            {
                fill_drop();
                house_tax_gridbind();
                fetch_house_no();
            }
        }

        public void fill_drop()
        {
            String sql_query1 = "Select *  from house_type";
            bL_House.fill_drop(ddl_house_type, sql_query1, "house_type", "house_type_id");
          
        }

        public void house_tax_gridbind()
        {
            DataTable dt = new DataTable();
            GetHouse.Sql_Operation = "Grid_Show";
            GetHouse.Village_Id = (village_id.Value);
            dt = bL_House.get_house_tax(GetHouse);
            OwnerGrid.DataSource = dt;
            ViewState["dirState"] = dt;
            OwnerGrid.DataBind();

        }
        public void runproc_save(String operation)
        {

            if (house_tax_id.Value != "")
                GetHouse.House_Tax_Id = Convert.ToInt32(house_tax_id.Value.ToString());
            GetHouse.Sql_Operation = "Update";
            GetHouse.Village_Id = village_id.Value;
            GetHouse.House_No = Convert.ToInt32(txt_house_no.Text);
            GetHouse.House_Type = Convert.ToInt32(ddl_house_type.ToString());
            GetHouse.From_Date = Convert.ToDateTime(Txtfrom_date.Text);
            GetHouse.To_Date = Convert.ToDateTime(Txt_todate.Text);
            GetHouse.House_Tax_Amount = Convert.ToDecimal(txt_tax_amount.Text);
            bL_House.update_house_tax(GetHouse);

        }
        public void runproc(string operation)
        {
            if (house_tax_id.Value != "")
                GetHouse.House_Tax_Id = Convert.ToInt32(house_tax_id.Value.ToString());
            GetHouse.Sql_Operation = operation;

            var result = bL_House.update_house_tax(GetHouse);
            if (operation == "Select")
            {

                (house_tax_id.Value) = result.House_Tax_Id.ToString();
                  village_id.Value = result.Village_Id;
                txt_house_no.Text = result.House_No.ToString();
                ddl_house_type.SelectedValue = result.House_Type.ToString();
                Txtfrom_date.Text = result.From_Date.ToString("yyyy-MM-dd");
                Txt_todate.Text = result.To_Date.ToString("yyyy-MM-dd");
                txt_tax_amount.Text = result.House_Tax_Amount.ToString();

                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            }
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            house_tax_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;
        }
        public void fetch_house_no()
        {
            GetHouse.Sql_Operation = "house_no_fetch";
            GetHouse.Village_Id = village_id.Value;
            var result = bL_House.fetch_house_no(GetHouse);
            txt_house_no.Text = result.House_No.ToString();
        }

        protected void Delete_Command(object sender, CommandEventArgs e)
        {

        }

        protected void OwnerGrid_Sorting(object sender, GridViewSortEventArgs e)
        {

        }

        protected void OwnerGrid_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void OwnerGrid_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc_save("Update");

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
        //    if (village_owner_id.Value != "")
        //        owner.Village_Owner_id = Convert.ToInt32(village_owner_id.Value);
        //    owner.Sql_Operation = "Delete";
        //    bL_Owner.delete(owner);
        //    Response.Redirect("village_owner_master.aspx");
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("house_tax.aspx");
        }
    }
}