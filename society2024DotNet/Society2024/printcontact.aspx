<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printcontact.aspx.cs" Inherits="Society.printcontact" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms, Version=15.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
    Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <asp:HiddenField ID="society_id" runat="server" />
    <asp:HiddenField ID="person_id" runat="server" />

    <div style="padding: 15px">
        <h1 class=" tex0 font-weight-bold " style="color: #012970;">Helper Contacts
        </h1>
        <div class="form-group">
            <div class="row ">

                <div class="col-sm-2">
                    <asp:Label ID="Label7" runat="server" Text="Person's Type"></asp:Label>
                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                    <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                </div>
                <div class="col-sm-4">
                    <div class="dropdown-container">
                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                            placeholder="Select" autocomplete="off" required="required" style="width:50%;" />
                        <div id="RepeaterContainer1" class="suggestion-list" style="width:50%;">
                            <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand">
                                <ItemTemplate>
                                    <asp:LinkButton
                                        ID="lnkCategory"
                                        runat="server"
                                        CssClass="suggestion-item link-button category-link"
                                        Text='<%# Eval("p_type_name") %>'
                                        CommandArgument='<%# Eval("p_type_id") %>'
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
            </div>
        </div>

        <div align="center">
            <asp:Button ID="Button1" runat="server" Text="Load Report" OnClick="Button1_Click"
                class="btn btn-primary" Font-Bold="True"  />

            <asp:Button ID="Button2" runat="server" Text="Download report" OnClick="Button1_Click"
                class="btn btn-danger" Font-Bold="True"  />
            <br />
            <br />

            <%-- <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="887px" AsyncRendering="false"></rsweb:ReportViewer>--%>
            <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="100%" Height="800px" ProcessingMode="Local">
            </rsweb:ReportViewer>

        </div>
    </div>
<script>
 
function initDropdownEvents() {

    const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

    const repeaterContainer1 = document.getElementById("RepeaterContainer1");
 
    textBox1.addEventListener("focus", function () {

        repeaterContainer1.style.display = "block";

    });
 
    textBox1.addEventListener("input", function () {

        const input = textBox1.value.toLowerCase();

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
