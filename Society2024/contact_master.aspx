<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="contact_master.aspx.cs" Inherits="Society.contact_master" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">
    <style>
        /* Add this to your existing CSS - Modified styles for delete button repositioning */

        /* Override default GridView table layout to show cards horizontally */
#<%= CardGridView.ClientID %> {
    display: flex;
    flex-wrap: wrap;
    gap: 24px;
}

#<%= CardGridView.ClientID %> table,
#<%= CardGridView.ClientID %> tbody,
#<%= CardGridView.ClientID %> tr,
#<%= CardGridView.ClientID %> td {
    display: contents;
}

.contact-card {
    flex: 0 0 calc(25% - 24px); /* 4 cards per row */
    box-sizing: border-box;
}

@media (max-width: 992px) {
    .contact-card {
        flex: 0 0 calc(50% - 24px); /* 2 cards per row on tablets */
    }
}

@media (max-width: 576px) {
    .contact-card {
        flex: 0 0 100%; /* 1 card per row on mobile */
    }
}


.contact-card {
    display:flex;
    flex-direction:column;
    background: linear-gradient(145deg, #ffffff, #f8f9fa);
    border: 1px solid #e9ecef;
    border-radius: 12px;
    padding: 24px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
    width:275px;
}

/* Delete button in top right corner */
.btn-delete-corner {
    position: absolute;
    top: 12px;
    right: 12px;
    width: 36px;
    height: 36px;
    padding: 0;
    background: #ffffff;
    color: #dc3545;
    border: 2px solid #dc3545;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    z-index: 10;
}

.btn-delete-corner:hover {
    background: #dc3545;
    color: white;
    transform: scale(1.1);
}

.btn-delete-corner i {
    font-size: 16px;
}

/* Update card actions to only show View and Edit */
.card-actions {
    display: flex;
    gap: 8px;
    margin-top: auto;
    padding-top: 16px;
    border-top: 1px solid #e9ecef;
}

.card-actions .btn-action {
    flex: 1;
}
        /* === LAYOUT & CONTAINER === */
        .page-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }

        .page-header {
            margin-bottom: 30px;
        }

        .page-title {
            color: #012970;
            font-size: 2rem;
            font-weight: 700;
            margin: 0;
        }

        /* === SEARCH & ACTION BAR === */
        .action-bar {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }

        .search-wrapper {
            flex: 1;
            min-width: 280px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .search-input {
            flex: 1;
            padding: 10px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 0.95rem;
            transition: all 0.3s ease;
        }

        .search-input:focus {
            outline: none;
            border-color: #007bff;
            box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
        }

        .btn-search {
            padding: 10px 20px;
            background: #007bff;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .btn-search:hover {
            background: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 123, 255, 0.3);
        }

        .btn-add {
            padding: 10px 24px;
            /*background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);*/
            background: #007bff;
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            white-space: nowrap;
        }

        .btn-add:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }

        /* === CARD GRID === */
        .cards-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 24px;
            margin-top: 20px;
        }

