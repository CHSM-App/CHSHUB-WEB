<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="upload_doc_search.aspx.cs" Inherits="Society.upload_doc_search" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

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
                    window.location.href = 'upload_doc_search.aspx';
                }
            });
        }

        function openModal() {
            $('#edit_model').modal('show');
        }

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= upload.ClientID %>');
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


                __doPostBack('<%= upload.UniqueID %>', '');

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
                            <h1 class=" font-weight-bold " style="color: #012970;">Documents</h1>
                        </th>
                    </tr>
                </table>
                <br />
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField ID="file_id" runat="server" />
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
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" OnRowUpdating="GridView1_RowUpdating" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" AllowSorting="true" HeaderStyle-BackColor="lightblue" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting">

                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <%--<asp:CommandField ShowSelectButton="false" ControlStyle-ForeColor="blue" />--%>
                                                <%--<asp:TemplateField HeaderText="ID" Visible="true" SortExpression="facility_id">
                                                        <ItemTemplate>

                                                            <asp:HyperLink runat="server" ID="HyperLink1" NavigateUrl='<%# "flat.aspx?facility_id=" + Eval("facility_id")%>' Text='<%# Bind("facility_id")%>'></asp:HyperLink>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>--%>
                                                <asp:TemplateField HeaderText="file_id" SortExpression="file_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="file_id" runat="server" Text='<%# Bind("file_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Building Name" Visible="true" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="HyperLink1" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Unit" SortExpression="flat_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="w_name" runat="server" Text='<%# Eval("w_name")+":" +Eval("flat_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Document" SortExpression="doc_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="flat_type" runat="server" Text='<%# Bind("doc_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField>
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("file_id")%>'><img src="Images/123.png"/></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="50">
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

                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-4">
                        <div class="modal-content" style="height: auto; width: auto;">
                            <div class="modal-header">
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Documents Upload</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel ID="afdhh" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <asp:HiddenField ID="doc_id" runat="server" />
                                        <asp:HiddenField ID="building_id" runat="server" />
                                        <asp:HiddenField ID="wing_id" runat="server" />
                                        <asp:HiddenField ID="flat_no_id" runat="server" />
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Date"></asp:Label>
                                                    <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_date" CssClass="form-control" runat="server" Height="32px" Width="200px" placeholder="Enter Date" TextMode="Date" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label1" runat="server" Text="Document name"></asp:Label>
                                                    <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width:200px"/>
                                                        <div id="RepeaterContainer1" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("doc_name") %>'
                                                                        CommandArgument='<%# Eval("doc_id") %>'
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
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label4" runat="server" Text="Building Name"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width:200px"/>
                                                        <div id="RepeaterContainer2" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("name") %>'
                                                                        CommandArgument='<%# Eval("build_id") %>'
                                                                        CommandName="SelectCategory1"
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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label3" runat="server" Text="Wing Name"></asp:Label>
                                                    <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width:200px"/>
                                                        <div id="RepeaterContainer3" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater3" runat="server" OnItemDataBound="Repeater3_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand3">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("w_name") %>'
                                                                        CommandArgument='<%# Eval("wing_id") %>'
                                                                        CommandName="SelectCategory2"
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
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label6" runat="server" Text="Flat Number"></asp:Label>
                                                    <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="TextBox4" runat="server" CssClass="input-box form-control"
                                                            placeholder="Select" autocomplete="off" required="required" Style="width:200px" />
                                                        <div id="RepeaterContainer4" class="suggestion-list">
                                                            <asp:Repeater ID="Repeater4" runat="server" OnItemDataBound="Repeater4_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand4">
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

                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-sm-4">
                                            <asp:FileUpload ID="file_name" runat="server" Font-Bold="False" />
                                            <br />
                                            <asp:Label ID="listofuploadedfiless" runat="server" />
                                            <asp:Label ID="Label22" runat="server" Height="32px" Width="200px" />
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="listofuploadedfiles" runat="server" />
                                                    <asp:Label ID="Label15" runat="server" Height="32px" Width="200px" />
                                                    <asp:Label ID="Label2" runat="server" Height="32px" Width="200px"></asp:Label>
                                                </div>
                                            </div>
                                        </div>
                                        <asp:Label runat="server" ID="lbl_building" Visible="false"></asp:Label>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                                <div class="modal-footer">

                                    <div class="form-group">
                                        <div class="row ">

                                            <center>
                                                <asp:Button ID="upload" runat="server" OnClientClick="disableSaveButtonIfValid();" Text="Upload" OnClick="upload_Click" class="btn btn-primary" ValidationGroup="g1" />
                                                <%-- <asp:Button ID="btn_delete" class="btn btn-primary" runat="server" Visible="false" Text="Delete" OnClientClick="return confirm('Are you sure want to delete?');" OnClick="btn_delete_Click" />--%>
                                                <asp:Button ID="Button1" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                            </center>
                                            </>
                                        </div>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>


            </div>
        </div>
    </div>






    <script>

        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            textBox1.addEventListener("focus", function () {

                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
                repeaterContainer4.style.display = "none";

            });

            textBox1.addEventListener("input", function () {

            const input = textBox1.value.toLowerCase();

            filterSuggestions("category-link", input);

        });
        const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");

        const repeaterContainer2 = document.getElementById("RepeaterContainer2");

        textBox2.addEventListener("focus", function () {

            repeaterContainer2.style.display = "block";
            repeaterContainer3.style.display = "none";
            repeaterContainer4.style.display = "none";

        });

        textBox2.addEventListener("input", function () {

            const input = textBox2.value.toLowerCase();

            filterSuggestions("category-link", input);

        });
        const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");

            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

        textBox3.addEventListener("focus", function () {

            repeaterContainer3.style.display = "block";
            repeaterContainer4.style.display = "none";

        });

        textBox3.addEventListener("input", function () {

            const input = textBox3.value.toLowerCase();

            filterSuggestions("category-link", input);

        });
        const textBox4 = document.getElementById("<%= TextBox4.ClientID %>");

            const repeaterContainer4 = document.getElementById("RepeaterContainer4");

            textBox4.addEventListener("focus", function () {

                repeaterContainer4.style.display = "block";

            });

            textBox4.addEventListener("input", function () {

                const input = textBox4.value.toLowerCase();

                filterSuggestions("category-link", input);

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
            document.getElementById("<%= TextBox3.ClientID %>").value = ""    ;
            document.getElementById("<%= TextBox4.ClientID %>").value = "";

            document.getElementById("RepeaterContainer2").style.display = "none";

        }

        function setTextBox3(value) {

            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            document.getElementById("<%= TextBox4.ClientID %>").value = "";

            document.getElementById("RepeaterContainer3").style.display = "none";

        }

        function setTextBox4(value) {

            document.getElementById("<%= TextBox4.ClientID %>").value = value;

            document.getElementById("RepeaterContainer4").style.display = "none";

        }


        Sys.Application.add_load(initDropdownEvents);


    </script>

</asp:Content>
