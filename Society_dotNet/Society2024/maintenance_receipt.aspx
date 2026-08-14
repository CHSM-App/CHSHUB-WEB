<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="maintenance_receipt.aspx.cs" Inherits="Society.MaintenanceReceipt" EnableEventValidation="false" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">


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

/*        ------------------------------------------------------------------------------------------------------------------*/
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
        .page-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 0;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

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

        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }



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
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .form-label {
            font-weight: 600;
            margin-bottom: 20px;
            color: #2c3e50;
            border-bottom: 2px solid #e9ecef;
            padding-bottom: 10px;
        }

        /* Modern Modal Styling */
        .modern-modal {
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            border: none;
            overflow: hidden;
        }

        .gradient-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 25px;
            border-bottom: none;
        }

            .gradient-header .modal-title {
                font-weight: 600;
                font-size: 1.3rem;
                margin: 0;
            }

            .gradient-header .btn-close {
                filter: brightness(0) invert(1);
                opacity: 0.9;
            }

                .gradient-header .btn-close:hover {
                    opacity: 1;
                }

        /* Modal Body */
        .modern-body {
            padding: 25px;
            background: #f8f9fa;
        }

        /* Form Sections */
        .form-section {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
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

        /* Modern Select */
        .modern-select {
            border: 2px solid #e9ecef;
            border-radius: 8px;
            padding: 10px 15px;
            font-size: 0.95rem;
            transition: all 0.3s ease;
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

        /* Modal Footer */
        .modern-footer {
            background: #f8f9fa;
            padding: 20px 25px;
            border-top: 1px solid #e9ecef;
            display: flex;
            justify-content: flex-end;
            gap: 12px;
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

        .hide-on-pdf {
    display: none !important;
}

        .pdf-page-break {
    margin-bottom: 15px;
}


    </style>

    <!-- Page Header -->


    <div style="margin-left:23px;">
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

                <div class="form-group">
                    <div class="row">
                        <div class="col-12">
                            <div class="top-row d-flex align-items-center">
                                <div class="search-container">

                                    
                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox"
                                                placeHolder="Search bills..."
                                                runat="server"
                                                TextMode="Search"                                               
                                                 onkeyup="triggerSearch()" />

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
                                            type="button"
                                            class="search-button2"
                                            onclick="filterTable()" >
                                            <span class="material-symbols-outlined">search</span>
                                        </button>
                                    </div>
                                </div>

                                &nbsp;&nbsp;
                              <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#paymentModal">Add</button>

                                &nbsp;&nbsp;
                                <button class="w-90 btn btn-primary" onclick="printreceiptsearch()">Print</button>
                                &nbsp;&nbsp;
                              <button class="w-90 btn btn-success" onclick="downloadGridViewAsPDF()">Download PDF</button>


                            </div>
                        </div>
                    </div>
                </div>

                <div style="overflow: visible" runat="server" id="paymentsGridWrapper" class="gridview-container">
                    <asp:GridView ID="gvPayments" runat="server" CssClass="table table-bordered table-hover table-striped"
                        AutoGenerateColumns="False" DataKeyNames="receipt_id" OnRowCommand="gvPayments_RowCommand" AllowSorting="true" HeaderStyle-BackColor="lightblue" OnSorting="gvPayments_Sorting" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found">
                        <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                        <Columns>
                            <%--<asp:BoundField SortExpression="receipt_no" DataField="receipt_no" HeaderText="Receipt No" />--%>

                             <asp:TemplateField HeaderText="Receipt No" SortExpression="receipt_no">
                                <ItemTemplate>
                                    <asp:Label ID="receipt_no" runat="server" Text='<%# Bind("receipt_no")%>'></asp:Label>
                                </ItemTemplate>
                             </asp:TemplateField>
                            <asp:TemplateField HeaderText="Owner Name" SortExpression="owner">
                                <ItemTemplate>
                                     <asp:Label ID="owner" runat="server" Text='<%# Bind("owner")%>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Amount Paid" SortExpression="paid_amount">
                                <ItemTemplate>
                                     <asp:Label ID="paid_amount" runat="server" Text='<%# Bind("paid_amount", "{0:N2}")%>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Bill Status" SortExpression="bill_status">
                                <ItemTemplate>
                                    <asp:Label ID="bill_status" runat="server" Text='<%# Bind("bill_status")%>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <%--<asp:BoundField DataField="bill_status" HeaderText="Bill Status" />--%>

                            <asp:TemplateField HeaderText="Transaction Ref" SortExpression="transaction_ref">
                                <ItemTemplate>
                                    <asp:Label ID="transaction_ref" runat="server" Text='<%# Bind("transaction_ref")%>'></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <%--<asp:BoundField DataField="transaction_ref" HeaderText="Transaction Ref" />--%>

                            <asp:TemplateField HeaderText="Receipt Date" SortExpression="receipt_date">
                                <ItemTemplate>
                                    <asp:Label ID="receipt_date" runat="server" Text='<%# Bind("receipt_date")%>' ></asp:Label>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <%--<asp:BoundField DataField="receipt_date" HeaderText="Date" DataFormatString="{0:dd/MM/yyyy}" />--%>
                            <asp:TemplateField HeaderText="Actions" >
                                <ItemTemplate>
                                    <asp:Button ID="btnView" runat="server" Text="View"
                                        CssClass="btn btn-sm btn-info" CommandName="ViewDetails"
                                        CommandArgument='<%# Eval("receipt_id") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>

                        </Columns>
                    </asp:GridView>
                </div>


            </ContentTemplate>
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="btnSavePayment" EventName="Click"/>
                <asp:AsyncPostBackTrigger ControlID="gvPayments" EventName="RowCommand"/>
            </Triggers>
        </asp:UpdatePanel>
    </div>

    <!-- Payment Modal -->
    <div class="modal fade" id="paymentModal" role="form" aria-labelledby="paymentModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <div class="modal-content modern-modal">
                <div class="modal-header gradient-header">
                    <h4 class="modal-title" id="paymentModalLabel">
                        <i class="fas fa-wallet me-2"></i><strong>New Maintenance Payment</strong>
                    </h4>
                    <button type="button" class="btn-close btn-close-white" data-dismiss="modal" aria-label="Close"></button>
                </div>
                <asp:UpdatePanel ID="UpdatePanelModal" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
                    <ContentTemplate>
                        <asp:HiddenField ID="flat_id" runat="server" />
                        <asp:HiddenField ID="bill_id" runat="server" />

                        <asp:HiddenField ID="HiddenField1" runat="server" />
<asp:HiddenField ID="hfMinAmount" runat="server" />

                        <div class="modal-body modern-body">


                            <!-- Owner Selection Section -->

                            <div class="section-header">
                                <i class="fas fa-user-circle"></i>
                                <span>Resident Information</span>
                            </div>
                            <div class="form-group">
                                <div class="row align-items-center">
                                    <div class="col-sm-3 col-12">
                                        <asp:Label ID="Label1" runat="server" Text="Resident Name"></asp:Label>
                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=" :"></asp:Label>
                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="#e74c3c" Text=" *"></asp:Label>
                                    </div>
                                    <div class="col-sm-9 col-12">
                                        <div class="dropdown-container">
                                            <asp:TextBox ID="txtResident" runat="server" CssClass="form-control"
                                                placeholder="Select Resident" autocomplete="off" required="required" />
                                            <div id="RepeaterContainer1" class="suggestion-list" style="width: 100%">
                                                <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                    <ItemTemplate>
                                                        <asp:LinkButton
                                                            ID="lnkCategory"
                                                            runat="server"
                                                            CssClass="suggestion-item link-button category-link"
                                                            Text='<%# Eval("resident_name") %>'
                                                            CommandArgument='<%# Eval("flat_id") %>'
                                                            OnClientClick="setCategoryBox1(this.innerText);" />
                                                    </ItemTemplate>
                                                    <FooterTemplate>
                                                        <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'>
                      <div class="suggestion-item" style="color: #9ca3af;">No Residents found</div>
                                                        </asp:Literal>
                                                    </FooterTemplate>
                                                </asp:Repeater>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Bill Selection Section -->
                            <asp:Panel ID="pnlBillDetails" runat="server" Visible="False">
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                              <asp:HiddenField ID="hfSelectedBills" runat="server" />
                                        <div class="form-section">
                                            <div class="section-header">
                                                <i class="fas fa-file-invoice-dollar"></i>
                                                <span>Select Bills to Pay</span>
                                            </div>

                                            <div class="bills-container">


                                                <asp:Repeater ID="rptBills" runat="server" >
                                                    <ItemTemplate>
                                                      

                                                        <div class="vBill-container">
                                                            <div class="vBill-item mb-2" data-bill-id='<%# Eval("bill_no") %>' data-bill-type='<%# Eval("BillType") %>' data-bill-amt='<%# Eval("Amount") %>' onclick="toggleBill(this)">
                                                                <div class="vBill-left">
                                                                    <div class="vBill-header">
                                                                        <i class="fas fa-file-alt"></i>
                                                                        <span class="vBill-number"><%# Eval("BillNo") %> - <%#(Convert.ToInt32(Eval("BillType")) == 1) ? "Regular" : "Add-On" %></span>
                                                                    </div>
                                                                    <div class="vBill-due">
                                                                        <i class="far fa-clock"></i>
                                                                        <span>Due: <%# Convert.ToDateTime(Eval("DueDate")).ToString("dd MMM yyyy") %></span>
                                                                    </div>
                                                                </div>

                                                                <div class="vBill-right">
                                                                    <div class="vBill-count"><%# Eval("Status") %></div>
                                                                    <div class="vBill-amount">Rs <%# Convert.ToDecimal(Eval("Amount")).ToString("N2") %></div>
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
                                <div class="form-section">
                                    <div class="section-header">
                                        <i class="fas fa-credit-card"></i>
                                        <span>Payment Mode</span>
                                    </div>

                                    <div class="payment-mode-buttons">
                                        <asp:LinkButton ID="btnChequeMode" runat="server"
                                            CssClass="payment-btn active"
                                            OnClick="btnChequeMode_Click">
                                        <div class="payment-btn-content">
                                            <i class="fas fa-money-check"></i>
                                            <span>Cheque</span>
                                        </div>
                                        </asp:LinkButton>

                                        <asp:LinkButton ID="btnPDCMode" runat="server"
                                            CssClass="payment-btn"
                                            OnClick="btnPDCMode_Click">
                                        <div class="payment-btn-content">
                                            <i class="fas fa-calendar-check"></i>
                                            <span>PDC Cheque</span>
                                        </div>
                                        </asp:LinkButton>
                                    </div>
                                </div>

                                <!-- Cheque Details Section -->
                                <asp:Panel ID="pnlChequeDetails" runat="server">
                                    <div class="form-section">
                                        <div class="section-header">
                                            <i class="fas fa-file-invoice"></i>
                                            <span>Cheque Details</span>
                                        </div>

                                        <!-- PDC Selection (Only for PDC Mode) -->
                                        <asp:Panel ID="pnlPDCSelection" runat="server" Visible="False">
                                            <div class="form-group mb-4">
                                                <div class="row align-items-center">
                                                    <div class="col-sm-3 col-12">
                                                        <asp:Label ID="Label4" runat="server" Text="Select PDC Cheque"></asp:Label>
                                                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=" :"></asp:Label>
                                                        <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="#e74c3c" Text=" *"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-9 col-12">
                                                        <asp:DropDownList ID="ddlPDCCheque" runat="server"
                                                            CssClass="form-select modern-select"
                                                            AutoPostBack="True"
                                                            OnSelectedIndexChanged="ddlPDCCheque_SelectedIndexChanged">
                                                        </asp:DropDownList>
                                                    </div>
                                                </div>
                                            </div>
                                        </asp:Panel>

                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-6 col-12 mb-3">
                                                    <label class="modern-label">
                                                        <i class="fas fa-hashtag me-2"></i>Transation ID/Cheque No
                                                    <span class="required-star">*</span>
                                                    </label>
                                                    <asp:TextBox ID="txtChequeNo" runat="server"
                                                        CssClass="form-control modern-input"
                                                        placeholder="Enter cheque number" required="required"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-6 col-12 mb-3">
                                                    <label class="modern-label">
                                                        <i class="far fa-calendar-alt me-2"></i>Payment Date
                                                    <span class="required-star">*</span>
                                                    </label>
                                                    <asp:TextBox ID="txtChequeDate" runat="server"
                                                        CssClass="form-control modern-input"
                                                        TextMode="Date" required="required" DataFormatString="{0:dd MMM yyyy}"></asp:TextBox>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row">
                                                <div class="col-sm-6 col-12 mb-3">
                                                    <label class="modern-label">
                                                        <i class="fas fa-university me-2"></i>Bank Name
                                                    <span class="required-star">*</span>
                                                    </label>
                                                    <asp:TextBox ID="txtBankName" required="required" runat="server"
                                                        CssClass="form-control modern-input"
                                                        placeholder="Enter bank name"></asp:TextBox>
                                                </div>
                                                <div class="col-sm-6 col-12 mb-3">
                                                    <label class="modern-label">
                                                        <i class="fas fa-map-marker-alt me-2"></i>Amount
                                                    <span class="required-star">*</span>
                                                    </label>
                                                    <asp:TextBox ID="txtAmt" required="required" runat="server"
                                                        CssClass="form-control modern-input"
                                                        placeholder="Enter Amount"></asp:TextBox>
                                                    <asp:Label ID="lblMinAmt" runat="server" CssClass="text-danger"></asp:Label>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <label class="modern-label">
                                                <i class="fas fa-comment-dots me-2"></i>Remarks
                                            </label>
                                            <asp:TextBox ID="txtRemarks" runat="server"
                                                CssClass="form-control modern-textarea"
                                                TextMode="MultiLine"
                                                Rows="3"
                                                placeholder="Enter any additional remarks..."></asp:TextBox>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Message Label -->

                            </asp:Panel>
                            <div class="align-items-center d-flex" style="width: 100%;">
                                <asp:Label ID="lblMessage" runat="server" CssClass="alert m-auto" Visible="False"></asp:Label>
                            </div>

                        </div>



                        <div class="modal-footer modern-footer">
                            <button type="button" class="btn btn-cancel" data-dismiss="modal" onclick="hidePanel()">
                                <i class="fas fa-times me-2"></i>Cancel
                            </button>
                            <asp:Button ID="btnSavePayment" runat="server" Text="Save Payment" OnClientClick="return validateAmount();"
                                CssClass="btn btn-save" OnClick="btnSavePayment_Click"></asp:Button>
                        </div>
                    </ContentTemplate>

                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="rptBills" EventName="ItemCommand" />
                        <asp:AsyncPostBackTrigger ControlID="ddlPDCCheque" EventName="SelectedIndexChanged" />
                        <asp:AsyncPostBackTrigger ControlID="btnSavePayment" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnChequeMode" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnPDCMode" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>
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
                            <h6 class="SB-section-header">Selected Bills</h6>
                            <div class="SB-bills-table">
                                <asp:GridView ID="gvSelectedBills" runat="server" AutoGenerateColumns="False"
                                    CssClass="table-hover" GridLines="None" ShowHeaderWhenEmpty="True">
                                    <Columns>
                                        <asp:BoundField DataField="bill_ref" HeaderText="Bill Ref" />
                                        <asp:BoundField DataField="billno" HeaderText="Bill no" />
                                        <asp:BoundField DataField="gen_date" HeaderText="Due Date" DataFormatString="{0:dd MMM yyyy}" />
                             <%--           <asp:BoundField DataField="Status" HeaderText="Status" />--%>
                                        <asp:BoundField DataField="Amount" HeaderText="Amount (₹)" DataFormatString="{0:N2}" />
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
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Cheque Number:</span>
                                        <asp:Label ID="lblChequeNumber" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Cheque Date:</span>
                                        <asp:Label ID="lblChequeDate" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Bank Name:</span>
                                        <asp:Label ID="lblBankName" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
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

    <div id="pdfLoader" style="
    display:none;
    position:fixed; top:0; left:0; width:100%; height:100%;
    background:rgba(0,0,0,0.5); z-index:9999;
    justify-content:center; align-items:center;">
    <div class="spinner-border text-light" style="width: 3rem; height: 3rem;" role="status"></div>
</div>


<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>


  <script type="text/javascript">
      var paymentModal;

      let selectedBills = new Map(); // billId → billType
      let totalAmount = 0;
      let minAmount = 0;
      // let userEdited = false; // true when user types manually

      function toggleBill(element) {
          const billId = element.getAttribute("data-bill-id");
          const billType = element.getAttribute("data-bill-type"); // 1 = Regular, 0 = Add-on
          const amountText = element.querySelector(".vBill-amount").innerText;
          const amount = parseFloat(amountText.replace(/[^0-9.]/g, ""));

          const lblTotal = document.getElementById("<%= lblTotalAmount.ClientID %>");
        const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
        const txtAmt = document.getElementById("<%= txtAmt.ClientID %>");
        const lblMinAmt = document.getElementById("<%= lblMinAmt.ClientID %>");
        const hfMin = document.getElementById("<%= hfMinAmount.ClientID %>");

          const isSelected = element.classList.toggle("vBill-selected");

          if (isSelected) {
              selectedBills.set(billId, billType);
          } else {
              selectedBills.delete(billId);
          }

          // Recalculate totals
          totalAmount = 0;
          minAmount = 0;
          let hasAddon = false;

          selectedBills.forEach((type, id) => {
              const el = document.querySelector(`[data-bill-id='${id}']`);
              if (el) {
                  const amtText = el.querySelector(".vBill-amount").innerText;
                  const amt = parseFloat(amtText.replace(/[^0-9.]/g, ""));
                  totalAmount += amt;
                  if (type === "1") minAmount += amt;
                  if (type === "0") hasAddon = true;
              }
          });

          // Update labels
          if (lblTotal) {
              txtAmt.value = totalAmount.toFixed(2);
              lblTotal.innerText = totalAmount.toLocaleString("en-IN", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2
              });
          }

          if (lblMinAmt) {
              lblMinAmt.innerText =
                  selectedBills.size && minAmount > 0
                      ? `Minimum amount is: ₹${minAmount.toLocaleString("en-IN")}`
                      : "";
          }

          // Hidden fields
          if (hf) {
              const sortedBillIds = Array.from(selectedBills.entries())
                  .sort((a, b) => b[1] - a[1])
                  .map(([billId]) => billId);
              hf.value = sortedBillIds.join(",");
          }

          if (hfMin) hfMin.value = minAmount.toFixed(2);

          // Control textbox (disabled for now)
          /*
          if (txtAmt) {
              if (selectedBills.size === 0) {
                  txtAmt.value = "";
                  txtAmt.disabled = true;
                  userEdited = false;
              } else if (!hasAddon) {
                  txtAmt.value = totalAmount.toFixed(2);
                  txtAmt.disabled = true;
                  userEdited = false;
              } else {
                  txtAmt.disabled = false;
                  if (!userEdited && (!txtAmt.value || txtAmt.value === "0")) {
                      txtAmt.value = totalAmount.toFixed(2);
                  }
              }
          }
          */
      }

      // Validate before submit
      function validateAmount() {
        const txtAmt = document.getElementById("<%= txtAmt.ClientID %>");
        const hfMin = document.getElementById("<%= hfMinAmount.ClientID %>");
        const minAmt = parseFloat(hfMin?.value || "0");
        const enteredAmt = parseFloat(txtAmt?.value || "0");

        if (enteredAmt < minAmt) {
            alert(`Amount entered is less than the minimum amount ₹${minAmt.toLocaleString("en-IN")}.`);
            return false;
        }

          return true;
      }

      // Preserve state after partial postback
      Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
          const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
        const lblTotal = document.getElementById("<%= lblTotalAmount.ClientID %>");
        const txtAmt = document.getElementById("<%= txtAmt.ClientID %>");
        const lblMinAmt = document.getElementById("<%= lblMinAmt.ClientID %>");
        const hfMin = document.getElementById("<%= hfMinAmount.ClientID %>");

        selectedBills = new Map();
        totalAmount = 0;
        minAmount = 0;
        userEdited = false;

        if (hf && hf.value) {
            const ids = hf.value.split(",");
            ids.forEach(id => {
                const el = document.querySelector(`[data-bill-id='${id}']`);
                if (el) {
                    const type = el.getAttribute("data-bill-type");
                    selectedBills.set(id, type);
                    el.classList.add("vBill-selected");
                    const amtText = el.querySelector(".vBill-amount").innerText;
                    const amt = parseFloat(amtText.replace(/[^0-9.]/g, ""));
                    totalAmount += amt;
                    if (type === "1") minAmount += amt;
                }
            });
        }

        if (lblTotal) {
            //txtAmt.value = totalAmount.toFixed(2);
            lblTotal.innerText = totalAmount.toLocaleString("en-IN", {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            });
        }

        if (lblMinAmt && minAmount > 0) {
            lblMinAmt.innerText =
                selectedBills.size > 0 && minAmount > 0
                    ? `Minimum amount is: ₹${minAmount.toLocaleString("en-IN")}`
                    : "";
        }

        /*
        if (txtAmt) {
            const hasAddon = Array.from(selectedBills.values()).includes("0");
            txtAmt.disabled = !hasAddon;
            if (!userEdited) {
                txtAmt.value = totalAmount.toFixed(2);
            }
        }
        */

        if (hfMin) hfMin.value = minAmount.toFixed(2);
    });

    //---------------------------------------------------------------------------------------------------------
    function showModal() {
        $('#paymentModal').modal('show');
    }

    function initDropdownEvents() {
        const categoryBox = document.getElementById("<%= txtResident.ClientID %>");
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
                noMatchMessage.innerHTML = "No matching vendors found.";
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
        document.getElementById("<%= txtResident.ClientID %>").value = value;
        document.getElementById("RepeaterContainer1").style.display = "none";

        const hf = document.getElementById("<%= hfSelectedBills.ClientID %>");
        hf.value = "";
        selectedBills.clear();
    }

    // Initialize on Sys.Application load
    Sys.Application.add_load(function () {
        initDropdownEvents();
    });

    // Search and Filter Functions
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

      function triggerSearch() {
          var btn = document.getElementById('btn_search');
          if (btn) {
              btn.click();   // ✅ correct
          }
      }

      // SweetAlert notifications
      function FailedEntryy() {
          Swal.fire({
              title: '❌ Rejected!',
              text: '',
              icon: 'error',
              showConfirmButton: true,
              confirmButtonColor: '#d33',
              confirmButtonText: 'Retry',
              timer: 1500,
              branding: false,
              timerProgressBar: true,
              didOpen: () => {
                  Swal.showLoading();
              }
          });
      }

      function SuccessEntryy() {
          Swal.fire({
              title: '✅ Approved!',
              text: '',
              icon: 'success',
              showConfirmButton: true,
              confirmButtonColor: '#3085d6',
              confirmButtonText: 'OK',
              timer: 1500,
              branding: false,
              timerProgressBar: true,
              didOpen: () => {
                  Swal.showLoading();
              },
              willClose: () => {
                  //$('#paymentModal').modal('hide');
              }
          });

          $('#paymentModal').modal('hide');
      }

      function hidePanel() {
          // Hide the Bill Details panel by setting its display to none
          var pnl = document.getElementById('<%= pnlBillDetails.ClientID %>');
                      if (pnl) {
                          pnl.style.display = 'none';
                      }
      }


      function downloadPaymentsPDF() {

          document.getElementById("pdfLoader").style.display = "flex";
          document.querySelectorAll(".hide-on-pdf").forEach(el => el.style.display = "none");

          const gridElement = document.getElementById("<%= paymentsGridWrapper.ClientID %>");
          const pdf = new jspdf.jsPDF("p", "mm", "a4");

          html2canvas(gridElement, { scale: 2, useCORS: true }).then(canvas => {

              const imgData = canvas.toDataURL("image/png");

              const pdfWidth = pdf.internal.pageSize.getWidth();
              const pdfHeight = pdf.internal.pageSize.getHeight();

              const margin = 15;
              const usableWidth = pdfWidth - margin * 2;
              const usableHeight = pdfHeight - margin * 2;

              const totalImgHeight = (canvas.height * usableWidth) / canvas.width;
              const totalPages = Math.ceil(totalImgHeight / usableHeight);

              for (let pageIndex = 0; pageIndex < totalPages; pageIndex++) {
                  const pageCanvas = document.createElement("canvas");
                  pageCanvas.width = canvas.width;
                  pageCanvas.height = usableHeight * canvas.width / usableWidth;

                  const pageContext = pageCanvas.getContext("2d");

                  pageContext.drawImage(
                      canvas,
                      0,
                      pageIndex * pageCanvas.height,
                      canvas.width,
                      pageCanvas.height,
                      0,
                      0,
                      pageCanvas.width,
                      pageCanvas.height
                  );

                  const pageImgData = pageCanvas.toDataURL("image/png");
                  const pageImgHeight = (pageCanvas.height * usableWidth) / pageCanvas.width;

                  if (pageIndex !== 0) pdf.addPage();
                  pdf.addImage(pageImgData, "PNG", margin, margin, usableWidth, pageImgHeight);
              }

              pdf.save("payments-grid.pdf");

              document.querySelectorAll(".hide-on-pdf").forEach(el => el.style.display = "");
              document.getElementById("pdfLoader").style.display = "none";
          });
      }


