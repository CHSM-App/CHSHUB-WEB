<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="new_village.aspx.cs" Inherits="Society2024.new_village" MasterPageFile="~/Site.Master" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <script type="text/javascript">
        function SuccessEntry() {
            Swal.fire(
                'SUCCESS!',
                'Quotation Entry Successfully Registered!',
                'success'
            )
        }
        function Fail() {
            Swal.fire({
                icon: 'error',
                title: 'Oops...',
                text: 'You Missed Something Empty!',
            })
        }
        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
        }


        function checkLength(el) {

            if (el.value.length != 10) {

                alert("length must be exactly 10 digits")

                return false;
            }
        }

    </script>
    <script type='text/javascript'>
        function openModal() {
            $('#edit_model').modal('show');
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
                },
                willClose: () => {
                    window.location.href = 'new_village.aspx';
                }
            });
        }
    </script>
                 <table width="100%">
                    <tr>
                        <th width="100%">
                          <h1 class=" font-weight-bold " style="color: #012970;">Village Master</h1>
                        </th>
                    </tr>
                </table>
    <hr />
    <div class="box box-primary">
        <div class="box-header with-border">
             <div class="box-body">
                <asp:HiddenField ID="id" runat="server" />
                <asp:HiddenField ID="user_id" runat="server" />
                <asp:HiddenField ID="village_id" runat="server" />

                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="form-group">
                            <div class="row ">

                                 <div class="col-sm-3">
                                    <asp:Label ID="Label5" runat="server" Text="Registration No"></asp:Label>
                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_registration" runat="server" Width="200px" AutoPostBack="true" placeholder="Enter Registration No" required Autofocus OnTextChanged="txt_registration_TextChanged"></asp:TextBox>
                                    <br />
                                    <asp:Label ID="Label22" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                </div>


                                <div class="col-sm-3">
                                    <asp:Label ID="lbl_co_name" runat="server" Text=" Village Name"></asp:Label>
                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_village" runat="server" placeholder="Enter Village Name" required autofocus Width="200px"></asp:TextBox>
                                    <br />
                                </div>
                            </div>
                        </div>

                        <hr />

                        <h4>Contact Info</h4>

                        <div class="form-group">
                            <div class="row ">
                                 <div class="col-sm-3">
                                    <asp:Label ID="Label1" runat="server" Text="Address"></asp:Label>
                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_address" runat="server" MaxLength="10" Width="200px" ValidationGroup="g1" placeholder="Enter Address." required></asp:TextBox>
                                </div>

                                <div class="col-sm-3">
                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Contact No."></asp:Label>
                                    <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_contact_no1" runat="server" MaxLength="10" Width="200px" ValidationGroup="g1" placeholder="Enter Contact No." onblur="checkLength(this)" onkeypress="return digit(event);" AutoPostBack="true" required></asp:TextBox>
                                </div>
                            </div>
                        </div>
                          <div class="form-group">
                            <div class="row ">
                                 <div class="col-sm-3">
                                    <asp:Label ID="lbl_mob" runat="server" Text="E-mail ID"></asp:Label>
                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_email" Width="200px" placeholder="Enter Email" runat="server" required></asp:TextBox>
                                    <br />
                                    <asp:RegularExpressionValidator ID="regexEmailValid" Height="32px" Width="200px" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_email" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Email Format" ValidationGroup="g1" Display="Dynamic"></asp:RegularExpressionValidator>
                               </div>

                                </div>
                              </div>


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-3">
                                    <asp:Label ID="Label17" runat="server" Text="State"></asp:Label>
                                    <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:DropDownList ID="ddl_state" Height="32px" Width="200px" OnSelectedIndexChanged="ddl_state_SelectedIndexChanged" AutoPostBack="true" runat="server"></asp:DropDownList>
                                </div>
                                 <div class="col-sm-3">
                                    <asp:Label ID="Label37" runat="server" Text="District"></asp:Label>
                                    <asp:Label ID="Label38" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label39" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                <div class="col-sm-3">
                                    <asp:DropDownList ID="ddl_district" Height="32px" OnSelectedIndexChanged="ddl_district_SelectedIndexChanged" AutoPostBack="true" Width="200px" runat="server"></asp:DropDownList>
                                </div>
                            </div>
                        </div>
                       
                        <div class="form-group">
                            <div class="row ">
                               
                                  <div class="col-sm-3">
                                    <asp:Label ID="Label40" runat="server" Text="Division"></asp:Label>
                                    <asp:Label ID="Label41" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label42" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                <div class="col-sm-3">
                                       <asp:DropDownList ID="ddl_division" Height="32px"  Width="200px" runat="server"></asp:DropDownList>
                                </div>
                                 <div class="col-sm-3">
                                    <asp:Label ID="Label28" runat="server" Text="Pincode"></asp:Label>
                                    <asp:Label ID="Label29" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    <asp:Label ID="Label30" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                </div>
                                <div class="col-sm-3">
                                    <asp:TextBox ID="txt_pincode" runat="server" Width="200px" MaxLength="6" onkeypress="return digit(event);" placeholder="Enter Pin" required autofocus></asp:TextBox>
                                    <br />

                                    <asp:RegularExpressionValidator ID="regularExp" ControlToValidate="txt_pincode" runat="server" ValidationExpression="[0-9]{6}" ErrorMessage="Invalid Pin Code." Font-Bold="True" ForeColor="red" ValidationGroup="g1"></asp:RegularExpressionValidator>
                                </div>
                            </div>
                        </div>
                   </ContentTemplate>
                </asp:UpdatePanel>
             </div>
           

            <div class="modal-footer">
                <div class="form-group">
                    <div class="row ">
                        <center>
                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" ValidationGroup="g1" />
                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" OnClick="btn_close_Click" UseSubmitBehavior="False" />
                        </center>
                    </div>
                </div>
             </div>

         
        </div>
        <!-- /.modal-body -->
    </div>
    <!-- /.modal-content -->
</asp:Content>