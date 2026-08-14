using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class Charges : System.Web.UI.Page
    {
        maintenance Maintenance = new maintenance();

        BL_Maintenance_Master bL_Maintenance = new BL_Maintenance_Master();

        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }


            if (!IsPostBack)
            {
                Charge_Gridbind();
            }
        }

        public void Charge_Gridbind()
        {
            DataTable dt = new DataTable();
            Maintenance.Sql_Operation = "Grid_Show";
            Maintenance.Society_Id = Session["society_id"].ToString();
            dt = bL_Maintenance.getCharges(Maintenance);
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }


        protected void btn_save_Click(object sender, EventArgs e)
        {
            
                runproc_save();
           

        }


        protected void dueDate_SelectedIndexChanged(object sender, EventArgs e)
        {
            
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            charge_id.Value = e.CommandArgument.ToString();
            runproc_select();

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_modal').modal('show');", true);
        }


        protected void runproc_select()
        {
            Maintenance.Charges_id = Convert.ToInt32(charge_id.Value);
            Maintenance.Society_Id = Session["society_id"].ToString();
            Maintenance.Sql_Operation = "select";
            var result = bL_Maintenance.select_charges_details(Maintenance);

            //chkStatus.Checked = result.Status;
            txtNatureOfCharge.Text = result.Nature_Of_Charge;
            txtAmount.Text = result.Amount;
            ddlType.SelectedValue = result.BillType ? "1" : "0";


        }

        protected void runproc_save()
        {
            if(charge_id.Value != "")
            {
                Maintenance.Charges_id = Convert.ToInt32(charge_id.Value);
            }
            Maintenance.Sql_Operation = "insert";
            Maintenance.Society_Id = Session["society_id"].ToString();
            Maintenance.Nature_Of_Charge = txtNatureOfCharge.Text.Trim();
            Maintenance.Amount = txtAmount.Text.Trim();
            Maintenance.Status = true;
            Maintenance.Creator = Convert.ToInt32(Session["UserId"]);
            Maintenance.BillType = ddlType.SelectedValue == "1" ? true : false;
            bL_Maintenance.add_Charges(Maintenance);
            Charge_Gridbind();
        }

        protected void runproc_update() { }
    }
}