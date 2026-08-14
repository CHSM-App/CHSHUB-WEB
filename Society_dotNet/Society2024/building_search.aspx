<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="building_search.aspx.cs" Inherits="Society.building_search" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <style>
        .valid {
            border: 2px solid green;
        }

        .invalid {
            border: 2px solid red;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='none' stroke='%23e74a3b' viewBox='0 0 12 12'%3e%3ccircle cx='6' cy='6' r='4.5'/%3e%3cpath stroke-linejoin='round' d='M5.8 3.6h.4L6 6.5z'/%3e%3ccircle cx='6' cy='8.2' r='.6' fill='%23e74a3b' stroke='none'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right calc(.375em + .1875rem) center;
            background-size: calc(.75em + .375rem) calc(.75em + .375rem)
        }

        input[type="text"] {
            padding: 10px;
            font-size: 16px;
            border-radius: 5px;
            outline: none;
        }

        .not-required.valid-field {
            border-color: #1cc88a !important;
            padding-right: calc(1.5em + .75rem);
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='8' height='8' viewBox='0 0 8 8'%3e%3cpath fill='%231cc88a' d='M2.3 6.73L.6 4.53c-.4-1.04.46-1.4 1.1-.8l1.1 1.4 3.4-3.8c.6-.63 1.6-.27 1.2.7l-4 4.6c-.43.5-.8.4-1.1.1z'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right calc(.375em + .1875rem) center;
            background-size: calc(.75em + .375rem) calc(.75em + .375rem);
        }

        .not-required.invalid-field {
            border-color: #e74a3b !important;
            padding-right: calc(1.5em + .75rem);
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='none' stroke='%23e74a3b' viewBox='0 0 12 12'%3e%3ccircle cx='6' cy='6' r='4.5'/%3e%3cpath stroke-linejoin='round' d='M5.8 3.6h.4L6 6.5z'/%3e%3ccircle cx='6' cy='8.2' r='.6' fill='%23e74a3b' stroke='none'/%3e%3c/svg%3e");
            background-repeat: no-repeat;
            background-position: right calc(.375em + .1875rem) center;
            background-size: calc(.75em + .375rem) calc(.75em + .375rem);
        }

        .resized-model {
            width: 529px;
            height: auto;
            right: 82px;
        }

        .txt_len {
            width: 200px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 90%;
                margin-top: 168px;
                right: 1px;
            }

            .txt_len {
                width: 100%;
            }
        }
    </style>


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
                },
                willClose: () => {
                    window.location.href = 'building_search.aspx';
                }
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
                btn.click();   
            }
        }


    </script>




    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" font-weight-bold " style="color: #012970;">Buildings</h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" ID="building" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="build_id" runat="server" />
                        <asp:HiddenField ID="society_id" runat="server" />

                         


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
                                                autocomplete="off"
                                                onkeyup="triggerSearch()"  />

                                            <div class="input-buttons">
                                                <button
                                                    id="btn_search"
                                                    type="button"
                                                    class="search-button2"                                                  
                                                    onclick ="filterTable()">
                                                    <span class="material-symbols-outlined">search</span>
                                                </button>
                                            </div>
                                        </div>

                                        &nbsp;&nbsp;
                                     <%-- <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model"></i> Add</button>--%>
                                        
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating" OnRowDeleting="GridView1_RowDeleting">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="build_id" ItemStyle-Width="100" SortExpression="name" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="build_id" runat="server" Text='<%# Bind("build_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Building Name" ItemStyle-Width="200" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Print Name" ItemStyle-Width="200" SortExpression="print_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="address1" runat="server" Text='<%# Bind("print_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Floor" ItemStyle-Width="100" SortExpression="no_of_floore">
                                                    <ItemTemplate>
                                                        <asp:Label ID="c_address" runat="server" Text='<%# Bind("no_of_floore")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Address" ItemStyle-Width="200" SortExpression="address1">
                                                    <ItemTemplate>
                                                        <asp:Label ID="mobile_no" runat="server" Text='<%# Eval("address1") +" " + Eval("address2") %>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>

                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("build_id")%>'><img src="Images/123.png" /></asp:LinkButton>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" Visible="false" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <%--                                    <asp:LinkButton  ButtonType="Button" data-toggle="modal" data-target=".bs-example-modal-sm" SelectText="Edit" ControlStyle-ForeColor="blue" />--%>
                                            </Columns>
                                        </asp:GridView>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>

                </asp:UpdatePanel>








                <div class="modal fade bs-example-modal-sm" tabindex="-1" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%--  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Building</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">


                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <div class="box-body">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="lbl_co_name" runat="server" Text="Building No/Name :"></asp:Label>

                                                        <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_name" CssClass="form-control txt_len" runat="server" Height="32px" placeholder="Enter Name/No" Style="text-transform: capitalize;" required> </asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please choose a Name/no .
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label1" runat="server" Text="Print Name"></asp:Label>
                                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_print_name" CssClass="form-control txt_len" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Building Name" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Building Name
                                                        </div>
                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label4" runat="server" Text="Registration No"></asp:Label>
                                                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_reg" CssClass="form-control txt_len" runat="server" Height="32px" placeholder="Enter Registration No" AutoPostBack="true" required OnTextChanged="txt_reg_TextChanged" ValidationGroup="g1"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Registration No
                                                        </div>
                                                        <asp:Label ID="Label13" runat="server" Font-Bold="true" ForeColor="Red"></asp:Label>
                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label7" runat="server" Text="Address"></asp:Label>
                                                        <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_add1" CssClass="form-control txt_len" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Address" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Adress
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_add2" CssClass="not-required txt_len" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Address" required></asp:TextBox>


                                                    </div>

                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label10" runat="server" Text="No of Floors"></asp:Label>
                                                        <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_floore" CssClass="form-control txt_len" runat="server" Height="32px" placeholder="Enter No. of Floors" onkeypress="return digit(event);" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter No Of Floors
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>
                                            <hr />
                                            <h4>Bank Details</h4>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label14" runat="server" Text="Bank Name"></asp:Label>
                                                        <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_bank" CssClass="form-control txt_len" runat="server" Height="32px" placeholder="Enter Bank name" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Bank Name
                                                        </div>


                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label25" runat="server" Text="Bank Address"></asp:Label>
                                                        <asp:Label ID="Label26" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label27" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_bank_add" CssClass="form-control txt_len" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Full Address" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Bank Adress
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label17" runat="server" Text="Branch"></asp:Label>
                                                        <asp:Label ID="Label24" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_branch" CssClass="form-control txt_len" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Branch" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Branch
                                                        </div>

                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label18" runat="server" Text="IFSC Code"></asp:Label>
                                                        <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_ifsc" CssClass="not-required txt_len" runat="server" Height="32px" MaxLength="11" placeholder="Enter IFSC Code" required="required" pattern="^[A-Z]{4}0[A-Z0-9]{6}$"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter IFSC Code
                                                        </div>

                                                        <br>
                                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator1" Height="32px" Width="200px" runat="server" ValidationExpression="^[A-Z]{4}0[A-Z0-9]{6}$"
                                                            ControlToValidate="txt_ifsc" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid IFSC Format" ValidationGroup="g1" Display="Dynamic"></asp:RegularExpressionValidator>
                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label21" runat="server" Text="Account No"></asp:Label>
                                                        <asp:Label ID="Label22" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label23" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_acc_no" CssClass="form-control txt_len" runat="server" Height="32px" placeholder="Enter Account No" required MaxLength="18"></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Account No
                                                        </div>

                                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator2" Height="32px" Width="200px" runat="server" ValidationExpression="^\d{9,18}$"
                                                            ControlToValidate="txt_acc_no" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Account No Format" ValidationGroup="g1" Display="Dynamic"></asp:RegularExpressionValidator>
                                                    </div>

                                                </div>
                                            </div>
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-4">
                                                        <asp:Label ID="Label28" runat="server" Text="Email ID"></asp:Label>
                                                        <asp:Label ID="Label29" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label30" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-6">
                                                        <asp:TextBox ID="txt_email" CssClass="form-control txt_len" runat="server" Height="32px" TextMode="Email" placeholder="Enter Email" required></asp:TextBox>
                                                        <div class="invalid-feedback">
                                                            Please Enter Email 
                                                        </div>
                                                    </div>

                                                </div>
                                            </div>


                                        </div>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>





                            <hr />

                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row ">

                                        <center>
                                            <asp:Button ID="btn_save" OnClientClick="validateIFSC();" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" OnClientClick="return confirm('Are you sure want to delete?');" Visible="false" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                        </center>

                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
                <!-- /.modal-content -->
            </div>
            <!-- /.modal-dialog -->



        </div>
    </div>

    
    <script>
       

        let formSubmitted = false;

        function validateIFSC() {
            const input = document.getElementById('<%= txt_ifsc.ClientID %>');
            const pattern = /^[A-Z]{4}0[A-Z0-9]{6}$/;
            formSubmitted = true;

            input.classList.remove('valid-field', 'invalid-field',);

            if (pattern.test(input.value)) {
                input.classList.add('valid-field');
            } else {
                input.classList.add('invalid-field');
            }
        }

        document.addEventListener("DOMContentLoaded", function () {
            const input = document.getElementById('<%= txt_ifsc.ClientID %>');
            input.addEventListener('input', function () {
                if (formSubmitted) validateIFSC();
            });
        });


        function validateEmail1(input) {
            var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (emailPattern.test(input.value)) {
                input.classList.remove("invalid");
                input.classList.add("valid");
            } else {
                input.classList.remove("valid");
                input.classList.add("invalid");
            }
        }

        var allowLiveValidation = false;

        function validateField(id, pattern) {
            var input = document.getElementById(id);
            if (input.value === "") {
                input.classList.remove("valid");
                input.classList.add("invalid");
                return false;
            }
            if (pattern.test(input.value)) {
                input.classList.remove("invalid");
                input.classList.add("valid");
                return true;
            } else {
                input.classList.remove("valid");
                input.classList.add("invalid");
                return false;
            }
        }

        function handleSubmit() {
            allowLiveValidation = true;

            var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            var ifscPattern = /^[A-Z]{4}0[A-Z0-9]{6}$/;
            var accPattern = /^\d{9,18}$/;

            var emailValid = validateField("txt_email", emailPattern);
            var ifscValid = validateField("txt_ifsc", ifscPattern);
            var accValid = validateField("txt_acc_no", accPattern);

            return emailValid && ifscValid && accValid;
        }

        function handleTyping(id, pattern) {
            if (allowLiveValidation) {
                validateField(id, pattern);
            }
        }

        

    </script>
</asp:Content>
