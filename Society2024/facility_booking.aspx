<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="facility_booking.aspx.cs" Inherits="Society.facility_booking" MasterPageFile="~/Site.Master" %>


<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 800px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 292px;
                margin-top: 168px;
                right: 1px;
            }
        }

        /* Sticky header styles */
        .sticky-header {
            position: sticky !important;
            top: 0 !important;
            z-index: 1000 !important;
            background-color: lightblue !important;
        }

        /* Target GridView table directly */
        #GridView1 {
            border-collapse: separate !important;
            border-spacing: 0 !important;
        }

            /* Target header row */
            #GridView1 > thead > tr > th {
                position: sticky !important;
                top: 0 !important;
                z-index: 1000 !important;
                background-color: lightblue !important;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
            }

        /* Alternative - target by class */
        .table-bordered thead th {
            position: sticky !important;
            top: 0 !important;
            z-index: 1000 !important;
            background-color: lightblue !important;
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
                    window.location.href = 'facility_booking.aspx';
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

    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Facility Bookings
                            </h1>
                        </th>
                    </tr>
                </table>

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="facility_book_id" runat="server" />
                        <asp:HiddenField ID="owner_id" runat="server" />
                        <asp:HiddenField ID="slot_id" runat="server" />




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
                                                OnTextChanged="btn_search_Click"
                                                onkeyup="removeFocusAfterTyping()" />

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
                                                    type="submit"
                                                    class="search-button2"
                                                    runat="server"
                                                    onserverclick="btn_search_Click">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>

                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-success" onclick="exportToExcel()">📊 Export to Excel</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-danger" onclick="exportToPDF()">📄 Download PDF</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" OnRowUpdating="GridView1_RowUpdating"
                                            CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue"
                                            ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">

                                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="parking_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="facility_book_id" runat="server" Text='<%# Bind("facility_book_id")%>'></asp:Label>

                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Name" Visible="true" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblName" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Building" Visible="true" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblBuilding" runat="server" Text='<%# Bind("build_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Unit" Visible="true" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblUnit" runat="server" Text='<%# Bind("Unit")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Phone" Visible="true" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblPhone" runat="server" Text='<%# Bind("pre_mob")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Facility" Visible="true" SortExpression="facility_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr" runat="server" Text='<%# Bind("facility_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Date" Visible="true">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr23" runat="server" Text='<%#!string.IsNullOrEmpty(Eval("to_date").ToString()) ? Eval("from_date", "{0:yyyy-MM-dd}") + " to  " + Eval("to_date", "{0:yyyy-MM-dd}"):Eval("from_date","{0:yyyy-MM-dd}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Time" Visible="true">
                                                    <ItemTemplate>
                                                        <asp:Label ID="addr1" runat="server"
                                                            Text='<%# (Eval("from_time") == null || Eval("from_time").ToString() == "12:00AM" 
            && Eval("to_time") == null || Eval("to_time").ToString() == "12:00AM")
            ? "N/A" 
            : Eval("from_time") + " - " + Eval("to_time") %>'>
                                                        </asp:Label>

                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Charges" ItemStyle-Width="150" Visible="true">
                                                    <ItemTemplate>
                                                        <asp:Label ID="charges" runat="server" Text='<%# Bind("amount")%>'></asp:Label>

                                                    </ItemTemplate>
                                                    <FooterTemplate>
                                                        <asp:Label ID="lblTotal" runat="server" Font-Bold="true" Text=""></asp:Label>
                                                    </FooterTemplate>
                                                </asp:TemplateField>
                                                <%-- <asp:TemplateField>
                                            <ItemTemplate>
                                                <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("parking_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>--%>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');">
                                                            <img src="Images/delete_10781634.png" height="25" width="25" />
                                                        </asp:LinkButton>
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
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Facility Booking</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="facility_id" runat="server" />
                                        <asp:HiddenField ID="name_id" runat="server" />
                                        <asp:HiddenField ID="flat_id" runat="server" />
                                        <asp:HiddenField ID="hidden_total_amount" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label7" runat="server" Text="Facilities"></asp:Label>
                                                    <asp:Label ID="Label28" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label29" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*" required></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("facility_id") %>'
                                                                        CommandName='<%# Eval("slot") %>'
                                                                        OnClientClick="setTextBox1(this.innerText);" />
                                                                </itemtemplate>
                                                                <footertemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>

                                                </div>


                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label33" runat="server" Text="Date :"></asp:Label>

                                                    <asp:Label ID="Label34" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_date" CssClass="form-control" runat="server" TextMode="Date" OnTextChanged="txt_date_TextChanged" Height="32px" Width="200px" AutoPostBack="true" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>

                                                </div>


                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-12">
                                                    <div style="width: 100%; overflow: auto;">
                                                        <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" OnRowDataBound="GridView2_RowDataBound" HeaderStyle-BackColor="lightblue">
                                                            <Columns>
                                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Reason" SortExpression="reason" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="status" runat="server" Text='<%# Bind("status")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="parking_id" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="slot_id" runat="server" Text='<%# Bind("slot_id")%>'></asp:Label>

                                                                    </ItemTemplate>
                                                                </asp:TemplateField>

                                                                <asp:TemplateField HeaderText="From Time" SortExpression="from_time">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="start_time" runat="server" Text='<%# Eval("start_time", "{0:hh:mm tt}") %>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="To Time" SortExpression="to_time">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="end_time" runat="server" Text='<%# Bind("end_time","{0:hh:mm tt}")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>



                                                                <asp:TemplateField Visible="true" SortExpression="reason">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="reason" runat="server"></asp:Label>
                                                                        <asp:CheckBox ID="chk" runat="server" AutoPostBack="true" OnCheckedChanged="chk_CheckedChanged" />
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>

                                                            </Columns>
                                                        </asp:GridView>
                                                    </div>
                                                </div>

                                            </div>
                                        </div>



                                        <asp:Panel ID="Panel2" runat="server" Visible="false">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label10" runat="server" Text="Name"></asp:Label>
                                                        <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <div class="dropdown-container">
                                                            <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                                placeholder="Select" autocomplete="off" required="required" />
                                                            <div id="RepeaterContainer2" class="suggestion-list">
                                                                <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                    <ItemTemplate>
                                                                        <asp:LinkButton
                                                                            ID="lnkCategory"
                                                                            runat="server"
                                                                            CssClass="suggestion-item link-button category-link"
                                                                            Text='<%# Eval("name") %>'
                                                                            CommandArgument='<%# Eval("owner_id") %>'
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
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label13" runat="server" Text="Flat no"></asp:Label>
                                                        <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_flat" CssClass="form-control" runat="server" Style="text-transform: capitalize;" Height="32px" Width="200px" AutoPostBack="true" placeholder="Enter Flat No" required autofocus></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Flat No
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>
                                        <asp:Panel ID="Panel1" Visible="false" runat="server">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label2" runat="server" Text="Name"></asp:Label>
                                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_name" runat="server" Height="32px" Width="200px" Style="text-transform: capitalize;" placeholder="Enter Name" required autofocus></asp:TextBox>

                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label1" runat="server" Text="Address"></asp:Label>
                                                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_add" CssClass="form-control" runat="server" Style="text-transform: capitalize;" Height="32px" Width="200px" placeholder="Enter Address" required autofocus></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Address
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label25" runat="server" Text="Contact No:"></asp:Label>
                                                        <asp:Label ID="Label26" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label27" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_contact" CssClass="form-control" runat="server" MaxLength="10" Height="32px" Width="200px" placeholder="Enter Mobile no" required autofocus></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Contact No
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>
                                        <asp:Panel ID="Panel3" runat="server" Visible="false">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="lbl_co_name" runat="server" TextMode="Date" Text="From Date :"></asp:Label>

                                                        <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_from_date" runat="server" TextMode="Date" Height="32px" Width="200px" placeholder="Enter Date" required autofocus></asp:TextBox>

                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label6" runat="server" TextMode="Date" Text="To Date:"></asp:Label>
                                                        <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">

                                                        <asp:TextBox ID="txt_to_date" runat="server" Height="32px" Width="200px" TextMode="Date" placeholder="Enter Date" OnTextChanged="txt_to_date_TextChanged" AutoPostBack="true" autofocus required></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>

                                        </asp:Panel>
                                        <asp:Panel ID="Panel4" runat="server" Visible=" 
                                            false">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label16" runat="server" TextMode="Date" Text="From Time"></asp:Label>
                                                        <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">

                                                        <asp:TextBox ID="from_time" runat="server" Height="32px" Width="200px" TextMode="Time" required></asp:TextBox>
                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label19" runat="server" TextMode="Date" Text="To Time"></asp:Label>
                                                        <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label21" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="to_time" runat="server" TextMode="Time" OnTextChanged="to_time_TextChanged" AutoPostBack="true" Height="32px" Width="200px" required autofocus></asp:TextBox>

                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>

                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label22" runat="server" Text="Charges"></asp:Label>
                                                    <asp:Label ID="Label23" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label24" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_amount" CssClass="form-control" runat="server" Height="50px" Width="200px" Enabled="false" TextMode="MultiLine" Rows="10"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Charges
                                                    </div>

                                                </div>

                                                <div class="col-sm-2">
                                                    <asp:Label ID="Label30" runat="server" Text="Note to Admin"></asp:Label>
                                                    <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-4">
                                                    <asp:TextBox ID="txt_note" CssClass="not-required" runat="server" Height="50px" Width="200px" placeholder="Enter Note" TextMode="MultiLine"></asp:TextBox>

                                                </div>
                                            </div>
                                        </div>

                                      <%--  <div class="col-sm-2">
                                            <asp:CheckBox ID="society_in" Text="In Society" runat="server" Checked="true" AutoPostBack="true" OnCheckedChanged="society_in_CheckedChanged" />

                                        </div>--%>
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
                                            <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" type="button-submit" runat="server" Text="Save" OnClick="btn_save_Click" ValidationGroup="g1" class="btn btn-primary" />
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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>

    <script>

        function addTotalRowsToGrid() {
            var gridView = document.getElementById('<%= GridView1.ClientID %>');
            if (!gridView) return;

            // Remove existing rows
            var existing = gridView.querySelectorAll('.empty-row, .total-row');
            existing.forEach(function (row) { row.remove(); });

            // Find all spans with id containing "charges"
            var chargeLabels = gridView.querySelectorAll('span[id*="charges"]');
            var total = 0;

            chargeLabels.forEach(function (label) {
                var text = label.textContent.trim();
                var amount = parseFloat(text.replace(/[^0-9.-]/g, ''));
                //console.log('Charge text:', text, 'Parsed amount:', amount);
                if (!isNaN(amount)) {
                    total += amount;
                }
            });

            // Store total globally for export functions
            window.gridTotalCharges = total;

            // Get column count from first data row
            var firstDataRow = gridView.querySelector('tr:nth-child(2)');
            var columnCount = firstDataRow ? firstDataRow.querySelectorAll('td').length : 10;

            var tbody = gridView.querySelector('tbody') || gridView;

            // Empty row (second last)
            var emptyRow = document.createElement('tr');
            emptyRow.className = 'empty-row';
            emptyRow.style.height = '30px';
            emptyRow.style.backgroundColor = '#ffffff';

            var emptyCell = document.createElement('td');
            emptyCell.colSpan = columnCount;
            emptyCell.style.border = 'none';
            emptyCell.style.padding = '0';
            emptyCell.innerHTML = '&nbsp;';

            emptyRow.appendChild(emptyCell);
            tbody.appendChild(emptyRow);

            // Total row (last) - Single merged cell with no column lines
            var totalRow = document.createElement('tr');
            totalRow.className = 'total-row';

            // Style the total row
            totalRow.style.fontWeight = 'bold';
            totalRow.style.backgroundColor = '#e8f4f8';
            totalRow.style.borderTop = '2px solid #4a90e2';
            totalRow.style.borderBottom = '2px solid #4a90e2';

            // Create single merged cell spanning all columns
            var totalCell = document.createElement('td');
            totalCell.colSpan = columnCount;

            totalCell.style.border = 'none';
            totalCell.style.borderTop = '2px solid #dee2e6';
            totalCell.style.padding = '15px 20px';
            totalCell.style.textAlign = 'right';
            totalCell.style.fontSize = '15px';
            totalCell.style.backgroundColor = '#f8f9fa';
            totalCell.style.color = '#495057';

            totalCell.innerHTML = '<span style="margin-right: 20px;">Total Charges:</span>' +
                '<span style="font-weight: bold; font-size: 17px;">' +
                total.toFixed(2) + '</span>';

            totalRow.appendChild(totalCell);
            tbody.appendChild(totalRow);
        }

        // Call on page load
        window.addEventListener('load', function () {
            setTimeout(function () {
                addTotalRowsToGrid();
            }, 500);
        });

        // For UpdatePanel scenarios
        if (typeof Sys !== 'undefined') {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                setTimeout(function () {
                    addTotalRowsToGrid();
                }, 500);
            });
        }

        //-------------------------------------------------------------------------------------------------------------------------------------
        function exportToPDF() {
            const table = document.getElementById("<%= GridView1.ClientID %>");

            if (!table) {
                alert('No data found to export');
                return;
            }

            // Show loading
            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.innerHTML = '⏳ Generating PDF...';
            btn.disabled = true;

            try {
                // Extract headers
                const headers = [];
                const headerCells = table.querySelectorAll('thead tr th, tr:first-child th');
                headerCells.forEach((cell, index) => {
                    // Skip columns with images
                    if (!cell.querySelector('img') && cell.innerText.trim() !== '') {
                        headers.push(cell.innerText.trim());
                    }
                });

                // Extract data
                const data = [];
                const rows = table.querySelectorAll('tbody tr, tr');

                rows.forEach((row, rowIndex) => {
                    if (rowIndex === 0 && row.querySelector('th')) return; // Skip header row

                    // Skip empty rows
                    if (row.classList.contains('empty-row')) return;

                    const rowData = [];
                    const cells = row.querySelectorAll('td');

                    // Check if this is the total row
                    if (row.classList.contains('total-row')) {
                        // Add empty cells for all columns except the last one
                        for (let i = 0; i < headers.length - 1; i++) {
                            rowData.push('');
                        }
                        // Add the total value
                        const totalText = cells[0].innerText.trim();
                        rowData.push(totalText);
                    } else {
                        cells.forEach((cell) => {
                            // Skip columns with images/buttons
                            if (!cell.querySelector('img') && !cell.querySelector('a[id*="edit"]')) {
                                const label = cell.querySelector('span');
                                const text = label ? label.innerText : cell.innerText;
                                rowData.push(text.trim());
                            }
                        });
                    }

                    if (rowData.length > 0) {
                        data.push(rowData);
                    }
                });

                // Create PDF
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('l', 'mm', 'a4'); // landscape for wide tables

                // Add title
                pdf.setFontSize(16);
                pdf.text('Facility Bookings Report', 14, 15);

                // Add date
                pdf.setFontSize(10);
                pdf.text('Generated: ' + new Date().toLocaleString(), 14, 22);

                // Add table
                pdf.autoTable({
                    head: [headers],
                    body: data,
                    startY: 28,
                    theme: 'grid',
                    styles: {
                        fontSize: 9,
                        cellPadding: 3,
                    },
                    headStyles: {
                        fillColor: [173, 216, 230], // lightblue
                        textColor: [0, 0, 0],
                        fontStyle: 'bold',
                        halign: 'center'
                    },
                    alternateRowStyles: {
                        fillColor: [245, 245, 245]
                    },
                    // Style the last row (total row) differently
                    didParseCell: function (data) {
                        if (data.row.index === data.table.body.length - 1) {
                            data.cell.styles.fontStyle = 'bold';
                            data.cell.styles.fillColor = [248, 249, 250];
                            data.cell.styles.textColor = [73, 80, 87];
                        }
                    },
                    margin: { top: 28, left: 14, right: 14 }
                });

                // Download
                pdf.save('FacilityBookings_' + new Date().toISOString().slice(0, 10) + '.pdf');

            } catch (error) {
                console.error('Error generating PDF:', error);
                alert('Error generating PDF. Please try again.');
            } finally {
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        }


        //-------------------------------------------------------------------------------------------------------------------------------------
        function exportToExcel() {
            const table = document.getElementById("<%= GridView1.ClientID %>");

            if (!table) {
                alert('No data found to export');
                return;
            }

            // Extract data
            const data = [];
            const rows = table.querySelectorAll('tr');

            rows.forEach((row, rowIndex) => {
                // Skip empty rows
                if (row.classList.contains('empty-row')) return;

                const rowData = [];
                const cells = row.querySelectorAll(rowIndex === 0 ? 'th' : 'td');

                // Check if this is the total row
                if (row.classList.contains('total-row')) {
                    const totalCell = cells[0];
                    if (totalCell) {
                        // Get the number of columns from the header row
                        const headerRow = table.querySelector('tr:first-child');
                        const headerCells = headerRow.querySelectorAll('th');
                        let columnCount = 0;

                        headerCells.forEach((cell) => {
                            if (!cell.querySelector('img')) {
                                columnCount++;
                            }
                        });

                        // Add empty cells for all columns except the last one
                        for (let i = 0; i < columnCount - 1; i++) {
                            rowData.push('');
                        }
                        // Add the total value
                        const totalText = totalCell.innerText.trim();
                        rowData.push(totalText);
                    }
                } else {
                    cells.forEach((cell) => {
                        // Skip image/button columns
                        if (!cell.querySelector('img')) {
                            const label = cell.querySelector('span');
                            const text = label ? label.innerText : cell.innerText;
                            rowData.push(text.trim());
                        }
                    });
                }

                if (rowData.length > 0) {
                    data.push(rowData);
                }
            });

            // Create workbook
            const wb = XLSX.utils.book_new();
            const ws = XLSX.utils.aoa_to_sheet(data);

            // Set column widths
            const colWidths = data[0].map(() => ({ wch: 15 }));
            ws['!cols'] = colWidths;

            // Style the last row (total row) - make it bold
            const lastRowIndex = data.length - 1;
            const lastColIndex = data[0].length - 1;

            if (ws[`A${lastRowIndex + 1}`]) {
                for (let col = 0; col <= lastColIndex; col++) {
                    const cellRef = XLSX.utils.encode_cell({ r: lastRowIndex, c: col });
                    if (ws[cellRef]) {
                        ws[cellRef].s = {
                            font: { bold: true },
                            fill: { fgColor: { rgb: "F8F9FA" } }
                        };
                    }
                }
            }

            // Add worksheet to workbook
            XLSX.utils.book_append_sheet(wb, ws, 'Facility Bookings');

            // Download
            XLSX.writeFile(wb, 'FacilityBookings_' + new Date().toISOString().slice(0, 10) + '.xlsx');
        }



        function closeAllDropdowns() {
            document.getElementById("RepeaterContainer1").style.display = "none";
            document.getElementById("RepeaterContainer2").style.display = "none";           
        }


      <%--  function initdropdownevents() {

            const textbox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeatercontainer1 = document.getElementById("RepeaterContainer1");

            const textbox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const repeatercontainer2 = document.getElementById("RepeaterContainer2");

            if (textbox1 && repeatercontainer1) {

                // 🔑 OPEN ON CLICK
                textbox1.addEventListener("mousedown", function (e) {
                    // e.stopPropagation();
                    closeAllDropdowns();
                    repeatercontainer1.style.display = "block";
                });

                // FILTER ON TYPING
                textbox1.addEventListener("input", function () {
                    const input = textbox1.value.toLowerCase();
                    filterSuggestions("category-link", input);
                    repeatercontainer1.style.display = "block";
                });
            }

            if (textbox2 && repeatercontainer2) {

                textbox2.addEventListener("mousedown", function (e) {
                    // e.stopPropagation();
                    closeAllDropdowns();
                    repeatercontainer2.style.display = "block";
                });

                textbox2.addEventListener("input", function () {
                    const input = textbox2.value.toLowerCase();
                    filterSuggestions("category-link", input);
                    repeatercontainer2.style.display = "block";
                });
            }

            // CLOSE WHEN CLICKING OUTSIDE
            document.addEventListener("mousedown", function () {
                if (repeatercontainer1) repeatercontainer1.style.display = "none";
                if (repeatercontainer2) repeatercontainer2.style.display = "none";
            });
        }--%>


        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
             const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
             

             const repeaterContainer1 = document.getElementById("RepeaterContainer1");
             const repeaterContainer2 = document.getElementById("RepeaterContainer2");
             

             //textBox1
             textBox1.addEventListener("focus", function () {
                 repeaterContainer1.style.display = "block";
                 repeaterContainer2.style.display = "none";
                 
             });

             textBox1.addEventListener("input", function () {
                 const input = textBox1.value.toLowerCase();
                 filterSuggestions("category-link", input);
             });

             //textBox2
             textBox2.addEventListener("focus", function () {
                 repeaterContainer2.style.display = "block";
                 repeaterContainer1.style.display = "none";
               
             });

             textBox2.addEventListener("input", function () {
                 const input = textBox2.value.toLowerCase();
                 filterSuggestions("category-link", input);
             });

             

             // Close dropdown when clicking anywhere else
             document.addEventListener("click", function (e) {
                 if (!e.target.closest(".dropdown-container")) {
                     closeAllDropdowns();
                 }
             });

         }

        Sys.Application.add_load(initDropdownEvents);
        // Call after page load
       // document.addEventListener("DOMContentLoaded", initdropdownevents);

        
 


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
            console.log(value);
            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            closeAllDropdowns();

        }

        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;

            closeAllDropdowns();

        }

        
    </script>

</asp:Content>
