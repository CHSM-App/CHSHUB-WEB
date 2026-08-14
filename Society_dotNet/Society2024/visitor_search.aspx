<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="visitor_search.aspx.cs" Inherits="Society.visitor_search" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css" />


    <style>


        .visitor-image-wrapper {
    padding: 12px 0;
   
    border-bottom: 1px solid #dee2e6;
}

.visitor-image {
    height:150px;  
    object-fit:cover;  
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.25);
}

       .resized-model {
            width: 900px;
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

        @media(max-width :650px) {
            .top-row {
                flex-direction: column;
            }
        }

        .input-buttons {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        #dateInput {
            width: 150px;
            padding: 6px 10px;
        }

        .calendar-icon {
            width: 24px;
            height: 24px;
        }

        .calendar-input {
            background: url('img/calendar.png') no-repeat right 10px center;
            background-size: 20px 20px;
            padding-right: 30px; /* space for image */
        }

        .calendar-input {
            background-image: url('img/calendar.png');
            background-repeat: no-repeat;
            background-position: center;
            background-size: 24px 24px;
            border: none;
            outline: none;
            width: 30px;
            height: 30px;
            color: transparent; /* hide text */
            cursor: pointer;
        }

            .calendar-input::placeholder {
                color: transparent;
            }

        .pr {
            padding: 7px 15px;
            padding-right: 70px;
        }


         /* View Details Button */
        .btn-view-details {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        .btn-view-details:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
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
                    window.location.href = 'visitor_search.aspx';
                }
            });
        }

        function openModal() {
            $('#view_model').modal('show');
        }

        function disableSaveButtonIfValid() {
            var btn = document.getElementById('<%= btn_in.ClientID %>');
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


                    __doPostBack('<%= btn_in.UniqueID %>', '');

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
                console.log("Hello")
                btn.click();   // ✅ correct
            }
        }

    </script>

    <%--        <div class="box box-primary">
            <div class="box-header with-border">
                <div class="box-body">--%>


    <table width="100%">
        <tr>
            <th width="100%">
                <h1 class=" font-weight-bold " style="color: #012970;">Visitors</h1>
            </th>
        </tr>
    </table>
    <br />




    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <asp:HiddenField ID="visitor_id" runat="server"></asp:HiddenField>
            <asp:HiddenField ID="society_id" runat="server" />
            <asp:HiddenField runat="server" ID="datefrom" />
            <asp:HiddenField runat="server" ID="dateto" />


            <asp:HiddenField ID="society_name" runat="server" />

            <div class="form-group">
                <div class="row">
                    <!-- Search and Calendar Container -->
                    <div class="col-12">
                        <div class="top-row d-flex align-items-center" style="gap: 12px;">
                            <div class="search-container">

                                <!-- Search TextBox -->
                                <asp:TextBox
                                    ID="txt_search"
                                    CssClass="aspNetTextBox "
                                    placeholder="Search here"
                                    runat="server"
                                    
                                    TextMode="Search"
                                    autocomplete="off"
                                    onkeyup="triggerSearch()" Style="padding-right: 70px;" />

                                <div class="input-buttons">

                                    <asp:TextBox ID="calendarRange" runat="server" CssClass="calendar-input" />
                                    <!-- Search Button -->
                                    <button
                                        id="btn_search"
                                        type="button"
                                        class="search-button2"
                                        
                                         onclick="filterTable()">
                                        <span class="material-symbols-outlined">search</span>
                                    </button>

                                </div>
                            </div>
                            <!-- Buttons Section (Add and Print buttons) -->

                            <div class=" d-flex">
                                <!-- "Add" Button -->
                                <asp:Button Visible="false" runat="server" ID="btn_save" type="button" UseSubmitBehavior="False" class="btn btn-primary me-2" data-toggle="modal" data-target="#edit_model" Text="Add" />

                                <!-- "Print" Button -->
                                <button type="button" class="btn btn-primary" onclick="printVisitorDetails()">Print</button>
                                &nbsp; 
                                                <button type="button" class="btn btn-success" usesubmitbehavior="False" onclick="downloadReceipt()">
                                                    <i class="fas fa-download me-1"></i>Download Report      
                                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>



            <div class="form-group">
                <div class="row ">
                    <div class="col-sm-12">
                        <div style="width: 100%; overflow: visible;" class="g-Table">
                            <asp:GridView ID="GridView1" runat="server"   OnPageIndexChanging="GridView1_PageIndexChanging" CssClass="table table-bordered table-hover table-striped" OnRowUpdating="GridView1_RowUpdating" OnSorting="GridView1_Sorting" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" AutoGenerateColumns="false" OnRowDeleting="GridView1_RowDeleting">
                                <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                <Columns>
                                    <asp:TemplateField HeaderText="No" Visible="true">
                                        <ItemTemplate>
                                            <asp:Label ID="No" runat="server" Text='<%#Container.DataItemIndex+1 %>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="visitor_id" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label ID="visitor_id" runat="server" Text='<%#Bind("visitor_id")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Name" SortExpression="v_name">
                                        <ItemTemplate>
                                            <asp:Label ID="ID1" runat="server" Text='<%#Bind("v_name")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Visitor Type" SortExpression="type">
                                        <ItemTemplate>
                                            <asp:Label ID="v_type" runat="server" Text='<%# Bind("type")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="In Date" SortExpression="in_date">
                                        <ItemTemplate>
                                            <asp:Label ID="in_date" runat="server" Text='<%# Bind("in_date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="IN Time" SortExpression="in_time">
                                        <ItemTemplate>
                                            <asp:Label ID="in_time" runat="server" Text='<%# Bind("in_time")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Out Date" SortExpression="out_date">
                                        <ItemTemplate>
                                            <asp:Label ID="out_date" runat="server" Text='<%# Bind("out_date", "{0:dd-MM-yyyy}")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Out Time" SortExpression="out_time">
                                        <ItemTemplate>
                                            <asp:Label ID="out_time" runat="server" Text='<%# Bind("out_time")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Details">
                                        <ItemTemplate>
                                            <asp:LinkButton runat="server" ID="View_model" CssClass="btn-view-details" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("visitor_id")%>'><i class="fa fa-eye"></i></asp:LinkButton>

                                            </asp:LinkButton>

                                        </ItemTemplate>
                                    </asp:TemplateField>

                                  

                                    <asp:TemplateField ItemStyle-Width="50" Visible="False">
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


    <%--View model start--%>
    <div class="modal fade bs-example-modal-sm" id="view_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-sm-4">
            <div class="modal-content resized-model">
                <div class="modal-header">
                    <h4 class="modal-title"><strong>Visitor Details</strong></h4>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <div class="container">
                                <!-- Visitor Image -->
                                <div class="visitor-image-wrapper form-group text-center">
                                    <asp:Image ID="imgVisitor" runat="server"
                                        CssClass="visitor-image"
                                        AlternateText="Visitor image" />
                                </div>

                                <!-- Static Fields -->
                                <div class="form-group detail-row">
                                    <div class="row">

                                        <!-- Label 1 + Value 1 -->
                                        <div class="col-md-2 detail-label">
                                            <label>Full Name</label>
                                        </div>
                                        <div class="col-md-4">
                                            <asp:TextBox ID="txtFullName" runat="server"
                                                CssClass="form-control detail-value" ReadOnly="true" />
                                        </div>

                                        <!-- Label 2 + Value 2 -->
                                        <div class="col-md-2 detail-label">
                                            <label>Phone Number:</label>
                                        </div>
                                        <div class="col-md-4">
                                            <asp:TextBox ID="txtPhoneNo" runat="server"
                                                CssClass="form-control detail-value" ReadOnly="true" />
                                        </div>

                                    </div>
                                </div>

                                <div class="form-group detail-row">
                                    <div class="row">
                                        <div class="col-md-2 detail-label">
                                            <label>Flat Number:</label>
                                        </div>
                                        <div class="col-md-4">
                                            <asp:TextBox ID="txtFlatNo" runat="server"
                                                CssClass="form-control detail-value" ReadOnly="true" />
                                        </div>
                                    </div>
                                </div>
                                <hr class="my-4" />

                                <!-- Entry Type -->
                                <div class="form-group">
                                    <%--<label>Entry Type</label><br />--%>
                                    <asp:Label ID="lblEntryType" runat="server"
                                        CssClass="badge badge-primary badge-entry-type"></asp:Label>
                                </div>


                                <!-- Guest Section -->
                                <asp:Panel ID="pnlGuest" runat="server" CssClass="entry-section" Visible="false">
                                    <h6 class="mb-3">Entry Type: Guest</h6>


                                    <div class="form-group detail-row">
                                        <div class="row">

                                            <!-- Label 1 + Value 1 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Purpose:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtGuestPurpose" runat="server"
                                                    CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>

                                            <!-- Label 2 + Value 2 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Address:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtGuestAddress" runat="server"
                                                    CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Cab Section -->
                                <asp:Panel ID="pnlCab" runat="server" CssClass="entry-section" Visible="false">
                                    <h6 class="mb-3">Entry Type: Cab</h6>
                                    <div class="form-group detail-row">
                                        <div class="row">

                                            <!-- Label 1 + Value 1 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Company:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtCabCompany" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>

                                            <!-- Label 2 + Value 2 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Vehicle Number:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtCabVehicle" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>

                                    <%--Single Label 3--%>
                                    <div class="form-group detail-row">
                                        <div class="row">
                                            <div class="col-md-2 detail-label">
                                                <label>Pickup/Drop Location:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtCabLocation" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Delivery Section -->
                                <asp:Panel ID="pnlDelivery" runat="server" CssClass="entry-section" Visible="false">
                                    <h6 class="mb-3">Entry Type: Delivery</h6>
                                    <div class="form-group detail-row">
                                        <div class="row">
                                            <!-- Label 1 + Value 1 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Company:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtDeliveryCompany" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>

                                            <!-- Label 2 + Value 2 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Vehicle Number:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtDeliveryVehicle" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>

                                    <%--Single Label 3--%>
                                    <div class="form-group detail-row">
                                        <div class="row">
                                            <div class="col-md-2 detail-label">
                                                <label>Package Description:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtPackageDesc" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Service Section -->
                                <asp:Panel ID="pnlService" runat="server" CssClass="entry-section" Visible="false">
                                    <h6 class="mb-3">Entry Type: Service</h6>
                                    <div class="form-group detail-row">
                                        <div class="row">
                                            <!-- Label 1 + Value 1 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Company:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtServiceCompany" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>

                                            <!-- Label 2 + Value 2 -->
                                            <div class="col-md-2 detail-label">
                                                <label>Vehicle Number:</label>
                                            </div>
                                            <div class="col-md-4">
                                                <asp:TextBox ID="txtServiceVehicle" runat="server" CssClass="form-control detail-value" ReadOnly="true" />
                                            </div>
                                        </div>
                                    </div>
                                </asp:Panel>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
                <div class="modal-footer">
                </div>
            </div>
        </div>
    </div>
    <%--view model end--%>

    <div class="modal fade bs-example-modal-sm" id="edit_model" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-sm-4">
            <div class="modal-content resized-model">
                <div class="modal-header">
                    <h4 class="modal-title" id="gridSystemModalLabel"><strong>Visitor Details</strong></h4>
                </div>
                <div class="modal-body" id="invoice_data">

                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>
                            <asp:HiddenField runat="server" ID="building_id" />
                            <asp:HiddenField ID="visitor_flat_id" runat="server" />
                            <asp:HiddenField ID="searchDateFrom" runat="server" />
                            <asp:HiddenField ID="SearchDateTo" runat="server" />
                            <div class="form-group">
                                <div class="row ">
                                    <div class="col-sm-3">
                                        <asp:Label ID="lbl_date" runat="server" Text="In Date"></asp:Label>
                                        <asp:Label ID="lbl_date_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_in_date" Width="192px" Height="32px" TextMode="Date" runat="server" Enabled="false"></asp:TextBox>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:Label ID="Label32" runat="server" Text="Out Date"></asp:Label>
                                        <asp:Label ID="Label33" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox AutoPostBack="true" ID="txt_out_date" TextMode="Date" Width="192px" Height="32px" runat="server" ValidationGroup="g1" OnTextChanged="txt_out_time_TextChanged"></asp:TextBox>
                                    </div>
                                </div>
                            </div>
                            <div class="form-group">
                                <div class="row ">
                                    <div class="col-sm-3"></div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_in_time" runat="server" Width="192px" Height="32px" Enabled="false"></asp:TextBox>
                                    </div>
                                    <div class="col-sm-3"></div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_out_time" Width="192px" Height="32px" TextMode="Time" runat="server" ValidationGroup="g1"></asp:TextBox>
                                    </div>
                                </div>
                            </div>

                            <div class="form-group">
                                <div class="row ">
                                    <div class="col-sm-3">
                                        <asp:Label ID="Label3" runat="server" Text="Visitor's name:"></asp:Label>

                                        <asp:Label ID="lbl_acc_no_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_v_name" CssClass="form-control" runat="server" Style="text-transform: capitalize;" required placeholder="Enter Visitor's Name" Width="192px" Height="32px"></asp:TextBox>
                                        <div class="invalid-feedback">
                                            Please Enter Visitors Name
                                        </div>
                                    </div>


                                    <div class="col-sm-3">
                                        <asp:Label ID="Label34" runat="server" Text="Contact No"></asp:Label>
                                        <asp:Label ID="Label35" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label36" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_contact" CssClass="form-control" runat="server" MaxLength="10" TextMode="Phone" placeholder="Enter Number" required="required" onkeypress="return event.charCode >= 48 && event.charCode <= 57"></asp:TextBox>
                                        <div class="invalid-feedback">
                                            Please Enter Contact No
                                        </div>
                                        <br />
                                    </div>
                                </div>
                            </div>

                            <div class="form-group">
                                <div class="row ">
                                    <div class="col-sm-3">
                                        <asp:Label ID="Label29" runat="server" Text="Building"></asp:Label>
                                        <asp:Label ID="Label30" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label31" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <div class="dropdown-container">
                                            <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                placeholder="Select" autocomplete="off" required="required" />
                                            <div id="RepeaterContainer1" class="suggestion-list">
                                                <asp:Repeater ID="Repeater1" runat="server" OnItemDataBound="Repeater1_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                    <ItemTemplate>
                                                        <asp:LinkButton
                                                            ID="lnkCategory"
                                                            runat="server"
                                                            CssClass="suggestion-item link-button category-link"
                                                            Text='<%# Eval("name") %>'
                                                            CommandArgument='<%# Eval("build_id") %>'
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
                                        <asp:Label ID="Label6" runat="server" Text="Visiting Flat No"></asp:Label>
                                        <asp:Label ID="Label10" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label11" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <div class="dropdown-container">
                                            <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                placeholder="Select" autocomplete="off" required="required" />
                                            <div id="RepeaterContainer2" class="suggestion-list">
                                                <asp:Repeater ID="Repeater2" runat="server" OnItemDataBound="Repeater2_ItemDataBound" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                    <ItemTemplate>
                                                        <asp:LinkButton
                                                            ID="lnkCategory"
                                                            runat="server"
                                                            CssClass="suggestion-item link-button category-link"
                                                            Text='<%# Eval("unit") %>'
                                                            CommandArgument='<%# Eval("flat_id") %>'
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
                                        <asp:Label ID="Label7" runat="server" Text="Visiting Type"></asp:Label>
                                        <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label9" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*" required></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:DropDownList ID="ddl_visiting_type" OnSelectedIndexChanged="ddl_visiting_type_SelectedIndexChanged" runat="server" Height="32px" Width="192px" AutoPostBack="true">
                                            <asp:ListItem>Select</asp:ListItem>
                                            <asp:ListItem Value="Cab">Cab </asp:ListItem>
                                            <asp:ListItem Value="Service">Home Service </asp:ListItem>
                                            <asp:ListItem Value="Delivery">Delivery </asp:ListItem>
                                            <asp:ListItem Value="Guest">Guest & Others </asp:ListItem>
                                        </asp:DropDownList>

                                    </div>

                                    <div class="col-sm-3">
                                        <asp:Label ID="Label12" runat="server" Text="Vehicle No"></asp:Label>
                                        <asp:Label ID="Label13" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_vehical_no" runat="server" Style="text-transform: capitalize;" MaxLength="250" placeholder="Enter Vehical No." Width="192px" Height="32px"></asp:TextBox>

                                    </div>
                                </div>
                            </div>

                            <asp:Panel ID="delivary" runat="server" Visible="false">
                                <div class="form-group">
                                    <div class="row ">

                                        <div class="col-sm-3">
                                            <asp:Label ID="Label4" runat="server" Text="Preference"></asp:Label>
                                            <asp:Label ID="Label5" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                            <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                        </div>
                                        <div class="col-sm-4">
                                            <asp:RadioButton ID="RadioButton1" runat="server" Text="Leave At Gate" Checked="true" GroupName="led_status" />
                                            &nbsp;&nbsp;
                                                         <asp:RadioButton ID="RadioButton2" runat="server" Text="Doorstep" GroupName="led_status" />
                                        </div>
                                    </div>
                            </asp:Panel>

                            <div class="form-group">
                                <div class="row ">

                                    <div class="col-sm-3">
                                        <asp:Label ID="Label19" runat="server" Text="Visiting Purpose"></asp:Label>
                                        <asp:Label ID="Label20" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label21" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <div class="col-sm-3">
                                        <asp:TextBox ID="txt_visiting_purpose" CssClass="form-control" runat="server" Style="text-transform: capitalize;" MaxLength="250" Width="192px" Height="32px" placeholder="Enter Visiting Purpose" required></asp:TextBox>
                                        <div class="invalid-feedback">
                                            Please Enter Visiting Purpose
                                        </div>
                                    </div>

                                    <div class="col-sm-3">
                                        <asp:Label ID="Label26" runat="server" Text="Image"></asp:Label>
                                        <asp:Label ID="Label27" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                        <asp:Label ID="Label28" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                    </div>
                                    <%--                                                <div class="col-sm-3">
                                                        <div class="d-flex flex-column">
                                                            <asp:FileUpload required="required" ID="FileUpload1" runat="server" accept=".jpg,jpeg" />
                                                            <asp:Label ID="image" runat="server"></asp:Label>
                                                            <asp:Image ID="UploadedImage" runat="server" Width="200px" />
                                                        </div>
                                                    </div>--%>
                                </div>
                            </div>


                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                            <asp:AsyncPostBackTrigger ControlID="txt_out_date" EventName="TextChanged" />

                        </Triggers>

                    </asp:UpdatePanel>
                    <div class="col-sm-3">
                        <div class="d-flex flex-column">
                            <asp:FileUpload required="required" ID="FileUpload1" runat="server" accept=".jpg,jpeg" />
                            <asp:Label ID="image" runat="server"></asp:Label>
                            <asp:Image ID="UploadedImage" runat="server" Width="200px" />
                        </div>
                    </div>

                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <div class="modal-footer">
                            <div class="form-group">
                                <div class="row ">
                                    <div class="col-sm-12">
                                        <div class="pull-center ml-4">
                                            <asp:Button OnClientClick="disableSaveButtonIfValid();" ID="btn_in" Visible="true" runat="server" Text="In" class="btn btn-primary" BackColor="red" ValidationGroup="valid" OnClick="btn_in_Click" />
                                            <asp:Button ID="btn_out" Visible="false" runat="server" Text="Out" class="btn btn-primary" BackColor="red" ValidationGroup="g1" OnClick="btn_out_Click" />
                                            <asp:Button ID="btn_close" runat="server" Text="Close" class="btn btn-primary" UseSubmitBehavior="False" OnClientClick="resetForm(); return false;" data-dismiss="modal" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="txt_out_date" EventName="TextChanged" />
                        <asp:AsyncPostBackTrigger ControlID="btn_save" EventName="Click" />
                        <asp:PostBackTrigger ControlID="btn_in" />
                        <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />

                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>

    <%--                PDF MODel--%>
    <div class="modal fade bs-example-modal-sm" id="pdfmodal" role="form" aria-labelledby="myLargeModalLabel" data-backdrop="static">
        <div class="modal-dialog modal-lg">
            <!-- Changed to modal-lg for better width -->
            <div class="modal-content resized-model">

                <!-- Modal Header -->
                <div class="modal-header" style="justify-content: center;">
                    <h4 class="modal-title text-center"><strong>Visitor Details</strong></h4>
                </div>

                <!-- Modal Body -->
                <div class="modal-body">

                    <!-- Society Name -->
                    <div style="text-align: center; margin-bottom: 10px;">
                        <h4><strong><%= society_name.Value %></strong></h4>
                    </div>

                    <!-- GridView Container -->
                    <div style="padding: 10px; border-radius: 5px; background-color: #f9f9f9;">

                        <asp:GridView ID="GridView2" runat="server"
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
                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                    <ItemTemplate>
                                        <asp:Label ID="lblRowNumber" runat="server" Text='<%# Container.DataItemIndex + 1 %>' />
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField DataField="v_name" HeaderText="Visitor Name" />
                                <asp:BoundField DataField="type" HeaderText="Type" />
                                <asp:BoundField DataField="in_date" HeaderText="Visit Date" DataFormatString="{0:dd-MM-yyyy}" />
                                <asp:BoundField DataField="out_date" HeaderText="Visit Date" DataFormatString="{0:dd-MM-yyyy}" />
                                <asp:BoundField DataField="build_name" HeaderText="Building" />
                                <asp:BoundField DataField="unit" HeaderText="Flat No." />
                            </Columns>
                        </asp:GridView>
                    </div>

                </div>
            </div>
        </div>
    </div>


    <!-- Add this empty container somewhere in your page, outside modal -->
    <div id="pdf-clone-container" style="position: absolute; top: -10000px; left: -10000px;"></div>
    <!-- Bootstrap core JavaScript-->
    <script src="vendor/jquery/jquery.min.js"></script>
    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Core plugin JavaScript-->
    <script src="vendor/jquery-easing/jquery.easing.min.js"></script>

    <!-- Custom scripts for all pages-->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
    <script>
     
        async function downloadReceipt() {
            const { jsPDF } = window.jspdf;

            const sourceElement = document.querySelector("#pdfmodal .modal-body");
            const cloneContainer = document.getElementById("pdf-clone-container");

            if (!sourceElement || !cloneContainer) {
                alert("Cannot find content to export.");
                return;
            }

            // Clone modal-body into offscreen div
            cloneContainer.innerHTML = "";
            const clone = sourceElement.cloneNode(true);

            // ✅ Style table: only header bold, no outer box
            const tables = clone.querySelectorAll("table");
            tables.forEach(tbl => {
                tbl.style.borderCollapse = "collapse"; // remove extra spacing

                // Remove outer table border
                tbl.style.border = "none";

                tbl.querySelectorAll("th, td").forEach(cell => {
                    cell.style.border = "1px solid #000"; // only inner cell borders
                    if (cell.tagName.toLowerCase() === "th") {
                        cell.style.fontWeight = "bold"; // header bold
                    } else {
                        cell.style.fontWeight = "normal"; // data normal
                    }
                    cell.style.color = "#000"; // black text
                });
            });

            cloneContainer.appendChild(clone);

            try {
                const canvas = await html2canvas(clone, {
                    scale: 2,
                    useCORS: true,
                    backgroundColor: "#fff" // ensures white background
                });

                const imgData = canvas.toDataURL("image/png");
                const pdf = new jsPDF("p", "pt", "a4");

                const pageWidth = pdf.internal.pageSize.getWidth();
                const margin = 40;
                const title = "Visitor Details ";

                // Add Centered Heading
                pdf.setFontSize(16);
                pdf.setFont("helvetica", "bold");
                const textWidth = pdf.getTextWidth(title);
                const x = (pageWidth - textWidth) / 2;
                pdf.text(title, x, 40); // Y position = 40pt from top

                // Add Image Below Heading
                const imgWidth = pageWidth - margin * 2;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const imageY = 60; // leave room for heading

                pdf.addImage(imgData, "PNG", margin, imageY, imgWidth, imgHeight);
                pdf.save("VisitorReport.pdf");
            } catch (err) {
                console.error("Error generating PDF:", err);
                alert("Failed to generate PDF.");
            }
        }

        function initDropdownEvents() {

            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");

                const repeaterContainer1 = document.getElementById("RepeaterContainer1");

                textBox1.addEventListener("focus", function () {

                    repeaterContainer1.style.display = "block";

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
                document.getElementById("<%= TextBox2.ClientID %>").value = "";

            document.getElementById("RepeaterContainer1").style.display = "none";

        }

        function setTextBox2(value) {

            document.getElementById("<%= TextBox2.ClientID %>").value = value;

            document.getElementById("RepeaterContainer2").style.display = "none";

        }

        function setupFlatpickr() {
            const calendarInput = document.getElementById('<%= calendarRange.ClientID %>');
                const searchInput = document.getElementById('<%= txt_search.ClientID %>');

                if (!calendarInput) return;

                // Make sure Flatpickr is not initialized twice
                if (calendarInput._flatpickr) {
                    calendarInput._flatpickr.destroy();
                }

                calendarInput.readOnly = true;

                flatpickr(calendarInput, {
                    mode: "range",
                    dateFormat: "Y-m-d",
                    onChange: function (selectedDates) {
                        if (selectedDates.length === 2) {
                            const fromDate = selectedDates[0].toLocaleDateString('en-CA');
                            const toDate = selectedDates[1].toLocaleDateString('en-CA');
                            searchInput.value = `${fromDate} to ${toDate}`;
                            document.getElementById("<%= searchDateFrom.ClientID %>").value = fromDate;
                            document.getElementById("<%= SearchDateTo.ClientID %>").value = toDate;
                        }
                    }
                });
        }

        // Initial load
        window.onload = function () {
            setupFlatpickr();
        };

        // Re-apply after every postback
        Sys.Application.add_load(function () {
            setupFlatpickr();
            initDropdownEvents();
        });


        function printVisitorDetails() {
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
            printWindow.document.write('<div style="text-align:center; margin-top:20px;">Printed on: ' + new Date().toLocaleString() + '</div>');

            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.focus();
            printWindow.print();
            printWindow.close();
        }

    </script>

</asp:Content>