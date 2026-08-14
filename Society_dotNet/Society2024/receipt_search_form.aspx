<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="receipt_search_form.aspx.cs" Inherits="Society.receipt_search_form" MasterPageFile="~/Site.Master" %>

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
        @media(max-width: 630px){
    .top-row{
        flex-direction:column;
    }

    .w-90{
        width:90%;
    }
}

        .modal-content {
            transition: all 0.3s ease-in-out;
        }

        .modal-body p {
            margin-bottom: 6px;
        }

        @media (max-width: 575.98px) {
            .modal-dialog {
                margin: 1rem;
            }

            .modal-content {
                padding: 1rem !important;
            }

            .modal-footer {
                flex-direction: column;
            }

                .modal-footer button {
                    width: 100%;
                    margin-bottom: 10px;
                }
        }

        .view-button {
            display: inline-block;
            padding: 1px 4px;
            background-color: #007bff; /* Bootstrap blue */
            color: white !important;
            border: 2px solid #0056b3;
            border-radius: 5px;
            text-decoration: none;
            font-weight: bold;
            transition: all 0.3s ease;
        }

            .view-button:hover {
                background-color: #0056b3;
                border-color: #003d80;
                color: #fff !important;
                cursor: pointer;
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
                    window.location.href = 'receipt_search_form.aspx';
                }
            });
        }
    </script>
    <script type='text/javascript'>
        function openModal() {
            $('#edit_model').modal('show');
        }
    </script>


    <div class="box box-primary">
        <div class="box-header with-border">

            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Receipts🧾</h1>
                        </th>
                    </tr>
                </table>
                <br />
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <%--                <h4 style="color: Navy">Purchase Entry</h4>--%>



                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="top-row d-flex align-items-center">
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
                                                Format="dd MMM yyyy" />

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
                                        <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>

                                        &nbsp;&nbsp;
          <button class="w-90 btn btn-primary" onclick="printreceiptsearch()">Print</button>
                                        &nbsp;&nbsp;
                                        <button class="w-90 btn btn-success" onclick="downloadReceipt()">Download PDF</button>


                                    </div>
                                </div>
                            </div>
                        </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">


                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView ID="GridView1" runat="server" AllowPaging="true" PageSize="15" OnPageIndexChanging="GridView1_PageIndexChanging" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating">


                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Receipt" SortExpression="receipt_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="receipt_no" runat="server" Text='<%# Bind("receipt_no")%>'></asp:Label>

                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Building Name" SortExpression="build_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="b_id" runat="server" Text='<%# Bind("build_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Name" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Wing" SortExpression="w_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name1" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Received Amount" SortExpression="received_amt">
                                                    <ItemTemplate>
                                                        <asp:Label ID="received_amt" runat="server" Text='<%# Bind("received_amt")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Payment Mode" SortExpression="pay_mode_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="pay_mode_name" runat="server" Text='<%# Bind("pay_mode_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Date" SortExpression="date">
                                                    <ItemTemplate>
                                                        <asp:Label ID="date" runat="server" Text='<%# Bind("date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Print" ItemStyle-Width="50">
                                                    <HeaderStyle HorizontalAlign="Center" Font-Bold="True" />
                                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                                    <ItemTemplate>
                                                        <asp:LinkButton ID="btnView" runat="server"
                                                            CommandArgument='<%# Bind("receipt_id") %>'
                                                            OnCommand="btnView_Command"
                                                            CssClass="view-button">
            View
                                                        </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("receipt_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <%--<asp:LinkButton  ButtonType="Button" data-toggle="modal" data-target=".bs-example-modal-sm" SelectText="Edit" ControlStyle-ForeColor="blue" />--%>
                                            </Columns>
                                        </asp:GridView>
                                    </div>


                                </div>
                            </div>
                        </div>

                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>


                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">

                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Receipt</strong></h4>
                                <asp:Label ID="receipt_no" runat="server" Font-Bold="True" Font-Size="Medium"></asp:Label>
                            </div>


                            <div class="modal-body" id="invoice_data">

                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="receipt_id" runat="server" />
                                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="build_id" runat="server" />
                                        <asp:HiddenField ID="n_m_id" runat="server" />

                                        <asp:HiddenField ID="shop_maint_id" runat="server" />
                                        <asp:HiddenField ID="wing_id" runat="server" />
                                        <asp:HiddenField ID="owner_id" runat="server" />
                                        <asp:HiddenField ID="building_id" runat="server" />
                                        <asp:HiddenField ID="wing_name_id" runat="server" />
                                        <asp:HiddenField ID="owner_name_id" runat="server" />
                                        <asp:HiddenField ID="pay_mode_id" runat="server" />

                                        <asp:HiddenField ID="society_name" runat="server" />

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label13" runat="server" Text="Building  Name"></asp:Label>
                                                    <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer1" class="suggestion-list" style="width: 100%;">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
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
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_date" runat="server" Text="Date :"></asp:Label>
                                                    <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_date" CssClass="form-control" runat="server" Height="32px" Width="150px" TextMode="Date" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>


                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label16" runat="server" Text="Wing Name"></asp:Label>
                                                    <asp:Label ID="Label1" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer2" class="suggestion-list" style="width: 100%;">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
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
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_cust_name" runat="server" Text="Owner Name"></asp:Label>
                                                    <asp:Label ID="lbl_cust_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer3" class="suggestion-list" style="width: 100%;">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand3">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("owner_id") %>'
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
                                            <div class="row ">
                                                <div class="col-sm-6 d-flex" style="align-items: center; justify-content: space-evenly;">
                                                    <asp:CheckBox Checked="true" ID="CheckBox1" runat="server" Text="Regular" AutoPostBack="true" OnCheckedChanged="CheckBoxes_CheckedChanged" />

                                                    <asp:CheckBox ID="CheckBox2" runat="server" Text="Add on" AutoPostBack="true" OnCheckedChanged="CheckBoxes_CheckedChanged" />

                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">


                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label6" runat="server" Text="Receivable Amount"></asp:Label>
                                                    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_amount" runat="server" Height="32px" Width="150px" placeholder="Enter Amount" Enabled="false"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_pay_status" runat="server" Text="Pay Mode"></asp:Label>
                                                    <asp:Label ID="lbl_pay_status_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox4" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="RepeaterContainer4" class="suggestion-list" style="width: 100%;">
                                                            <asp:Repeater ID="Repeater4" runat="server" OnItemDataBound="Repeater4_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand4">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("pay_mode") %>'
                                                                        CommandArgument='<%# Eval("pay_id") %>'
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
                                            </div>
                                        </div>


                                        <asp:Panel ID="panel3" runat="server" Visible="false">
                                            <div class="form-group">
                                                <div class="row">
                                                    <!-- Label -->
                                                    <div class="col-sm-2">
                                                        <asp:Label ID="Label21" runat="server" Text="Enter UPI:"></asp:Label>
                                                        <asp:Label ID="Label22" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                    </div>

                                                    <!-- Input -->
                                                    <div class="col-sm-4">
                                                        <asp:TextBox ID="txt_upi" CssClass="form-control" required Width="200px" Height="32px" runat="server"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter UPI
                                                        </div>
                                                    </div>

                                                    <!-- Small Blank Column -->
                                                    <div class="col-sm-1">
                                                        <!-- Blank spacing -->
                                                    </div>

                                                    <!-- Button -->
                                                    <div class="col-sm-2">
                                                        <asp:Button ID="Button2" runat="server" Height="30px" CssClass="btn btn-primary" Text="Verify & Proceed" />
                                                    </div>
                                                </div>
                                        </asp:Panel>

                                        <asp:Panel ID="panel2" runat="server">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_chqno" runat="server" Text="Cheque/Draft No"></asp:Label>
                                                        <asp:Label ID="lbl_chqno_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_chq" runat="server" Height="32px" Width="150px" AutoPostBack="true" OnSelectedIndexChanged="txt_chqno_SelectedIndexChanged" />
                                                        <asp:TextBox ID="txt_chqno" runat="server" Height="32px" Width="150px" placeholder="Cheque No"></asp:TextBox>
                                                    </div>


                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_chqdate" runat="server" Text="Cheque Date"></asp:Label>
                                                        <asp:Label ID="lbl_chqdate_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_chqdate" runat="server" Enabled="false" Height="32px" Width="150px" TextMode="Date"></asp:TextBox>

                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-6"></div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label17" runat="server" Text="Cheque Amount"></asp:Label>
                                                        <asp:Label ID="Label23" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="che_amount" runat="server" Enabled="false" Height="32px" Width="150px" placeholder="Cheque Amount"></asp:TextBox>

                                                    </div>

                                                </div>
                                            </div>
                                        </asp:Panel>

                                        <asp:Panel ID="panel1" runat="server">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label4" runat="server" Text="Received Amount"></asp:Label>
                                                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_received_amt" CssClass="form-control" Height="32px" Width="150px" runat="server" MaxLength="50" placeholder="Received Amount" onkeypress="return digit(event);" required OnTextChanged="txt_received_amt_TextChanged" AutoPostBack="true"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Received Amount
                                                        </div>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label9" runat="server" Text="Balance"></asp:Label>
                                                        <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_pdc_balance" Height="32px" Width="150px" runat="server" Enabled="false"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_remarks" runat="server" Text="Remark"></asp:Label>

                                                    <asp:Label ID="lbl_remarks_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_remarks" runat="server" Style="text-transform: capitalize;" Height="32px" Width="150px" MaxLength="250" placeholder="Enter Remark"></asp:TextBox>
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
                                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClick="btn_delete_Click" OnClientClick="return confirm('Are you sure want to delete?');" CausesValidation="false" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />


                                            <asp:Button ID="btn_email" Visible="false" runat="server" Text="Email" class="btn btn-primary" OnClick="btn_email_Click" CausesValidation="false" />
                                        </center>
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
    </div>

    <!-- Payment Success Modal -->
    <!-- Payment Success Modal -->
    <div class="modal fade" id="paymentSuccessModal" tabindex="-1" role="dialog" aria-labelledby="paymentModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-md">
            <div class="modal-content shadow-lg rounded-4 border-0" style="font-family: 'Segoe UI', sans-serif;">

                <!-- MODAL BODY -->
                <div class="modal-body px-4 py-5">

                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>

                            <!-- ✅ Success Icon & Title -->
                            <div class="text-center mb-4">
                                <div class="rounded-circle d-inline-flex justify-content-center align-items-center shadow-sm"
                                    style="width: 80px; height: 80px; background-color: #e6f4ea;">
                                    <i class="fas fa-check-circle text-success" style="font-size: 48px;"></i>
                                </div>
                                <h3 class="mt-3 fw-bold text-dark">Payment Successful</h3>
                                <p class="text-secondary small">Your receipt has been processed successfully.</p>
                            </div>

                            <!-- ✅ Receipt Info Section -->
                            <div class="bg-light p-3 rounded-3 border border-secondary-subtle mb-3" style="font-size: 15px; line-height: 1.8;">
                                <p><strong>Name:</strong>
                                    <asp:Label ID="lblName" runat="server" /></p>
                                <p>
                                    <strong>Wing:</strong>
                                    <asp:Label ID="lblWing" runat="server" />
                                    | 
                 <strong>Flat No:</strong>
                                    <asp:Label ID="lblFlatNo" runat="server" />
                                </p>
                                <p><strong>Receipt No:</strong>
                                    <asp:Label ID="lblReceiptNo" runat="server" /></p>
                                <p><strong>Date:</strong>
                                    <asp:Label ID="lblDate" runat="server" /></p>
                                <p><strong>Payment Mode:</strong>
                                    <asp:Label ID="lblPayMode" runat="server" /></p>
                                <p><strong>Received Amount:</strong> ₹<asp:Label ID="lblAmount" runat="server" /></p>
                                <p><strong>Location:</strong> Gokuldham, T-1, Trump Tower-Adeli, Kutwalwadi</p>
                            </div>

                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                        </Triggers>
                    </asp:UpdatePanel>

                </div>

                <!-- MODAL FOOTER BUTTONS -->
                <div class="modal-footer justify-content-center border-0 pb-4">
                    <button type="button" class="btn btn-outline-dark px-4 me-2" data-dismiss="modal">
                        <i class="fas fa-times me-1"></i>Close
                    </button>
                    <button type="button" class="btn btn-outline-primary px-4 me-2" onclick="printReceipt()">
                        <i class="fas fa-print me-1"></i>Print
                    </button>
                    <button type="button" class="btn btn-outline-success px-4" onclick="downloadPDF()">
                        <i class="fas fa-file-download me-1"></i>Download
                    </button>
                </div>

            </div>
        </div>
    </div>


    <!-- Hidden Printable Receipt -->
    <div id="receiptPreview" style="display: none; font-family: 'Segoe UI', sans-serif; width: 720px; padding: 30px; border: 1px solid #000;">
        <div style="text-align: center;">
            <h2 style="margin: 0;">RECEIPT</h2>
            <h3 style="margin: 4px 0;">Gokuldham</h3>
            <p style="margin: 0;">T-1, Trump Tower-Adeli, Kutwalwadi</p>
        </div>

        <div style="text-align: right; font-weight: bold; margin-top: 10px;">
            <span id="r_generatedOn">04-08-2025</span>
        </div>

        <hr style="margin: 12px 0;" />

        <table style="width: 100%; font-size: 15px; margin-bottom: 10px;">
            <tr>
                <td><strong>Flat No:</strong> <span id="r_flat"></span></td>
                <td><strong>Wing Name:</strong> <span id="r_wing"></span></td>
                <td><strong>Name Of The Member:</strong> <span id="r_name"></span></td>
            </tr>
        </table>

        <table style="width: 100%; border-collapse: collapse; border: 1px solid black; font-size: 15px;">
            <thead>
                <tr style="background-color: #f2f2f2;">
                    <th style="border: 1px solid black; padding: 4px;">Receipt no</th>
                    <th style="border: 1px solid black; padding: 4px;">Receipt date</th>
                    <th style="border: 1px solid black; padding: 4px;">Payment Mode</th>
                    <th style="border: 1px solid black; padding: 4px;">Cheque No</th>
                    <th style="border: 1px solid black; padding: 4px;">Cheque Date</th>
                    <th style="border: 1px solid black; padding: 4px;">Received amount</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td style="border: 1px solid black; padding: 4px;"><span id="r_receiptNo"></span></td>
                    <td style="border: 1px solid black; padding: 4px;"><span id="r_date"></span></td>
                    <td style="border: 1px solid black; padding: 4px;"><span id="r_payMode"></span></td>
                    <td style="border: 1px solid black; padding: 4px;"></td>
                    <td style="border: 1px solid black; padding: 4px;"></td>
                    <td style="border: 1px solid black; padding: 4px;"><span id="r_amount"></span></td>
                </tr>
                <tr>
                    <td colspan="5" style="border: 1px solid black; text-align: right; padding: 4px;"><strong>Total Amount Received</strong></td>
                    <td style="border: 1px solid black; padding: 4px;"><span id="r_amount_2"></span></td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- receipt PDF Modal -->

    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Changed to modal-lg for better width -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Receipt Details</strong></h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">

                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->
                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">

                        <asp:GridView ID="GridView3" runat="server"
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
                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField HeaderText="Receipt" DataField="receipt_no" SortExpression="receipt_no" />
                                <asp:BoundField HeaderText="Building Name" DataField="build_name" SortExpression="build_name" />
                                <asp:BoundField HeaderText="Name" DataField="name" SortExpression="name" />
                                <asp:BoundField HeaderText="Wing" DataField="w_name" SortExpression="w_name" />
                                <asp:BoundField HeaderText="Received Amount" DataField="received_amt" SortExpression="received_amt" />
                                <asp:BoundField HeaderText="Payment Mode" DataField="pay_mode_name" SortExpression="pay_mode_name" />
                                <asp:BoundField HeaderText="Date" DataField="date" SortExpression="date" DataFormatString="{0:dd-MM-yyyy}" HtmlEncode="false" />
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


    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>




    <script>

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
                const title = "Receipt Details";

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
                pdf.save("receiptReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }
        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");


            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clone modal-body into offscreen div
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
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
                const title = "Receipt Details "

                // ✅ Add Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40); // Y position = 40pt from top

                // ✅ Add Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60; // leave room for heading

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("receiptReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }
        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            textBox1.addEventListener("focus", function () {

                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";

            });

            textBox1.addEventListener("input", function () {

                const input = textBox1.value.toLowerCase();

                filterSuggestions("category-link", input);

            });
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");

            const repeaterContainer2 = document.getElementById("RepeaterContainer2");

            textBox2.addEventListener("focus", function () {

                repeaterContainer2.style.display = "block";
                repeaterContainer3.style.display = "none";

            });

            textBox2.addEventListener("input", function () {

                const input = textBox2.value.toLowerCase();

                filterSuggestions("category-link", input);

            });
            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");

            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

            textBox3.addEventListener("focus", function () {

                repeaterContainer3.style.display = "block";

            });

            textBox3.addEventListener("input", function () {

                const input = textBox3.value.toLowerCase();

                filterSuggestions("category-link", input);

            });
            const textBox4 = document.getElementById("<%= TextBox4.ClientID %>");

            const repeaterContainer4 = document.getElementById("RepeaterContainer4");

            textBox4.addEventListener("focus", function () {

                repeaterContainer4.style.display = "block";

            });

            textBox4.addEventListener("input", function () {

                const input = textBox4.value.toLowerCase();

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
            document.getElementById("<%= TextBox2.ClientID %>").value = "";
            document.getElementById("<%= TextBox3.ClientID %>").value = "";

            document.getElementById("RepeaterContainer1").style.display = "none";

        }
        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            document.getElementById("<%= TextBox3.ClientID %>").value = "";

            document.getElementById("RepeaterContainer2").style.display = "none";

        }
        function setTextBox3(value) {

            document.getElementById("<%= TextBox3.ClientID %>").value = value;

            document.getElementById("RepeaterContainer3").style.display = "none";

        }
        function setTextBox4(value) {

            document.getElementById("<%= TextBox4.ClientID %>").value = value;

            document.getElementById("RepeaterContainer4").style.display = "none";

        }

        function getLabelValue(id) {
            return document.getElementById(id).innerText || document.getElementById(id).textContent;
        }

        function fillReceiptPreview() {
            document.getElementById("r_name").innerText = getLabelValue("<%= lblName.ClientID %>");
            document.getElementById("r_wing").innerText = getLabelValue("<%= lblWing.ClientID %>");
            document.getElementById("r_flat").innerText = getLabelValue("<%= lblFlatNo.ClientID %>");
            document.getElementById("r_receiptNo").innerText = getLabelValue("<%= lblReceiptNo.ClientID %>");
            document.getElementById("r_date").innerText = getLabelValue("<%= lblDate.ClientID %>");
            document.getElementById("r_payMode").innerText = getLabelValue("<%= lblPayMode.ClientID %>");
            document.getElementById("r_amount").innerText = getLabelValue("<%= lblAmount.ClientID %>");
            document.getElementById("r_amount_2").innerText = getLabelValue("<%= lblAmount.ClientID %>");
            document.getElementById("r_generatedOn").innerText = new Date().toLocaleDateString();
        }

        function printReceipt() {
            fillReceiptPreview();
            var content = document.getElementById("receiptPreview").innerHTML;
            var win = window.open('', '', 'width=800,height=900');
            win.document.write('<html><head><title>Receipt</title></head><body>');
            win.document.write(content);
            win.document.write('</body></html>');
            win.document.close();
            win.print();
        }

        async function downloadPDF() {
            fillReceiptPreview(); // populate receipt first

            const previewElement = document.getElementById("receiptPreview");

            // Make it temporarily visible for rendering
            previewElement.style.display = "block";

            const canvas = await html2canvas(previewElement, {
                scale: 2,
                useCORS: true
            });

            const imgData = canvas.toDataURL("image/png");
            const pdf = new jspdf.jsPDF("p", "pt", "a4");

            const imgWidth = 550; // fit A4 width
            const pageHeight = 800;
            const imgHeight = (canvas.height * imgWidth) / canvas.width;

            pdf.addImage(imgData, 'PNG', 30, 40, imgWidth, imgHeight);
            pdf.save("Maintenance_Receipt.pdf");

            // Hide it again
            previewElement.style.display = "none";
        }


        function printreceiptsearch() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;

            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Receipt Details</title>');
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
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>');
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
