<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="v_tax_payment.aspx.cs" Inherits="Society.waste_tax_v" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .nav-tabs {
            border-bottom: 2px solid #e0e0e0;
            margin-bottom: 30px;
        }

            .nav-tabs .nav-item {
                margin-right: 5px;
            }

            .nav-tabs .nav-link {
                border: none;
                border-bottom: 3px solid transparent;
                color: #666;
                font-weight: 500;
                padding: 12px 24px;
                background-color: transparent;
            }

                .nav-tabs .nav-link:hover {
                    border-bottom-color: #ccc;
                    background-color: transparent;
                }

                .nav-tabs .nav-link.active {
                    border-bottom-color: #2196F3;
                    color: #2196F3;
                    background-color: transparent;
                }

        /* Pending Bills Table */
        .table-container {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        .custom-table {
            margin-bottom: 0;
        }

            .custom-table thead th {
                background-color: #34495e;
                color: white;
                font-weight: 600;
                border: none;
                padding: 16px;
                text-align: left;
            }

            .custom-table tbody td {
                padding: 16px;
                vertical-align: middle;
                border-top: 1px solid #e0e0e0;
            }

            .custom-table tbody tr:hover {
                background-color: #f8f9fa;
            }

        .tax-link {
            color: #2196F3;
            cursor: pointer;
            text-decoration: none;
            font-weight: 500;
        }

            .tax-link:hover {
                color: #1976D2;
                text-decoration: underline;
            }

        .btn-pay-all {
            background-color: #27ae60;
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 4px;
            font-weight: 500;
            transition: all 0.3s;
        }

            .btn-pay-all:hover {
                background-color: #229954;
                color: white;
                transform: translateY(-1px);
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

        /* Paid Houses Table */
        .paid-table thead th {
            background-color: #34495e;
            color: white;
            font-weight: 600;
            border: none;
            padding: 16px;
        }

        .paid-table tbody td {
            padding: 16px;
            vertical-align: middle;
            border-top: 1px solid #e0e0e0;
        }

        .paid-table tbody tr:hover {
            background-color: #f8f9fa;
        }

        .btn-receipt {
            background-color: #00bcd4;
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 4px;
            font-weight: 500;
            transition: all 0.3s;
        }

            .btn-receipt:hover {
                background-color: #0097a7;
                color: white;
                transform: translateY(-1px);
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }

        /* Tax Items Modal */
        .modal-header {
            background-color: #f8f9fa;
            border-bottom: 2px solid #e0e0e0;
        }

        .modal-title {
            color: #34495e;
            font-weight: 600;
            font-size: 1.25rem;
        }

        .modal-body {
            padding: 30px;
        }

        /* Tax Items Checklist */
        .tax-items-list {
            max-height: 400px;
            overflow-y: auto;
            padding: 10px 0;
        }

        .tax-item {
            padding: 15px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            margin-bottom: 12px;
            background-color: #f8f9fa;
            transition: all 0.2s;
            cursor: pointer;
        }

            .tax-item:hover {
                background-color: #e9ecef;
                border-color: #bbb;
            }

            .tax-item.selected {
                background-color: #e3f2fd;
                border-color: #2196F3;
            }

            .tax-item label {
                margin-bottom: 0;
                cursor: pointer;
                display: flex;
                align-items: center;
                font-weight: 500;
                width: 100%;
            }

            .tax-item input[type="checkbox"] {
                width: 22px;
                height: 22px;
                margin-right: 15px;
                cursor: pointer;
            }

        .tax-item-text {
            flex: 1;
            font-size: 1rem;
            color: #34495e;
        }

        .tax-item-amount {
            font-size: 1.1rem;
            font-weight: 600;
            color: #27ae60;
            margin-left: 10px;
        }

        .total-section {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            margin-top: 20px;
            border: 2px solid #e0e0e0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

            .total-section .total-label {
                font-size: 1.2rem;
                font-weight: 600;
                color: #34495e;
            }

            .total-section .total-amount {
                font-size: 1.5rem;
                font-weight: 700;
                color: #27ae60;
            }

        .modal-footer {
            border-top: 2px solid #e0e0e0;
            padding: 20px 30px;
        }

        .btn-pay-modal {
            background-color: #27ae60;
            color: white;
            border: none;
            padding: 10px 30px;
            border-radius: 4px;
            font-weight: 500;
        }

            .btn-pay-modal:hover {
                background-color: #229954;
                color: white;
            }

        .btn-close-modal {
            background-color: #6c757d;
            color: white;
            border: none;
            padding: 10px 30px;
            border-radius: 4px;
        }

            .btn-close-modal:hover {
                background-color: #5a6268;
                color: white;
            }

        /* Receipt Modal */
        .receipt-modal .modal-dialog {
            max-width: 600px;
        }

        .receipt-content {
            padding: 40px;
        }

        .receipt-header {
            text-align: center;
            border-bottom: 2px solid #34495e;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }

            .receipt-header h4 {
                color: #34495e;
                font-weight: 700;
                margin-bottom: 10px;
            }

            .receipt-header p {
                color: #7f8c8d;
                margin: 0;
            }

        .receipt-details {
            margin-bottom: 30px;
        }

        .receipt-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #e0e0e0;
        }

            .receipt-row:last-child {
                border-bottom: none;
            }

        .receipt-label {
            font-weight: 600;
            color: #34495e;
        }

        .receipt-value {
            color: #555;
            text-align: right;
        }

        .receipt-total {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            margin-top: 30px;
            text-align: center;
        }

            .receipt-total .label {
                font-size: 1.1rem;
                font-weight: 600;
                color: #34495e;
                margin-bottom: 10px;
            }

            .receipt-total .amount {
                font-size: 2rem;
                font-weight: 700;
                color: #27ae60;
            }

        .receipt-footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
            font-style: italic;
            color: #7f8c8d;
        }

        .btn-print {
            background-color: #2196F3;
            color: white;
            border: none;
            padding: 10px 30px;
            border-radius: 4px;
            font-weight: 500;
        }

            .btn-print:hover {
                background-color: #1976D2;
                color: white;
            }

        /* Modal Dialog */
        .pay-modal-dialog {
            max-width: 600px;
            margin: 1.75rem auto;
        }

        .pay-modal-content {
            border: none;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
        }

        /* Modal Header */
        .pay-modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 12px 12px 0 0;
            padding: 20px 24px;
            border-bottom: none;
        }

        .pay-modal-title {
            font-size: 1.25rem;
            font-weight: 600;
            margin: 0;
            color: white;
        }

        .pay-close-btn {
            color: white;
            opacity: 0.9;
            font-size: 1.5rem;
            font-weight: 300;
            text-shadow: none;
            padding: 0;
            background: transparent;
            border: none;
            cursor: pointer;
        }

            .pay-close-btn:hover {
                opacity: 1;
            }

        /* Modal Body */
        .pay-modal-body {
            padding: 24px;
            max-height: calc(100vh - 250px);
            overflow-y: auto;
        }

        /* Section Styling */
        .pay-section {
            margin-bottom: 24px;
        }

        .pay-section-title {
            font-size: 0.95rem;
            font-weight: 600;
            color: #2d3748;
            margin-bottom: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        /* Items Container - Scrollable */
        .pay-items-container {
            max-height: 250px;
            overflow-y: auto;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 8px;
            background: #f8fafc;
        }

            /* Custom Scrollbar */
            .pay-items-container::-webkit-scrollbar {
                width: 8px;
            }

            .pay-items-container::-webkit-scrollbar-track {
                background: #f1f1f1;
                border-radius: 4px;
            }

            .pay-items-container::-webkit-scrollbar-thumb {
                background: #cbd5e0;
                border-radius: 4px;
            }

                .pay-items-container::-webkit-scrollbar-thumb:hover {
                    background: #a0aec0;
                }

        /* Individual Items */
        .pay-item {
            background: white;
            border: 2px solid #e2e8f0;
            border-radius: 6px;
            margin-bottom: 8px;
            transition: all 0.2s ease;
        }

            .pay-item:last-child {
                margin-bottom: 0;
            }

            .pay-item:hover {
                border-color: #667eea;
                box-shadow: 0 2px 8px rgba(102, 126, 234, 0.1);
            }

        .pay-item-label {
            display: flex;
            align-items: center;
            padding: 12px;
            margin: 0;
            cursor: pointer;
            width: 100%;
        }

        .pay-checkbox {
            width: 18px;
            height: 18px;
            margin-right: 12px;
            cursor: pointer;
            flex-shrink: 0;
            accent-color: #667eea;
        }

        .pay-item-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex: 1;
        }

        .pay-item-text {
            font-size: 0.95rem;
            color: #2d3748;
            flex: 1;
        }

        .pay-item-amount {
            font-weight: 600;
            color: #667eea;
            font-size: 1rem;
            margin-left: 12px;
        }

        /* Form Elements */
        .pay-form-group {
            margin-bottom: 16px;
        }

        .pay-label {
            display: block;
            font-size: 0.9rem;
            font-weight: 500;
            color: #4a5568;
            margin-bottom: 6px;
        }

        .pay-required {
            color: #e53e3e;
        }

        .pay-select,
        .pay-input {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #cbd5e0;
            border-radius: 6px;
            font-size: 0.95rem;
            transition: border-color 0.2s ease;
        }

            .pay-select:focus,
            .pay-input:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

        .pay-textarea {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #cbd5e0;
            border-radius: 6px;
            font-size: 0.95rem;
            resize: vertical;
            font-family: inherit;
            transition: border-color 0.2s ease;
        }

            .pay-textarea:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

        /* Total Section */
        .pay-total-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: linear-gradient(135deg, #f6f8fb 0%, #eef2f7 100%);
            padding: 16px 20px;
            border-radius: 8px;
            border: 2px solid #667eea;
            margin-top: 20px;
        }

        .pay-total-label {
            font-size: 1.1rem;
            font-weight: 600;
            color: #2d3748;
        }

        .pay-total-amount {
            font-size: 1.5rem;
            font-weight: 700;
            color: #667eea;
        }

        /* Modal Footer */
        .pay-modal-footer {
            padding: 16px 24px;
            border-top: 1px solid #e2e8f0;
            background: #f8fafc;
            border-radius: 0 0 12px 12px;
        }

        /* Buttons */
        .pay-btn-secondary {
            background: white;
            color: #4a5568;
            border: 1px solid #cbd5e0;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            transition: all 0.2s ease;
        }

            .pay-btn-secondary:hover {
                background: #f7fafc;
                border-color: #a0aec0;
            }

        .pay-btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            transition: all 0.2s ease;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }

            .pay-btn-primary:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
            }

        /* Responsive Design */
        @media (max-width: 576px) {
            .pay-modal-dialog {
                margin: 0.5rem;
                max-width: calc(100% - 1rem);
            }

            .pay-modal-body {
                padding: 16px;
            }

            .pay-items-container {
                max-height: 200px;
            }

            .pay-item-text {
                font-size: 0.85rem;
            }

            .pay-item-amount {
                font-size: 0.9rem;
            }
        }

        .select-cell {
            cursor: pointer;
            padding: 6px 10px;
        }

            .select-cell input[type="checkbox"] {
                pointer-events: none; /* prevents blocking click on container */
            }
    </style>

    <body>
        <asp:HiddenField ID="hfActiveTab" runat="server" Value="#pending" />

        <table width="100%">
            <tr>
                <th width="100%" class="">
                    <h1 class=" tex0 font-weight-bold " style="color: #012970;">Tax Payments
                    </h1>
                </th>
            </tr>
        </table>

        <div class="form-group ">
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

                    </div>
                </div>
            </div>
        </div>

        <div class="container-fluid">


            <ul class="nav nav-tabs">
                <li class="nav-item">
                    <a class="nav-link active" data-toggle="tab" href="#pending" onclick="setActiveTab('#pending')">Pending Bills</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" data-toggle="tab" href="#paid" onclick="setActiveTab('#paid')">Paid Bills</a>
                </li>
            </ul>

            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                <ContentTemplate>

                    <div class="tab-content">
                        <!-- Pending Bills Tab -->
                        <div id="pending" class="tab-pane active">
                            <div style="width: 100%; overflow: visible;" class="table-container">
                                <asp:GridView ID="gvPending"
                                    runat="server"
                                    AutoGenerateColumns="false"
                                    CssClass="table table-striped table-bordered"
                                    ShowHeaderWhenEmpty="true" 
                                    EmptyDataText="No Record Found" 
                                    AllowSorting="true"
                                    OnRowCommand="gvPending_RowCommand"
                                    OnSorting="gvPending_Sorting"                                   
                                    GridLines="None">
                                    <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                    <Columns>
                                        <asp:TemplateField HeaderText="Name" SortExpression="owner_name">
                                            <ItemTemplate>
                                                <asp:Label ID="owner_name" runat="server" Text='<%# Eval("owner_name") %>'></asp:Label>                                              
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="House No" SortExpression="house_no">
                                            <ItemTemplate>
                                                <asp:Label ID="house_no" runat="server" Text='<%# Eval("house_no") %>'></asp:Label>                                              
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Water Tax" SortExpression="pending_water_charges">
                                            <ItemTemplate>
                                                <asp:LinkButton ID="lnkWater" runat="server" Text='<%# Eval("pending_water_charges", "₹{0:N2}") %>' CommandName="ViewWater" CommandArgument='<%# Eval("house_id") %>' CssClass="tax-link" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Property Tax" SortExpression="pending_property_tax">
                                            <ItemTemplate>
                                                <asp:LinkButton ID="lnkProperty" runat="server" Text='<%# Eval("pending_property_tax", "₹{0:N2}") %>' CommandName="ViewProperty" CommandArgument='<%# Eval("house_id") %>' CssClass="tax-link" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Waste Tax" SortExpression="pending_waste_charges">
                                            <ItemTemplate>
                                                <asp:LinkButton ID="lnkWaste" runat="server" Text='<%# Eval("pending_waste_charges", "₹{0:N2}") %>' CommandName="ViewWaste" CommandArgument='<%# Eval("house_id") %>' CssClass="tax-link" />
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:TemplateField HeaderText="Select">
                                            <HeaderTemplate>
                                                <div class="select-cesll" style="padding: 6px 10px;">
                                                    <input type="checkbox" id="chkSelectAll" />
                                                    Select

                                                </div>
                                            </HeaderTemplate>

                                            <ItemTemplate>
                                                <div class="select-cell">
                                                    <asp:CheckBox ID="chkSelect" runat="server" />
                                                    <asp:HiddenField ID="hfOwner" Value='<%# Eval("owner_name") %>' runat="server" />
                                                    <asp:HiddenField ID="hfMobile" Value='<%# Eval("pre_mob") %>' runat="server" />

                                                    <asp:HiddenField ID="hfWater" Value='<%# Eval("pending_water_charges") %>' runat="server" />
                                                    <asp:HiddenField ID="hfProperty" Value='<%# Eval("pending_property_tax") %>' runat="server" />
                                                    <asp:HiddenField ID="hfWaste" Value='<%# Eval("pending_waste_charges") %>' runat="server" />
                                                </div>
                                            </ItemTemplate>
                                        </asp:TemplateField>



                                <%--                                        <asp:TemplateField HeaderText="Total Pending" SortExpression="TotalPending">
                                            <ItemTemplate>
                                                <%# Eval("TotalPending", "₹{0:N2}") %>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Action">
                                            <ItemTemplate>
                                                <asp:Button ID="btnPayAll" runat="server" Text="Pay All" CssClass="btn btn-pay-all" CommandName="PayAll" CommandArgument='<%# Eval("Name") %>' />
                                            </ItemTemplate>
                                        </asp:TemplateField>--%>
                            </Columns>
                        </asp:GridView>

                        <%--  </ContentTemplate>
                        </asp:UpdatePanel>--%>
                    </div>
                <asp:Button ID="btnSendSMS" 
                    runat="server"
                    Text="Send SMS"
                    CssClass="btn btn-primary mt-3"
                    OnClick="btnSendSMS_Click"
                    OnClientClick="return validateSelection();" />
                </div>


                <!-- Paid Houses Tab -->
                <div id="paid" class="tab-pane">
                    <div style="width: 100%; overflow: visible;" class="table-container">
                        <asp:GridView ID="gvPaid" runat="server" AutoGenerateColumns="false" CssClass="table table-striped table-bordered" AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="gvPaid_Sorting"  OnRowCommand="gvPaid_RowCommand" GridLines="None">
                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                            <Columns>
                                <asp:TemplateField HeaderText="Owner Name" SortExpression="name">
                                    <ItemTemplate>
                                        <asp:Label ID="name" runat="server" Text='<%# Eval("name") %>'></asp:Label>                                   
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="House Number" SortExpression="house_no">
                                    <ItemTemplate>
                                        <asp:Label ID="house_no" runat="server" Text=' <%# Eval("house_no") %>'></asp:Label>                                
                                    </ItemTemplate>
                                </asp:TemplateField>                                
                                <asp:TemplateField HeaderText="Bill Type" SortExpression="payment_type_name">
                                    <ItemTemplate>
                                        <asp:Label ID="payment_type_name" runat="server" Text='<%# Eval("payment_type_name") %>'></asp:Label>                                      
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Total Tax"  SortExpression="Amount_paid">
                                    <ItemTemplate>
                                        <asp:Label ID="Amount_paid" runat="server" Text='<%# Eval("Amount_paid", "₹{0:N2}") %>'></asp:Label>                                     
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Payment Date"  SortExpression="pay_date">
                                    <ItemTemplate>
                                        <asp:Label ID="pay_date" runat="server" Text='<%# Eval("pay_date", "{0:MM-dd-yyyy}") %>'></asp:Label>                                      
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Payment Method"  SortExpression="pay_mode">
                                    <ItemTemplate>
                                        <asp:Label ID="pay_mode" runat="server" Text='<%# Eval("pay_mode") %>'></asp:Label>                                       
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Action">
                                    <ItemTemplate>
                                        <asp:Button ID="btnReceipt" runat="server" Text="Receipt" CssClass="btn btn-receipt" CommandName="ViewReceipt" CommandArgument='<%# Eval("house_receipt_id") %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
                     </ContentTemplate>
        
                    </asp:UpdatePanel>

        </div>

        <!-- Tax Items Modal (for individual tax types) -->
        <div class="modal fade" id="taxModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg pay-modal-dialog" role="document">
                <div class="modal-content pay-modal-content">
                    <div class="modal-header pay-modal-header">
                        <h5 class="modal-title pay-modal-title">
                            <asp:Label ID="lblModalTitle" runat="server" />
                        </h5>
                        <button type="button" class="close pay-close-btn" data-dismiss="modal">
                            <span>&times;</span>
                        </button>
                    </div>
                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>

                            <div class="modal-body pay-modal-body">
                                <!-- Tax Items Section with Scrollable Checkboxes -->
                                <div class="pay-section">
                                    <h6 class="pay-section-title">Select Items to Pay</h6>
                                    <div class="pay-items-container">
                                        <asp:Repeater ID="rptModalItems" runat="server">
                                            <ItemTemplate>
                                                <div class="pay-item">
                                                    <label class="pay-item-label">
                                                        <input type="checkbox" class="pay-checkbox" name="selectedItems" value='<%# Eval("house_receipt_id") %>' data-amount='<%# Eval("pending_amount") %>' onchange="updateTotal()" />
                                                        <span class="pay-item-content">
                                                            <span class="pay-item-text"><%# Eval("month")+" "+Eval("year") %></span>
                                                            <span class="pay-item-amount"><%# Eval("pending_amount", "₹{0:N2}") %></span>
                                                        </span>
                                                    </label>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </div>

                                <!-- Total Section -->

                                <!-- Payment Details Section -->
                                <div class="pay-section">
                                    <div class="pay-total-section mb-2">
                                        <span class="pay-total-label">Total Amount:</span>
                                        <span class="pay-total-amount">₹<span id="spanTotal">0.00</span></span>
                                    </div>

                                    <!-- Payment Method -->
                                    <div class="pay-form-group">
                                        <label class="pay-label">Payment Method <span class="pay-required">*</span></label>
                                        <asp:DropDownList ID="ddlPaymentMethod" runat="server" CssClass="pay-select" onchange="toggleTransactionRef()">
                                            <asp:ListItem Value="1" Selected="True">Cash</asp:ListItem>
                                            <asp:ListItem Value="4">UPI</asp:ListItem>
                                            <asp:ListItem Value="2">Cheque</asp:ListItem>
                                        </asp:DropDownList>
                                    </div>

                                    <!-- Transaction Reference (Hidden by default for Cash) -->
                                    <div class="pay-form-group" id="divTransactionRef" style="display: none;">
                                        <label class="pay-label">Transaction Reference <span class="pay-required">*</span></label>
                                        <asp:TextBox ID="txtTransactionRef" runat="server" CssClass="pay-input" placeholder="Enter transaction/reference number" MaxLength="50" />
                                    </div>

                                    <div id="divCheque" style="display: none;">

                                        <div class="pay-form-group">
                                            <label class="pay-label ">Cheque No.<span class="pay-required">*</span></label>
                                            <asp:TextBox ID="chequeNo" runat="server" CssClass="pay-input" placeholder="Enter Cheque number" MaxLength="50" />
                                        </div>
                                        <div class="pay-form-group">
                                            <label class="pay-label ">Cheque Date<span class="pay-required">*</span></label>
                                            <asp:TextBox ID="chequeDate" runat="server" CssClass="pay-input" placeholder="Enter cheque Date" MaxLength="50" TextMode="Date" />
                                        </div>

                                    </div>

                                    <!-- Remarks -->
                                    <div class="pay-form-group">
                                        <label class="pay-label">Remarks</label>
                                        <asp:TextBox ID="txtRemarks" runat="server" CssClass="pay-textarea" TextMode="MultiLine" Rows="3" placeholder="Add any additional notes (optional)" MaxLength="500" />
                                    </div>
                                </div>


                            </div>

                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger EventName="RowCommand" ControlID="gvPending" />
                        </Triggers>
                    </asp:UpdatePanel>
                    <div class="modal-footer pay-modal-footer">
                        <button type="button" class="btn pay-btn-secondary" data-dismiss="modal">Cancel</button>
                        <asp:Button ID="btnPayModal" runat="server" Text="Process Payment" CssClass="btn pay-btn-primary" OnClick="btnPayModal_Click" />
                    </div>
                </div>
            </div>
        </div>
        <!-- Receipt Modal -->
        <div class="modal fade receipt-modal" id="receiptModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Payment Receipt</h5>
                        <button type="button" class="close" data-dismiss="modal">
                            <span>&times;</span>
                        </button>
                    </div>
                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>


                            <div class="modal-body">
                                <div class="receipt-content" id="printableReceipt">
                                    <div class="receipt-header">
                                        <h4><span>
                                            <asp:Label runat="server" Style="color: #34495e; font-weight: 700; margin-bottom: 10px;"
                                                ID="lblTaxType"></asp:Label></span> Tax Payment Receipt</h4>
                                        <p>Tax Management Department</p>
                                    </div>
                                    <div class="receipt-details">
                                        <div class="receipt-row">
                                            <span class="receipt-label">Receipt No:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptNo" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row">
                                            <span class="receipt-label">Date:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptDate" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row">
                                            <span class="receipt-label">Owner Name:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptOwner" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row">
                                            <span class="receipt-label">House Number:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptHouse" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row" runat="server">
                                            <span class="receipt-label">Payment Method:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptMethod" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row" id="divTran" runat="server">
                                            <span class="receipt-label">Transaction Reference:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblReceiptTxn" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row" id="divChequeNo" runat="server">
                                            <span class="receipt-label">Cheque No</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblChequeNoTxn" runat="server" />
                                            </span>
                                        </div>
                                        <div class="receipt-row" id="divChequeDate" runat="server">
                                            <span class="receipt-label">Cheque Date:</span>
                                            <span class="receipt-value">
                                                <asp:Label ID="lblChequeDateTxn" runat="server" />
                                            </span>
                                        </div>
                                    </div>
                                    <div class="receipt-total">
                                        <div class="label">Total Amount Paid:</div>
                                        <div class="amount">
                                            <asp:Label ID="lblReceiptAmount" runat="server" />
                                        </div>
                                    </div>
                                    <div class="receipt-footer">
                                        Thank you for your payment!
                                    </div>
                                </div>
                            </div>
                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger EventName="RowCommand" ControlID="gvPaid" />
                        </Triggers>
                    </asp:UpdatePanel>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-close-modal" data-dismiss="modal">Close</button>
                        <button type="button" class="btn btn-print" onclick="printReceipt()">Print Receipt</button>
                    </div>
                </div>
            </div>
        </div>

        <asp:HiddenField ID="hfUser" runat="server" />
        <asp:HiddenField ID="hfTaxType" runat="server" />
        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
        <script type="text/javascript">
            function triggerSearch() {
                    var btn = document.getElementById('btn_search');
            if (btn) {
                btn.click();   
                }
            }

            function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
            if (!input) return;

            const filter = input.value.toLowerCase();
            const table = document.querySelector('.table-container table');

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
            

            function setActiveTab(tab) {
                document.getElementById('<%= hfActiveTab.ClientID %>').value = tab;
            }

            // Restore active tab after postback
            function restoreActiveTab() {
                var activeTab = document.getElementById('<%= hfActiveTab.ClientID %>').value || '#pending';

                // Remove all active classes
                $('.nav-tabs .nav-link').removeClass('active');
                $('.tab-pane').removeClass('active show');

                // Add active class to the correct tab
                $('.nav-tabs a[href="' + activeTab + '"]').addClass('active');
                $(activeTab).addClass('active show');
            }

            // Execute on page load
            $(document).ready(function () {
                restoreActiveTab();
            });
            

            // Execute after UpdatePanel async postback
            var prm = Sys.WebForms.PageRequestManager.getInstance();
            prm.add_endRequest(function () {
                restoreActiveTab();
            });


            // 1. Select All behavior
            $(document).on("change", "#chkSelectAll", function () {
                let checked = $(this).prop("checked");
                $("input[id*='chkSelect']").prop("checked", checked);
            });

            // 2. Make the whole cell clickable
            $(document).on("click", ".select-cell", function (e) {
                // avoid double toggle when clicking directly on checkbox
                if ($(e.target).is("input[type='checkbox']")) return;

                let chk = $(this).find("input[type='checkbox']");
                chk.prop("checked", !chk.prop("checked"));
            });


            function validateSelection() {
                var checkboxes = document.querySelectorAll("#<%= gvPending.ClientID %>input[type='checkbox']");
                var anySelected = false;

                checkboxes.forEach(function (cb) {
                    if (cb.checked) anySelected = true;
                });

                if (!anySelected) {
                    alert("Please select at least one user.");
                    return false; // stops postback
                }

                return true; // allow postback
            }



            function updateTotal() {
                var checkboxes = document.querySelectorAll('.pay-checkbox:checked');
                var total = 0;

                checkboxes.forEach(function (checkbox) {
                    var amount = parseFloat(checkbox.getAttribute('data-amount')) || 0;
                    total += amount;
                });

                document.getElementById('spanTotal').textContent = total.toFixed(2);
            }

            function toggleTransactionRef() {
                var paymentMethod = document.getElementById('<%= ddlPaymentMethod.ClientID %>').value;
                var transactionRefDiv = document.getElementById('divTransactionRef');
                var chequeDiv = document.getElementById('divCheque');

                transactionRefDiv.style.display = 'none';
                chequeDiv.style.display = 'none';

                if (paymentMethod === '4') {
                    transactionRefDiv.style.display = 'block';
                } else if (paymentMethod === '2') {
                    chequeDiv.style.display = 'block';
                }
            }

            // Re-apply after UpdatePanel refresh
            var prm = Sys.WebForms.PageRequestManager.getInstance();
            prm.add_endRequest(function () {
                // Reattach event handler after partial postback
                var dropdown = document.getElementById('<%= ddlPaymentMethod.ClientID %>');
                if (dropdown) {
                    dropdown.onchange = toggleTransactionRef;
                }
            });

            // Initialize on page load
            document.addEventListener('DOMContentLoaded', function () {
                updateTotal();
                toggleTransactionRef();
            });

            function toggleCheckbox(element) {
                var checkbox = element.querySelector('input[type="checkbox"]');
                checkbox.checked = !checkbox.checked;
                updateTotal();
                updateItemStyle(element, checkbox.checked);
            }

            function updateItemStyle(element, isSelected) {
                if (isSelected) {
                    element.classList.add('selected');
                } else {
                    element.classList.remove('selected');
                }
            }

            function updateTotal() {
                var total = 0;
                $('.modal input[type="checkbox"]:checked').each(function () {
                    total += parseFloat($(this).data('amount')) || 0;
                });
                $('#spanTotal').text(total.toFixed(2));
            }

            $(document).ready(function () {
                $('.modal input[type="checkbox"]').change(function () {
                    updateTotal();
                    updateItemStyle($(this).closest('.tax-item')[0], this.checked);
                });
            });

            function printReceipt() {
                var content = document.getElementById('printableReceipt').innerHTML;
                var printWindow = window.open('', '', 'height=600,width=800');
                printWindow.document.write('<html><head><title>Receipt</title>');
                printWindow.document.write('<style>');
                printWindow.document.write('body { font-family: Arial, sans-serif; padding: 40px; }');
                printWindow.document.write('.receipt-header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; margin-bottom: 30px; }');
                printWindow.document.write('.receipt-row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #ddd; }');
                printWindow.document.write('.receipt-total { background-color: #f8f9fa; padding: 20px; margin-top: 30px; text-align: center; }');
                printWindow.document.write('.receipt-total .amount { font-size: 2rem; font-weight: bold; color: #27ae60; }');
                printWindow.document.write('.receipt-footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 2px solid #333; font-style: italic; }');
                printWindow.document.write('</style>');
                printWindow.document.write('</head><body>');
                printWindow.document.write(content);
                printWindow.document.write('</body></html>');
                printWindow.document.close();
                printWindow.print();
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
                        window.location.href = 'v_tax_payment.aspx';
                    }
                });
            }


        </script>
    </body>
</asp:Content>
