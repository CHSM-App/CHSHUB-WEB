using BusinessLogic.BL;
using DataAccessLayer.DA;
using DocumentFormat.OpenXml.Drawing;
using System;
using System.Data;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class contact_master : Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        usefull_Contact contact = new usefull_Contact();
        BL_Contact_Master bL_Contact = new BL_Contact_Master();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
                Response.Redirect("login1.aspx");
            else
                society_id.Value = Session["society_id"].ToString();
             
            if (!IsPostBack)
            {
                
                FillCategoryRepeater(); 

                if (Request.QueryString["usefull_contact_id"] != null)
                {
                    usefull_contact_id.Value = Request.QueryString["usefull_contact_id"];
                    runproc("Select");
                    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
                } 

                btn_search_Click(sender, e);
            }
        }
        private void FillCategoryRepeater(){
            DataTable dt = new DataTable();
            contact.Sql_Operation = "fill_list";
            contact.Society_Id = society_id.Value;
            dt = bL_Contact.GetContactDetails_1(contact);
            //Repeater1.DataSource = dt;
            //Repeater1.DataBind();
            categoryRepeater.DataSource = dt;
            categoryRepeater.DataBind();
        }

        protected void rptTypeFilter_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                string selectedTypeId = e.CommandArgument.ToString();

                contact.Sql_Operation = "Search";
                contact.Society_Id = society_id.Value;
                contact.P_Type = Convert.ToInt32(selectedTypeId);
                contact.P_Name = txt_search.Text.Trim();

                var result = bL_Contact.GetContactDetails_1(contact);
                CardGridView.DataSource = result;
                CardGridView.DataBind();
            }
        }

        protected void CategoryRepeater_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                contact_type_id.Value = e.CommandArgument.ToString();
            }
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            
            runproc_save("Update");

            FillCategoryRepeater();

            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(usefull_contact_id.Value))
            {
                contact.usefull_contact_id = Convert.ToInt32(usefull_contact_id.Value);
                contact.Sql_Operation = "Delete";
                bL_Contact.delete(contact);
            }
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("contact_master.aspx");
        }

        protected void drp_per_type_SelectedIndexChanged(object sender, EventArgs e)
        {
            contact.usefull_contact_id = !string.IsNullOrEmpty(usefull_contact_id.Value) ? Convert.ToInt32(usefull_contact_id.Value) : 0;
            contact.Sql_Operation = "p_name_already_exist";
            contact.P_Name = txt_p_name.Text;
            contact.P_Type = Convert.ToInt32(contact_type_id.Value);
            var result = bL_Contact.Per_Type_SelectIndexChanged(contact);
            //Label10.Text = result.Sql_Result;
            btn_save.Enabled = string.IsNullOrEmpty(result.Sql_Result);
        }

        protected void btn_print_Click(object sender, EventArgs e)
        {
            Response.Redirect("printcontact.aspx");
        }

        protected void lnkEdit_Command(object sender, CommandEventArgs e)
            {
            usefull_contact_id.Value = e.CommandArgument.ToString();
            runproc("Select");
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
            //upModal.Update();
        }

        protected void lnkDelete_Command(object sender, CommandEventArgs e)
        {
            contact.usefull_contact_id = Convert.ToInt32(e.CommandArgument);
            contact.Sql_Operation = "Delete";
            bL_Contact.delete(contact);
            Response.Redirect("contact_master.aspx");
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            contact.Sql_Operation = "Search";
            contact.P_Type = 0;
            contact.P_Name = txt_search.Text.Trim();
            contact.Society_Id = society_id.Value;
            var result = bL_Contact.GetContactDetails_1(contact);
            CardGridView.DataSource = result;
            CardGridView.DataBind();
        }


        private string runproc_save(string operation)
        {
            string path = "";

            if (operation == "Update")
            {
                path = UploadId();
            }

            // Check if contact_type_id is empty
            if (string.IsNullOrEmpty(contact_type_id.Value))
            {
                // Show a message on the UI and stop execution
                ScriptManager.RegisterStartupScript(this, this.GetType(), "alert",
                    "alert('Please select a Contact Type.');", true);
                return "Error"; // or return empty string
            }

            if (!string.IsNullOrEmpty(usefull_contact_id.Value))
                contact.usefull_contact_id = Convert.ToInt32(usefull_contact_id.Value);

            contact.Sql_Operation = operation;
            contact.Society_Id = society_id.Value;
            contact.P_Name = txt_p_name.Text;
            contact.P_Type = Convert.ToInt32(contact_type_id.Value); // safe now
            contact.Org_Name = txt_org_name.Text;
            contact.Contact_Address = txt_org_addr1.Text;
            contact.Address2 = txt_org_addr2.Text;
            contact.Contact_No = txt_org_tel.Text;
            contact.Email = txt_email.Text;
            contact.Remark = txt_remark.Text;
            contact.id_path = path;

            var result = bL_Contact.update_Usefull_Contact_Details(contact);
            return result.Sql_Result;
        }


        private void runproc(string operation)
        {
            if (!string.IsNullOrEmpty(usefull_contact_id.Value))
                contact.usefull_contact_id = Convert.ToInt32(usefull_contact_id.Value);

            contact.Sql_Operation = "select";
            var result = bL_Contact.update_Usefull_Contact_Details(contact);

            usefull_contact_id.Value = result.usefull_contact_id.ToString();
            society_id.Value = result.Society_Id;
            txt_p_name.Text = result.P_Name;
            contact_type_id.Value = result.P_Type.ToString();
            txt_org_name.Text = result.Org_Name;
            txt_org_addr1.Text = result.Contact_Address;
            txt_org_addr2.Text = result.Address2;
            txt_org_tel.Text = result.Contact_No;
            txt_email.Text = result.Email;
            txt_remark.Text = result.Remark;
            listofuploadedfiles.Text = result.id_path;
            FillCategoryRepeater();
        }

        protected void CardRepeater_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (usefull_contact_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == usefull_contact_id.Value)
                        categoryBox.Text = link.Text;
                }

            }
        }

        protected string UploadId()
        {
            string relativeFolder = "/Documents/ContactID/" + Session["society_name"] + "/";
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


    }
}