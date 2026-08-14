<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="agm_report.aspx.cs" Inherits="Society.agm_report" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Flatpickr CSS + JS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>

    <style>
        .year-box {
            width: 220px;
            padding: 8px 10px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
            text-align: center;
        }

        .financial-label {
            font-weight: 600;
            color: #012970;
            margin-top: 15px;
            display: block;
        }

        /* Hide months/days - show only year grid */
        .flatpickr-months, .flatpickr-weekdays, .flatpickr-days, .flatpickr-current-month {
            display: none !important;
        }

        .flatpickr-calendar {
            width: 250px !important;
            text-align: center;
        }

        .flatpickr-yearSelect-year {
            padding: 8px;
            cursor: pointer;
            border-radius: 4px;
        }

            .flatpickr-yearSelect-year:hover {
                background-color: #007bff;
                color: white;
            }
    </style>

    <h1 class="font-weight-bold" style="color: #012970;">AGM Report</h1>

    <div class="form-group mt-4">
        <label style="font-weight: 600;">Select Financial Year Range</label><br />

        <asp:TextBox
            ID="txtYearRange"
            runat="server"
            CssClass="year-box"
            placeholder="Select Year Range"
            AutoPostBack="true"
            OnTextChanged="txtYearRange_TextChanged" />

        <asp:Label
            ID="lblFinancialRange"
            runat="server"
            CssClass="financial-label"></asp:Label>
    </div>


    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped"
        AllowSorting="true" ShowHeaderWhenEmpty="true" EmptyDataText="No Record Found" HeaderStyle-BackColor="lightblue"
        AllowPaging="true"
        PageSize="10">
        <Columns>
            <asp:TemplateField HeaderText="No" ItemStyle-Width="30">
                <ItemTemplate>
                    <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="charges" HeaderText="Charges" />
            <asp:BoundField DataField="total" HeaderText="Amount" DataFormatString="₹{0:N2}" />
            <asp:BoundField DataField="gen_date" HeaderText="Bill Date" DataFormatString="{0:dd-MMM-yyyy}" />
        </Columns>
    </asp:GridView>

<%--    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const input = document.getElementById("<%= txtYearRange.ClientID %>");

            // Create a list of years manually
            const currentYear = new Date().getFullYear();
            const startYear = 2000;
            const endYear = 2100;

            input.addEventListener("focus", function () {
                // Build a custom popup
                const existingPopup = document.querySelector(".year-picker-popup");
                if (existingPopup) existingPopup.remove();

                const popup = document.createElement("div");
                popup.classList.add("year-picker-popup");
                popup.style.position = "absolute";
                popup.style.background = "#fff";
                popup.style.border = "1px solid #ccc";
                popup.style.borderRadius = "6px";
                popup.style.padding = "10px";
                popup.style.boxShadow = "0 2px 6px rgba(0,0,0,0.2)";
                popup.style.maxHeight = "200px";
                popup.style.overflowY = "auto";
                popup.style.zIndex = "9999";

                for (let y = endYear; y >= startYear; y--) {
                    const yearItem = document.createElement("div");
                    yearItem.classList.add("flatpickr-yearSelect-year");
                    yearItem.textContent = y;
                    popup.appendChild(yearItem);
                }

                // Handle year selection
                let selectedYears = [];

                popup.addEventListener("click", function (e) {
                    if (e.target.classList.contains("flatpickr-yearSelect-year")) {
                        const year = e.target.textContent;

                        if (selectedYears.length < 2) {
                            selectedYears.push(year);
                            e.target.style.backgroundColor = "#007bff";
                            e.target.style.color = "white";
                        }

                        if (selectedYears.length === 2) {
                            selectedYears.sort();
                            input.value = selectedYears.join(" - ");
                            popup.remove();
                            __doPostBack("<%= txtYearRange.UniqueID %>", "");
                        }
                    }
                });

                document.body.appendChild(popup);

                // Position below input
                const rect = input.getBoundingClientRect();
                popup.style.top = (rect.bottom + window.scrollY + 5) + "px";
                popup.style.left = (rect.left + window.scrollX) + "px";

                // Close on outside click
                document.addEventListener("click", function handleOutsideClick(event) {
                    if (!popup.contains(event.target) && event.target !== input) {
                        popup.remove();
                        document.removeEventListener("click", handleOutsideClick);
                    }
                });
            });
        });
    </script>--%>


