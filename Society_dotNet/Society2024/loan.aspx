<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="loan.aspx.cs" Inherits="Society.loan" MasterPageFile="~/Site.Master" %>


<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
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
        function openModal() {
            $('#edit_model').modal('show');
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
                    window.location.href = 'loan.aspx';
                }
            });
        }

        function disableSaveButtonIfValid() {
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

                return false; // prevent default to avoid double postback
            }

            return false; // prevent postback if not valid
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
                btn.click();   // ✅ correct
            }
        }

    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Loan
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="loan_id" runat="server" />


                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>


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
                                                autocomplete="off"
                                                onkeyup="triggerSearch()" />

                                            <ajaxToolkit:CalendarExtender
                                                ID="CalendarExtender1"
                                                runat="server"
                                                TargetControlID="txt_search"
                                                PopupButtonID="btn_calendar"
                                                Format="yyyy-MM-dd" />

                                            <!-- Calendar and Search Buttons -->
                                            <div class="input-buttons">
                                                <img
                                                    id="btn_calendar"
                                                    src="img/calendar.png"
                                                    alt="Pick Date"
                                                    class="calendar-icon"
                                                    style="cursor: pointer;" />

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
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                    </div>
                                </div>
                            </div>
                        </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">
                                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50px" SortExpression="No">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="loan_id" SortExpression="loan_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="loan_id" runat="server" Text='<%# Bind("loan_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Bank Name" SortExpression="bank">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Lblff" runat="server" Text='<%# Bind("bank")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Loan Clearance" ItemStyle-Width="250px" SortExpression="loan_clearance">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lfhf" runat="server" Text='<%# Bind("loan_clearance","{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50px">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("loan_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50px">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
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
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content" style="height: auto; width: auto">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Add Loan & Lien</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <asp:HiddenField ID="flat_no_id" runat="server" />
                                        <asp:HiddenField ID="loan_type_id" runat="server" />
                                        <asp:HiddenField ID="share_id" runat="server" />
                                        <div class="form-group">
                                            <div class="alert alert-danger danger" style="display: none;"></div>
                                        </div>

                                        <label>Flat Number:<asp:Label ID="Label1" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox1" Style="width: 100%" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" required="required" autocomplete="off" />
                                                <div id="RepeaterContainer1" style="width: 100%" class="suggestion-list">
                                                    <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1" OnItemDataBound="Repeater1_ItemDataBound">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("flat_no") %>'
                                                                CommandArgument='<%# Eval("flat_id") %>'
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

                                        <label>Name of the Bank:<asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="False" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <asp:TextBox ID="txt_bank" CssClass="form-control" Font-Bold="False" Style="text-transform: capitalize;" placeholder="Enter Bank Name" runat="server" required class="form-control"></asp:TextBox>
                                            <div class="invalid-feedback">
                                                Please Enter Bank Name
                                            </div>
                                        </div>

                                        <label>Type of Loan:<asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox2" Style="width: 100%" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" required="required" autocomplete="off" />
                                                <div id="RepeaterContainer2" class="suggestion-list" style="width: 100%">
                                                    <asp:Repeater ID="Repeater2" runat="server" OnItemCommand="CategoryRepeater_ItemCommand2" OnItemDataBound="Repeater2_ItemDataBound">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("loan_type") %>'
                                                                CommandArgument='<%# Eval("type_id") %>'
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

                                        <asp:Panel ID="Panel2" Visible="false" runat="server">
                                            <label class="specifyOthers">Specify Other:</label>
                                            <div class="form-group">
                                                <asp:TextBox ID="txt_other" Font-Bold="true" runat="server" Style="text-transform: capitalize;" class="form-control" required></asp:TextBox>
                                            </div>
                                        </asp:Panel>

                                        <label>First NOC Issue By:<asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <asp:DropDownList ID="ddl_noc" runat="server" class="form-control" parsely-trigger="change" BackColor="WhiteSmoke" required>
                                                <asp:ListItem>select</asp:ListItem>
                                                <asp:ListItem>Society</asp:ListItem>
                                                <asp:ListItem>Builder</asp:ListItem>
                                            </asp:DropDownList>
                                            <asp:CompareValidator ControlToValidate="ddl_noc" ID="CompareValidator3" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please select First NOC Issued By" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                        </div>

                                        <label>Society NOC Date:<asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <asp:TextBox ID="txt_noc_society" CssClass="form-control" Font-Bold="False" runat="server" TextMode="Date" class="form-control" required></asp:TextBox>
                                            <div class="invalid-feedback">
                                                Please Enter Date
                                            </div>
                                        </div>

                                        <asp:Panel ID="Panel1" Visible="false" runat="server">
                                            <div class="form-group">
                                                <label>Date of Loan Clearance:<asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                                <asp:TextBox ID="txt_loan_clear" Font-Bold="true" TextMode="Date" runat="server" class="form-control" required></asp:TextBox>
                                            </div>
                                        </asp:Panel>

                                        <label>Share Certificate With:<asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label></label>
                                        <div class="form-group">
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox3" Style="width: 100%" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" required="required" autocomplete="off" />
                                                <div id="RepeaterContainer3" style="width: 100%" class="suggestion-list">
                                                    <asp:Repeater ID="Repeater3" runat="server" OnItemCommand="CategoryRepeater_ItemCommand3" OnItemDataBound="Repeater3_ItemDataBound">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("c_name") %>'
                                                                CommandArgument='<%# Eval("cert_id") %>'
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
                                            <asp:Button ID="btn_save" type="button-submit" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" OnClick="btn_save_Click" ValidationGroup="g1" class="btn btn-primary" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />

                                        </center>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script type="text/javascript">

        function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");

            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

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

        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            document.getElementById("RepeaterContainer3").style.display = "none";
        }


        Sys.Application.add_load(initDropdownEvents);
    </script>







    <script>
        document.addEventListener('click', function (e) {

            // Close all dropdowns if click is outside any dropdown-container
            document.querySelectorAll('.dropdown-container').forEach(function (container) {
                var dropdown = container.querySelector('.suggestion-list');

                if (!container.contains(e.target)) {
                    if (dropdown) dropdown.style.display = 'none';
                }
            });
        });

        // Show dropdown on focus
        document.getElementById('<%= TextBox1.ClientID %>').addEventListener('focus', function () {
            document.getElementById('RepeaterContainer1').style.display = 'block';
        });

        document.getElementById('<%= TextBox2.ClientID %>').addEventListener('focus', function () {
        document.getElementById('RepeaterContainer2').style.display = 'block';
    });

    function setTextBox1(value) {
        document.getElementById('<%= TextBox1.ClientID %>').value = value;
        document.getElementById('RepeaterContainer1').style.display = 'none';
        return false; // stop postback flicker
    }

    function setTextBox2(value) {
        document.getElementById('<%= TextBox2.ClientID %>').value = value;
            document.getElementById('RepeaterContainer2').style.display = 'none';
            return false;
        }
    </script>

</asp:Content>