function downloadGridViewAsPDF() {
    // Show loader
    showPDFLoader();
    
    // Small delay to ensure loader displays
    setTimeout(() => {
        try {
            // Get the GridView table
            const gridView = document.getElementById('<%= gvPayments.ClientID %>');
            
            if (!gridView) {
                alert('GridView not found!');
                hidePDFLoader();
                return;
            }
            
            // Extract headers (excluding Actions column)
            const headers = [];
            const headerRow = gridView.querySelector('thead tr, tbody tr:first-child');
            
            if (headerRow) {
                const headerCells = headerRow.querySelectorAll('th, td');
                headerCells.forEach((cell, index) => {
                    const headerText = cell.innerText.trim();
                    // Skip the Actions column
                    if (headerText.toLowerCase() !== 'actions') {
                        headers.push(headerText);
                    }
                });
            }
            
            // Extract data rows (excluding Actions column)
            const data = [];
            const rows = gridView.querySelectorAll('tbody tr, tr');
            
            rows.forEach((row, index) => {
                // Skip header row if it's in tbody
                if (index === 0 && row.querySelector('th')) {
                    return;
                }
                
                const cells = row.querySelectorAll('td');
                if (cells.length === 0) return;
                
                const rowData = [];
                cells.forEach((cell, cellIndex) => {
                    // Check if this column is Actions by checking if it contains buttons
                    const hasButton = cell.querySelector('input[type="submit"], button, .btn');
                    
                    if (!hasButton) {
                        rowData.push(cell.innerText.trim());
                    }
                });
                
                if (rowData.length > 0) {
                    data.push(rowData);
                }
            });
            
            if (data.length === 0) {
                alert('No data to export!');
                hidePDFLoader();
                return;
            }
            
            // Create PDF with proper margins
            const { jsPDF } = window.jspdf;
            const pdf = new jsPDF('p', 'mm', 'a4');
            
            // Page dimensions and margins
            const pageWidth = pdf.internal.pageSize.getWidth();
            const pageHeight = pdf.internal.pageSize.getHeight();
            const margin = 15; // 15mm margins on all sides
            
            // Add title
            pdf.setFontSize(16);
            pdf.setFont(undefined, 'bold');
            pdf.text('Payment Records', margin, margin + 5);
            
            // Add date
            pdf.setFontSize(10);
            pdf.setFont(undefined, 'normal');
            const currentDate = new Date().toLocaleDateString('en-GB');
            pdf.text(`Generated on: ${currentDate}`, margin, margin + 12);
            
            // Configure autoTable with proper settings
            pdf.autoTable({
                head: [headers],
                body: data,
                startY: margin + 18,
                margin: { top: margin, right: margin, bottom: margin, left: margin },
                
                // Styling
                styles: {
                    fontSize: 9,
                    cellPadding: 3,
                    overflow: 'linebreak',
                    halign: 'left'
                },
                
                headStyles: {
                    fillColor: [0, 123, 255], // Bootstrap blue
                    textColor: 255,
                    fontStyle: 'bold',
                    halign: 'center'
                },
                
                alternateRowStyles: {
                    fillColor: [245, 245, 245]
                },
                
                // Prevent row breaking across pages
                rowPageBreak: 'avoid',
                
                // Add page numbers
                didDrawPage: function(data) {
                    // Footer with page number
                    pdf.setFontSize(8);
                    pdf.setTextColor(128);
                    const pageNumber = 'Page ' + pdf.internal.getNumberOfPages();
                    pdf.text(
                        pageNumber,
                        pageWidth - margin - pdf.getTextWidth(pageNumber),
                        pageHeight - 10
                    );
                }
            });
            
            // Save the PDF
            pdf.save('Payment_Records_' + currentDate.replace(/\//g, '-') + '.pdf');
            
            // Hide loader after successful generation
            setTimeout(() => {
                hidePDFLoader();
            }, 500);
            
        } catch (error) {
            console.error('Error generating PDF:', error);
            alert('Error generating PDF. Please try again.');
            hidePDFLoader();
        }
    }, 10);
}

// Loader functions
function showPDFLoader() {
    // Check if loader already exists
    if (document.getElementById('pdfLoader')) {
        return;
    }
    
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
                <div class="pdf-loader-dots">
                    <div class="pdf-loader-dot"></div>
                    <div class="pdf-loader-dot"></div>
                    <div class="pdf-loader-dot"></div>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', loaderHTML);
}

function hidePDFLoader() {
    const loader = document.getElementById('pdfLoader');
    if (loader) {
        loader.style.opacity = '0';
        setTimeout(() => loader.remove(), 300);
    }
}

// Add CSS for the loader (add this in your page head or stylesheet)
const loaderCSS = `
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
    transition: opacity 0.3s ease;
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
</style>
`;

// Inject loader styles on page load
if (!document.getElementById('pdf-loader-styles')) {
    document.head.insertAdjacentHTML('beforeend', loaderCSS);
    const styleMarker = document.createElement('div');
    styleMarker.id = 'pdf-loader-styles';
    styleMarker.style.display = 'none';
    document.body.appendChild(styleMarker);
}


  </script>

</asp:Content>
