//using System.Windows.Controls;
//using Azure;
using BusinessLogic.MasterBL;
using ClosedXML.Excel;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Security.Cryptography;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;
//using System.IdentityModel.Metadata;


 
namespace Society
{
    public partial class society_search : System.Web.UI.Page
    {
        private BL_Society_Master bL_Society = new BL_Society_Master();
        private Search_Society society = new Search_Society();
        private Wing wing = new Wing();
        private BL_Wing_Master bL_Wing = new BL_Wing_Master();
        private Flat flat = new Flat();
        private BL_Flat_Master bL_Flat = new BL_Flat_Master();
        private Owner owner = new Owner();
        private BL_Owner_Master bL_Owner = new BL_Owner_Master();
        private BL_Building_Master bL_Building = new BL_Building_Master();
        private Building building = new Building();
        private BL_Society_Member_Master bL_Society_Member = new BL_Society_Member_Master();
        private Society_Member member = new Society_Member();
        string  upfilename;
        
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)

            {
                fill_drop1();
                Society_Gridbind();

            }

        }
        public void fill_drop1()
        {
            String sql_query = "Select *  from state";
            bL_Society.fill_drop(ddl_state, sql_query, "state", "state_id");
            String sql_query1 = "Select *  from district";
            bL_Society.fill_drop(ddl_district, sql_query1, "district", "district_id");
            String sql_query2 = "Select *  from division";
            bL_Society.fill_drop(ddl_division, sql_query2, "division", "division_id");
        }

        public void Society_Gridbind()
        {
            DataTable dt = new DataTable();
            dt = bL_Society.getSocietyDetails(society_id.Value);

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


        private static string HashPassword(string password)
        {
            byte[] salt;
            new RNGCryptoServiceProvider().GetBytes(salt = new byte[16]);

            var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000);
            byte[] hash = pbkdf2.GetBytes(20);

            byte[] hashBytes = new byte[36];
            Array.Copy(salt, 0, hashBytes, 0, 16);
            Array.Copy(hash, 0, hashBytes, 16, 20);

            return Convert.ToBase64String(hashBytes);
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {

            society.Name = txt_search.Text.Trim();
            society.Sql_Operation = "search";
            society.Society_Id = society_id.Value;
            var result = bL_Society.search_society(society);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        public string runproc_save(string operation)
        {

            if (!string.IsNullOrEmpty(society_master_id.Value))
                society.society_master_id = Convert.ToInt32(society_master_id.Value);

            society.Sql_Operation = operation;
            society.Society_Id = society_id.Value;
            society.Name = txt_name.Text;
            //society.Establish_Date = Convert.ToDateTime(txt_es_date.Text.ToString());
            society.Registration_No = txt_registration.Text;
            society.Off_Address1 = txt_off_address1.Text;
            society.Off_Address2 = txt_off_address2.Text;
            society.Contact_No1 = txt_contact_no1.Text;
            society.Email = txt_email.Text;
            society.City = txt_city.Text;
            society.State_Id = Convert.ToInt32(ddl_state.SelectedValue.ToString());
            society.Pincode = txt_pincode.Text;
            society.Home_No = Convert.ToInt32(txt_street.Text);
            society.Division =ddl_division.SelectedValue;
            society.District_Id = Convert.ToInt32(ddl_district.SelectedValue);
            society.Tan_No = txt_tan_no.Text;
            society.Gstin_No = txt_gstin_no.Text;
            society.Pan_No = txt_pan_no.Text;
            var result = bL_Society.updateSocietyDetails(society);

            return result.Sql_Result;
        }

        public void runproc(string operation)
        {
            if (society_master_id.Value != "")
                society.society_master_id = Convert.ToInt32(society_master_id.Value);
            society.Sql_Operation = operation;

            var result = bL_Society.updateSocietyDetails(society);
            

            (society_master_id.Value) = result.society_master_id.ToString();
            society_id.Value = result.Society_Id;
            txt_name.Text = result.Name;
            //txt_es_date.Text = result.Establish_Date.ToString("yyyy-MM-dd");
            txt_registration.Text = result.Registration_No;
            txt_off_address1.Text = result.Off_Address1;
            txt_off_address2.Text = result.Off_Address2;
            txt_contact_no1.Text = result.Contact_No1;
            txt_email.Text = result.Email;
            txt_city.Text = result.City;
            ddl_state.SelectedValue = result.State_Id.ToString();
            txt_pincode.Text = result.Pincode;
            txt_street.Text = result.Home_No.ToString();
            ddl_division.Text = result.Division.ToString();
            ddl_district.SelectedValue = result.District_Id.ToString();
            txt_tan_no.Text = result.Tan_No;
            txt_gstin_no.Text = result.Gstin_No;
            txt_pan_no.Text = result.Pan_No;

        }


        protected void btn_new_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_member_search.aspx");
        }
        protected void btn_save_Click(object sender, EventArgs e)
        {


            if (Label22.Text == "")
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "failedEntry();", true);

            }

        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {

                if (society_master_id.Value != "")
                    society.society_master_id = Convert.ToInt32(society_master_id.Value);
                society.Sql_Operation = "Delete";

               
                bL_Society.delete(society);
            
            Response.Redirect("society_search.aspx");
        }



        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            society_master_id.Value = id;
            runproc("Select");
            
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
           
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label society_master_id = (System.Web.UI.WebControls.Label)row.FindControl("society_master_id");
                society.Sql_Operation = "Delete";

                society.society_master_id = Convert.ToInt32(society_master_id.Text);
                bL_Society.delete(society);
            
                Society_Gridbind();
        }



        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_search.aspx");
        }

        protected void txt_registration_TextChanged(object sender, EventArgs e)
        {
            if (txt_name.Text.Trim() != "")
            {
                if (society_master_id.Value != "")
                    society.society_master_id = Convert.ToInt32(society_master_id.Value);
                society.Sql_Operation = "check_no";
                society.Name = txt_name.Text;
                society.Registration_No = txt_registration.Text;


                var result = bL_Society.SelectTextChanged(society);
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                Label22.Text = result.Sql_Result;
            }
        }
        //public void document()
        //{

        //    if (FileUpload1.HasFiles)
        //    {

        //        foreach (HttpPostedFile file_name in FileUpload1.PostedFiles)
        //        {
        //            file_name.SaveAs(System.IO.Path.Combine(Server.MapPath(file_name.FileName)));
        //            upfilename = file_name.FileName;
        //        }

        //        path = System.IO.Path.Combine(Server.MapPath(file_name.FileName));
        //    }
        //}

        //protected void btn_photo_upload_Click(object sender, EventArgs e)
        //{
        //    uploadedfiles.Text = "";

        //    document();

        //            ImportDataFromExcel(path + "\\"+ upfilename);



        //}
        //public void ImportDataFromExcel(string excelFilePath)
        //{

        //    string[] upfile;
        //    upfile = upfilename.Split('.');

        //    ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
        //    SqlDataReader sdr = null;
        //    string status1 = "";
        //    int count = 0;
        //    Microsoft.Office.Interop.Excel.Application xlApp = new Microsoft.Office.Interop.Excel.Application();
        //    Microsoft.Office.Interop.Excel.Workbook xlWorkBook;
        //    try
        //    {
        //        xlWorkBook = xlApp.Workbooks.Open(excelFilePath, 0, true, 5, "", "", false, Microsoft.Office.Interop.Excel.XlPlatform.xlWindows, "\t", true, false, 0, true, 0);

        //        Microsoft.Office.Interop.Excel.Worksheet worksheet1 = (Microsoft.Office.Interop.Excel.Worksheet)xlApp.Worksheets.Item[1];

        //        int sheet1LastRowCount = worksheet1.UsedRange.Rows.Count;
        //        int columnCount = worksheet1.UsedRange.Columns.Count;
        //        string[] firstRow = new string[columnCount];
        //        for (int i = 2; i <= sheet1LastRowCount; i++)
        //        {
        //            if (worksheet1.Range["A" + i, "A" + i].Value2.ToString().Trim() != null)
        //            {
        //                if (!string.IsNullOrEmpty(society_master_id.Value))
        //                    society.society_master_id = Convert.ToInt32(society_master_id.Value);

        //                society.Sql_Operation = "Update";
        //                society.Name = worksheet1.Range["A" + i, "A" + i].Value2.ToString().Trim();

        //                society.Registration_No = worksheet1.Range["C" + i, "C" + i].Value2.ToString().Trim();
        //                society.Off_Address1 = worksheet1.Range["D" + i, "D" + i].Value2.ToString().Trim();
        //                society.Off_Address2 = worksheet1.Range["E" + i, "E" + i].Value2.ToString().Trim();
        //                society.Contact_No1 = worksheet1.Range["F" + i, "F" + i].Value2.ToString().Trim();
        //                society.Email = worksheet1.Range["G" + i, "G" + i].Value2.ToString().Trim();
        //                //society.Society_Id = worksheet1.Range["H" + i, "H" + i].Value2.ToString().Trim();
        //                society.City = worksheet1.Range["I" + i, "I" + i].Value2.ToString().Trim();

        //                society.Pincode = worksheet1.Range["K" + i, "K" + i].Value2.ToString().Trim();
        //                society.Tan_No = worksheet1.Range["L" + i, "L" + i].Value2.ToString().Trim();
        //                society.Gstin_No = worksheet1.Range["M" + i, "M" + i].Value2.ToString().Trim();
        //                society.Pan_No = worksheet1.Range["N" + i, "N" + i].Value2.ToString().Trim();

        //                society.Establish_Date = Convert.ToDateTime(worksheet1.Range["B" + i, "B" + i].Value.ToString().Trim());
        //                society.State_Id = Convert.ToInt32(worksheet1.Range["J" + i, "J" + i].Value2.ToString().Trim());

        //                bL_Society.updateSocietyDetails(society);
        //            }
        //        }
        //        if (uploadedfiles.Text != "Selected Values Does not match to Excel data")
        //        {
        //            if (count > 0)
        //            {
        //                uploadedfiles.Text = "   " + count + " Rows  Updated Successfully";
        //                runproc("Update");
        //            }
        //            else
        //                uploadedfiles.Text = "Already have data!!";
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        uploadedfiles.Text = ex.ToString();
        //        Console.WriteLine(ex.Message);
        //        xlApp.Quit();
        //    }
        //    finally
        //    {
        //        xlApp.Quit();
        //    }
        //    //File.Delete(excelFilePath);

        //}

        protected void ddl_state_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_state.Text != "select")
            {

                string sql1 = "select * from dbo.district Where state_id=" + ddl_state.SelectedValue;
                bL_Society.fill_drop(ddl_district, sql1, "district", "district_id");

            }
        }

        protected void ddl_district_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (ddl_district.Text != "select")
            {

                string sql2 = "select * from dbo.division Where district_id=" + ddl_district.SelectedValue;
                bL_Society.fill_drop(ddl_division, sql2, "division", "division_id");

            }
        }




        //using (var workbook = new XLWorkbook(path))
        //{
        //    var worksheet = workbook.Worksheet(1); // Use appropriate worksheet index or name
        //    int count = 0;

        //    for (int i = 2; !string.IsNullOrWhiteSpace(worksheet.Cell("A" + i).GetString()); i++)
        //    {
        //        if (ddl_import.SelectedValue == "society_member")
        //        {
        //            member.Society_Id = society_id.Value;
        //            member.Name = worksheet.Cell("A" + i).GetString().Trim();
        //            member.Contact_No = worksheet.Cell("E" + i).GetString().Trim();
        //            member.Sql_Operation = "check_name";

        //            var society_member_exist = bL_Society_Member.SocietyMemberTextChange(member);

        //            if (string.IsNullOrEmpty(society_member_exist.Sql_Result))
        //            {
        //                member.Sql_Operation = "Update";
        //                member.Society_Id = society_id.Value;
        //                member.Name = worksheet.Cell("A" + i).GetString().Trim();
        //                member.Designation = getRole(worksheet.Cell("B" + i).GetString().Trim());
        //                member.Address1 = worksheet.Cell("C" + i).GetString().Trim();
        //                member.Address2 = worksheet.Cell("D" + i).GetString().Trim();
        //                member.Contact_No = worksheet.Cell("E" + i).GetString().Trim();
        //                member.Email = worksheet.Cell("F" + i).GetString().Trim();
        //                member.UserName = worksheet.Cell("G" + i).GetString().Trim();
        //                member.Password = worksheet.Cell("H" + i).GetString().Trim();
        //                // member.Status = worksheet.Cell("I" + i).GetString().Trim(); // If needed

        //                bL_Society_Member.updateSocietyMemberDetails(member);
        //                count++;
        //            }
        //        }
        //    }
        //}


        protected void btn_photo_upload_Click(object sender, EventArgs e)
        {

            uploadedfiles.Text = "";

            if (file_name.HasFiles)
            {

                foreach (HttpPostedFile file_name in file_name.PostedFiles)
                {
                    file_name.SaveAs(System.IO.Path.Combine(Server.MapPath(file_name.FileName)));
                    upfilename = file_name.FileName;
                }

                ImportDataFromExcel(System.IO.Path.Combine(Server.MapPath(file_name.FileName)));


                ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "$('#import_model').modal('show');", true);


            }
        }


        public void ImportDataFromExcel(string excelFilePath)
        {
            int count = 0;

            try
            {
                using (var workbook = new XLWorkbook(excelFilePath))
                {
                    var worksheet = workbook.Worksheet(1);
                    int sheet1LastRowCount = worksheet.LastRowUsed().RowNumber();

                    for (int i = 2; i <= sheet1LastRowCount; i++)
                    {
                        var cellA = worksheet.Cell("A" + i).GetString().Trim();
                        if (!string.IsNullOrEmpty(cellA))
                        {
                            /* ================================
                             *        SOCIETY MEMBER 
                             * ================================ */
                            if (ddl_import.SelectedValue == "society_member")
                            {
                                member.Society_Id = society_id.Value;
                                member.Name = worksheet.Cell("A" + i).GetString().Trim();
                                member.Contact_No = worksheet.Cell("C" + i).GetString().Trim();
                                member.Sql_Operation = "chk_name";

                                var society_member_exist = bL_Society_Member.SocietyMemberTextChange(member);
                                if (string.IsNullOrEmpty(society_member_exist.Sql_Result))
                                {
                                    member.Sql_Operation = "Update";
                                    member.Designation = getRole(worksheet.Cell("B" + i).GetString().Trim());
                                    member.Email = worksheet.Cell("D" + i).GetString().Trim();

                                    member.Password = HashPassword(worksheet.Cell("C" + i).GetString().Trim());
                                    member.UserName = worksheet.Cell("D" + i).GetString().Trim();
                                    bL_Society_Member.updateSocietyMemberDetails(member);
                                    count++;
                                }
                            }

                            /* ================================
                             *        BUILDING 
                             * ================================ */
                            else if (ddl_import.SelectedValue == "building")
                            {
                                building.Registration_No = worksheet.Cell("F" + i).GetString().Trim();
                                building.Sql_Operation = "check_no";
                                var building_exist = bL_Building.BuildingTextchange(building);

                                if (string.IsNullOrEmpty(building_exist.Sql_Result))
                                {
                                    building.Sql_Operation = "Update";
                                    building.Society_Id = society_id.Value;
                                    building.Name = worksheet.Cell("A" + i).GetString().Trim();
                                    building.No_Of_Floore = int.TryParse(worksheet.Cell("D" + i).GetString().Trim(), out int floors) ? floors : 0;
                                    building.Print_Name = worksheet.Cell("C" + i).GetString().Trim();
                                    building.Email = worksheet.Cell("B" + i).GetString().Trim();
                                    bL_Building.updateBuildingDetails(building);
                                    count++;
                                }
                            }

                            /* ================================
                             *        OWNER IMPORT
                             * ================================ */
                            else if (ddl_import.SelectedValue == "owner")
                            {
                                // --- Get building ---
                                wing.Sql_Operation = "getbuilding";
                                wing.Society_Id = society_id.Value;
                                wing.B_Name = worksheet.Cell("A" + i).GetString().Trim();
                                var build = bL_Wing.Get_Building(wing);
                                wing.build_id = build.build_id;

                                if (build.build_id != 0)
                                {
                                    /* ----------- Wing ----------- */
                                    wing.Sql_Operation = "check_name";
                                    wing.W_Name = worksheet.Cell("B" + i).GetString().Trim();
                                    var existWing = bL_Wing.WingTextChanged(wing);
                                    if (string.IsNullOrEmpty(existWing.Sql_Result))
                                    {
                                        wing.Sql_Operation = "Update";
                                        bL_Wing.updateWingDetails(wing);
                                    }

                                    /* ----------- Flat ----------- */
                                    flat.Sql_Operation = "getwing";
                                    flat.Society_Id = society_id.Value;
                                    flat.B_Name = worksheet.Cell("A" + i).GetString().Trim();
                                    flat.W_Name = worksheet.Cell("B" + i).GetString().Trim();
                                    var ft = bL_Flat.GetWing(flat);
                                    flat.wing_id = ft.wing_id;

                                    flat.Sql_Operation = "check_no";
                                    flat.Flat_No = worksheet.Cell("C" + i).GetString().Trim();
                                    var flat_exist = bL_Flat.FlatTextChange(flat);

                                    if (string.IsNullOrEmpty(flat_exist.Sql_Result))
                                    {
                                        flat.Sql_Operation = "Update";
                                        flat.Usage_Id = getUsage(worksheet.Cell("D" + i).GetString().Trim());
                                        flat.bed_id = getBed(worksheet.Cell("E" + i).GetString().Trim());
                                        flat.flat_type_id = getType(worksheet.Cell("I" + i).GetString().Trim()).ToString();
                                        flat.Sq_Ft = worksheet.Cell("F" + i).GetString().Trim();
                                        flat.Terrace_Sq_Ft = worksheet.Cell("G" + i).GetString().Trim();
                                        flat.Intercom_No = worksheet.Cell("H" + i).GetString().Trim();
                                        bL_Flat.updateFlatDetails(flat);
                                    }

                                    /* ----------- Owner ----------- */
                                    owner.Sql_Operation = "getFlat";
                                    owner.Society_Id = society_id.Value;
                                    owner.Flat_No = worksheet.Cell("C" + i).GetString().Trim();
                                    owner.Flat_type_Id = getType(worksheet.Cell("I" + i).GetString().Trim());
                                    owner.wing_id = ft.wing_id;
                                    var flat_id = bL_Owner.getFlat(owner);
                                    owner.flat_id = flat_id.flat_id;

                                    owner.Sql_Operation = "check_no";
                                    var owner_exist = bL_Owner.FlatTextChanged(owner);

                                    if (string.IsNullOrEmpty(owner_exist.Sql_Result))
                                    {
                                        owner.owner_id = 0;
                                        owner.Sql_Operation = "Update";

                                        /* ===== NULL SAFE DATE CONVERSIONS ===== */

                                        string possDate = worksheet.Cell("J" + i).GetString().Trim();
                                        if (!string.IsNullOrEmpty(possDate))
                                            owner.Poss_Date = Convert.ToDateTime(possDate);

                                        string dob = worksheet.Cell("P" + i).GetString().Trim();
                                        if (!string.IsNullOrEmpty(dob))
                                            owner.Dob = Convert.ToDateTime(dob);

                                        owner.Name = worksheet.Cell("K" + i).GetString().Trim();
                                        owner.Pre_Mob = worksheet.Cell("L" + i).GetString().Trim();
                                        owner.Email = worksheet.Cell("N" + i).GetString().Trim();
                                        owner.Alter_Mob = worksheet.Cell("M" + i).GetString().Trim();
                                        owner.married_id = getMarried(worksheet.Cell("O" + i).GetString().Trim());
                                        owner.Occup = worksheet.Cell("Q" + i).GetString().Trim();
                                        owner.Monthly_Income = worksheet.Cell("R" + i).GetString().Trim();
                                        owner.Off_Addr1 = worksheet.Cell("S" + i).GetString().Trim();
                                        owner.Off_Addr2 = worksheet.Cell("T" + i).GetString().Trim();
                                        owner.Off_Tel = worksheet.Cell("U" + i).GetString().Trim();
                                        owner.Type = worksheet.Cell("AB" + i).GetString().Trim();

                                        /* ------- RENTAL DATES ---------- */
                                        if (owner.Type == "Rent")
                                        {
                                            string X = worksheet.Cell("X" + i).GetString().Trim();
                                            if (!string.IsNullOrEmpty(X))
                                                owner.Aggrement_Date = Convert.ToDateTime(X);

                                            string Y = worksheet.Cell("Y" + i).GetString().Trim();
                                            if (!string.IsNullOrEmpty(Y))
                                                owner.Aggrement_Period_From = Convert.ToDateTime(Y);

                                            string Z = worksheet.Cell("Z" + i).GetString().Trim();
                                            if (!string.IsNullOrEmpty(Z))
                                                owner.Aggrement_Period_To = Convert.ToDateTime(Z);

                                            string AA = worksheet.Cell("AA" + i).GetString().Trim();
                                            if (!string.IsNullOrEmpty(AA))
                                                owner.Police_Verification_Date = Convert.ToDateTime(AA);

                                            bL_Owner.UpdateRentalDetails(owner);
                                        }
                                        else
                                        {
                                            bL_Owner.updateOwnerDetails(owner);
                                        }

                                        count++;
                                    }
                                }
                            }
                        }
                    }
                }

                uploadedfiles.Text = count > 0
                    ? $"{count} Rows Inserted Successfully"
                    : "Rows already exist";
            }
            catch (Exception ex)
            {
                uploadedfiles.Text = ex.ToString();
            }
            finally
            {
                if (File.Exists(excelFilePath))
                    File.Delete(excelFilePath);
            }
        }


        private int getUsage(string usage)
        {
            if (usage == "Residential")
                return 1;
            else if (usage == "Industrial")
                return 2;
            else if (usage == "Commercial")
                return 3;
            else return 0;
        }

        private int getBed(string type)
        {
            if (type == "1 RK")
                return 1;
            if (type == "1 BED")
                return 2;
            if (type == "2 BED")
                return 3;
            if (type == "3 BED")
                return 4;
            if (type == "4 BED")
                return 5;
            if (type == "5 BED")
                return 6;
            else return 0;
        }

        private int getType(string type)
        {
            if (type == "Flat")
                return 1;
            if (type == "Office")
                return 2;
            if (type == "Shop")
                return 3;
            if (type == "Plot")
                return 4;
            else return 0;
        }

        private int getRole(string role)
        {
            if (role == "President")
                return 1;
            if (role == "Secretary")
                return 2;
            if (role == "Chairman")
                return 3;
            if (role == "Member")
                return 4;
            if (role == "Vice President")
                return 5;
            if (role == "Treasurer")
                return 6;
            else return 0;
        }

        protected void btn_import_Click(object sender, EventArgs e)
        {
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "$('#import_model').modal('show');", true);
        }

        protected void btn_close1_Click(object sender, EventArgs e)
        {

        }



        private int getMarried(string married)
        {
            if (married == "Married")
                return 1;
            else if (married == "Not Married")
                return 2;
            else if (married == "Single")
                return 3;
            else if (married == "Widow")
                return 4;
            else return 0;

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Society_Gridbind();
        }
    }

}