/*        .contact-card {
            background: linear-gradient(145deg, #ffffff, #f8f9fa);
            border: 1px solid #e9ecef;
            border-radius: 12px;
            padding: 24px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }*/

        .contact-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 4px;
            background: linear-gradient(90deg, #667eea, #764ba2);
            transform: scaleX(0);
            transition: transform 0.3s ease;
        }

        .contact-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 12px 28px rgba(0, 0, 0, 0.12);
            border-color: #667eea;
        }

        .contact-card:hover::before {
            transform: scaleX(1);
        }

        .card-header {
            border-bottom: 2px solid #e9ecef;
            padding-bottom: 16px;
            margin-bottom: 20px;
        }

        .card-name {
            font-size: 1.25rem;
            font-weight: 700;
            color: #1a1a1a;
            margin: 0 0 4px 0;
        }

        .card-type {
            font-size: 0.9rem;
            color: #6c757d;
            font-weight: 500;
        }

        .card-details {
            display: flex;
            flex-direction: column;
            gap: 1px;
            margin-bottom: 20px;
        }

        .detail-row {
            display: flex;
            align-items: flex-start;            
            gap: 12px;
            font-size: 0.9rem;
        }

        .detail-icon {
            color: #667eea;
            width: 20px;
            flex-shrink: 0;
            margin-top: 2px;
        }

        .detail-text {
            color: #343a40;
            line-height: 1.5;
            word-break: break-word;
        }

        .card-actions {
            display: flex;
            gap: 8px;
            margin-top: auto;
            padding-top: 16px;
            border-top: 1px solid #e9ecef;
        }

        .btn-action {
            flex: 1;
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 0.875rem;
            font-weight: 500;
            border: none;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }

        .btn-view {
            background: #007bff;
            color: white;
        }

        .btn-view:hover {
            background: #0056b3;
        }

        .btn-edit {
            background: #ffffff;
            color: #007bff;
            border: 2px solid #007bff;
        }

        .btn-edit:hover {
            background: #007bff;
            color: white;
        }

        .btn-delete {
            background: #ffffff;
            color: #dc3545;
            border: 2px solid #dc3545;
        }

        .btn-delete:hover {
            background: #dc3545;
            color: white;
        }

        /* === MODAL === */
        .modal-content {
            border-radius: 12px;
            border: none;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        }

        .modal-header {
            /*background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);*/
            color: #343a40;
            border-radius: 12px 12px 0 0;
            padding: 20px 24px;
        }

        .modal-title {
            font-weight: 600;
            font-size: 1.5rem;
        }

        .modal-body {
            padding: 24px;
        }

        .form-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .form-group-custom {
            display: flex;
            flex-direction: column;
        }

        .form-label {
            font-weight: 600;
            color: #343a40;
            margin-bottom: 8px;
            font-size: 0.9rem;
        }

        .form-label .required {
            color: #dc3545;
            margin-left: 2px;
        }

        .form-control {
            padding: 10px 14px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 0.95rem;
            transition: all 0.3s ease;
        }

        .form-control:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        /* === FILE UPLOAD === */
        .file-upload-wrapper {
            position: relative;
        }

        input[type="file"] {
            padding: 12px;
            border: 2px dashed #e0e0e0;
            border-radius: 8px;
            background: #fafafa;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 0.9rem;
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
            font-size: 0.875rem;
            font-weight: 500;
            margin-right: 12px;
            transition: all 0.2s ease;
        }

        input[type="file"]::-webkit-file-upload-button:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
        }

        /* === DROPDOWN SUGGESTIONS === */
        .dropdown-container {
            position: relative;
        }

        .suggestion-list {
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
            margin-top: 4px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .suggestion-item {
            padding: 10px 14px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: block;
            color: #343a40;
            text-decoration: none;
        }

        .suggestion-item:hover {
            background: #f8f9fa;
            color: #667eea;
        }

        /* === MODAL FOOTER === */
        .modal-footer {
            padding: 20px 24px;
            border-top: 1px solid #e9ecef;
            display: flex;
            justify-content: center;
            gap: 12px;
        }

        .btn-modal {
            padding: 10px 32px;
            border-radius: 8px;
            font-weight: 500;
            border: none;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .btn-secondary:hover {
            background: #5a6268;
        }

        /* === RESPONSIVE === */
        @media (max-width: 768px) {
            .cards-container {
                grid-template-columns: 1fr;
            }

            .action-bar {
                flex-direction: column;
                align-items: stretch;
            }

            .search-wrapper {
                min-width: 100%;
            }

            .form-row {
                grid-template-columns: 1fr;
            }

            .modal-dialog {
                margin: 10px;
            }
        }

        /* === UTILITIES === */
        .text-danger {
            color: #dc3545;
        }

        .text-muted {
            color: #6c757d;
        }

        .mb-3 {
            margin-bottom: 1rem;
        }

        .mt-3 {
            margin-top: 1rem;
        }

        /* Hide default GridView styling */
        .card-grid {
            border: none !important;
        }

            .card-grid tr,
            .card-grid td {
                display: contents;
            }

        .align-cards {
            display: flex;
            flex-wrap: wrap;
            gap: 26px;
        }
    </style>



    <div class="page-container">
        <div class="page-header">
            <h1 class="page-title">Assistant Contact</h1>
        </div>

        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>

                        <div class="form-group">
            <div class="row">
                <div class="col-12">
                    <div class="d-flex align-items-center">
                        <div class="search-container">

                            <asp:TextBox
                                ID="txt_search"
                                CssClass="aspNetTextBox"
                                placeHolder="Search Assistant..."
                                runat="server"
                                TextMode="Search"
                                AutoPostBack="true"
                                autocomplete="off"
                                onkeyup="filterTable()"/>

                            <!-- Calendar and Search Buttons -->
                            <div class="input-buttons">
                                <button
                                    id="Button1"
                                    type="submit"
                                    class="search-button2"
                                    runat="server"
                                     onclick="filterTable()">
                                    <span class="material-symbols-outlined">search</span>
                                </button>
                            </div>
                        </div>

                        &nbsp;&nbsp;
                                      <button type="button" class="btn-add" data-toggle="modal" data-target="#edit_model">
                  + Add Contact
              </button>
                    </div>
                </div>
            </div>
        </div>



                <div class="gridview-container">
                        <asp:GridView ID="CardGridView" runat="server" AutoGenerateColumns="False"
                            GridLines="None" CssClass="card-grid row" ShowHeader="False">
                            <Columns>
                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <div class="contact-card align-cards">
                                            <!-- Delete button in top right corner -->
                                            <asp:LinkButton ID="lnkDelete"
                                                runat="server"
                                                CssClass="btn-delete-corner"
                                                CommandArgument='<%# Eval("usefull_contact_id") %>'
                                                OnCommand="lnkDelete_Command"
                                                OnClientClick="return confirm('Are you sure you want to delete this contact?');"
                                                ToolTip="Delete Contact">
                                                <i class="fa fa-trash"></i>
                                        </asp:LinkButton>

                                        <div class="card-header">
                                            <h3 class="card-name"><%# Eval("p_name") %></h3>
                                            <span class="card-type"><%# Eval("p_type_name") %></span>
                                        </div>

                                        <div class="card-details">
                                            <div class="detail-row">
                                                <i class="fa fa-building detail-icon"></i>
                                                <span class="detail-text"><%# Eval("org_name") %></span>
                                            </div>
                                            <div class="detail-row">
                                                <i class="fa fa-phone detail-icon"></i>
                                                <span class="detail-text"><%# Eval("contact_no") %></span>
                                            </div>
                                            <div class="detail-row">
                                                <i class="fa fa-envelope detail-icon"></i>
                                                <span class="detail-text"><%# Eval("email") %></span>
                                            </div>
                                            <div class="detail-row">
                                                <i class="fa fa-home detail-icon"></i>
                                                <span class="detail-text"><%# Eval("contact_address") %></span>
                                            </div>
                                            <div class="detail-row">
                                                <i class="fa fa-comment detail-icon"></i>
                                                <span class="detail-text"><%# Eval("remark") %></span>
                                            </div>
                                        </div>

                                        <div class="card-actions">
                                            <asp:Button ID="btnViewFile"
                                                runat="server"
                                                Text="View File"
                                                CssClass="btn-action btn-view"
                                                CommandArgument='<%# Eval("id_path") %>'
                                                OnCommand="btnViewFile_Command"
                                                UseSubmitBehavior="false" />
                                            <asp:LinkButton ID="lnkEdit"
                                                runat="server"
                                                CssClass="btn-action btn-edit"
                                                CommandArgument='<%# Eval("usefull_contact_id") %>'
                                                OnCommand="lnkEdit_Command"
                                                ToolTip="Edit Contact">
                    <i class="fa fa-edit"></i> Edit
                                            </asp:LinkButton>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>

                    </div>
                <asp:Label ID="lblMessage" runat="server" CssClass="text-danger mt-3" />
            </ContentTemplate>
        </asp:UpdatePanel>

        <!-- Add/Edit Modal -->
        <div class="modal fade" id="edit_model" tabindex="-1" role="dialog" data-backdrop="static">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">New Assistant Contact</h4>
                        <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 1;">
                            <span>&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="upModal">
                            <ContentTemplate>
                                <asp:HiddenField ID="contact_type_id" runat="Server" />
                                <asp:HiddenField ID="usefull_contact_id" runat="Server" />

                                <div class="form-row">
                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Person's Name <span class="required">*</span>
                                        </label>
                                        <asp:TextBox ID="txt_p_name"
                                            CssClass="form-control"
                                            runat="server"
                                            placeholder="Enter person's name"
                                            required></asp:TextBox>
                                    </div>

                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Person's Type <span class="required">*</span>
                                        </label>
                                        <div class="dropdown-container">
                                            <asp:TextBox ID="categoryBox"
                                                runat="server"
                                                CssClass="form-control"
                                                placeholder="Select type"
                                                autocomplete="off"
                                                required="required"
                                                oninput="clearCategoryId()" />
                                            <div id="categoryRepeaterContainer" class="suggestion-list">
                                                <asp:Repeater ID="categoryRepeater" runat="server" OnItemCommand="CategoryRepeater_ItemCommand" OnItemDataBound="CardRepeater_ItemDataBound">
                                                    <ItemTemplate>
                                                        <asp:LinkButton
                                                            ID="lnkCategory"
                                                            runat="server"
                                                            CssClass="suggestion-item category-link"
                                                            Text='<%# Eval("p_type_name") %>'
                                                            CommandArgument='<%# Eval("p_type_id") %>'
                                                            CommandName="SelectCategory"
                                                            OnClientClick="setCategoryBox(this.innerText);" />
                                                    </ItemTemplate>
                                                </asp:Repeater>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Organization Name 
                                        </label>
                                        <asp:TextBox ID="txt_org_name"
                                            CssClass="form-control"
                                            runat="server"
                                            MaxLength="50"
                                            placeholder="Enter organization name"
                                            ></asp:TextBox>
                                    </div>

                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Contact Number <span class="required">*</span>
                                        </label>
                                        <asp:TextBox ID="txt_org_tel"
                                            onkeypress="return event.charCode >= 48 && event.charCode <= 57"
                                            CssClass="form-control"
                                            runat="server"
                                            MaxLength="10"
                                            placeholder="Enter mobile number"
                                            required></asp:TextBox>
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Email Address <span class="required">*</span>
                                        </label>
                                        <asp:TextBox ID="txt_email"
                                            CssClass="form-control"
                                            runat="server"
                                            placeholder="Enter email address"
                                            required></asp:TextBox>
                                        <asp:RegularExpressionValidator
                                            ID="regexEmailValid"
                                            runat="server"
                                            ValidationExpression="\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*"
                                            ControlToValidate="txt_Email"
                                            ForeColor="Red"
                                            ErrorMessage="Invalid Email Format"
                                            ValidationGroup="g1"></asp:RegularExpressionValidator>
                                    </div>

                                    <div class="form-group-custom">
                                        <label class="form-label">Remark</label>
                                        <asp:TextBox ID="txt_remark"
                                            CssClass="form-control"
                                            runat="server"
                                            placeholder="Enter remark"></asp:TextBox>
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group-custom">
                                        <label class="form-label">
                                            Address <span class="required">*</span>
                                        </label>
                                        <asp:TextBox ID="txt_org_addr1"
                                            CssClass="form-control"
                                            runat="server"
                                            MaxLength="250"
                                            placeholder="Enter address line 1"
                                            required></asp:TextBox>
                                    </div>

                                    <div class="form-group-custom">
                                        <label class="form-label">Address Line 2</label>
                                        <asp:TextBox ID="txt_org_addr2"
                                            CssClass="form-control"
                                            runat="server"
                                            MaxLength="250"
                                            placeholder="Enter address line 2"></asp:TextBox>
                                    </div>
                                </div>

                                <div class="form-group-custom">
                                    <label class="form-label">
                                        ID Proof <span class="required">*</span>
                                    </label>
                                    <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf, .jpg, .jpeg" onchange="validateFileSize(this)" />
                                    <asp:Label ID="listofuploadedfiles" runat="server" />
                                    <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
                                </div>
                            </ContentTemplate>
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="CardGridView" EventName="RowCommand" />
                            </Triggers>
                        </asp:UpdatePanel>
                    </div>

                    <div class="modal-footer">
                        <asp:Button ID="btn_save"
                            T
                            runat="server"
                            OnClientClick="disableSaveButtonIfValid();"
                            Text="Save"
                            CssClass="btn-modal btn-primary"
                            OnClick="btn_save_Click"
                            ValidationGroup="g1" />
                        <asp:Button ID="btn_close"
                            runat="server"
                            Text="Close"
                            CssClass="btn-modal btn-secondary"
                            UseSubmitBehavior="False"
                            data-dismiss="modal" />
                    </div>
                </div>
            </div>
        </div>

        <!-- File Viewer Modal -->
        <div class="modal fade" id="fileModal" tabindex="-1" role="dialog">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>
                            <div class="modal-header">
                                <h5 class="modal-title">File Viewer</h5>
                                <button type="button" class="close" data-dismiss="modal" style="color: white; opacity: 1;">
                                    <span>&times;</span>
                                </button>
                            </div>
                            <div class="modal-body">
                                <asp:Label ID="lblFileMessage" runat="server" CssClass="text-danger"></asp:Label>
                                <iframe id="iframeFile" runat="server" width="100%" height="500px" style="border: none;"></iframe>
                            </div>
                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="CardGridView" EventName="RowCommand" />
                        </Triggers>
                    </asp:UpdatePanel>
                </div>
            </div>
        </div>
    </div>

        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
        <script type="text/javascript">
            function FailedEntry() {
                Swal.fire({

                    title: '❌ Failed!',
                    text: 'Something went wrong. Please try again.',
                    icon: 'error',
                    confirmButtonColor: '#d33',
                    confirmButtonText: 'Retry',
                    timer: 3000,
                    timerProgressBar: true
                });
            }

            function SuccessEntry() {
                Swal.fire({
                    title: '✅ Success!',
                    text: 'Saved Successfully',
                    icon: 'success',
                    confirmButtonColor: '#667eea',
                    confirmButtonText: 'OK',
                    timer: 1400,
                    timerProgressBar: true,
                    willClose: () => {
                        window.location.href = 'contact_master.aspx';
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
                    return false;
                }
                return false;
            }

            function initDropdownEvents() {
                const categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
                const categorySuggestions = document.getElementById("categoryRepeaterContainer");

                if (categoryBox && categorySuggestions) {
                    categoryBox.addEventListener("focus", function () {
                        categorySuggestions.style.display = "block";
                    });

                    categoryBox.addEventListener("input", function () {
                        const input = categoryBox.value.toLowerCase();
                        filterSuggestions("category-link", input);
                    });

                    // Close dropdown when clicking outside
                    document.addEventListener("click", function (e) {
                        if (!categoryBox.contains(e.target) && !categorySuggestions.contains(e.target)) {
                            categorySuggestions.style.display = "none";
                        }
                    });
                }
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
                        noMatchMessage.className = "suggestion-item";
                        noMatchMessage.style.color = "#9ca3af";
                        noMatchMessage.innerHTML = "No matching vendors found.";
                        items[0]?.parentNode?.appendChild(noMatchMessage);
                    }
                    noMatchMessage.style.display = "block";
                } else {
                    if (noMatchMessage) {
                        noMatchMessage.style.display = "none";
                    }
                }
            }

            function setCategoryBox(value) {
                document.getElementById("<%= categoryBox.ClientID %>").value = value;
                document.getElementById("categoryRepeaterContainer").style.display = "none";

            }

            // Initialize on Sys.Application load
            Sys.Application.add_load(function () {
                initDropdownEvents();
            });

        </script>


    <%--    whole script for searching in grid--%>
    <script type="text/javascript">
        (function () {
            // get references (use server ClientID)
            var input = document.getElementById('<%= txt_search.ClientID %>');
            var grid = document.getElementById('<%= CardGridView.ClientID %>');

            // fallback if grid id not found or GridView output changed
            function getAllCards() {
                // prefer cards inside grid if grid exists
                if (grid) {
                    var inside = grid.querySelectorAll('.contact-card');
                    if (inside && inside.length) return Array.from(inside);
                }
                // otherwise find all .contact-card on page
                return Array.from(document.querySelectorAll('.contact-card'));
            }

            // the filter function
            function filterCards() {
                var q = '';
                if (!input) {
                    // fallback: search an element with id 'txt_search' if client id differs
                    input = document.querySelector('input[placeholder="Search bills..."]') || document.getElementById('<%= txt_search.ClientID %>');
                }
                if (!input) return;
                q = (input.value || '').trim().toLowerCase();

                var cards = getAllCards();
                if (!cards || cards.length === 0) return;

                cards.forEach(function (card) {
                    // text to search — you can narrow this to specific selectors inside card if needed
                    var text = (card.textContent || card.innerText || '').toLowerCase();
                    if (q === '' || text.indexOf(q) !== -1) {
                        card.style.display = ''; // show
                    } else {
                        card.style.display = 'none'; // hide
                    }
                });
            }

            // prevent the form from posting back when user presses Enter inside search box
            function preventSubmitOnEnter(e) {
                if (!e) e = window.event;
                var key = e.key || e.keyCode;
                if (key === 'Enter' || key === 13) {
                    e.preventDefault ? e.preventDefault() : (e.returnValue = false);
                    // optionally run filter immediately
                    filterCards();
                    return false;
                }
            }

            // attach events once DOM is ready
            function init() {
                if (!input) input = document.getElementById('<%= txt_search.ClientID %>');
                if (!input) {
                    // give friendly console hint for debugging
                    console.warn('Search input not found. Make sure txt_search.ClientID is correct.');
                    return;
                }

                // bind key events
                input.removeEventListener('input', filterCards);
                input.removeEventListener('keyup', filterCards);
                input.addEventListener('input', filterCards); // best for real-time typing
                input.addEventListener('keyup', filterCards); // extra safety
                input.addEventListener('keypress', preventSubmitOnEnter);
                input.addEventListener('keydown', function (e) {
                    // block Enter causing a submit for older browsers/forms
                    if ((e.key && e.key === 'Enter') || e.keyCode === 13) {
                        e.preventDefault();
                        filterCards();
                        return false;
                    }
                });

                // If your search button is a server button that submits the form,
                // it's better to make it client-only. If you can't change it to type="button",
                // intercept the form submit and run filter instead of posting back.
                var searchBtn = document.getElementById('Button1') || document.querySelector('.search-button2');
                if (searchBtn) {
                    // ensure clicking won't submit the whole page
                    searchBtn.addEventListener('click', function (evt) {
                        // if this is a server control it may cause postback; prevent by default
                        evt.preventDefault();
                        filterCards();
                        return false;
                    });
                }

                // initial run in case input has a value from server
                filterCards();
            }

            // Run after DOM loaded
            if (document.readyState === 'complete' || document.readyState === 'interactive') {
                setTimeout(init, 0);
            } else {
                document.addEventListener('DOMContentLoaded', init);
            }

            // Expose function so you can call it manually after an async update
            window.filterContactsGrid = filterCards;
        })();

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
