<%@ Page Title="" Language="C#" AutoEventWireup="true" CodeBehind="village_master.aspx.cs" Inherits="Society2024.village_master" MasterPageFile="~/Site.Master" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
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



            alert("length must be exactly 10 digits")
            if (el.value.length != 10) {
                return false;
            }

        }

    </script>
    <script type='text/javascript'>
        function openModal() {
            $('#edit_model').modal('show');

        }
    </script>

    <script type="text/javascript">
        function confirmDelete() {
            return confirm("Are you sure you want to delete this record?");
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
                    window.location.href = 'village_master.aspx';
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
                          <h1 class=" font-weight-bold " style="color: #012970;">Village Master</h1>
                        </th>
                    </tr>
                </table>
                
                 <asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
                <ContentTemplate>
                <asp:HiddenField ID="user_id" runat="server" />
                <asp:HiddenField ID="village_id" runat="server" />
                
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
                                OnTextChanged="btn_search_Click"
                                onkeyup="removeFocusAfterTyping()"/>                    

                            <!-- Calendar and Search Buttons -->
                            <div class="input-buttons">
                                 <button
                                    id="btn_search"
                                    type="submit"
                                    class="search-button2"
                                    runat="server"
                                    onserverclick="btn_search_Click">
                                    <span class="material-symbols-outlined">search</span>
                                </button>
                            </div>
                        </div>

                        &nbsp;&nbsp;
                            <asp:Button ID="Button1" runat="server" class="btn btn-primary" OnClick="btn_import_Click" Text="Import Data From Excel" UseSubmitBehavior="False" />

                    </div>
                </div>
            </div>
        </div>
                
  
                      
                           



                <div class="form-group">
                    <div class="row ">
                        <div class="col-sm-12">
                            <div style="width: 100%; overflow: auto;">
                                <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" HeaderStyle-BackColor="lightblue" OnSorting="GridView1_Sorting" OnRowEditing="GridView1_RowEditing" AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15">
                    
                                    <Columns>
                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                            <ItemTemplate>
                                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="v_id" Visible="false">
                                            <ItemTemplate>
                                                <asp:Label ID="id" runat="server" Text='<%# Bind("id")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                          <asp:TemplateField HeaderText="Village Name" ItemStyle-Width="150" SortExpression="name">
                                            <ItemTemplate>
                                                <asp:Label ID="village_name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Division" ItemStyle-Width="150" SortExpression="division">
                                            <ItemTemplate>
                                                <asp:Label ID="division" runat="server" Text='<%# Bind("division")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Email" ItemStyle-Width="150" SortExpression="email">
                                            <ItemTemplate>
                                                <asp:Label ID="email" runat="server" Text='<%# Bind("email")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField HeaderText="Contact No" ItemStyle-Width="150" SortExpression="contact_no">
                                            <ItemTemplate>
                                                <asp:Label ID="contact_no" runat="server" Text='<%# Bind("contact_no")%>'></asp:Label>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                       
                                        <asp:TemplateField HeaderText="Edit" ItemStyle-Width="60">
                                            <ItemTemplate>

                                                <asp:LinkButton runat="server" ID="edit" onCommand="edit_Command"  CommandArgument='<%# Bind("id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                               
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
                    <div class="modal-dialog modal-sm-1" style="right: 80px">
                        <div class="modal-content" style="height: auto; width: 900px;">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Village Details</strong></h4>
                               
                            </div>
                             
                            <div class="modal-body" id="invoice_data">
                                
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="form-group">
                                        <div class="alert alert-danger danger" style="display: none;"></div>
                                    </div>
                                   
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_co_name" runat="server" Text="Name"></asp:Label>
                                                        <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_name" runat="server" placeholder="Enter First Name Middle Name and Last Name" required autofocus Width="200px"></asp:TextBox>
                                                        <br />

                                                    </div>


                                                    <div class="col-sm-3">
                                                        <asp:Label ID="lbl_pre_mob" runat="server" Text="Contact No."></asp:Label>
                                                        <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_contact_no" runat="server" MaxLength="10" Width="200px" placeholder="Enter Contact No." onblur="checkLength(this)" onkeypress="return digit(event);" AutoPostBack="true" required></asp:TextBox>
                                                        <br />

                                                    </div>
                                                </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                               <div class="col-sm-3">
                                                        <asp:Label ID="Label1" runat="server" Text="E-mail ID"></asp:Label>
                                                        <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                        <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_email" Width="200px" placeholder="Enter Email Id" runat="server" required></asp:TextBox>
                                                        <br />
                                                        <asp:RegularExpressionValidator ID="RegularExpressionValidator1" Height="32px" Width="200px" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_email" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Email Format" ValidationGroup="g1" Display="Dynamic"></asp:RegularExpressionValidator>

                                                    </div>
                                               <div class="col-sm-3">
                                                        <asp:Label ID="Label17" runat="server" Text="State"></asp:Label>
                                                        <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_state" Height="32px" Width="200px" OnSelectedIndexChanged="ddl_state_SelectedIndexChanged" runat="server"></asp:DropDownList>
                                                    </div>

                                            </div>
                                         </div>
                                                                                      
                                           
                                            <div class="form-group">
                                                <div class="row ">
                                                   
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label37" runat="server" Text="District"></asp:Label>
                                                        <asp:Label ID="Label38" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label39" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_district" Height="32px" Width="200px" OnSelectedIndexChanged="ddl_district_SelectedIndexChanged" runat="server"></asp:DropDownList>
                                                    </div>
                                                     <div class="col-sm-3">
                                                        <asp:Label ID="Label40" runat="server" Text="Division"></asp:Label>
                                                        <asp:Label ID="Label41" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        <asp:Label ID="Label42" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                         </div>
                                                   <div class="col-sm-3">
                                                        <asp:DropDownList ID="ddl_division" Height="32px" Width="200px" runat="server"></asp:DropDownList>
                                                    </div>
                                                 </div>
                                            </div>

                                            <div class="form-group">
                                                <div class="row ">
                                                    
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
                                     

                                       </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                             </div>
                            <div class="modal-footer">
                                <div class="form-group">
                                    <div class="row ">
                                        <center>
                                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" ValidationGroup ="g1" />
                                           <%-- <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" OnClientClick="return confirm('Are you sure want to delete?');" Visible="false" OnClick="btn_delete_Click" />--%>
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" OnClick="btn_close_Click" UseSubmitBehavior="False" />
                                        </center>
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
        </div>
</asp:Content>

