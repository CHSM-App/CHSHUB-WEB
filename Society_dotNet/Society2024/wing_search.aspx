 <%@ Page Language="C#" AutoEventWireup="true" CodeBehind="wing_search.aspx.cs" Inherits="Society.wing_search" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <link href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css" rel="stylesheet" />
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>

    <style>
        .resized-model {
            width: 529px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 292px;
                right: 1px;
            }
        }

        .not-required.valid-field {
            border-color: #1cc88a !important;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='8' height='8' viewBox='0 0 8 8'%3e%3cpath fill='%231cc88a' d='M2.3 6.73L.6 4.53c-.4-1.04.46-1.4 1.1-.8l1.1 1.4 3.4-3.8c.6-.63 1.6-.27 1.2.7l-4 4.6c-.43.5-.8.4-1.1.1z'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right calc(.375em + .1875rem) center;
            background-size: calc(.75em + .375rem) calc(.75em + .375rem);
        }

        .not-required.invalid-field {
            border-color: #e74a3b !important;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='none' stroke='%23e74a3b' viewBox='0 0 12 12'%3e%3ccircle cx='6' cy='6' r='4.5'/%3e%3cpath stroke-linejoin='round' d='M5.8 3.6h.4L6 6.5z'/%3e%3ccircle cx='6' cy='8.2' r='.6' fill='%23e74a3b' stroke='none'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right calc(.375em + .1875rem) center;
            background-size: calc(.75em + .375rem) calc(.75em + .375rem);
        }


</style>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">
        function FailedEntry() {
            Swal.fire({
                title: '❌ Failed!',
                text: 'Something went wrong. Please try again.',
                icon: 'error',
                showConfirmButton: true,
                confirmButtonColor: '#d33',
                confirmButtonText: 'Retry',
                timer: 3000,
                timerProgressBar: true,

                didOpen: () => {
                    Swal.showLoading()
                }


            });

        }
        function SuccessEntry() {
            Swal.fire({
                title: '✅ Success!',
                text: 'Saved Successfully',
                icon: 'success',
                showConfirmButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'OK',
                timer: 1400,
                timerProgressBar: true,

                didOpen: () => {
                    Swal.showLoading()
                },
                willClose: () => {
                    window.location.href = 'wing_search.aspx';
                }
            });
        }


        function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
            if (!input) return;

            const filter = input.value.toLowerCase();
            const table = document.querySelector('.g-Table table');

            if (!table) return;

            const rows = table.getElementsByTagName('tr');

            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                const cells = row.getElementsByTagName('td');
                let found = false;

                for (let j = 0; j < cells.length - 1; j++) {
                    const cell = cells[j];
                    if (cell && cell.textContent.toLowerCase().indexOf(filter) > -1) {
                        found = true;
                        break;
                    }
                }

                row.style.display = found ? '' : 'none';
            }
        }

    </script>
    <script type="text/javascript">
        function validateInput(sender, args) {
            var input = document.getElementById(args.ControlToValidate);
            var value = input.value.trim();

            if (value.length < 5) {
                input.classList.add("invalid-feedback");
                args.IsValid = false;
            } else {
                input.classList.add("valid-feedback");
                args.IsValid = true;
            }
        }
    </script>
    <div class="box box-primary">
        <div class="box-header with-border">

            <div class="box-body">


                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Wings
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel UpdateMode="Conditional" ID="wings" runat="server">
                    <ContentTemplate>
                        <asp:HiddenField ID="HiddenField4" runat="server" />
                        <asp:HiddenField ID="society_id" runat="server" />

                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="d-flex align-items-center">
                                        <div class="search-container">

                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox"
                                                placeHolder="Search here"
                                                runat="server"
                                                TextMode="Search"
                                                AutoPostBack="true"
                                                autocomplete="off"
                                                onkeyup="filterTable()"/>

                                            <!-- Calendar and Search Buttons -->
                                            <div class="input-buttons">
                                                <button
                                                    id="btn_search"
                                                    type="submit"
                                                    class="search-button2"
                                                    runat="server"
                                                    onclick="filterTable()">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>

                                        &nbsp;&nbsp;
                                        <button   type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                    </div>
                                </div>
                            </div>
                        </div>

