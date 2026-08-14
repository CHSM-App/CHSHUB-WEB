using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DocumentFormat.OpenXml.Bibliography;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;

namespace Society
{
    public partial class rental_search : System.Web.UI.Page 
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Owner owner = new Owner();
        BL_Owner_Master bL_Owner = new BL_Owner_Master();

        
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            society_id.Value = Session["society_id"].ToString();
            
            if (!IsPostBack)
            {
                Rental_Gridbind();
                //fill_drop1();
                txt_dob.Attributes["max"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_f_dob.Attributes["max"] = DateTime.Now.ToString("yyyy-MM-dd");

                Allbound();
            }

        }

         
        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = bL_Owner.Fill_list(society_id.Value, "Fill_wing",building_lbl.Text, type_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "types", building_lbl.Text, type_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "flat_types", building_lbl.Text, type_id.Value);
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "married", building_lbl.Text, type_id.Value);
            Repeater4.DataSource = dt;
            Repeater4.DataBind();
            //dt = bL_Owner.Fill_list(society_id.Value, "Fill_doc", building_lbl.Text, type_id.Value);
            //Repeater5.DataSource = dt;
            //Repeater5.DataBind();
   

        }

        //protected void Allbound()
        //{
        //    String str1 = "Select wing_id,(name + w_name) as name from global_society_view where society_id='" + society_id.Value + "'";
        //    repeater.fill_list(Repeater1, str1);

        //    String str2 = "Select *  from types ";
        //    repeater.fill_list(Repeater2, str2);

        //    String str3 = "Select society_id,flat_id,(flat_no +'  '+ usage+'  '+ bed +'  '+ sq_ft) as flat_type  from flat where  society_id='" + society_id.Value + "'";
        //    repeater.fill_list(Repeater3, str3);

        //    String str4 = "Select *  from married_status ";
        //    repeater.fill_list(Repeater4, str4);

        //    String str5 = "Select * from doc_master where active_status=0 and society_id='" + society_id.Value + "'";
        //    repeater.fill_list(Repeater5, str5);
        //}
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                Buildling_wing_id.Value = e.CommandArgument.ToString();
                building_lbl.Text = e.CommandArgument.ToString();
                if (!(type_id.Value==""))
                {
                    var dt = bL_Owner.Fill_list(society_id.Value, "flat_types", building_lbl.Text, type_id.Value);
                    Repeater3.DataSource = dt;
                    Repeater3.DataBind();
                }
            }

        }
         
        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                type_id.Value = e.CommandArgument.ToString();
                //string sql1 = "Select distinct flat_type,flat_id from dbo.flat_types where flat_status=0  and active_status=0 and society_id='" + society_id.Value + "' and  wing_id='" + building_lbl.Text + "' and flat_type_id='" + type_id.Value + "'";
                //repeater.fill_list(Repeater3, sql1);
                DataTable dt = new DataTable();
                dt = bL_Owner.Fill_list(society_id.Value, "flat_types", building_lbl.Text, type_id.Value);
                Repeater3.DataSource = dt;
                Repeater3.DataBind();
            }

        }
        protected void CategoryRepeater_ItemCommand3(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                flat_no_id.Value = e.CommandArgument.ToString();

            }

        }
        protected void CategoryRepeater_ItemCommand4(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                married_id.Value = e.CommandArgument.ToString();

            }

        }
        protected void CategoryRepeater_ItemCommand5(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                doc_id_id.Value = e.CommandArgument.ToString();

            }

        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            owner_id.Value = id;
            runproc("Select");
            Family_Details_Gridbind();
            
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        public void Rental_Gridbind()
        {
            DataTable dt = new DataTable();
            owner.Sql_Operation = "Grid_Show";
            owner.Type = "Rent";
            owner.Society_Id = society_id.Value;
            dt = bL_Owner.getRentalDetails(owner);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            GridView3.DataSource = dt;
            GridView3.DataBind();

        }

        public void Family_Details_Gridbind()
        {
            DataTable dt = new DataTable();
            owner.Sql_Operation = "Grid_Show_Family";
            owner.owner_id = Convert.ToInt32(owner_id.Value);
            dt = bL_Owner.getFamilyDetails(owner);
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

        protected void btn_search_Click(object sender, EventArgs e)
        {
            owner.Name = txt_search.Text.Trim();
            owner.Sql_Operation ="search";
            owner.Society_Id = society_id.Value;
            var result = bL_Owner.search_rental(owner);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        public string runproc_save(string operation)
        {
            string type = "Rent";
            List<string> files = UploadFiles();
            if (owner_id.Value != "")
                owner.owner_id = Convert.ToInt32(owner_id.Value);

            owner.Id_Proof = files[0];
            owner.Aggreement_path = files[1];
            owner.Police_ver_path = files[2];


            owner.Sql_Operation = operation;
            owner.Society_Id = society_id.Value;
            owner.wing_id = Convert.ToInt32(Buildling_wing_id.Value.ToString());
            //owner.Poss_Date = Convert.ToDateTime(txt_poss_date.Text.ToString());
            owner.Name = txt_name.Text;
            owner.Pre_Mob = txt_pre_mob.Text;
            owner.Dob = Convert.ToDateTime(txt_dob.Text);
            owner.married_id = Convert.ToInt32(married_id.Value.ToString());
            owner.Occup = txt_occup.Text;
            owner.Monthly_Income = txt_org.Text;
            owner.Off_Addr1 = txt_off_addr1.Text;
            owner.Off_Tel = txt_off_tel.Text;
            owner.Email = txt_email.Text;
            owner.Alter_Mob = txt_add_mob.Text;
            owner.flat_id = Convert.ToInt32(flat_no_id.Value.ToString());
            owner.Flat_type_Id = Convert.ToInt32(type_id.Value.ToString());
            //owner.Photo_Name = uploadphotopath.Text;
            //owner.Id_Proof = uploadidpath.Text;
            owner.Type = type;
            owner.Aggrement_Date = Convert.ToDateTime(txt_aggrement_date.Text.ToString());
            owner.Aggrement_Period_From = Convert.ToDateTime(txt_period_from.Text.ToString());
            owner.Aggrement_Period_To = Convert.ToDateTime(txt_period_to.Text.ToString());
            owner.Police_Verification_Date = Convert.ToDateTime(txt_police_verification.Text.ToString());
            //owner.Doc_Id = Convert.ToInt32(doc_id_id.Value);



            var result = bL_Owner.UpdateRentalDetails(owner);
            owner_id.Value = result.owner_id.ToString();
            
      
            return result.Sql_Result;
        }

        public void runproc_F_Save(string operation)
        {
            if (o_ex_id.Value != "")
                owner.O_Ex_Id = Convert.ToInt32(o_ex_id.Value);
            owner.Sql_Operation = operation;
            owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Society_Id = society_id.Value;
            owner.F_Name = txt_fam_mem_name.Text;
            owner.Relation = txt_owner_rel.Text;
            owner.F_Occu = txt_f_occu.Text;
            owner.F_Dob = txt_f_dob.Text;
            bL_Owner.updateFamilyOwnerDetails(owner);
        }

        public void runproc(String operation)
        {
            if (owner_id.Value != "")
                owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Sql_Operation = operation;

            var result = bL_Owner.runproc(owner);
            if (operation == "Select")
            {

                (owner_id.Value) = result.owner_id.ToString();
                society_id.Value = result.Society_Id;
                Buildling_wing_id.Value = result.wing_id.ToString();
                building_lbl.Text = result.wing_id.ToString();
                //txt_poss_date.Text = result.Poss_Date.ToString("yyyy-MM-dd");
                txt_name.Text = result.Name;
                txt_pre_mob.Text = result.Pre_Mob;
                txt_dob.Text = result.Dob?.ToString("yyyy-MM-dd");
                married_id.Value = result.married_id.ToString();
                txt_occup.Text = result.Occup;
                txt_org.Text = result.Monthly_Income;
                txt_off_addr1.Text = result.Off_Addr1;
                txt_off_tel.Text = result.Off_Tel;
                txt_email.Text = result.Email;
                txt_add_mob.Text = result.Alter_Mob;
                flat_no_id.Value = result.flat_id.ToString();
                doc_id_id.Value = result.Doc_Id.ToString();
                type_id.Value = result.Flat_type_Id.ToString();
                //listofuploadedfiles.Text = result.Id_Proof.ToString();
                //listofuploadedfiles.Text = Path.GetFileName(result.Photo_Name);
                //listofuploadedfiles1.Text = Path.GetFileName(result.Id_Proof);

                txt_aggrement_date.Text = result.Aggrement_Date.ToString("yyyy-MM-dd");
                txt_period_from.Text = result.Aggrement_Period_From.ToString("yyyy-MM-dd");
                txt_period_to.Text = result.Aggrement_Period_To.ToString("yyyy-MM-dd");
                txt_police_verification.Text = result.Police_Verification_Date.ToString("yyyy-MM-dd");

                DataTable dt = new DataTable();
                dt = bL_Owner.Fill_list(society_id.Value, "Fill_wing", building_lbl.Text, type_id.Value);
                Repeater1.DataSource = dt;
                Repeater1.DataBind();
                dt = bL_Owner.Fill_list(society_id.Value, "types", building_lbl.Text, type_id.Value);
                Repeater2.DataSource = dt;
                Repeater2.DataBind();
                dt = bL_Owner.Fill_list(society_id.Value, "flat_types", "0","0");
                Repeater3.DataSource = dt;
                Repeater3.DataBind();
                dt = bL_Owner.Fill_list(society_id.Value, "married", building_lbl.Text, type_id.Value);
                Repeater4.DataSource = dt;
                Repeater4.DataBind();
            }

        }


        protected void btn_save_Click1(object sender, EventArgs e)

        {


            if (Label11.Text == "" )
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);

               
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

            }
        }

        //protected void btn_photo_upload_Click(object sender, EventArgs e)
        //{
        //    string createfolder = Server.MapPath("~/Documents") + "/" + txt_name.Text + "/";

          
        //    System.IO.Directory.CreateDirectory(createfolder);

        //    if (FileUpload1.HasFiles)
        //    {

        //        foreach (HttpPostedFile file_name in FileUpload1.PostedFiles)
        //        {
        //            file_name.SaveAs(System.IO.Path.Combine(Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + file_name.FileName));
        //            listofuploadedfiles.Text += file_name.FileName + "<br/>";
        //        }
               
        //        uploadphotopath.Text = System.IO.Path.Combine(Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + FileUpload1.FileName);
        //    }
        //    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        //}

        //protected void btnotice_id_upload_Click(object sender, EventArgs e)
        //{
        //    string createfolder = Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + (doc_id_id.Value.ToString()) + "/";
           
        //    System.IO.Directory.CreateDirectory(createfolder);

        //    if (FileUpload2.HasFiles)
        //    {

        //        foreach (HttpPostedFile file_name in FileUpload2.PostedFiles)
        //        {
        //            file_name.SaveAs(System.IO.Path.Combine(Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + (doc_id_id.Value.ToString()) + "/" + file_name.FileName));
        //            listofuploadedfiles1.Text += file_name.FileName + "<br/>";

        //        }
        //               uploadidpath.Text = System.IO.Path.Combine(Server.MapPath("~/Documents") + "\\" + txt_name.Text + "\\" + (doc_id_id.Value.ToString()) + "\\" + FileUpload2.FileName);

        //    }
        //    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        //}

        public void cleardata()
        {
            txt_fam_mem_name.Text = "";
            txt_f_dob.Text = "";
            txt_f_occu.Text = "";
            txt_owner_rel.Text = "";
        }
        protected void btn_add_Click(object sender, EventArgs e)

        {
           
            runproc_save("Update");
            runproc_F_Save("D_Update");
            Family_Details_Gridbind();
            cleardata();
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
           
                runproc("Delete");
           
            Response.Redirect("rental_search.aspx");

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label owner_id = (System.Web.UI.WebControls.Label)row.FindControl("owner_id");
                owner.Sql_Operation = "Delete";

                owner.owner_id = Convert.ToInt32(owner_id.Text);
                bL_Owner.OwnerDelete(owner);
           
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            Rental_Gridbind();

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("rental_search.aspx");
        }

        protected void ddl_flat_SelectedIndexChanged(object sender, EventArgs e)
        {

            if (owner_id.Value != "")
                owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Sql_Operation = "check_build";
            owner.wing_id = Convert.ToInt32(Buildling_wing_id.Value);
            owner.flat_id = Convert.ToInt32(flat_no_id.Value);
            var result = bL_Owner.FlatTextChanged(owner);
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            Label11.Text = result.Sql_Result;

        }

        protected void btn_print_Click(object sender, EventArgs e)
        {
            Response.Redirect("printrental.aspx");
        }

        protected void ddl_type_SelectedIndexChanged(object sender, EventArgs e)
        {

            //if (ddl_type.Text != "select")
            //{

            //    string sql1 = "Select distinct flat_type,flat_id from dbo.flat_types where flat_status = 0 and active_status=0 and society_id='" + society_id.Value + "' and  wing_id='" + ddl_build_wing.SelectedValue + "' and flat_type_id='" + ddl_type.SelectedValue +"'";
            //    bL_Owner.fill_drop(ddl_flat, sql1, "flat_type", "flat_id");

            //}

        }

        protected void GridView2_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            MessageBoxButtons buttons = MessageBoxButtons.YesNo;
            DialogResult result = MessageBox.Show("Are you sure want to delete", "delete", buttons);
            if (result == DialogResult.Yes)
            {
                GridViewRow row = (GridViewRow)GridView2.Rows[e.RowIndex];

                System.Web.UI.WebControls.Label id = (System.Web.UI.WebControls.Label)row.FindControl("o_ex_id");
                owner.Sql_Operation = "D_delete";
                owner.O_Ex_Id = Convert.ToInt32(id.Text);
                bL_Owner.FamilyDelete(owner);
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            }
            Family_Details_Gridbind();

        }

        protected void GridView2_Sorting(object sender, GridViewSortEventArgs e)
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
                GridView2.DataSource = dtrslt;
                GridView2.DataBind();


            }
        }

        protected void txt_pre_mob_TextChanged(object sender, EventArgs e)
        {
            if (owner_id.Value != "")
                owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Sql_Operation = "cust_sel";
            owner.Pre_Mob = txt_pre_mob.Text;
            var result = bL_Owner.MobileTextchanged(owner);
            Label31.Text = result.Sql_Result;
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Rental_Gridbind();
        }


        protected List<string> UploadFiles()
        {
            // Initialize the list with 3 items (for id_proof, agreement, police_verification)
            List<string> filePaths = new List<string> { "", "", "" };

            string baseFolder = "/Documents/" + Session["society_name"] + "/rental/" + txt_name.Text + flat_no_id.Value + "/";
            string rootPath = Server.MapPath(baseFolder);
            System.IO.Directory.CreateDirectory(rootPath);

            var uploads = new List<(FileUpload Control, string SubFolder, int Index)>
                {
                    (FileUpload1, "id_proof", 0),
                    (FileUpload2, "agreement", 1),
                    (FileUpload3, "police_verification", 2)
                };

            foreach (var upload in uploads)
            {
                if (upload.Control.HasFile)
                {
                    string targetFolder = System.IO.Path.Combine(rootPath, upload.SubFolder);
                    System.IO.Directory.CreateDirectory(targetFolder);

                    string originalFileName = System.IO.Path.GetFileName(upload.Control.FileName);
                    string extension = System.IO.Path.GetExtension(originalFileName);
                    string baseName = System.IO.Path.GetFileNameWithoutExtension(originalFileName);

                    string fileName = originalFileName;
                    string filePath = System.IO.Path.Combine(targetFolder, fileName);

                    int count = 1;
                    while (System.IO.File.Exists(filePath))
                    {
                        fileName = $"{baseName}({count}){extension}";
                        filePath = System.IO.Path.Combine(targetFolder, fileName);
                        count++;
                    }

                    upload.Control.SaveAs(filePath);

                    string relativePath = $"{baseFolder}{upload.SubFolder}/{fileName}";
                    filePaths[upload.Index] = relativePath;
                }
            }

            return filePaths;
        }

        //    protected List<string> UploadFiles()
        //    {
        //        const int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

        //        // Initialize the list with 3 items
        //        List<string> filePaths = new List<string> { "", "", "" };

        //        string baseFolder = "/Documents/" + Session["society_name"] + "/rental/"
        //                            + txt_name.Text + flat_no_id.Value + "/";
        //        string rootPath = Server.MapPath(baseFolder);
        //        System.IO.Directory.CreateDirectory(rootPath);

        //        var uploads = new List<(FileUpload Control, string SubFolder, int Index)>
        //{
        //    (FileUpload1, "id_proof", 0),
        //    (FileUpload2, "agreement", 1),
        //    (FileUpload3, "police_verification", 2)
        //};

        //        foreach (var upload in uploads)
        //        {
        //            if (upload.Control.HasFile)
        //            {
        //                // 🔴 FILE SIZE CHECK
        //                if (upload.Control.PostedFile.ContentLength > MAX_FILE_SIZE)
        //                {
        //                    throw new Exception(
        //                        $"{upload.SubFolder} file size must not exceed 10 MB."
        //                    );
        //                    // OR: show label message and return
        //                }

        //                string targetFolder = System.IO.Path.Combine(rootPath, upload.SubFolder);
        //                System.IO.Directory.CreateDirectory(targetFolder);

        //                string originalFileName = System.IO.Path.GetFileName(upload.Control.FileName);
        //                string extension = System.IO.Path.GetExtension(originalFileName);
        //                string baseName = System.IO.Path.GetFileNameWithoutExtension(originalFileName);

        //                string fileName = originalFileName;
        //                string filePath = System.IO.Path.Combine(targetFolder, fileName);

        //                int count = 1;
        //                while (System.IO.File.Exists(filePath))
        //                {
        //                    fileName = $"{baseName}({count}){extension}";
        //                    filePath = System.IO.Path.Combine(targetFolder, fileName);
        //                    count++;
        //                }

        //                upload.Control.SaveAs(filePath);

        //                string relativePath = $"{baseFolder}{upload.SubFolder}/{fileName}";
        //                filePaths[upload.Index] = relativePath;
        //            }
        //        }

        //        return filePaths;
        //    }




        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (Buildling_wing_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == Buildling_wing_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }
        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (type_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == type_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void Repeater3_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (flat_no_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == flat_no_id.Value)
                        TextBox3.Text = link.Text;
                }
            }
        }

        protected void Repeater4_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (married_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == married_id.Value)
                        TextBox4.Text = link.Text;
                }
            }
        }

        //protected void Repeater5_ItemDataBound(object sender, RepeaterItemEventArgs e)
        //{
        //    if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
        //    {
        //        if (doc_id_id.Value != "")
        //        {
        //            var link = (LinkButton)e.Item.FindControl("lnkCategory");
        //            if (link.CommandArgument == doc_id_id.Value)
        //                TextBox5.Text = link.Text;
        //        }
        //    }
        //}


        protected void btnViewFile_Command(object sender, CommandEventArgs e)
        {
            string[] paths = e.CommandArgument.ToString().Split('|');
            while (paths.Length < 3)
                Array.Resize(ref paths, 3);

            string[] labels = { "ID Proof", "Agreement", "Police Verification" };
            string previewHtml = "";

            for (int i = 0; i < 3; i++)
            {
                string relativePath = paths[i]?.Trim();
                if (!string.IsNullOrEmpty(relativePath))
                {
                    // ✅ Build correct server + web path
                    string physicalPath = Server.MapPath("~/" + relativePath);
                    string webPath = ResolveUrl("~/" + relativePath);

                    if (File.Exists(physicalPath))
                    {
                        previewHtml += $@"
                    <div style='margin-bottom:20px;'>
                        <h6 style='margin-bottom:8px;'>{labels[i]}</h6>
                        <iframe src='{webPath}' width='100%' height='700px' style='border:1px solid #ccc;'></iframe>
                    </div>";
                    }
                    else
                    {
                        previewHtml += $@"
                    <div style='margin-bottom:20px;'>
                        <h6 style='margin-bottom:8px;'>{labels[i]}</h6>
                        <div style='height:400px; border:1px solid #ccc; display:flex; align-items:center; justify-content:center; color:gray;'>
                            File not found 
                        </div>
                    </div>";
                    }
                }
                else
                {
                    previewHtml += $@"
                <div style='margin-bottom:20px;'>
                    <h6 style='margin-bottom:8px;'>{labels[i]}</h6>
                    <div style='height:400px; border:1px solid #ccc; display:flex; align-items:center; justify-content:center; color:gray;'>
                        No Document Uploaded
                    </div>
                </div>";
                }
            }

            previewContainer.InnerHtml = previewHtml;

            ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#docPreviewModal').modal('show');", true);
        }



    }
}

