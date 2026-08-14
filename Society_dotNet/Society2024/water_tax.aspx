<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="water_tax.aspx.cs" Inherits="Society2024.Water_tax" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

  <style>
        .container { margin-top: 30px; }
        .table th { background-color: #2c5282; color: white; }
        .btn-pay, .btn-receipt { padding: 5px 20px; }
        .nav-tabs { margin-bottom: 20px; }
        .receipt-container { padding: 30px; }
        .receipt-header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 15px; margin-bottom: 20px; }
        .receipt-row { display: flex; justify-content: space-between; margin-bottom: 10px; }
        .receipt-label { font-weight: bold; }
        .receipt-total { border-top: 2px solid #333; margin-top: 20px; padding-top: 10px; font-size: 1.2em; font-weight: bold; }
    </style>
    <body>
        <div class="box box-primary">
            <div class="box-header with-border">

                <div class="box-body">
                    <table width="100%">
                        <tr>
                            <th width="100%" class="">
                                <h1 class=" tex0 font-weight-bold " style="color: #012970;">House Tax
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
                                            placeHolder="Search here"
                                            runat="server"
                                            TextMode="Search"
                                            AutoPostBack="true"
                                            autocomplete="off"
                                            onkeyup="filterTable()" />

                                        <!-- Calendar and Search Buttons -->
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

                                    &nbsp;&nbsp;
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#import_model">Add</button>
                                </div>
                            </div>
                        </div>
                    </div>

       <div class="container">
            
            <!-- Nav Tabs -->
            <ul class="nav nav-tabs" id="myTab" role="tablist">
                <li class="nav-item">
                    <a class="nav-link active" id="pending-tab" data-toggle="tab" href="#pending" role="tab">Pending Bills</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" id="paid-tab" data-toggle="tab" href="#paid" role="tab">Paid Houses</a>
                </li>
            </ul>

            <!-- Tab Content -->
            <div class="tab-content" id="myTabContent">
                <!-- Pending Bills Tab -->
                <div class="tab-pane fade show active" id="pending" role="tabpanel">
                    <asp:UpdatePanel ID="upPending" runat="server">
                        <ContentTemplate>
                            <asp:GridView ID="gvPendingBills" runat="server" CssClass="table table-striped table-bordered" 
                                AutoGenerateColumns="False" OnRowCommand="gvPendingBills_RowCommand">
                                <Columns>
                                    <asp:BoundField DataField="Owner_Name" HeaderText="Owner Name" />
                                    <asp:BoundField DataField="House_No" HeaderText="House Number" />
                                    <asp:BoundField DataField="TotalTax" HeaderText="Total Tax" DataFormatString="{0:C2}" />
                                    <asp:BoundField DataField="DueDate" HeaderText="Due Date" DataFormatString="{0:MM/dd/yyyy}" />
                                    <asp:TemplateField HeaderText="Action">
                                        <ItemTemplate>
                                            <asp:Button ID="btnPay" runat="server" Text="Pay" CssClass="btn btn-success btn-pay"
                                                CommandName="Pay" CommandArgument='<%# Eval("House_Id") %>' 
                                                OnClientClick='<%# "showPaymentModal(" + Eval("House_Id") + ", \"" + Eval("Owner_Name") + "\", \"" + Eval("House_No") + "\", " + Eval("TotalTax") + "); return false;" %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </ContentTemplate>
                    </asp:UpdatePanel>
                </div>

                <!-- Paid Houses Tab -->
                <div class="tab-pane fade" id="paid" role="tabpanel">
                    <asp:UpdatePanel ID="upPaid" runat="server">
                        <ContentTemplate>
                            <asp:GridView ID="gvPaidHouses" runat="server" CssClass="table table-striped table-bordered" 
                                AutoGenerateColumns="False" OnRowCommand="gvPaidHouses_RowCommand">
                                <Columns>
                                    <asp:BoundField DataField="Owner_Name" HeaderText="Owner Name" />
                                    <asp:BoundField DataField="House_No" HeaderText="House Number" />
                                    <asp:BoundField DataField="TotalTax" HeaderText="Total Tax" DataFormatString="{0:C2}" />
                                    <asp:BoundField DataField="PaymentDate" HeaderText="Payment Date" DataFormatString="{0:MM/dd/yyyy}" />
                                    <asp:BoundField DataField="PaymentMethod" HeaderText="Payment Method" />
                                    <asp:TemplateField HeaderText="Action">
                                        <ItemTemplate>
                                            <asp:Button ID="btnReceipt" runat="server" Text="Receipt" CssClass="btn btn-info btn-receipt"
                                                CommandName="ViewReceipt" CommandArgument='<%# Eval("House_Id") %>' 
                                                OnClientClick='<%# "showReceiptModal(" + Eval("House_Id") + ", \"" + Eval("Owner_Name") + "\", \"" + Eval("House_No") + "\", " + Eval("TotalTax") + ", \"" + Eval("PaymentDate") + "\", \"" + Eval("PaymentMethod") + "\", \"" + Eval("TransactionRef") + "\"); return false;" %>' />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>
                        </ContentTemplate>
                    </asp:UpdatePanel>
                </div>
            </div>
        </div>
                    </div>
                </div>
            </div>
        
        <!-- Payment Modal -->
        <div class="modal fade" id="paymentModal" tabindex="-1" role="dialog" aria-labelledby="paymentModalLabel" aria-hidden="true">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="paymentModalLabel">Payment Details</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <asp:HiddenField ID="hdnHouseId" runat="server" />
                        
                        <div class="form-group">
                            <label>Owner Name:</label>
                            <asp:TextBox ID="txtOwnerName" runat="server" CssClass="form-control" ReadOnly="true"></asp:TextBox>
                        </div>
                        
                        <div class="form-group">
                            <label>House Number:</label>
                            <asp:TextBox ID="txtHouseNo" runat="server" CssClass="form-control" ReadOnly="true"></asp:TextBox>
                        </div>
                        
                        <div class="form-group">
                            <label>Total Tax Amount:</label>
                            <asp:TextBox ID="txtTotalTax" runat="server" CssClass="form-control" ReadOnly="true"></asp:TextBox>
                        </div>
                        
                        <div class="form-group">
                            <label>Payment Method:</label>
                            <asp:DropDownList ID="ddlPaymentMethod" runat="server" CssClass="form-control">
                                <asp:ListItem Value="">Select Payment Method</asp:ListItem>
                                <asp:ListItem Value="Cash">Cash</asp:ListItem>
                                <asp:ListItem Value="Card">Card</asp:ListItem>
                                <asp:ListItem Value="Online">Online Transfer</asp:ListItem>
                                <asp:ListItem Value="Cheque">Cheque</asp:ListItem>
                            </asp:DropDownList>
                        </div>
                        
                        <div class="form-group">
                            <label>Transaction Reference:</label>
                            <asp:TextBox ID="txtTransactionRef" runat="server" CssClass="form-control" placeholder="Enter reference number"></asp:TextBox>
                        </div>
                        
                        <div class="form-group">
                            <label>Remarks:</label>
                            <asp:TextBox ID="txtRemarks" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Any additional notes"></asp:TextBox>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                        <asp:Button ID="btnSubmitPayment" runat="server" Text="Submit Payment" CssClass="btn btn-primary" OnClick="btnSubmitPayment_Click" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Receipt Modal -->
        <div class="modal fade" id="receiptModal" tabindex="-1" role="dialog" aria-labelledby="receiptModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="receiptModalLabel">Payment Receipt</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <div class="receipt-container" id="receiptContent">
                            <div class="receipt-header">
                                <h3>House Tax Payment Receipt</h3>
                                <p>Tax Management Department</p>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">Receipt No:</span>
                                <span id="receiptNo"></span>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">Date:</span>
                                <span id="receiptDate"></span>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">Owner Name:</span>
                                <span id="receiptOwner"></span>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">House Number:</span>
                                <span id="receiptHouseNo"></span>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">Payment Method:</span>
                                <span id="receiptPaymentMethod"></span>
                            </div>
                            
                            <div class="receipt-row">
                                <span class="receipt-label">Transaction Reference:</span>
                                <span id="receiptTransactionRef"></span>
                            </div>
                            
                            <div class="receipt-total">
                                <div class="receipt-row">
                                    <span class="receipt-label">Total Amount Paid:</span>
                                    <span id="receiptAmount"></span>
                                </div>
                            </div>
                            
                            <div style="text-align: center; margin-top: 30px; font-style: italic;">
                                <p>Thank you for your payment!</p>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                        <button type="button" class="btn btn-primary" onclick="printReceipt()">Print Receipt</button>
                    </div>
                </div>
            </div>
        </div>

 <script type="text/javascript">
     function showPaymentModal(houseId, ownerName, houseNo, totalTax) {
         document.getElementById('<%= hdnHouseId.ClientID %>').value = houseId;
            document.getElementById('<%= txtOwnerName.ClientID %>').value = ownerName;
            document.getElementById('<%= txtHouseNo.ClientID %>').value = houseNo;
         document.getElementById('<%= txtTotalTax.ClientID %>').value = '₹' + totalTax.toFixed(2);
         $('#paymentModal').modal('show');
     }

     function showReceiptModal(houseId, ownerName, houseNo, totalTax, paymentDate, paymentMethod, transactionRef) {
         document.getElementById('receiptNo').innerText = 'RCP-' + houseId + '-' + new Date().getTime();
         document.getElementById('receiptDate').innerText = paymentDate;
         document.getElementById('receiptOwner').innerText = ownerName;
         document.getElementById('receiptHouseNo').innerText = houseNo;
         document.getElementById('receiptPaymentMethod').innerText = paymentMethod;
         document.getElementById('receiptTransactionRef').innerText = transactionRef || 'N/A';
         document.getElementById('receiptAmount').innerText = '₹' + parseFloat(totalTax).toFixed(2);
         $('#receiptModal').modal('show');
     }

     function printReceipt() {
         var printContent = document.getElementById('receiptContent').innerHTML;
         var originalContent = document.body.innerHTML;
         document.body.innerHTML = printContent;
         window.print();
         document.body.innerHTML = originalContent;
         location.reload();
     }
 </script>

    </body>
  
</asp:Content>
