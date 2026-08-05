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
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using System.Web.Services.Description;
using System.EnterpriseServices;
using System.IO;
using System.Windows.Forms;
using DocumentFormat.OpenXml.Bibliography;
using BusinessLogic.BL;
using Microsoft.Ajax.Utilities;
using System.Web.UI.HtmlControls;
using static System.Windows.Forms.LinkLabel;
using ClosedXML.Excel;

namespace Society
{
    public partial class owner_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        BL_Owner_Master bL_Owner = new BL_Owner_Master();
        Owner owner = new Owner();


        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            } else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                txt_poss_date.Attributes["min"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_dob.Attributes["max"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_f_dob.Attributes["max"] = DateTime.Now.ToString("yyyy-MM-dd");
                Owner_Gridbind();

                AllRepeater();


            }
        }


        protected void AllRepeater()
        {
            DataTable dt = new DataTable();
            dt = bL_Owner.Fill_list(society_id.Value, "Fill_wing", Buildling_wing_id.Value, type_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "types", Buildling_wing_id.Value, type_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "flat_owners", Buildling_wing_id.Value, type_id.Value);
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "married", Buildling_wing_id.Value, type_id.Value);
            Repeater4.DataSource = dt;
            Repeater4.DataBind();
            //dt = bL_Owner.Fill_list(society_id.Value, "Fill_doc", Buildling_wing_id.Value, type_id.Value);
            //Repeater5.DataSource = dt;
            //Repeater5.DataBind();
        }

        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                Buildling_wing_id.Value = e.CommandArgument.ToString();
                lbl_Building.Text = e.CommandArgument.ToString();

               
                   var dt = bL_Owner.Fill_list(society_id.Value, "flat_owners", Buildling_wing_id.Value, type_id.Value);
                    Repeater3.DataSource = dt;
                    Repeater3.DataBind();
            }
        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                type_id.Value = e.CommandArgument.ToString();
               var dt = bL_Owner.Fill_list(society_id.Value, "flat_owners", Buildling_wing_id.Value, type_id.Value);
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
        

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            owner_id.Value = id;
            runproc("Select");
            //runproc_Family("Select_Family");
            Family_Details_Gridbind();

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        public void Owner_Gridbind()
        {
            DataTable dt = new DataTable();
            owner.Sql_Operation = "Grid_Show";
            owner.Type = "Owner";
            owner.Society_Id = society_id.Value;
            dt = bL_Owner.getOwnerDetails(owner);
            OwnerGrid.DataSource = dt;
            ViewState["dirState"] = dt;
            OwnerGrid.DataBind();
            GridView2.DataSource = dt;
            GridView2.DataBind();

        }

        public void Family_Details_Gridbind()
        {
            DataTable dt = new DataTable();
            owner.Sql_Operation = "Grid_Show_Family";
            owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Type = "Owner";
            dt = bL_Owner.getFamilyDetails(owner);
            FamilyGrid.DataSource = dt;
            ViewState["dirState"] = dt;
            FamilyGrid.DataBind();

        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

            owner.Sql_Operation = "search";
            owner.Name = txt_search.Text;
            owner.Society_Id = society_id.Value;
            var result = bL_Owner.search_rental(owner);
            OwnerGrid.DataSource = result;
            ViewState["dirState"] = result;
            OwnerGrid.DataBind();
            GridView2.DataSource = result;
            GridView2.DataBind();

        }

        public string runproc_save(string operation)
        {
            DateTime dob;
            string type = "Owner";
            if (owner_id.Value != "")
                owner.owner_id = Convert.ToInt32(owner_id.Value);
            owner.Sql_Operation = operation;
            owner.Society_Id = society_id.Value;
            owner.wing_id = Convert.ToInt32(Buildling_wing_id.Value);
            owner.Poss_Date = Convert.ToDateTime(txt_poss_date.Text.ToString());
            owner.Name = txt_name.Text;
            owner.Pre_Mob = txt_pre_mob.Text;
            owner.Dob = DateTime.TryParse(txt_dob.Text, out dob) ? dob: (DateTime?)null;
            owner.married_id = Convert.ToInt32(married_id.Value.ToString());
            owner.Occup = txt_occup.Text;
            owner.Monthly_Income = txt_monthly_income.Text;
            owner.Off_Addr1 = txt_off_addr1.Text;
            owner.Off_Tel = txt_off_tel.Text;
            owner.Email = txt_email.Text;
            owner.Alter_Mob = txt_add_mob.Text;
            owner.flat_id = Convert.ToInt32(flat_no_id.Value.ToString());
            owner.Flat_type_Id = Convert.ToInt32(type_id.Value.ToString());
            owner.Id_Proof = UploadId();
            owner.Type = type;
            //owner.Doc_Id = Convert.ToInt32(doc_id_id.Value); // Set docid  

            var result = bL_Owner.updateOwnerDetails(owner);

            owner_id.Value = result.owner_id.ToString();

            return result.Sql_Result;
        }



        public void runproc_F_save(string operation)
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


        public void runproc(string operation)
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
                txt_poss_date.Text = result.Poss_Date.ToString("yyyy-MM-dd");
                txt_name.Text = result.Name;
                txt_pre_mob.Text = result.Pre_Mob;
                txt_dob.Text = result.Dob?.ToString("yyyy-MM-dd");
                married_id.Value = result.married_id.ToString();
                txt_occup.Text = result.Occup;
                txt_monthly_income.Text = result.Monthly_Income;
                txt_off_addr1.Text = result.Off_Addr1;
                txt_off_tel.Text = result.Off_Tel;
                txt_email.Text = result.Email;
                txt_add_mob.Text = result.Alter_Mob;
                flat_no_id.Value = result.flat_id.ToString();
                type_id.Value = result.Flat_type_Id.ToString();
              //  doc_id_id.Value = result.Doc_Id.ToString();


            }
            DataTable dt = new DataTable();
            dt = bL_Owner.Fill_list(society_id.Value, "Fill_wing", Buildling_wing_id.Value, type_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "types", Buildling_wing_id.Value, type_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "flat_owners", "0","0");
            Repeater3.DataSource = dt;
            Repeater3.DataBind();
            dt = bL_Owner.Fill_list(society_id.Value, "married", Buildling_wing_id.Value, type_id.Value);
            Repeater4.DataSource = dt;
            Repeater4.DataBind();
            //String str1 = "Select wing_id,(name + w_name) as name from global_society_view where society_id='" + society_id.Value + "'";
            //repeater.fill_list(Repeater1, str1);
        }


        protected void btn_save_Click1(object sender, EventArgs e)
        {
            string str = runproc_save("Update");
            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
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

        //    //ScriptManager.RegisterStartupScript(modalpanel, this.GetType(), "Pop", "$('#edit_model').modal('show');", true);
        //    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);


        //    //ScriptManager.RegisterStartupScript(modalpanel, this.GetType(), "Pop", "$('#edit_model').modal('show');", true);
        //}

        //protected void btnotice_id_upload_Click(object sender, EventArgs e)
        //{
        //    //ScriptManager.RegisterStartupScript(modalpanel, this.GetType(), "Pop", "$('#edit_model').modal('hide');", true);
        //    string createfolder = Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + (doc_id_id.Value.ToString()) + "/";
        //    System.IO.Directory.CreateDirectory(createfolder);

        //    if (FileUpload2.HasFiles)
        //    {

        //        foreach (HttpPostedFile file_name in FileUpload2.PostedFiles)
        //        {
        //            file_name.SaveAs(System.IO.Path.Combine(Server.MapPath("~/Documents") + "/" + txt_name.Text + "/" + (doc_id_id.Value.ToString()) + "/" + file_name.FileName));
        //            listofuploadedfiles1.Text += file_name.FileName + "<br/>";

        //        }

        //        uploadidproof.Text = System.IO.Path.Combine(Server.MapPath("~/Documents") + "\\" + txt_name.Text + "\\" + (doc_id_id.Value.ToString()) + "\\" + FileUpload2.FileName);

        //    }
        //    //ScriptManager.RegisterStartupScript(modalpanel, this.GetType(), "Pop", "$('#edit_model').modal('show');", true);

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
            runproc_F_save("D_Update");
            Family_Details_Gridbind();
            cleardata();
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void FamilyGrid_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)FamilyGrid.Rows[e.RowIndex];

            System.Web.UI.WebControls.Label id = (System.Web.UI.WebControls.Label)row.FindControl("o_ex_id");
            owner.Sql_Operation = "D_delete";

            owner.O_Ex_Id = Convert.ToInt32(id.Text);
            bL_Owner.FamilyDelete(owner);

            Family_Details_Gridbind();
            ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("owner_search.aspx");
        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {

            runproc("Delete");

            Response.Redirect("owner_search.aspx");

        }
        protected void OwnerGrid_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)OwnerGrid.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label owner_id = (System.Web.UI.WebControls.Label)row.FindControl("owner_id");
            owner.Sql_Operation = "Delete";

            owner.owner_id = Convert.ToInt32(owner_id.Text);
            bL_Owner.OwnerDelete(owner);

            Owner_Gridbind();
        }

        protected void OwnerGrid_Sorting(object sender, GridViewSortEventArgs e)
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
                OwnerGrid.DataSource = dtrslt;
                OwnerGrid.DataBind();


            }
        }

        protected void OwnerGrid_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }




        //protected void ddl_type_SelectedIndexChanged(object sender, EventArgs e)
        // {

        //        if (flat_no_id.Value.ToString() != "select")
        //        {
        //            string sql1 = "Select distinct flat_type,flat_id from dbo.flat_types where flat_status=0  and active_status=0 and society_id='" + society_id.Value + "' and  wing_id='" + ddl_build_wing.SelectedValue + "' and flat_type_id='" + ddl_type.SelectedValue +"'";
        //            bL_Owner.fill_drop(ddl_flat, sql1, "flat_type", "flat_id");

        //        }
        //    ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
        //}

        protected void FamilyGrid_Sorting(object sender, GridViewSortEventArgs e)
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
                FamilyGrid.DataSource = dtrslt;
                FamilyGrid.DataBind();


            }
        }

        protected void FamilyGrid_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void OwnerGrid_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            OwnerGrid.PageIndex = e.NewPageIndex;
            Owner_Gridbind();
        }


        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {

            // Match item index
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (Buildling_wing_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == Buildling_wing_id.Value)
                    {
                        TextBox1.Text = link.Text;

                    }
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


        protected void btnExportToExcel_Click(object sender, EventArgs e)
        {
            DataTable dt = ViewState["dirState"] as DataTable;
            if (dt == null || dt.Rows.Count == 0)
                return;

            using (XLWorkbook workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("Owner Report");

                // Add title
                worksheet.Cell("A1").Value = "Owner Details Report";
                worksheet.Cell("A1").Style.Font.Bold = true;
                worksheet.Cell("A1").Style.Font.FontSize = 16;
                worksheet.Range("A1:E1").Merge().Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Insert table starting from A3
                var table = worksheet.Cell(3, 1).InsertTable(dt, "OwnerData", true);

                var headerRow = table.HeadersRow();
                headerRow.Style.Font.Bold = true;
                headerRow.Style.Fill.BackgroundColor = XLColor.LightSteelBlue;
                headerRow.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Optional: Auto-size columns
                worksheet.Columns().AdjustToContents();

                // Prepare the response
                using (MemoryStream stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    stream.Position = 0;

                    Response.Clear();
                    Response.Buffer = true;
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    Response.AddHeader("content-disposition", "attachment; filename=Owner_Report.xlsx");
                    Response.BinaryWrite(stream.ToArray());
                    Response.End();  // Finalize
                }
            }
        }


        protected string UploadId()
        {
            string relativeFolder = "/Documents/owner/" + Session["society_name"] + "/";
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
    }


    
}




