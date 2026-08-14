<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="vendor_search.aspx.cs" Inherits="Society.vendor_search" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 900px;
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
    </style>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">
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
                    window.location.href = 'vendor_search.aspx';
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

                return false; // prevent default to avoid double postback
            }

            return false; // prevent postback if not valid
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
                btn.click();   // ✅ correct
            }
        }

    </script>
    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">

                            <h1 class=" font-weight-bold " style="color: #012970;">Vendor</h1>

                        </th>
                    </tr>
                </table>
                <br />

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField ID="vendor_id" runat="server"></asp:HiddenField>
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
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
                                onkeyup="triggerSearch()"/>                 

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

                        &nbsp;&nbsp;
<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                    </div>
                </div>
            </div>
        </div>

                        <div style="overflow:visible" class="g-Table">
                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">
                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                            <Columns>
                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="v_id" SortExpression="vendor_id" Visible="false">
                                    <ItemTemplate>
                                        <asp:Label runat="server" ID="vendor_id" Text='<%# Bind("vendor_id")%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Vendor Name" SortExpression="vendor_name" >
                                    <ItemTemplate>
                                        <asp:Label runat="server" ID="Hyper" Text='<%# Bind("vendor_name")%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Service" SortExpression="Service_type">
                                    <ItemTemplate>
                                        <asp:Label ID="w_name" runat="server" Text='<%# Bind("Service_type")%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Contact" SortExpression="contact_no">
                                    <ItemTemplate>
                                        <asp:Label ID="no_of_cheq" runat="server" Text='<%# Bind("contact_no")%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Address" SortExpression="address">
                                    <ItemTemplate>
                                        <asp:Label ID="total_chq_amount" runat="server" Text='<%# Bind("address")%>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                    <ItemTemplate>
                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("vendor_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
                                    <ItemTemplate>
                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                            </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Vendor Details</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_name" runat="server" Text="Name"></asp:Label>
                                                    <asp:Label ID="lbl_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_name" CssClass="form-control" runat="server" Style="text-transform: capitalize;" MaxLength="50" placeholder="Enter Vendor Name" OnTextChanged="txt_name_TextChanged" AutoPostBack="true" required> </asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Vendor Name
                                                    </div>
                                                    <br />
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label1" runat="server" Text="Service Type"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_service" CssClass="form-control" runat="server" Style="text-transform: capitalize;"  placeholder="Service Type" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Service Type
                                                    </div>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                </div>

                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Contact Person"></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large"  ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_person" CssClass="form-control" runat="server"  placeholder="Enter Name"  required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Name
                                                    </div>
                                                    <br />
                                                    <asp:Label ID="Label17" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>

                                                    <%-- <asp:RegularExpressionValidator ID="RegularExpressionValidator1" runat="server" ControlToValidate="txt_mob" ErrorMessage="Enter Numbers Only" Font-Bold="True" ForeColor="Red" ValidationExpression="^\d+" Display="Dynamic"></asp:RegularExpressionValidator>--%>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label4" runat="server" Text=" Contact No."></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_contact" CssClass="form-control" runat="server" MaxLength="10" onblur="checkLength(this)" onkeypress="return digit(event);" AutoPostBack="true" placeholder="Enter Office Contact" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter  Contact No
                                                    </div>
                                                    <br />

                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_pre_addr1" runat="server" Text="Address"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    <asp:Label ID="lbl_pre_addr1_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_add" CssClass="form-control" Style="text-transform: capitalize;" runat="server" MaxLength="250" required placeholder="Enter Persent Address"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Address
                                                    </div>
                                                </div>
                                                   <div class="col-sm-3">
       <asp:Label ID="Label7" runat="server" Text=" Email"></asp:Label>
       <asp:Label ID="Label50" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
       <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
   </div>
   <div class="col-sm-3">
       <asp:TextBox ID="txt_mail" CssClass="form-control" runat="server" MaxLength="50" placeholder="Enter Email" AutoPostBack="True" required OnTextChanged="txt_mail_TextChanged"></asp:TextBox>
       <div class="invalid-feedback">
           Please Enter Email
       </div>
       <br />
       <asp:Label ID="Label13" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
       <asp:RegularExpressionValidator ID="regexEmailValid" Height="32px" Width="200px" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_mail" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Email Format" ValidationGroup="g1" Display="Dynamic"></asp:RegularExpressionValidator>

   </div>
                                              
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                               <div class="col-sm-3">
      <asp:Label ID="Label14" runat="server" Text="GSTN No"></asp:Label>
    <%--  <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>--%>
      <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
  </div>
  <div class="col-sm-3">
      <asp:TextBox ID="txt_gst" CssClass="form-control" runat="server" MaxLength="250" placeholder="Enter GSTN NO" ></asp:TextBox>
      <div class="invalid-feedback">
          Please Enter GSTN NO
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
                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row">
                                        <center>
                                            <asp:Button ID="btn_save" type="button-submit" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" OnClick="btn_save_Click" ValidationGroup="g1" class="btn btn-primary" />
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
            </div>
        </div>
    </div>

</asp:Content>




