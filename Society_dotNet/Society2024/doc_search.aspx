<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="doc_search.aspx.cs" Inherits="Society.doc_search" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

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
                    window.location.href = 'doc_search.aspx';
                }
            });
        }

        function openModal() {
            $('#edit_model').modal('show');
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

    </script>

    <div class="box box-primary" style="min-height: 74vh;">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Documents
                            </h1>
                        </th>
                    </tr>
                </table>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField ID="flat_id" runat="server" />
                        <asp:HiddenField ID="doc_id" runat="Server"></asp:HiddenField>
                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                                                          <div class="form-group">
 <div class="form-group">
     <div class="row">
         <div class="col-12">
             <div class="top-row d-flex align-items-center">
                 <div class="search-container">

                     <asp:TextBox
                         ID="txt_search"
                         CssClass="aspNetTextBox"
                         placeHolder="Search here"
                         runat="server"
                         TextMode="Search"
                         AutoPostBack="true"
                          autocomplete="off"
 onkeyup="filterTable()"/>

                     <ajaxToolkit:CalendarExtender
                         ID="CalendarExtender1"
                         runat="server"
                         TargetControlID="txt_search"
                         PopupButtonID="btn_calendar"
                         Format="yyyy-MM-dd" />

                     <!-- Calendar and Search Buttons -->
                     <div class="input-buttons">
                         <img
                             id="btn_calendar"
                             src="img/calendar.png"
                             alt="Pick Date"
                             class="calendar-icon"
                             style="cursor: pointer;" />

                         <button
                             id="btn_search"
                             type="submit"
                             class="search-button2"
                             runat="server"
                              onclick="filterTable()">
                             <span class="material-symbols-outlined">search</span>
                         </button>
                     </div>
                 </div>

                 &nbsp;&nbsp;

                      <!-- "Print" Button -->
                 <button type="button" class="w-90 btn btn-primary">Print</button>



             </div>
         </div>
                     
     </div>
 </div>
                        &nbsp;&nbsp;


                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;" class="g-Table">
                                        <asp:GridView AllowPaging="true" ID="GridView1" runat="server" AutoGenerateColumns="false" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="10" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowUpdating="GridView1_RowUpdating">

                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="doc_id" SortExpression="doc_id" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="doc_id" runat="server" Text='<%# Bind("doc_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Document Type" SortExpression="doc_name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="doc_name" runat="server" Text='<%# Bind("doc_name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("doc_id")%>'> <img src="Images/123.png" /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Delete" ItemStyle-Width="50" Visible="false">
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
                <div class="modal fade bs-example-modal-sm" tabindex="-1" id="edit_model" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm">
                        <div class="modal-content" style="height: auto; width: 400px;">
                            <div class="modal-header">
                                <%--  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>New Document Type</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">


                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-5">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Document Type"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>

                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_doc_name" CssClass="form-control" runat="server" Style="text-transform: capitalize;" placeholder="Enter Document Type" required autofocus OnTextChanged="txt_doc_name_TextChanged" AutoPostBack="true"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Document 
                                                    </div>
                                                    <asp:Label ID="Label1" runat="server" Font-Bold="true" ForeColor="Red"></asp:Label>
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
                                            <asp:Button ID="btn_save" runat="server" Text="Save" OnClientClick="disableSaveButtonIfValid();" class="btn btn-primary" OnClick="btn_save_Click" />
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
    <br />
    <br />
</asp:Content>
