using BusinessLogic.BL;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class v_staff_management : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        staff Staff = new staff();
        BL_v_Staff bL_Staff = new BL_v_Staff();
        DataTable dt = new DataTable();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["village_id"].ToString();


            if (!IsPostBack)
            {

                Staff.Sql_Operation = "get_staff_role";
                Staff.Society_Id = Session["village_id"].ToString();
                dt = bL_Staff.getstaffdetails(Staff);

                categoryRepeater.DataSource = dt;
                categoryRepeater.DataBind();
                staff_Gridbind();

            }

        }



        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                role_id.Value = e.CommandArgument.ToString();

            }
        }
        //public void fill_drop1()
        //{
        //    String sql_query = "Select *  from staff_role where active_status=0 and society_id='" + society_id.Value + "'";
        //    bL_Staff.fill_drop(ddl_role, sql_query, "role", "role_id");

        //}
        public void staff_Gridbind()
        {
            DataTable dt = new DataTable();
            Staff.Sql_Operation = "Grid_Show";
            Staff.Society_Id = society_id.Value;
            dt = bL_Staff.getstaffdetails(Staff);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            GridView3.DataSource = dt;
            GridView3.DataBind();
        }
         
        protected void btn_save_Click(object sender, EventArgs e)
        {

            var str = runproc_save("Update");
            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);

            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

            }

        }

        public string runproc_save(string operation)
        {
            if (staff_id.Value != "")
                Staff.staff_id = Convert.ToInt32(staff_id.Value);
            Staff.Sql_Operation = operation;
            Staff.Society_Id = Session["village_id"].ToString();

            Staff.Name = txt_name.Text;
            Staff.Address = txt_address.Text;
            Staff.Contact_No = txt_contact.Text;
            Staff.Salary = Convert.ToDecimal(txt_salary.Text);
            Staff.Email = txt_email.Text == "" ? "N/A" : txt_email.Text;
            Staff.Date_Of_Join = Convert.ToDateTime(txt_doj.Text);
            if (role_id.Value != "")
                Staff.role_id = Convert.ToInt32(role_id.Value);
            Staff.role = categoryBox.Text;
            Staff.id_proof = UploadId();
            var result = bL_Staff.update_staff(Staff);
            staff_Gridbind();

            return result.Sql_Result;

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

        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (staff_id.Value != "")
                Staff.staff_id = Convert.ToInt32(staff_id.Value);
            Staff.Sql_Operation = "Delete";
            bL_Staff.delete(Staff);

            Response.Redirect("Staff_Master.aspx");

        }
        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label notice_id = (System.Web.UI.WebControls.Label)row.FindControl("staff_id");
            Staff.Sql_Operation = "Delete";

            Staff.staff_id = Convert.ToInt32(notice_id.Text);
            bL_Staff.delete(Staff);

            staff_Gridbind();



        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("Staff_Master.aspx");
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            staff_id.Value = id;
            runproc_staff("Select");
            btn_delete.Visible = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        private void runproc_staff(string operation)
        {
            if (staff_id.Value != "")
                Staff.staff_id = Convert.ToInt32(staff_id.Value.ToString());

            Staff.Sql_Operation = operation;
            var result = bL_Staff.update_staff(Staff);

            (staff_id.Value) = result.staff_id.ToString();
            society_id.Value = result.Society_Id;

            txt_name.Text = result.Name;
            txt_address.Text = result.Address;
            txt_contact.Text = result.Contact_No;
            txt_email.Text = result.Email;
            txt_doj.Text = result.Date_Of_Join.ToString("yyyy-MM-dd");
            if (role_id.Value == "")
                role_id.Value = result.role_id.ToString();

            Staff.Sql_Operation = "fill_staff";
            Staff.Society_Id = society_id.Value;
            dt = bL_Staff.getstaffdetails(Staff);

            categoryRepeater.DataSource = dt;
            categoryRepeater.DataBind();

        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            Staff.Name = txt_search.Text;
            Staff.Sql_Operation = "search";
            Staff.Society_Id = society_id.Value;
            var result = bL_Staff.search_staff(Staff);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        protected void txt_contact_TextChanged(object sender, EventArgs e)
        {
            if (txt_contact.Text.Trim() != "")
            {
                if (staff_id.Value != "")
                {
                    Staff.staff_id = Convert.ToInt32(staff_id.Value);
                    Staff.Sql_Operation = "check_no";
                    Staff.Contact_No = txt_contact.Text;
                    var result = bL_Staff.contact_textchanged(Staff);
                    //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                    Label19.Text = result.Sql_Result;
                }
            }
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            staff_Gridbind();
        }

        protected void categoryRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (role_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    if (link.CommandArgument == role_id.Value)

                        categoryBox.Text = link.Text;

                }

            }

        }

        protected string UploadId()
        {
            string relativeFolder = "/Documents/village_Docs/" + Session["society_name"] + "/";
            string folderPath = Server.MapPath(relativeFolder);

            // Ensure folder exists
            System.IO.Directory.CreateDirectory(folderPath);

            if (FileUpload1.HasFile)
            {
                string originalFileName = System.IO.Path.GetFileName(FileUpload1.FileName);
                string extension = System.IO.Path.GetExtension(originalFileName);
                string baseName = System.IO.Path.GetFileNameWithoutExtension(originalFileName);

                string fileName = originalFileName;
                string filePath = System.IO.Path.Combine(folderPath, fileName);

                int count = 1;

                while (System.IO.File.Exists(filePath))
                {
                    fileName = $"{baseName}({count}){extension}";
                    filePath = System.IO.Path.Combine(folderPath, fileName);
                    count++;
                }

                FileUpload1.SaveAs(filePath);
                return relativeFolder + fileName;
            }

            return string.Empty; // return empty if no file uploaded 
        }




        protected void btnViewFile_Command(object sender, CommandEventArgs e)
        {
            try
            {
                string rawPath = e.CommandArgument?.ToString()?.Trim();

                // Validate path first
                if (string.IsNullOrEmpty(rawPath))
                {
                    iframeFile.Attributes["src"] = "";
                    lblFileMessage.Text = "No file path found or file not uploaded.";
                    lblFileMessage.Visible = true;

                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
                    return;
                }

                // Extract relative path starting from ~/Documents/
                string filePath = Regex.Replace(rawPath, @"^.*(?=Documents)", "~/");

                string physicalPath = Server.MapPath(filePath);

                // Check if file exists
                if (!System.IO.File.Exists(physicalPath))
                {
                    iframeFile.Attributes["src"] = "";
                    lblFileMessage.Text = "File not found or path is invalid.";
                    lblFileMessage.Visible = true;

                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
                    return;
                }

                // If file exists, show it in iframe
                iframeFile.Attributes["src"] = ResolveUrl(filePath);
                lblFileMessage.Visible = false;

                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
            }
            catch
            {
                iframeFile.Attributes["src"] = "";
                lblFileMessage.Text = "An error occurred while loading the document.";
                lblFileMessage.Visible = true;

                ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#fileModal').modal('show');", true);
            }
        }


        //protected void id_upload()
        //{
        //    string createfolder = Server.MapPath("~/Documents/StaffId") + "/" + txt_name.Text + "/";


        //    System.IO.Directory.CreateDirectory(createfolder);

        //    if (FileUpload1.HasFiles)
        //    {

        //        foreach (HttpPostedFile file_name in FileUpload1.PostedFiles)
        //        {
        //            file_name.SaveAs(System.IO.Path.Combine(Server.MapPath("~/Documents/StaffID") + "/" + txt_name.Text + "/" + file_name.FileName));
        //            listofuploadedfiles.Text += file_name.FileName + "<br/>";
        //        }

        //        uploadphotopath.Text = System.IO.Path.Combine(Server.MapPath("~/Documents/StaffID") + "/" + txt_name.Text + "/" + FileUpload1.FileName);

        //    }

        //}
    }
}