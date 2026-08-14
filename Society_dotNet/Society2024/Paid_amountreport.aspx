<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Paid_amountreport.aspx.cs" Inherits="Society2024.Paid_amount" MasterPageFile="~/Site.Master" %>
<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
     <asp:HiddenField ID="village_id" runat="server" />
     <asp:HiddenField ID="receipt_id" runat="server" />


    <div style="padding:15px">
<div align="center" style="font-size: 30px;">Paid Amount Report</div>

<div align="center">
<asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click" Visible="false"
    class="btn btn-primary" Font-Bold="True" />
<br />
<br />

 <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="887px"></rsweb:ReportViewer>
</div>
</div>
   
</asp:Content>
