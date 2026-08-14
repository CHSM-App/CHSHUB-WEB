<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ForgetPassword.aspx.cs" Inherits="Society2024.ForgetPassword" Async="true" %>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>Forgot Password</title>

    <!-- Custom fonts for this template-->
    <link href="vendor/fontawesome-free/css/all.min.css" rel="stylesheet" type="text/css">
    <link
        href="https://fonts.googleapis.com/css?family=Nunito:200,200i,300,300i,400,400i,600,600i,700,700i,800,800i,900,900i"
        rel="stylesheet">

    <!-- Custom styles for this template-->

    <link href="css/sb-admin-2.min.css" rel="stylesheet">

    <style>
        .containerMain {
            background-color: white;
            width: 30vw;
            margin: 10vh auto;
        }

        @media(max-width: 431px) {
            .containerMain {
                width: 90vw;
            }
        }
    </style>
</head>

<body style="background-color: #F0F4F8;">

    <div class="containerMain">

        <div class="col-lg-6" style="min-width: 100%;">
            <div class="p-5">
                <div class="text-center">
                    <h1 class="h4 text-gray-900 mb-2">Forgot Your Password?</h1>
                    <p class="mb-4">
                        We get it, stuff happens. Just enter your email address below
                                            and we'll send you a OTP to reset your password!
                   
                    </p>
                </div>
                <form class="user" runat="server">
                    <div class="form-group">
                        <asp:TextBox runat="server" type="email" class="form-control form-control-user"
                            ID="exampleInputEmail" aria-describedby="emailHelp"
                            placeholder="Enter Email Address..."></asp:TextBox>
                    </div>
                    <asp:Label runat="server" ID="Label10"></asp:Label>

                    <asp:Button runat="server" class="btn btn-primary btn-user btn-block" OnClick="send_otp" Text="Send otp" />
                </form>
                <hr>
                <div class="text-center">
                    <a class="small" href="new_registration.aspx">Create an Account!</a>
                </div>
                <div class="text-center">
                    <a class="small" href="login1.aspx">Already have an account? Login!</a>
                </div>
            </div>
        </div>

    </div>

    <!-- Bootstrap core JavaScript-->
    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Core plugin JavaScript-->
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>

    <!-- Custom scripts for all pages-->
    <script src="js/sb-admin-2.min.js"></script>

</body>

</html>
