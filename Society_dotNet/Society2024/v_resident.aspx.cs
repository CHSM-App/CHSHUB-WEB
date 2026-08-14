using BusinessLogic.BL;
using ClosedXML.Excel;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class v_resident : System.Web.UI.Page
    {
        bl_v_resident bL_House = new bl_v_resident();
        homeModal house = new homeModal();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                BindGrid();
            }
        }



        // Bind data to GridView
        private void BindGrid()
        {
            try
            {
                DataTable dt = bL_House.gridBind(Session["village_id"].ToString(), "Grid_Show");
                ViewState["BillsData"] = dt;
                GridViewBills.DataSource = dt;
                GridViewBills.DataBind();
            }
            catch (Exception ex)
            {
                lblMessage.ForeColor = System.Drawing.Color.Red;
                lblMessage.Text = "Error loading data: " + ex.Message;
            }
        }

        // Handle Edit button click
        protected void GridViewBills_RowEditing(object sender, GridViewEditEventArgs e)
        {
            GridViewBills.EditIndex = e.NewEditIndex;
            BindGrid();
        }

        // Handle Cancel button click
        protected void GridViewBills_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
        {
            GridViewBills.EditIndex = -1;
            BindGrid();
        }

        // Handle Update button click
        protected void GridViewBills_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {
            try
            {
                // Get the row being updated
                GridViewRow row = GridViewBills.Rows[e.RowIndex];

                // Get HouseId from DataKeys
                house.House_Id = Convert.ToInt32(GridViewBills.DataKeys[e.RowIndex].Value);

                // Get values from textboxes
                //house.House_No = ((TextBox)row.FindControl("txtHouseNo")).Text;
                //house.Owner_Name = ((TextBox)row.FindControl("txtOwnerName")).Text;
               // house.address = ((TextBox)row.FindControl("txtadd")).Text;
               // house.phone = ((TextBox)row.FindControl("txtmob")).Text;
                house.House_Sqft = Convert.ToInt32(((TextBox)row.FindControl("txtHouseSqft")).Text);
                house.Sqft_Charges = Convert.ToDecimal(((TextBox)row.FindControl("txtSqftCharges")).Text);
                house.No_Of_Taps = Convert.ToInt32(((TextBox)row.FindControl("txtNoOfTaps")).Text);
                house.Tap_Charges = Convert.ToDecimal(((TextBox)row.FindControl("txtTapCharges")).Text);
                house.Solid_Waste_Fee = Convert.ToDecimal(((TextBox)row.FindControl("txtSolidWasteFee")).Text);
                house.village_owner_id = Convert.ToInt32(((Label)row.FindControl("lbl_o_id")).Text);
             



                // Update in-memory data (Session)
                UpdateHouseBillingInMemory(house);

                // Exit edit mode and rebind
                GridViewBills.EditIndex = -1;
                BindGrid();

                lblMessage.ForeColor = System.Drawing.Color.Green;
                lblMessage.Text = "Record updated successfully!";
            }
            catch (Exception ex)
            {
                lblMessage.ForeColor = System.Drawing.Color.Red;
                lblMessage.Text = "Error updating record: " + ex.Message;
            }
        }

        // Update data in memory (Session) - Replace this with DB update later
        private void UpdateHouseBillingInMemory(homeModal house)
        {
            house.Sql_Operation = "Update";
            house.Village_id = Session["village_id"].ToString();
            house.UserId = Convert.ToInt32(Session["UserId"]);
            int houseID = bL_House.InsertHouse(house);

            house.UserId = Convert.ToInt32(Session["UserId"].ToString());
            //house.House_Id = houseID;

            bL_House.InsertOwner(house);

        }


        protected void btn_house_upload_Click(object sender, EventArgs e)
        {
            if (!houseXL.HasFiles)
                return;

            string uploadFolder = Server.MapPath("~/ExcelUploads/");

            // Create folder if missing
            if (!Directory.Exists(uploadFolder))
            {
                Directory.CreateDirectory(uploadFolder);
            }

            string savedPath = "";

            foreach (HttpPostedFile postedFile in houseXL.PostedFiles)
            {
                string fileName = Path.GetFileName(postedFile.FileName);
                savedPath = Path.Combine(uploadFolder, fileName);

                postedFile.SaveAs(savedPath);
            }

            ImportHouseDataFromExcel(savedPath);

            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "SuccessEntryy()", true);
        }

        //To insert owner and home data in the db
        public void ImportHouseDataFromExcel(string excelFilePath)
        {
            int count = 0;

            try
            {
                using (var workbook = new XLWorkbook(excelFilePath))
                {
                    var ws = workbook.Worksheet(1);
                    int lastRow = ws.LastRowUsed().RowNumber();

                    for (int i = 2; i <= lastRow; i++) // Row 1 = Header
                    {
                        var cellA = ws.Cell("A" + i).GetString().Trim();
                        if (string.IsNullOrEmpty(cellA))
                            continue;

                        // Create model object
                        //homeModal house = new homeModal
                        //{
                        house.Sql_Operation = "Update";
                        //house.House_Id = Convert.ToInt32(ws.Cell("A" + i).GetValue<int>());
                        house.House_No = ws.Cell("B" + i).GetString().Trim();
                        house.House_type = ws.Cell("H" + i).GetValue<int>();
                        house.House_Sqft = ws.Cell("C" + i).GetValue<int>();
                        house.Village_id = Session["village_id"].ToString();
                        house.Sqft_Charges = ws.Cell("D" + i).GetValue<decimal>();
                        house.No_Of_Taps = ws.Cell("E" + i).GetValue<int>();
                        house.Tap_Charges = ws.Cell("F" + i).GetValue<decimal>();
                        house.Solid_Waste_Fee = ws.Cell("G" + i).GetValue<decimal>();

                        house.address = ws.Cell("i" + i).GetString().Trim();
                        house.phone = ws.Cell("j" + i).GetString().Trim();


                        house.Owner_Name = ws.Cell("A" + i).GetString().Trim();
                        int houseID = bL_House.InsertHouse(house);

                        house.House_Id = houseID;

                        bL_House.InsertOwner(house);
                        house.House_Id = 0;

                    }
                }

                BindGrid();
                uploadedfiles.Text = $"House Records Imported Successfully.";
            }
            catch (Exception ex)
            {
                uploadedfiles.Text = "Error: " + ex.Message;
            }
        }

        protected void btnSubmitHouse_Click(object sender, EventArgs e)
        {
            try
            {
            

                house.Owner_Name = txtOwnerName.Text.Trim();
                house.address = txtAddress.Text.Trim();
                house.phone = txtPhone.Text.Trim();
                house.House_No = txtHouseNo.Text.Trim();

                house.House_Sqft = Convert.ToInt32(txtSqft.Text.Trim());
                house.Sqft_Charges = Convert.ToDecimal(txtSqftCharges.Text.Trim());
                house.No_Of_Taps = Convert.ToInt32(txtTaps.Text.Trim());
                house.Tap_Charges = Convert.ToDecimal(txtTapCharges.Text.Trim());
                house.Solid_Waste_Fee = Convert.ToDecimal(txtWaste.Text.Trim());
                house.UserId = Convert.ToInt32(Session["UserId"]);

                // Save to DB (Write your actual DB insert method here)
                int houseID = bL_House.InsertHouse(house);

                house.House_Id = houseID;

                bL_House.InsertOwner(house);
                house.House_Id = 0;

                BindGrid();
            }
            catch (Exception ex)
            {
                // Handle exception
                Response.Write(ex.Message);
            }
        }

        protected void GridViewBills_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["BillsData"];
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
                GridViewBills.DataSource = dtrslt;
                GridViewBills.DataBind();
            }
        }
    }



    // Data model class
    public class HouseBillingData
    {
        public int HouseId { get; set; }
        public string OwnerName { get; set; }
        public string HouseNo { get; set; }
        public decimal HouseSqft { get; set; }
        public decimal SqftCharges { get; set; }
        public int NoOfTaps { get; set; }
        public decimal TapCharges { get; set; }
        public decimal SolidWasteFee { get; set; }
    }
}