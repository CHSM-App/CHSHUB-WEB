<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="society_member_search.aspx.cs" Inherits="Society.society_member_search" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 400px;
            height: auto;
            right: 0px;
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
        <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>
    <!-- Bootstrap core JavaScript-->
    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Core plugin JavaScript-->
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>

    <!-- Custom scripts for all pages-->
    <script src="js/sb-admin-2.min.js"></script>
    <script src="js/site_master_js.js"></script> 

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script type="text/javascript">

        function openModal() {
            $('#edit_model').modal('show');
        }

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
                    window.location.href = 'society_member_search.aspx';
                }
            });
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

                return true;
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
                console.log("Hello")
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
                            <h1 class=" font-weight-bold " style="color: #012970;">Committee Member List</h1>
                        </th>
                    </tr>
                </table>
                <br />




                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                                      
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
                                                onkeyup="triggerSearch()" />

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
                                        <button id="btnAdd" type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model"  runat="server" onserverclick="showPass">Add</button>
                                    </div>
                                </div>
                            </div>
                        </div>



                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" HeaderStyle-BackColor="lightblue" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">


                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="User Id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="user_id" runat="server" Text='<%# Bind("user_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Name" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Designation" SortExpression="UserTypeName">
                                                    <ItemTemplate>
                                                        <asp:Label ID="UserTypeName" runat="server" Text='<%# Bind("UserTypeName")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("user_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Delete" Visible="false" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
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
                    <div class="modal-dialog modal-sm-6">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Member</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">


                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <asp:HiddenField ID="user_id" runat="server" />
                                        <asp:HiddenField ID="Designation_id" runat="server" />
                                        <asp:HiddenField runat="server" ID="name_id" />

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Name"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" Style="width: 200px;" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Name" autocomplete="off" required="required" />
                                                        <div id="categoryRepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="categoryRepeater1" runat="server" OnItemDataBound="categoryRepeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("owner_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setCategoryBox1(this.innerText);" />
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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label4" runat="server" Text="Designation"></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="Textbox2" Style="width: 200px;" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select Designation" autocomplete="off" required="required" />
                                                        <div id="categoryRepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="categoryRepeater2" runat="server" OnItemDataBound="categoryRepeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("UserTypeName") %>'
                                                                        CommandArgument='<%# Eval("UserTypeId") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setCategoryBox2(this.innerText);" />
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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_pre_mob" runat="server" Text="Contact No."></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_pre_mob_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_contact_no" CssClass="form-control" runat="server" MaxLength="10" onkeypress="return event.charCode >= 48 && event.charCode <= 57" Width="200px" placeholder="Enter contact No." OnTextChanged="txt_contact_no_TextChanged" AutoPostBack="true" required TextMode="Phone"></asp:TextBox>
                                                    <asp:Label ID="Label25" runat="server" Font-Bold="true" ForeColor="Red"></asp:Label>
                                                    <div class="invalid-feedback">
                                                        Please Enter Contact No
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_mob" runat="server" Text="E-mail ID"></asp:Label>
                                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_email" CssClass="form-control" Width="200px" Style="text-transform: lowercase;" placeholder="Enter Email" AutoPostBack="true" OnTextChanged="txt_email_TextChanged" runat="server" required TextMode="Email"></asp:TextBox>
                                                    <asp:RegularExpressionValidator ID="regexEmailValid" Height="32px" Width="200px" runat="server" ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*" ControlToValidate="txt_email" Font-Bold="true" ForeColor="red" ErrorMessage="Invalid Email Format" Display="Dynamic" ValidationGroup="g1"></asp:RegularExpressionValidator>
                                                    <div class="invalid-feedback">
                                                        Please Enter Email
                                                    </div>
                                                     <asp:Label ID="Label7" ForeColor="Red" runat="server"></asp:Label>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label1" runat="server" Text="Username"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_username" CssClass="form-control" Width="200px" placeholder="Enter Username" Enabled="false" runat="server" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Username
                                                    </div>
                                                       <asp:Label ID="Label8" ForeColor="Red" runat="server" ></asp:Label>  
                                                      
                                                </div>
                                            </div>
                                        </div>
                                        <asp:Panel ID="passPanel" runat="server">
                                        <div class="form-group">
                                            <div class="row ">

                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label10" runat="server" Text="Password"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Medium" ForeColor="Black" Text=":"></asp:Label>
                                                    <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_password" CssClass="form-control" Width="200px" placeholder="Enter Password" runat="server" required TextMode="Password"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Password 
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                            </asp:Panel>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                        <asp:AsyncPostBackTrigger ControlID="btnAdd" EventName="ServerClick" />
                                    </Triggers>
                                </asp:UpdatePanel>



                            </div>


                            <div class="modal-footer">

                                <div class="form-group">
                                    <div class="row ">
                                        <center>
                                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" ValidationGroup="g1" OnClientClick="disableSaveButtonIfValid();" OnClick="btn_save_Click" />
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

    <br />
    <br />

       <script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>
    <!-- Bootstrap core JavaScript-->
    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Core plugin JavaScript-->
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>

    <!-- Custom scripts for all pages-->
    <script src="js/sb-admin-2.min.js"></script>
    <script src="js/site_master_js.js"></script> 


    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <script>

        <%--function initDropdownEvents() {

            const categoryBox = document.getElementById("<%= TextBox1.ClientID %>");

            const categorySuggestions = document.getElementById("categoryRepeaterContainer1");

            categoryBox.addEventListener("focus", function () {

                categorySuggestions.style.display = "block";

                itemSuggestions.style.display = "none";

            });

            categoryBox.addEventListener("input", function () {

                const input = categoryBox.value.toLowerCase();

                filterSuggestions("category-link", input);

            });

            const categoryBox2 = document.getElementById("<%= Textbox2.ClientID %>");

            const categorySuggestions2 = document.getElementById("categoryRepeaterContainer2");

            categoryBox2.addEventListener("focus", function () {

                categorySuggestions2.style.display = "block";

                itemSuggestions.style.display = "none";

            });

            categoryBox2.addEventListener("input", function () {

                const input = categoryBox2.value.toLowerCase();

                filterSuggestions("category-link", input);

            });
        }--%>

        function closeAllDropdowns() {
            document.querySelectorAll(".suggestion-list").forEach(function (el) {
                el.style.display = "none";
            });
        }

        function initDropdownEvents() {

        const nameBox = document.getElementById("<%= TextBox1.ClientID %>");
        const nameDropdown = document.getElementById("categoryRepeaterContainer1");

            const designationBox = document.getElementById("<%= Textbox2.ClientID %>");
            const designationDropdown = document.getElementById("categoryRepeaterContainer2");

            if (nameBox) {
                nameBox.addEventListener("focus", function () {
                    closeAllDropdowns();
                    nameDropdown.style.display = "block";
                });

                nameBox.addEventListener("input", function () {
                    filterSuggestions("category-link", nameBox.value.toLowerCase());
                });
            }

            if (designationBox) {
                designationBox.addEventListener("focus", function () {
                    closeAllDropdowns();
                    designationDropdown.style.display = "block";
                });

                designationBox.addEventListener("input", function () {
                    filterSuggestions("category-link", designationBox.value.toLowerCase());
                });
            }
        }

        // Close dropdown when clicking anywhere else (non-dropdown fields)
        document.addEventListener("click", function (e) {
            if (!e.target.closest(".dropdown-container")) {
                closeAllDropdowns();
            }
        });

        // Prevent immediate close when clicking inside dropdown
        document.addEventListener("DOMContentLoaded", function () {
            document.querySelectorAll(".dropdown-container").forEach(function (container) {
                container.addEventListener("click", function (e) {
                    e.stopPropagation();
                });
            });
        });

        // Required for ASP.NET UpdatePanel
        Sys.Application.add_load(function () {
            initDropdownEvents();
        });


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


        function setCategoryBox1(value) {

            document.getElementById("<%= TextBox1.ClientID %>").value = value;

            document.getElementById("categoryRepeaterContainer1").style.display = "none";

        }
        function setCategoryBox2(value) {

            document.getElementById("<%= Textbox2.ClientID %>").value = value;

            document.getElementById("categoryRepeaterContainer2").style.display = "none";

        }

        Sys.Application.add_load(initDropdownEvents);
        

    </script>

</asp:Content>