using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web.UI.WebControls;
using System.Data;
using Page = System.Web.UI.Page;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.Windows.Forms;
using System.Web.UI;
using BusinessLogic.BL;
//using System.IdentityModel.Metadata;

namespace Society
{
    public partial class caretaker : Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        BL_CareTaker_Master bL_Caretaker = new BL_CareTaker_Master();
        Caretaker care = new Caretaker();

        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["name"] == null) 
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Allbound();

                Caretaker_Gridbind();
                //fill_drop1();
            }
        }

        protected void Allbound()
        {

            DataTable dt = new DataTable();
            dt = bL_Caretaker.Fill_list(Session["society_id"].ToString(), "fill_wing");
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Caretaker.Fill_list(Session["society_id"].ToString(), "fill_doc");
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = bL_Caretaker.Fill_list(Session["society_id"].ToString(), "fill_state");
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
        
        }


       
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                building_wing_id.Value = e.CommandArgument.ToString();

               var dt = bL_Caretaker.Fill_list(building_wing_id.Value, "fill_flat");
                Repeater4.DataSource = dt;
                Repeater4.DataBind();
            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                doc_id.Value = e.CommandArgument.ToString();

            }

        }


        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                state_id.Value = e.CommandArgument.ToString();

            }
        }
        public void fill_drop1()
        {

            //String sql_query = "Select *  from doc_master";
            //bL_Caretaker.fill_drop(ddl_doc_name, sql_query, "doc_name", "doc_id");

            //String sql_query1 = "Select *  from state";
            //bL_Caretaker.fill_drop(ddl_state, sql_query1, "state", "state_id");

            //String sql_query2 = "Select wing_id,(name + w_name) as name from global_society_view";
            //bL_Caretaker.fill_drop(ddl_build_wing1, sql_query2, "name", "wing_id");
        }

        public void Caretaker_Gridbind()
        {
            DataTable dt = new DataTable();
            dt = bL_Caretaker.CareTakerDetails(society_id.Value);
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

        protected void btn_search_Click(object sender, EventArgs e)
        {

            care.C_Name = txt_search.Text.Trim();
            care.Sql_Operation = "search";
            care.Society_Id = society_id.Value;
            var result = bL_Caretaker.search_caretaker(care);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        public string runproc_save(string operation)
        {
            if (caretaker_id.Value != "")
                care.Caretaker_Id = Convert.ToInt32(caretaker_id.Value);
            care.Sql_Operation = operation;
            care.Society_Id = society_id.Value;
            care.Wing_Id = Convert.ToInt32(building_wing_id.Value.ToString());
            care.Flat_No = txtflat.Text;
            care.C_Name = txt_c_name.Text;
            care.doc_id = Convert.ToInt32(doc_id.Value.ToString());
            care.C_Address = txt_c_address.Text;
            care.Area = txt_area.Text;
            care.Mobile_No = txt_mobile_no.Text;
            care.Email = txt_email.Text;
            care.City = txt_city.Text;
            care.State_Id = Convert.ToInt32(state_id.Value.ToString());
            care.Pincode = txt_pincode.Text;
            //care.Doc_Executed = txt_doc_executed.Text;
            var result = bL_Caretaker.updateCareTakerDetails(care);
            return result.Sql_Result;
        }

        public void runproc(string operation)
        {
            if (caretaker_id.Value != "")
               care.Caretaker_Id = Convert.ToInt32(caretaker_id.Value);
            care.Sql_Operation = operation;
            var result = bL_Caretaker.updateCareTakerDetails(care);

            caretaker_id.Value = result.Caretaker_Id.ToString();
            society_id.Value = result.Society_Id;
            building_wing_id.Value = result.Wing_Id.ToString();
            txtflat.Text = result.Flat_No;
            txt_c_name.Text = result.C_Name;
            doc_id.Value = result.doc_id.ToString();
            txt_c_address.Text = result.C_Address;
            txt_area.Text = result.Area;
            txt_mobile_no.Text = result.Mobile_No;
            txt_email.Text = result.Email;
            txt_city.Text = result.City;
            state_id.Value = result.State_Id.ToString();
            txt_pincode.Text = result.Pincode;
            //txt_d.Text = result.Doc_Executed;
            Allbound();

            var dt = bL_Caretaker.Fill_list(building_wing_id.Value, "fill_flat");
            Repeater4.DataSource = dt;
            Repeater4.DataBind();

        }


        protected void btn_save_Click(object sender, EventArgs e)
        {
            string str = runproc_save("Update");

            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            else
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

            }

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("caretaker.aspx");
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
                if (caretaker_id.Value != "")
                    care.Caretaker_Id = Convert.ToInt32(caretaker_id.Value);
                care.Sql_Operation = "Delete";
                bL_Caretaker.delete(care);
            
            Response.Redirect("caretaker.aspx");

        }



        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            caretaker_id.Value = id;
            
            runproc("Select");
            btn_delete.Visible = true;

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label c_id = (System.Web.UI.WebControls.Label)row.FindControl("caretaker_id");
                care.Sql_Operation = "Delete";

                care.Caretaker_Id = Convert.ToInt32(c_id.Text);
                bL_Caretaker.delete(care);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
          
            Caretaker_Gridbind();
        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Caretaker_Gridbind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (building_wing_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == building_wing_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (doc_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == doc_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (state_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == state_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }

        protected void Repeater4_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (!string.IsNullOrEmpty(txt_flat_id.Value))
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == txt_flat_id.Value)
                    {
                        txtflat.Text = link.Text; // Populate textbox with the flat/unit name
                    }
                }
            }
        }


        protected void Repeater4_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                string flatId = e.CommandArgument.ToString();

                txt_flat_id.Value = flatId; // Save the selected flat ID
                                            // Optionally: fetch flat name from DB and set in textbox
                txtflat.Text = ((LinkButton)e.CommandSource).Text;
            }
        }

    }
}
