<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Staff_Master.aspx.cs" Inherits="Society.Staff_Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .resized-model {
            width: 529px;
            height: auto;
            right: 82px;
        }

        .resized-input {
            width: 200px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 292px;
                margin-top: 168px;
                right: 1px;
            }

            .resized-input {
                width: 100%;
            }
        }

        @media(max-width: 630px) {
            .top-row {
                flex-direction: column;
            }

            .w-90 {
                width: 90%;
            }
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






        /* ================= Modal ================= */
#attendanceModal .modal-dialog {
    max-width: 70%;
}

#attendanceModal .modal-content {
    border-radius: 18px;
    border: none;
    overflow: hidden;
    box-shadow: 0 12px 40px rgba(0,0,0,0.2);
}

/* ================= Header ================= */
#attendanceModal .modal-header {
    background: #0d6efd;
    padding: 1.2rem 1.5rem;
    border-bottom: none;
}

#attendanceModal .modal-title {
    font-size: 1.4rem;
    font-weight: 600;
    letter-spacing: 0.4px;
}

#attendanceModal .btn-close {
    filter: invert(1);
    opacity: 0.9;
}

/* ================= Summary Section ================= */
#attendanceSummary {
    padding: 1.2rem;
    gap: 1rem;
    
}

#attendanceSummary .col {
    padding: 0.4rem;
    
}

/* Card Base */
#attendanceSummary .p-2 {
    background: #ffffff !important;
    border-radius: 12px;
    padding: 1.1rem !important;
    box-shadow: 0 6px 18px rgba(0,0,0,0.08);
    transition: all 0.3s ease;
    border-top: 4px solid #0d6efd;
}

/* Hover */
#attendanceSummary .p-2:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 30px rgba(0,0,0,0.15);
}

/* Titles */
#attendanceSummary h6 {
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
    margin-bottom: 0.2rem;
    color: #0d6efd;
}

/* Numbers */
#attendanceSummary h4 {
    font-size: 2rem;
    font-weight: 800;
    margin: 0;
    color: #0d6efd;
}

/* Remove default bg colors */
#attendanceSummary .bg-success,
#attendanceSummary .bg-danger,
#attendanceSummary .bg-warning {
    background: #ffffff !important;
}

/* ================= Modal Body ================= */
#attendanceModal .modal-body {
    background: #f5f7fb;
    padding: 1rem 1.2rem 1.4rem;
}

/* ================= FullCalendar ================= */
#calendar {
    background: #ffffff;
    border-radius: 12px;
    padding: 0.8rem;
    box-shadow: 0 4px 14px rgba(0,0,0,0.08);
}

/* Calendar Header */
.fc-toolbar-title {
    font-size: 1.6rem !important;
    font-weight: 600;
    color: #0d6efd;
}

/* Buttons */
.fc-button {
    background: #0d6efd !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 0.45rem 0.9rem !important;
    font-size: 0.85rem !important;
    gap: 5px;
    font-weight: 500;
    box-shadow: 0 4px 12px rgba(13,110,253,0.35);
}

.fc .fc-button-group{
    gap: 5px !important;
}

.fc-button:hover {
    background: #0b5ed7 !important;
}

.fc-button-active {
    background: #0b5ed7 !important;
}

/* ================= Calendar Cells ================= */
.fc-daygrid-day-number {
    color: #0d6efd;
    font-weight: 500;
}

.fc-col-header-cell {
    background: #ffffff;
    font-weight: 600;
    font-size: 0.85rem;
}

/* ================= Attendance Labels ================= */
.fc-event {
    display:flex !important;
    justify-content:space-evenly !important;
    border: none !important;
    border-radius: 4px !important;
    padding: 2px 6px;
    font-size: 0.75rem;
    font-weight: 600;
}

/* Present */
.fc-event.bg-success {
    background: #198754 !important;
    color: white !important;
}

/* Absent */
.fc-event.bg-danger {
    background: #dc3545 !important;
    color: white !important;
}

/* Leave */
.fc-event.bg-warning {
    background: #ffc107 !important;
    color: #000 !important;
}

