<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printledger_details.aspx.cs" Inherits="Society.printledger_details" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <div style="padding: 15px">
        <asp:HiddenField ID="society_id" runat="server" />
        <h1 class=" tex0 font-weight-bold " style="color: #012970;">Ledger Details Reports
        </h1>
        <br />
        <div align="center">
            <asp:Button ID="Button1" CssClass="btn btn-primary" runat="server" Text="Load Report" OnClick="Button1_Click"
               
                Font-Bold="True" />
             <asp:Button ID="Button2" CssClass="btn btn-danger" runat="server" Text="Download Report" OnClick="Button1_Click" Font-Bold="True" />
            <br />
            <br />
            <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="49%"></rsweb:ReportViewer>
        </div>
    </div>

</asp:Content>
