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
using System.IO;
using Society2024;
using BusinessLogic.BL;
using Utility.DataClass;

namespace Society
{
    public partial class upload_doc_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        upload_doc doc = new upload_doc();
        BL_Upload_Doc BL_Upload = new BL_Upload_Doc();

      
       
        string path;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                //fill_drop1();

                Allbound();

                upload_doc_gridbind();  
                

            }

        }

        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = BL_Upload.Fill_list(society_id.Value, "fill_doc", building_id.Value, wing_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = BL_Upload.Fill_list(society_id.Value, "fill_build", building_id.Value, wing_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = BL_Upload.Fill_list(society_id.Value, "fill_wing", building_id.Value, wing_id.Value);
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            dt = BL_Upload.Fill_list(society_id.Value, "fill_flat", building_id.Value, wing_id.Value);
            Repeater4.DataSource = dt;
            Repeater4.DataBind();
           
        }

      
        

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                doc_id.Value = e.CommandArgument.ToString();

            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory1")
            {
                building_id.Value = e.CommandArgument.ToString();
                lbl_building.Text = e.CommandArgument.ToString();
                var dt = BL_Upload.Fill_list(society_id.Value, "fill_wing", building_id.Value, wing_id.Value);
                Repeater3.DataSource = dt;
                Repeater3.DataBind();
              
            }

        }
        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory2")
            {
                wing_id.Value = e.CommandArgument.ToString();
                var dt = BL_Upload.Fill_list(society_id.Value, "fill_flat", building_id.Value, wing_id.Value);
                Repeater4.DataSource = dt;
                Repeater4.DataBind();
           
            }

        }
        protected void CategoryRepeater_ItemCommand4(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                flat_no_id.Value = e.CommandArgument.ToString();

            }

        }

        public void uplaod_doc()
        {
            string createfolder = Server.MapPath("~/Documents") + "/" + TextBox2.Text + "/" + TextBox3.Text + "/" + TextBox4.Text + "/" + (TextBox1.Text) + "/";
            Directory.CreateDirectory(createfolder);

            if (file_name.HasFiles)
            {

                foreach (HttpPostedFile file_name in file_name.PostedFiles)
                {
                    file_name.SaveAs(Path.Combine(Server.MapPath(("~/Documents") + "/" + TextBox2.Text + "/" +TextBox3.Text + "/"+ TextBox4.Text + "/" + (TextBox1.Text) + "/" + file_name.FileName)));
                    listofuploadedfiles.Text += file_name.FileName + "<br/>";
                }

                path = Path.Combine(Server.MapPath(("~/Documents") + "/" + TextBox2.Text + "/" + TextBox3.Text + "/"  + TextBox4.Text + "/" + (TextBox1.Text) + "/" + file_name.FileName));
            
            }
        }


        public void runproc(string operation)
        {

            if (file_id.Value!= "")
                doc.File_Id = Convert.ToInt32(file_id.Value);
            doc.Sql_Operation = operation;

            var result = BL_Upload.updatedocsearch(doc);
             
            //(parking_id.Value) = result.parking_id.ToString();
            society_id.Value = result.Society_Id;
            listofuploadedfiles.Text = Path.GetFileName(result.File_Save_Path);
            doc_id.Value = result.doc_id.ToString();
            building_id.Value = result.build_id.ToString();
            wing_id.Value = result.wing_id.ToString();
            flat_no_id.Value = result.flat_id.ToString();
            
            txt_date.Text = result.Date.ToString("yyyy-MM-dd");
            Allbound();


        } 
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            file_id.Value = id;
            runproc("Select");
            //txt_wing.Visible = true;
            //ddl_wing.Visible = false;
            
            //txt_no.Visible = true;
            //ddl_flatno.Visible = false;
            Label2.Visible = false;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }
        public string runproc_save(string operation)
        {
            if (file_id.Value != "")
                doc.File_Id = Convert.ToInt32(file_id.Value);
            doc.Sql_Operation = operation;
            doc.Society_Id = society_id.Value;
            doc.File_Save_Path = path;
            doc.doc_id = Convert.ToInt32(doc_id.Value.ToString());
            doc.build_id = Convert.ToInt32(building_id.Value.ToString());
            doc.wing_id = Convert.ToInt32(wing_id.Value.ToString());
          
            doc.flat_id = Convert.ToInt32(flat_no_id.Value.ToString());
            doc.Date = Convert.ToDateTime(txt_date.Text);
            var result = BL_Upload.updatedocsearch(doc);
            return result.Sql_Result;
   
        }





        protected void upload_Click(object sender, EventArgs e)
        {
            //    uplaod_doc();
            //    runproc("Update");
            //    Response.Redirect("upload_doc_search.aspx");
            if (!file_name.HasFile)
            {
               
                listofuploadedfiles.Text = "Please select a file before uploading.";
                listofuploadedfiles.ForeColor = System.Drawing.Color.Red;
                return;
            }
            {
                uplaod_doc();
                string str = runproc_save("Update");

                if (str == "Done")
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
                else
                {
                    ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

                }

            }
            }
            protected void upload_doc_gridbind()
        {
            DataTable dt = new DataTable();
            doc.Sql_Operation= "Grid_Show";
            doc.Society_Id = society_id.Value;
            dt = BL_Upload.GetUploadDoc(doc);
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
            doc.Doc_Name = txt_search.Text.Trim();
            doc.Sql_Operation = "search";
            doc.Society_Id = society_id.Value;
            var result = BL_Upload.search_upload_doc(doc);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("upload_doc_search.aspx");
            ScriptManager.RegisterStartupScript(this, this.GetType(), "HideModal", "$('#edit_model').modal('hide');", true);
        }


        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            Label file_id = (Label)row.FindControl("file_id");
            doc.Sql_Operation = "Delete";
            doc.File_Id = Convert.ToInt32(file_id.Text);
            BL_Upload.delete(doc);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            upload_doc_gridbind();

        }

        protected void ddl_flatno_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (flat_no_id.Value != "")
            {
                if (file_id.Value != "")
                {
                    doc.File_Id = Convert.ToInt32(file_id.Value);
                    doc.Sql_Operation = "check_no";
                    //owner.owner_id = Convert.ToInt32(owner_id.Value);
                    doc.Society_Id = society_id.Value;
                    doc.doc_id = Convert.ToInt32(doc_id.Value.ToString());
                    doc.flat_id = Convert.ToInt32(flat_no_id.Value.ToString());


                    var result = BL_Upload.flat_no_selectedIndexChanged(doc);
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
                    //Label7.Text = result.Sql_Result;
                }
            }
        }

        protected void ddl_build_SelectedIndexChanged(object sender, EventArgs e)
        {
            //if (ddl_build.Text != "select")
            //{

            //    string sql1 = "Select distinct w_name,wing_id from dbo.flat_types where  society_id='" + society_id.Value + "' and  name='" + ddl_build.SelectedItem.Text + "' ";
            //    BL_Upload.fill_drop(ddl_wing, sql1, "w_name", "wing_id");
            //    ddl_wing_SelectedIndexChanged(sender, e);

            //}

        }

        protected void ddl_wing_SelectedIndexChanged(object sender, EventArgs e)
        {
            //if (ddl_wing.Text != "select")
            //{

            //    string sql1 = "Select distinct flat_no,flat_id from dbo.flat_types where  society_id='" + society_id.Value + "' and build_id=" + ddl_build.SelectedValue + " and wing_id=" + ddl_wing.SelectedValue;
            //    BL_Upload.fill_drop(ddl_flatno, sql1, "flat_no", "flat_id");

            //}
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            upload_doc_gridbind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (doc_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == doc_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (building_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == building_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (wing_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == wing_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }

        protected void Repeater4_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (flat_no_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == flat_no_id.Value)
                        TextBox4.Text = link.Text;
                }
            }
        }
    }
}

    
