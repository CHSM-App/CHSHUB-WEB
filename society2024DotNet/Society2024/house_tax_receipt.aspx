<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="house_tax_receipt.aspx.cs" MasterPageFile="~/Site.Master" Inherits="Society.house_tax_receipt" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <script type="text/javascript">

        function openModal() {
            $('#edit_model').modal('show');
        }


        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
        }

        function validateAndSubmit() {

            $('#emailmodal').modal('hide');
            return true;
        }
    </script>

    <script>
        function openEmailModal() {
            $('#emailmodal').modal('show');
        }
    </script>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <script type="text/javascript"> 
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

                }, willClose: () => {

                    window.location.href = 'house_tax_receipt.aspx';

                }

            });

        }

    </script>

    <div class="box box-primary">
        <div class="box-header with-border">

            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">House Tax Receipt</h1>
                        </th>
                    </tr>
                </table>
                <br />

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="house_receipt_id" runat="server" />
                        <asp:HiddenField ID="village_id" runat="Server"></asp:HiddenField>

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-12">
                                    <div class="d-flex align-items-center">

                                        <asp:DropDownList ID="search_field" runat="server" Width="200px" Height="32px" OnSelectedIndexChanged="search_field_SelectedIndexChanged" AutoPostBack="true">
                                            <asp:ListItem Value="house_no">House No</asp:ListItem>
                                            <asp:ListItem Value="pay_date">Pay Date</asp:ListItem>
                                            <asp:ListItem Value="house_tax">House Tax</asp:ListItem>
                                            <asp:ListItem Value="paid_amount">Paid Amount</asp:ListItem>

                                        </asp:DropDownList>&nbsp;&nbsp;
                      
                             <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btn_search" CssClass="d-flex align-items-center me-2">
                                 <asp:TextBox ID="txt_search" Style="text-transform: capitalize;" Width="200px" Height="32px" Font-Bold="true" placeholder="Search Here" runat="server"></asp:TextBox>&nbsp;&nbsp;
                        
                            <asp:Button ID="btn_search" runat="server" class="btn btn-primary" OnClick="btn_search_Click" Text="Search" UseSubmitBehavior="False" />
                             </asp:Panel>
                                        &nbsp;&nbsp; 
                        
                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-sm">New Entry</button>


                                    </div>
                                </div>
                            </div>
                        </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView ID="GridView1" runat="server" AllowPaging="true" PageSize="50" OnPageIndexChanging="GridView1_PageIndexChanging" OnRowEditing="GridView1_RowEditing" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowUpdating="GridView1_RowUpdating">
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="id" ItemStyle-Width="100" SortExpression="id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="house_receipt_id" runat="server" Text='<%# Bind("house_receipt_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="House No" SortExpression="house_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="house_no" runat="server" Text='<%# Bind("house_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="House Tax" SortExpression="house_tax">
                                                    <ItemTemplate>
                                                        <asp:Label ID="house_tax" runat="server" Text='<%# Bind("house_tax")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Pay Date" SortExpression="pay_date">
                                                    <ItemTemplate>
                                                        <asp:Label ID="pay_date" runat="server" Text='<%# Bind("pay_date","{0:yyyy-MM-dd}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Paid Amount" SortExpression="paid_amount">
                                                    <ItemTemplate>
                                                        <asp:Label ID="paid_amount" runat="server" Text='<%# (Eval("house_amount").ToString() != "0.00" ? Eval("house_amount"): Eval("water_amount"))%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" Text="Print" CommandName="Update" CommandArgument='<%# Bind("house_receipt_id")%>'><img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Print" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Button runat="server" ID="Print" OnCommand="Print_Command" Text="Print" CommandName="Edit" CommandArgument='<%# Bind("house_receipt_id")%>'></asp:Button>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="Delete" OnCommand="Delete_Command" CommandName="Delete" CommandArgument='<%# Bind("house_receipt_id")%>'> <img src="Images/delete_10781634.png" height="25" width="25" /></asp:LinkButton>
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


                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content" style="height: auto; width: 800px;">
                             <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                        <ContentTemplate>
                            <div class="modal-header d-flex justify-content-between align-items-start w-100">

                                <h4 class="modal-title" id="gridSystemModalLabel">
                                    <strong>House Tax Receipt</strong>
                                </h4>

                                <div class="text-end">
                                    <asp:Label ID="receipt_no" runat="server" Font-Bold="True" Font-Size="Medium"></asp:Label><br />
                                    <asp:Label ID="txt_date" runat="server" Font-Bold="True" Font-Size="Medium"></asp:Label>
                                </div>
                            </div>



                            <div class="modal-body" id="invoice_data">
                                <form id="owner-socity-add" action="" method="post">

                                    <div class="form-group">
                                        <div class="alert alert-danger danger" style="display: none;"></div>
                                    </div>
                                   

                                            <div class="form-group">
                                                <div class="row ">
                                                   
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label11" runat="server" Text="Type"></asp:Label>
                                                        <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label21" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_type" Height="32px" Width="150px" runat="server"  parsely-trigger="change" AutoPostBack="true">
                                                             <asp:ListItem  value="0">select</asp:ListItem>   
                                                           <asp:ListItem  value="1">House Tax</asp:ListItem>   
                                                                     <asp:ListItem  value="2">Water Tax</asp:ListItem>  
                                                        </asp:DropDownList>
                                                        <br />
                                                        <asp:CompareValidator ControlToValidate="ddl_type" ID="CompareValidator3" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please select type" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label13" runat="server" Text="House No"></asp:Label>
                                                        <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_house_no" Height="32px" Width="150px" runat="server" required OnSelectedIndexChanged="ddl_house_no_SelectedIndexChanged" parsely-trigger="change" AutoPostBack="true"></asp:DropDownList>
                                                        <br />
                                                        <asp:CompareValidator ControlToValidate="ddl_house_no" ID="CompareValidator2" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please select House No" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                     <div class="col-sm-3">
                                                        <asp:Label ID="lbl_cust_name" runat="server" Text="House Tax"></asp:Label>
                                                        <asp:Label ID="lbl_cust_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_house_tax" runat="server" Height="32px" Width="150px" Enabled="false"></asp:TextBox>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label6" runat="server" Text="Paid Amount"></asp:Label>
                                                        <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_paid_amt" runat="server" Height="32px" Width="150px" OnTextChanged="txt_paid_amt_TextChanged" AutoPostBack="true" placeholder="Enter Paid Amount"></asp:TextBox>
                                                    </div>
                                                    
                                                    
                                                </div>
                                            </div>

                                            <%-- <asp:Panel ID="panel3" runat="server" Visible="false">
                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-2">
                                                            <asp:Label ID="Label21" runat="server" Text="Enter UPI:"></asp:Label>
                                                            <asp:Label ID="Label22" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-4">
                                                            <asp:TextBox ID="txt_upi" required Width="200px" Height="32px" runat="server"></asp:TextBox>
                                                        </div>

                                                        <asp:Button ID="Button2" runat="server" Height="30px" CssClass="btn btn-primary" Text="Verify & Proceed" />
                                                    </div>
                                                </div>

                                            </asp:Panel>--%>
                                            <%--       <asp:Panel ID="panel2" runat="server">
                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="lbl_chqno" runat="server" Text="Cheque/Draft No"></asp:Label>
                                                            <asp:Label ID="lbl_chqno_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:DropDownList ID="ddl_chq" runat="server" Height="32px" Width="150px" AutoPostBack="true" OnSelectedIndexChanged="ddl_chq_SelectedIndexChanged" />
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
                                            </asp:Panel>--%>
                                            

                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label1" runat="server" Text="Pay Mode"></asp:Label>
                                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="drp_pay_status" runat="server" Height="32px" Width="150px" AutoPostBack="true" parsely-trigger="change" OnSelectedIndexChanged="drp_pay_status_SelectedIndexChanged"></asp:DropDownList>
                                                        <br />
                                                        <asp:CompareValidator ControlToValidate="drp_pay_status" ID="CompareValidator1" ValidationGroup="g1" CssClass="errormesg" ErrorMessage="Please Select Pay Status" Font-Bold="true" ForeColor="Red" runat="server" Display="Dynamic" Operator="NotEqual" ValueToCompare="select" Type="String" />
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label9" runat="server" Text="Balance"></asp:Label>
                                                        <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_balance" Height="32px" Width="150px" runat="server" Enabled="false"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>

                                            <asp:Panel ID="panel3" runat="server" Visible="false">
                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label4" runat="server" Text="Enter UPI:"></asp:Label>
                                                            <asp:Label ID="Label5" runat="server" Text="*" ForeColor="Red"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_upi" required Width="150px" Height="32px" runat="server"></asp:TextBox>
                                                        </div>
                                                        <asp:Button ID="btn_verify" runat="server" Width="150px" Height="34px" CssClass="btn btn-primary" Text="Verify & Proceed" />
                                                    </div>
                                                </div>
                                            </asp:Panel>

                                            <asp:Panel ID="panel2" runat="server" Visible="false">
                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label8" runat="server" Text="Cheque/Draft No"></asp:Label>
                                                            <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:DropDownList ID="ddl_chq" runat="server" Height="32px" Width="150px" AutoPostBack="true" OnSelectedIndexChanged="ddl_chq_SelectedIndexChanged" />
                                                            <asp:TextBox ID="txt_chqno" runat="server" Height="32px" Width="150px" placeholder="Cheque No"></asp:TextBox>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label18" runat="server" Text="Cheque Date"></asp:Label>
                                                            <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
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
                                                            <asp:Label ID="Label24" runat="server" Text="Cheque Amount"></asp:Label>
                                                            <asp:Label ID="Label25" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="che_amount" runat="server" Enabled="false" Height="32px" Width="150px" placeholder="Cheque Amount"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>
                                            </asp:Panel>
                                        </ContentTemplate>
                                        <Triggers>
                                            <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                        </Triggers>
                                    </asp:UpdatePanel>

                                </form>
                            </div>

                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row ">
                                        <center>
                                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" OnClick="btn_close_Click" CausesValidation="false" UseSubmitBehavior="False" />
                                            <asp:Button ID="btn_print" runat="server" Text="Print" class="btn btn-primary" OnClick="btn_print_Click" CausesValidation="false" />
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

</asp:Content>

