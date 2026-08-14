using BusinessLogic.BL;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using System.Windows.Forms;

namespace Society2024
{ 
    public partial class Facility_master : System.Web.UI.Page
    {
        facility GetFacility = new facility();
        BL_facility bL_Party = new BL_facility();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();


            if (!IsPostBack)
            {
                //SetToggleState(false);
                facility_gridbind();

            } 
        }

        public void facility_gridbind()
        {
            DataTable dt = new DataTable();
            GetFacility.Sql_Operation = "Grid_Show";
            GetFacility.Society_Id = society_id.Value;
            dt = bL_Party.getfacility(GetFacility);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
        }

        public string runproc_save(string operation)
            
        {
            //bool isEnabled = hdnToggleValue.Value == "true";
            //bool temp = bool.TryParse(hdnToggleValue.Value, out isEnabled);

            //System.Diagnostics.Debug.WriteLine($"Hidden field value: {temp}");


            if (facility_id.Value != "")
                GetFacility.facility_id = Convert.ToInt32(facility_id.Value.ToString());
            GetFacility.Society_Id = society_id.Value;
            GetFacility.Name = txt_facility.Text;
            GetFacility.Cost = Convert.ToDecimal(txt_cost.Text);
            GetFacility.Max_capacity = Convert.ToInt32(txt_capacity.Text);
            if (radiobtn1.Checked) GetFacility.Slot = 1; else if (radiobtn3.Checked) GetFacility.Slot = 2; else GetFacility.Slot = 3;
            GetFacility.Description = txt_desc.Text;
            GetFacility.Sql_Operation = operation;
            GetFacility.IsActive = true ;
            //bool isChecked = hdnToggleValue.Value == "true";
            var result = bL_Party.update_facility(GetFacility);
            facility_id.Value = result.facility_id.ToString();

            return result.Sql_Result;
        }

        private void runproc_facility(string operation)
        {
            if (facility_id.Value != "")
                GetFacility.facility_id = Convert.ToInt32(facility_id.Value.ToString());

            GetFacility.Sql_Operation = operation;
            var result = bL_Party.select_facility(GetFacility);

            (facility_id.Value) = result.facility_id.ToString();
            society_id.Value = result.Society_Id;
            txt_facility.Text = result.Name;
            txt_cost.Text = result.Cost.ToString();
            txt_capacity.Text = result.Max_capacity.ToString();
            txt_desc.Text = result.Description;
            if (result.Slot == 1)
                radiobtn1.Checked = true;
            else if (result.Slot == 2)
                radiobtn3.Checked = true;
            else
            {
                slot_gridbind();
                radiobtn2.Checked = true;
                panel1.Visible = true;
            }

        }

        public void runproc_slot_save(string operation)
        {
            if (slot_id.Value != "")
                GetFacility.Slot_Id = Convert.ToInt32(slot_id.Value.ToString());
            GetFacility.facility_id = Convert.ToInt32(facility_id.Value);
            GetFacility.Society_Id = society_id.Value;
            GetFacility.Sql_Operation = operation;

            GetFacility.Start_Time = Convert.ToDateTime(txt_from.Text);
            GetFacility.To_Time = Convert.ToDateTime(txt_to.Text);
            bL_Party.runproc_slot(GetFacility);
            slot_gridbind();
        }

        public void slot_gridbind()
        {
            DataTable dt = new DataTable();
            GetFacility.Sql_Operation = "Grid_Show_Slot";
            GetFacility.facility_id = Convert.ToInt32(facility_id.Value);
            dt = bL_Party.getslot(GetFacility);
            GridView2.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView2.DataBind();
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

        protected void btn_save_Click(object sender, EventArgs e)
        {
            var str = runproc_save("Update");
            facility_gridbind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "SuccessEntry();", true);
        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (facility_id.Value != "")
                GetFacility.facility_id = Convert.ToInt32(facility_id.Value);
            GetFacility.Sql_Operation = "Delete";
            bL_Party.delete(GetFacility);

            Response.Redirect("Facility_Master.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("Facility_Master.aspx");
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            GetFacility.Name = txt_search.Text;
            GetFacility.Sql_Operation = "search";
            GetFacility.Society_Id = society_id.Value;
            var result = bL_Party.search_facility(GetFacility);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            facility_id.Value = id;
            runproc_facility("Select");

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        public void cleardata()
        {
            txt_slot.Text = "";
            txt_from.Text = "";
            txt_to.Text = "";

        }
        protected void btn_add_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            runproc_slot_save("S_Update");
            slot_id.Value = null;
            cleardata();
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void radiobtn1_CheckedChanged(object sender, EventArgs e)
        {
            panel1.Visible = false;
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void radiobtn2_CheckedChanged(object sender, EventArgs e)
        {
            panel1.Visible = true;
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }
        protected void radiobtn3_CheckedChanged(object sender, EventArgs e)
        {
            panel1.Visible = false;
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void GridView2_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView2.Rows[e.RowIndex];

            System.Web.UI.WebControls.Label id = (System.Web.UI.WebControls.Label)row.FindControl("slot_id");
            GetFacility.Sql_Operation = "Delete_Slot";

            GetFacility.Slot_Id = Convert.ToInt32(id.Text);
            bL_Party.delete_slot(GetFacility);
            slot_gridbind();

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void GridView2_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            facility_gridbind();
        }
    }
}