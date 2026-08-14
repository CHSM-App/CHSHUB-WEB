<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="maintanance_report.aspx.cs" Inherits="Society.maintanance_report" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <asp:HiddenField ID="society_id" runat="server" />
    <asp:HiddenField ID="receipt_id" runat="server" />
    <table width="100%">
        <tr>
            <th width="100%" class="">
                <h1 class=" tex0 font-weight-bold " style="color: #012970;">Society Maintenance Bill Reports 
                </h1>
            </th>
        </tr>
    </table>
    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <div align="center">

                <asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click"
                    class="btn btn-primary" Font-Bold="True" />
                <br />
                <br />
                <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="62%"></rsweb:ReportViewer>
            </div>
        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
