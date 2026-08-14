<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printshop.aspx.cs" Inherits="Society.printshop" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <div style="padding: 15px">

        <h1 class=" tex0 font-weight-bold " style="color: #012970;">Shop Maintenance Reports
        </h1>
        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <asp:HiddenField ID="society_id" runat="server" />
                <asp:HiddenField ID="payment_id" runat="server" />
                <div class="form-group">
                    <div class="d-flex align-items-center bg-white align-items-center p-2  ">

                        <div class="col-sm-2">
                            <asp:Label ID="Label8" runat="server" Text="Payment Method"></asp:Label>

                        </div>
                        <div class="col-sm-4">
                            <div class="dropdown-cntainer">
                                <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                    placeholder="Select" autocomplete="off" required="required" style="width:50%;" />
                                <div id="RepeaterContainer1" class="suggestion-list" style="width:47%;">
                                    <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand">
                                        <ItemTemplate>
                                            <asp:LinkButton
                                                ID="lnkCategory"
                                                runat="server"
                                                CssClass="suggestion-item link-button category-link"
                                                Text='<%# Eval("pay_method") %>'
                                                CommandArgument='<%# Eval("led_id") %>'
                                                CommandName="SelectCategory"
                                                OnClientClick="setTextBox1(this.innerText);" />
                                        </ItemTemplate>
                                        <FooterTemplate>
                                            <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                Text="No items found." />
                                        </FooterTemplate>
                                    </asp:Repeater>
                                </div>
                            </div>


                        </div>
                        <div class="col-sm-2">
                            <asp:Label ID="Label2" runat="server" Text=" Maintenance Date:"></asp:Label>

                        </div>
                        <div class="col-sm-4">
                            <asp:TextBox ID="txt_date" Width="200px" Height="32px" TextMode="Date" runat="server"></asp:TextBox>

                        </div>

                    </div>
                </div>

                <div align="center">
                    <asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click"
                        class="btn btn-primary" Font-Bold="True" />
                     <asp:Button ID="Button2" runat="server" Text="Download Report" OnClick="Button1_Click"
                        class="btn btn-danger" Font-Bold="True" />
                    <br />
                    <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="62%"></rsweb:ReportViewer>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>




    <script>
 
function initDropdownEvents() {

    const categoryBox = document.getElementById("<%= TextBox1.ClientID %>");

    const categorySuggestions = document.getElementById("RepeaterContainer1");
 
    categoryBox.addEventListener("focus", function () {

        categorySuggestions.style.display = "block";

        itemSuggestions.style.display = "none";

    });
 
    categoryBox.addEventListener("input", function () {

        const input = categoryBox.value.toLowerCase();

        filterSuggestions("category-link", input);

    });
 
 
}
 
 
function filterSuggestions(className, value) {

    const items = document.querySelectorAll("." + className);

    let matchFound = false;
 
    items.forEach(item => {

        if (item.innerText.toLowerCase().includes(value.toLowerCase())) {

            item.style.display = "block";

            matchFound = true;

        } else {

            item.style.display = "none";

        }

    });
 
    let noMatchMessage = document.getElementById("no-match-message");
  
    if (!matchFound) {

        if (!noMatchMessage) {

            noMatchMessage = document.createElement("div");

            noMatchMessage.id = "no-match-message";
 
            noMatchMessage.innerText = "No matching suggestions.";

            items[0]?.parentNode?.appendChild(noMatchMessage);

        }

        noMatchMessage.style.display = "block";

    } else {

        if (noMatchMessage) {

            noMatchMessage.style.display = "none";

        }

    }

}
 
 
        function setTextBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            document.getElementById("RepeaterContainer1").style.display = "none";
 
        }
 
 
Sys.Application.add_load(initDropdownEvents);
 
  
    </script>
 
</asp:Content>
