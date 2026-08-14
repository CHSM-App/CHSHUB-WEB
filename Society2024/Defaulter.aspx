<%@ Page Language="C#" 
    Async="true" 
    AutoEventWireup="true" 
    CodeBehind="Defaulter.aspx.cs" 
    Inherits="Society.Defaulter" 
    MasterPageFile="~/Site.Master" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    
    <!-- Responsive Styles -->
    <style>
        /* Base responsive styles */
        * {
            box-sizing: border-box;
        }

        .container-fluid {
            padding: 15px;
            max-width: 100%;
            overflow-x: hidden;
        }

        /* Communication Toggle - Responsive */
        .communication-toggle {
            display: flex;
            background: white;
            border-radius: 12px;
            padding: 4px;
            width: 100%;
            max-width: 300px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            margin-bottom: 17px;
        }

        @media (min-width: 768px) {
            .communication-toggle {
                width: 250px;
            }
        }

        .toggle-option {
            flex: 1;
            padding: 8px 12px;
            border: none;
            background: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 500;
            font-size: 14px;
            text-align: center;
        }

        .toggle-option.active {
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
        }

        /* Email Composer - Responsive */
        .email-composer {
            background: white;
            border-radius: 16px;
            padding: 15px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        @media (min-width: 768px) {
            .email-composer {
                padding: 24px;
            }
        }

        .email-textarea {
            width: 100%;
            min-height: 120px;
            padding: 12px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-family: inherit;
            font-size: 14px;
            resize: vertical;
            transition: all 0.3s ease;
        }

        @media (min-width: 768px) {
            .email-textarea {
                min-height: 150px;
                padding: 16px;
                font-size: 16px;
            }
        }

        .email-textarea:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        .email-actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 16px;
            flex-wrap: wrap;
            gap: 12px;
        }

        @media (max-width: 576px) {
            .email-actions {
                flex-direction: column;
                align-items: stretch;
            }
            
            .email-actions .btn {
                width: 100%;
                margin-top: 10px;
            }
        }

        /* Button Styles - Responsive */
        .btn-primary {
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 500;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(59, 130, 246, 0.3);
        }

        .btn-success, .btn {
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 14px;
            margin: 2px;
        }

        @media (max-width: 576px) {
            .btn-group-mobile {
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            
            .btn-group-mobile .btn {
                width: 100%;
                margin: 2px 0;
            }
        }

        .aspNetTextBox {
            width: 100%;
            padding: 10px 45px 10px 15px;
            border: 2px solid #e2e8f0;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .aspNetTextBox:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        /* Header Section - Responsive */
        .page-header {
            margin-bottom: 20px;
        }

        .page-header h1 {
            font-size: 1.8rem;
            color: #012970;
            margin-bottom: 15px;
        }

        @media (max-width: 576px) {
            .page-header h1 {
                font-size: 1.5rem;
            }
        }

        /* Controls Section - Responsive */
        .controls-section {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 15px;
            margin-bottom: 20px;
        }

        @media (max-width: 768px) {
            .controls-section {
                flex-direction: column;
                align-items: stretch;
            }
        }

        .search-controls {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 10px;
            flex-grow: 1;
        }

        @media (max-width: 576px) {
            .search-controls {
                flex-direction: column;
                width: 100%;
            }
        }

        /* Select All Checkbox - Responsive */
        .select-all-container {
            display: flex;
            align-items: center;
            margin-top: 10px;
        }

        .select-all-label {
            cursor: pointer;
            display: inline-block;
            padding: 8px 16px;
            background-color: #f0f0f0;
            border: 1px solid #ccc;
            border-radius: 5px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .select-all-label:hover {
            background-color: #e0e0e0;
        }

        /* Total Due Section - Responsive */
        .total-due-section {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 15px;
            border-radius: 8px;
            background-color: #f8f9fa;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            min-width: 200px;
        }

        @media (max-width: 768px) {
            .total-due-section {
                width: 100%;
                margin-top: 15px;
            }
        }

        .total-due-content h3 {
            margin-bottom: 5px;
            font-weight: bold;
            color: #012970;
            font-size: 1.1rem;
        }

        @media (max-width: 576px) {
            .total-due-content h3 {
                font-size: 1rem;
            }
        }

        .total-due-amount {
            display: flex;
            justify-content: center;
            align-items: baseline;
            font-size: 18px;
            color: #28a745;
            font-weight: 600;
        }

        /* GridView - Responsive */
        .gridview-container {
            width: 100%;
            overflow-x: auto;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .table-responsive {
            min-height: 200px;
        }

        .table {
            margin-bottom: 0;
            font-size: 14px;
        }

        @media (max-width: 768px) {
            .table {
                font-size: 12px;
            }
            
            .table th,
            .table td {
                padding: 6px 4px;
                white-space: nowrap;
            }
        }

        @media (max-width: 576px) {
            .table th,
            .table td {
                padding: 4px 2px;
                font-size: 11px;
            }
        }

        /* Pagination - Responsive */
        .pagination-container {
            text-align: center;
            padding: 15px;
            background: white;
        }

        .pagination-container table {
            margin: 0 auto;
        }

        .pagination-container td {
            padding: 5px;
        }

        @media (max-width: 576px) {
            .pagination-container td {
                padding: 2px;
            }
            
            .pagination-container a,
            .pagination-container span {
                font-size: 12px;
                padding: 4px 6px;
            }
        }

        /* Modal - Responsive */
        @media (max-width: 768px) {
            .modal-dialog {
                margin: 10px;
                max-width: calc(100% - 20px);
            }
            
            .modal-body {
                padding: 15px;
            }
            
            .modal-body .table {
                font-size: 11px;
            }
        }

        /* Recipient Count - Responsive */
        .recipient-count {
            font-size: 14px;
            color: #6b7280;
            font-weight: 500;
        }

        @media (max-width: 576px) {
            .recipient-count {
                font-size: 12px;
                text-align: center;
                width: 100%;
            }
        }

        /* Utility Classes */
        .mobile-stack {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }

        @media (max-width: 576px) {
            .mobile-stack {
                flex-direction: column;
            }
        }

        .mobile-full-width {
            width: 100%;
        }

        @media (min-width: 577px) {
            .mobile-full-width {
                width: auto;
            }
        }

        /* Box styling - Responsive */
        .box {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
            min-width: 75vw;
        }

        .box-body {
            padding: 15px;
        }

        @media (min-width: 768px) {
            .box-body {
                padding: 25px;
            }
        }

        /* Print styles */
        @media print {
            .btn, .search-container, .communication-toggle, .email-composer {
                display: none !important;
            }
        }

        /* Main Grid Styles */
        .main-grid {
            width: 100%;
            border-collapse: collapse;
            background-color: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .main-grid th {
            background-color: #2C5282;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            border: 1px solid #ddd;
        }

        .main-grid td {
            padding: 10px 12px;
            border: 1px solid #ddd;
            transition: all 0.3s ease;
        }

        .main-grid tr:hover td {
            background-color: #f0f0f0;
        }

        /* View Details Button */
        .btn-view-details {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        .btn-view-details:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        /* Payment Details Modal */
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 0;
        }

        .modal-header .close {
            color: white;
            opacity: 0.8;
        }

        .modal-header .close:hover {
            opacity: 1;
        }

        /* Payment Details Grid */
        .payment-details-grid {
            width: 100%;
            border-collapse: collapse;
        }

        .payment-details-grid th {
            background-color: #E6F2FF;
            color: #2C5282;
            padding: 10px;
            text-align: left;
            font-weight: 500;
            border: 1px solid #ddd;
        }

        .payment-details-grid td {
            padding: 8px 10px;
            border: 1px solid #ddd;
        }

        .payment-details-grid tr:nth-child(even) {
            background-color: #f8f8f8;
        }

        .payment-details-grid tr:hover {
            background-color: #e3f2fd;
        }
        #pdfmodal table {
    border-collapse: collapse !important;
}

#pdfmodal table,
#pdfmodal th,
#pdfmodal td {
    border: 1px solid #333333 !important;   /* 🔥 PURE BLACK */
}

#pdfmodal th {
    background-color: #012970 !important;
    color: #ffffff !important;
    font-weight: bold;
}

#pdfmodal td {
    color: #000000 !important;
}

    </style>

    <div class="con">
        <div class="box box-primary">
            <div class="box-body">
                
                <!-- Page Header -->
                <div class="page-header">
                    <h1 class="font-weight-bold">Defaulters</h1>
                </div>

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="society_name" runat="server" />
                        
                        <!-- Controls Section -->
                        <div class="controls-section">
                            <div class="search-controls">
                                <!-- Search Container -->
                                <div class="search-container">
                                    <asp:TextBox
                                        ID="txt_search"
                                        CssClass="aspNetTextBox"
                                        placeHolder="Search here"
                                        runat="server"
                                        TextMode="Search"
                                        AutoPostBack="true"
                                        autocomplete="off"
                                        onkeyup="filterTable()" />

                                    <div class="input-buttons">
                                        <button
                                            id="btn_search"
                                            type="submit"
                                            class="search-button2"
                                            runat="server"
                                            onclick="filterTable()">
                                            <span class="material-symbols-outlined">search</span>
                                        </button>
                                    </div>
                                </div>

                                <!-- Action Buttons -->

                                <div class="btn-group-mobile mobile-stack">
                                    <button class="btn btn-primary mobile-full-width" onclick="printDefaultersearch()">Print</button>
                                    <button class="btn btn-success mobile-full-width" onclick="downloadReceipt()">Download PDF</button>
                                </div>
                                
                                <!-- Select All -->
                                <div class="select-all-container">
                                    <asp:CheckBox
                                        ID="select_all"
                                        runat="server"
                                        AutoPostBack="true"
                                        OnCheckedChanged="select_all_CheckedChanged"
                                        Style="display: none;" />
                                    <label for="<%= select_all.ClientID %>" class="select-all-label">
                                        Select All
                                    </label>
                                </div>
                            </div>

                            <!-- Total Due Section -->
                            <div class="total-due-section">
                                <div class="total-due-content text-center">
                                    <h3>Total Due</h3>
                                    <div class="total-due-amount">
                                        <span>₹</span>&nbsp;<asp:Label runat="server" ID="lbl_due" ForeColor="#212529"></asp:Label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- GridView Section -->
                        <div class="gridview-container">
                            <div class="table-responsive">
                                <asp:GridView ID="gvOwners" runat="server"
                                    AutoGenerateColumns="False"
                                    CssClass="main-grid"
                                    OnRowDataBound="gvOwners_RowDataBound"
                                    DataKeyNames="flat_id">

                                    <Columns>
                                        <asp:TemplateField HeaderText="Details">
                                            <ItemTemplate>
                                                <asp:LinkButton ID="btnViewDetails" runat="server" 
                                                    CssClass="btn-view-details"
                                                    OnClick="btnViewDetails_Click"
                                                    Text="View Details">
                                                    <i class="fa fa-eye"></i>
                                                </asp:LinkButton>
                                            </ItemTemplate>
                                        </asp:TemplateField>

                                        <asp:BoundField DataField="owner_name" HeaderText="Owner Name" />
                                        <asp:BoundField DataField="bed" HeaderText="BED" />
                                        <asp:BoundField DataField="Unit" HeaderText="Unit" />
                                        <asp:BoundField DataField="flat_no" HeaderText="Flat no" />
                                        <asp:BoundField DataField="email" HeaderText="Email" />
                                        <asp:BoundField DataField="pre_mob" HeaderText="Mobile" />
                                        <asp:BoundField DataField="due" HeaderText="Due" DataFormatString="{0:N2}" />
                                        
                                        <asp:TemplateField HeaderText="Select" ItemStyle-Width="100">
                                            <ItemTemplate>
                                                <asp:CheckBox ID="CheckBox1" runat="server" onchange="updateRecipientCount()" />
                                                <asp:Label ID="email" runat="server" Text='<%# Eval("email") %>' Visible="false"></asp:Label>
                                                <asp:Label ID="owner_name" runat="server" Text='<%# Eval("owner_name") %>' Visible="false"></asp:Label>
                                                <asp:Label ID="mobile_no" runat="server" Text='<%# Eval("pre_mob") %>' Visible="false"></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>
                            </div>
                        </div>

                        <!-- Hidden Buttons -->
                        <asp:Button ID="Button1" runat="server"
                                    OnClick="btn_send_email_Click" UseSubmitBehavior="False" style="display:none" />
                        <asp:Button ID="Button2" runat="server"
                                    OnClick="btn_send_sms_Click" style="display:none" UseSubmitBehavior="False" />
                        <asp:HiddenField ID="hf_message_content" runat="server" />

                        <!-- Communication Toggle -->
                        <div class="communication-toggle">
                            <button type="button" class="toggle-option active" onclick="switchMode('email')">
                                📧 Email
                            </button>
                            <button type="button" class="toggle-option" onclick="switchMode('sms')">
                                📱 SMS
                            </button>
                        </div>

                        <!-- Email Composer -->
                        <div class="email-composer">
                            <asp:TextBox
                                class="email-textarea"
                                ID="messageContent"
                                runat="server"
                                Text=" Dear Residents,

We hope this message finds you well. This is a gentle reminder that your maintenance payments are currently overdue.

Please arrange for the payment at your earliest convenience to avoid any inconvenience.

For any queries, please feel free to contact us.

Best regards,
Property Management Team" TextMode="MultiLine"></asp:TextBox>

                            <div class="email-actions">
                                <div class="recipient-count" id="recipientCount">
                                    No recipients selected (0 selected)
                                </div>
                                <button
                                    type="button"
                                    class="btn btn-primary"
                                    onclick="sendCommunication()"
                                    id="sendButton"
                                    disabled>
                                    📤 Send Message
                                </button>
                            </div>
                        </div>

                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>

    <!-- Payment Details Modal -->
    <div class="modal fade" id="paymentDetailsModal" tabindex="-1" role="dialog" aria-labelledby="paymentDetailsLabel">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="paymentDetailsLabel">Payment Details</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body paymentDetailsPdf">
                    <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="detailedPay">
                        <ContentTemplate>

                            <asp:Label ID="lblOwnerName" runat="server" CssClass="font-weight-bold d-block"></asp:Label>
                            <asp:Label ID="lblFlatId" runat="server" CssClass="text-muted d-block mb-3"></asp:Label>


                            <asp:GridView ID="gvPaymentDetails" runat="server"
                                CssClass="payment-details-grid"
                                AutoGenerateColumns="False"
                                ShowHeaderWhenEmpty="true"
                                EmptyDataText="No payment details available.">
                                <Columns>
                                    <asp:BoundField DataField="month" HeaderText="Month" />
                                    <asp:BoundField DataField="tax_interest_amt" HeaderText="Tax" DataFormatString="{0:N2}" />
                                    <asp:BoundField DataField="amt_forward" HeaderText="Amount Forward" DataFormatString="{0:N2}" />
                                </Columns>
                            </asp:GridView>

                            <asp:Label ID="lblTotalForward" runat="server"
                                CssClass="font-weight-bold text-right d-block mt-3">
                            </asp:Label>

                        </ContentTemplate>


                    </asp:UpdatePanel>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <button type="button"
        class="btn btn-primary"
        onclick="downloadPaymentDetailsPdf()">
    Download PDF
</button>

                </div>
            </div>
        </div>
    </div>

    <!-- PDF Modal -->
    <div class="modal fade bs-example-modal-sm" 
         id="pdfmodal" 
         role="form" 
         aria-labelledby="myLargeModalLabel" 
         data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <div class="modal-content resized-model">
                
                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center">
                        <strong>Defaulters Details</strong>
                    </h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">
                    
                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->
                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">
                        <asp:GridView ID="GridView3" 
                                      runat="server"
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
                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                    <ItemTemplate>
                                        <asp:Label ID="Label1" 
                                                   runat="server" 
                                                   Text='<%# Container.DataItemIndex + 1 %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:BoundField HeaderText="Owner Name" 
                                                DataField="owner_name" 
                                                SortExpression="owner_name" 
                                                ItemStyle-Width="100" />
                                <asp:BoundField HeaderText="Type" 
                                                DataField="bed" 
                                                SortExpression="bed" 
                                                ItemStyle-Width="100" />
                                <asp:BoundField HeaderText="Unit" 
                                                DataField="unit" 
                                                SortExpression="unit" 
                                                ItemStyle-Width="100" />
                                <asp:BoundField HeaderText="Email" 
                                                DataField="email" 
                                                SortExpression="o_name" 
                                                ItemStyle-Width="100" />
                                <asp:BoundField HeaderText="Contact No" 
                                                DataField="pre_mob" 
                                                SortExpression="chqno" 
                                                ItemStyle-Width="100" />
                                <asp:BoundField HeaderText="Due (Including GST)" 
                                                DataField="due" 
                                                SortExpression="due" 
                                                ItemStyle-Width="100" />
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- PDF Clone Container -->
    <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>

    <!-- External Scripts -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>


<script>
    document.addEventListener('DOMContentLoaded', function () {
        const mainGrid = document.querySelector('.main-grid');
        if (!mainGrid) return;

        let openChildRow = null;
        let openIcon = null;
        let openParentRow = null;

        mainGrid.addEventListener('click', function (e) {
            const row = e.target.closest('tr');

            // Ignore clicks inside child rows
            if (!row || row.classList.contains('child-row')) return;

            const icon = row.querySelector('.expand-icon');
            const childRow = row.nextElementSibling;

            if (!icon || !childRow || !childRow.classList.contains('child-row')) return;

            // CASE 1: Clicked the already open row -> toggle close with animation
            if (openChildRow === childRow) {
                icon.classList.remove('expanded');
                childRow.classList.remove('show');
                row.classList.remove('row-expanded');

                // Reset references
                openChildRow = null;
                openIcon = null;
                openParentRow = null;
                return;
            }

            // CASE 2: Close previously open row with animation
            if (openChildRow) {
                openChildRow.classList.remove('show');
                if (openIcon) openIcon.classList.remove('expanded');
                if (openParentRow) openParentRow.classList.remove('row-expanded');
            }

            // CASE 3: Open the clicked one with animation
            icon.classList.add('expanded');
            row.classList.add('row-expanded');

            // Small delay to ensure smooth animation
            setTimeout(() => {
                childRow.classList.add('show');
            }, 10);

            // Update references
            openChildRow = childRow;
            openIcon = icon;
            openParentRow = row;

            // Smooth scroll to expanded row
            setTimeout(() => {
                row.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }, 300);
        });

        // Add hover effect to expand icons
        const expandIcons = mainGrid.querySelectorAll('.expand-icon');
        expandIcons.forEach(icon => {
            const parentTd = icon.closest('td');
            if (parentTd) {
                parentTd.addEventListener('mouseenter', function () {
                    if (!icon.classList.contains('expanded')) {
                        icon.style.transform = 'scale(1.2)';
                    }
                });
                parentTd.addEventListener('mouseleave', function () {
                    if (!icon.classList.contains('expanded')) {
                        icon.style.transform = 'scale(1)';
                    }
                });
            }
        });
    });
</script>

    <!-- JavaScript Functions -->
    <script>

        function downloadPaymentDetailsPdf() {
            // jsPDF (UMD)
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF('p', 'mm', 'a4');

            /* ===============================
               SAFE DATA EXTRACTION
            =============================== */

            const ownerNameEl = document.getElementById('<%= lblOwnerName.ClientID %>');
            const flatIdEl = document.getElementById('<%= lblFlatId.ClientID %>');
    const totalForwardEl = document.getElementById('<%= lblTotalForward.ClientID %>');
            const table = document.getElementById('<%= gvPaymentDetails.ClientID %>');

            if (!ownerNameEl || !flatIdEl || !totalForwardEl || !table) {
                console.error('Required elements not found for PDF generation');
                return;
            }

            const ownerName = ownerNameEl.innerText.trim();
            const flatId = flatIdEl.innerText.trim();

            // 🔴 IMPORTANT: extract only numeric part from total
            const rawTotalText = totalForwardEl.innerText;
            const amountMatch = rawTotalText.match(/[\d,.]+/);
            const numericAmount = amountMatch
                ? parseFloat(amountMatch[0].replace(/,/g, ''))
                : 0;

            const formattedTotal = numericAmount.toLocaleString('en-IN', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            });

            const rows = table.querySelectorAll('tr');

            /* ===============================
               PAGE SETUP
            =============================== */

            const pageWidth = doc.internal.pageSize.getWidth();
            const pageHeight = doc.internal.pageSize.getHeight();
            const margin = 15;
            let yPos = margin;

            /* ===============================
               HEADER
            =============================== */

            doc.setFillColor(41, 128, 185);
            doc.rect(0, 0, pageWidth, 40, 'F');

            doc.setTextColor(255, 255, 255);
            doc.setFontSize(20);
            doc.setFont(undefined, 'bold');
            doc.text('Payment Details', pageWidth / 2, 20, { align: 'center' });

            doc.setFontSize(10);
            doc.setFont(undefined, 'normal');
            doc.text(
                `Generated on: ${new Date().toLocaleDateString('en-IN')}`,
                pageWidth / 2,
                30,
                { align: 'center' }
            );

            yPos = 55;

            /* ===============================
               OWNER INFO
            =============================== */

            doc.setTextColor(0, 0, 0);
            doc.setFontSize(12);
            doc.setFont(undefined, 'bold');
            doc.text('Owner Information', margin, yPos);

            yPos += 8;
            doc.setFontSize(10);
            doc.setFont(undefined, 'normal');
            doc.text(`Name: ${ownerName}`, margin + 5, yPos);

            yPos += 6;
            doc.text(`Flat ID: ${flatId}`, margin + 5, yPos);

            yPos += 15;

            /* ===============================
               TABLE HEADER
            =============================== */

            doc.setFontSize(12);
            doc.setFont(undefined, 'bold');
            doc.text('Payment Breakdown', margin, yPos);

            yPos += 10;

            const colWidths = [60, 50, 60];
            const startX = margin;
            const tableWidth = colWidths.reduce((a, b) => a + b, 0);

            doc.setFillColor(52, 73, 94);
            doc.rect(startX, yPos - 6, tableWidth, 10, 'F');

            doc.setTextColor(255, 255, 255);
            doc.setFontSize(10);
            doc.setFont(undefined, 'bold');

            let xPos = startX + 5;
            const headerCells = rows[0].querySelectorAll('th');

            headerCells.forEach((cell, i) => {
                if (i < colWidths.length) {
                    doc.text(cell.innerText.trim(), xPos, yPos);
                    xPos += colWidths[i];
                }
            });

            yPos += 8;

            /* ===============================
               TABLE ROWS
            =============================== */

            doc.setTextColor(0, 0, 0);
            doc.setFont(undefined, 'normal');

            let alternate = false;

            for (let i = 1; i < rows.length; i++) {
                const cells = rows[i].querySelectorAll('td');
                if (cells.length === 0) continue;

                if (alternate) {
                    doc.setFillColor(236, 240, 241);
                    doc.rect(startX, yPos - 6, tableWidth, 8, 'F');
                }

                xPos = startX + 5;
                cells.forEach((cell, idx) => {
                    if (idx < colWidths.length) {
                        const cleanText = cell.innerText
                            .replace(/\u00A0/g, ' ')
                            .trim();

                        doc.text(cleanText, xPos, yPos);
                        xPos += colWidths[idx];
                    }
                });

                yPos += 8;
                alternate = !alternate;

                if (yPos > pageHeight - 40) {
                    doc.addPage();
                    yPos = margin;
                }
            }

            /* ===============================
               TOTAL (FIXED)
            =============================== */


            yPos += 10;

            doc.setDrawColor(52, 73, 94);
            doc.setLineWidth(0.5);
            doc.line(startX, yPos - 5, startX + tableWidth, yPos - 5);

            yPos += 7;

            // Force safe font + spacing
            doc.setFont('helvetica', 'bold'); 
            doc.setFontSize(11);
            doc.setTextColor(41, 128, 185);

            // ⛔ Do NOT use template literals here
            console.log(formattedTotal);
            doc.text(
                'Total Amount Forward: ₹ ' + formattedTotal,
                startX + 5,
                yPos,
                { charSpace: 0 }
            );



            /* ===============================
               FOOTER
            =============================== */

            doc.setFontSize(8);
            doc.setTextColor(120, 120, 120);
            doc.setFont(undefined, 'normal');
            doc.text(
                'This is a system-generated document',
                pageWidth / 2,
                pageHeight - 10,
                { align: 'center' }
            );

            /* ===============================
               SAVE
            =============================== */

            const safeFlatId = flatId.replace(/[^a-zA-Z0-9]/g, '_');
            const fileName = `Payment_Details_${safeFlatId}_${Date.now()}.pdf`;

            doc.save(fileName);
        }



        function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
                 if (!input) return;

                 const filter = input.value.toLowerCase();
            const table = document.querySelector('.table-responsive');

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


        let formSubmitted = false;
        let currentMode = 'email'; // Default mode

        // Function to update recipient count
        function updateRecipientCount() {
            const checkboxes = document.querySelectorAll('#<%= gvOwners.ClientID %> input[type="checkbox"][id*="CheckBox1"]');
            const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;

            const recipientCountElement = document.getElementById('recipientCount');
            const sendButton = document.getElementById('sendButton');

            if (checkedCount > 0) {
                recipientCountElement.textContent = `${checkedCount} recipient${checkedCount > 1 ? 's' : ''} selected`;
                sendButton.disabled = false;
            } else {
                recipientCountElement.textContent = 'No recipients selected (0 selected)';
                sendButton.disabled = true;
            }
        }

        // Function to send communication
        function sendCommunication() {
            const messageContent = document.getElementById('<%= messageContent.ClientID %>').value.trim();
            const checkedCount = document.querySelectorAll('#<%= gvOwners.ClientID %> input[type="checkbox"][id*="CheckBox1"]:checked').length;

            if (checkedCount === 0) {
                alert('Please select at least one recipient.');
                return;
            }

            if (messageContent === '') {
                alert('Please enter a message.');
                return;
            }

            // Store message content in hidden field
            document.getElementById('<%= hf_message_content.ClientID %>').value = messageContent;

            // Call appropriate server-side function based on current mode
            if (currentMode === 'email') {
                document.getElementById('<%= Button1.ClientID %>').click();
            } else {
                document.getElementById('<%= Button2.ClientID %>').click();
            }
        }

        // PDF Download Functions
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
            clone.style.width = `${sourceElement.offsetWidth}px`;
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
                const title = "Defaulter Details";

                // Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40);

                // Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60;

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("DefaulterReport.pdf");
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

            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);

            /* 🔥 Force PDF styles */
            clone.style.background = "#ffffff";
            clone.querySelectorAll("table, th, td").forEach(el => {
                el.style.border = "2px solid #000";
                el.style.color = "#000";
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 4,                    // 🔥 HIGH DPI
                    useCORS: true,
                    backgroundColor: "#ffffff"
                });

                const imgData = canvas.toDataURL("image/jpeg", 1.0);
                const pdf = new jsPDF("p", "pt", "a4");

                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;

                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                pdf.text("Defaulters Details", pageWidth / 2, 40, { align: "center" });

                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;

                pdf.addImage(
                    imgData,
                    "JPEG",
                    margin,
                    60,
                    imgWidth,
                    imgHeight,
                    undefined,
                    "FAST"
                );

                pdf.save("DefaultersReport.pdf");

            } catch (err) {
                console.error(err);
                alert("PDF generate failed");
            }
        }

        //async function downloadReceipt() {
        //    const { jsPDF } = window.jspdf;
        //    const sourceElement = document.querySelector("#pdfmodal .modal-body");
        //    const cloneContainer = document.getElementById("pdf-clone-container");

        //    if (!sourceElement || !cloneContainer) {
        //        alert("Cannot find content to export.");
        //        return;
        //    }

        //    // Clone modal-body into offscreen div
        //    cloneContainer.innerHTML = "";
        //    const clone = sourceElement.cloneNode(true);
        //    cloneContainer.appendChild(clone);

        //    try {
        //        const canvas = await html2canvas(clone, {
        //            scale: 2,
        //            useCORS: true
        //        });

        //        const imgData = canvas.toDataURL("image/png");
        //        const pdf = new jsPDF("p", "pt", "a4");

        //        const pageWidth = pdf.internal.pageSize.getWidth();
        //        const margin = 40;
        //        const title = "Defaulters Details";

        //        // Add Centered Heading
        //        pdf.setFontSize(16);
        //        pdf.setFont("helvetica", "bold");
        //        const textWidth = pdf.getTextWidth(title);
        //        const x = (pageWidth - textWidth) / 2;
        //        pdf.text(title, x, 40);

        //        // Add Image Below Heading
        //        const imgWidth = pageWidth - margin * 2;
        //        const imgHeight = (canvas.height * imgWidth) / canvas.width;
        //        const imageY = 60;

        //        pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
        //        pdf.save("DefaultersReport.pdf");
        //    } catch (err) {
        //        console.error("Error generating PDF:", err);
        //        alert("Failed to generate PDF.");
        //    }
        //}

        // Print Function
        function printDefaultersearch() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;
            var printWindow = window.open('', '', 'height=700,width=900');

            printWindow.document.write('<html><head><title>Defaulter Details</title>');
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

            // Add centered headers manually
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>');
            printWindow.document.write('</div>');

            // Add GridView content
            printWindow.document.write(modalContent);

            // Print timestamp
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + new Date().toLocaleString() + '</div>');

            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

        // Communication Mode Switch Function (No Page Refresh)
        function switchMode(mode) {
            currentMode = mode;
            const buttons = document.querySelectorAll(".toggle-option");
            buttons.forEach((btn) => btn.classList.remove("active"));
            event.target.classList.add("active");

            const textarea = document.getElementById('<%= messageContent.ClientID %>');
            const sendButton = document.getElementById("sendButton");

            if (mode === "email") {
                textarea.value = `Dear Residents,

We hope this message finds you well. This is a gentle reminder that your maintenance payments are currently overdue.

Please arrange for the payment at your earliest convenience to avoid any inconvenience.

For any queries, please feel free to contact us.

Best regards,
Property Management Team`;
                sendButton.innerHTML = "📤 Send Email";
            } else {
                textarea.value = `Hi Residents, your maintenance payments are overdue. Please pay at your earliest convenience. Thank you - Management`;
                sendButton.innerHTML = "📱 Send SMS";
            }
        }

        // Initialize recipient count on page load
        document.addEventListener('DOMContentLoaded', function () {
            updateRecipientCount();
        });
    </script>

</asp:Content>  