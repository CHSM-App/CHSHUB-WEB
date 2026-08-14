<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="flat_search.aspx.cs" Inherits="Society.flat_search" MasterPageFile="~/Site.Master" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <style>
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
        .resized-model {
            width: 100%;
            max-width: 750px;
            height: auto;
            margin: auto;
        }
        @media (max-width: 576px) {
            .resized-model {
                max-width: 100%;
                margin-top: 0;
            }
            .modal-dialog {
                margin: 0.5rem;
            }
            .suggestion-list {
                width: 100% !important;
            }
            .search-container {
                width: 100%;
            }
            .input-buttons {
                display: flex;
                justify-content: flex-end;
            }
        }
        .dropdown-container {
            position: relative;
        }
        .suggestion-list {
            position: absolute;
            z-index: 1000;
            background: white;
            border: 1px solid #ccc;
            max-height: 200px;
            overflow-y: auto;
            width: 100%;
        }
        .suggestion-item {
            padding: 8px;
            cursor: pointer;
        }
        .suggestion-item:hover {
            background: #f0f0f0;
        }

        /* GridView PDF export dark border */
.table.gridview-custom,
.table.gridview-custom th,
.table.gridview-custom td {
    border: 1px solid #333 !important; /* Dark border */
}

.table.gridview-custom th {
    background-color: #fff !important;
    color: #012970 !important;
    font-weight: bold;
}

