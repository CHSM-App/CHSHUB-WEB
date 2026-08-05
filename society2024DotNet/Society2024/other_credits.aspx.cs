using BusinessLogic.BL;
using DBCode.DataClass;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using static System.Windows.Forms.VisualStyles.VisualStyleElement;

namespace Society
{
    public partial class other_credits : System.Web.UI.Page
    {
        BL_Other_credits credits = new BL_Other_credits();
        maintenance Maintenance = new maintenance();

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

        private void BindGrid()
        {
            try
            {

                Maintenance.Society_Id = Session["society_id"].ToString();
                Maintenance.Sql_Operation = "SELECT";

                DataTable dt = credits.Get_other_credits(Maintenance);
                gvOtherCredits.DataSource = dt;
                gvOtherCredits.DataBind();


                //using (SqlConnection conn = new SqlConnection(connectionString))
                //{
                //    using (SqlCommand cmd = new SqlCommand("sp_ManageOtherCredits", conn))
                //    {
                //        cmd.CommandType = CommandType.StoredProcedure;
                //        cmd.Parameters.AddWithValue("@Operation", "SELECT");
                //        cmd.Parameters.AddWithValue("@SearchText", searchText);

                //        using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                //        {
                //            DataTable dt = new DataTable();
                //            sda.Fill(dt);
                //            gvOtherCredits.DataSource = dt;
                //            gvOtherCredits.DataBind();
                //        }
                //    }
                //}
            }
            catch (Exception ex)
            {
                ShowMessage("Error loading data: " + ex.Message);
            }
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            //BindGrid(txt_search.Text.Trim());
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (Page.IsValid)
            {
                try
                {
                    int creditid= Convert.ToInt32(hdnCreditId.Value);
                    Maintenance.Description = txtDescription.Text.Trim();
                    Maintenance.Amount = txtPayment.Text.Trim();
                    Maintenance.Date = Convert.ToDateTime(txtDate.Text);
                    Maintenance.Sql_Operation = creditid == 0 ? "INSERT" : "UPDATE";
                    Maintenance.Society_Id = Session["society_id"].ToString();

                    if(creditid != 0)
                    {
                        Maintenance.Bill_No = creditid;
                    }   

                    var result = credits.add_other_credits(Maintenance);

                    if (result.Sql_Result == "Success")
                    {
                        // Clear form and close modal
                        ClearForm();
                        BindGrid();
                        //ShowMessage(message);

                        // Close modal using JavaScript
                        ScriptManager.RegisterStartupScript(this, GetType(), "closeModal", "SuccessEntry();", true);
                    }

                    
                }
                catch (Exception ex)
                {
                    ShowMessage("Error saving data: " + ex.Message);
            
                }
            }
            else
            {
                // Keep modal open if validation failed
               
            }
        }

        protected void gvOtherCredits_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "EditRecord")
            {
                int creditId = Convert.ToInt32(e.CommandArgument);
                LoadCreditForEdit(creditId);
            }
            else if (e.CommandName == "DeleteRecord")
            {
                int creditId = Convert.ToInt32(e.CommandArgument);
                DeleteCredit(creditId);
            }
        }

        private void LoadCreditForEdit(int creditId)
        {
            try
            {
                Maintenance.Society_Id = Session["society_id"].ToString();
                Maintenance.Sql_Operation = "GETBYID";
                Maintenance.Bill_No = creditId;

                var result = credits.Get_other_credits_by_Id(Maintenance);
                if (result != null)
                {
                    hdnCreditId.Value = creditId.ToString();
                    txtDescription.Text = result.Description;
                    txtPayment.Text = result.Amount;
                    txtDate.Text = result.Date.ToString("yyyy-MM-dd");
                }

                // Show modal with edit data
                //ltlShowModal.Text = @"$document.getElementById('creditModalLabel').innerText = 'Edit Credit';";

                ScriptManager.RegisterStartupScript(this, GetType(), "openModal", "openEditModal();", true);
            }
            catch (Exception ex)
            {
                ShowMessage("Error loading credit: " + ex.Message);
            }
        }

        private void DeleteCredit(int creditId)
        {
            try
            {
                //using (SqlConnection conn = new SqlConnection(connectionString))
                //{
                //    using (SqlCommand cmd = new SqlCommand("sp_ManageOtherCredits", conn))
                //    {
                //        cmd.CommandType = CommandType.StoredProcedure;
                //        cmd.Parameters.AddWithValue("@Operation", "DELETE");
                //        cmd.Parameters.AddWithValue("@Id", creditId);

                //        conn.Open();

                //        using (SqlDataReader reader = cmd.ExecuteReader())
                //        {
                //            if (reader.Read())
                //            {
                //                string status = reader["Status"].ToString();
                //                string message = reader["Message"].ToString();

                //                ShowMessage(message);

                //                if (status == "Success")
                //                {
                //                    BindGrid();
                //                }
                //            }
                //        }
                //    }
                //}
            }
            catch (Exception ex)
            {
                ShowMessage("Error deleting credit: " + ex.Message);
            }
        }

        private void GetTotalCredits()
        {
            try
            {
                //using (SqlConnection conn = new SqlConnection(connectionString))
                //{
                //    using (SqlCommand cmd = new SqlCommand("sp_ManageOtherCredits", conn))
                //    {
                //        cmd.CommandType = CommandType.StoredProcedure;
                //        cmd.Parameters.AddWithValue("@Operation", "TOTAL");

                //        conn.Open();

                //        using (SqlDataReader reader = cmd.ExecuteReader())
                //        {
                //            if (reader.Read())
                //            {
                //                int totalRecords = Convert.ToInt32(reader["TotalRecords"]);
                //                decimal totalAmount = reader["TotalAmount"] != DBNull.Value ?
                //                    Convert.ToDecimal(reader["TotalAmount"]) : 0;
                //                decimal avgAmount = reader["AverageAmount"] != DBNull.Value ?
                //                    Convert.ToDecimal(reader["AverageAmount"]) : 0;

                //                // You can use these values to display summary
                //                // For example: lblTotalAmount.Text = totalAmount.ToString("N2");
                //            }
                //        }
                //    }
                //}
            }
            catch (Exception ex)
            {
                ShowMessage("Error getting totals: " + ex.Message);
            }
        }

        private void GetCreditsByDateRange(DateTime startDate, DateTime endDate)
        {
            try
            {
                //using (SqlConnection conn = new SqlConnection(connectionString))
                //{
                //    using (SqlCommand cmd = new SqlCommand("sp_ManageOtherCredits", conn))
                //    {
                //        cmd.CommandType = CommandType.StoredProcedure;
                //        cmd.Parameters.AddWithValue("@Operation", "DATERANGE");
                //        cmd.Parameters.AddWithValue("@StartDate", startDate);
                //        cmd.Parameters.AddWithValue("@EndDate", endDate);

                //        using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                //        {
                //            DataTable dt = new DataTable();
                //            sda.Fill(dt);
                //            gvOtherCredits.DataSource = dt;
                //            gvOtherCredits.DataBind();
                //        }
                //    }
                //}
            }
            catch (Exception ex)
            {
                ShowMessage("Error loading data by date range: " + ex.Message);
            }
        }

        private void ClearForm()
        {
            hdnCreditId.Value = "0";
            txtDescription.Text = "";
            txtPayment.Text = "";
        }

        private void ShowMessage(string message)
        {
            ScriptManager.RegisterStartupScript(this, GetType(), "alert",
                $"alert('{message.Replace("'", "\\'")}');", true);
        }
    }
}