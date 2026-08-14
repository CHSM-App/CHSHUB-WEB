<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="society_expense.aspx.cs" Inherits="Society.society_expense" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .resized-model {
            width: 950px;
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

        @media(max-width: 630px) {
            .top-row {
                flex-direction: column;
            }

            .w-90 {
                width: 90%;
            }
        }
    </style>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Expenses
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>



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
                                        <button id="save" runat="server" onserverclick="Unnamed_ServerClick" type="button" class="w-90 btn btn-primary" runat="server" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp;&nbsp;
                                             <!-- "Print" Button -->
                                        <button type="button" class="w-90 btn btn-primary" onclick="printparkingDetails()">Print</button>

                                        &nbsp; 
                                            <button type="button" class="w-90 btn btn-success" usesubmitbehavior="False" onclick="downloadReceipt()">
                                                <i class="fas fa-download me-1"></i>Download Report      
                                            </button>


                                    </div>
                                </div>
                     
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView ID="GridView1" runat="server"
                                            AutoGenerateColumns="False"
                                            CssClass="table table-striped table-bordered"
                                            OnSorting="GridView1_Sorting"
                                            OnRowDeleting="GridView1_RowDeleting"
                                            OnPageIndexChanging="GridView1_PageIndexChanging"
                                            AllowSorting="True"
                                            AllowPaging="True"
                                            PageSize="10">
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="expense_id" SortExpression="expense_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="expense_id" Text='<%# Bind("expense_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Vendor Name" SortExpression="ex_name">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="v_name" Text='<%# Bind("ex_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Expense Details" SortExpression="ex_details">
                                                    <ItemTemplate>
                                                        <asp:Label ID="ex_details" runat="server" Text='<%# Bind("ex_details")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Date" SortExpression="date" ItemStyle-Width="150">
                                                    <ItemTemplate>
                                                        <asp:Label ID="date" runat="server" Text='<%# Bind("date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Amount" SortExpression="f_amount">
                                                    <ItemTemplate>
                                                        <asp:Label ID="f_amount" runat="server" Text='<%# Bind("f_amount")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Type" SortExpression="expense_status">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="lbltype" Text='<%# Bind("type")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Status" SortExpression="expense_status">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="lblstatu" Text='<%# Bind("expense_status")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Action">
                                                    <ItemTemplate>
                                                        <asp:LinkButton ID="lnkEdit" runat="server"
                                                            OnCommand="edit_Command"
                                                            CommandArgument='<%# Eval("expense_id") %>'
                                                            Text="Edit"
                                                            CssClass="btn btn-primary btn-sm">
                                                            <i class="fa fa-edit"></i> Edit
                                                        </asp:LinkButton>

                                                        <asp:LinkButton ID="lnkDelete" runat="server"
                                                            CommandName="Delete"
                                                            CommandArgument='<%# Eval("expense_id") %>'
                                                            Text="Delete"
                                                            CssClass="btn btn-danger btn-sm"
                                                            OnClientClick="return confirm('Are you sure you want to delete this expense?');">
                                                            <i class="fa fa-trash"></i> Delete
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
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Society Expense</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="expense_id" runat="server"></asp:HiddenField>
                                        <asp:HiddenField ID="approvar_id" runat="server"></asp:HiddenField>
                                        <asp:HiddenField ID="mem_id" runat="server"></asp:HiddenField>
                                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>

                                        <asp:HiddenField runat="server" ID="vendor_name_id" />
                                        <asp:HiddenField runat="server" ID="building_id" />

                                        <asp:HiddenField ID="society_name" runat="server" />
                                        <asp:Panel ID="expense_panel" runat="server">


                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_name" runat="server" Text="Invoice No"></asp:Label>
                                                        <asp:Label ID="lbl_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="lbl_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_no" CssClass="from-control" runat="server" Height="32px" Width="200px" placeholder="Enter Invoice No" Enabled="false" required> </asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Invoice No
                                                        </div>
                                                        <br />

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label1" runat="server" Text="Date"></asp:Label>
                                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_date" CssClass="form-control" runat="server" Height="32px" Width="200px" TextMode="Date" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Date
                                                        </div>
                                                    </div>

                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_pre_mob" runat="server" Text="Expense Types"></asp:Label>
                                                        <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-2">
                                                        <asp:RadioButton ID="vendor" selected="true" runat="server" Text="Vendor" GroupName="g1" Font-Bold="true" AutoPostBack="true" OnCheckedChanged="vendor_CheckedChanged" />
                                                    </div>
                                                    <div class="col-sm-1">
                                                        <asp:RadioButton ID="cash" runat="server" Text="Cash" AutoPostBack="true" GroupName="g1" Font-Bold="true" OnCheckedChanged="cash_CheckedChanged" />
                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label4" runat="server" Text="Vendor Name "></asp:Label>
                                                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <%-- <asp:TextBox ID="txt_name" CssClass="form-control" runat="server" Height="32px" Width="200px" placeholder="Enter Name" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Name
                                                        </div>--%>
                                                        <div class="dropdown-container">
                                                            <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                                placeholder="Select" autocomplete="off" required="required" Style="width: 200px;" />
                                                            <asp:Panel ID="drp_Container" runat="server">
                                                                <div id="RepeaterContainer1" class="suggestion-list">
                                                                    <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                        <ItemTemplate>
                                                                            <asp:LinkButton
                                                                                ID="lnkCategory"
                                                                                runat="server"
                                                                                CssClass="suggestion-item link-button category-link"
                                                                                Text='<%# Eval("vendor_name") %>'
                                                                                CommandArgument='<%# Eval("vendor_id") %>'
                                                                                CommandName="SelectCategory"
                                                                                OnClientClick="setCategoryBox1(this.innerText);" />
                                                                        </ItemTemplate>
                                                                        <FooterTemplate>
                                                                            <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                                Text="No items found." />
                                                                        </FooterTemplate>
                                                                    </asp:Repeater>
                                                                </div>
                                                            </asp:Panel>
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <%--<div class="col-sm-3">
                                                        <asp:Label ID="Label23" runat="server" Text="Building name"></asp:Label>
                                                        <asp:Label ID="Label24" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        <asp:Label ID="Label25" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <div class="dropdown-container">
                                                            <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                                placeholder="Select" autocomplete="off" required="required" Style="width: 200px;" />
                                                            <div id="RepeaterContainer2" class="suggestion-list">
                                                                <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                    <ItemTemplate>
                                                                        <asp:LinkButton
                                                                            ID="lnkCategory"
                                                                            runat="server"
                                                                            CssClass="suggestion-item link-button category-link"
                                                                            Text='<%# Eval("name") %>'
                                                                            CommandArgument='<%# Eval("build_id") %>'
                                                                            CommandName="SelectCategory"
                                                                            OnClientClick="setCategoryBox2(this.innerText);" />
                                                                    </ItemTemplate>
                                                                    <FooterTemplate>
                                                                        <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                            Text="No items found." />
                                                                    </FooterTemplate>
                                                                </asp:Repeater>
                                                            </div>
                                                        </div>
                                                    </div>--%>


                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_pre_addr1" runat="server" Text="Expense Details"></asp:Label>
                                                        <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        <asp:Label ID="lbl_pre_addr1_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_details" CssClass="form-control" runat="server" Height="32px" Width="200px" Style="text-transform: capitalize;" placeholder="Enter details" TextMode="MultiLine" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Expense Details
                                                        </div>

                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label7" runat="server" Text="Comments"></asp:Label>
                                                        <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_comment" CssClass="not-required" runat="server" Height="32px" Width="200px" placeholder="Enter comments" Style="text-transform: capitalize;" TextMode="MultiLine"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    <asp:Panel runat="server" Width="460px"></asp:Panel>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label15" runat="server" Text="Amount"></asp:Label>
                                                        <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_amount" CssClass="form-control" runat="server" Height="32px" Width="200px" placeholder="Enter Amount" onkeypress="return digit(event);" OnTextChanged="txt_amount_TextChanged" AutoPostBack="True" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Amount
                                                        </div>
                                                        <br />

                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-6">
                                                        <asp:CheckBox Visible="false" ID="add_chk" runat="server" Text="Adding Maintenance" Width="200px" />
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label10" runat="server" Text="Tax"></asp:Label>
                                                        <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_tax" CssClass="form-control" runat="server" Height="32px" Width="200px" placeholder="Tax" onkeypress="return digit(event);" OnTextChanged="txt_tax_TextChanged" AutoPostBack="true" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Tax
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-6">
                                                        <asp:CheckBox ID="regular_chk" runat="server" Text="Regular Expense" Width="200px" />

                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label26" runat="server" Text="TDS"></asp:Label>
                                                        <asp:Label ID="Label27" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label28" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_tds" CssClass="form-control" runat="server" Height="32px" Width="200px" onkeypress="return digit(event);" placeholder="TDS"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter TDS
                                                        </div>

                                                    </div>
                                                </div>
                                            </div>


                                            <div class="form-group">
                                                <div class="row">

                                                    <div class="col-sm-3">
                                                        <asp:LinkButton ID="btn_add" runat="server" Text="Add Approver" data-toggle="modal" data-target="#emailmodal"></asp:LinkButton>
                                                    </div>


                                                    <div class="col-sm-3">
                                                        <asp:GridView ID="GridView3" runat="server" AutoGenerateColumns="false" OnRowDeleting="GridView3_RowDeleting" OnRowDataBound="GridView3_RowDataBound" GridLines="None">

                                                            <Columns>

                                                                <asp:TemplateField HeaderText="user_id" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label runat="server" ID="user_id" Text='<%# Bind("user_id")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Approvers">
                                                                    <ItemTemplate>
                                                                        <asp:Label runat="server" ID="name1" Text='<%# Bind("name")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Action" Visible="False">
                                                                    <ItemTemplate>
                                                                        <asp:Label runat="server" ID="status" Text='<%#  Eval("status").ToString()=="0"?"No Action":"Approved <br/>" +Eval("date","{0:dd-MMM-yyyy}")%>'></asp:Label>
                                                                        <asp:Button runat="server" ID="btn_approved" OnClick="btn_approved_Click" OnClientClick="return confirm('Are you sure want to approve this expense?');" Text="Not Approved" />
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField ItemStyle-Width="20">
                                                                    <ItemTemplate>
                                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>

                                                            </Columns>
                                                        </asp:GridView>

                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label20" runat="server" Text="Final Amount"></asp:Label>
                                                        <asp:Label ID="Label21" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label22" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_famount" CssClass="form-control" runat="server" Height="32px" Width="200px" onkeypress="return digit(event);" placeholder="Final Amount" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Final Amount
                                                        </div>

                                                    </div>


                                                </div>
                                            </div>


                                        </asp:Panel>
                                    </ContentTemplate>

                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                        <asp:AsyncPostBackTrigger ControlID="btn_confirm" EventName="Click" />
                                        <asp:AsyncPostBackTrigger ControlID="save" EventName="ServerClick" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>


                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button OnClientClick="disableSaveButtonIfValid();" ID="btn_save" type="button-submit" runat="server" Text="Save" OnClick="btn_save_Click" ValidationGroup="g1" class="btn btn-primary" />
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


                <div class="modal fade bs-example-modal-sm" id="emailmodal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content" style="height: auto; width: 300px;">
                            <div class="modal-header">

                                <h4 class="modal-title" id="gridSystemModalLabel1"><strong>Select Customer</strong></h4>
                            </div>
                            <asp:UpdatePanel ID="assd" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="modal-body">

                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-12">
                                                    <label>
                                                        Select all</label>
                                                    <asp:CheckBox ID="CheckAll" runat="server" AutoPostBack="true" OnCheckedChanged="CheckAll_CheckedChanged"></asp:CheckBox>
                                                </div>
                                            </div>
                                        </div>


                                        <div class="col-sm-12">
                                            <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false" OnRowDataBound="GridView2_RowDataBound" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" ShowHeader="false" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" GridLines="None">

                                                <Columns>

                                                    <asp:TemplateField HeaderText="user_id" Visible="false">
                                                        <ItemTemplate>
                                                            <asp:Label runat="server" ID="user_id" Text='<%# Bind("user_id")%>'></asp:Label>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>
                                                    <asp:TemplateField>
                                                        <ItemTemplate>
                                                            <asp:Label runat="server" ID="name" Text='<%# Bind("name")%>'></asp:Label>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>
                                                    <asp:TemplateField>
                                                        <ItemTemplate>
                                                            <asp:CheckBox runat="server" ID="chk" AutoPostBack="true" OnCheckedChanged="name_CheckedChanged"></asp:CheckBox>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>
                                                </Columns>
                                            </asp:GridView>

                                        </div>


                                    </div>
                                </ContentTemplate>
                            </asp:UpdatePanel>

                            <div class="modal-footer">
                                <div class="row">
                                    <div class="col-sm-6">
                                        <div class="pull-left">
                                            <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-default" data-dismiss="modal" />
                                        </div>
                                    </div>
                                    <div class="col-sm-6">
                                        <div class="pull-right">
                                            <asp:Button ID="btn_confirm" runat="server" Text="Confirm" OnClick="btn_confirm_Click" data-dismiss="modal" UseSubmitBehavior="false" class="btn btn-primary" />
                                        </div>
                                    </div>
                                </div>
                            </div>

                        </div>
                        <!-- /.modal-body -->
                    </div>
                    <!-- /.modal-content -->
                </div>

            </div>
        </div>
    </div>


    <!--  PDF Modal -->

    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Changed to modal-lg for better width -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Rental Details</strong></h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">

                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->

                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">

                        <asp:GridView ID="GridView4" runat="server"
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

                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" runat="server" Text='<%# Container.DataItemIndex + 1 %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField HeaderText="expense_id" DataField="expense_id" SortExpression="expense_id" Visible="false" />
                                <asp:BoundField HeaderText="Vendor Name" DataField="ex_name" SortExpression="ex_name" />
                                <asp:BoundField HeaderText="Expense Details" DataField="ex_details" SortExpression="ex_details" />
                                <asp:BoundField HeaderText="Date" DataField="date" SortExpression="date" DataFormatString="{0:dd-MM-yyyy}" HtmlEncode="false" ItemStyle-Width="150" />
                                <asp:BoundField HeaderText="Amount" DataField="f_amount" SortExpression="f_amount" />
                                <asp:BoundField HeaderText="Type" DataField="type" SortExpression="expense_status" />
                                <asp:BoundField HeaderText="Status" DataField="expense_status" SortExpression="expense_status" />



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

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">

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
                const title = "Society expenses Details "

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
                pdf.save("ExpensesReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
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
                    window.location.href = 'society_expense.aspx';
                }
            });
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

                //openModal();
            });
        }

        function openModal() {
            $('#edit_model').modal('show');
        }



        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
        }

        function printparkingDetails() {
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

    </script>
</asp:Content>



