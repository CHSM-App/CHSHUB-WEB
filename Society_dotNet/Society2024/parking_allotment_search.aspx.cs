using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Web.Configuration;
using DBCode.DataClass.Master_Dataclass;
using BusinessLogic.MasterBL;
using BusinessLogic;
using BusinessLogic.BL;
using System.Windows.Forms;

namespace Society
{
    public partial class parking_allotment_search : System.Web.UI.Page 
    {
        BL_FillRepeater repeater = new BL_FillRepeater();

        Parking parking = new Parking();
        BL_Parking_Allotment parking_Allotment = new BL_Parking_Allotment();
      
    
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {


                Park_Allotment_GridBind();

                fill_drop1();
            }
        }

        public void fill_drop1()
        {
            
            DataTable dt = new DataTable();
            dt = parking_Allotment.Fill_list(society_id.Value, "fill_owner", "","");
            Repeater_1.DataSource = dt;
            Repeater_1.DataBind();
            dt = parking_Allotment.Fill_list(society_id.Value, "fill_vehicle", flat_id.Value, vehicle_type_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = parking_Allotment.Fill_list(society_id.Value, "fill_place", flat_id.Value, vehicle_type_id.Value);
            Repeater3.DataSource = dt;
            Repeater3.DataBind();

        }


        public void Park_Allotment_GridBind()
        {
            DataTable dt = new DataTable();
            parking.Sql_Operation = "Grid_Show";
            parking.Society_Id = society_id.Value;
            dt = parking_Allotment.GetParkingAllotment(parking);
           
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            GridView3.DataSource = dt;
            GridView3.DataBind();

        }

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["dirState"];
            if (dtrslt.Rows.Count > 0)
            {
                if (Convert.ToString(ViewState["sortdr"]) == "Asc")
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Desc";
                    ViewState["sortdr"] = "Desc";
                }
                else
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Asc";
                    ViewState["sortdr"] = "Asc";
                }
                GridView1.DataSource = dtrslt;
                GridView1.DataBind();

            }
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

            parking.Name = txt_search.Text.Trim();
            parking.Sql_Operation = "search";
            parking.Society_Id = society_id.Value;
            var result = parking_Allotment.search_park(parking);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }

        public void runproc_save(String operation)
        {
            if (vehicle_id.Value != "")
                parking.vehicle_Id = Convert.ToInt32(vehicle_id.Value.ToString());
            parking.Sql_Operation = operation;
            parking.Society_Id = society_id.Value;
            parking.flat_Id = Convert.ToInt32(flat_id.Value);
            parking.place_id = Convert.ToInt32(place_id.Value);
            parking.Vehicle_No = TextBox2.Text;
            //parking.Name = txt_name.Text;
            //parking.Park_For = ddl_park_for.SelectedItem.Text;
            //parking.Park_Type = ddl_type.Text;
            //parking.Contact_No = txt_contact_no.Text;
            //parking.Vehicle_No = txt_vehical_no.Text;
            //parking.place_id = Convert.ToInt32(assign_id.Value.ToString());
            var result = parking_Allotment.UpdateParkingAllotment(parking);

            if (result.Sql_Result=="Done")
            { 
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }

            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }

        }

        public void runproc(string operation)
        {
            if (vehicle_id.Value != "")
                parking.vehicle_Id = Convert.ToInt32(vehicle_id.Value);
            parking.Sql_Operation = operation;
            var result = parking_Allotment.UpdateParkingAllotment(parking);

            vehicle_id.Value = result.vehicle_Id.ToString();
            society_id.Value = result.Society_Id;
            flat_id.Value = result.flat_Id.ToString();
            place_id.Value = result.place_id.ToString();
            vehicle_type_id.Value = result.VehicleTypeID.ToString();
          
            fill_drop1();
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {

                runproc_save("AssignPlace");

        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            vehicle_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (vehicle_id.Value != "")
                    parking.vehicle_Id = Convert.ToInt32(vehicle_id.Value);
                parking.Sql_Operation = "Delete";
                parking_Allotment.Parking_Delete(parking);
          
            Response.Redirect("parking_allotment_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("parking_allotment_search.aspx");
        }

     

        
        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label parking_id = (System.Web.UI.WebControls.Label)row.FindControl("parking_id");
                parking.Sql_Operation = "Delete";

                parking.vehicle_Id = Convert.ToInt32(parking_id.Text);
                parking_Allotment.Parking_Delete(parking);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
          
            Park_Allotment_GridBind();
        }

   
        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Park_Allotment_GridBind();
        }

        protected void Repeater_1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (flat_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == flat_id.Value)
                        TextBox1.Text = link.Text;
                }
            }

        }

        protected void Repeater_1_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
            flat_id.Value = e.CommandArgument.ToString();
                vehicle_type_id.Value = null;
                TextBox2.Text = null;
               var dt = parking_Allotment.Fill_list(society_id.Value, "fill_vehicle", flat_id.Value, "0");
                Repeater2.DataSource = dt;
                Repeater2.DataBind();
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (vehicle_type_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == vehicle_type_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                string arg = e.CommandArgument.ToString();
                string[] parts = arg.Split('|');

                string vehicleId = parts[1];
                vehicle_type_id.Value = parts[0];
                vehicle_id.Value = vehicleId;
                TextBox3.Text = null;
                var dt = parking_Allotment.Fill_list(society_id.Value, "fill_parking_place", flat_id.Value, vehicle_type_id.Value);
                Repeater3.DataSource = dt;
                Repeater3.DataBind();
            }

        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (place_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == place_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                place_id.Value = e.CommandArgument.ToString();
            }
        }
    }

}
