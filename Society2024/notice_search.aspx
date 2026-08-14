<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="notice_search.aspx.cs" Inherits="Society.notice_search" MasterPageFile="~/Site.Master" Async="true" %>


<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Notices
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
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
                                        <asp:GridView ID="GridView1" runat="server" AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="notice_id" ItemStyle-Width="300" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="notice_id" runat="server" Text='<%# Bind("notice_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Subject" ItemStyle-Width="300" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Valid Till" ItemStyle-Width="300" SortExpression="date">
                                                    <ItemTemplate>
                                                        <asp:Label ID="date" runat="server" Text='<%# Bind("valid_to","{0:yyyy-MM-dd}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField ItemStyle-Width="50" HeaderText="Edit">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("notice_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="50" HeaderText="Delete" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
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
                </asp:UpdatePanel>

                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-6">
                        <div class="modal-content" style="height: auto; width: 400px;">
                            <div class="modal-header">

                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Notice</strong></h4>
                            </div>

                            <div class="modal-body" id="invoice_data">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <asp:HiddenField ID="notice_id" runat="server" />
                                        <asp:HiddenField ID="Recipient_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label1" runat="server" Text="Subject"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_sub" CssClass="form-control" runat="server" Style="text-transform: capitalize;" Height="32px" Width="200px" placeholder="Enter Subject" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Subject Name
                                                    </div>
                                                </div>

                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Recipients"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="categoryBox" runat="server" Style="width: 200px;" CssClass="form-control"
                                                            placeholder="Select Recipients" autocomplete="off" required="required" />
                                                        <div id="categoryRepeaterContainer" class="suggestion-list">
                                                            <asp:Repeater ID="categoryRepeater" runat="server" OnItemDataBound="categoryRepeater_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("recipients") %>'
                                                                        CommandArgument='<%# Eval("recipients_id") %>'
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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label7" runat="server" Text=" Valid Date"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_valid_to" CssClass="form-control" runat="server" Height="32px" Width="200px" required TextMode="Date"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>

                                                    <%--<asp:CalendarExtender ID="CalendarExtender1" runat="server" Enabled="True" TargetControlID="txt_valid_to" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label4" runat="server" Text="Description"></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_desc" CssClass="form-control" runat="server" TextMode="MultiLine" Rows="6" Height="90px" Width="200px" placeholder="Enter Description" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Description
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
                                            <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click1" />
                                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#emailmodal">Email</button>
                                            <%-- <asp:Button ID="btn_email" runat="server" Text="Email" class="btn btn-primary" OnClick="btn_email_Click" />--%>
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" data-dismiss="#edit_model" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                        </center>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal fade bs-example-modal-sm" id="emailmodal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content" style="height: auto; width: 300px;">
                            <div class="modal-header">
                                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                <h4 class="modal-title" id="gridSystemModalLabel1"><strong>Select Customer</strong></h4>
                            </div>

                            <div class="modal-body">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <label>
                                                        Select all</label>
                                                    <asp:CheckBox ID="CheckAll" runat="server" AutoPostBack="true" OnCheckedChanged="CheckAll_CheckedChanged"></asp:CheckBox>
                                                </div>
                                            </div>
                                        </div>


                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <asp:Panel ID="Panel21" runat="server" ScrollBars="Auto" Height="400px">

                                                        <asp:CheckBoxList ID="CheckBoxList1" runat="server" Font-Bold="true" OnSelectedIndexChanged="CheckBoxList1_SelectedIndexChanged"></asp:CheckBoxList>


                                                    </asp:Panel>
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
                                <div class="row">
                                    <div class="col-sm-6">
                                        <div class="pull-left">
                                            <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                        </div>
                                    </div>
                                    <div class="col-sm-6">
                                        <div class="pull-right">
                                            <asp:Button ID="btn_email_send" runat="server" Text="Email" class="btn btn-primary" />
                                        </div>
                                    </div>
                                </div>



                            </div>
                        </div>
                        <!-- /.modal-body 
                    </div>
                    <!-- /.modal-content -->
                    </div>
                    <!-- /.modal-dialog -->


                </div>
            </div>
        </div>
    </div>
<%--        <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Core plugin JavaScript-->
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>--%>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>




    <script>
        document.addEventListener('click', function (event) {
            var container = document.querySelector('.dropdown-container');
            var suggestionList = document.getElementById('categoryRepeaterContainer');

            if (!container || !suggestionList) return;

            // If click is outside dropdown-container
            if (!container.contains(event.target)) {
                suggestionList.style.display = 'none';
            }
        });

        // Optional: show dropdown when typing
        document.getElementById('<%= categoryBox.ClientID %>').addEventListener('focus', function () {
        var list = document.getElementById('categoryRepeaterContainer');
        if (list) list.style.display = 'block';
    });

    function setCategoryBox(value) {
        document.getElementById('<%= categoryBox.ClientID %>').value = value;
            document.getElementById('categoryRepeaterContainer').style.display = 'none';
        }
    </script>







<script type="text/javascript">

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
                Swal.showLoading();
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
            timer: 3000,
            timerProgressBar: true,
            didOpen: () => {
                Swal.showLoading();
            },
            willClose: () => {
                window.location.href = 'notice_search.aspx';
            }
        });
    }

    function openModal() {
        $('#edit_model').modal('show');
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

    function initDropdownEvents() {
        const categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
        const categorySuggestions = document.getElementById("categoryRepeaterContainer");

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

    function setCategoryBox(value) {
        document.getElementById("<%= categoryBox.ClientID %>").value = value;
        document.getElementById("categoryRepeaterContainer").style.display = "none";
    }

    Sys.Application.add_load(initDropdownEvents);
</script>


</asp:Content>
