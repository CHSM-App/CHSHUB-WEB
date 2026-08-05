<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="recent_activity.aspx.cs" Inherits="Society.recent_activity" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxtoolkit" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <!-- External Libraries -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css" />
    <link href="https://cdn.jsdelivr.net/npm/nouislider@15.7.0/dist/nouislider.min.css" rel="stylesheet" />

    <style>
        .filter-container {
            position: relative;
        }

        #filterSidebar {
            position: absolute;
            top: 40px;
            left: 0;
            width: 280px;
            background-color: #f8f9fa;
            box-shadow: 0 0 5px rgba(0,0,0,0.2);
            z-index: 10;
            padding: 20px;
            display: none;
            border-radius: 4px;
        }

            #filterSidebar.show {
                display: block;
            }

        .filter-chip {
            margin: 4px;
            padding: 2px 4px;
            font-size: 13px;
            background-color: #17a2b8;
            color: white;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
        }

            .filter-chip button {
                background: none;
                border: none;
                color: white;
                margin-left: 6px;
                cursor: pointer;
                font-weight: bold;
            }

        #priceSlider {
            margin-top: 10px;
        }

        #priceRangeDisplay {
            font-size: 14px;
            margin-top: 4px;
        }
    </style>
    <asp:HiddenField ID="HiddenField1" runat="server" />
    <asp:HiddenField ID="HiddenField2" runat="server" />
    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <h1 class="font-weight-bold" style="color: #012970;">Recent Activities</h1>
                <br />


                <%--         <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                    <ContentTemplate>--%>

                <!-- Filter Container -->
                <div class="form-group filter-container">
                    <div class="form-group">
                        <div class="row">
                            <div class="col-12">
                                <div class="d-flex align-items-center">
                                    <button id="filterButton" type="button" style="margin-right: 8px; border-radius: 12px; border: 1px solid #ccc; display:none">
                                        <img style="width: 28px; margin: 5px;" src="img/filter.svg" />
                                    </button>

                                    <div class="search-container">

                                        <asp:TextBox
                                            ID="txt_search"
                                            CssClass="aspNetTextBox"
                                            placeHolder="Search here"
                                            runat="server"
                                            TextMode="Search"
                                            AutoPostBack="true"
                                              onkeyup="filterTable()"/>

                                        <!-- Calendar and Search Buttons -->
                                        <div class="input-buttons">
                                            <button
                                                id="btn_search"
                                                type="submit"
                                                class="search-button2"
                                                runat="server"
                                                onkeyup="filterTable()">
                                                <span class="material-symbols-outlined">search</span>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Filter Sidebar -->
                    <div id="filterSidebar">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <h6>Filter Options</h6>
                            <button class="btn btn-sm btn-danger" onclick="toggleFilterPanel()">×</button>
                        </div>

                        <!-- Date Filter -->
                        <div class="form-group">
                            <label>Date Range</label>
                            <asp:TextBox ID="calendarRange" runat="server" CssClass="form-control" placeholder="Select date range" />
                            <asp:HiddenField ID="dateFrom" runat="server" />
                            <asp:HiddenField ID="dateTo" runat="server" />
                        </div>

                        <!-- Activity Type -->
                        <div class="form-group">
                            <label>Activity Type</label>
                            <asp:DropDownList ID="activityType" runat="server" CssClass="form-control" AutoPostBack="false">
                                <asp:ListItem Text="All" Value="0" />
                                <asp:ListItem Text="Maintenance" Value="Maintenance" />
                                <asp:ListItem Text="Payment" Value="Payment" />
                            </asp:DropDownList>
                        </div>

                        <!-- Price Range -->
                        <div class="form-group">
                            <label>Price Range</label>
                            <div id="priceSlider"></div>
                            <div id="priceRangeDisplay">₹0 – ₹5000</div>
                            <asp:HiddenField ID="minPriceHidden" runat="server" />
                            <asp:HiddenField ID="maxPriceHidden" runat="server" />
                            <asp:HiddenField ID="selectedMinPriceHidden" runat="server" />
                            <asp:HiddenField ID="selectedMaxPriceHidden" runat="server" />

                        </div>
                        <asp:UpdatePanel ID="UpdatePanel2" runat="server">
                            <ContentTemplate>

                                <!-- Buttons -->
                                <div class="mb-2">
                                    <asp:Button ID="btnResetFilters" runat="server" Text="Reset"
                                        CssClass="btn btn-secondary btn-sm"
                                        OnClientClick="resetFilters(); return false;" />

                                    <asp:Button ID="btnApplyFilters" runat="server" Text="Apply Filter"
                                        CssClass="btn btn-primary btn-sm"
                                        OnClick="btnApplyFilters_Click"
                                        UseSubmitBehavior="false" />
                                </div>

                                <!-- Filter Chips -->
                                <div id="Div1" runat="server" class="chips-container"></div>

                                <!-- GridView -->
                                <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false"
                                    CssClass="table table-bordered table-hover table-striped" ShowHeaderWhenEmpty="true"
                                    EmptyDataText="No Record Found">
                                    <Columns>
                                        <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                            <ItemTemplate>
                                                <%# Container.DataItemIndex + 1 %>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="date" HeaderText="Date" />
                                        <asp:BoundField DataField="particular" HeaderText="Name" />
                                        <asp:BoundField DataField="received_amt" HeaderText="Amount" />
                                    </Columns>
                                </asp:GridView>

                            </ContentTemplate>
                        </asp:UpdatePanel>


                    </div>
                </div>

                <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                    <ContentTemplate>

                        <!-- Filter Chips -->
                        <div id="filterChips" runat="server" class="chips-container"></div>

                        <!-- GridView -->
                        <div class="table-conteiner">
                            <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false"
                                CssClass="table table-bordered table-hover table-striped" ShowHeaderWhenEmpty="true"
                                EmptyDataText="No Record Found">
                                <Columns>
                                    <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                                        <ItemTemplate>
                                            <%# Container.DataItemIndex + 1 %>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:BoundField DataField="timestamp" HeaderText="Date" />
                                    <asp:BoundField DataField="particular" HeaderText="Name" />
                                    <asp:BoundField DataField="paid_amount" HeaderText="Amount" />
                                </Columns>
                            </asp:GridView>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnApplyFilters" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="txt_search" EventName="TextChanged" />
                    </Triggers>
                </asp:UpdatePanel>


                <%--                </ContentTemplate>

                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="txt_search" EventName="TextChanged" />
                        <asp:AsyncPostBackTrigger ControlID="btnApplyFilters" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>--%>
            </div>
        </div>
    </div>


    <!-- JS Libraries -->
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://cdn.jsdelivr.net/npm/nouislider@15.7.0/dist/nouislider.min.js"></script>

    <script>
        // Filter Sidebar toggle
        document.getElementById("filterButton").addEventListener("click", () => {
            document.getElementById("filterSidebar").classList.toggle("show");
        });

        function toggleFilterPanel() {
            document.getElementById("filterSidebar").classList.remove("show");
        }

        document.addEventListener("click", function (e) {
            const sidebar = document.getElementById("filterSidebar");
            const button = document.getElementById("filterButton");
            if (!sidebar.contains(e.target) && !button.contains(e.target)) {
                sidebar.classList.remove("show");
            }
        });

        // Flatpickr
        flatpickr("#<%= calendarRange.ClientID %>", {
            mode: "range",
            dateFormat: "Y-m-d", // Keep format as YYYY-MM-DD
            onChange: function (selectedDates) {
                if (selectedDates.length === 2) {
                    const fromDate = selectedDates[0].toLocaleDateString('en-CA'); // YYYY-MM-DD
                    const toDate = selectedDates[1].toLocaleDateString('en-CA');   // YYYY-MM-DD

                    document.getElementById("<%= dateFrom.ClientID %>").value = fromDate;
                        document.getElementById("<%= dateTo.ClientID %>").value = toDate;
                    }
                }
            });


        window.addEventListener("load", function () {
            const priceSlider = document.getElementById("priceSlider");

            const minFromServer = parseInt(document.getElementById("<%= minPriceHidden.ClientID %>").value) || 0;
                const maxFromServer = parseInt(document.getElementById("<%= maxPriceHidden.ClientID %>").value) || 50000;

                const selectedMinHidden = document.getElementById("<%= selectedMinPriceHidden.ClientID %>");
                const selectedMaxHidden = document.getElementById("<%= selectedMaxPriceHidden.ClientID %>");

                noUiSlider.create(priceSlider, {
                    start: [minFromServer, maxFromServer],
                    connect: true,
                    range: { min: minFromServer, max: maxFromServer },
                    step: 100,
                    tooltips: [true, true],
                    format: {
                        to: value => Math.round(value),
                        from: value => Number(value)
                    }
                });

                // Set selected values to hidden fields on slider change
                priceSlider.noUiSlider.on('update', function (values, handle) {
                    selectedMinHidden.value = Math.round(values[0]);
                    selectedMaxHidden.value = Math.round(values[1]);
                });
            });


        // Apply Filter Logic  z
        function applyFilter() {
            const fromDate = document.getElementById("<%= dateFrom.ClientID %>").value;
                const toDate = document.getElementById("<%= dateTo.ClientID %>").value;
                const type = document.getElementById("<%= activityType.ClientID %>").value;

            let chipsHTML = "";

            if (fromDate || toDate) {
                chipsHTML += `<span class="filter-chip" id="chip-date">📅 ${fromDate || '...'} – ${toDate || '...'} <button onclick="removeFilter('date')">×</button></span>`;
            }
            if (type) {
                chipsHTML += `<span class="filter-chip" id="chip-type">🛠️ Type: ${type} <button onclick="removeFilter('type')">×</button></span>`;
            }
            if (minPrice || maxPrice) {
                chipsHTML += `<span class="filter-chip" id="chip-price">💰 ₹${minPrice} – ₹${maxPrice} <button onclick="removeFilter('price')">×</button></span>`;
            }

            document.getElementById("filterChips").innerHTML = chipsHTML;
            toggleFilterPanel();
        }

        function resetFilters() {
            const minFromServer = parseInt(document.getElementById("<%= minPriceHidden.ClientID %>").value) || 0;
                const maxFromServer = parseInt(document.getElementById("<%= maxPriceHidden.ClientID %>").value) || 50000;

                document.getElementById("<%= dateFrom.ClientID %>").value = '';
                document.getElementById("<%= dateTo.ClientID %>").value = '';
                document.getElementById("<%= calendarRange.ClientID %>").value = '';
                document.getElementById("<%= activityType.ClientID %>").value = 'All';
            document.getElementById("filterChips").innerHTML = '';
            priceSlider.noUiSlider.set([minFromServer, maxFromServer]);
        }

        function removeFilter(type) {
            if (type === 'date') {
                document.getElementById("<%= dateFrom.ClientID %>").value = '';
                    document.getElementById("<%= dateTo.ClientID %>").value = '';
                    document.getElementById("<%= calendarRange.ClientID %>").value = '';
                }
                if (type === 'type') {
                    document.getElementById("<%= activityType.ClientID %>").value = '';
                }
                if (type === 'price') {
                    priceSlider.noUiSlider.set([0, 5000]);
                    document.getElementById("<%= selectedMaxPriceHidden.ClientID %>").value = '';
                    document.getElementById("<%= selectedMinPriceHidden.ClientID %>").value = '';
                }

                // Trigger the same Apply Filters button click via JavaScript
                __doPostBack('<%= btnApplyFilters.UniqueID %>', '');
        }



        function filterTable() {
            const input = document.getElementById('<%= txt_search.ClientID %>');
            if (!input) return;

            const filter = input.value.toLowerCase();
            const table = document.querySelector('.table-conteiner table');

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
</asp:Content>
