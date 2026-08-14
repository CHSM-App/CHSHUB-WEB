<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="suggestion_request.aspx.cs" Inherits="Society._thought" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">
    <style>
                .resized-model {
            width: 600px;
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
                    window.location.href = 'suggestion_request.aspx';
                }
            });
        }

        function openModal() {
            $('#edit_model').modal('show');
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
                            <h1 class=" font-weight-bold " style="color: #012970;">Suggestion\Request</h1>
                        </th>
                    </tr>
                </table>
                <br />
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="th_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="sug_id" runat="Server"></asp:HiddenField>

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

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true"
                                            EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">


                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="th_id" SortExpression="th_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="sug_id" runat="server" Text='<%# Bind("sug_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Subject" SortExpression="subject">
                                                    <ItemTemplate>
                                                        <asp:Label ID="subject" runat="server" Text='<%# Bind("subject")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Details" SortExpression="details">
                                                    <ItemTemplate>
                                                        <asp:Label ID="details" runat="server" Text='<%# Bind("details")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("sug_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                        <%-- <asp:Label ID="addr" runat="server" Text='<%# Bind("w_name")%>'></asp:Label>-  NavigateUrl='<%# "wing_search.aspx?w_id=" + Eval("w_id")%>' --%>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50">
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
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>


                <div class="modal fade bs-example-modal-sm" tabindex="-1" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-1">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%--  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Suggestion/Request</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">

                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                      
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-5">
                                                    <asp:Label ID="Label1" runat="server" Text="Subject:"></asp:Label>

                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_sub" runat="server" Height="35px" CssClass="form-control" Width="250px" placeholder="Enter Subject" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Subject
                                                    </div>

                                                </div>
                                            </div>
                                            <br />
                                            <div class="row ">
                                                <div class="col-sm-5">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Suggestions/Requests:"></asp:Label>

                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_details" runat="server" Height="35px" CssClass="form-control" Width="250px" placeholder="Enter Suggestion/Request" required autofocus TextMode="MultiLine"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Suggestions/Requests
                                                    </div>

                                                </div>
                                            </div>

                                        </div>
                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>

                                <div class="modal-footer">
                                    <div class="row ">
                                        <div class="pull-right">
                                            <asp:Button ID="btn_save" runat="server" Text="Save" class="btn btn-primary" OnClick="btn_save_Click" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" class="btn btn-primary" OnClientClick="return confirm('Are you sure you want delete?');" OnClick="btn_delete_Click" Visible="false" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss ="modal" />
 
                                        </div>
                                    </div>
                                </div>


                            </div>
                            <!-- /.modal-body -->
                        </div>
                        <!-- /.modal-content -->
                    </div>

                </div>


            </div>
        </div>
    </div>

</asp:Content>
