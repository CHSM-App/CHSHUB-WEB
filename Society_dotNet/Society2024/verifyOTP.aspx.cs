using BusinessLogic;
using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class verifyPassword : System.Web.UI.Page
    {
        // Session keys for tracking resend attempts
        private const string SESSION_RESEND_COUNT = "ResendOTPCount";
        private const string SESSION_LAST_RESEND_TIME = "LastResendTime";
        private readonly IEmailService _emailService = new SendGridEmailService();

        Society_Member member = new Society_Member();

        BL_Society_Member_Master bL_Society = new BL_Society_Member_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                InitializeResendInfo();
            }
            UpdateResendStatus();
        }

        private void InitializeResendInfo()
        {
            // Initialize resend count if not exists
            if (Session[SESSION_RESEND_COUNT] == null)
            {
                Session[SESSION_RESEND_COUNT] = 0;
            }
            UpdateResendInfo();
        }

        private void UpdateResendStatus()
        {
            int resendCount = GetResendCount();
            DateTime? lastResendTime = GetLastResendTime();

            // Check if user has exceeded 3 attempts in the last 2 hours
            if (resendCount >= 3 && lastResendTime.HasValue &&
                (DateTime.Now - lastResendTime.Value).TotalHours < 2)
            {
                lnkResendOtp.Enabled = false;
                lnkResendOtp.Visible = false;
                lblResendAttempts.Text = "Maximum attempts reached. Try again after 2 hours.";
                lblResendAttempts.CssClass = "resend-info max-attempts";
                lblCooldownTimer.Text = "";
                return;
            }
            else if (resendCount >= 3)
            {
                // Reset attempts after 2 hours
                Session[SESSION_RESEND_COUNT] = 0;
                Session[SESSION_LAST_RESEND_TIME] = null;
            }

            // Normal state - show resend link
            lnkResendOtp.Enabled = true;
            lnkResendOtp.Visible = true;
            lblResendAttempts.CssClass = "resend-info";
            UpdateResendInfo();
        }

        private void UpdateResendInfo()
        {
            int resendCount = GetResendCount();
            int remaining = Math.Max(0, 3 - resendCount);
            lblResendAttempts.Text = $"Remaining attempts: {remaining}/3";
        }

        private int GetResendCount()
        {
            return Session[SESSION_RESEND_COUNT] != null ? (int)Session[SESSION_RESEND_COUNT] : 0;
        }

        private DateTime? GetLastResendTime()
        {
            return Session[SESSION_LAST_RESEND_TIME] as DateTime?;
        }

        protected void btnVerifyOtp_Click(object sender, EventArgs e)
        {
            try
            {
                var sessionOtp = Session["ResetOtp"]?.ToString();
                var otpTime = Session["ResetOtpTime"] as DateTime?;

                if (sessionOtp == null || otpTime == null)
                {
                    lblMessage.Text = "";
                    lblErrorMessage.Text = "Invalid OTP!";
                    return; // OTP not generated or expired
                }

                // Check expiry (e.g., 5 minutes)
                if ((DateTime.Now - otpTime.Value).TotalMinutes > 5)
                {
                    Session.Remove("ResetOtp");
                    Session.Remove("ResetOtpTime");
                    lblMessage.Text = "";
                    lblErrorMessage.Text = "OTP has expired! Please request a new one.";
                    return; // OTP expired
                }

                if (sessionOtp == txtOtp.Text.Trim())
                {
                    // OTP correct → remove it from session (one-time use)

                    Session.Remove("ResetOtp");
                    Session.Remove("ResetOtpTime");

                    // Clear resend attempts on successful verification
                    Session[SESSION_RESEND_COUNT] = null;
                    Session[SESSION_LAST_RESEND_TIME] = null;

                    lblMessage.Text = "OTP Verified Successfully!";
                    lblErrorMessage.Text = "";
                    passwordSection.Attributes["class"] = ""; // remove hidden class

                    // Disable OTP controls after successful verification
                    txtOtp.Enabled = false;
                    btnVerifyOtp.Enabled = false;
                    lnkResendOtp.Enabled = false;
                    lnkResendOtp.Visible = false;
                    lblResendAttempts.Text = "OTP Verified";
                    lblCooldownTimer.Text = "";

                    return;
                }

                lblMessage.Text = "";
                lblErrorMessage.Text = "Invalid OTP! Please try again.";
            }
            catch (Exception ex)
            {
                lblMessage.Text = "";
                lblErrorMessage.Text = "An error occurred. Please try again.";
                // Log the exception if you have logging setup
            }
        }

        protected void btnResetPassword_Click(object sender, EventArgs e)
        {
            try
            {
                string newPassword = txtNewPassword.Text.Trim();
                string confirmPassword = txtConfirmPassword.Text.Trim();

                if (string.IsNullOrEmpty(newPassword))
                {
                    lblErrorMessage.Text = "Please enter a new password.";
                    lblMessage.Text = "";
                    return;
                }

                if (newPassword != confirmPassword)
                {
                    lblErrorMessage.Text = "Passwords do not match.";
                    lblMessage.Text = "";
                    return;
                }

                // Add password strength validation
                if (newPassword.Length < 6)
                {
                    lblErrorMessage.Text = "Password must be at least 6 characters long.";
                    lblMessage.Text = "";
                    return;
                }

                // TODO: Implement your password reset logic here
                // Example: Update password in database
                bool passwordReset = UpdateUserPassword(newPassword);

                if (passwordReset)
                {
                    
                    
                    lblMessage.Text = "Password reset successfully! Redirecting to login...";
                    lblErrorMessage.Text = "";

                    // Clear all session data
                    ClearResetSessions();

                    // Redirect to login page after 3 seconds
                    Response.AddHeader("REFRESH", "3;URL=login1.aspx");
                }
                else
                {
                    lblErrorMessage.Text = "Failed to reset password. Please try again.";
                    lblMessage.Text = "";
                }
            }
            catch (Exception ex)
            {
                lblErrorMessage.Text = "An error occurred. Please try again.";
                lblMessage.Text = "";
                // Log the exception if you have logging setup
            }
        }

        protected void btnResendOtp_Click(object sender, EventArgs e)
        {
            try
            {
                int currentCount = GetResendCount();
                DateTime? lastResendTime = GetLastResendTime();

                // Check if user has exceeded 3 attempts in the last 2 hours
                if (currentCount >= 3 && lastResendTime.HasValue &&
                    (DateTime.Now - lastResendTime.Value).TotalHours < 2)
                {
                    // Use JavaScript to show max attempts message
                    ScriptManager.RegisterStartupScript(this, GetType(), "maxAttempts",
                        "showMaxAttemptsMessage();", true);
                    return;
                }
                else if (currentCount >= 3)
                {
                    // Reset attempts after 2 hours
                    currentCount = 0;
                }

                // Check if within 30 seconds of last resend
                if (lastResendTime.HasValue && (DateTime.Now - lastResendTime.Value).TotalSeconds < 30)
                {
                    int remainingSeconds = 30 - (int)(DateTime.Now - lastResendTime.Value).TotalSeconds;
                    lblErrorMessage.Text = $"Please wait {remainingSeconds} seconds before requesting another OTP.";
                    lblMessage.Text = "";
                    return;
                }

                // Increment resend count and update timestamp
                currentCount++;
                Session[SESSION_RESEND_COUNT] = currentCount;
                Session[SESSION_LAST_RESEND_TIME] = DateTime.Now;

                // Generate new OTP and update session

                generateOTP();
                // TODO: Send OTP via email - implement your email sending logic here
                string newOtp = Session["ResetOtp"].ToString();
        
                    //SendOTPEmail(newOtp);

                if (true)
                {
                    lblMessage.Text = "New OTP has been sent to your email!";
                    lblErrorMessage.Text = "";

                    // Clear the OTP input for new entry
                    txtOtp.Text = "";

                    // Check if max attempts reached
                    if (currentCount >= 3)
                    {
                        // Use JavaScript to show max attempts message
                        ScriptManager.RegisterStartupScript(this, GetType(), "maxAttempts",
                            "showMaxAttemptsMessage();", true);
                    }
                    else
                    {
                        // Start 30-second countdown
                        UpdateResendInfo();
                        ScriptManager.RegisterStartupScript(this, GetType(), "startCountdown",
                            "startCountdown();", true);
                    }
                }
                else
                {
                    // Decrement count if sending failed
                    currentCount--;
                    Session[SESSION_RESEND_COUNT] = Math.Max(0, currentCount);
                    Session[SESSION_LAST_RESEND_TIME] = lastResendTime; // Restore previous time
                    lblErrorMessage.Text = "Failed to send OTP. Please try again.";
                    lblMessage.Text = "";
                }
            }
            catch (Exception ex)
            {
                lblErrorMessage.Text = "An error occurred while sending OTP. Please try again.";
                lblMessage.Text = "";
                // Log the exception if you have logging setup
            }
        }

        // Helper method to send OTP via email
        private async void SendOTPEmail(string otp)
        {
            List<(string Email, string Name)> recipients = new List<(string Email, string Name)>();
            recipients.Add((Session["ResetOtpEmail"].ToString(), "User"));
            try
            {
                string subject ="Reset password for SocietyHub";
                string htmlBody = otp;
                string plainBody = System.Text.RegularExpressions.Regex
                    .Replace(htmlBody, "<.*?>", string.Empty);

                await _emailService.SendEmailAsync(
                    recipients, subject, plainBody, htmlBody);
                

            }
            catch (Exception ex)
            {
                
                // Log ex via your logging framework
            }
        }

        // Helper method to update user password
        private bool UpdateUserPassword(string newPassword)
        {
            try
            {
                member.Email = Session["ResetOtpEmail"].ToString().Trim();
                member.Password = HashPassword(newPassword);
                member.Sql_Operation = "ResetForgotPassword";

                bL_Society.UpdateProfile(member);

                return true; // Placeholder - replace with actual password update logic
            }
            catch
            {
                return false;
            }
        }

        // Helper method to clear all reset-related session data
        private void ClearResetSessions()
        {
            Session.Remove("ResetOtp");
            Session.Remove("ResetOtpTime");
            Session.Remove(SESSION_RESEND_COUNT);
            Session.Remove(SESSION_LAST_RESEND_TIME);
            // Remove any other reset-related session data
        }


        private void generateOTP()
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
    }
}