using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class homeTax : System.Web.UI.Page
    {


        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            if (!IsPostBack)
            {
                BindPendingBills();
                BindPaidHouses();
            }
        }

        private void BindPendingBills()
        {
            List<HouseTaxViewModel> pendingList = GetPendingBills();
            gvPendingBills.DataSource = pendingList;
            gvPendingBills.DataBind();
        }

        private void BindPaidHouses()
        {
            List<PaidHouseViewModel> paidList = GetPaidHouses();
            gvPaidHouses.DataSource = paidList;
            gvPaidHouses.DataBind();
        }

        private List<HouseTaxViewModel> GetPendingBills()
        {
            List<HouseTaxViewModel> houses = new List<HouseTaxViewModel>();

            // Create dummy pending bills
            var house1 = new homeModal
            {
                House_Id = 1,
                Owner_Name = "Amit Sharma",
                House_No = "A-101",
                House_Sqft = 1450,
                Sqft_Charges = 2.5m,
                No_Of_Taps = 3,
                Tap_Charges = 50m,
                Solid_Waste_Fee = 120m
            };

            var house2 = new homeModal
            {
                House_Id = 1,
                Owner_Name = "Rohit Verma",
                House_No = "A-102",
                House_Sqft = 1600,
                Sqft_Charges = 2.7m,
                No_Of_Taps = 4,
                Tap_Charges = 55m,
                Solid_Waste_Fee = 110m
            };

            var house3 = new homeModal
            {
                House_Id = 1,
                Owner_Name = "Priya Singh",
                House_No = "A-103",
                House_Sqft = 1350,
                Sqft_Charges = 2.4m,
                No_Of_Taps = 3,
                Tap_Charges = 50m,
                Solid_Waste_Fee = 100m
            };
            houses.Add(new HouseTaxViewModel
            {
                House_Id = house1.House_Id,
                Owner_Name = house1.Owner_Name,
                House_No = house1.House_No,
                TotalTax = CalculateTotalTax(house1),
                DueDate = DateTime.Now.AddDays(15)
            });


            houses.Add(new HouseTaxViewModel
            {
                House_Id = house2.House_Id,
                Owner_Name = house2.Owner_Name,
                House_No = house2.House_No,
                TotalTax = CalculateTotalTax(house2),
                DueDate = DateTime.Now.AddDays(10)
            });


            houses.Add(new HouseTaxViewModel
            {
                House_Id = house3.House_Id,
                Owner_Name = house3.Owner_Name,
                House_No = house3.House_No,
                TotalTax = CalculateTotalTax(house3),
                DueDate = DateTime.Now.AddDays(20)
            });

            return houses;
        }

        private List<PaidHouseViewModel> GetPaidHouses()
        {
            List<PaidHouseViewModel> paidHouses = new List<PaidHouseViewModel>();
            var house4= new homeModal
            {
                House_Id = 2,
                Owner_Name = "Suresh Kumar",
                House_No = "B-201",
                House_Sqft = 1700,
                Sqft_Charges = 3.0m,
                No_Of_Taps = 4,
                Tap_Charges = 60m,
                Solid_Waste_Fee = 130m
            };

            var house5 = new homeModal
            {
                House_Id = 2,
                Owner_Name = "Neha Gupta",
                House_No = "B-202",
                House_Sqft = 1550,
                Sqft_Charges = 2.8m,
                No_Of_Taps = 3,
                Tap_Charges = 55m,
                Solid_Waste_Fee = 120m
            };

            var house6 = new homeModal
            {
                House_Id = 2,
                Owner_Name = "Vikram Malhotra",
                House_No = "B-203",
                House_Sqft = 1800,
                Sqft_Charges = 3.2m,
                No_Of_Taps = 5,
                Tap_Charges = 60m,
                Solid_Waste_Fee = 140m
            };


            paidHouses.Add(new PaidHouseViewModel
            {
                House_Id = house4.House_Id,
                Owner_Name = house4.Owner_Name,
                House_No = house4.House_No,
                TotalTax = CalculateTotalTax(house4),
                PaymentDate = DateTime.Now.AddDays(-5),
                PaymentMethod = "Online",
                TransactionRef = "TXN123456789"
            });


            paidHouses.Add(new PaidHouseViewModel
            {
                House_Id = house5.House_Id,
                Owner_Name = house5.Owner_Name,
                House_No = house5.House_No,
                TotalTax = CalculateTotalTax(house5),
                PaymentDate = DateTime.Now.AddDays(-10),
                PaymentMethod = "Cash",
                TransactionRef = "CASH001"
            });


            paidHouses.Add(new PaidHouseViewModel
            {
                House_Id = house6.House_Id,
                Owner_Name = house6.Owner_Name,
                House_No = house6.House_No,
                TotalTax = CalculateTotalTax(house6),
                PaymentDate = DateTime.Now.AddDays(-15),
                PaymentMethod = "Card",
                TransactionRef = "CARD987654321"
            });

            return paidHouses;
        }

        private decimal CalculateTotalTax(homeModal house)
        {
            decimal sqftTotal = house.House_Sqft * house.Sqft_Charges;
            decimal tapTotal = house.No_Of_Taps * house.Tap_Charges;
            return sqftTotal + tapTotal + house.Solid_Waste_Fee;
        }

        protected void gvPendingBills_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "Pay")
            {
                int houseId = Convert.ToInt32(e.CommandArgument);
                // Additional logic if needed
            }
        }

        protected void gvPaidHouses_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "ViewReceipt")
            {
                int houseId = Convert.ToInt32(e.CommandArgument);
                // Additional logic if needed for receipt viewing
            }
        }

        protected void btnSubmitPayment_Click(object sender, EventArgs e)
        {
            try
            {
                // Get values from modal
                int houseId = Convert.ToInt32(hdnHouseId.Value);
                string ownerName = txtOwnerName.Text;
                string houseNo = txtHouseNo.Text;
                string totalTax = txtTotalTax.Text;
                string paymentMethod = ddlPaymentMethod.SelectedValue;
                string transactionRef = txtTransactionRef.Text;
                string remarks = txtRemarks.Text;

                // Validation
                if (string.IsNullOrEmpty(paymentMethod))
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "alert",
                        "alert('Please select a payment method.'); $('#paymentModal').modal('show');", true);
                    return;
                }

                // Process payment
                bool paymentSuccess = ProcessPayment(houseId, ownerName, houseNo, totalTax,
                    paymentMethod, transactionRef, remarks);

                if (paymentSuccess)
                {
                    // Clear modal fields
                    ClearModalFields();

                    // Refresh both grids
                    BindPendingBills();
                    BindPaidHouses();

                    // Show success message and hide modal
                    ScriptManager.RegisterStartupScript(this, GetType(), "success",
                        "alert('Payment submitted successfully!'); $('#paymentModal').modal('hide');", true);
                }
                else
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "error",
                        "alert('Payment processing failed. Please try again.'); $('#paymentModal').modal('show');", true);
                }
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "error",
                    $"alert('Error: {ex.Message}'); $('#paymentModal').modal('show');", true);
            }
        }

        private bool ProcessPayment(int houseId, string ownerName, string houseNo,
            string totalTax, string paymentMethod, string transactionRef, string remarks)
        {
            // TODO: Implement your backend logic here
            // This should include:
            // 1. Insert payment record into database
            // 2. Update house tax status from pending to paid
            // 3. Store payment details (payment method, transaction ref, date, etc.)
            // 4. Generate receipt number
            // 5. Send confirmation email

            // Example backend call structure:
            /*
            homeModal payment = new homeModal
            {
                House_Id = houseId,
                Owner_Name = ownerName,
                House_No = houseNo,
                Sql_Operation = "INSERT_PAYMENT"
            };
            
            PaymentDetails paymentDetails = new PaymentDetails
            {
                HouseId = houseId,
                PaymentMethod = paymentMethod,
                TransactionRef = transactionRef,
                PaymentDate = DateTime.Now,
                Amount = decimal.Parse(totalTax.Replace("$", "")),
                Remarks = remarks
            };
            
            // Call your data layer
            // YourDataLayer.ProcessPayment(payment, paymentDetails);
            */

            // For now, return true to simulate success
            System.Threading.Thread.Sleep(500); // Simulate processing
            return true;
        }

        private void ClearModalFields()
        {
            hdnHouseId.Value = string.Empty;
            txtOwnerName.Text = string.Empty;
            txtHouseNo.Text = string.Empty;
            txtTotalTax.Text = string.Empty;
            ddlPaymentMethod.SelectedIndex = 0;
            txtTransactionRef.Text = string.Empty;
            txtRemarks.Text = string.Empty;
        }
    }

    // ViewModel class for Pending Bills GridView
    public class HouseTaxViewModel
    {
        public int House_Id { get; set; }
        public string Owner_Name { get; set; }
        public string House_No { get; set; }
        public decimal TotalTax { get; set; }
        public DateTime DueDate { get; set; }
    }

    // ViewModel class for Paid Houses GridView
    public class PaidHouseViewModel
    {
        public int House_Id { get; set; }
        public string Owner_Name { get; set; }
        public string House_No { get; set; }
        public decimal TotalTax { get; set; }
        public DateTime PaymentDate { get; set; }
        public string PaymentMethod { get; set; }
        public string TransactionRef { get; set; }
    }
}