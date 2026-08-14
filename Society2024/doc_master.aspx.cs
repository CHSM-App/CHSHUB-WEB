using BusinessLogic.BL;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society

{
    public partial class doc_master : System.Web.UI.Page
    {
        //string cs = ConfigurationManager.ConnectionStrings["DBCS"].ConnectionString;
        upload_doc doc = new upload_doc();
        BL_Upload_Doc bL_Upload_Doc = new BL_Upload_Doc();


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
                BindDocuments();
                //BindRecycleBin();
                //AutoCleanRecycleBin();
            }


        }


        // 📌 Upload new document
        protected void btn_upload_Click(object sender, EventArgs e)
        {
            try
            {
                if (!FileUpload1.HasFile)
                {
                    lbl_message.Text = "Please select a file.";
                    return;
                }

                string docName = txt_document_name.Text.Trim();
                string tags = txt_tags.Text.Trim();
                string desc = txt_description.Text.Trim();

                int fileSize = FileUpload1.PostedFile.ContentLength;

                if (fileSize > 10 * 1024 * 1024) // 10 MB
                {

                    lbl_message.Text = "File too large. Max 10MB allowed.";
                    //return;
                }

                doc.Sql_Operation = "Update";
                doc.Society_Id = society_id.Value;
                doc.Tag = tags;
                doc.Description = desc;
                doc.File_Save_Path = UploadId();
                doc.Doc_Name = docName;

                bL_Upload_Doc.updatedocsearch(doc);
            }
            catch(Exception ex)
            {
                lblFileMessage.Text = ex.ToString();
            }

            Response.Redirect("doc_master.aspx");

        }

        // 📌 Bind uploaded docs
        private void BindDocuments(string search = "")
        {
            doc.Doc_Name = search;
            doc.Sql_Operation = "search";
            doc.Society_Id = society_id.Value;

            var result = bL_Upload_Doc.search_upload_doc(doc);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();


        }

        // 📌 Search
        protected void btn_search_Click(object sender, EventArgs e)
        {
            BindDocuments(txt_search.Text.Trim());
        }

        protected void btnClearSearch_Click(object sender, EventArgs e)
        {
            txt_search.Text = "";
            BindDocuments();
        }

        public void runproc(string operation)
        {

            if (file_Id.Value != "")
                doc.File_Id = Convert.ToInt32(file_Id.Value);
            doc.Sql_Operation = operation;

            var result = bL_Upload_Doc.updatedocsearch(doc);
            txt_document_name.Text = result.Doc_Name;
            txt_tags.Text = result.Tag;
            txt_description.Text = result.Description;

            //(parking_id.Value) = result.parking_id.ToString();
            society_id.Value = result.Society_Id;
            //uploa.Text = Path.GetFileName(result.File_Save_Path);

            //txt_date.Text = result.Date.ToString("yyyy-MM-dd");
            //Allbound();


        }

        // 📌 Grid commands (Edit/Delete)
        protected void GridView1_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            //int docId = Convert.ToInt32(e.CommandArgument);
            //file_Id.Value = docId.ToString();
            //runproc("Select");
            //ScriptManager.RegisterStartupScript(this, GetType(), "showModal", "$('#edit_model').modal('show');", true);

        }

        // 📌 Bind recycle bin
        private void BindRecycleBin(string search = "")
        {
            //using (SqlConnection con = new SqlConnection(cs))
            //{
            //    string query = "SELECT * FROM tbl_documents WHERE is_deleted = 1";
            //    if (!string.IsNullOrEmpty(search))
            //        query += " AND document_name LIKE @search";

            //    SqlDataAdapter da = new SqlDataAdapter(query, con);
            //    da.SelectCommand.Parameters.AddWithValue("@search", "%" + search + "%");
            //    DataTable dt = new DataTable();
            //    da.Fill(dt);

            //    GridView_Recycle.DataSource = dt;
            //    GridView_Recycle.DataBind();
            //}
        }

        // 📌 Recycle bin search
        protected void txt_recycle_search_TextChanged(object sender, EventArgs e)
        {
            BindRecycleBin(txt_recycle_search.Text.Trim());
        }

        // 📌 Empty recycle bin
        protected void btn_empty_recycle_Click(object sender, EventArgs e)
        {
            //using (SqlConnection con = new SqlConnection(cs))
            //{
            //    string query = "DELETE FROM tbl_documents WHERE is_deleted=1";
            //    SqlCommand cmd = new SqlCommand(query, con);
            //    con.Open();
            //    cmd.ExecuteNonQuery();
            //}
            //BindRecycleBin();
        }

        // 📌 Recycle bin actions
        protected void GridView_Recycle_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            //int docId = Convert.ToInt32(e.CommandArgument);

            //if (e.CommandName == "RestoreDocument")
            //{
            //    using (SqlConnection con = new SqlConnection(cs))
            //    {
            //        string query = "UPDATE tbl_documents SET is_deleted=0, deleted_date=NULL WHERE doc_id=@id";
            //        SqlCommand cmd = new SqlCommand(query, con);
            //        cmd.Parameters.AddWithValue("@id", docId);
            //        con.Open();
            //        cmd.ExecuteNonQuery();
            //    }
            //    ScriptManager.RegisterStartupScript(this, GetType(), "showRestore", "RestoreSuccess();", true);
            //    BindDocuments();
            //    BindRecycleBin();
            //}
            //else if (e.CommandName == "PermanentDelete")
            //{
            //    using (SqlConnection con = new SqlConnection(cs))
            //    {
            //        string query = "DELETE FROM tbl_documents WHERE doc_id=@id";
            //        SqlCommand cmd = new SqlCommand(query, con);
            //        cmd.Parameters.AddWithValue("@id", docId);
            //        con.Open();
            //        cmd.ExecuteNonQuery();
            //    }
            //    BindRecycleBin();
            //}
        }

        // 📌 Auto clean recycle bin after 30 days
        private void AutoCleanRecycleBin()
        {
            //using (SqlConnection con = new SqlConnection(cs))
            //{
            //    string query = "DELETE FROM tbl_documents WHERE is_deleted=1 AND DATEDIFF(DAY, deleted_date, GETDATE()) > 30";
            //    SqlCommand cmd = new SqlCommand(query, con);
            //    con.Open();
            //    cmd.ExecuteNonQuery();
            //}
        }

        // 📌 Format file size in KB/MB
        public string FormatFileSize(object sizeObj)
        {
            if (sizeObj == DBNull.Value) return "0 KB";
            long size = Convert.ToInt64(sizeObj);
            if (size < 1024) return size + " B";
            if (size < 1024 * 1024) return (size / 1024) + " KB";
            return (size / (1024 * 1024)) + " MB";
        }

        // 📌 Days left before permanent delete
        public string CalculateDaysLeft(object deletedDateObj)
        {
            if (deletedDateObj == DBNull.Value) return "-";
            DateTime deletedDate = Convert.ToDateTime(deletedDateObj);
            int daysLeft = 30 - (int)(DateTime.Now - deletedDate).TotalDays;
            return daysLeft > 0 ? daysLeft + " days" : "Expired";
        }

        protected void Unnamed_Command(object sender, CommandEventArgs e)
        {
            string relativePath = e.CommandArgument.ToString();

            relativePath = Regex.Replace(relativePath, @"^.*(?=UploadedDocs)", "~/");
            // Resolve to virtual path usable in browser
            pdfView.Attributes["src"] = ResolveUrl(relativePath);
            //  main_update_panel.Update();
            ScriptManager.RegisterStartupScript(this, GetType(), "showModal", "$('#docModal').modal('show');", true);
        }


        protected string UploadId()
        {
            string relativeFolder = "/Documents/Docs/" + Session["society_name"] + "/";
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

        protected void btn_delete_Command(object sender, CommandEventArgs e)
        {
            string filePath = e.CommandArgument.ToString();
            try
            {
                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                }

            }
            catch (Exception ex) { }

            bL_Upload_Doc.delete_file(Convert.ToInt32(e.CommandName));

            BindDocuments();

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
    }
}