<script>
    document.addEventListener("DOMContentLoaded", function () {
        const input = document.getElementById("<%= txtYearRange.ClientID %>");
    const currentYear = new Date().getFullYear();
    const startYear = 2000;
    const endYear = 2100;

    input.addEventListener("focus", function () {
        // Remove existing popup if any
        const existingPopup = document.querySelector(".year-picker-popup");
        if (existingPopup) existingPopup.remove();

        // Create popup container
        const popup = document.createElement("div");
        popup.classList.add("year-picker-popup");
        popup.style.cssText = `
            position: absolute;
            background: #fff;
            border: 1px solid #ccc;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 9999;
            min-width: 320px;
        `;

        // Add search input
        const searchInput = document.createElement("input");
        searchInput.type = "text";
        searchInput.placeholder = "Type year or use arrows...";
        searchInput.style.cssText = `
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            margin-bottom: 10px;
            font-size: 14px;
        `;

        // Add quick jump buttons
        const quickJump = document.createElement("div");
        quickJump.style.cssText = `
            display: flex;
            gap: 5px;
            margin-bottom: 10px;
            flex-wrap: wrap;
        `;
        
        const decades = [2000, 2010, 2020, 2030, 2040];
        decades.forEach(decade => {
            const btn = document.createElement("button");
            btn.textContent = `${decade}s`;
            btn.type = "button";
            btn.style.cssText = `
                padding: 4px 10px;
                border: 1px solid #007bff;
                background: #f0f8ff;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
            `;
            btn.addEventListener("click", function(e) {
                e.preventDefault();
                e.stopPropagation();
                yearList.scrollTop = 0;
                const targetYear = yearList.querySelector(`[data-year="${decade}"]`);
                if (targetYear) {
                    targetYear.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
            quickJump.appendChild(btn);
        });

        // Add year list container
        const yearList = document.createElement("div");
        yearList.style.cssText = `
            max-height: 250px;
            overflow-y: auto;
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 5px;
            padding: 5px;
        `;

        // Populate years and track 2030 position
        let year2030Element = null;
        for (let y = endYear; y >= startYear; y--) {
            const yearItem = document.createElement("div");
            yearItem.classList.add("year-item");
            yearItem.setAttribute("data-year", y);
            yearItem.textContent = y;
            yearItem.style.cssText = `
                padding: 8px;
                text-align: center;
                cursor: pointer;
                border-radius: 4px;
                border: 1px solid #e0e0e0;
                background: #fafafa;
                font-size: 13px;
                transition: all 0.2s;
            `;
            
            if (y === currentYear) {
                yearItem.style.border = "2px solid #007bff";
                yearItem.style.fontWeight = "bold";
            }

            // Track 2030 element for auto-scroll
            if (y === 2030) {
                year2030Element = yearItem;
            }

            yearItem.addEventListener("mouseenter", function() {
                if (!this.classList.contains("selected")) {
                    this.style.background = "#e3f2fd";
                }
            });

            yearItem.addEventListener("mouseleave", function() {
                if (!this.classList.contains("selected")) {
                    this.style.background = "#fafafa";
                }
            });

            yearList.appendChild(yearItem);
        }

        // Assemble popup
        popup.appendChild(searchInput);
        popup.appendChild(quickJump);
        popup.appendChild(yearList);

        // Handle year selection
        let selectedYears = [];

        yearList.addEventListener("click", function (e) {
            if (e.target.classList.contains("year-item")) {
                const year = e.target.getAttribute("data-year");

                if (selectedYears.length < 2) {
                    selectedYears.push(year);
                    e.target.classList.add("selected");
                    e.target.style.backgroundColor = "#007bff";
                    e.target.style.color = "white";
                    e.target.style.border = "1px solid #0056b3";
                }

                if (selectedYears.length === 2) {
                    selectedYears.sort();
                    input.value = selectedYears.join(" - ");
                    popup.remove();
                    __doPostBack("<%= txtYearRange.UniqueID %>", "");
                }
            }
        });

        // Search functionality
        searchInput.addEventListener("input", function () {
            const searchTerm = this.value.trim();
            const yearItems = yearList.querySelectorAll(".year-item");

            if (searchTerm === "") {
                yearItems.forEach(item => item.style.display = "block");
                return;
            }

            yearItems.forEach(item => {
                const year = item.getAttribute("data-year");
                if (year.includes(searchTerm)) {
                    item.style.display = "block";
                    // Scroll first match into view
                    if (item === yearList.querySelector(`.year-item[data-year*="${searchTerm}"]`)) {
                        item.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                    }
                } else {
                    item.style.display = "none";
                }
            });
        });

        // Prevent popup from closing when clicking inside
        popup.addEventListener("click", function (e) {
            e.stopPropagation();
        });

        document.body.appendChild(popup);

        // Position below input
        const rect = input.getBoundingClientRect();
        popup.style.top = (rect.bottom + window.scrollY + 5) + "px";
        popup.style.left = (rect.left + window.scrollX) + "px";

        // Auto-focus search input and scroll to 2030s
        setTimeout(() => {
            searchInput.focus();
            if (year2030Element) {
                year2030Element.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);

        // Close on outside click
        document.addEventListener("click", function handleOutsideClick(event) {
            if (!popup.contains(event.target) && event.target !== input) {
                popup.remove();
                document.removeEventListener("click", handleOutsideClick);
            }
        });

        // Close on Escape key
        document.addEventListener("keydown", function handleEscape(event) {
            if (event.key === "Escape") {
                popup.remove();
                document.removeEventListener("keydown", handleEscape);
            }
        });
    });
});
</script>
</asp:Content>
