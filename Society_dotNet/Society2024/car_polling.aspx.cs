using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Configuration;
using System.Web.Configuration;
using System.Web.Services.Description;
using BusinessLogic.BL;
using DBCode.DataClass;
using System.Windows.Forms;

namespace Society
{
    public partial class car_polling : Page
    {

        carpolling car = new carpolling();
        BL_Car_Polling BL_Car = new BL_Car_Polling();
        //    stored st = new stored();
      
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if
                (!IsPostBack)
            {
                Car_Polling_GridBind();
                txt_time.Text = DateTime.Now.ToString("hh:mm");
            }
            if (Request.QueryString["car_id"] != null)
            {
                car_id.Value = Request.QueryString["car_id"].ToString();
                runproc("Select");
            }

        }

        public void Car_Polling_GridBind()
        {
            DataTable dt = new DataTable();

            car.Sql_Operation = "Grid_Show";
            car.Society_Id = society_id.Value;
            dt = BL_Car.Getcarpolling(car);

            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();

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

        public string runproc_save(String operation)
        {
            if (car_id.Value != "")
                car.Car_Id = Convert.ToInt32(car_id.Value.ToString());
            car.Sql_Operation = operation;
            car.Society_Id = society_id.Value;
            car.C_Name = txt_c_name.Text;
            car.Vehical_No = txt_vehical_no.Text;
            car.Seat = txt_seat.Text;
            car.Time = Convert.ToDateTime(txt_time.Text.ToString());
            car.Date = Convert.ToDateTime(txt_date.Text);
            car.Destination = txt_destination.Text;
            car.Charges = txt_charges.Text;
            var result = BL_Car.updatecarpolling(car);
            return result.Sql_Result;

        }

        public void runproc(String operation)
        {
            if (car_id.Value != "")
                car.Car_Id = Convert.ToInt32(car_id.Value);
            car.Sql_Operation = operation;
            var result = BL_Car.updatecarpolling(car);

            car_id.Value = result.Car_Id.ToString();
            society_id.Value = result.Society_Id;
            txt_c_name.Text = result.C_Name;
            txt_vehical_no.Text = result.Vehical_No;
            txt_seat.Text = result.Seat;
            txt_time.TextMode = TextBoxMode.SingleLine;
            txt_time.Text = result.Time.ToString("hh:mm tt");
            txt_date.Text = result.Date.ToString("yyyy-MM-dd");
            txt_destination.Text = result.Destination;
            txt_charges.Text = result.Charges;
        }

        protected void btn_save_Click(object sender, EventArgs e)
    {
        if (Label10.Text == "")
        {
            runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
        else
        {
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

        }
    }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("car_polling.aspx");
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                if (car_id.Value != "")
                    car.Car_Id = Convert.ToInt32(car_id.Value);
                car.Sql_Operation = "Delete";
                BL_Car.Delete_Car_Polling(car);
           
            Response.Redirect("car_polling.aspx");

        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            car_id.Value = id;
            runproc("Select");
            btn_delete.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label car_id = (System.Web.UI.WebControls.Label)row.FindControl("car_id");
                car.Sql_Operation = "Delete";

                car.Car_Id = Convert.ToInt32(car_id.Text);
                BL_Car.Delete_Car_Polling(car);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
          
            Car_Polling_GridBind();

        }


        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void txt_vehical_no_TextChanged(object sender, EventArgs e)
        {
            if (txt_vehical_no.Text.Trim() != "")
            {
                if (car_id.Value != "")
                    car.Car_Id = Convert.ToInt32(car_id.Value);
                car.Sql_Operation = "check_no";
                car.Society_Id = society_id.Value;
                car.Vehical_No = txt_vehical_no.Text;
                var result = BL_Car.Vehical_No_Changed(car);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                Label10.Text = result.Sql_Result;
            }
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            car.C_Name = txt_search.Text.Trim();
            car.Sql_Operation = "search";
            car.Society_Id = society_id.Value;
            var result = BL_Car.search_car(car);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }


        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Car_Polling_GridBind();
        }

        protected void GridView1_PageIndexChanging1(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Car_Polling_GridBind();
        }
    }

}
