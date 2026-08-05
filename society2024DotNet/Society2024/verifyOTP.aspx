<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="verifyOTP.aspx.cs" Async="true" Inherits="Society2024.verifyPassword" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Reset Password</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f7fa;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 400px;
            margin: 80px auto;
            background: #fff;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0px 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }
        h2 {
            margin-bottom: 10px;
        }
        p {
            color: #777;
            font-size: 14px;
        }
        .input-field {
            width: 90%;
            padding: 12px;
            margin: 10px 0;
            border: 1px solid #ccc;
            border-radius: 25px;
            outline: none;
        }
        .btn {
            width: 95%;
            padding: 12px;
            background: #4169e1;
            color: #fff;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px 0;
        }
        .btn:hover {
            background: #365acb;
        }
        .hidden {
            display: none;
        }
        .message {
            color: green;
            font-size: 14px;
            margin-top: 5px;
        }
        .error-message {
            color: red;
            font-size: 14px;
            margin-top: 5px;
        }
        .resend-info {
            color: #666;
            font-size: 12px;
            margin: 5px 0;
            text-align: center;
        }
        .countdown {
            color: #ff6b35;
            font-weight: bold;
        }
        .max-attempts {
            color: #dc3545;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
        <div class="container">
            <h2>Verify OTP</h2>
            <p>Please enter the OTP sent to your email</p>
            
            <!-- OTP Input -->
            <asp:TextBox ID="txtOtp" CssClass="input-field" runat="server" placeholder="Enter OTP"></asp:TextBox>
            
            <!-- Verify Button -->
            <asp:Button ID="btnVerifyOtp" runat="server" CssClass="btn" Text="Verify OTP" OnClick="btnVerifyOtp_Click" />
            
            <!-- Resend OTP Section -->
            <div style="margin: 15px 0;">
                <asp:LinkButton ID="lnkResendOtp" runat="server" OnClick="btnResendOtp_Click" Text="Resend OTP" 
                    style="color: #4169e1; text-decoration: underline; font-size: 14px;" />
                <div class="resend-info">
                    <asp:Label ID="lblResendAttempts" runat="server"></asp:Label>
                </div>
                <div class="resend-info">
                    <asp:Label ID="lblCooldownTimer" runat="server" CssClass="countdown"></asp:Label>
                </div>
            </div>
            
            <!-- Message -->
            <asp:Label ID="lblMessage" runat="server" CssClass="message"></asp:Label>
            <asp:Label ID="lblErrorMessage" runat="server" CssClass="error-message"></asp:Label>
            
            <!-- Password fields (hidden until OTP verified) -->
            <div id="passwordSection" runat="server" class="hidden">
                <asp:TextBox ID="txtNewPassword" CssClass="input-field" runat="server" TextMode="Password" placeholder="New Password"></asp:TextBox>
                <asp:TextBox ID="txtConfirmPassword" CssClass="input-field" runat="server" TextMode="Password" placeholder="Re-enter Password"></asp:TextBox>
                <asp:Button ID="btnResetPassword" runat="server" CssClass="btn" Text="Reset Password" OnClick="btnResetPassword_Click" />
            </div>
        </div>
    </form>
    
    <script type="text/javascript">
        var countdownSeconds = 0;
        var countdownInterval;

        // Function to start 30-second countdown
        function startCountdown() {
            countdownSeconds = 30;
            var lnkResend = document.getElementById('<%= lnkResendOtp.ClientID %>');
            var countdownElement = document.getElementById('<%= lblCooldownTimer.ClientID %>');
            
            // Hide resend link during countdown
            lnkResend.style.display = 'none';
            
            countdownInterval = setInterval(function() {
                countdownElement.innerHTML = 'Resend OTP in ' + countdownSeconds + ' seconds';
                countdownSeconds--;
                
                if (countdownSeconds < 0) {
                    clearInterval(countdownInterval);
                    countdownElement.innerHTML = '';
                    // Show resend link after countdown
                    lnkResend.style.display = 'inline';
                }
            }, 1000);
        }
        
        // Function to hide resend link and show max attempts message
        function showMaxAttemptsMessage() {
            var lnkResend = document.getElementById('<%= lnkResendOtp.ClientID %>');
            var attemptsElement = document.getElementById('<%= lblResendAttempts.ClientID %>');

            lnkResend.style.display = 'none';
            attemptsElement.innerHTML = 'Maximum attempts reached. Try again after 2 hours.';
            attemptsElement.className = 'resend-info max-attempts';
        }
    </script>
</body>
</html>