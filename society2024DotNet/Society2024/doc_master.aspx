    <%@ Page Language="C#" AutoEventWireup="true" CodeBehind="doc_master.aspx.cs" Inherits="Society.doc_master" MasterPageFile="~/Site.Master" %>

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
                text: 'Document uploaded successfully',
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
                    window.location.href = 'doc_master.aspx';
                }
            });
        }

        function RestoreSuccess() {
            Swal.fire({
                title: '✅ Restored!',
                text: 'Document restored successfully',
                icon: 'success',
                showConfirmButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'OK',
                timer: 1400,
                timerProgressBar: true
            });
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
                            <h1 class="font-weight-bold" style="color: #012970;">Document Manager</h1>
                        </th>
                    </tr>
                </table>
                <br />

                <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="main_update_panel">
                    <ContentTemplate>

                        <asp:HiddenField ID="document_id" runat="server" />
                        <asp:HiddenField ID="society_id" runat="Server" />

                        <div class="form-group">
                            <div class="row">
                                <div class="col-12">
                                    <div class="d-flex align-items-center">
                                        <div class="search-container">
                                            <asp:TextBox
                                                ID="txt_search"
                                                CssClass="aspNetTextBox"
                                                placeHolder="Search documents..."
                                                runat="server"
                                                TextMode="Search"                                              
                                                autocomplete="off"
                                                onkeyup="triggerSearch()" />

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
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#edit_model">
                                            <i class="fas fa-plus"></i>Add Document
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="row">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible" class="g-Table">
                                        <asp:GridView
                                            AllowPaging="true"
                                            PageSize="15"
                                            ID="GridView1"
                                            runat="server"
                                            AutoGenerateColumns="false"
                                            CssClass="table table-bordered table-hover table-striped"
                                            OnRowCommand="GridView1_RowCommand"
                                            ShowHeaderWhenEmpty="true"
                                            EmptyDataText="No Documents Found"
                                            AllowSorting="true" 
                                            OnSorting="GridView1_Sorting"
                                            HeaderStyle-BackColor="lightblue"
                                            DataKeyNames="file_id">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Document Name" SortExpression="Doc_name">
                                                    <ItemTemplate>
                                                        <asp:Label runat="server" ID="doc_name" Text='<%# Bind("Doc_name")%>' Font-Weight="Bold"></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Actions" ItemStyle-Width="200">
                                                    <ItemTemplate>
                                                        <div class="btn-group" role="group">
                                                            <%--           <asp:LinkButton runat="server" OnCommand="Unnamed_Command" CommandArgument='<%# Eval("file_save_path") %>' CssClass="btn btn-sm btn-success">   <i class="fas fa-eye"></i>
                                                            </asp:LinkButton>--%>

                                                            <asp:LinkButton runat="server" ID="btnViewFile" OnCommand="btnViewFile_Command" CssClass="btn btn-sm btn-success" CommandArgument='<%# Bind("file_save_path")%>'>  <i class="fas fa-eye"></i></asp:LinkButton>

                                                            <asp:LinkButton runat="server" ID="btn_delete"
                                                                CommandName='<%# Bind("file_id")%>'
                                                                CommandArgument='<%# Bind("file_save_path")%>'

                                                                CssClass="btn btn-sm btn-danger"
                                                                title="Delete"
                                                                OnClientClick="return confirm('Are you sure you want to permenantly delete this document?');"
                                                                OnCommand="btn_delete_Command">
                                                                <i class="fas fa-trash"></i>
                                                            </asp:LinkButton>
                                                        </div>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
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

                <asp:HiddenField ID="file_Id" runat="server" />

                <!-- Upload/Edit Document Modal -->
                <div class="modal fade bs-example-modal-sm" id="docModal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-lg" role="document">
                        <div class="modal-content">

                            <!-- Header -->
                            <div class="modal-header">
                                <h5 class="modal-title" id="docModalLabel">View Document</h5>
                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>

                            <!-- Body -->
                            <div class="modal-body">
                                <iframe id="pdfView" height="800" runat="server" width="600"></iframe>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h4 class="modal-title">
                                    <strong><i class="fas fa-plus-circle"></i>Add New Document</strong>
                                </h4>
                                <button type="button" class="close" data-dismiss="modal">&times;</button>
                            </div>
                            <div class="modal-body">
                                <asp:UpdatePanel ID="add_modal_update" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <asp:Label runat="server" Text="Document Name" CssClass="form-label"></asp:Label>
                                                    <asp:Label runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    <asp:TextBox ID="txt_document_name"
                                                        CssClass="form-control"
                                                        runat="server"
                                                        placeholder="Enter document name"
                                                        required="required"
                                                        MaxLength="200"></asp:TextBox>
                                                    <div class="invalid-feedback">Please enter document name</div>
                                                </div>
                                            </div>


                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <asp:Label runat="server" Text="Tags (Optional)" CssClass="form-label"></asp:Label>
                                                    <asp:TextBox ID="txt_tags"
                                                        CssClass="form-control"
                                                        runat="server"
                                                        placeholder="Enter tags separated by commas"
                                                        MaxLength="500"></asp:TextBox>
                                                    <small class="text-muted">e.g., important, urgent, review</small>
                                                </div>

                                            </div>

                                            <div class="row">
                                                <div class="col-md-12">
                                                    <div class="form-group">
                                                        <asp:Label runat="server" Text="Description (Optional)" CssClass="form-label"></asp:Label>
                                                        <asp:TextBox ID="txt_description"
                                                            CssClass="form-control"
                                                            runat="server"
                                                            TextMode="MultiLine"
                                                            Rows="3"
                                                            placeholder="Enter document description"
                                                            MaxLength="1000"></asp:TextBox>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- File Upload -->
                                            <div class="form-group">
                                                <div class="row align-items-center mb-3">
                                                    <div class="col-12 col-sm-3">
                                                        <asp:Label ID="Label15" runat="server" Text="ID Proof"></asp:Label>
                                                        <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                    </div>
                                                    <div class="col-12 col-sm-9">
                                                        <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf, .jpg, .jpge" onchange="validateFileSize(this)"/>
                                                        <div class="overflow-div">
                                                            <asp:Label ID="listofuploadedfiles" runat="server" />
                                                        </div>
                                                        <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
                                                    </div>
                                                </div>
                                            </div>

                                            <asp:Label runat="server" ID="lbl_message" CssClass="text-danger"></asp:Label>
                                    </ContentTemplate>
                                    <Triggers>

                                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    </Triggers>
                                </asp:UpdatePanel>
                            </div>

                            <div class="modal-footer">
                                <div class="d-flex gap-2">
                                    <asp:Button ID="btn_upload"
                                        runat="server"
                                        OnClientClick="disableSaveButtonIfValid();"
                                        Text="Upload Document"
                                        OnClick="btn_upload_Click"
                                        CssClass="btn btn-primary" />

                                    <asp:Button ID="btn_close_add"
                                        runat="server"
                                        Text="Close"
                                        CssClass="btn btn-secondary"
                                        UseSubmitBehavior="False"
                                        OnClientClick="resetForm(); return false;"
                                        data-dismiss="modal" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>


                <!-- Recycle Bin Modal -->
                <div class="modal fade" id="recycle_bin_modal" role="dialog" data-backdrop="static">
                    <div class="modal-dialog modal-xl">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h4 class="modal-title">
                                    <strong><i class="fas fa-trash-restore"></i>Recycle Bin</strong>
                                    <small class="text-muted">(Documents will be permanently deleted after 30 days)</small>
                                </h4>
                                <button type="button" class="close" data-dismiss="modal">&times;</button>
                            </div>
                            <div class="modal-body">

                                <asp:UpdatePanel ID="recycle_update_panel" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>

                                        <div class="row mb-3">
                                            <div class="col-md-8">
                                                <asp:TextBox ID="txt_recycle_search"
                                                    CssClass="form-control"
                                                    runat="server"
                                                    placeholder="Search in recycle bin..."
                                                    AutoPostBack="true"
                                                    OnTextChanged="txt_recycle_search_TextChanged"></asp:TextBox>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:Button ID="btn_empty_recycle"
                                                    runat="server"
                                                    Text="Empty Recycle Bin"
                                                    CssClass="btn btn-danger"
                                                    OnClick="btn_empty_recycle_Click"
                                                    OnClientClick="return confirm('This will permanently delete all documents in recycle bin. Are you sure?');" />
                                            </div>
                                        </div>

                                        <div style="max-height: 400px; overflow-y: auto;">
                                            <asp:GridView
                                                ID="GridView_Recycle"
                                                runat="server"
                                                AutoGenerateColumns="false"
                                                CssClass="table table-bordered table-hover table-striped"
                                                OnRowCommand="GridView_Recycle_RowCommand"
                                                ShowHeaderWhenEmpty="true"
                                                EmptyDataText="Recycle bin is empty"
                                                HeaderStyle-BackColor="#dc3545"
                                                HeaderStyle-ForeColor="white"
                                                DataKeyNames="file_id">

                                                <Columns>
                                                    <asp:TemplateField HeaderText="Document Name">
                                                        <ItemTemplate>
                                                            <asp:Label ID="DN" runat="server" Text='<%# Bind("document_name")%>' Font-Weight="Bold"></asp:Label>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>

                                                    <asp:TemplateField HeaderText="Deleted Date">
                                                        <ItemTemplate>
                                                            <asp:Label ID="DD" runat="server" Text='<%# Bind("deleted_date", "{0:dd-MM-yyyy HH:mm}")%>'></asp:Label>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>

                                                    <%--  <asp:TemplateField HeaderText="Days Left">
                                                        <ItemTemplate>
                                                            <asp:Label runat="server" 
                                                                Text='<%# CalculateDaysLeft(Eval("deleted_date"))%>' 
                                                                CssClass="badge badge-warning"></asp:Label>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>--%>

                                                    <asp:TemplateField HeaderText="Actions" ItemStyle-Width="150">
                                                        <ItemTemplate>
                                                            <div class="btn-group" role="group">
                                                                <asp:LinkButton runat="server" ID="btn_restore"
                                                                    CommandName="RestoreDocument"
                                                                    CommandArgument='<%# Bind("file_id")%>'
                                                                    CssClass="btn btn-sm btn-success"
                                                                    title="Restore">
                                                                    <i class="fas fa-undo"></i> Restore
                                                                </asp:LinkButton>

                                                                <asp:LinkButton runat="server" ID="btn_permanent_delete"
                                                                    CommandName="PermanentDelete"
                                                                    CommandArgument='<%# Bind("file_id")%>'
                                                                    CssClass="btn btn-sm btn-danger"
                                                                    title="Delete Permanently"
                                                                    OnClientClick="return confirm('This will permanently delete the document. This action cannot be undone!');">
                                                                    <i class="fas fa-trash"></i> Delete
                                                                </asp:LinkButton>
                                                            </div>
                                                        </ItemTemplate>
                                                    </asp:TemplateField>
                                                </Columns>
                                            </asp:GridView>
                                        </div>

                                    </ContentTemplate>
                                </asp:UpdatePanel>
                            </div>

                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <div class="modal fade" id="fileModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <div class="modal-header">
                            <h5 class="modal-title">File Viewer</h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <!-- iframe for PDF/Image -->
                                   <asp:Label ID="lblFileMessage" runat="server" CssClass="text-danger"></asp:Label>
                            <iframe id="iframeFile" runat="server" width="100%" height="500px" style="border: none;"></iframe>
                        </div>

                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>


    <style>
        .btn-group .btn {
            margin: 0 2px;
        }

        .badge {
            font-size: 0.85em;
        }

        .search-container {
            position: relative;
            display: flex;
            align-items: center;
        }

        .file-preview {
            border: 2px dashed #007bff;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            background-color: #f8f9fa;
        }

        .modal-lg {
            max-width: 800px;
        }

        .modal-xl {
            max-width: 1200px;
        }

        .text-muted {
            color: #6c757d !important;
        }

        .gap-2 {
            gap: 0.5rem;
        }

        .d-flex {
            display: flex;
        }

        /* File Upload Styling */
        input[type="file"] {
            padding: 10px;
            border: 2px dashed #e0e0e0;
            border-radius: 8px;
            background: #fafafa;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 14px;
            width: 100%;
        }

            input[type="file"]:hover {
                border-color: #667eea;
                background: #f5f7ff;
            }

            input[type="file"]::-webkit-file-upload-button {
                padding: 8px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 13px;
                font-weight: 500;
                margin-right: 10px;
                transition: all 0.2s ease;
            }

                input[type="file"]::-webkit-file-upload-button:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
                }

            /* Firefox */
            input[type="file"]::file-selector-button {
                padding: 8px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 13px;
                font-weight: 500;
                margin-right: 10px;
                transition: all 0.2s ease;
            }

                input[type="file"]::file-selector-button:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
                }
    </style>

    <script>
        function openAddModal() {
            $('#add_document_modal').modal('show');
        }

        function openRecycleBin() {
            $('#recycle_bin_modal').modal('show');
        }

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_upload.ClientID %>');
            var modal = document.getElementById('add_document_modal');
            var inputs = modal.querySelectorAll('input[required], select[required]');
            var allValid = true;

            inputs.forEach(function (input) {
                if (!input.checkValidity()) {
                    allValid = false;
                }
            });

            if (allValid && btn) {
                btn.disabled = true;
                btn.value = "Uploading...";
                __doPostBack('<%= btn_upload.UniqueID %>', '');
                return false;
            }
            return false;
        }


        function downloadFile(fileId, fileName) {
            // Create download link
            const link = document.createElement('a');
            link.href = 'DownloadHandler.ashx?file_id=' + fileId;
            link.download = fileName;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        function viewFile(fileId, fileName) {
            // Open file in new window for viewing
            window.open('ViewFileHandler.ashx?file_id=' + fileId, '_blank');
        }

        function resetForm() {
            document.getElementById('<%= txt_document_name.ClientID %>').value = '';
            document.getElementById('<%= txt_tags.ClientID %>').value = '';
            document.getElementById('<%= txt_description.ClientID %>').value = ''; 
            document.getElementById('<%= file_Id.ClientID %>').value = '';
            document.getElementById('file_preview').style.display = 'none';
        }

        // Call this when opening Add modal
        $('#edit_model').on('show.bs.modal', function (e) {
            var trigger = $(e.relatedTarget);
            if (trigger.hasClass('btn-primary')) { // Add button
                resetForm();
            }
        });


        function validateFileSize(fileInput) {
            if (!fileInput.files || fileInput.files.length === 0) {
                return;
            }

            const file = fileInput.files[0];
            const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

            if (file.size > MAX_SIZE) {
                alert("The file is too large. Maximum allowed size is 10 MB.");
                fileInput.value = ""; // clear file selection
            }
        }

    </script>

</asp:Content>