/* ================= Responsive ================= */
@media (max-width: 768px) {
    #attendanceSummary .col {
        flex: 0 0 100%;
        max-width: 100%;
    }

    .fc-toolbar {
        flex-direction: column;
        gap: 0.5rem;
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
                    window.location.href = 'Staff_Master.aspx';
                }
            });
        }

        function digit(evt) {
            if (evt.keyCode < 48 || evt.keyCode > 57) {

                return false;
            }
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

        function triggerSearch() {
            var btn = document.getElementById('btn_search');
            if (btn) {
                btn.click();
            }
        }



    </script>


    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">

                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Staff</h1>
                        </th>
                    </tr>
                </table>
                <br />

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>


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
                                                autocomplete="off"
                                                onkeyup="triggerSearch()" />


                                            <ajaxToolkit:CalendarExtender
                                                ID="CalendarExtender1"
                                                runat="server"
                                                TargetControlID="txt_search"
                                                PopupButtonID="btn_calendar"
                                                Format="yyyy-MM-dd" />

                                            <!-- Calendar and Search/ Buttons -->
                                            <div class="input-buttons">
                                                <img
                                                    id="btn_calendar"
                                                    src="img/calendar.png"
                                                    alt="Pick Date"
                                                    class="calendar-icon"
                                                    style="cursor: pointer;" />

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
            <button type="button" class="w-90 btn btn-primary" data-toggle="modal" data-target="#edit_model">Add</button>
                                        &nbsp; 
                                             <!-- "Print" Button -->
                                        <button type="button" class="w-90 btn btn-primary" onclick="printflatDetails()">Print</button>

                                        &nbsp; 
                                            <button type="button" class="w-90 btn btn-success" usesubmitbehavior="False" onclick="downloadReceipt()">
                                                <i class="fas fa-download me-1"></i>Download Report      
                                            </button>
                                    </div>
                                </div>
                            </div>
                        </div>



                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowDeleting="GridView1_RowDeleting" OnRowUpdating="GridView1_RowUpdating">
                                            <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="ID" Visible="false">
                                                    <ItemTemplate>
                                                        <asp:Label ID="staff_id" runat="server" Text='<%# Bind("staff_id")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Name" ItemStyle-Width="400" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Address" ItemStyle-Width="200" SortExpression="address">
                                                    <ItemTemplate>
                                                        <asp:Label ID="address" runat="server" Text='<%# Bind("address")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Contact No" ItemStyle-Width="200" SortExpression="contact_no">
                                                    <ItemTemplate>
                                                        <asp:Label ID="contact_no" runat="server" Text='<%# Bind("contact_no")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Email" ItemStyle-Width="200" SortExpression="email">
                                                    <ItemTemplate>
                                                        <asp:Label ID="email" runat="server" Text='<%# Bind("email")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Date of Join" ItemStyle-Width="400" SortExpression="date_of_join">
                                                    <ItemTemplate>
                                                        <asp:Label ID="date_of_join" runat="server" Text='<%# Bind("date_of_join","{0:dd-MM-yyyy}")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Role" ItemStyle-Width="200" SortExpression="role">
                                                    <ItemTemplate>
                                                        <asp:Label ID="role" runat="server" Text='<%# Bind("Role")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="" ItemStyle-Width="200" SortExpression="role">
                                                    <ItemTemplate>
                                                        <asp:LinkButton ID="btnViewFile"
                                                            runat="server"
                                                            CssClass="btn btn-primary"
                                                            CommandArgument='<%# Eval("id_path") %>'
                                                            OnCommand="btnViewFile_Command" UseSubmitBehavior="false">View ID</asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Attendance" ItemStyle-Width="150">
                                                    <ItemTemplate>
                                                        <button type="button"
                                                            class="btn btn-success btn-sm"
                                                            onclick="openAttendance('<%# Eval("staff_id") %>')">
                                                            View Attendance
                                                        </button>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="100" HeaderText="Edit">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("staff_id")%>'> <img src="Images/123.png"  /></asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField ItemStyle-Width="50" HeaderText="Delete">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');"><img src="Images/delete_10781634.png" height="25" width="25" /> </asp:LinkButton>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                            </Columns>
                                        </asp:GridView>



                                        <%--Attendance model--%>
                                        <div class="modal fade" id="attendanceModal" tabindex="-1">
                                            <div class="modal-dialog modal-lg">
                                                <div class="modal-content">
                                                    <div class="modal-header bg-primary text-white">
                                                        <h5 class="modal-title">Staff Attendance</h5>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>


                                                    <div class="row text-center mb-3">
                                                        <div class="row text-center mb-3" id="attendanceSummary">
                                                            <div class="col">
                                                                <div class="p-2 rounded bg-success text-white">
                                                                    <h6 class="mb-0">Present</h6>
                                                                    <h4 id="presentCount">0</h4>
                                                                </div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="p-2 rounded bg-danger text-white">
                                                                    <h6 class="mb-0">Absent</h6>
                                                                    <h4 id="absentCount">0</h4>
                                                                </div>
                                                            </div>
                                                            <div class="col">
                                                                <div class="p-2 rounded bg-warning text-dark">
                                                                    <h6 class="mb-0">Leave</h6>
                                                                    <h4 id="leaveCount">0</h4>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div class="modal-body">
                                                            <div id="calendar"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                      <%--Attendance model--%>
                                    </div>
                                </div>
                            </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-6">
                        <div class="modal-content" style="height: auto; width: 400px;">
                            <div class="modal-header">
                                <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Staff Details</strong></h4>
                            </div>
                            <div class="modal-body" id="invoice_data">


                                <div class="form-group">
                                    <div class="alert alert-danger danger" style="display: none;"></div>
                                </div>
                                <asp:UpdatePanel ID="upnlCountry" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="staff_id" runat="Server"></asp:HiddenField>
                                        <asp:HiddenField ID="build_id" runat="server" />
                                        <asp:HiddenField ID="role_id" runat="server" />

                                        <asp:HiddenField ID="society_name" runat="server" />

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Name"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox OnTextChanged="isStaffExist" ID="txt_name" CssClass="form-control resized-input" runat="server" Height="32px" placeholder="Enter Name" required autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Name

                                                    </div>
                                                    <asp:Label runat="server" ID="lblNameExist" Visible="False" Text="Staff already exist" ForeColor="Red"></asp:Label>
                                                    <br />


                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label14" runat="server" Text="Role"></asp:Label>
                                                    <asp:Label ID="Label15" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label16" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <div class="dropdown-container">
                                                        <asp:TextBox ID="categoryBox" runat="server" CssClass="input-box resized-input form-control"
                                                            placeholder="Select" autocomplete="off" required="required" />
                                                        <div id="categoryRepeaterContainer" class="suggestion-list">
                                                            <asp:Repeater ID="categoryRepeater" runat="server" OnItemDataBound="categoryRepeater_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand">
                                                                <ItemTemplate>
                                                                    <asp:LinkButton
                                                                        ID="lnkCategory"
                                                                        runat="server"
                                                                        CssClass="suggestion-item link-button category-link"
                                                                        Text='<%# Eval("role") %>'
                                                                        CommandArgument='<%# Eval("role_id") %>'
                                                                        CommandName="SelectCategory"
                                                                        OnClientClick="setCategoryBox(this.innerText);" />
                                                                </ItemTemplate>
                                                                <%--                                                                <FooterTemplate>
                                                                    <asp:Literal ID="litNoItem" runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                                                        Text="No items found." />
                                                                </FooterTemplate>--%>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>

                                                </div>

                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label7" runat="server" Text=" Address"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_address" CssClass="form-control resized-input" runat="server" Height="32px" Style="text-transform: capitalize;" placeholder="Enter Address" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Adress
                                                    </div>

                                                    <%--<asp:CalendarExtender ID="CalendarExtender1" runat="server" Enabled="True" TargetControlID="txt_valid_to" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label4" runat="server" Text="Contact No"></asp:Label>
                                                    <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_contact" onkeypress="return event.charCode >= 48 && event.charCode <= 57" CssClass="form-control resized-input" runat="server" MaxLength="10" Height="32px" TextMode="Phone" placeholder="Enter Contact No" required autofocus AutoPostBack="true"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Contact No
                                                    </div>
                                                    <%-- <asp:RegularExpressionValidator ID="RegularExpressionValidator2" runat="server" ControlToValidate="txt_contact" ErrorMessage="Numbers Only" Font-Bold="True" ForeColor="Red" ValidationExpression="^\d+" Display="Dynamic" ValidationGroup="g1"></asp:RegularExpressionValidator>--%>
                                                    <asp:Label ID="Label19" runat="server" Font-Bold="True" ForeColor="Red"></asp:Label>
                                                </div>

                                            </div>
                                        </div>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label11" runat="server" Text="Email"></asp:Label>
                                                    <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_email" CssClass="form-control resized-input" runat="server" TextMode="Email" Height="32px" placeholder="Enter Email" autofocus></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Valid Email
                                                    </div>
                                                </div>

                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Lbl1" runat="server" Text="Salary"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_Salary" CssClass="form-control resized-input" runat="server" TextMode="Email" Height="32px" placeholder="Enter Salary" autofocus></asp:TextBox>

                                                </div>

                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-4">
                                                    <asp:Label ID="Label10" runat="server" Text="Date of Join"></asp:Label>
                                                    <asp:Label ID="Label17" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label18" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>
                                                <div class="col-sm-6">
                                                    <asp:TextBox ID="txt_doj" CssClass="form-control resized-input" runat="server" Height="32px" placeholder="Enter Address" TextMode="Date" required></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Date
                                                    </div>

                                                    <%--<asp:CalendarExtender ID="CalendarExtender1" runat="server" Enabled="True" TargetControlID="txt_valid_to" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- File Upload -->
                                        <div class="form-group">
                                            <div class="row align-items-center mb-3">
                                                <div class="col-12 col-sm-3">
                                                    <asp:Label ID="Label1" runat="server" Text="ID Proof"></asp:Label>
                                                </div>
                                                <div class="col-12 col-sm-9">
                                                    <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf, .jpg, .jpeg" onchange="validateFileSize(this)" />
                                                    <div class="overflow-div">
                                                        <asp:Label ID="listofuploadedfiles" runat="server" />
                                                    </div>
                                                    <asp:Label ID="uploadphotopath" runat="server" Visible="false" />
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
                                            <asp:Button ID="btn_save" OnClientClick="disableSaveButtonIfValid();" runat="server" Text="Save" OnClick="btn_save_Click" class="btn btn-primary" ValidationGroup="g1" />
                                            <asp:Button ID="btn_delete" runat="server" Text="Delete" OnClick="btn_delete_Click" OnClientClick="return confirm('Are you sure want to delete?');" class="btn btn-primary" Visible="False" />
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

    <!--  PDF Modal -->

    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Modal Content -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Staff Details</strong></h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">

                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->
                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">
                        <asp:GridView ID="GridView3" runat="server"
                            CssClass="table table-bordered table-hover table-sm gridview-custom"
                            AutoGenerateColumns="false"
                            ShowHeaderWhenEmpty="true"
                            EmptyDataText="No data found."
                            HeaderStyle-BackColor="#012970"
                            HeaderStyle-ForeColor="White"
                            Font-Size="Small"
                            GridLines="Both"
                            CellPadding="6"
                            BorderStyle="None"
                            BorderWidth="0px">

                            <Columns>
                                <asp:TemplateField HeaderText="No">
                                    <ItemStyle Width="10px" />
                                    <HeaderStyle Width="10px" />
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="ID" Visible="false">
                                    <ItemTemplate>
                                        <asp:Label ID="staff_id" runat="server" Text='<%# Bind("staff_id") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Name">
                                    <ItemStyle Width="120px" />
                                    <HeaderStyle Width="120px" />
                                    <ItemTemplate>
                                        <asp:Label ID="name" runat="server" Text='<%# Bind("name") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Address">
                                    <ItemStyle Width="150px" />
                                    <HeaderStyle Width="150px" />
                                    <ItemTemplate>
                                        <asp:Label ID="address" runat="server" Text='<%# Bind("address") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Contact No">
                                    <ItemStyle Width="100px" />
                                    <HeaderStyle Width="100px" />
                                    <ItemTemplate>
                                        <asp:Label ID="contact_no" runat="server" Text='<%# Bind("contact_no") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Email">
                                    <ItemStyle Width="150px" />
                                    <HeaderStyle Width="150px" />
                                    <ItemTemplate>
                                        <asp:Label ID="email" runat="server" Text='<%# Bind("email") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Date of Join">
                                    <ItemStyle Width="100px" />
                                    <HeaderStyle Width="100px" />
                                    <ItemTemplate>
                                        <asp:Label ID="date_of_join" runat="server" Text='<%# Bind("date_of_join", "{0:dd-MM-yyyy}") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Role">
                                    <ItemStyle Width="100px" />
                                    <HeaderStyle Width="100px" />
                                    <ItemTemplate>
                                        <asp:Label ID="role" runat="server" Text='<%# Bind("role") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>


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
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>


    <!-- Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

    <!-- jQuery (Required for AJAX WebMethod) -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

    <!-- FullCalendar -->
    <link href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.8/index.global.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.8/index.global.min.js"></script>



    <script>
        let formSubmitted = false;
    </script>


    <%--Script for showing attendance--%>
    <script>
        var calendar;

        function openAttendance(staffId) {

            var modal = new bootstrap.Modal(document.getElementById('attendanceModal'));
            modal.show();

            if (calendar) {
                calendar.destroy();
            }

            calendar = new FullCalendar.Calendar(document.getElementById('calendar'), {
                initialView: 'dayGridMonth',
                height: 520,

                /* 🔒 BLOCK PREV / NEXT MONTH */
                showNonCurrentDates: false,
                fixedWeekCount: false,

                headerToolbar: {
                    left: 'prev,next today',
                    center: 'title',
                    right: ''
                },

                events: function (fetchInfo, successCallback, failureCallback) {

                    fetch('VoteService.asmx/GetAttendance', {
                        method: 'POST',
                        credentials: 'include',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ staff_id: staffId })
                    })
                        .then(response => response.json())
                        .then(data => {

                            // ✅ 1. Merge duplicate DB rows per date
                            const mergedEvents = mergeAttendanceByDate(data.d);
                            console.log(data.d);


                            // ✅ 2. Filter ONLY visible month
                            const filteredEvents = mergedEvents.filter(e => {
                                const d = new Date(e.start);
                                return d >= fetchInfo.start && d < fetchInfo.end;
                            });

                            // ✅ 3. Update counts
                            updateCounts(filteredEvents);

                            // ✅ 4. Render ONCE
                            successCallback(filteredEvents);
                        })
                        .catch(error => {
                            alert("Failed to load attendance");
                            failureCallback(error);
                        });
                }
            });

            document.getElementById('attendanceModal')
                .addEventListener('shown.bs.modal', function () {
                    calendar.render();
                }, { once: true });

        }
        
        /* ================== HELPERS ================== */

        // ✅ Merge multiple attendance rows per date into ONE
        function mergeAttendanceByDate(events) {

            const map = {};

            events.forEach(e => {

                const dateKey = e.start.split('T')[0]; // yyyy-mm-dd

                if (!map[dateKey]) {
                    map[dateKey] = e;
                } else {
                    // Priority: Present > Leave > Absent
                    if (e.title === 'Present') {
                        map[dateKey] = e;
                    }
                    else if (e.title === 'Leave' && map[dateKey].title !== 'Present') {
                        map[dateKey] = e;
                    }
                }
            });

            return Object.values(map);
        }

        // ✅ Monthly counts (use FILTERED events only)
        function updateCounts(events) {

            let present = 0;
            let absent = 0;
            let leave = 0;

            events.forEach(e => {
                if (e.title === 'Present') present++;
                else if (e.title === 'Absent') absent++;
                else if (e.title === 'Leave') leave++;
            });

            document.getElementById('presentCount').innerText = present;
            document.getElementById('absentCount').innerText = absent;
            document.getElementById('leaveCount').innerText = leave;
        }
    </script>



    <script>       
        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");

            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clone modal-body for offscreen rendering
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);
            cloneContainer.appendChild(clone);

            // Apply table border styles directly to cloned element
            const table = clone.querySelector('table');
            if (table) {
                table.style.borderCollapse = 'collapse';
                table.style.border = '2px solid #4f5d73';
                table.style.width = '100%';

                // Style header cells
                const headerCells = table.querySelectorAll('thead th, th');
                headerCells.forEach(th => {
                    th.style.borderBottom = '3px solid #4f5d73';
                    th.style.borderLeft = '2px solid #4f5d73';
                    th.style.borderRight = '2px solid #4f5d73';
                    th.style.backgroundColor = '#fff';
                    th.style.color = '#012970';
                    th.style.fontWeight = '600';
                    th.style.padding = '8px';
                });

                // Style data cells - DARK BORDERS
                const dataCells = table.querySelectorAll('tbody td');
                dataCells.forEach(td => {
                    td.style.borderBottom = '2px solid #4f5d73';
                    td.style.borderLeft = '2px solid #4f5d73';
                    td.style.borderRight = '2px solid #4f5d73';
                    td.style.color = '#222';
                    td.style.padding = '8px';
                    td.style.backgroundColor = '#ffffff'; // White background
                });
            }

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true
                });

                const imgData = canvas.toDataURL("image/png");

                // ✅ Use Portrait A4 (595pt width x 842pt height)
                const pdf = new jsPDF("portrait", "pt", "a4");

                const pageWidth = pdf.internal.pageSize.getWidth();    // 595
                const pageHeight = pdf.internal.pageSize.getHeight();  // 842
                const margin = 40;
                const title = "Staff Details";

                // Title on first page
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const titleX = (pageWidth - textWidth) / 2;
                pdf.text(title, titleX, 40);

                // Image settings
                const availableWidth = pageWidth - margin * 2;
                const fullImageHeight = (canvas.height * availableWidth) / canvas.width;
                const pageAvailableHeight = pageHeight - 60 - margin; // 60pt used for title

                let yPosition = 60; // First image Y after title
                let remainingHeight = fullImageHeight;
                let sourceY = 0;

                while (remainingHeight > 0) {
                    const canvasPartHeight = Math.min(pageAvailableHeight, remainingHeight);
                    const cropCanvas = document.createElement("canvas");
                    cropCanvas.width = canvas.width;
                    cropCanvas.height = (canvasPartHeight * canvas.width) / availableWidth;

                    const ctx = cropCanvas.getContext("2d");
                    ctx.drawImage(
                        canvas,
                        0, sourceY, canvas.width, cropCanvas.height,
                        0, 0, canvas.width, cropCanvas.height
                    );

                    const croppedImageData = cropCanvas.toDataURL("image/png");
                    pdf.addImage(croppedImageData, "PNG", margin, yPosition, availableWidth, canvasPartHeight);

                    remainingHeight -= canvasPartHeight;
                    sourceY += cropCanvas.height;

                    if (remainingHeight > 0) {
                        pdf.addPage();
                        yPosition = margin; // Top margin for new pages (no title)
                    }
                }

                pdf.save("StaffDetails.pdf");

            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }

      

        function initDropdownEvents() {
            const categoryBox = document.getElementById("<%= categoryBox.ClientID %>");
      const categorySuggestions = document.getElementById("categoryRepeaterContainer");


      categoryBox.addEventListener("focus", function () {
          categorySuggestions.style.display = "block";
      });

            // Filter items as the user types
            categoryBox.addEventListener("input", function () {
                const input = categoryBox.value.toLowerCase();
                filterSuggestions("category-link", input);
            });

            // Hide dropdown when clicking outside
            document.addEventListener("click", function (e) {
                if (!categoryBox.contains(e.target) && !categorySuggestions.contains(e.target)) {
                    categorySuggestions.style.display = "none";
                }
            });

            // Prevent closing dropdown when clicking inside it
            //categorySuggestions.addEventListener("click", function (e) {
            //    e.stopPropagation();
            //});   
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
              noMatchMessage.className = "text-muted p-2";
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

  function setCategoryBox(value) {
      document.getElementById("<%= categoryBox.ClientID %>").value = value;
      document.getElementById("categoryRepeaterContainer").style.display = "none";

      // Remove invalid class when valid selection is made
            document.getElementById("<%= categoryBox.ClientID %>").classList.remove("is-invalid");
        }


        function printflatDetails() {
            var modalContent = document.querySelector("#pdfmodal .modal-body").innerHTML;

            var printWindow = window.open('', '', 'height=700,width=900');
            printWindow.document.write('<html><head><title>Visitor Details</title>');
            printWindow.document.write('<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">');
            printWindow.document.write('<style>');
            printWindow.document.write('body {font - size: 12px; margin: 30px; font-family: Arial, sans-serif; }');
            printWindow.document.write('h4 {margin - bottom: 10px; text-align: center; }');
            printWindow.document.write('.table {width: 100%; border-collapse: collapse; margin-top: 20px; }');
            printWindow.document.write('th, td {border: 1px solid #ccc; padding: 8px; text-align: left; }');
            printWindow.document.write('th {background - color: #012970; color: white; text-align: center; }');
            printWindow.document.write('.print-header {text - align: center; margin-bottom: 20px; }');
            printWindow.document.write('</style>');
            printWindow.document.write('</head><body>');

            // Add centered headers manually
            printWindow.document.write('<div class="print-header">');
            printWindow.document.write('<h4><strong>' + document.querySelector("#pdfmodal h4 strong").innerText + '</strong></h4>'); // Visitor Details

            printWindow.document.write('</div>');

            // Add GridView content
            printWindow.document.write(modalContent);

            // Optional: Print timestamp
            const now = new Date();
            const formattedDate = now.getDate().toString().padStart(2, '0') + '/' +
                (now.getMonth() + 1).toString().padStart(2, '0') + '/' +
                now.getFullYear();
            const formattedTime = now.toLocaleTimeString();
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + formattedDate + ' ' + formattedTime + '</div>');

            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

        Sys.Application.add_load(initDropdownEvents);


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
