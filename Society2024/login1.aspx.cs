using System;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Security.Cryptography; // 🔐 For password verification
using System.Text;
using Utility.DataClass;
using BusinessLogic.MasterBL;

namespace Society2024
{
    public partial class login1 : System.Web.UI.Page
    {
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();

        protected void btn_Login_Click(object sender, EventArgs e)
        {
            string enteredUsername = txt_Username.Text.Trim();
            string enteredPassword = txt_password.Text;

            // 🔐 Step 1: Get user details by username
            var result = BL_Login.GetLoginByUsername(enteredUsername); // You need to implement this method

            if (result != null && VerifyPassword(enteredPassword, result.Password)) // 🔐 verify hash
            {
                Session["UserId"] = result.UserLoginId;
                Session["OwnerId"] = result.Email;
                Session["name"] = result.Name;
                Session["society_id"] = result.Society_Id;
                Session["village_id"] = result.Village_Id;
                Session["society_name"] = result.Society_Name;
                Session["user_type"] = result.Type;
                Session["user_role"] = result.User_Type_Name;

                if (!string.IsNullOrEmpty(result.Village_Id))
                    Response.Redirect("village_dashboard.aspx");
                else
                    Response.Redirect("dashboard.aspx");
            }
            else
            {
                lbl.Text = "Invalid Name or Password";
            }
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            Response.Redirect("new_registration.aspx");
        }

        // 🔐 Password verification using PBKDF2
        private static bool VerifyPassword(string enteredPassword, string storedHash)
        {
            try
            {
                byte[] hashBytes = Convert.FromBase64String(storedHash);

                // Extract salt
                byte[] salt = new byte[16];
                Array.Copy(hashBytes, 0, salt, 0, 16);

                // Generate hash with entered password
                var pbkdf2 = new Rfc2898DeriveBytes(enteredPassword, salt, 10000);
                byte[] hash = pbkdf2.GetBytes(20);

                // Compare hash
                for (int i = 0; i < 20; i++)
                {
                    if (hashBytes[i + 16] != hash[i])
                        return false;
                }

                return true;
            }
            catch
            {
                return false;
            }
        }

    }
}

