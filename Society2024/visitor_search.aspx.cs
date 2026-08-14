 using Society;
using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Collections.Generic;
using Microsoft.Reporting.WebForms;
using DBCode.DataClass.Master_Dataclass;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.EnterpriseServices;
using System.Globalization;
using System.Data.SqlTypes;
using Society2024;
using System.Security.Cryptography;
using System.Web; 
using System.IO; 
using System.Windows.Forms; 
using DocumentFormat.OpenXml.Bibliography;
using BusinessLogic.BL;

namespace Society
{
    partial class visitor_search : Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Visitor visitor = new Visitor();
        BL_Visitor_Master BL_Visitor = new BL_Visitor_Master();
        string path = null; 
        protected void Page_Load(object sender, System.EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();
            society_name.Value = Session["society_name"].ToString();
            if (!IsPostBack)
            {

                //filldrop();
                Visitor_Gridbind();
                btn_in.Visible = true;
                txt_in_date.Text = DateTime.Now.Date.ToString("yyyy-MM-dd");
                txt_in_time.Text = DateTime.Now.ToShortTimeString().ToString();
                txt_out_date.Attributes["max"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_out_date.Enabled = false;
                txt_out_time.Enabled = false;

                Allbound();
               
            }
        }

        protected void Allbound() 
        {
            DataTable dt = new DataTable();
            dt = BL_Visitor.Fill_list("fill_build", building_id.Value, society_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = BL_Visitor.Fill_list("fill_owner", building_id.Value, society_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                building_id.Value = e.CommandArgument.ToString();
                String str = "Select unit, flat_id from owner_search_vw where  society_id='" + society_id.Value + "'and  build_id=" + building_id.Value;
                repeater.fill_list(Repeater2, str);
            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                visitor_flat_id.Value = e.CommandArgument.ToString();
            }

        }

        public void Visitor_Gridbind()
        {
            DataTable dt = new DataTable();
            visitor.Sql_Operation = "Grid_Show";
            visitor.Society_Id = society_id.Value;
            dt = BL_Visitor.getVisitorDetails(visitor);
            GridView2.DataSource = dt;
            GridView2.DataBind();
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
            visitor.V_Name = "";

            if (searchDateFrom.Value != "" && SearchDateTo.Value != "")
            {
                visitor.In_Date = Convert.ToDateTime(searchDateFrom.Value);
                visitor.Out_Date = Convert.ToDateTime(SearchDateTo.Value);
            }

            if ((SearchDateTo.Value == "") || (searchDateFrom.Value=="") || (!string.IsNullOrEmpty(txt_search.Text) && !(txt_search.Text.Contains(searchDateFrom.Value))))
            {
                visitor.V_Name = txt_search.Text;
            }

            visitor.Sql_Operation = "Search";
            visitor.Society_Id = society_id.Value;
            var result = BL_Visitor.search_visitor(visitor);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }
        public string runproc_save(string operation)
        {

            if (FileUpload1.HasFiles)
            {

                foreach (HttpPostedFile file_name in FileUpload1.PostedFiles)
                {
                    file_name.SaveAs(System.IO.Path.Combine(Server.MapPath("~/Documents") + file_name.FileName));


                }

                path = System.IO.Path.Combine(Server.MapPath("~/Documents") + FileUpload1.FileName);


            }


            if (visitor_id.Value != "")
                visitor.visitor_id = Convert.ToInt32(visitor_id.Value);
            visitor.Sql_Operation = operation;
            visitor.V_Name = txt_v_name.Text;
            visitor.Society_Id = society_id.Value;
            visitor.V_Type = ddl_visiting_type.SelectedValue;
            visitor.In_Date = Convert.ToDateTime(txt_in_date.Text);
            if (txt_out_date.Text != "")
                visitor.Out_Date = Convert.ToDateTime(txt_out_date.Text);
            visitor.In_Time = Convert.ToDateTime(txt_in_time.Text);
            if (txt_out_time.Text != "")
                visitor.Out_Time = Convert.ToDateTime(txt_out_time.Text);
            visitor.Contact_No = txt_contact.Text;
            visitor.build_id = Convert.ToInt32(building_id.Value);
            visitor.flat_id = Convert.ToInt32(visitor_flat_id.Value);
            visitor.Vehical_No = txt_vehical_no.Text;
            visitor.Visiting_Purpose = txt_visiting_purpose.Text;
            visitor.Image = path;

            var result = BL_Visitor.updateVisitorDetails(visitor);
            return result.Sql_Result;
        }




        public void runproc(string operation)
        {
            pnlGuest.Visible = false;
            pnlCab.Visible = false;
            pnlService.Visible = false;
            pnlDelivery.Visible = false;
            if (visitor_id.Value != "")
                visitor.visitor_id = Convert.ToInt32(visitor_id.Value);
            visitor.Sql_Operation = operation;
            var result = BL_Visitor.updateVisitorDetails(visitor);
           

            ddl_visiting_type.SelectedValue = result.V_Type;

            switch (result.V_Type?.ToUpper())
            {
                case "GUEST":
                    pnlGuest.Visible = true;
                    break;

                case "CAB":
                    pnlCab.Visible = true;
                    break;

                case "DELIVERY":
                    pnlDelivery.Visible = true;
                    break;

                case "SERVICE":
                    pnlService.Visible = true;
                    break;

                default:
                    // Optional: handle invalid V_type
                    break;
            }

           
            (visitor_id.Value) = result.visitor_id.ToString();
            society_id.Value = result.Society_Id;
            txtFullName.Text = result.V_Name;
            


            txt_in_date.Text = result.In_Date.ToString("yyyy-MM-dd");
            if (result.Out_Date != DateTime.MinValue)
                txt_out_date.Text = result.Out_Date.ToString("yyyy-MM-dd");
            txt_in_time.Text = result.In_Time.ToString("hh:mm tt");
            if (result.Out_Time != DateTime.MinValue)
                txt_out_time.Text = result.Out_Time.ToString("hh:mm:ss");
            building_id.Value = result.build_id.ToString();
            txtFlatNo.Text = result.flat_id.ToString();
            txtPhoneNo.Text = result.Contact_No;
            txtCabVehicle.Text = result.Vehical_No;
            txtServiceVehicle.Text = result.Vehical_No;
            txtDeliveryVehicle.Text = result.Vehical_No;
            txtCabCompany.Text = result.company;
            txtServiceCompany.Text = result.company;
            txtDeliveryCompany.Text = result.company;
            txtCabLocation.Text = result.location;
            txtGuestAddress.Text = result.location;
            txtGuestPurpose.Text = result.Visiting_Purpose;
            txtPackageDesc.Text = result.Visiting_Purpose;
            path = Path.GetFileName(result.Image);
            imgVisitor.ImageUrl = result.Image;
            // Display the uploaded image
            UploadedImage.ImageUrl = "~/Documents/" + path;


            Allbound();
        }

        protected void btn_in_Click(object sender, EventArgs e)
        {
            runproc_save("Update");

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_out_Click(object sender, EventArgs e)
        {
            runproc_save("Update");
            Response.Redirect("visitor_search.aspx");
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            visitor_id.Value = id;
            runproc("Select");
            btn_in.Visible = false;

            btn_in.Visible = false;
            txt_out_date.Enabled = true;
            txt_out_time.Enabled = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }


        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label visitor_id = (System.Web.UI.WebControls.Label)row.FindControl("visitor_id");
            visitor.Sql_Operation = "Delete";

            visitor.visitor_id = Convert.ToInt32(visitor_id.Text);
            BL_Visitor.deletevisitor(visitor);

            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            Visitor_Gridbind();

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("visitor_search.aspx");
        }

        protected void btn_print_Click(object sender, EventArgs e)
        {
            

        }

        protected void ddl_build_SelectedIndexChanged(object sender, EventArgs e)
        {
            //if (ddl_build.SelectedValue != "select")
            //{
            //    string sql1 = "Select unit, flat_id from owner_search_vw where  society_id='" + society_id.Value + "'and  build_id=" + ddl_build.SelectedValue;
            //    BL_Visitor.fill_drop(ddl_flat, sql1, "unit", "flat_id");
            //}
        }

        protected void ddl_visiting_type_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_visiting_type.SelectedValue == "Delivery")
            {
                delivary.Visible = true;


            }
            else
            {
                delivary.Visible = false;
            }
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Visitor_Gridbind();

        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (building_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == building_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (visitor_flat_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == visitor_flat_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void txt_out_time_TextChanged(object sender, EventArgs e)
        {
            btn_out.Visible = true;
        }

        protected void addButtonClick(object sender, EventArgs e)
        {
            btn_in.Visible = true;
            btn_out.Visible = false;
        }
    }
}



