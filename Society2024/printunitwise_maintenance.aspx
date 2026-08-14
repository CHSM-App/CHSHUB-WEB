<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printunitwise_maintenance.aspx.cs" Inherits="Society.printunitwise_maintenance" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">


    <div style="padding: 15px">
        <h1 class=" font-weight-bold " style="color: #012970;">Unit wise Maintenance Report</h1>
        <br />

    </div>

    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div class="form-group">

                <asp:HiddenField ID="society_id" runat="server" />
                <div class="d-flex align-items-center bg-white p-2 justify-content-around">
                    <div class="col-sm-3 d-flex align-items-center ">
                        <asp:Label ID="lbl_date" Width="87px" runat="server" Text="From Date :"></asp:Label>

                        <asp:TextBox ID="txt_from" TextMode="Date" runat="server" SelectedDate="<%# DateTime.Today %>"></asp:TextBox>
                    </div>

                    <div class="col-sm-3 d-flex align-items-center">
                        <asp:Label Width="87px" ID="Label1" runat="server" Text="To Date :"></asp:Label>

                        <asp:TextBox ID="txt_to" TextMode="Date" runat="server"></asp:TextBox>
                    </div>
                </div>
            </div>


            <div align="center">
                <asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click"
                    class="btn btn-primary" Font-Bold="True" />
                <br />
                <br />
                <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="60%"></rsweb:ReportViewer>
            </div>

        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>
