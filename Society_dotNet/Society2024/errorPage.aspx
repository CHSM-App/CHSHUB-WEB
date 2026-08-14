<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="errorPage.aspx.cs" Inherits="Society2024.errorPage" %>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>404 Not Found</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: #f7f9fc;
      color: #1d1d1f;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      text-align: center;
      padding: 20px;
    }

    h1 {
      color: #002d5f;
      font-size: 2.5rem;
      margin-bottom: 10px;
    }

    p {
      font-size: 1rem;
      color: #555;
      margin-bottom: 30px;
    }

    .btn {
      background-color: #002d5f;
      color: white;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 6px;
      transition: background 0.3s;
    }

    .btn:hover {
      background-color: #004080;
    }

    .error-image {
      max-width: 100%;
      width: 350px;
      margin: 30px 0;
    }

    .error-code {
      font-size: 4rem;
      font-weight: bold;
      color: #b30000;
    }
  </style>
</head>
<body>
  <h1>Oops... We Didn't Find It!</h1>
  <p>We've looked everywhere, but we're sorry,<br>we can't find the page you're looking for.</p>

  <img src="img/errorImg404.png" alt="404 Illustration" class="error-image">


  <a href="/" class="btn">Go to homepage →</a>
</body>
</html>