.table.gridview-custom td {
    background-color: #fff !important;
}

    </style>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">
        function openModal() {
            $('#edit_model').modal('show');
        }
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
                    window.location.href = 'flat_search.aspx';
                }
            });
        }
        function disableSaveButtonIfValid() {
            validateIFSC();
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit_model');
            var inputs = modal.querySelectorAll('input[required], select[required]');
            var allValid = true;
            inputs.forEach(function (input) {
                if (!input.checkValidity()) {
                    allValid = false;
                }
            });
            if (allValid && btn) {
                btn.disabled = true;
                btn.value = "Saving...";
                __doPostBack('<%= btn_save.UniqueID %>', '');
                return false;
            }
            return false;
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

        function triggerSearch() {
            var btn = document.getElementById('btn_search');
            if (btn) {
                btn.click();
            }
        }

    </script>
    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="80%" class="">
                            <h1 class="tex0 font-weight-bold" style="color: #012970;">Flats
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="flat_id" runat="server" />
                        <asp:HiddenField ID="society_id" runat="server" />
                        <asp:HiddenField ID="society_name" runat="server" />
                        <asp:HiddenField ID="HiddenField1" runat="server" />
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="d-flex align-items-center flex-wrap">
                                        <div class="search-container">
                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox form-control"
                                                placeHolder="Search here"
                                                runat="server"
                                                TextMode="Search"                                               
                                                autocomplete="off"
                                                onkeyup="triggerSearch()" />
                                            <!-- Calendar and Search Buttons -->
                                            <div class="input-buttons">
                                                <button
                                                    id="btn_search"
                                                    type="button"
                                                    class="search-button2"                                                 
                                                    onclick="filterTable()">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-primary mt-2 mt-sm-0" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;
                                        <button class="btn btn-primary mt-2 mt-sm-0" onclick="printFlatMaster()">Print</button>
                                        &nbsp;
                                        <button class="btn btn-success mt-2 mt-sm-0" onclick="downloadReceipt()">Download PDF</button>
                                    </div>
                                </div>
                            </div> 
                        </div>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div style="overflow:visible" class="table-responsive g-Table">
                                        <asp:GridView ID="GridView1" runat="server" AllowPaging="true" PageSize="50" OnPageIndexChanging="GridView1_PageIndexChanging" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">
                                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="facility_id" ItemStyle-Width="150px" SortExpression="flat_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="flat_id" runat="server" Text='<%# Bind("flat_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Building & Wing Name" SortExpression="build_wing">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl5" runat="server" Text='<%# Bind("build_wing")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Flat No" SortExpression="flat_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl2" runat="server" Text='<%# Bind("flat_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Bedrooms" SortExpression="bed">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl4" runat="server" Text='<%# Bind("bed")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Sq.Ft" SortExpression="sq_ft">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl1" runat="server" Text='<%# Bind("sq_ft")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Types" SortExpression="flat_type">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl8" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Usege" SortExpression="usage">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lbl12" runat="server" Text='<%# Bind("usage")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("flat_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" Visible="false" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="delete" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
                <div class="modal fade" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Add Flat</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="Building_id" runat="server" />
                                        <asp:HiddenField ID="flat_type_id" runat="server" />
                                        <asp:HiddenField ID="usage_id" runat="server" />
                                        <asp:HiddenField ID="Bedroom_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label5" runat="server" Text="Building & Wing :"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Building/Wing" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("wing_id") %>'
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
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Flat Type :"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select " required="required" autocomplete="off" />
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("flat_type") %>'
                                                                        CommandArgument='<%# Eval("flat_type_id") %>'
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
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label11" runat="server" Text="Flat No "></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:TextBox ID="txt_no" CssClass="form-control" Style="text-transform: capitalize;" parsely="trigger" AutoPostBack="true" required OnTextChanged="txt_no_TextChanged" PlaceHolder="Enter Flat Number" runat="server"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Flat No
                                                    </div>
                                                    <br />
                                                    <asp:Label ID="Label20" ForeColor="Red" Font-Bold="true" runat="server"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label2" runat="server" Text="Usage"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Usage" required="required" autocomplete="off" />
                                                        <div id="RepeaterContainer3" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand3">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link link3"
                                                                        Text='<%# Eval("usage") %>'
                                                                        CommandArgument='<%# Eval("usage_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox3(this.innerText);" />
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
                                            <div class="row">
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label1" runat="server" Text="Bedrooms"></asp:Label>
                                                    <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox4" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Bedroom" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer4" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater4" runat="server" OnItemDataBound="Repeater4_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand4">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link link4"
                                                                        Text='<%# Eval("bed") %>'
                                                                        CommandArgument='<%# Eval("bed_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox4(this.innerText);" />
                                                                    
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label6" runat="server" Text="Size(Sq.Ft)"></asp:Label>
                                                    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                
                                                <div class="col-sm-3 col-12">
                                                    <asp:TextBox ID="txt_feet" CssClass="form-control" runat="server" placeholder="Enter size" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Size
                                                    </div>
                                                </div>
                                            </div>
                                            
                                        </div>
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label14" runat="server" Text="Open Terraced(Sq.Ft)"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:TextBox ID="txt_terrace" CssClass="not-required form-control" runat="server" placeholder="Enter size"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Size
                                                    </div>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:Label ID="Label18" runat="server" Text="InterCom No"></asp:Label>
                                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-3 col-12">
                                                    <asp:TextBox ID="txt_intercom" CssClass="not-required form-control" runat="server" placeholder="Enter Number"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter No
                                                    </div>
                                                </div>

                                            </div>
                                        </div>
                                        <asp:Label runat="server" Visible="false" ID="building_lbl"></asp:Label>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>
                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" type="button-submit" runat="server" Text="Save" OnClick="btn_save_Click" class="btn btn-primary" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                        </center>
                                        <br />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <br />
    <br />
    <!-- Flat PDF Modal -->
    <div class="modal fade" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <div class="modal-content resized-model">
                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Flat Details</strong></h4>
                </div>
                <!-- Modal Body -->
                <div class="modal-body">
                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>
                    <!-- GridView Container -->
                    <div class="table-responsive" style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">
                        <asp:GridView ID="GridView2" runat="server"
                            CssClass="table table-bordered table-hover table-sm gridview-custom"
                            AutoGenerateColumns="false"
                            ShowHeaderWhenEmpty="true"
                            EmptyDataText="No data found."
                            HeaderStyle-BackColor="#012970"
                            HeaderStyle-ForeColor="White"
                            Font-Size="Small"
                            GridLines="Both"
                            CellPadding="6"
                            BorderStyle="None"
                            BorderWidth="0px">
                            <Columns>
                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField HeaderText="Building & Wing Name" DataField="build_wing" />
                                <asp:BoundField HeaderText="Flat No" DataField="flat_no" />
                                <asp:BoundField HeaderText="Bedrooms" DataField="bed" />
                                <asp:BoundField HeaderText="Sq.Ft" DataField="sq_ft" />
                                <asp:BoundField HeaderText="Types" DataField="flat_type" />
                                <asp:BoundField HeaderText="Usage" DataField="usage" />
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
    <script>
        let formSubmitted = false;
    </script>
    <script type="text/javascript">
        async function downloadFlatMaster() {
            const { jsPDF } = window.jspdf;
            const sourceElement = document.querySelector("#pdfFlatModal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");
            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }
            // Clear and clone modal body content
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            clone.style.width = `${sourceElement.offsetWidth}px`; // Match original width
            cloneContainer.appendChild(clone);
            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true
                });
                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");
                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;
                const title = "Flat Master Details";
                // Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40); // Heading Y pos
                // Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60;
                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("FlatMasterReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }

        //async function downloadReceipt() {
        //    const { jsPDF } = window.jspdf;
        //    const sourceElement = document.querySelector("#pdfmodal .modal-body");
        //    const cloneContainer = document.getElementById("pdf-clone-container");
        //    if (!sourceElement || !cloneContainer) {
        //        alert("Cannot find content to export.");
        //        return;
        //    }
        //    // Clone modal-body into offscreen div
        //    cloneContainer.innerHTML = "";
        //    const clone = sourceElement.cloneNode(true);
        //    cloneContainer.appendChild(clone);
        //    try {
        //        const canvas = await html2canvas(clone, {
        //            scale: 2,
        //            useCORS: true
        //        });
        //        const imgData = canvas.toDataURL("image/png");
        //        const pdf = new jsPDF("p", "pt", "a4");
        //        const pageWidth = pdf.internal.pageSize.getWidth();
        //        const margin = 40;
        //        const title = "Flat Details "
        //        // ✅ Add Centered Heading
        //        pdf.setFontSize(16);
        //        pdf.setFont("helvetica", "bold");
        //        const textWidth = pdf.getTextWidth(title);
        //        const x = (pageWidth - textWidth) / 2;
        //        pdf.text(title, x, 40); // Y position = 40pt from top
        //        // ✅ Add Image Below Heading
        //        const imgWidth = pageWidth - margin * 2;
        //        const imgHeight = (canvas.height * imgWidth) / canvas.width;
        //        const imageY = 60; // leave room for heading
        //        pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
        //        pdf.save("FlatReport.pdf");
        //    } catch (err) {
        //        console.error("Error generating PDF:", err);
        //        alert("Failed to generate PDF.");
        //    }
        //}


        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;
            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");

            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clear previous clone
            cloneContainer.innerHTML = "";

            // Clone modal body
            const clone = sourceElement.cloneNode(true);

            // Force dark borders for table inside clone
            const tables = clone.querySelectorAll('table');
            tables.forEach(tbl => {
                tbl.classList.add('gridview-custom'); // Apply dark border CSS
                tbl.style.border = "1px solid #333";  // extra safety
                tbl.querySelectorAll('th, td').forEach(cell => {
                    cell.style.border = "1px solid #333";
                });
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true,
                    backgroundColor: '#fff' // Ensure white background
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();
                const margin = 40;

                // Heading
                const title = "Flat Details";
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40);

                // Add table image
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60; // leave room for heading
                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);

                pdf.save("FlatReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }

        
        <%--function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");
            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");
            const textBox4 = document.getElementById("<%= TextBox4.ClientID %>");
            const repeaterContainer4 = document.getElementById("RepeaterContainer4");
            textBox1.addEventListener("focus", function () {
                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
            });
            textBox1.addEventListener("input", function () {
                const input = textBox1.value.toLowerCase();
                filterSuggestions("category-link", input);
            });
            textBox2.addEventListener("focus", function () {
                repeaterContainer2.style.display = "block";
            });
            textBox2.addEventListener("input", function () {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("link2", input);
            });
            textBox3.addEventListener("focus", function () {
                repeaterContainer3.style.display = "block";
            });
            textBox3.addEventListener("input", function () {
                const input = textBox3.value.toLowerCase();
                filterSuggestions("link3", input);
            });
            textBox4.addEventListener("focus", function () {
                repeaterContainer4.style.display = "block";
            });
            textBox4.addEventListener("input", function () {
                const input = textBox4.value.toLowerCase();
                filterSuggestions("link4", input);
            });
        }--%>

        function closeAllDropdowns() {
            document.getElementById("RepeaterContainer1").style.display = "none";
            document.getElementById("RepeaterContainer2").style.display = "none";
            document.getElementById("RepeaterContainer3").style.display = "none";
            document.getElementById("RepeaterContainer4").style.display = "none";
        }

        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            const textBox4 = document.getElementById("<%= TextBox4.ClientID %>");

            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");
            const repeaterContainer4 = document.getElementById("RepeaterContainer4");

            //textBox1
            textBox1.addEventListener("focus", function () {               
                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
                repeaterContainer4.style.display = "none";
            });

            textBox1.addEventListener("input", function () {
                const input = textBox1.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox2
            textBox2.addEventListener("focus", function () {               
                repeaterContainer2.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer3.style.display = "none";
                repeaterContainer4.style.display = "none";
            });

            textBox2.addEventListener("input", function () {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("category-link", input);               
            });

            //textBox3
            textBox3.addEventListener("focus", function () {               
                repeaterContainer3.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer2.style.display = "none";
                repeaterContainer4.style.display = "none";
            });

            textBox3.addEventListener("input", function () {
                const input = textBox3.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            //textBox4
            textBox4.addEventListener("focus", function () {               
                repeaterContainer4.style.display = "block";
                repeaterContainer1.style.display = "none";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
            });

            textBox4.addEventListener("input", function () {
                const input = textBox4.value.toLowerCase();
                    filterSuggestions("category-link", input );
            });

            // Close dropdown when clicking anywhere else
            document.addEventListener("click", function (e) {
                if (!e.target.closest(".dropdown-container")) {
                    closeAllDropdowns();
                }
            });

        }

       

        // Important for UpdatePanel
        Sys.Application.add_load(function () {
            initDropdownEvents();
        });



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
            closeAllDropdowns();
        }


        function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            closeAllDropdowns();
        }


        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            closeAllDropdowns();
        }


        function setTextBox4(value) {
            document.getElementById("<%= TextBox4.ClientID %>").value = value;
            closeAllDropdowns();
        }


        function printDivContent(divId) {
            var printContents = document.getElementById(divId).innerHTML;
            var originalContents = document.body.innerHTML;
            document.body.innerHTML = printContents;
            window.print();
            document.body.innerHTML = originalContents;
            location.reload(); // Optional: reload to restore scripts/events
        }

        function printFlatMaster() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;
            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Visitor Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body {font - size: 12px; margin: 30px; font-family: Arial, sans-serif; }');
            printWindow.document.write('h4 {margin - bottom: 10px; text-align: center; }');
            printWindow.document.write('.table {width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td {border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th {background - color: #012970; color: white; text-align: center; }');
            printWindow.document.write('.print-header {text - align: center; margin-bottom: 20px; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');
            // Add centered headers manually
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>'); // Visitor Details
            printWindow.document.write('</div>');
            // Add GridView content
            printWindow.document.write(modalContent);
            // Optional: Print timestamp
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + new Date().toLocaleString() + '</div>');
            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }
        Sys.Application.add_load(initDropdownEvents);
    </script>
</asp:Content>