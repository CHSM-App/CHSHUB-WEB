<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="errorPage500.aspx.cs" Inherits="Society2024.errorPage500" %>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Internal Server Error</title>
  <style>
    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      padding: 0;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #ffffff;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }

    .container {
      display: flex;
      flex-direction: column;
      align-items: center;
      max-width: 1000px;
      width: 100%;
    }

    @media(min-width: 768px) {
      .container {
        flex-direction: row;
        justify-content: space-between;
      }
    }

    .text-section {
      max-width: 500px;
    }

    .text-section h1 {
      font-size: 32px;
      color: #1f2937; /* dark gray */
      margin-bottom: 16px;
    }

    .text-section p {
      color: #4b5563; /* gray */
      font-size: 16px;
      margin-bottom: 12px;
    }

    .btn {
      display: inline-block;
      padding: 10px 20px;
      background-color: #2563eb; /* blue */
      color: #fff;
      text-decoration: none;
      border-radius: 5px;
      margin-top: 10px;
      transition: background-color 0.3s;
    }

    .btn:hover {
      background-color: #1e40af;
    }

    .image-section img {
      width: 100%;
      max-width: 600px;
    }
  </style>
</head>
<body>

  <div class="container">
    
    <!-- Left Text Section -->
    <div class="text-section">
      <h1 class=" font-weight-bold " style="color: #012970;">Internal Server Error</h1>
      <p>Sorry, we encountered some technical issues during your last operation.</p>
      <p>Please try again later, or contact support if the problem persists.</p>
      <a href="/" class="btn">Go to homepage →</a>
    </div>

    <!-- Right Image Section -->
    <div class="image-section">
      <img src="img/serverError.png" alt="Server Error Illustration">
    </div>

  </div>

</body>
</html>
