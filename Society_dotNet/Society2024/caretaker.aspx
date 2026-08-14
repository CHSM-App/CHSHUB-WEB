<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="caretaker.aspx.cs" Inherits="Society.caretaker" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">
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
                    window.location.href = 'caretaker.aspx';
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
      //      var btn = document.getElementById('<%= btn_save.ClientID %>');
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


        //        __doPostBack('<%= btn_save.UniqueID %>', '');

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
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">CareTakers
                            </h1>
                        </th>
                    </tr>
                </table>


                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                      



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
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">

                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="caretaker_id" ItemStyle-Width="200" SortExpression="caretaker_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="caretaker_id" runat="server" Text='<%# Bind("caretaker_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Caretaker Name" SortExpression="c_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="c_name" runat="server" Text='<%# Bind("c_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Flat No" ItemStyle-Width="100" SortExpression="flat_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="flat_no" runat="server" Text='<%# Bind("flat_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Address" SortExpression="c_address">
                                                    <ItemTemplate>
                                                        <asp:Label ID="c_address" runat="server" Text='<%# Bind("c_address")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Contact No" SortExpression="mobile_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="mobile_no" runat="server" Text='<%# Bind("mobile_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="50" HeaderText="Edit">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("caretaker_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
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

                <div class="modal fade bs-example-modal-sm" tabindex="-1" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%--  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Caretaker</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">


                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        
                        <asp:HiddenField ID="building_wing_id" runat="server" />
                        <asp:HiddenField ID="doc_id" runat="server" />
                        <asp:HiddenField ID="state_id" runat="server" />
                                          <asp:HiddenField ID="HiddenField4" runat="server" />
                        <asp:HiddenField ID="HiddenField1" runat="server" />
                        <asp:HiddenField ID="caretaker_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="wing_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="txt_flat_id" runat="server" />
                        <asp:HiddenField ID="txt_flat_no" runat="server" />


                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_acc_no" runat="server" Text="Build & Wing"></asp:Label>
                                                    <asp:Label ID="lbl_acc_no_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required"/>
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("wing_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox1(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label6" runat="server" Text="Flat No"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="txtflat" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required"/>
                                                        <div id="RepeaterContainer" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater4" runat="server" OnItemDataBound="Repeater4_ItemDataBound" OnItemCommand="Repeater4_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("flat_no") %>'
                                                                        CommandArgument='<%# Eval("flat_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox4(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                    <%--    <asp:Label ID="Label10" runat="server" forecolor="Red"></asp:Label>--%>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_name" runat="server" Text="Caretaker Name"></asp:Label>
                                                    <asp:Label ID="lbl_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_c_name" CssClass="form-control" runat="server" Height="32px" Width="200px" MaxLength="50" placeholder="Enter Name" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Name
                                                    </div>
                                                    <%--    <asp:Label ID="Label10" runat="server" forecolor="Red"></asp:Label>--%>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label1" runat="server" Text="Document Type"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required"/>
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link link2"
                                                                        Text='<%# Eval("doc_name") %>'
                                                                        CommandArgument='<%# Eval("doc_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox2(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_pre_addr1" runat="server" Text="Address"></asp:Label>
                                                    <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    <asp:Label ID="lbl_pre_addr1_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_c_address" CssClass="form-control" runat="server" Height="32px" Style="text-transform: capitalize;" Width="200px" MaxLength="250" required placeholder="Enter Address"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Address
                                                    </div>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label7" runat="server" Text="Area"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_area" CssClass="form-control" runat="server" MaxLength="50" Height="32px" Width="200px" placeholder="Enter Area" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Area
                                                    </div>

                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Contact No."></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_mobile_no" CssClass="form-control" runat="server" MaxLength="10" Height="32px" Width="200px" onblur="checkLength(this)" onkeypress="return digit(event);" placeholder="Enter contact No." AutoPostBack="true" required></asp:TextBox><br />
                                                    <div class="invalid-feedback">
                                                        Please Enter Contact No
                                                    </div>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_mob" runat="server" Text="E-mail ID"></asp:Label>
                                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_email" CssClass="form-control" Height="32px" Width="200px" placeholder="Enter Email" runat="server" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Email
                                                    </div>
                                                    <br />
                                                    <asp:RegularExpressionValidator ID="regexEmailValid" Height="32px" Width="200px" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_email" Font-Bold="True" ForeColor="red" ErrorMessage="Invalid Email Format" Display="Dynamic" ValidationGroup="g1"></asp:RegularExpressionValidator>

                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label14" runat="server" Text="City"></asp:Label>
                                                    <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_city" CssClass="form-control" runat="server" Height="32px" Width="200px" Style="text-transform: capitalize;" placeholder="Enter City" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter City 
                                                    </div>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label17" runat="server" Text="State"></asp:Label>
                                                    <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-3">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required"/>
                                                        <div id="RepeaterContainer3" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand3">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link link3"
                                                                        Text='<%# Eval("state") %>'
                                                                        CommandArgument='<%# Eval("state_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setTextBox3(this.innerText);" />
                                                                </ItemTemplate>
                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
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
                                                    <asp:TextBox ID="txt_pincode" CssClass="form-control" runat="server" MaxLength="6" Height="32px" Width="200px" placeholder="Enter Pincode" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Pincode
                                                    </div>
                                                    <br />
                                                    <asp:RegularExpressionValidator ID="regularExp" ControlToValidate="txt_pincode" runat="server" ValidationExpression="[0-9]{6}" ErrorMessage="Invalid Pin Code." Font-Bold="True" ForeColor="red" ValidationGroup="g1"></asp:RegularExpressionValidator>
                                                </div>
                                                <%-- <div class="col-sm-3">
                        <asp:Label ID="Label4" runat="server" Text="Document Executed"></asp:Label>
                        <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                       <%-- <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>--%>
                                                <%-- </div>
                    <div class="col-sm-3">
                        <asp:TextBox ID="txt_doc_executed" runat="server"  Height="32px" Width="200px"  placeholder="Enter Executed" required autofocus></asp:TextBox>
                    </div>--%>
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
                                            <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" Visible="false" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
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





    <script>

        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

        const repeaterContainer1 = document.getElementById("RepeaterContainer1");

        textBox1.addEventListener("focus", function () {

            repeaterContainer1.style.display = "block";

        });



            const txt1 = document.getElementById("<%= txtflat.ClientID %>");

            const repeaterContainer = document.getElementById("RepeaterContainer");

            txt1.addEventListener("focus", function () {

                repeaterContainer.style.display = "block";

            });


        textBox1.addEventListener("input", function () {

            const input = textBox1.value.toLowerCase();

            filterSuggestions("category-link", input);

        });
        const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");

        const repeaterContainer2 = document.getElementById("RepeaterContainer2");

        textBox2.addEventListener("focus", function () {

            repeaterContainer2.style.display = "block";

        });

        textBox2.addEventListener("input", function () {

            const input = textBox2.value.toLowerCase();

            filterSuggestions("link2", input);

        });
        const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");

            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

            textBox3.addEventListener("focus", function () {

                repeaterContainer3.style.display = "block";

            });

            textBox3.addEventListener("input", function () {

                const input = textBox3.value.toLowerCase();

                filterSuggestions("link3", input);

            });

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

                    noMatchMessage.innerText = "No matching suggestions.";

                    items[0]?.parentNode?.appendChild(noMatchMessage);

                }

                noMatchMessage.style.display = "block";

            } else {

                if (noMatchMessage) {

                    noMatchMessage.style.display = "none";

                }

            }

        }

        function setTextBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            document.getElementById("RepeaterContainer1").style.display = "none";

        }
        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;

            document.getElementById("RepeaterContainer2").style.display = "none";

        }
        function setTextBox3(value) {

            document.getElementById("<%= TextBox3.ClientID %>").value = value;

            document.getElementById("RepeaterContainer3").style.display = "none";

        }

        function setTextBox4(value) {

            document.getElementById("<%= txtflat.ClientID %>").value = value;

              document.getElementById("RepeaterContainer").style.display = "none";

          }


        Sys.Application.add_load(initDropdownEvents);


    </script>

</asp:Content>
