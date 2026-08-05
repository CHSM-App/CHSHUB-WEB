<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="other_credits.aspx.cs" Inherits="Society.other_credits" MasterPageFile="~/Site.Master" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .search-section {
            background-color: white;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
            align-items: center;
        }

        .search-input {
            flex: 0 0 300px;
            padding: 8px 15px;
            border: 1px solid #ccc;
            border-radius: 4px;
            font-size: 14px;
        }

        .btn-search {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }

        .btn-add {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            /*            margin-left: auto;*/
        }

        .btn-search:hover,
        .btn-add:hover {
            background-color: #0056b3;
        }

        .grid-container {
            background-color: white;
            border-radius: 5px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .credits-grid {
            width: 100%;
            border-collapse: collapse;
        }

        .credits-grid thead {
            background-color: #f8f9fa;
        }

        .credits-grid th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #003366;
            border-bottom: 2px solid #dee2e6;
            font-size: 14px;
        }

        .credits-grid td {
            padding: 15px;
            border-bottom: 1px solid #dee2e6;
            color: #333;
            font-size: 14px;
        }

        .credits-grid tbody tr:hover {
            background-color: #f8f9fa;
        }

        .edit-icon {
            color: #17a2b8;
            cursor: pointer;
            font-size: 18px;
        }

        .edit-icon:hover {
            color: #138496;
        }

        .modal-header {
            /*            background-color: #007bff;*/
            /*            color: white;*/
            border-radius: 0;
        }

        .modal-title {
            font-size: 1.5rem;
            font-weight: 600;
        }

        .modal-body {
            padding: 30px;
        }

        .form-group {
            margin-bottom: 25px;
        }

        .form-label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 500;
            font-size: 14px;
        }

        .required {
            color: red;
            margin-left: 3px;
        }

        .form-control-custom {
            width: 100%;
            padding: 10px 15px;
            border: 1px solid #ced4da;
            border-radius: 4px;
            font-size: 14px;
        }

        .form-control-custom:focus {
            outline: none;
            border-color: #80bdff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, .25);
        }

        .modal-footer {
            padding: 15px 30px;
            border-top: 1px solid #dee2e6;
        }

        .btn-save {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 25px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
        }

        .btn-close-modal {
            background-color: #6c757d;
            color: white;
            border: none;
            padding: 10px 25px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            margin-left: 10px;
        }

        .btn-save:hover {
            background-color: #0056b3;
        }

        .btn-close-modal:hover {
            background-color: #5a6268;
        }
    </style>

    <div class="credits-co">
        <table width="100%">
            <tr>
                <th width="100%">
                    <h1 class=" font-weight-bold " style="color: #012970;">Other Credits</h1>
                </th>
            </tr>
        </table>


        <div class="form-group">
            <div class="row">
                <div class="col-12">
                    <div class="d-flex align-items-center">
                        <div class="search-container">

                            <asp:TextBox ID="txt_search" CssClass="aspNetTextBox" placeHolder="Search here" runat="server" TextMode="Search" autocomplete="off" onkeyup="triggerSearch()"  />

                            <!-- Calendar and Search Buttons -->
                            <div class="input-buttons">
                                <button id="btn_search" type="button" class="search-button2" onclick="filterTable()">
                                    <span class="material-symbols-outlined">search</span>
                                </button>
                            </div>
                        </div>

                        &nbsp;&nbsp;
                        <asp:Button ID="btnAdd" runat="server" Text="Add" CssClass="btn-add" OnClientClick="showModal(); return false;" />
                    </div>
                </div>
            </div>
        </div>

        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
            <ContentTemplate>



                <div style="overflow:visible" class="grid-container">
                    <asp:GridView ID="gvOtherCredits" runat="server" CssClass="table table-bordered table-hover table-striped" AutoGenerateColumns="False" OnRowCommand="gvOtherCredits_RowCommand" DataKeyNames="Id">
                         <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                        <Columns>
                            <asp:TemplateField HeaderText="No">
                                <ItemTemplate>
                                    <%# Container.DataItemIndex + 1 %>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:BoundField DataField="Description" HeaderText="Description" />
                            <asp:BoundField DataField="Amount" HeaderText="Amount" DataFormatString="{0:N2}" />
                            <asp:BoundField DataField="PaymentDate" HeaderText="Date" DataFormatString="{0:dd-MMM-yyyy}" />

                            <asp:TemplateField HeaderText="Edit">
                                <ItemTemplate>
                                    <asp:LinkButton ID="btnEdit" runat="server" CommandName="EditRecord" CommandArgument='<%# Eval("Id") %>' CssClass="edit-icon">
                                        <i class="fas fa-edit"></i>
                                    </asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate>
                            <div style="text-align: center; padding: 30px; color: #666;">
                                No records found
                            </div>
                        </EmptyDataTemplate>
                    </asp:GridView>
                </div>
            </ContentTemplate>
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="btn_save" EventName="Click" />
            </Triggers>
        </asp:UpdatePanel>

    </div>

    <!-- Bootstrap Modal -->
    <div class="modal fade" id="creditModal" tabindex="-1" role="dialog" aria-labelledby="creditModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="creditModalLabel">New Credit</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color: white; opacity: 1;">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>


                        <div class="modal-body">
                            <asp:HiddenField ID="hdnCreditId" runat="server" Value="0" />

                            <div class="form-group">
                                <label class="form-label">Description <span class="required">*</span></label>
                                <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control-custom form-control" required placeholder="Enter Description (e.g., Hoardings, Bhangar Sell)"></asp:TextBox>
                                     </div>

                            <div class="form-group">
                                <label class="form-label">Payment <span class="required">*</span></label>
                                <asp:TextBox ID="txtPayment" runat="server" CssClass="form-control-custom form-control" required placeholder="Enter Payment Amount" TextMode="Number"></asp:TextBox>
                                   </div>

                            <div class="form-group">
                                <label class="form-label">Date <span class="required">*</span></label>
                                <asp:TextBox ID="txtDate" runat="server" CssClass="form-control-custom form-control" required placeholder="Enter Date" TextMode="Date"></asp:TextBox>
                                   </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="gvOtherCredits" EventName="RowCommand" />
                        <asp:AsyncPostBackTrigger ControlID="btn_save" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" class="btn btn-primary" OnClick="btnSave_Click" />
                    <button type="button" class="btn-close-modal" data-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>


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
                    //window.location.href = 'other_credits.aspx';
                }
            });
        }



        // Open modal for Edit
        function openEditModal() {
            $('#creditModal').modal('show');
            document.getElementById('creditModalLabel').innerText = 'Edit Credit';
        }

        // Open modal for Add
        function showModal() {
            $('#creditModal').modal('show');

            document.getElementById('<%= txtDescription.ClientID %>').value = '';
        document.getElementById('<%= txtPayment.ClientID %>').value = '';
        document.getElementById('<%= hdnCreditId.ClientID %>').value = '0';

        document.getElementById('creditModalLabel').innerText = 'New Credit';
    }

    // Close modal
    function closeModal() {
        $('#creditModal').modal('hide');
    }

    // Search filter
    function filterTable() {
        const input = document.getElementById('<%= txt_search.ClientID %>');
        if (!input) return;

        const filter = input.value.toLowerCase();
        const table = document.querySelector('.grid-container table');
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




    // Disable Save button after valid save (prevents double submissions)
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

                $('#creditModal').modal('hide');
                __doPostBack('<%= btn_save.UniqueID %>', '');

                return false; // prevent default to avoid double postback
            }

            return false; // prevent postback if not valid
        }

    </script>

</asp:Content>