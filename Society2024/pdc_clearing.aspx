<%@ Page Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="pdc_clearing.aspx.cs" Inherits="Society.pdc_clearing" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <asp:HiddenField ID="id" runat="Server"></asp:HiddenField>
    <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
    
    <style>
        /* Custom styles for responsiveness */
        .responsive-table {
            overflow-x: auto;
            width: 100%;
        }
        .form-group {
            margin-bottom: 1rem;
        }
        .form-control {
            width: 100%;
            max-width: 200px;
        }
        .btn-responsive {
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
        }
        .header-title {
            font-size: 2rem;
            color: #012970;
        }
        .form-row {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            align-items: center;
        }
        @media (max-width: 768px) {
            .header-title {
                font-size: 1.5rem;
            }
            .form-control {
                max-width: 100%;
            }
            .form-row {
                flex-direction: column;
                align-items: stretch;
            }
            .btn-responsive {
                width: 100%;
                margin-top: 0.5rem;
            }
            .gridview-header th {
                font-size: 0.9rem;
            }
            .gridview-row td {
                font-size: 0.85rem;
            }
        }
        @media (max-width: 576px) {
            .header-title {
                font-size: 1.2rem;
            }
            .gridview-header th, .gridview-row td {
                font-size: 0.75rem;
            }
        }
    </style>

    <script type="text/javascript">  
        // Check all checkboxes in GridView
        function CheckAll(Checkbox) {
            var GridVwHeaderCheckbox = document.getElementById("<%=GridView1.ClientID %>");
            for (var i = 1; i < GridVwHeaderCheckbox.rows.length; i++) {
                GridVwHeaderCheckbox.rows[i].cells[0].getElementsByTagName("INPUT")[0].checked = Checkbox.checked;
            }
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
                    Swal.showLoading();
                },
                willClose: () => {
                    window.location.href = 'pdc_clearing.aspx';
                }
            });
        }


    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <div class="container-fluid">
                    <div class="row">
                        <div class="col-12">
                            <h1 class="header-title font-weight-bold">PDC Clearing</h1>
                        </div>
                    </div>
                    <br />

                    <div class="form-group">
                        <div class="row">
                            <div class="col-12">
                                <asp:Panel ID="pnlSearch" runat="server" DefaultButton="search_button" CssClass="form-row">
                                    <div class="d-flex align-items-center">
                                        <asp:Label ID="lbl_form_date" runat="server" Text="From Date:" CssClass="me-2"></asp:Label>
                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*" CssClass="me-2"></asp:Label>
                                        <asp:TextBox ID="txt_form_date" runat="server" TextMode="Date" CssClass="form-control me-2" placeholder="Enter From Date" data-inputmask="'alias': 'dd/mm/yyyy'" data-mask required></asp:TextBox>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <asp:Label ID="Label1" runat="server" Text="To Date:" CssClass="me-2"></asp:Label>
                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*" CssClass="me-2"></asp:Label>
                                        <asp:TextBox ID="txt_to_date" runat="server" CssClass="form-control me-2" placeholder="Enter To Date" TextMode="Date" data-inputmask="'alias': 'dd/mm/yyyy'" data-mask required></asp:TextBox>
                                    </div>
                                    <asp:Button ID="search_button" runat="server" Text="Search" CssClass="btn btn-primary btn-responsive" OnClick="search_button_Click" />
                                    <asp:Button ID="Button1" runat="server" Text="Save" OnClick="btn_save_Click" CssClass="btn btn-primary btn-responsive" Visible="False" />
                                </asp:Panel>
                            </div>
                        </div>
                    </div>

                    <div class="responsive-table">
                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" Width="100%" runat="server" 
                            CssClass="table table-bordered table-hover" HeaderStyle-CssClass="gridview-header" RowStyle-CssClass="gridview-row"
                            HeaderStyle-BackColor="LightBlue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" 
                            OnSorting="GridView1_Sorting" AllowSorting="true" AutoGenerateColumns="False">
                            <Columns>
                                <asp:TemplateField HeaderText="No" SortExpression="no">
                                    <ItemTemplate>
                                        <asp:Label ID="account_no" runat="server" Text='<%# Container.DisplayIndex + 1 %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="pdc_rem_id" Visible="false">
                                    <ItemTemplate>
                                        <asp:Label ID="pdc_rem_id" runat="server" Text='<%# Bind("pdc_rem_id") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Owner Name" SortExpression="owner_name">
                                    <ItemTemplate>
                                        <asp:Label ID="owner_name" runat="server" Text='<%# Bind("owner_name") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Cheque Date" SortExpression="che_date">
                                    <ItemTemplate>
                                        <asp:Label ID="che_date" runat="server" Text='<%# Bind("che_date", "{0:dd/MM/yyyy}") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Cheque No" SortExpression="chqno">
                                    <ItemTemplate>
                                        <asp:Label ID="cheque_no" runat="server" Text='<%# Bind("chqno") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Amount" SortExpression="che_amount">
                                    <ItemTemplate>
                                        <asp:Label ID="che_amount" runat="server" Text='<%# Bind("che_amount") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Deposited">
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chk_depo" runat="server" AutoPostBack="true" OnCheckedChanged="chk_depo_CheckedChanged" Checked='<%# Eval("che_dep").ToString() == "1" ? true : false %>'></asp:CheckBox>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Returned">
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chk_ret" runat="server" AutoPostBack="true" OnCheckedChanged="chk_ret_CheckedChanged" Checked='<%# Eval("che_ret").ToString() == "1" ? true : false %>'></asp:CheckBox>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Bounced">
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chk_can" runat="server" AutoPostBack="true" OnCheckedChanged="chk_can_CheckedChanged" Checked='<%# Eval("che_can").ToString() == "1" ? true : false %>'></asp:CheckBox>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>