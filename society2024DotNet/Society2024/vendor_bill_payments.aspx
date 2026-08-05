<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="vendor_bill_payments.aspx.cs" Inherits="Society.VendorBillPayments" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <%--    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />--%>
    <style>
        /* Modal Backdrop */
        .SB-modal-backdrop {
            background: rgba(0, 0, 0, 0.5);
        }

        /* Modal Container */
        .SB-payment-summary-modal .modal-content {
            border-radius: 12px;
            border: none;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
            overflow: hidden;
        }

        /* Modal Header - Purple Gradient */
        .SB-payment-summary-modal .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 24px;
            border: none; 
        }

        .SB-payment-summary-modal .modal-title {
            font-size: 18px;
            font-weight: 600;
            color: white;
            display: flex;
            align-items: center;
            gap: 10px;
        }

            .SB-payment-summary-modal .modal-title i {
                font-size: 20px;
            }

        .SB-payment-summary-modal .close {
            color: white;
            opacity: 0.9;
            text-shadow: none;
            font-size: 28px;
            font-weight: 300;
        }

            .SB-payment-summary-modal .close:hover {
                opacity: 1;
                color: white;
            }

        /* Modal Body */
        .SB-payment-summary-modal .modal-body {
            padding: 24px;
            background: #f8f9fa;
        }

        /* Section Headers */
        .SB-section-header {
            font-size: 14px;
            font-weight: 600;
            color: #333;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

            .SB-section-header::before {
                content: '';
                width: 4px;
                height: 18px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 2px;
            }

        /* Info Cards */
        .SB-info-card {
            background: white;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            border: 0.5px solid #0000802e;
        }

        .SB-info-row {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 12px;
        }

            .SB-info-row:last-child {
                margin-bottom: 0;
            }

        .SB-info-item {
            flex: 1;
            min-width: 200px;
        }

        .SB-info-label {
            font-size: 12px;
            color: #666;
            font-weight: 500;
            margin-bottom: 4px;
            display: block;
        }

        .SB-info-value {
            font-size: 14px;
            color: #333;
            font-weight: 500;
        }

        /* GridView Styling */
        .SB-bills-table {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            margin-bottom: 16px;
            border: 0.5px solid #0000802e;
        }

            .SB-bills-table table {
                margin: 0;
            }

            .SB-bills-table th {
                background: #f8f9fa;
                color: #555;
                font-size: 13px;
                font-weight: 600;
                padding: 12px 16px;
                border: none;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .SB-bills-table td {
                padding: 14px 16px;
                font-size: 14px;
                color: #333;
                border-bottom: 1px solid #f0f0f0;
            }

            .SB-bills-table tr:last-child td {
                border-bottom: none;
            }

        /* Total Amount */
        .SB-total-amount {
            background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
            border-radius: 8px;
            padding: 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }

        .SB-total-label {
            font-size: 14px;
            font-weight: 600;
            color: #555;
        }

        .SB-total-value {
            font-size: 20px;
            font-weight: 700;
            color: #667eea;
        }

        /* Divider */
        .SB-divider {
            border: none;
            height: 1px;
            background: #e0e0e0;
            margin: 24px 0;
        }

        /* Modal Footer */
        .SB-payment-summary-modal .modal-footer {
            background: white;
            border-top: 1px solid #e0e0e0;
            padding: 16px 24px;
        }

        /* Buttons */
        .SB-btn-back {
            background: white;
            border: 2px solid #e0e0e0;
            color: #666;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.3s ease;
        }

            .SB-btn-back:hover {
                background: #f8f9fa;
                border-color: #ccc;
                color: #333;
            }

        .SB-btn-confirm {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            color: white;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }

            .SB-btn-confirm:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
                color: white;
            }

        /* Responsive */
        @media (max-width: 768px) {
            .SB-info-item {
                min-width: 100%;
            }

            .SB-payment-summary-modal .modal-body {
                padding: 16px;
            }

            .SB-total-amount {
                flex-direction: column;
                gap: 8px;
                text-align: center;
            }
        }

        .vBill-container {
            display: flex;
            flex-direction: column;
            gap: 12px;
            font-family: "Segoe UI", sans-serif;
        }

        .vBill-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1.8px solid #dcdcdc;
            border-radius: 10px;
            padding: 14px 16px;
            cursor: pointer;
            background-color: #fff;
            transition: all 0.2s ease;
        }

            .vBill-item:hover {
                border-color: #6b8afd;
            }

            .vBill-item.vBill-selected {
                border-color: #6b8afd;
                background-color: #f5f7ff;
            }

        .vBill-left {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .vBill-header {
            font-weight: 600;
            color: #001f52;
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 15px;
        }

        .vBill-due {
            color: #777;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .vBill-right {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .vBill-count {
            background-color: #fff3cd;
            color: #856404;
            padding: 4px 8px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 600;
        }

        .vBill-amount {
            font-weight: bold;
            color: #001f52;
            font-size: 15px;
        }

        .vBill-check {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            background-color: #e8ebf0;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            transition: all 0.2s ease;
        }

        .vBill-item.vBill-selected .vBill-check {
            background-color: #4e73df;
        }


        /*        ----------------------------------------------------------------------------------------------*/
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }

        .card-header {
            background-color: #667eea;
            color: white;
            border-radius: 15px 15px 0 0 !important;
            padding: 15px 20px;
        }



        .bill-item {
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 10px;
            transition: all 0.3s;
        }

            .bill-item:hover {
                border-color: #667eea;
                background: #fff;
            }

            .bill-item.selected {
                border-color: #667eea;
                background: #e7f3ff;
            }

        .total-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
        }

        .gridview-container {
            overflow-x: auto;
        }

