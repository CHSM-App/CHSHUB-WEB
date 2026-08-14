<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="servent_search.aspx.cs" Inherits="Society.servent_search" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
                .resized-model{
        width: 900px;
    height: auto;
    right: 82px;
}

@media(max-width: 431px){
   .resized-model{
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
                    window.location.href = 'servent_search.aspx';
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
    </script>




    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Servents </h1>
                        </th>
                    </tr>
                </table>
                <br />


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
<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                    </div>
                </div>
            </div>
        </div>

                <div class="form-group">
                    <div class="col-12">
                        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                                <asp:HiddenField ID="servent_id" runat="Server"></asp:HiddenField>

                                <br />



                                <div class="form-group">
                                    <div class="row ">
                                        <div class="col-sm-12">
                                            <div style="width: 100%; overflow: auto;">
                                                <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowEditing="GridView1_RowEditing" OnRowDeleting="GridView1_RowDeleting">

                                                    <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                                    <Columns>
                                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                            <ItemTemplate>
                                                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField HeaderText="society_master_id" ItemStyle-Width="200" SortExpression="society_master_id" Visible="false">
                                                            <ItemTemplate>
                                                                <asp:Label ID="servent_id" runat="server" Text='<%# Bind("servent_id")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField HeaderText="Name" SortExpression="s_name">
                                                            <ItemTemplate>
                                                                <asp:Label ID="s_name" runat="server" Text='<%# Bind("s_name")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField HeaderText="Address" SortExpression="s_address_1">
                                                            <ItemTemplate>
                                                                <asp:Label ID="s_address_1" runat="server" Text='<%# Bind("s_address_1")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField HeaderText="Mobile No" SortExpression="mobile_no1" ItemStyle-Width="200">
                                                            <ItemTemplate>
                                                                <asp:Label ID="mobile_no1" runat="server" Text='<%# Bind("mobile_no1")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField ItemStyle-Width="50" HeaderText="Edit">
                                                            <ItemTemplate>
                                                                <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Edit" CommandArgument='<%# Bind("servent_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                                <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                        <asp:TemplateField ItemStyle-Width="50" HeaderText="Delete">
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
                        <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                            <div class="modal-dialog modal-sm-4">
                                <div class="modal-content resized-model">
                                    <div class="modal-header">
                                        <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                        <h4 class="modal-title" id="gridSystemModalLabel"><strong>Servent</strong></h4>
                                    </div>
                                    <div class="modal-body" id="invoice_data">

                                        <div class="form-group">
                                            <div class="alert alert-danger danger" style="display: none;"></div>
                                        </div>
                                        <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                            <ContentTemplate>
                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="lbl_acc_no" runat="server" Text="Person's Name :"></asp:Label>

                                                            <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_p_name" CssClass="form-control" Style="text-transform: capitalize;" runat="server" placeholder="Enter Name" required></asp:TextBox>
                                                            <div class="invalid-feedback">
                                                                Please Enter Name
                                                            </div>
                                                        </div>

                                                        <div class="col-sm-3">
                                                            <asp:Label ID="lbl_pre_addr1" runat="server" Text="Address"></asp:Label>
                                                            <asp:Label ID="lbl_pre_addr1_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                            <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_org_addr1" CssClass="form-control" Style="text-transform: capitalize;" runat="server" MaxLength="250" placeholder="Enter Address" required></asp:TextBox>
                                                            <div class="invalid-feedback">
                                                                Please Enter Address
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label1" runat="server" Text="Contact No"></asp:Label>
                                                            <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                            <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_mobile_no1" CssClass="form-control" onkeypress="return event.charCode >= 48 && event.charCode <= 57" runat="server" MaxLength="10" TextMode="Phone" placeholder="Enter contact No" AutoPostBack="True" required="required"   OnTextChanged="txt_mobile_no1_TextChanged"></asp:TextBox>
                                                            <div class="invalid-feedback">
                                                                Please Enter Contact No
                                                            </div>  
                                                            <br />

                                                            <asp:Label ID="Label11" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_org_addr2" CssClass="form-control" runat="server" Style="text-transform: capitalize;" MaxLength="250" placeholder="Enter Address"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label3" runat="server" Text="Alternate Contact No"></asp:Label>
                                                            <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_mobile_no2" CssClass="form-control" runat="server" MaxLength="10" placeholder="Enter Alternate Contact No" onblur="checkLength(this)" AutoPostBack="True" onkeypress="return digit(event);"></asp:TextBox><br />

                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label4" runat="server" Text="Remark"></asp:Label>
                                                            <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                        </div>
                                                        <div class="col-sm-3">
                                                            <asp:TextBox ID="txt_remark" CssClass="form-control" runat="server" Style="text-transform: capitalize;" placeholder="Enter Remark"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                    </div>
                                                </div>


                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4" style="left: 0px; top: 1px"></div>
                                                        <div class="col-sm-3">
                                                            <asp:Label ID="Label7" runat="server" Text="Nature of Service" Font-Bold="True" Width="184px" BorderColor="Black" BorderWidth="2px"></asp:Label>

                                                            <%--<asp:TextBox ID="txt_col8_name" runat="server" Font-Bold="true"  placeholder="Nature of Service" enabled="false"   ></asp:TextBox>--%>
                                                            <hr style="display: block; margin-top: 0.5em; margin-bottom: 0.5em; border-width: 1px;" font-bold="true" />
                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:Label ID="Label8" runat="server" Text="Amount Per Month" Font-Bold="True" Width="184px" BorderColor="Black" BorderWidth="2px"></asp:Label>
                                                            <%--  <asp:TextBox ID="txt_col8_value" runat="server" Font-Bold="true"  placeholder="Amount" enabled="false"></asp:TextBox>--%>
                                                            <hr style="display: block; margin-top: 0.5em; margin-bottom: 0.5em; border-width: 1px;" />
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4"></div>
                                                        <div class="col-sm-3">
                                                            <%--<asp:CheckBox ID="chk_meal" runat="server" Text="Preparing Meal" OnCheckedChanged="chk_meal_CheckedChanged" AutoPostBack="true" />--%>
                                                            <asp:CheckBox ID="chk_meal" runat="server" OnCheckedChanged="chk_meal_CheckedChanged" AutoPostBack="true" /><span class="ml-2">Preparing Meal</span>

                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:TextBox ID="txt_meal" required CssClass="form-control" runat="server" Width="184px" placeholder="Enter Amount" autofocus></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4"></div>
                                                        <div class="col-sm-3">
                                                            <asp:CheckBox ID="chk_c_wash" runat="server" OnCheckedChanged="chk_c_wash_CheckedChanged" AutoPostBack="true" /><span class="ml-2">Cloth Washing</span>
                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:TextBox ID="txt_c_wash" required CssClass="form-control" runat="server" Width="184px" placeholder="Enter Amount" autofocus="autofocus"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4"></div>
                                                        <div class="col-sm-3">
                                                            <asp:CheckBox ID="chk_p_wash" runat="server" OnCheckedChanged="chk_p_wash_CheckedChanged" AutoPostBack="true" /><span class="ml-2">Pot Washing</span>
                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:TextBox ID="txt_p_wash" required CssClass="form-control" runat="server" Width="184px" placeholder="Enter Amount" autofocus></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4"></div>
                                                        <div class="col-sm-3">
                                                            <asp:CheckBox ID="chk_f_wash" runat="server" OnCheckedChanged="chk_f_wash_CheckedChanged" AutoPostBack="true" /><span class="ml-2">Floor Washing</span>
                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:TextBox ID="txt_f_wash" required CssClass="form-control" runat="server" Width="184px" placeholder="Enter Amount" autofocus></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="form-group">
                                                    <div class="row ">
                                                        <div class="col-sm-4"></div>
                                                        <div class="col-sm-3">
                                                            <asp:CheckBox ID="chk_b_set" runat="server" OnCheckedChanged="chk_b_set_CheckedChanged" AutoPostBack="true" /><span class="ml-2">Baby Sitting</span>
                                                        </div>
                                                        <div class="col-sm-2">
                                                            <asp:TextBox ID="txt_b_set" required CssClass="form-control" runat="server" Width="184px" placeholder="Enter Amount" autofocus></asp:TextBox>
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
                                            <div class="row ">
                                                <center>
                                                    <asp:Button ID="btn_save" runat="server" OnClientClick="disableSaveButtonIfValid();" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClick="btn_save_Click" />
                                                    <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                                    <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss ="modal" />
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
        </div>
    </div>
    <br />




    <br />


</asp:Content>
