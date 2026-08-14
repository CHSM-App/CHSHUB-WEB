<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Facility_master.aspx.cs" Inherits="Society2024.Facility_master" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet" />


    <style>
        .suggautocomplete-container {
            position: relative;
        }



        .suggsuggestions-box {
            position: absolute;
            width: 100%;
            max-height: 200px;
            overflow-y: auto;
            background: white;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 4px 4px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            display: none;
            z-index: 1000;
            box-sizing: border-box;
        }

        .suggsuggestion-item {
            padding: 10px;
            cursor: pointer;
            border-bottom: 1px solid #f0f0f0;
        }

            .suggsuggestion-item:hover {
                background-color: #f0f0f0;
            }

            .suggsuggestion-item:last-child {
                border-bottom: none;
            }

        .suggno-results {
            padding: 10px;
            color: #999;
            text-align: center;
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


/*        -------------------------------------------------------------------------------*/


        
           .toggle-wrapper {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    /* Hide the default checkbox */
    .toggle-input input[type="checkbox"],
    .toggle-input {
        display: none;
    }

    .toggle-label {
        position: relative;
        width: 50px;
        height: 26px;
        background-color: #ccc;
        border-radius: 34px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    .toggle-label::before {
        content: "";
        position: absolute;
        top: 3px;
        left: 3px;
        width: 20px;
        height: 20px;
        background-color: #fff;
        border-radius: 50%;
        transition: transform 0.3s;
    }

    /* When checked */
    input[type="checkbox"]:checked + .toggle-label {
        background-color: #28a745;
    }

    input[type="checkbox"]:checked + .toggle-label::before {
        transform: translateX(24px);
    }

    .toggle-text {
        font-size: 16px;
        color: #333;
    }


    </style>

    <style>
    .toggle-wrapper {
        padding: 1.5rem;
        background: #ffffff;
        border-radius: 0.5rem;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .form-check-input {
        width: 3rem;
        height: 1.5rem;
        cursor: pointer;
    }
    
    .form-check-input:checked {
        background-color: #198754;
        border-color: #198754;
    }
    
    .form-check-label {
        cursor: pointer;
    }
    
    .form-label {
        margin-bottom: 0.5rem;
        color: #212529;
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
                    window.location.href = 'Facility_master.aspx';
                }
            });
        }
        function openModal() {
            $('#edit_model').modal('show');
        }

        function disableSaveButtonIfValid() {
            updateHiddenField();
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
                        <th width="100%" class="">
                            <h1 class=" tex0 font-weight-bold " style="color: #012970;">Facilities
                            </h1>
                        </th>
                    </tr>
                </table>
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
                                    <div style="width: 100%; overflow: visible;" class="g-Table">
                                        <asp:GridView AllowPaging="true" OnPageIndexChanging="GridView1_PageIndexChanging" PageSize="15" ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating">
                                             <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%#  Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Facility Name" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="facility_name" runat="server" Text='<%# Bind("name")%>'></asp:Label>

                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Cost of Facility" SortExpression="cost">
                                                    <ItemTemplate>
                                                        <asp:Label ID="facility_cost" runat="server" Text='<%# Eval("cost")  %>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>


                                                <asp:TemplateField HeaderText="Edit" ItemStyle-Width="50">
                                                    <ItemTemplate>
                                                        <asp:LinkButton runat="server" ID="edit" OnCommand="edit_Command" CommandName="Update" CommandArgument='<%# Bind("facility_id")%>'>
                                                            <img src="Images/123.png" /></asp:LinkButton>
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

                <div class="modal fade bs-example-modal-sm" id="edit_model" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" data-backdrop="static">
                    <div class="modal-dialog modal-sm-6">
                        <div class="modal-content resized-model">
                            <div class="modal-header">
                                <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>--%>
                                <h4 class="modal-title" id="gridSystemModalLabel"><strong>Facilities</strong></h4>
                            </div>
                            <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <asp:HiddenField ID="facility_id" runat="server" />

                                    <asp:HiddenField ID="slot_id" runat="server" />
                                    <div class="modal-body" id="invoice_data">


                                        <div class="form-group">
                                            <div class="alert alert-danger danger" style="display: none;"></div>
                                        </div>



                                        <div class="form-group">
                                            <div class="row">
                                                <!-- Facility Name -->
                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label1" runat="server" Text="Facility Name"></asp:Label>
                                                    <asp:Label ID="Label2" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label3" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>

                                                <div class="col-sm-3">
                                                    <div class="suggautocomplete-container">
                                                        <asp:TextBox ID="txt_facility" CssClass="form-control" onkeyup="showSuggestions(this)" runat="server" Height="32px" Width="200px"
                                                            placeholder="Enter Facility Name" required autofocus></asp:TextBox>

                                                        <div id="suggsuggestionsBox" class="suggsuggestions-box"></div>

                                                        <div class="invalid-feedback">
                                                            Please Enter Facility Name
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Cost of Facility -->
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_co_name" runat="server" Text="Cost of Facility"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_co_name_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_cost" CssClass="form-control" runat="server" Height="32px" Width="200px"
                                                        placeholder="Enter Facility Cost" required TextMode="Number"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Facility Cost
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Capacity Row -->
                                            <div class="row mt-2">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="lbl_capacity" runat="server" Text="Capacity"></asp:Label>
                                                    <asp:Label ID="lbl_capacity_sep" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="lbl_capacity_mandatory" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_capacity" CssClass="form-control" runat="server" Height="32px" Width="200px"
                                                        placeholder="Enter Capacity" required TextMode="Number"></asp:TextBox>
                                                    <div class="invalid-feedback">
                                                        Please Enter Capacity
                                                    </div>
                                                </div>
                                            </div>
                                        </div>




                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-3">
                                                    <asp:Label ID="txt_slot" runat="server" Text="Slots"></asp:Label>
                                                    <asp:Label ID="Label4" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                    <asp:Label ID="Label14" runat="server" Font-Bold="True" Font-Size="Large" ForeColor="Red" Text="*"></asp:Label>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:RadioButton ID="radiobtn1" runat="server" Checked="true" Text="Day" OnCheckedChanged="radiobtn1_CheckedChanged" AutoPostBack="true" GroupName="led_status"></asp:RadioButton>
                                                    <asp:RadioButton ID="radiobtn3" runat="server" Text="Hour" OnCheckedChanged="radiobtn3_CheckedChanged" AutoPostBack="true" GroupName="led_status"></asp:RadioButton>
                                                    <asp:RadioButton ID="radiobtn2" runat="server" Text="Slot" OnCheckedChanged="radiobtn2_CheckedChanged" AutoPostBack="true" GroupName="led_status"></asp:RadioButton>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:Label ID="Label7" runat="server" Text=" Description"></asp:Label>
                                                    <asp:Label ID="Label8" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>
                                                </div>

                                                <div class="col-sm-3">
                                                    <asp:TextBox ID="txt_desc" CssClass="not-required" runat="server" Height="50px" placeholder="Enter Description" Width="200px" TextMode="MultiLine"></asp:TextBox>

                                                    <%--<asp:CalendarExtender ID="CalendarExtender1" runat="server" Enabled="True" TargetControlID="txt_valid_to" Format="dd/MM/yyyy"></asp:CalendarExtender>--%>
                                                </div>
                                            </div>
                                        </div>

                                        <asp:Panel ID="panel1" runat="server" Visible="false">
                                            <div class="form-group">
                                                <div class="row ">
                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label5" runat="server" Text="Start Time"></asp:Label>
                                                        <asp:Label ID="Label6" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_from" runat="server" Height="32px" Width="200px" TextMode="Time"></asp:TextBox>
                                                    </div>

                                                    <div class="col-sm-3">
                                                        <asp:Label ID="Label11" runat="server" Text="End Time"></asp:Label>
                                                        <asp:Label ID="Label12" runat="server" Font-Bold="True" Font-Size="Medium" Text=":"></asp:Label>

                                                    </div>
                                                    <div class="col-sm-3">
                                                        <asp:TextBox ID="txt_to" runat="server" Height="32px" Width="200px" TextMode="Time"></asp:TextBox>

                                                    </div>
                                                </div>
                                            </div>
                                            <div class="text-center">
                                                <asp:Button ID="btn_add" runat="server" Text="Add Slot" class="btn btn-primary" OnClick="btn_add_Click" />

                                            </div>
                                            <br />
                                        </asp:Panel>

                                        <div class="form-group">
                                            <div class="row ">
                                                <div class="col-sm-12">
                                                    <div style="width: 100%; overflow: auto;">
                                                        <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" AllowSorting="true" HeaderStyle-BackColor="lightblue" ShowHeaderWhenEmpty="true" OnRowDeleting="GridView2_RowDeleting" OnRowUpdating="GridView2_RowUpdating" EmptyDataText="No Record Found">

                                                            <%--                                            <asp:GridView ID="grid_cust" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped table-dark">--%>
                                                            <Columns>
                                                                <asp:TemplateField HeaderText="Slot" ItemStyle-Width="50">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="meet_id" ItemStyle-Width="200" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="slot_id" runat="server" Text='<%# Bind("slot_id")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="Start" ItemStyle-Width="400">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="start_time" runat="server" Text='<%# Bind("start_time")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField HeaderText="End" ItemStyle-Width="400">
                                                                    <ItemTemplate>
                                                                        <asp:Label ID="end_time" runat="server" Text='<%# Bind("end_time")%>'></asp:Label>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                                <asp:TemplateField ItemStyle-Width="50" Visible="false">
                                                                    <ItemTemplate>
                                                                        <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');">
                                                                            <img src="Images/delete_10781634.png" height="25" width="25" />
                                                                        </asp:LinkButton>
                                                                    </ItemTemplate>
                                                                </asp:TemplateField>
                                                            </Columns>
                                                        </asp:GridView>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>



                                    </div>


                                </ContentTemplate>
                                <Triggers>
                                    <asp:AsyncPostBackTrigger ControlID="GridView1" EventName="RowCommand" />
                                    <asp:AsyncPostBackTrigger ControlID="txt_facility" EventName="TextChanged" />

                                </Triggers>
                            </asp:UpdatePanel>

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
    <%--  --%>

<%--    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>--%>
    <script type="text/javascript">

        // Hardcoded suggestions array
        const suggestions = [
            "Swimming Pool", "Cricket terf", "Tennis cort", "GYM"
        ];

        const suggtxtSearch = document.getElementById('<%= txt_facility.ClientID %>');
        const suggsuggestionsBox = document.getElementById('suggsuggestionsBox');

        // Event listener for focus - show all suggestions
        suggtxtSearch.addEventListener('focus', function () {
            const searchTerm = this.value.trim().toLowerCase();

            if (searchTerm.length === 0) {
                // Show all suggestions when focused with empty input
                displaySuggestions(suggestions);
            } else {
                // Show filtered suggestions if there's already text
                const filtered = suggestions.filter(item =>
                    item.toLowerCase().includes(searchTerm)
                );
                displaySuggestions(filtered);
            }
        });

        // Event listener for input - filter suggestions
        suggtxtSearch.addEventListener('input', function () {
            const searchTerm = this.value.trim().toLowerCase();

            if (searchTerm.length === 0) {
                // Show all suggestions when input is cleared
                displaySuggestions(suggestions);
                return;
            }

            // Filter suggestions based on input
            const filtered = suggestions.filter(item =>
                item.toLowerCase().includes(searchTerm)
            );

            displaySuggestions(filtered);
        });

        // Display suggestions
        function displaySuggestions(items) {
            //if (items.length === 0) {
            //    suggsuggestionsBox.innerHTML = '<div class="suggno-results">No results found</div>';
            //    suggsuggestionsBox.style.display = 'block';
            //    return;
            //}

            let html = '';
            items.forEach(item => {
                html += `<div class="suggsuggestion-item" onclick="selectSuggestion('${item}')">${item}</div>`;
            });

            suggsuggestionsBox.innerHTML = html;
            suggsuggestionsBox.style.display = 'block';
        }

        // Select suggestion
        function selectSuggestion(value) {
            suggtxtSearch.value = value;
            suggsuggestionsBox.style.display = 'none';
        }

        // Close suggestions when clicking outside
        document.addEventListener('click', function (e) {
            if (!suggtxtSearch.contains(e.target) && !suggsuggestionsBox.contains(e.target)) {
                suggsuggestionsBox.style.display = 'none';
            }
        });

        // Handle keyboard navigation
        suggtxtSearch.addEventListener('keydown', function (e) {
            const items = suggsuggestionsBox.getElementsByClassName('suggsuggestion-item');

            if (items.length === 0) return;

            if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (items[0]) items[0].focus();
            } else if (e.key === 'Escape') {
                suggsuggestionsBox.style.display = 'none';
            }
        });
    </script>
</asp:Content>