/*        .table {
            background: white;
        }*/

            .table thead {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }

        .cheque-details {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-top: 15px;
        }

        .form-label {
            font-weight: 600;
            color: #495057;
        }

        /* Modern Modal Styling */
        .before-i-color {
            color: #e9ecef;
        }

        .after-i-color {
            color: #012970;
        }



        .gradient-header .btn-close {
            filter: brightness(0) invert(1);
            opacity: 0.9;
        }

            .gradient-header .btn-close:hover {
                opacity: 1;
            }


        /* Form Sections */
        .form-section {
            background: white;
            border-radius: 12px;
            border: 0.5px solid #00000024;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgb(102 126 234 / 10%);
        }

        .section-header {
            display: flex;
            align-items: center;
            font-size: 1.1rem;
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 20px;
            padding-bottom: 12px;
            border-bottom: 2px solid #e9ecef;
        }

            .section-header i {
                color: #667eea;
                margin-right: 10px;
                font-size: 1.2rem;
            }


        .modern-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.15);
        }

        /* Bills Container */
        .bills-container {
            max-height: 400px;
            overflow-y: auto;
            padding: 5px;
        }

            .bills-container::-webkit-scrollbar {
                width: 8px;
            }

            .bills-container::-webkit-scrollbar-track {
                background: #f1f1f1;
                border-radius: 10px;
            }

            .bills-container::-webkit-scrollbar-thumb {
                background: #667eea;
                border-radius: 10px;
            }

        /* Bill Items */
        .bill-item {
            display: block;
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 12px;
            transition: all 0.3s ease;
            text-decoration: none;
            color: inherit;
            position: relative;
            overflow: hidden;
        }

            .bill-item:hover {
                border-color: #667eea;
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
            }

            .bill-item.selected {
                border-color: #667eea;
                background: linear-gradient(135deg, #f8f9ff 0%, #f0f2ff 100%);
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
            }

        .bill-content {
            display: flex;
            flex-direction: column;
            padding-right: 40px;
        }

        .bill-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }

        .bill-number {
            font-weight: 600;
            color: #2c3e50;
            font-size: 1rem;
        }

        .bill-status {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

            .bill-status.pending {
                background: #fff3cd;
                color: #856404;
            }

            .bill-status.overdue {
                background: #f8d7da;
                color: #721c24;
            }

        .bill-details {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .bill-info {
            display: flex;
            gap: 10px;
        }

        .bill-amount {
            font-size: 1.2rem;
            font-weight: 700;
            color: #667eea;
        }

        .selection-indicator {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 1.5rem;
            color: #e9ecef;
            transition: all 0.3s ease;
        }

        .bill-item.selected .selection-indicator {
            color: #667eea;
            transform: translateY(-50%) scale(1.2);
        }

        /* Total Card */
        .total-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            color: white;
            margin-top: 20px;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .total-label {
            font-size: 1.1rem;
            font-weight: 500;
        }

        .total-amount {
            font-size: 2rem;
            font-weight: 700;
        }

        /* Payment Mode Buttons */
        .payment-mode-buttons {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }

        .payment-btn {
            width: -webkit-fill-available;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
            border: 2px solid #e9ecef;
            border-radius: 12px;
            background: white;
            transition: all 0.3s ease;
            text-decoration: none;
            color: #6c757d;
            cursor: pointer;
        }

            .payment-btn:hover {
                border-color: #667eea;
                transform: translateY(-3px);
                box-shadow: 0 6px 20px rgba(102, 126, 234, 0.15);
                color: #667eea;
            }

            .payment-btn.active {
                border-color: #667eea;
                background: linear-gradient(135deg, #f8f9ff 0%, #f0f2ff 100%);
                color: #667eea;
                box-shadow: 0 4px 15px rgba(102, 126, 234, 0.2);
            }

        .payment-btn-content {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
        }

            .payment-btn-content i {
                font-size: 2rem;
            }

            .payment-btn-content span {
                font-weight: 600;
                font-size: 1rem;
            }

        /* Modern Inputs */
        .modern-label {
            display: flex;
            align-items: center;
            font-weight: 500;
            color: #495057;
            margin-bottom: 8px;
        }

        .required-star {
            color: #e74c3c;
            margin-left: 4px;
        }

        .modern-input,
        .modern-textarea {
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 10px 15px;
            transition: all 0.3s ease;
            font-size: 0.95rem;
        }

            .modern-input:focus,
            .modern-textarea:focus {
                border-color: #667eea;
                box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.15);
            }


        .btn-cancel,
        .btn-save {
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s ease;
            border: none;
            font-size: 0.95rem;
        }

        .btn-cancel {
            background: #6c757d;
            color: white;
        }

            .btn-cancel:hover {
                background: #5a6268;
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(108, 117, 125, 0.3);
            }

        .btn-save {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

            .btn-save:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
            }

        /* Alert Styling */
        .alert {
            border-radius: 8px;
            padding: 12px 15px;
            margin-top: 15px;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .modern-body {
                padding: 15px;
            }

            .form-section {
                padding: 15px;
            }

            .bill-amount {
                font-size: 1rem;
            }

            .total-amount {
                font-size: 1.5rem;
            }

            .payment-mode-buttons {
                grid-template-columns: 1fr;
            }
        }


        .status-badge {
  		display: inline-block;
  		padding: 10px 13px;
  		border-radius: 8px;
  		color: white;
  		font-size: 13px;
  		font-weight: 600;
  		text-align: center;
  		min-width: 100px;
  		box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

  		.status-badge.pending {
  			background-color: #6c757d; /* Gray */
  		}

  		.status-badge.partial {
  			background-color: #ffc107; /* Yellow */
  			color: #212529; /* Dark text for contrast */
  		}

  		.status-badge.paid {
  			background-color: #28a745; /* Green */
  		}

  		.status-badge.approved {
  			background-color: #20c997; /* Lighter green shade */
  		}

  		.status-badge.rejected {
  			background-color: #dc3545; /* Red */
  		}

  		.status-badge.unknown {
  			background-color: #adb5bd; /* Light gray for unknown */
  		}


          
        /* File Upload Styling */
        input[type="file"] {
            padding: 10px;
            border: 2px dashed #e0e0e0;
            border-radius: 8px;
            background: #fafafa;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 14px;
            width: 100%;
        }

            input[type="file"]:hover {
                border-color: #667eea;
                background: #f5f7ff;
            }

            input[type="file"]::-webkit-file-upload-button {
                padding: 8px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 13px;
                font-weight: 500;
                margin-right: 10px;
                transition: all 0.2s ease;
            }

                input[type="file"]::-webkit-file-upload-button:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
                }

            /* Firefox */
            input[type="file"]::file-selector-button {
                padding: 8px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 13px;
                font-weight: 500;
                margin-right: 10px;
                transition: all 0.2s ease;
            }

                input[type="file"]::file-selector-button:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
                }

                d-none{
                    display:none;
                }

                d-block{
                    display:block;
                }
    </style>
    <!-- Page Header -->

    <div style="margin: 15px 30px;">
        <table width="100%">
            <tr>
                <th width="100%" class="">
                    <h1 class=" tex0 font-weight-bold " style="color: #012970;">Vendor Bill Payments
                    </h1>
                </th>
            </tr>
        </table>
        <div class="form-group">
            <div class="row">
                <div class="col-12">
                    <div class="d-flex align-items-center">
                        <div class="search-container">

                            <asp:TextBox
                                ID="txt_search"
                                CssClass="aspNetTextBox"
                                placeHolder="Search bills..."
                                runat="server"
                                TextMode="Search"
                                AutoPostBack="true"
                                onkeyup="filterTable()" />

                            <!-- Calendar and Search Buttons -->
                            <div class="input-buttons">
                                <button
                                    id="btn_search"
                                    type="submit"
                                    class="search-button2"
                                    runat="server">
                                    <span class="material-symbols-outlined">search</span>
                                </button>
                            </div>
                        </div>

                        &nbsp;&nbsp;
                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#paymentModal">New Payment</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Previous Payments Grid -->
<%--        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="fas fa-history me-2"></i>Previous Payments</h5>
            </div>--%>
            <div class="card-body">
                <asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="gridview-container">
                            <asp:GridView ID="gvPayments" runat="server" CssClass="table table-bordered table-hover table-striped"
                                AutoGenerateColumns="False" DataKeyNames="payment_id" OnRowCommand="gvPayments_RowCommand">
                                <Columns>
                                    <asp:BoundField DataField="payment_no" HeaderText="Payment No" />
                                    <asp:BoundField DataField="payment_date" HeaderText="Date" DataFormatString="{0:dd/MM/yyyy}" />
                                    <asp:BoundField DataField="vendor_name" HeaderText="Vendor Name" />
                                    <asp:BoundField DataField="transaction_ref" HeaderText="Transaction Ref" />
                                    <asp:BoundField DataField="paid_amount" HeaderText="Paid Amount" />

                                    <asp:TemplateField HeaderText="Actions">
                                        <ItemTemplate>
                                            <asp:Button ID="btnView" runat="server" Text="View"
                                                CssClass="btn btn-sm btn-info" CommandName="ViewDetails"
                                                CommandArgument='<%# Eval("payment_id") %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Document">
                                        <ItemTemplate>
                                             <asp:LinkButton runat="server" ID="btnViewFile" OnCommand="btnViewFile_Command" CssClass="btn btn-sm btn-success" CommandName="showFile" CommandArgument='<%# Bind("file_path")%>'>  <i class="fas fa-eye"></i></asp:LinkButton>

                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>
        </div>
    <%--</div>--%>

    <div class="modal fade" id="paymentModal" data-backdrop="static" data-keyboard="false" tabindex="-1" aria-labelledby="staticBackdropLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content modal-lg">
                <div class="modal-header">
                    <h5 class="modal-title" id="staticBackdropLabel"><i class="fas fa-wallet me-2"></i><strong>New Maintenance Payment</strong></h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <asp:UpdatePanel ID="UpdatePanelModal" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField runat="server" ID="vendor_id" />

                        <div class="modal-body modern-body">

                            <!-- Owner Selection -->
                            <div class="form-section mb-4">
                                <div class="section-header">
                                    <i class="fas fa-user-circle"></i>
                                    <span>Vendor Information</span>
                                </div>

                                <div class="form-group row align-items-center">
                                    <div class="col-sm-3 col-12">
                                        <asp:Label ID="Label1" runat="server" Text="Vendor Name"></asp:Label>
                                        <asp:Label ID="Label2" runat="server" Text=" :" Font-Bold="true"></asp:Label>
                                        <asp:Label ID="Label3" runat="server" Text=" *" Font-Bold="true" ForeColor="#e74c3c"></asp:Label>
                                    </div>

                                    <div class="col-sm-9 col-12">
                                        <div class="dropdown-container position-relative">
                                            <asp:TextBox ID="vendor_name" runat="server" CssClass="form-control"
                                                placeholder="Select vendor" autocomplete="off" required="required" />

                                            <asp:Panel ID="drp_Container" runat="server" CssClass="suggestion-list-container">
                                                <div id="RepeaterContainer1" class="suggestion-list w-100">
                                                    <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                        <ItemTemplate>
                                                            <asp:LinkButton ID="lnkCategory" runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("vendor_name") + " (" + Eval("service_type") + ")" %>'
                                                                CommandArgument='<%# Eval("vendor_id") %>'
                                                                CommandName='<%# Eval("gst_no") %>'
                                                                OnClientClick="setCategoryBox1(this.innerText);" />
                                                        </ItemTemplate>
                                                        <FooterTemplate>
                                                            <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'>
                                                            <div class="suggestion-item text-muted">No vendors found</div>
                                                            </asp:Literal>
                                                        </FooterTemplate>
                                                    </asp:Repeater>
                                                </div>
                                            </asp:Panel>
                                        </div>
                                    </div>
                                </div>
                            </div>


                            <!-- Bill Selection Section -->
                            <div id="divBillDetails" runat="server" class="d-none">
                            <asp:Panel ID="pnlBillDetails" runat="server">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="hfSelectedBills" runat="server" />

                                        <div class="form-section mb-4">
                                            <div class="section-header">
                                                <i class="fas fa-file-invoice-dollar"></i>
                                                <span>Select Bills to Pay</span>
                                            </div>

                                            <div class="bills-container">

                                                <asp:Repeater ID="temp" runat="server">
                                                    <ItemTemplate>
                                                        <div class="vBill-container">
                                                            <div class="vBill-item mb-2" data-bill-id='<%# Eval("bill_id") %>' onclick="toggleBill(this)">
                                                                <div class="vBill-left">
                                                                    <div class="vBill-header">
                                                                        <i class="fas fa-file-alt"></i>
                                                                        <span class="vBill-number"><%# Eval("bill_number") %> - <%# Convert.ToBoolean(Eval("service_type")) ? "Service" : "Inventory" %></span>
                                                                    </div>
                                                                    <div class="vBill-due">
                                                                        <i class="far fa-clock"></i>
                                                                        <span>Due: <%# Convert.ToDateTime(Eval("bill_date")).ToString("dd MMM yyyy") %></span>
                                                                    </div>
                                                                </div>

                                                                <div class="vBill-right">
                                                                    <div class="vBill-count"><%# Eval("Status") %></div>
                                                                    <div class="vBill-amount">Rs <%# Convert.ToDecimal(Eval("total_amount")).ToString("N2") %></div>
                                                                    <div class="vBill-check">
                                                                        <i class="fas fa-check text-white"></i>
                                                                    </div>
                                                                </div>
                                                            </div>

                                                        </div>


                                                    </ItemTemplate>
                                                </asp:Repeater>
                                            </div>

                                            <!-- Total Amount -->
                                            <div class="total-card mt-3 p-3 border d-flex justify-content-between align-items-center">
                                                <div class="total-label">
                                                    <i class="fas fa-calculator me-2"></i>Total Amount to Pay
                                                </div>
                                                <div class="total-amount">
                                                    <i class="fas fa-rupee-sign"></i>
                                                    <asp:Label ID="lblTotalAmount" runat="server" Text="0.00"></asp:Label>
                                                </div>
                                            </div>
                                        </div>

                                    </ContentTemplate>
                                </asp:UpdatePanel>
                                <!-- Payment Mode Section -->
                                <div class="form-section mb-4">
                                    <div class="section-header">
                                        <i class="fas fa-credit-card"></i>
                                        <span>Payment Mode</span>
                                    </div>
                                    <div class="payment-mode-buttons d-flex gap-2">
                                        <asp:LinkButton ID="btnChequeMode" runat="server" CssClass="payment-btn active" OnClick="btnChequeMode_Click">
                                        <div class="payment-btn-content">
                                            <i class="fas fa-money-check"></i><span>Cheque</span>
                                        </div>
                                        </asp:LinkButton>

                                        <asp:LinkButton ID="btnPDCMode" runat="server" CssClass="payment-btn" OnClick="btnPDCMode_Click">
                                        <div class="payment-btn-content">
                                            <i class="fas fa-calendar-check"></i><span>Online/ UPI</span>
                                        </div>
                                        </asp:LinkButton>
                                    </div>
                                </div>

                                <!-- Cheque Details Section -->
                                <asp:Panel ID="pnlChequeDetails" runat="server">
                                    <div class="form-section">
                                        <div class="section-header">
                                            <i class="fas fa-file-invoice"></i><span>Cheque Details</span>
                                        </div>

                                        <asp:Panel ID="pnlOnline" runat="server" Visible="False">
                                            <div class="form-group row mb-3">
                                                <div class="form-group row">
                                                    <div class="col-sm-6 mb-3">
                                                        <label><i class="fas fa-hashtag me-2"></i>Transaction Referance <span class="required-star">*</span></label>
                                                        <asp:TextBox   ID="txtTransactionRef" runat="server" CssClass="form-control" placeholder="Enter Transaction Referance"></asp:TextBox>
                                                    </div>
                                                    <div class="col-sm-6 mb-3">
                                                        <label><i class="far fa-calendar-alt me-2"></i>Amount <span class="required-star">*</span></label>
                                                        <asp:TextBox  ID="txtAmtOl" runat="server" CssClass="form-control"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>

                                        <asp:Panel ID="pnlCheque" runat="server">
                                            <div class="form-group row">
                                                <div class="col-sm-6 mb-3">
                                                    <label><i class="fas fa-hashtag me-2"></i>Cheque Number <span class="required-star">*</span></label>
                                                    <asp:TextBox required="required" ID="txtChequeNo" runat="server" CssClass="form-control" placeholder="Enter cheque number"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-6 mb-3">
                                                    <label><i class="far fa-calendar-alt me-2"></i>Cheque Date <span class="required-star">*</span></label>
                                                    <asp:TextBox required="required" ID="txtChequeDate" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
                                                </div>
                                            </div>

                                            <div class="form-group row">
                                                <div class="col-sm-6 mb-3">
                                                    <label><i class="fas fa-university me-2"></i>Bank Name <span class="required-star">*</span></label>
                                                    <asp:TextBox required="required" ID="txtBankName" runat="server" CssClass="form-control" placeholder="Enter bank name"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-6 mb-3">
                                                    <label><i class="fas fa-map-marker-alt me-2"></i>Amount <span class="required-star">*</span></label>
                                                    <asp:TextBox required="required" ID="txtAmtCqu" runat="server" CssClass="form-control" placeholder="Enter Amount"></asp:TextBox>
                                                </div>
                                            </div>
                                        </asp:Panel>



                                        <div class="form-group">
                                            <label><i class="fas fa-comment-dots me-2"></i>Remarks</label>
                                            <asp:TextBox ID="txtRemarks" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Enter any additional remarks..."></asp:TextBox>
                                        </div>
                                    </div>
                                </asp:Panel>

                         

                                <!-- File Upload -->
                                <div class="form-group">
                                    <div class="row align-items-center mb-3">
                                        <div class="col-12 col-sm-3">
                                            <asp:Label ID="Label15" runat="server" Text="Bill Proof"></asp:Label>
                                            <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                        </div>
                                        <div class="col-12 col-sm-9">
                                            <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf, .jpg, .jpge" required CssClass="form-control"  Style="    padding: 18px 22px;
    height: 61px;"/>
                                            <div class="overflow-div">
                                                <asp:Label ID="listofuploadedfiles" runat="server" />
                                            </div>
                                            <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
                                        </div>
                                    </div>
                                </div>


                                <asp:Label ID="lblMessage" runat="server" CssClass="alert alert-warning mt-3" Visible="False"></asp:Label>
                            </asp:Panel>
                                </div>
                        </div>




                    </ContentTemplate>
                    <Triggers>
                      
                        <asp:AsyncPostBackTrigger ControlID="btnChequeMode" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnPDCMode" EventName="Click" />
                    </Triggers>

                </asp:UpdatePanel>


                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal" onclick="hidePanel();"> Close</button>
                    <asp:Button ID="btnSavePayment" runat="server" Text="Save Payment"
                        CssClass="btn btn-save" OnClick="btnSavePayment_Click" OnClientClick="disableSaveButtonIfValid()" />

                </div>
            </div>
        </div>
    </div>


    <!-- Payment Summary Modal -->
    <div class="modal fade SB-payment-summary-modal" id="paymentSummaryModal" tabindex="-1" role="dialog" aria-labelledby="paymentSummaryModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <!-- Header -->
                <div class="modal-header">
                    <h5 class="modal-title" id="paymentSummaryModalLabel">
                        <i class="fas fa-file-invoice"></i>Payment Summary
                    </h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <!-- Body -->
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <!-- Resident Info -->
                            <h6 class="SB-section-header">Resident Information</h6>
                            <div class="SB-info-card">
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Resident Name:</span>
                                        <asp:Label ID="lblResidentName" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
                            </div>

                            <!-- Selected Bills -->
                            <h6 class="SB-section-header">Paid Bills</h6>
                            <div class="SB-bills-table">
                                <asp:GridView ID="gvSelectedBills" runat="server" AutoGenerateColumns="False"
                                    CssClass="table-hover" GridLines="None" ShowHeaderWhenEmpty="True">
                                    <Columns>
                                        <asp:BoundField DataField="bill_number" HeaderText="Bill No" />
                                        <%--<asp:BoundField DataField= <%# Convert.ToBoolean(Eval("service_type")) ? "Service" : "Inventory" %> HeaderText="Description" />--%>

                                        <asp:BoundField DataField="payment_date" HeaderText="Bill Date" DataFormatString="{0:dd MMM yyyy}" />
                                        <%--<asp:BoundField DataField="Status" HeaderText="Status" />--%>
                                        <asp:BoundField DataField="Amount" HeaderText="Amount (₹)" DataFormatString="{0:N2}" />
                                        <asp:TemplateField HeaderText="Status">
                                            <ItemTemplate>
                                                <%# 
                                                    Eval("status").ToString() == "1" ? "<span class='status-badge pending'>Pending</span>" :
                                                    Eval("status").ToString() == "2" ? "<span class='status-badge approved'>Approved</span>" :
                                                    Eval("status").ToString() == "3" ? "<span class='status-badge paid'>Paid</span>" :
                                                    Eval("status").ToString() == "4" ? "<span class='status-badge rejected'>Rejected</span>" :
                                                    Eval("status").ToString() == "5" ? "<span class='status-badge partial'>Partially Paid</span>" :
                                                    "<span class='status-badge unknown'>Unknown</span>"
                                                %>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>
                            </div>

                            <%--                            <div class="SB-total-amount">
                                <span class="SB-total-label">Total Amount:</span>
                                <asp:Label ID="Label7" runat="server" CssClass="SB-total-value"></asp:Label>
                            </div>--%>

                            <!-- Payment Details -->
                            <h6 class="SB-section-header">Payment Details</h6>
                            <div class="SB-info-card">
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Payment Mode:</span>
                                        <asp:Label ID="lblPaymentMode" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                    <asp:Panel ID="pnlTransactionRef" runat="server">
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Transaction Referance</span>
                                            <asp:Label ID="lblTransaction" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                    </asp:Panel>
                                </div>
                                <asp:Panel runat="server" ID="pnlBankPayInfo">
                                    <div class="SB-info-row">
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Cheque Number:</span>
                                            <asp:Label ID="lblChequeNumber" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Cheque Date:</span>
                                            <asp:Label ID="lblChequeDate" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Bank Name:</span>
                                            <asp:Label ID="lblBankName" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                    </div>
                                </asp:Panel>
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Amount:</span>
                                        <asp:Label ID="lblPaymentAmount" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
                                <div class="SB-info-row">
                                    <div class="SB-info-item" style="flex: 1 1 100%;">
                                        <span class="SB-info-label">Remarks:</span>
                                        <asp:Label ID="lblRemarks" runat="server" CssClass="SB-info-value text-muted"></asp:Label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="gvPayments" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
                <!-- Footer -->
                <div class="modal-footer">
                    <button type="button" class="btn SB-btn-back" data-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    
    <div class="modal fade" id="fileModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <div class="modal-header">
                            <h5 class="modal-title">File Viewer</h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <!-- iframe for PDF/Image -->
                                   <asp:Label ID="lblFileMessage" runat="server" CssClass="text-danger"></asp:Label>
                            <iframe id="iframeFile" runat="server" width="100%" height="500px" style="border: none;"></iframe>
                        </div>

                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="gvPayments" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>


    <script type="text/javascript">

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btnSavePayment.ClientID %>');
            var modal = document.getElementById('paymentModal');
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

                        __doPostBack('<%= btnSavePayment.UniqueID %>', '');

                        return true;
                    }

                    return false;
                }


        // Keep global variables
        let selectedBills = new Set();
        let totalAmount = 0;

        function toggleBill(element) {
            const billId = element.getAttribute("data-bill-id");
            const amountText = element.querySelector(".vBill-amount").innerText;
            const amount = parseFloat(amountText.replace(/[^0-9.]/g, ""));
            const lblTotal = document.getElementById("<%= lblTotalAmount.ClientID %>");
            const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
            const txtAmt = document.getElementById("<%= txtAmtCqu.ClientID %>");
            const txtAmtonl = document.getElementById("<%= txtAmtOl.ClientID %>");

            const isSelected = element.classList.toggle("vBill-selected");

            if (isSelected) {
                // Add new bill if not already selected
                if (!selectedBills.has(billId)) {
                    selectedBills.add(billId);
                    totalAmount += amount;
                }
            } else {
                // Remove bill and subtract its amount
                if (selectedBills.has(billId)) {
                    selectedBills.delete(billId);
                    totalAmount -= amount;
                }
            }

            // Prevent rounding errors
            totalAmount = Math.max(totalAmount, 0);

            // Update UI
            if (lblTotal) {
                if (txtAmt) {
                    txtAmt.value = totalAmount.toFixed(2);
                }
                if (txtAmtonl) {
                    txtAmtonl.value = totalAmount.toFixed(2);
                }

                lblTotal.innerText = totalAmount.toLocaleString("en-IN", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                });
            }

            // Update hidden field
            if (hf) {
                hf.value = Array.from(selectedBills).join(",");
            }
        }

        // Preserve state after partial postback
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            const txtAmtonl = document.getElementById("<%= txtAmtOl.ClientID %>");
            const txtAmt = document.getElementById("<%= txtAmtCqu.ClientID %>");
            const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
            const lblTotal = document.getElementById("<%= lblTotalAmount.ClientID %>");

            if (hf && hf.value) {
                selectedBills = new Set(hf.value.split(","));
            } else {
                selectedBills = new Set();
            }

            totalAmount = 0;
            selectedBills.forEach(id => {
                const el = document.querySelector(`[data-bill-id='${id}']`);
                if (el) {
                    el.classList.add("vBill-selected");
                    const amountText = el.querySelector(".vBill-amount").innerText;
                    totalAmount += parseFloat(amountText.replace(/[^0-9.]/g, ""));
                }
            });

            if (lblTotal) {
                //if (txtAmt) {
                //    txtAmt.value = totalAmount.toFixed(2);
                //}
                //if (txtAmtonl) {
                //    txtAmtonl.value = totalAmount.toFixed(2);
                //}
                lblTotal.innerText = totalAmount.toLocaleString("en-IN", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                });
            }
        });


        function toggleBillSelection(billId, linkButton) {
            const hiddenField = document.getElementById('<%= hfSelectedBills.ClientID %>');
            let selectedBills = hiddenField.value ? hiddenField.value.split(',') : [];

            // Toggle selection
            if (selectedBills.includes(billId)) {
                selectedBills = selectedBills.filter(id => id !== billId);
                linkButton.classList.remove('selected');
            } else {
                selectedBills.push(billId);
                linkButton.classList.add('selected');
            }

            // Update hidden field
            hiddenField.value = selectedBills.join(',');
        }

        // Toggle bill selection styling
        function toggleBillSelection(element) {
            element.classList.toggle('selected');
        }

        var paymentModal;

        window.onload = function () {
            paymentModal = new bootstrap.Modal(document.getElementById('paymentModal'));
        };

        function showModal() {
            $('#myModal').modal('paymentModal')
        }

        function hideModal() {
            paymentModal.hide();
        }


        // Dropdown Functions
        function initDropdownEvents() {
            const categoryBox = document.getElementById("<%= vendor_name.ClientID %>");
            const categorySuggestions = document.getElementById("RepeaterContainer1");

            if (categoryBox && categorySuggestions) {
                categoryBox.addEventListener("focus", function () {
                    categorySuggestions.style.display = "block";
                });

                categoryBox.addEventListener("input", function () {
                    const input = categoryBox.value.toLowerCase();
                    filterSuggestions("category-link", input);
                });

                // Close dropdown when clicking outside
                document.addEventListener("click", function (e) {
                    if (!categoryBox.contains(e.target) && !categorySuggestions.contains(e.target)) {
                        categorySuggestions.style.display = "none";
                    }
                });
            }
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
                    noMatchMessage.className = "suggestion-item";
                    noMatchMessage.style.color = "#9ca3af";
                    noMatchMessage.innerHTML = `
                          No matching vendors found.
                          <a href="javascript:void(0)" onclick="openAddVendorModal()" class="add-vendor-link">
                              <i class="fas fa-plus"></i> Add New
                          </a>
                      `;
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
            document.getElementById("<%= vendor_name.ClientID %>").value = value;
            document.getElementById("RepeaterContainer1").style.display = "none";
            document.getElementById("divBillDetails").style.display = "block";
            document.getElementById("divBillDetails").classList.remove = "d-none";  
            
            const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
            hf.value = "";
            selectedBills.clear();
        }

        // Initialize on Sys.Application load
        Sys.Application.add_load(function () {
            initDropdownEvents();
        });


        function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
            if (!input) return;

            const filter = input.value.toLowerCase();
            const table = document.querySelector('.gridview-container table');

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


            function hidePanel() {
                // Hide the Bill Details panel by setting its display to none
                var pnl = document.getElementById('<%= pnlBillDetails.ClientID %>');
                if (pnl) {
                    pnl.style.display = 'none';
                }
            }
  

    </script>
</asp:Content>
