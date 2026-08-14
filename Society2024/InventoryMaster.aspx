<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="InventoryMaster.aspx.cs" Inherits="Society.InventoryMaster" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        .resized-model {
            width: 700px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 768px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 90%;
                right: 1px;
            }
        }

        .form-row-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        @media(max-width: 576px) {
            .form-row-grid {
                grid-template-columns: 1fr;
            }
        }

        .stock-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .stock-high {
            background: #d4edda;
            color: #155724;
        }

        .stock-medium {
            background: #fff3cd;
            color: #856404;
        }

        .stock-low {
            background: #f8d7da;
            color: #721c24;
        }

        .action-icons {
            display: flex;
            gap: 10px;
            justify-content: center;
        }

        .action-icon {
            cursor: pointer;
            transition: all 0.2s;
        }

            .action-icon:hover {
                transform: scale(1.2);
            }
    </style>



    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class="tex0 font-weight-bold" style="color: #012970;">Inventory Management
                            </h1>
                        </th>
                    </tr>
                </table>

                <asp:UpdatePanel UpdateMode="Conditional" ID="upnlInventory" runat="server">
                    <ContentTemplate>

                        <asp:HiddenField ID="society_id" runat="server" />
                        <asp:HiddenField runat="server" ID="vendor_name_id" Value="0" />
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="d-flex align-items-center">
                                        <div class="search-container">
                                            <asp:TextBox ID="txtSearch" CssClass="aspNetTextBox" placeholder="Search here..." runat="server" TextMode="Search" onkeyup="filterTable()" />

                                            <div class="input-buttons">
                                                <button type="button" class="search-button2">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>

                                      <%--  &nbsp;&nbsp;
										<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">
                                            <i class="fas fa-plus"></i>Add New Item
                                        </button>--%>
                                        &nbsp;
										<button type="button" class="btn btn-success" onclick="location.href='VendorBill.aspx'">
                                            <i class="fas fa-file-invoice"></i>Vendor Bills
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;">
                                        <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Inventory Items Found" HeaderStyle-BackColor="lightblue" AllowPaging="true" PageSize="10">
                                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Item ID" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblItemId" runat="server" Text='<%# Bind("item_id") %>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Item Name" SortExpression="item_name">
                                                    <ItemTemplate>
                                                        <strong><%# Eval("item_name") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Vendor" SortExpression="item_name">
                                                    <ItemTemplate>
                                                        <strong><%# Eval("vendor_name") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Date" SortExpression="item_name">
                                                    <ItemTemplate>

                                                        <strong><%# Eval("purchase_date", "{0:dd-MMM-yyyy}") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Quantity" SortExpression="item_name">
                                                    <ItemTemplate>
                                                        <strong><%# Eval("quantity") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Warranty" SortExpression="warranty_last_date">
                                                    <ItemTemplate>
                                                        <strong><%# Eval("warranty_last_date", "{0:dd-MMM-yyyy}") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <asp:TemplateField HeaderText="Total Amount" SortExpression="item_name">
                                                    <ItemTemplate>
                                                        <strong><%# Eval("total_amount") %></strong>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Condition" SortExpression="item_name">
                                                    <ItemTemplate>
                                                        <asp:DropDownList
                                                            ID="ddl_condition"
                                                            runat="server"
                                                            CssClass="form-control"
                                                            AutoPostBack="true"
                                                            SelectedValue='<%# Eval("condition_status") == DBNull.Value ? "0" : Eval("condition_status") %>' OnSelectedIndexChanged="ddl_conditiond_SelectedIndexChanged">

                                                            <asp:ListItem Text="Select" Value="0"></asp:ListItem>
                                                            <asp:ListItem Text="New" Value="1"></asp:ListItem>
                                                            <asp:ListItem Text="Good" Value="2"></asp:ListItem>
                                                            <asp:ListItem Text="Needs repair" Value="3"></asp:ListItem>
                                                            <asp:ListItem Text="Disposed" Value="4"></asp:ListItem>

                                                        </asp:DropDownList>


                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <%--            <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("item_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>--%>


                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                    <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
                                        <i class="fas fa-box-open"></i>
                                        <h3>No Inventory Items Found</h3>
                                        <p>Start by adding your first inventory item</p>
                                    </asp:Panel>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnClose" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>



                <!-- Add/Edit Modal -->
                <div class="modal fade" id="edit_model" role="dialog" data-backdrop="static">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title">
                                    <i class="fas fa-box"></i><span id="modalTitle">Add New Item</span>
                                </h4>
                            </div>
                            <div class="modal-body">
                                <asp:UpdatePanel ID="upnlModal" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="hdnItemId" runat="server" />
                                        <asp:HiddenField ID="hdnVendorId" runat="server" />
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-4">
                                                    <asp:Label runat="server" Text="Item :"></asp:Label>
                                                    <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-8">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass=" form-control" placeholder="Select" autocomplete="off" required="required" />
                                                        <asp:Panel ID="drp_Container" runat="server">
                                                            <div id="RepeaterContainer1" class="suggestion-list" style="width: 100%">
                                                                <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                    <ItemTemplate>
                                                                        <%--  <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='t'
                                                                        CommandName="SelectCategory"
                                                                        CommandArgument='<%# Eval("item_id") + "|" 
																			+ Eval("vendor_name") + "|" 
																			+ Eval("purchase_date","{0:yyyy-MM-dd}") + "|" 
																			+ Eval("purchase_cost") + "|" 
																			+ Eval("quantity") + "|" 
																			+ Eval("condition_status") + "|" 
																			+ Eval("remarks") + "|"
																			+ Eval("vendor_id")+"|"
																			+ Eval("warranty") 
																			%>' OnClientClick="setCategoryBox1(this.innerText);"/>--%>
                                                                    </ItemTemplate>
                                                                    <FooterTemplate>
                                                                        <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>' Text="No items found." />
                                                                    </FooterTemplate>
                                                                </asp:Repeater>
                                                            </div>
                                                        </asp:Panel>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-4">
                                                    <asp:Label runat="server" Text="Vendor Name:"></asp:Label>
                                                    <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-8">
                                                    <asp:TextBox ID="txtItemName" runat="server" CssClass="form-control" placeholder="Enter item name" required="required"></asp:TextBox>
                                                    <asp:RequiredFieldValidator runat="server" ControlToValidate="txtItemName" ErrorMessage="Item name is required" ForeColor="Red" Display="Dynamic" ValidationGroup="ItemValidation"></asp:RequiredFieldValidator>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Purchase Date"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="date" runat="server" CssClass="form-control" TextMode="Date" placeholder="0.00" required="required" AutoPostBack="true" OnTextChanged="date_TextChanged"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Purchase Cost"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="txt_Cost" runat="server" CssClass="form-control" TextMode="Number" placeholder="0.00" required="required"></asp:TextBox>
                                                            <asp:RequiredFieldValidator runat="server" ControlToValidate="txt_Cost" ErrorMessage="Current stock is required" ForeColor="Red" Display="Dynamic" ValidationGroup="ItemValidation"></asp:RequiredFieldValidator>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row">

                                                <!-- Quantity -->
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Quantity:"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="txt_quantity" runat="server" CssClass="form-control" placeholder="Enter Quantity" required="required"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Condition -->
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Condition"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            
                                                        </div>
                                                    </div>
                                                </div>

                                            </div>
                                        </div>



                                        <!-- Warranty Section -->
                                        <div class="form-group">
                                            <div class="row">

                                                <!-- Warranty Months -->
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Warranty(Months)"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="txtWarrantyMonths" runat="server" CssClass="form-control" TextMode="Number"
                                                                placeholder="Enter months" AutoPostBack="true" OnTextChanged="txtWarrantyMonths_TextChanged"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Warranty Last Date -->
                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Warranty Last Date:"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="txtWarrantyLastDate" runat="server" CssClass="form-control" ReadOnly="true"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                            </div>
                                        </div>


                                        <div class="form-group">
                                            <div class="row">


                                                <div class="col-sm-6">
                                                    <div class="row">
                                                        <div class="col-sm-6">
                                                            <asp:Label runat="server" Text="Remark"></asp:Label>
                                                            <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-6">
                                                            <asp:TextBox ID="remark" runat="server" CssClass="form-control"></asp:TextBox>

                                                        </div>
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
                                <center>
                                    <asp:Button ID="btnSave" runat="server" Text="Save" OnClick="btnSave_Click" CssClass="btn btn-primary" ValidationGroup="ItemValidation" />
                                    <asp:Button ID="btnClose" runat="server" Text="Close" CssClass="btn btn-secondary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                </center>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>


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
                    window.location.href = 'InventoryMaster.aspx';
                }
            });
        }

        function openModal() {
            $('#edit_model').modal('show');
            document.getElementById('<%= hdnItemId.ClientID %>').value = '0';
            //clearForm();
        }

        function closeModal() {
            $('#edit_model').modal('hide');
            clearForm();
        }

        function clearForm() {
            document.getElementById('<%= txtItemName.ClientID %>').value = '';
            document.getElementById('<%= txt_quantity.ClientID %>').value = '';
            document.getElementById('<%= remark.ClientID %>').value = '';

            var btn = document.getElementById('<%= btnSave.ClientID %>');
            if (btn) {
                btn.disabled = false;
                btn.value = "Save";
            }
        }

        function editItem(itemId) {
            __doPostBack('EditItem', itemId);
        }

        function deleteItem(itemId) {
            Swal.fire({
                title: 'Are you sure?',
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, delete it!'
            }).then((result) => {
                if (result.isConfirmed) {
                    __doPostBack('DeleteItem', itemId);
                }
            });
        }

        function filterTable() {
            var input = document.getElementById('<%= txtSearch.ClientID %>');
            var filter = input.value.toLowerCase();
            var table = document.getElementById('<%= GridView1.ClientID %>');

            if (!table) return;

            var rows = table.getElementsByTagName('tr');

            for (var i = 1; i < rows.length; i++) {
                var row = rows[i];
                var cells = row.getElementsByTagName('td');
                var found = false;

                for (var j = 0; j < cells.length - 1; j++) {
                    var cell = cells[j];
                    if (cell && cell.textContent.toLowerCase().indexOf(filter) > -1) {
                        found = true;
                        break;
                    }
                }

                row.style.display = found ? '' : 'none';
            }
        }

        function disableSaveButton() {
            var btn = document.getElementById('<%= btnSave.ClientID %>');
            var itemName = document.getElementById('<%= txtItemName.ClientID %>').value.trim();
            var openingStock = document.getElementById('<%= txt_quantity.ClientID %>').value;
            var cost = document.getElementById('<%= txt_Cost.ClientID %>').value;
            var date = document.getElementById('<%= date.ClientID %>').value;

            if (!itemName || !openingStock || !cost || !date) {
                Swal.fire({
                    title: '⚠️ Validation Error',
                    text: 'Please fill all required fields.',
                    icon: 'warning',
                    confirmButtonColor: '#f39c12',
                    confirmButtonText: 'OK',
                    timer: 3000
                });
                return false;
            }

            if (btn) {
                btn.disabled = true;
                btn.value = "Saving...";
            }

            return true;
        }

        function resetForm() {
            clearForm();
        }

        function initDropdownEvents() {

            const categoryBox = document.getElementById("<%= TextBox1.ClientID %>");

            const categorySuggestions = document.getElementById("RepeaterContainer1");

            categoryBox.addEventListener("focus", function () {
                categorySuggestions.style.display = "block";
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


        function setCategoryBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            document.getElementById("RepeaterContainer1").style.display = "none";

        }

        Sys.Application.add_load(initDropdownEvents);
    </script>
</asp:Content>
