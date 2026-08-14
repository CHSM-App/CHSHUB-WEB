using BusinessLogic;
using BusinessLogic.BL;
using DocumentFormat.OpenXml.Office.Word;
using SendGrid.Helpers.Mail;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;
using Utility.DataClass;

namespace Society2024
{
    public partial class ForgetPassword : System.Web.UI.Page
    {
        private readonly IEmailService _emailService = new SendGridEmailService();
        BL_New_Registration BL_new_Registration = new BL_New_Registration();
        Login_Details Details = new Login_Details();
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected async void send_otp(object sender, EventArgs e)
        {

            Details.Emailid = exampleInputEmail.Text;
            Details.Sql_Operation = "check_Email";
            var result = BL_new_Registration.Email_Check(Details);

            if (result.Sql_Result != "Exist")
                Label10.Text = "Email id not Found";
            else
            {

                using (var rng = new RNGCryptoServiceProvider())
                {
                    var length = 6;
                    var bytes = new byte[length];
                    rng.GetBytes(bytes);

                    int otp = BitConverter.ToUInt16(bytes, 0) % (int)Math.Pow(10, length);
                    string OTP = otp.ToString(new string('0', length)); // Pad with zeros

                    Session["ResetOtp"] = otp;
                    Session["ResetOtpTime"] = DateTime.Now;
                    Session["ResetOtpEmail"] = exampleInputEmail.Text;

                }

                List<(string Email, string Name)> recipients = new List<(string Email, string Name)>();
                recipients.Add((exampleInputEmail.Text, "User"));
                try
                {
                    string subject = Session["society_name"] + " Maintenance Due reminder!";
                    string htmlBody = Session["ResetOtp"].ToString();
                    string plainBody = System.Text.RegularExpressions.Regex
                        .Replace(htmlBody, "<.*?>", string.Empty);

                    await _emailService.SendEmailAsync(
                        recipients, subject, plainBody, htmlBody);

                }
                catch (Exception ex)
                {

                    // Log ex via your logging framework
                }

                Response.Redirect("verifyOTP.aspx?email=" + exampleInputEmail.Text);
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

        //public bool VerifyOtp(string enteredOtp)
        //{
        //    var sessionOtp = Session["ResetOtp"].ToString();
        //    var otpTime = HttpContext.Current.Session["ResetOtpTime"] as DateTime?;

        //    if (sessionOtp == null || otpTime == null)
        //        return false; // OTP not generated or expired

        //    Expiry(e.g., 5 minutes)
        //    if ((DateTime.Now - otpTime.Value).TotalMinutes > 5)
        //    {
        //        HttpContext.Current.Session.Remove("ResetOtp");
        //        HttpContext.Current.Session.Remove("ResetOtpTime");
        //        return false; // OTP expired
        //    }

        //    if (sessionOtp == enteredOtp)
        //    {
        //        OTP correct → remove it from session (one - time use)
        //        HttpContext.Current.Session.Remove("ResetOtp");
        //        HttpContext.Current.Session.Remove("ResetOtpTime");
        //        return true;
        //    }

        //    return false; // Wrong OTP
        //}

        //protected void Unnamed_Click(object sender, EventArgs e)
        //{
        //    bool checkOtp = VerifyOtp(TextBox2.Text);

        //    if (checkOtp)
        //        temp.Text = "matched";
        //    else
        //        temp.Text = "not matched";

        //}
    }
}