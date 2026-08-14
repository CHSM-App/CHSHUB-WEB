<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Admin_Dashboard.aspx.cs" Inherits="Society2024.Admin_Dashboard" MasterPageFile="~/Site.Master" %>


<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&icon_names=search" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css" />
    <link href="https://cdn.jsdelivr.net/npm/nouislider@15.7.0/dist/nouislider.min.css" rel="stylesheet" />
    <style>
        .resized-model {
            width: 529px;
            height: auto;
            right: 82px;
        }

        @media(max-width: 431px) {
            .resized-model {
                height: auto;
                margin: auto;
                width: 233px;
                margin-top: 168px;
                right: 1px;
            }
        }

        .filter-container {
            position: relative;
        }

        #filterSidebar {
    position: absolute;
    top: 132px;
    left: 13px;
    width: 331px;
    background-color: #f8f9fa;
    box-shadow: 0 0 5px rgba(0, 0, 0, 0.2);
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
            padding: 4px 6px;
            font-size: 13px;
            background-color: #17a2b8;
            color: white;
            border-radius: 16px;
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
    <script type="text/javascript">
        function SuccessEntry() {
            Swal.fire(
                'SUCCESS!',
                'Quotation Entry Successfully Registered!',
                'success'
            )
        }
        function Fail() {
            Swal.fire({
                icon: 'error',
                title: 'Oops...',
                text: 'You Missed Something Empty!',
            })
        }
    </script>

    <script type='text/javascript'>
        function openModal() {
            $('#edit_model').modal('show');
        }
    </script>

    <div class="box box-primary">
        <div class="box-header with-border">
            <div class="box-body">
                <table width="100%">
                    <tr>
                        <th width="100%">
                            <h1 class=" font-weight-bold " style="color: #012970;">Admin Dashboard</h1>
                        </th>
                    </tr>
                </table>
                <br />


                <div class="form-group">
                    <div class="row">
                        <div class="col-12">
                            <div class="d-flex align-items-center">
                                <button id="filterButton" type="button" style="margin-right: 8px; border-radius: 12px; border: 1px solid #ccc;">
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
                                        OnTextChanged="btn_search_Click"
                                        onkeyup="removeFocusAfterTyping()" />

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
                    <div class="row">
                        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <asp:HiddenField ID="HiddenField4" runat="server" />
                                <asp:HiddenField ID="society_id" runat="server" />
                                <asp:HiddenField ID="state" runat="server" />
                                <asp:HiddenField ID="dist" runat="server" />
                                <asp:HiddenField ID="city" runat="server" />
                                <div class="row">
                                    <div class="col-6">
                                        <div class="form-group">
                                            <label>State</label>
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox1" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" autocomplete="off" required="required" />
                                                <div id="RepeaterContainer1" class="suggestion-list">
                                                    <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                        <ItemTemplate>

                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("state") %>'
                                                                CommandArgument='<%# Eval("state_id") %>'
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

                                    <div class="col-6">
                                        <div class="form-group">
                                            <label>District</label>
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox2" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" autocomplete="off" required="required" />
                                                <div id="RepeaterContainer2" class="suggestion-list">
                                                    <asp:Repeater ID="Repeater2" runat="server" OnItemCommand="CategoryRepeater_ItemCommand2">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("district") %>'
                                                                CommandArgument='<%# Eval("district_id") %>'
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
                                <div class="row">
                                    <div class="col-6">
                                        <div class="form-group">

                                            <label>City</label>
                                            <div class="dropdown-container">
                                                <asp:TextBox ID="TextBox3" runat="server" CssClass="input-box form-control"
                                                    placeholder="Select" autocomplete="off" required="required" />
                                                <div id="RepeaterContainer3" class="suggestion-list">
                                                    <asp:Repeater ID="Repeater3" runat="server" OnItemCommand="CategoryRepeater_ItemCommand3">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item link-button category-link"
                                                                Text='<%# Eval("city") %>'
                                                                CommandArgument='society_id.value'
                                                                CommandName="SelectCategory"
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

                                    <div class="col-6">
                                        <div class="form-group">
                                            <label>Pin Code</label>
                                            <asp:TextBox ID="TextBox4" runat="server" CssClass="form-control" placeholder="Enter Pin Code" />
                                        </div>
                                    </div>
                                </div>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                        <!-- Date Filter -->
                        <div class="form-group">
                            <label>Date Range</label>
                            <asp:TextBox ID="calendarRange" runat="server" CssClass="form-control" placeholder="Select date range" />
                            <asp:HiddenField ID="dateFrom" runat="server" />
                            <asp:HiddenField ID="dateTo" runat="server" />
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

                        <asp:Button ID="btnResetFilters" runat="server" Text="Reset" CssClass="btn btn-secondary btn-sm mt-2" OnClientClick="resetFilters(); return false;" />
                        <asp:Button ID="btnApplyFilters" runat="server" Text="Apply Filter"
                            CssClass="btn btn-primary btn-sm mt-2"
                            OnClick="btnApplyFilters_Click" />

                    </div>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div id="filterChips" runat="server" class="chips-container"></div>

                        <div class="form-group">
                            <div class="row ">
                                <div class="col-sm-12">
                                    <div style="width: 100%; overflow: auto;">
                                        <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" EmptyDataText="No Record Found" ShowHeaderWhenEmpty="true" HeaderStyle-BackColor="lightblue" AllowSorting="true" OnSorting="GridView1_Sorting" OnRowUpdating="GridView1_RowUpdating">

                                            <Columns>
                                                <asp:TemplateField HeaderText="No" ItemStyle-Width="100">
                                                    <ItemTemplate>
                                                        <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Society Name" ItemStyle-Width="400" SortExpression="name">
                                                    <ItemTemplate>
                                                        <asp:Label ID="society_name" runat="server" Text='<%# Bind("name")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Address" ItemStyle-Width="400" SortExpression="address">
                                                    <ItemTemplate>
                                                        <asp:Label ID="address" runat="server" Text='<%# Eval("address") %>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Total Flats" ItemStyle-Width="150" SortExpression="total_flats">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label6" runat="server" Text='<%# Bind("total_unit")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Point of Contact" ItemStyle-Width="400" SortExpression="contact_no1">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label7" runat="server" Text='<%# Bind("contact_no1")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Email Address" ItemStyle-Width="150" SortExpression="email">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label8" runat="server" Text='<%# Bind("email")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>

                                                <asp:TemplateField HeaderText="Charges Per Month" ItemStyle-Width="150" SortExpression="chargesPerMonth">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label10" runat="server" Text='<%# Bind("chargesPerUnit")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Pending Amount" ItemStyle-Width="150" SortExpression="pending_amount">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label10" runat="server" Text='<%# Bind("amount")%>'></asp:Label>
                                                    </ItemTemplate>
                                                </asp:TemplateField>
                                                <asp:TemplateField HeaderText="Pending Month" ItemStyle-Width="150" SortExpression="month">
                                                    <ItemTemplate>
                                                        <asp:Label ID="Label10" runat="server" Text='<%# Bind("month")%>'></asp:Label>
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
                        <asp:AsyncPostBackTrigger ControlID="btnApplyFilters" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="txt_search" EventName="TextChanged" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>
        </div>
    </div>


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
    const filterPanel = document.getElementById("filterSection"); // The filter panel

    // Ensure that the sidebar doesn't close when interacting inside the filter panel
    if (!sidebar.contains(e.target) && !button.contains(e.target) && !filterPanel.contains(e.target)) {
        sidebar.classList.remove("show");
    }
});


        // Flatpickr
        flatpickr("#<%= calendarRange.ClientID %>", {
            mode: "range",
            dateFormat: "Y-m-d",
            onChange: function (selectedDates) {
                if (selectedDates.length === 2) {
                    document.getElementById("<%= dateFrom.ClientID %>").value = selectedDates[0].toISOString().split("T")[0];
                    document.getElementById("<%= dateTo.ClientID %>").value = selectedDates[1].toISOString().split("T")[0];
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
            const state = document.getElementById("<%= TextBox1.ClientID %>").value;
            const district = document.getElementById("<%= TextBox2.ClientID %>").value;
            const city = document.getElementById("<%= TextBox3.ClientID %>").value;
            let chipsHTML = "";

            if (fromDate || toDate) {
                chipsHTML += `<span class="filter-chip" id="chip-date">📅 ${fromDate || '...'} – ${toDate || '...'} <button onclick="removeFilter('date')">×</button></span>`;
            }
            if (state) {
                chipsHTML += `<span class="filter-chip" id="chip-type">🛠️ State: ${state} <button onclick="removeFilter('state')">×</button></span>`;
            }
             if (district) {
                chipsHTML += `<span class="filter-chip" id="chip-type">🛠️ District: ${district} <button onclick="removeFilter('district')">×</button></span>`;
            }
            if (city) {
                chipsHTML += `<span class="filter-chip" id="chip-type">🛠️ city: ${city} <button onclick="removeFilter('city')">×</button></span>`;
            }
            if (minPrice || maxPrice) {
                chipsHTML += `<span class="filter-chip" id="chip-price">💰 ₹${minPrice} – ₹${maxPrice} <button onclick="removeFilter('price')">×</button></span>`;
            }

            document.getElementById("filterChips").innerHTML = chipsHTML;
            toggleFilterPanel();
        }

        function resetFilters() {
            document.getElementById("<%= dateFrom.ClientID %>").value = '';
            document.getElementById("<%= dateTo.ClientID %>").value = '';
            document.getElementById("<%= TextBox1.ClientID %>").value = '';
            document.getElementById("<%= TextBox2.ClientID %>").value = '';
            document.getElementById("<%= TextBox3.ClientID %>").value = '';
            document.getElementById("<%= TextBox4.ClientID %>").value = '';
            document.getElementById("filterChips").innerHTML = '';
            priceSlider.noUiSlider.set([0, 5000]);
        }

        function removeFilter(type) {
            if (type === 'date') {
                document.getElementById("<%= dateFrom.ClientID %>").value = '';
                document.getElementById("<%= dateTo.ClientID %>").value = '';
                document.getElementById("<%= calendarRange.ClientID %>").value = '';
            }
            if (type === 'price') {
                priceSlider.noUiSlider.set([0, 5000]);
                document.getElementById("<%= selectedMinPriceHidden.ClientID %>").value = '';
                document.getElementById("<%= selectedMaxPriceHidden.ClientID %>").value = '';
            }

            if(type ==='state'){
               document.getElementById("<%= TextBox1.ClientID %>").value = '';
            }

            
            if(type ==='dist'){
               document.getElementById("<%= TextBox2.ClientID %>").value = '';
            }

            
            if(type ==='city'){
               document.getElementById("<%= TextBox3.ClientID %>").value = '';
            }

            
            if(type ==='pin'){
               document.getElementById("<%= TextBox4.ClientID %>").value = '';
            }
            // Trigger the same Apply Filters button click via JavaScript
            __doPostBack('<%= btnApplyFilters.UniqueID %>', '');
        }

    </script>

    <script>

        function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");

            textBox1.addEventListener("focus", function () {
                repeaterContainer1.style.display = "block";
                repeaterContainer2.style.display = "none";
                repeaterContainer3.style.display = "none";
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

            const textBox3 = document.getElementById("<%= TextBox3.ClientID %>");
            const repeaterContainer3 = document.getElementById("RepeaterContainer3");

            textBox3.addEventListener("focus", function () {
                repeaterContainer3.style.display = "block";
            });

            textBox3.addEventListener("input", function () {
                const input = textBox3.value.toLowerCase();
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
            document.getElementById("<%= TextBox2.ClientID %>").value = "";
            document.getElementById("<%= TextBox3.ClientID %>").value = "";
        }

        function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            document.getElementById("RepeaterContainer2").style.display = "none";
            document.getElementById("<%= TextBox3.ClientID %>").value = "";
        }

        function setTextBox3(value) {
            document.getElementById("<%= TextBox3.ClientID %>").value = value;
            document.getElementById("RepeaterContainer3").style.display = "none";
        }


        Sys.Application.add_load(initDropdownEvents);


    </script>

</asp:Content>
