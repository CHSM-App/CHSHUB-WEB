<%@ Page Title="Contact" Language="C#" AutoEventWireup="true" CodeBehind="printowner.aspx.cs" Inherits="Society.printowner" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms, Version=15.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
    Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <h1 class=" tex0 font-weight-bold " style="color: #012970;">Flat Owners Reports
    </h1>
    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <asp:HiddenField ID="society_id" runat="server" />
            <asp:HiddenField ID="building_id" runat="server" />
            <asp:HiddenField ID="wing_id" runat="server" />

            <div class="form-group">

                <div class="d-flex align-items-center bg-white p-2 justify-content-around">
                    <div class="col-sm-3 d-flex align-items-center ">
                        <asp:Label ID="lbl_acc_no" Width="176px" runat="server" Text="Building Name :"></asp:Label>

                        <div class="dropdown-contaier">
                            <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                placeholder="Select" autocomplete="off" required="required"  />
                            <div id="RepeaterContainer1" class="suggestion-list" style="width:50%;">
                                <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater1_ItemCommand">
                                    <ItemTemplate>
                                        <asp:LinkButton
                                            ID="lnkCategory"
                                            runat="server"
                                            CssClass="suggestion-item link-button category-link"
                                            Text='<%# Eval("build_name") %>'
                                            CommandArgument='<%# Eval("build_id") %>'
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

                    <div class="col-sm-3 d-flex align-items-center">
                        <asp:Label Width="57px" ID="lbl_date" runat="server" Text="Wing :"></asp:Label>

                        <div class="dropdown-contaier">
                            <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                placeholder="Select" autocomplete="off" required="required" style="width:72%;" />
                            <div id="RepeaterContainer2" class="suggestion-list" style="width:50%;">
                                <asp:Repeater ID="Repeater2" runat="server" OnItemCommand="CategoryRepeater2_ItemCommand">
                                    <ItemTemplate>
                                        <asp:LinkButton
                                            ID="lnkCategory"
                                            runat="server"
                                            CssClass="suggestion-item link-button category-link"
                                            Text='<%# Eval("w_name") %>'
                                            CommandArgument='<%# Eval("wing_id") %>'
                                            CommandName="SelectCategory"
                                            OnClientClick="setTextBox2(this.innerText);" />
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
                    class="btn btn-primary" Font-Bold="True" />
                 <asp:Button ID="Button2" runat="server" Text="Download Report" OnClick="Button1_Click"
                        class="btn btn-danger" Font-Bold="True" />
                <br />
                <br />
                <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="61%"></rsweb:ReportViewer>
            </div>
        </ContentTemplate>
    </asp:UpdatePanel>

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

    const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");

            const repeaterContainer2 = document.getElementById("RepeaterContainer2");

            textBox2.addEventListener("focus", function () {

                repeaterContainer2.style.display = "block";

            });

            textBox2.addEventListener("input", function () {

                const input = textBox2.value.toLowerCase();

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

        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;

            document.getElementById("RepeaterContainer2").style.display = "none";

        }

        Sys.Application.add_load(initDropdownEvents);


    </script>

</asp:Content>