<div class="form-group">
    <div class="row">
        <div class="col-sm-12">
            <div style="width: 100%; overflow: visible;" class="g-Table">
                <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" 
                    CssClass="table table-bordered table-hover table-striped"
                    AllowSorting="true" ShowHeaderWhenEmpty="true" 
                    EmptyDataText="No Record Found" 
                    OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" 
                    OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">
                    
                                        <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                   
                                            <%-- <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="w_id" SortExpression="wing_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="wing_id" runat="server" Text='<%# Bind("wing_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Building" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Wing Name" SortExpression="w_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="w_name" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandArgument='<%# Bind("wing_id")%>'>
                                                         <img src="Images/123.png" /></asp:LinkButton>
                                                          </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Delete" Visible="false" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');">
                                                            <img src="Images/delete_10781634.png" height="25" width="25" />
                                                        </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <%--                                    <asp:LinkButton  ButtonType="Button" data-toggle="modal" data-target=".bs-example-modal-sm" SelectText="Edit" ControlStyle-ForeColor="blue" />--%>
                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btn_close" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>

                <div class="modal fade bs-example-modal-sm" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content resized-model">
                            <div class="modal-header">

                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Wing</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="ddl_build_name" runat="server" />
                                        <asp:HiddenField ID="wing_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-5">

                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Building No/Name :"></asp:Label>

                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-7">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="categoryBox" Style="width: 200px;" runat="server" CssClass="search-box form-control"
                                                            placeholder="Select Building/Wing" autocomplete="off" required="required" />
                                                        <asp:HiddenField ID="hdnCategoryId" runat="server" />
                                                        <div id="categoryRepeaterContainer" class="suggestion-list">
                                                            <asp:Repeater ID="categoryRepeater" runat="server" OnItemCommand="CategoryRepeater_ItemCommand" OnItemDataBound="categoryRepeater_ItemDataBound">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("build_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setCategoryBox(this.innerText);" />
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

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-5">

                                                    <asp:Label ID="Label1" runat="server" Text="Wing :"></asp:Label>

                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-7">
                                                    <asp:TextBox ID="txt_w_name" CssClass="form-control" parsley-trigger="change" runat="server" class="form-control" Width="200px" Height="32px" ToolTip="Wing" OnTextChanged="txt_w_name_TextChanged" AutoPostBack="true" placeholder="Enter Wing Name" required="required" autofocus></asp:TextBox>
                                                    <asp:Label ID="Label4" runat="server" Font-Bold="true" ForeColor="Red"></asp:Label>
                                                    <div class="invalid-feedback">
                                                        Please Enter Wing Name
                                                    </div>
                                                </div>

                                            </div>
                                        </div>


                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>

                            </div>
                            <div class="modal-footer">

                                <div class="form-group">
                                    <div class="row ">

                                        <center>
                                            <asp:Button OnClientClick="disableSaveButtonIfValid();" ID="btn_save" runat="server" Text="Save" OnClick="btn_save_Click" class="btn btn-primary" ValidationGroup="g1" UseSubmitBehavior="True" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" runat="server" Visible="false" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick = "resetForm(); return false;"  data-dismiss="modal" />
                                        </center>
                                        </>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                    <!-- /.modal-body -->
                </div>
                <!-- /.modal-content -->
            </div>
            <!-- /.modal-dialog -->
        </div>
    </div>


    <script>
        // Add this script to your page - it replaces the existing disableSaveButtonIfValid function

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit_model');
            var inputs = modal.querySelectorAll('input[required], select[required]');
            var allValid = true;

            // Check all required fields
            inputs.forEach(function (input) {
                if (!input.checkValidity()) {
                    allValid = false;
                }
            });

            // CRITICAL: Check if user selected from the repeater
            var categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
            var hdnCategoryId = document.getElementById("<%= wing_id.ClientID %>");

            if (!hdnCategoryId.value || hdnCategoryId.value.trim() === "") {
                allValid = false;

                // Show error message
                categoryBox.classList.add("is-invalid");

                // Show alert to user
                Swal.fire({
                    title: 'Selection Required',
                    text: 'Please select a Building from the dropdown list',
                    icon: 'warning',
                    confirmButtonColor: '#3085d6',
                    confirmButtonText: 'OK'
                });

                return false;
            }

            if (allValid && btn) {
                btn.disabled = true;
                btn.value = "Saving...";
                __doPostBack('<%= btn_save.UniqueID %>', '');
                return false;
            }

            return false;
        }

        let formSubmitted = false;

        function initDropdownEvents() {
            const categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
            const categorySuggestions = document.getElementById("categoryRepeaterContainer");
            const hdnCategoryId = document.getElementById("<%= wing_id.ClientID %>");

            categoryBox.addEventListener("focus", function () {
                categorySuggestions.style.display = "block";
            });

            categoryBox.addEventListener("input", function () {
                const input = categoryBox.value.toLowerCase();

                // Clear the hidden field when user types
                hdnCategoryId.value = "";

                // Remove invalid class when user starts typing
                categoryBox.classList.remove("is-invalid");

                filterSuggestions("category-link", input);
            });

            // Close dropdown when clicking outside
            document.addEventListener("click", function (e) {
                if (!categoryBox.contains(e.target) && !categorySuggestions.contains(e.target)) {
                    categorySuggestions.style.display = "none";
                }
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
                    noMatchMessage.className = "text-muted p-2";
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

        function setCategoryBox(value) {
            document.getElementById("<%= categoryBox.ClientID %>").value = value;
            document.getElementById("categoryRepeaterContainer").style.display = "none";

            // Remove invalid class when valid selection is made
            document.getElementById("<%= categoryBox.ClientID %>").classList.remove("is-invalid");
        }

        function resetForm() {
            // Clear the category box
            var categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
            var hdnCategoryId = document.getElementById("<%= wing_id.ClientID %>");

            if (categoryBox) {
                categoryBox.value = "";
                categoryBox.classList.remove("is-invalid");
            }

            if (hdnCategoryId) {
                hdnCategoryId.value = "";
            }

            // Clear wing name
            var wingName = document.getElementById("<%= txt_w_name.ClientID %>");
            if (wingName) {
                wingName.value = "";
            }
        }

        Sys.Application.add_load(initDropdownEvents);
    </script>

</asp:Content>


        
