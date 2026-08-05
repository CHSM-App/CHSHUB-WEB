<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="maintenance_search.aspx.cs" Inherits="Society.maintenance_search" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <style>
        @media(max-width: 630px) {
            .top-row {
                flex-direction: column;
            }

            .w-90 {
                width: 90%;
            }
        }

        .setting{
            margin-left:auto;
            padding: 5px; 
            border: 2px solid black; 
            border-radius: 7px; 
            background:white; 
            color: black;
        }

  
        .resized-model {
            width: 100%;
            max-width: 900px;
            height: auto;
            margin: auto;
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

        e
        .suggestion-item:hover {
            background: #f0f0f0;
        }

        .pdf-page-break {
            page-break-after: always;
            padding: 20px;
        }

            .pdf-page-break:last-child {
                page-break-after: auto;
            }

        @media print {
            .page-break {
                page-break-after: always;
            }

            .no-print {
                display: none !important;
            }
        }

        @media (max-width: 576px) {
            .resized-model {
                max-width: 100%;
                margin: 0.5rem;
            }

            .modal-dialog {
                margin: 0.5rem;
            }

            .suggestion-list {
                width: 100% !important;
            }

            .form-control {
                width: 100% !important;
            }

            .calendar-icon {
                width: 24px;
                height: 24px;
            }

            .btn {
                width: 100%;
                /*                margin-top: 0.5rem;*/
            }
        }

     
    </style>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table class="w-100">
                    <tr>
                        <th>
                            <h1 class="font-weight-bold" style="color: #012970;">Society Maintenance Bills</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel ID="bill" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="m_bill_status" runat="Server"></asp:HiddenField>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="top-row d-flex align-items-center flex-wrap">
                                        <div class="search-container">

                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox"
                                                placeHolder="Search here"
                                                runat="server"
                                                TextMode="Search"                                               
                                                autocomplete="off"
                                                onkeyup="triggerSearch()"/>

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
                                        <asp:Button ID="addNew" type="button" class="btn btn-primary mt-sm-0" data-toggle="modal" data-target="#edit_model" runat="server" OnClick="btnAdd_Click" OnClientClick="bind_date()" Text="Add"></asp:Button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-primary mt-sm-0" onclick="printmaintenanceDetails()">Print</button>
                                        &nbsp;&nbsp;
                                        <button type="button" class="btn btn-success mt-sm-0" onclick="downloadReceipt()">
                                            <i class="fas fa-download me-1"></i>Download Report
                                        </button>
                                         &nbsp;&nbsp;
                                        <asp:Button runat="server" ID="generateBill" type="button" class="btn btn-success mt-sm-0" OnClick="generate_regular_Click" Text="Generate regular Bill" OnClientClick="return confirm('Are you sure you want to generate the regular bill?');">
                                        </asp:Button>

                                        <asp:Button ID="settingsButton"   runat="server" OnClick="Unnamed_ServerClick" type="button" onClientClick="openSettingModal()" class="setting" usesubmitbehavior="False" Text="Settings">
                                          
                                        </asp:Button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div style="overflow:visible" class="table-responsive g-Table">
                                        <asp:GridView ID="GridView1" runat="server" AllowPaging="true" PageSize="10" OnPageIndexChanging="GridView1_PageIndexChanging" AutoGenerateColumns="false"
                                            CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue"
                                            OnSorting="GridView1_Sorting" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="80">
                                                    <ItemTemplate>
                                                        <asp:Label ID="No" runat="server" Text='<%#Container.DataItemIndex+1 %>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="ID" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="n_m_id" runat="server" Text='<%# Bind("bill_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Month" ItemStyle-Width="100" SortExpression="month_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="month" runat="server" Text='<%#Bind("month_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Year" ItemStyle-Width="100" SortExpression="year">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Year" runat="server" Text='<%# Bind("year")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Bill Date" ItemStyle-Width="150" SortExpression="m_date">
                                                    <ItemTemplate>
                                                        <asp:Label ID="m_date" runat="server" Text='<%# Bind("gen_date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Due Date" ItemStyle-Width="150" SortExpression="due_date">
                                                    <ItemTemplate>
                                                        <asp:Label ID="due_date" runat="server" Text='<%# Bind("due_date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
<%--                                                <asp:TemplateField HeaderText="Amount" ItemStyle-Width="120" SortExpression="m_total">
                                                    <ItemTemplate>
                                                        <asp:Label ID="m_total" runat="server" Text='<%# Bind("total_amount")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>--%>
                                                <asp:TemplateField HeaderText="Status" ItemStyle-Width="150" SortExpression="Status">
                                                    <ItemTemplate>
                                                        <asp:Label ID="gsg" runat="server" Text='<%# Bind("Status")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                     <%--           <asp:TemplateField ItemStyle-Width="80" HeaderText="Edit">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("bill_id")%>' OnClientClick="openModal()">
                                                            <img src="Images/123.png" />
                                                        </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>--%>

                                                <asp:TemplateField ItemStyle-Width="100" HeaderText="View">
                                                    <ItemTemplate>
                                                        <asp:Button
                                                            ID="btnViewBill"
                                                            runat="server"
                                                            Text="View Bill"
                                                            CssClass="btn btn-primary btn-sm"
                                                            CommandName="ViewBill"
                                                            CommandArgument='<%# Eval("bill_id") %>' OnCommand="btnViewBill_Command" />
                                                        <!-- ✅ Add this -->
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <asp:TemplateField ItemStyle-Width="50" HeaderText="Delete" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /></asp:LinkButton>
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
                                <h4 class="modal-title"><strong>New Maintenance</strong></h4>
                            </div>
                            <div class="modal-body" id="printPreviewBody">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="building_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="wing_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="n_m_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="society_name" runat="server" />
                                        <asp:Panel ID="Panel1" runat="server">
                                            <div class="form-group">
                                                <div class="row align-items-center mb-3">
                                                    <div class="col-12 col-sm-3">
                                                        <asp:Label ID="Label42" runat="server" Font-Bold="True" Font-Size="Medium" Text="Date"></asp:Label>
                                                        <asp:Label ID="Label44" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-12 col-sm-3">
                                                        <asp:TextBox ID="txt_date" CssClass="not-required" runat="server" placeholder="Enter Date" required="required" Enabled="false"></asp:TextBox>
                                                        <%--       <div class="invalid-feedback">
                                                            Please Enter Date
                                                        </div>--%>
                                                    </div>
                                                    <div class="col-12 col-sm-3">
                                                        <asp:Label runat="server" Font-Bold="True" Font-Size="Medium" Text="Bill Period "></asp:Label>
                                                        <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-12 col-sm-3">
                                                        <asp:TextBox ID="txt_period" CssClass="form-control" runat="server" placeholder="Enter in months" required TextMode="Number"></asp:TextBox>
                                                        <%--           <div class="invalid-feedback">
                                                            Please Enter Date
                                                        </div>--%>
                                                        <asp:Label runat="server" ID="dueDate"></asp:Label>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-12 col-sm-6">
                                                <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Medium"></asp:Label>
                                            </div>
                                            <div class="form-group">
                                                <div class="row">
                                                    <div class="col-12">
                                                        <div class="table-responsive">
                                                            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                                                <ContentTemplate>



                                                                    <asp:GridView ID="expenseGrid" runat="server" PageSize="30" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Expense for this Month">
                                                                        <Columns>
                                                                            <asp:TemplateField HeaderText="Nature of Charges" ItemStyle-Width="33%">
                                                                                <ItemTemplate>
                                                                                    <asp:Label ID="month" runat="server" Text='<%#Bind("charges")%>'></asp:Label>
                                                                                </ItemTemplate>

                                                                            </asp:TemplateField>
                                                                            <asp:TemplateField HeaderText="Amount" ItemStyle-Width="33%">
                                                                                <ItemTemplate>
                                                                                    <asp:Label ID="Year" runat="server" Text='<%# Bind("amount")%>'></asp:Label>
                                                                                </ItemTemplate>
                                                                            </asp:TemplateField>
                                                                            <asp:TemplateField HeaderText="Amount Per Flat" ItemStyle-Width="33%">
                                                                                <ItemTemplate>
                                                                                    <asp:Label ID="building_name" runat="server" Text='<%# Bind("amount_per_flat")%>'></asp:Label>
                                                                                </ItemTemplate>
                                                                            </asp:TemplateField>
                                                                        </Columns>
                                                                    </asp:GridView>
                                                                </ContentTemplate>
                                                                <Triggers>
                                                                    <asp:AsyncPostBackTrigger ControlID="addNew" EventName="Click" />
                                                                </Triggers>
                                                            </asp:UpdatePanel>

                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group d-none">
                                                <asp:Label runat="server" ID="lblMsg"></asp:Label>
                                                <div class="row align-items-center mb-3">
                                                    <div class="col-12 col-sm-3">
                                                        <asp:Label ID="TextBox1" runat="server" Text="Total Amount" Font-Bold="True"></asp:Label>
                                                    </div>
                                                    <div class="col-12 col-sm-3">
                                                        <asp:TextBox ID="txt_amount" runat="server" placeholder="Amount" Enabled="false" CssClass="form-control"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>
                            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="modal-footer">
                                        <div class="row">
                                            <div class="col-12 text-center d-flex">
                                                <asp:Panel runat="server" ID="BtnPanel" CssClass="d-flex justify-content-center" Visible="false">
                                                    <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" Visible="false" class="btn btn-primary mr-2" ValidationGroup="g1" OnClick="btn_save_Click" />
                                                    <asp:Button ID="btn_bill" runat="server" Text="Generate Bill" class="btn btn-primary mr-2" OnClick="btn_bill_Click" />
                                                    <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary mr-2" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" Visible="False" />
                                                    <button type="button" class="btn btn-primary mr-2" data-toggle="modal" data-target="#emailmodal">Email</button>
                                                    <asp:Button ID="btn_print" runat="server" Text="Print" class=" btn btn-primary mr-2" OnClick="btn_print_Click" />
                                                </asp:Panel>
                                                <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                            </div>
                                        </div>
                                    </div>
                                </ContentTemplate>
                                <Triggers>
                                    <asp:AsyncPostBackTrigger ControlID="addNew" EventName="Click" />
                                </Triggers>
                            </asp:UpdatePanel>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal fade" id="emailmodal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                <div class="modal-dialog modal-sm">
                    <div class="modal-content resized-model">
                        <div class="modal-header">
                            <h4 class="modal-title" id="gridSystemModalLabel1"><strong>Select Customer</strong></h4>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                        </div>
                        <div class="modal-body">
                            <asp:UpdatePanel ID="assd" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="form-group">
                                        <div class="row align-items-center mb-3">
                                            <div class="col-12">
                                                <label>Select all</label>
                                                <asp:CheckBox ID="CheckAll" runat="server" AutoPostBack="true" OnCheckedChanged="CheckAll_CheckedChanged"></asp:CheckBox>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <div class="row">
                                            <div class="col-12">
                                                <asp:Panel ID="Panel21" runat="server" ScrollBars="Auto" Height="400px">
                                                    <asp:CheckBoxList ID="CheckBoxList1" runat="server" AutoPostBack="true" OnSelectedIndexChanged="CheckBoxList1_SelectedIndexChanged" Font-Bold="true"></asp:CheckBoxList>
                                                </asp:Panel>
                                            </div>
                                        </div>
                                    </div>
                                </ContentTemplate>
                                <Triggers>
                                    <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    <asp:AsyncPostBackTrigger ControlID="addNew" EventName="Click" />
                                </Triggers>
                            </asp:UpdatePanel>
                        </div>
                        <div class="modal-footer">
                            <div class="row">
                                <div class="col-12 d-flex justify-content-between">
                                    <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-default" data-dismiss="modal" />
                                    <asp:Button ID="btn_email_send" runat="server" Text="Email" class="btn btn-primary" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal fade" id="printModal" tabindex="-1" aria-labelledby="modalLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg ">
                    <div class="modal-content p-4 resized-model  bill-section" id="billContainer" style="font-family: Arial, sans-serif;">
                        <div >
                            <div class="modal-header border-bottom-0 no-print d-flex justify-content-end">
                                <button type="button" class="btn btn-success ml-2" onclick="openPrintDialog()">Print</button>
                                <button type="button" class="btn btn-primary ml-2" onclick="downloadPDF()">Download PDF</button>
                            </div>
                            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="modal-body">
                                        <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound">
                                            <ItemTemplate>
                                                <div class="pdf-page-break print-page page-break">
                                                     <hr />
                                                     <br />
                                                    <h3 class="modal-title mx-auto text-center centerT" style="font-weight: bold;">MAINTENANCE BILL</h3>
                                                    <div class="text-center mb-2">
                                                        <h4 class="centerT" style="margin: 0;"><%# Eval("society_name") %></h4>
                                                        <p class="centerT" style="margin: 0;">Registration No: <%# Eval("registration_no") %></p>
                                                        <p class="centerT" style="margin: 0;"><%# Eval("address1") %></p>
                                                        
                                                    </div>
                                                    <table class="table table-bordered mb-3">
                                                        <tbody>
                                                            <tr>
                                                                <td><strong>Owner Name: <%# Eval("owner_name") %></strong></td>
                                                                  <%--<td>
                                                                  <asp:Label ID="Label3" runat="server" /></td>--%>
                                                                <td><strong>Flat No: <%# Eval("flat_no") %></strong></td>
                                                               <%-- <td>
                                                                    <asp:Label ID="Label5" runat="server" /></td>--%>
                                                            </tr>
                                                            <tr>
                                                                <td><strong>Wing Name: <%# Eval("w_name") %></strong></td>
                                                                 <%-- <td>
                                                                  <asp:Label ID="Label7" runat="server" /></td>--%>
                                                                <td><strong>Bill Date: <%# Eval("gen_date", "{0:dd-MM-yyyy}") %></strong></td>
                                                           <%--     <td>
                                                                    <asp:Label ID="Label8" runat="server" /></td>--%>
                                                            </tr>
                                                            <tr>
                                                                <td><strong>Area : <%# Eval("sq_ft") %> sq.ft</strong></td>
                                                                 <%-- <td>
                                                                  <asp:Label ID="Label9" runat="server" /></td>--%>
                                                                <td><strong>Due Date: <%# Eval("due_date", "{0:dd-MM-yyyy}") %></strong></td>
                                                                <%--<td></td>--%>
                                                            </tr>
                                                        </tbody>
                                                    </table>
                                                    <asp:Repeater ID="billCharges" runat="server" OnItemDataBound="billCharges_ItemDataBound">
                                                        <HeaderTemplate>
                                                            <table class="table table-bordered">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Sr. No</th>
                                                                        <th>Nature of Charges</th>
                                                                        <th style="text-align:right;">Amount (₹)</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                        </HeaderTemplate>
                                                        <ItemTemplate>
                                                            <tr>
                                                             <td><%# Container.ItemIndex + 1 %></td>
                                                                <td><%# Eval("ChargeName") %></td>
                                                               <td style="text-align:right;"> <span>₹ <asp:Label ID="Label1" runat="server" Text='<%# String.Format(new System.Globalization.CultureInfo("hi-IN"), "{0:N2}", Convert.ToDecimal(Eval("Amount"))) %>' /></span></td>

                                                            </tr>
                                                        </ItemTemplate>
                                                        <FooterTemplate>
                                                            </tbody></table>
                                                        </FooterTemplate>
                                                    </asp:Repeater>
                                                    <table class="table table-bordered mb-3">
                                                        <tbody>
                                                            <tr>
                                                                <td>
                                                                    <div style="display: flex; justify-content: space-between; width: 100%;">
                                                                        <span><strong>Total:</strong></span>
                                                                       <span>₹ <asp:Label ID="Label1" runat="server" Text='<%# String.Format(new System.Globalization.CultureInfo("hi-IN"), "{0:N2}", Convert.ToDecimal(Eval("total_amount"))) %>' /></span>

                                                                    </div>
                                                                </td>
                                                            </tr>

                                                            <tr id="trAmtForward" runat="server">
                                                                <td>
                                                                    <div style="display: flex; justify-content: space-between; width: 100%;">
                                                                        <span><strong>Dues as of <%# Eval("gen_date", "{0:dd-MM-yyyy}") %> :</strong></span>
                                                                      <span>₹ <asp:Label ID="Label11" runat="server" Text='<%# String.Format(new System.Globalization.CultureInfo("hi-IN"), "{0:N2}", Convert.ToDecimal(Eval("amt_forward"))) %>' /> </span>

                                                                    </div>
                                                                </td>
                                                            </tr>

                                                            <tr>
                                                                <td>
                                                                    <div style="display: flex; justify-content: space-between; width: 100%;">
                                                                        <span><strong>Grand Total:</strong></span>
                                                                        <span><span><strong>₹ <%# String.Format(new System.Globalization.CultureInfo("hi-IN"), "{0:N2}",  Convert.ToDecimal(Eval("total_amount")) + Convert.ToDecimal(Eval("amt_forward"))) %>
                                                                        </strong></span>
                                                                        </span>
                                                                    </div>
                                                                </td>
                                                            </tr>

                                                            <tr>
                                                                <td>
                                                                    <div style="display: flex; justify-content: space-between; width: 100%;">
                                                                        <span style="width: 200px;"><strong>Amount in Words:</strong></span>
                                                                        <asp:Label style="text-align:right;" ID="Label14" runat="server" Text='<%# NumberToWords(Convert.ToDecimal(Eval("total_amount"))) %>' />
                                                                    </div>
                                                                </td>
                                                            </tr>
                                                        </tbody>

                                                    </table>
                                                    <br />
                                                    <br />

                                                    <div class="signature-block text-end">
                                                        <p class="right"><strong>For <%# Eval("society_name") %></strong></p>
                                                        <p class="right"><strong>HON- SECRETARY</strong></p>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </ContentTemplate>
                                <Triggers>
                                    <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                </Triggers>
                            </asp:UpdatePanel>
                            <div class="modal-footer no-print d-flex justify-content-end">
                                <button type="button" class="btn btn-success ml-2" onclick="openPrintDialog()">Print</button>
                                <button type="button" class="btn btn-primary ml-2" onclick="downloadPDF()">Download PDF</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="modal fade" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content resized-model">
                        <div class="modal-header" style="justify-content: center;">
                            <h4 class="modal-title text-center"><strong>Maintenance Details</strong></h4>
                        </div>
                        <asp:UpdatePanel runat="server">
                            <ContentTemplate>
                                <div class="modal-body">
                                    <div style="text-align: center; margin-bottom: 10px;">
                                        <h4><strong><%= society_name.Value %></strong></h4>
                                    </div>
                                    <div class="table-responsive" style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">
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
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="80">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" runat="server" Text='<%# Container.DataItemIndex + 1 %>' />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:BoundField HeaderText="Month" DataField="month_name" SortExpression="month_name" ItemStyle-Width="100" />
                                                <asp:BoundField HeaderText="Year" DataField="year" SortExpression="year" ItemStyle-Width="100" />
                                <%--                <asp:BoundField HeaderText="Building" DataField="build_name" SortExpression="building_name" ItemStyle-Width="200" />
                                                <asp:BoundField HeaderText="Wing" DataField="wings" SortExpression="wings" ItemStyle-Width="150" />--%>
                                                <asp:BoundField HeaderText="Bill Date" DataField="gen_date" DataFormatString="{0:dd-MM-yyyy}" SortExpression="gen_date" ItemStyle-Width="150" />
                                                <asp:BoundField HeaderText="Due Date" DataField="due_date" DataFormatString="{0:dd-MM-yyyy}" SortExpression="due_date" ItemStyle-Width="150" />
                                                <%--<asp:BoundField HeaderText="Amount" DataField="total_amount" SortExpression="total_amount" ItemStyle-Width="120" />--%>
                                                <asp:BoundField HeaderText="Status" DataField="Status" SortExpression="Status" ItemStyle-Width="150" />
                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                </div>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>
            </div>
            <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>
            <!-- Settings Modal -->
            <div class="modal fade bs-example-modal-sm" id="settingModal" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                <div class="modal-dialog">
                    <div class="modal-content">

                        <div class="modal-header">
                            <h5 class="modal-title " id="settingModalLabel">Regular Maintenance Settings</h5>
                        </div>
                        <asp:UpdatePanel ID="updModal" runat="server">
                            <ContentTemplate>

                                <div class="modal-body">
                                    <div class="form-group mb-3">
                                        <label for="txt_per_sqft_rate">Per Sq. Feet Rate</label>
                                        <asp:TextBox ID="txt_per_sqft_rate" runat="server" CssClass="form-control" placeholder="Enter per sq. ft. rate" required="required" ValidationGroup="g1"></asp:TextBox>
                                 
                                    </div>

                                    <div class="form-group mb-3">
                                        <label for="txt_2w_rate">2 Wheeler Rate</label>
                                        <asp:TextBox ID="txt_2w_rate" runat="server" CssClass="form-control" placeholder="Enter 2 wheeler rate" required></asp:TextBox>
                                    </div>

                                    <div class="form-group mb-3">
                                        <label for="txt_4w_rate">4 Wheeler Rate</label>
                                        <asp:TextBox ID="txt_4w_rate" runat="server" CssClass="form-control" placeholder="Enter 4 wheeler rate" required></asp:TextBox>
                                    </div>

                                    <div class="form-group mb-3">
                                        <label for="txt_gen_day">Generation Day (1–31)</label>
                                        <asp:TextBox ID="txt_gen_day" runat="server" CssClass="form-control" placeholder="Enter day (1–31)" TextMode="Number" min="1" max="31" MaxLength="32" required></asp:TextBox>
                                    </div>

                                    <div class="form-group mb-3">
                                        <label for="txt_due_period">Due Date Period (in days)</label>
                                        <asp:TextBox ID="txt_due_period" runat="server" CssClass="form-control" placeholder="Enter number of days" TextMode="Number" required></asp:TextBox>
                                    </div>

                                    <div class="form-group mb-3">
                                        <div class="form-check form-switch">
                                            <input runat="server" class="form-check-input" type="checkbox" role="switch" id="chk_auto_gen">
                                            <label class="form-check-label" for="flexSwitchCheckDefault">Auto Maintenance Generation</label>
                                        </div>
                                    </div>
                                </div>
                            </ContentTemplate>
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="btnSave" EventName="Click" />
                                <asp:AsyncPostBackTrigger ControlID="settingsButton" EventName="Click" />
                            </Triggers>
                        </asp:UpdatePanel>


                        <div class="modal-footer">
                            <asp:Button ID="btnSave" OnClientClick="disableSaveButtonIfValidSettings"  runat="server" Text="Save" CssClass="btn btn-primary" OnClick="btnSave_Click" ValidationGroup="g1"/>
                            <asp:Button ID="Button2" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                        </div>


                    </div>
                </div>
            </div>

        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
<%--    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>--%>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>



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


        function numberToWords(num) {
            if (num === 0) return "zero";

            const belowTwenty = [
                "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
                "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                "seventeen", "eighteen", "nineteen"
            ];
            const tens = [
                "", "", "twenty", "thirty", "forty", "fifty",
                "sixty", "seventy", "eighty", "ninety"
            ];
            const thousands = ["", "thousand", "million", "billion"];

            function helper(n) {
                if (n === 0) return "";
                else if (n < 20) return belowTwenty[n] + " ";
                else if (n < 100) return tens[Math.floor(n / 10)] + " " + helper(n % 10);
                else return belowTwenty[Math.floor(n / 100)] + " hundred " + helper(n % 100);
            }

            let result = "";
            let i = 0;

            while (num > 0) {
                if (num % 1000 !== 0) {
                    result = helper(num % 1000) + thousands[i] + " " + result;
                }
                num = Math.floor(num / 1000);
                i++;
            }

            return result.trim();
        }


        function bind_date() {
            var txtDate = document.getElementById('<%= txt_date.ClientID %>');
            if (txtDate) {
                // Get today's date
                var today = new Date();

                // Format as yyyy-MM-dd
                var formattedDate = today.toISOString().split('T')[0];

                // Set the value in the textbox
                txtDate.value = formattedDate;
            }
        }

        function closeModalSettings() {
            resetForm(); // clear form
            var modalEl = document.getElementById('settingModal');
            var modal = bootstrap.Modal.getInstance(modalEl) || new bootstrap.Modal(modalEl);
            modal.hide(); // programmatically hide modal
        }

        function resetForm() {
            document.getElementById('<%= txt_per_sqft_rate.ClientID %>').value = '';
            document.getElementById('<%= txt_2w_rate.ClientID %>').value = '';
            document.getElementById('<%= txt_4w_rate.ClientID %>').value = '';
            document.getElementById('<%= txt_due_period.ClientID %>').value = '';
            document.getElementById(chk_auto_gen).checked = false;
        }


        function openSettingModal() {
            $('#settingModal').modal('show');
        }

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
        function SuccessEntryy() {
            Swal.fire({
                title: '✅ Success!',
                text: 'bill Generated Successfully',
                icon: 'success',
                showConfirmButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'OK',
                timer: 2000,
                timerProgressBar: true,
                didOpen: () => {
                    Swal.showLoading()
                },
                willClose: () => {
                    window.location.href = 'maintenance_search.aspx';
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
                return false;
            }
            return false;
        }
        function disableSaveButtonIfValidSettings() {
            var btn = document.getElementById('<%= btnSave.ClientID %>');
            var modal = document.getElementById('settingModal');
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
                __doPostBack('<%= btnSave.UniqueID %>', '');
                return false;
            }
            return false;
        }


        document.addEventListener("DOMContentLoaded", function () {
        //    const txtDate = document.getElementById('<%= txt_date.ClientID %>');
            const today = new Date().toISOString().split('T')[0];
            txtDate.value = today;
            txtDate.disabled = true; // disable textbox
        });

        document.addEventListener("DOMContentLoaded", function () {
            const txtMonths = document.getElementById('<%= txt_period.ClientID %>');
            const lblNewDate = document.getElementById('<%= dueDate.ClientID %>');

            txtMonths.addEventListener("input", function () {
                const monthsToAdd = parseInt(txtMonths.value);
                if (isNaN(monthsToAdd) && monthsToAdd.innerText != null) {
                    lblNewDate.innerText = "Invalid number";
                    return;
                }

                // Base date (you can replace with your own if needed)
                const currentDate = new Date();

                // Add months
                const newDate = new Date(currentDate);
                newDate.setMonth(currentDate.getMonth() + monthsToAdd);

                // Format (yyyy-mm-dd)
                const formattedDate = newDate.toISOString().split('T')[0];

                // Set to label
                lblNewDate.innerText = "Due date : " + formattedDate;
            });
        });






        let formSubmitted = false;
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
            const clone = sourceElement.cloneNode(true);
            clone.style.width = "800px";

            // Apply dark borders and header bold via inline styles
            clone.querySelectorAll("table").forEach(table => {
                table.style.borderCollapse = "collapse";
                table.style.width = "100%";
            });
            clone.querySelectorAll("table, th, td").forEach(el => {
                el.style.border = "1px solid #000"; // dark border
                el.style.padding = "5px";
            });
            clone.querySelectorAll("th").forEach(th => {
                th.style.fontWeight = "bold"; // bold header
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 3,
                    useCORS: true,
                    scrollY: -window.scrollY,
                    allowTaint: true
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");
                const pageWidth = pdf.internal.pageSize.getWidth();
                const pageHeight = pdf.internal.pageSize.getHeight();
                const margin = 40;

                // PDF header text
                const title = "Maintenance Details";
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const titleX = (pageWidth - textWidth) / 2;
                pdf.text(title, titleX, 40);

                const imgWidth = pageWidth - margin * 2;
                const fullImageHeight = (canvas.height * imgWidth) / canvas.width;
                const contentYStart = 60;
                const availableHeight = pageHeight - contentYStart - margin;
                let remainingHeight = fullImageHeight;
                let yOffset = 0;
                let pageIndex = 0;

                while (remainingHeight > 0) {
                    const sliceHeight = Math.min(availableHeight, remainingHeight);
                    const sliceCanvas = document.createElement("canvas");
                    sliceCanvas.width = canvas.width;
                    sliceCanvas.height = (sliceHeight * canvas.width) / imgWidth;

                    const ctx = sliceCanvas.getContext("2d");
                    ctx.drawImage(
                        canvas,
                        0, yOffset, canvas.width, sliceCanvas.height,
                        0, 0, canvas.width, sliceCanvas.height
                    );

                    const croppedImg = sliceCanvas.toDataURL("image/png");
                    const yPos = pageIndex === 0 ? contentYStart : margin;
                    pdf.addImage(croppedImg, "PNG", margin, yPos, imgWidth, sliceHeight);

                    remainingHeight -= sliceHeight;
                    yOffset += sliceCanvas.height;
                    pageIndex++;

                    if (remainingHeight > 0) {
                        pdf.addPage();
                    }
                }

                pdf.save("MaintenanceReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }

        function openPrintDialog() {
            const content = document.querySelector("#printModal .model-temp").innerHTML;
            const printWindow = window.open('', '', 'height=800,width=1000');
            printWindow.document.write('<html><head><title>Print</title>');
            printWindow.document.write(`
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .page-break { page-break-after: always; }
                    .centerT { text-align: center; }
                    .right { text-align: right; }
                    .table { width: 100%; border-collapse: collapse; }
                    .table td, .table th { border: 1px solid #000; padding: 8px; }
                    @media print {
                        .no-print { display: none !important; }
                    }
                </style>
            `);
            printWindow.document.write('</head><body>');
            printWindow.document.write(content);
            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

<%--        function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox5.ClientID %>");
            const textBox2 = document.getElementById("<%= TextBox6.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");
            textBox1.addEventListener("focus", () => {
                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
            });
            textBox1.addEventListener("input", () => {
                const input = textBox1.value.toLowerCase();
                filterSuggestions("category-link", input, repeaterContainer1);
            });
            textBox2.addEventListener("focus", () => {
                repeaterContainer2.style.display = "block";
                repeaterContainer1.style.display = "none";
            });
            textBox2.addEventListener("input", () => {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("category-link", input, repeaterContainer2);
            });
        }--%>

        // Add this CSS to your stylesheet or in a <style> tag
        const loaderStyles = `
<style>
.pdf-loader-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 99999;
  opacity: 1;
}

.pdf-loader-content {
  text-align: center;
  color: white;
}

.pdf-loader-spinner {
  width: 120px;
  height: 120px;
  position: relative;
  margin: 0 auto 30px;
}

.pdf-loader-ring {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 3px solid transparent;
  border-radius: 50%;
  animation: rotate 2s linear infinite;
}

.pdf-loader-ring:nth-child(1) {
  border-top-color: #007bff;
  animation-duration: 1.5s;
}

.pdf-loader-ring:nth-child(2) {
  border-right-color: #0056b3;
  animation-duration: 2s;
  animation-direction: reverse;
}

.pdf-loader-ring:nth-child(3) {
  border-bottom-color: #004085;
  animation-duration: 2.5s;
}

@keyframes rotate {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.pdf-loader-dots {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin-top: 20px;
}

.pdf-loader-dot {
  width: 12px;
  height: 12px;
  background: #007bff;
  border-radius: 50%;
  animation: bounce 1.4s ease-in-out infinite;
}

.pdf-loader-dot:nth-child(1) { animation-delay: -0.32s; }
.pdf-loader-dot:nth-child(2) { animation-delay: -0.16s; }

@keyframes bounce {
  0%, 80%, 100% { transform: scale(0); opacity: 0.5; }
  40% { transform: scale(1); opacity: 1; }
}

.pdf-loader-text {
  font-size: 24px;
  font-weight: 600;
  color: white;
  margin-bottom: 10px;
}

.pdf-loader-subtext {
  font-size: 14px;
  color: #888;
  margin-top: 10px;
}

.pdf-loader-progress {
  width: 300px;
  height: 4px;
  background: white;
  border-radius: 10px;
  margin-top: 30px;
  overflow: hidden;
}

.pdf-loader-progress-bar {
  height: 100%;
  background: #007bff;
  border-radius: 10px;
  width: 0%;
  transition: width 0.3s ease;
}
</style>
`;

        // Inject styles if not already present
        if (!document.getElementById('pdf-loader-styles')) {
            const styleElement = document.createElement('div');
            styleElement.id = 'pdf-loader-styles';
            styleElement.innerHTML = loaderStyles;
            document.head.appendChild(styleElement.firstElementChild);
        }

        // Create loader HTML
        function createLoader() {
            const loaderHTML = `
    <div class="pdf-loader-overlay" id="pdfLoader">
      <div class="pdf-loader-content">
        <div class="pdf-loader-spinner">
          <div class="pdf-loader-ring"></div>
          <div class="pdf-loader-ring"></div>
          <div class="pdf-loader-ring"></div>
        </div>
        <div class="pdf-loader-text">Generating PDF</div>
        <div class="pdf-loader-subtext">Please wait while we prepare your document...</div>
        <div class="pdf-loader-progress">
          <div class="pdf-loader-progress-bar" id="pdfProgressBar"></div>
        </div>
        <div class="pdf-loader-dots">
          <div class="pdf-loader-dot"></div>
          <div class="pdf-loader-dot"></div>
          <div class="pdf-loader-dot"></div>
        </div>
      </div>
    </div>
  `;

            const loaderDiv = document.createElement('div');
            loaderDiv.innerHTML = loaderHTML;
            document.body.appendChild(loaderDiv.firstElementChild);
        }

        // Remove loader
        function removeLoader() {
            const loader = document.getElementById('pdfLoader');
            if (loader) {
                loader.style.opacity = '0';
                setTimeout(() => loader.remove(), 300);
            }
        }

        // Update progress bar
        function updateProgress(current, total) {
            const progressBar = document.getElementById('pdfProgressBar');
            if (progressBar) {
                const percentage = (current / total) * 100;
                progressBar.style.width = percentage + '%';
            }
        }

        // Modified download function
async function downloadPDF() {
    console.log("Downloading PDF");
    createLoader();
    updateProgress(0, 100);
    
    await new Promise(resolve => setTimeout(resolve, 50));
    
    try {
        const pdf = new jspdf.jsPDF("p", "mm", "a4");
        const pages = document.querySelectorAll("#billContainer .pdf-page-break");
        
        if (pages.length === 0) {
            console.log("No PDF page blocks found");
            removeLoader();
            return;
        }
        
        const totalPages = pages.length;
        const pdfWidth = pdf.internal.pageSize.getWidth();
        const pdfHeight = pdf.internal.pageSize.getHeight();
        
        // Process each page sequentially
        for (let index = 0; index < totalPages; index++) {
            try {
                // Capture single page
                const canvas = await html2canvas(pages[index], {
                    scale: 2, // Good quality
                    useCORS: true,
                    logging: false,
                    allowTaint: false,
                    backgroundColor: '#ffffff'
                });
                
                // Calculate dimensions to fit A4 page
                const imgWidth = pdfWidth;
                const imgHeight = (canvas.height * pdfWidth) / canvas.width;
                
                // Compress image
                const imgData = canvas.toDataURL("image/jpeg", 0.80);
                
                // Add new page if not first
                if (index > 0) {
                    pdf.addPage();
                }
                
                // Add image to fit page (will scale if needed)
                if (imgHeight > pdfHeight) {
                    // If content is taller than page, fit to page height
                    const scaledWidth = (canvas.width * pdfHeight) / canvas.height;
                    pdf.addImage(imgData, "JPEG", 0, 0, scaledWidth, pdfHeight, undefined, 'FAST');
                } else {
                    // Content fits in one page
                    pdf.addImage(imgData, "JPEG", 0, 0, imgWidth, imgHeight, undefined, 'FAST');
                }
                
                // Update progress
                updateProgress(index + 1, totalPages);
                
                // Small delay to prevent UI freeze
                await new Promise(resolve => setTimeout(resolve, 10));
                
            } catch (error) {
                console.error(`Error processing page ${index + 1}:`, error);
            }
        }
        
        // Save PDF
        await new Promise(resolve => setTimeout(resolve, 300));
        pdf.save("maintenance-bill.pdf");
        removeLoader();
        
    } catch (error) {
        console.error("Error generating PDF:", error);
        removeLoader();
        alert("Error generating PDF. Please try again.");
    }
}






        function printmaintenanceDetails() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;
            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Maintenance Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body { font-size: 12px; margin: 30px; font-family: Arial, sans-serif; }');
            printWindow.document.write('h4 { margin-bottom: 10px; text-align: center; }');
            printWindow.document.write('.table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th { background-color: #012970; color: white; text-align: center; }');
            printWindow.document.write('.print-header { text-align: center; margin-bottom: 20px; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>');
            printWindow.document.write('</div>');
            printWindow.document.write(modalContent);
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + new Date().toLocaleString() + '</div>');
            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

        function setModalData(date, amount, mode, txnRef, upiId) {
            document.getElementById("modalDate").innerText = date;
            document.getElementById("modalAmount").innerText = amount;
            document.getElementById("modalMode").innerText = mode;
            document.getElementById("modalTxnRef").innerText = txnRef;
            document.getElementById("modalUpiId").innerText = upiId;
        }

        function printModalReceipt() {
            var printContents = document.querySelector(".modal-content").innerHTML;
            var originalContents = document.body.innerHTML;

            document.body.innerHTML = printContents;
            window.print();
            document.body.innerHTML = originalContents;
            location.reload(); // reload the page to restore event handlers
        }

        function downloadModalPDF() {
            html2canvas(document.querySelector(".modal-content")).then(canvas => {
                const imgData = canvas.toDataURL('image/png');
                const pdf = new jsPDF();
                pdf.addImage(imgData, 'PNG', 10, 10);
                pdf.save("PaymentReceipt.pdf");
            });
        }


        Sys.Application.add_load(initDropdownEvents);
    </script>

</asp:Content>
