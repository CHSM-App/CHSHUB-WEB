<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="shop_maintenance.aspx.cs" Inherits="Society.shop_maintenance" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <script type='text/javascript'>
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
            $('#edit').modal('show');
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
                    window.location.href = 'shop_maintenance.aspx';
                }
            });
        }

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_save.ClientID %>');
            var modal = document.getElementById('edit');
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
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Shop Maintenance</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="shop_maint_id" runat="server" />
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
                                                onkeyup="triggerSearch()"/>

                                            <ajaxtoolkit:calendarextender
                                                id="CalendarExtender1"
                                                runat="server"
                                                targetcontrolid="txt_search"
                                                popupbuttonid="btn_calendar"
                                                format="yyyy-MM-dd" />

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
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit">Add</button>
                                    </div>
                                </div>
                            </div>
                        </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;"class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" EmptyDataText="No Records found" ShowHeaderWhenEmpty="true">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="m_id" SortExpression="name" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="shop_maint_id" runat="server" Text='<%# Bind("shop_maint_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Recipt No" Visible="true" SortExpression="mrep_no">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="mrep_no" Text='<%# Bind("mrep_no")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Date" Visible="true" SortExpression="m_date">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="m_date" Text='<%# Bind("m_date","{0:yyyy-MM-dd}")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="ledger" Visible="true" SortExpression="led_id">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="led_id" Text='<%# Bind("led_description")%>'></asp:Label>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("flat_type")%>'></asp:Label>--%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit1" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("shop_maint_id")%>'><img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50" Visible="false">
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
                <div class="modal fade bs-example-modal-sm" id="edit" role="form" aria-labelledby="mymodel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content" style="height: auto; width: 800px;">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystem"><strong>Shop Maintenance</strong></h4>
                            </div>
                            <d class="modal-body" id="invoice_data">
                                <asp:UpdatePanel ID="updatepnl" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        
                        <asp:HiddenField ID="ledger_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label6" runat="server" Text="Receipt No:"></asp:Label>
                                                    <asp:Label ID="Label7" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_recipt" CssClass="form-control" Width="200px" Height="32px" placeholder="Enter Receipt No" OnTextChanged="txt_recipt_TextChanged" onkeypress="return digit(event);" runat="server" AutoPostBack="true" required Autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Recipt No
                                                    </div>
                                                    </br>
                                <asp:Label ID="Label14" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label2" runat="server" Text="Date:"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_date" CssClass="form-control" required Width="200px" Height="32px" TextMode="Date" runat="server"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>

                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label4" runat="server" Text="Ledger:"></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width:200px;"/>
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("led_description") %>'
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
                                                    <asp:Label ID="Label8" runat="server" Text="Payment Method"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:DropDownList ID="ddl_method" Width="200px" Height="32px" runat="server" parsely-trigger="change" OnSelectedIndexChanged="ddl_method_SelectedIndexChanged" AutoPostBack="true" required>
                                                        <asp:ListItem Value="select">Select</asp:ListItem>
                                                        <asp:ListItem>Cash</asp:ListItem>
                                                        <asp:ListItem>UPI Payment</asp:ListItem>
                                                        <asp:ListItem>Cheque No</asp:ListItem>
                                                    </asp:DropDownList>

                                                    <asp:CompareValidator ControlToValidate="ddl_method" ID="CompareValidator3" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please Select Payment Method" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                                </div>

                                            </div>
                                        </div>
                                        <asp:Panel ID="panel2" runat="server">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="lbl_chqno" runat="server" Text="Cheque/Draft No"></asp:Label>
                                                        <asp:Label ID="lbl_chqno_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_chqno" CssClass="form-control" runat="server" Width="200px" Height="32px" MaxLength="50" placeholder="Cheque/Draft No." required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Cheque/Draft No
                                                        </div>
                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="lbl_chqdate" runat="server" Text="Cheque Date"></asp:Label>
                                                        <asp:Label ID="lbl_chqdate_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:TextBox ID="txt_chqdate" runat="server" Width="200px" Height="32px" TextMode="Date" required></asp:TextBox>

                                                    </div>

                                                </div>
                                            </div>
                                        </asp:Panel>
                                        <asp:Panel ID="panel3" runat="server">
                                            <div class="form-group">
                                                <div class="row ">


                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label12" runat="server" Text="Enter UPI:"></asp:Label>
                                                        <asp:Label ID="Label13" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_upi" CssClass="form-control" required Width="200px" Height="32px" runat="server"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter UPI
                                                        </div>
                                                    </div>

                                                    <asp:Button ID="Button2" runat="server" Height="30px" CssClass="btn btn-primary" Text="Verify & Proceed" />
                                                </div>

                                            </div>


                                        </asp:Panel>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label9" runat="server" Text=" Ledger Details"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_details" CssClass="form-control" placeholder="Enter Ledger Details" Width="200px" Height="32px" runat="server" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Ledger Details
                                                    </div>
                                                </div>


                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label1" runat="server" Text=" Amount:"></asp:Label>
                                                    <asp:Label ID="Label15" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_amt" CssClass="form-control" placeholder="Enter The Amount" Width="200px" Height="32px" onkeypress="return digit(event);" runat="server" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Amount
                                                    </div>
                                                </div>


                                            </div>
                                        </div>

                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>



                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" runat="server" OnClientClick="disableSaveButtonIfValid();" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                                            <asp:Button ID="btn_delete" class="btn btn-primary" Visible="false" runat="server" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_print" runat="server" Text="Print" class="btn btn-primary" OnClick="btn_print_Click" />
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



    <script>
        document.addEventListener('click', function (e) {

            var container = document.querySelector('#<%= TextBox1.ClientID %>').closest('.dropdown-container');
        var dropdown = document.getElementById('RepeaterContainer1');

        if (!container || !dropdown) return;

        // Close dropdown if click is outside
        if (!container.contains(e.target)) {
            dropdown.style.display = 'none';
        }
    });

        // Show dropdown when textbox is focused or typed
        document.getElementById('<%= TextBox1.ClientID %>').addEventListener('focus', function () {
        var dropdown = document.getElementById('RepeaterContainer1');
        if (dropdown) dropdown.style.display = 'block';
    });

    function setTextBox1(value) {
        document.getElementById('<%= TextBox1.ClientID %>').value = value;
            document.getElementById('RepeaterContainer1').style.display = 'none';
            return false; // stop postback flicker
        }
    </script>

</asp:Content>
