<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ownerwise_maintenance.aspx.cs" Inherits="Society.ownerwise_maintenance" MasterPageFile="~/Site.Master" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">
    <!-- Add jsPDF library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>

    <style>
        /* GridView specific styling - Target the actual rendered table */
        table[id*="GridView1"] tbody tr:nth-child(2) td {
            background-color: #e8f5e9 !important; /* Light green for Opening Balance (2nd row) */
            font-weight: bold !important;
        }
        
        table[id*="GridView1"] tbody tr:nth-last-child(2) td {
            background-color: #e3f2fd !important; /* Light blue for Total Balance */
            font-weight: bold !important;
        }
        
        table[id*="GridView1"] tbody tr:last-child td {
            background-color: #fff3e0 !important; /* Light orange for Closing Balance */
            font-weight: bold !important;
        }
        
        /* Hover effects */
        table[id*="GridView1"] tbody tr:nth-child(2):hover td,
        table[id*="GridView1"] tbody tr:nth-last-child(2):hover td,
        table[id*="GridView1"] tbody tr:last-child:hover td {
            filter: brightness(0.93) !important;
        }

        /* Minimal Page Styling */
        .page-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .page-header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }

        .filter-section {
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
            margin-bottom: 25px;
        }

        .form-row {
            display: flex;
            gap: 15px;
            margin-bottom: 15px;
            flex-wrap: wrap;
        }

        .form-group-inline {
            display: flex;
            gap: 10px;
        }

        .form-group-inline label {
            margin: 0;
            white-space: nowrap;
            font-weight: 500;
            color: #333;
        }

        .form-control {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 8px 12px;
            font-size: 14px;
        }

        .form-control:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .button-group {
            display: flex;
            gap: 10px;
            justify-content: center;
            margin-top: 20px;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .btn-primary {
            background: #667eea;
            color: white;
        }

        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(102, 126, 234, 0.3);
        }

        .btn-danger {
            background: #f56565;
            color: white;
        }

        .btn-danger:hover {
            background: #e53e3e;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(245, 101, 101, 0.3);
        }

        .grid-container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
            overflow: auto;
        }

        .table {
            border-collapse: collapse;
            width: 100%;
        }

        .table thead th {
            background-color: #667eea !important;
            color: white !important;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }

        .table tbody td {
            padding: 10px 12px;
            border-bottom: 1px solid #e2e8f0;
        }

        .table-striped tbody tr:nth-of-type(odd):not(:nth-of-type(2)):not(:nth-last-of-type(2)):not(:last-of-type) {
            background-color: #f7fafc;
        }

        /* Dropdown styling */
        .dropdown-container {
            position: relative;
        }

        .suggestion-list {
            display: none;
            position: absolute;
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-top: 2px;
            width: 100%;
        }

        .suggestion-item {
            display: block;
            padding: 10px 15px;
            color: #333;
            text-decoration: none;
            border-bottom: 1px solid #f0f0f0;
        }

        .suggestion-item:hover {
            background-color: #f0f4ff;
            color: #667eea;
        }

        .suggestion-item:last-child {
            border-bottom: none;
        }
    </style>

    <table width="100%">
        <tr>
            <th width="100%" class="">
                <h1 class=" tex0 font-weight-bold " style="color: #012970;">Owner wise Maintenance Bill Reports
                </h1>
            </th>
        </tr>
    </table>
    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
            <asp:HiddenField runat="server" ID="build_id" />
            <asp:HiddenField runat="server" ID="owner_id" />

            <div class="filter-section">
                <div class="form-row">
                    <div class="form-group-inline">
                        <asp:Label ID="Label1" runat="server" Text="Building Name:"></asp:Label>
                        <div class="dropdown-container">
                            <asp:TextBox ID="TextBox1" runat="server" CssClass="form-control"
                                placeholder="Select Building" autocomplete="off" Width="200px" AutoCompleteType="Disabled" />
                            <div id="RepeaterContainer1" class="suggestion-list">
                                <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1">
                                    <ItemTemplate>
                                        <asp:LinkButton
                                            ID="lnkCategory"
                                            runat="server"
                                            CssClass="suggestion-item category-link"
                                            Text='<%# Eval("name") %>'
                                            CommandArgument='<%# Eval("build_id") %>'
                                            CommandName="SelectCategory"
                                            OnClientClick="setTextBox1(this.innerText);" />
                                    </ItemTemplate>
                                    <FooterTemplate>
                                        <asp:Literal ID="litNoItem" runat="server"
                                            Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                            Text="<div class='suggestion-item'>No items found.</div>" />
                                    </FooterTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>

                    <div class="form-group-inline">
                        <asp:Label ID="Label2" runat="server" Text="Owner Name:"></asp:Label>
                        <div class="dropdown-container">
                            <asp:TextBox ID="TextBox2" runat="server" CssClass="form-control"
                                placeholder="Select Owner" autocomplete="off" Width="200px"  AutoCompleteType="Disabled"  />
                            <div id="RepeaterContainer2" class="suggestion-list">
                                <asp:Repeater ID="Repeater2" runat="server" OnItemCommand="CategoryRepeater_ItemCommand2">
                                    <ItemTemplate>
                                        <asp:LinkButton
                                            ID="lnkCategory"
                                            runat="server"
                                            CssClass="suggestion-item category-link"
                                            Text='<%# Eval("name") %>'
                                            CommandArgument='<%# Eval("owner_id") %>'
                                            CommandName="SelectCategory"
                                            OnClientClick="setTextBox2(this.innerText);" />
                                    </ItemTemplate>
                                    <FooterTemplate>
                                        <asp:Literal ID="litNoItem" runat="server" 
                                            Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'
                                            Text="<div class='suggestion-item'>No items found.</div>" />
                                    </FooterTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>


                    <div class="form-group-inline">
                        <asp:Label ID="lbl_date" runat="server" Text="From Date:"></asp:Label>
                        <asp:TextBox ID="txt_from" TextMode="Date" runat="server" CssClass="form-control" Width="150px"></asp:TextBox>
                    </div>

                    <div class="form-group-inline">
                        <asp:Label ID="Label12" runat="server" Text="To Date:"></asp:Label>
                        <asp:TextBox ID="txt_to" TextMode="Date" runat="server" CssClass="form-control" Width="150px"></asp:TextBox>
                    </div>
                </div>

                <div class="button-group">
                    <asp:Button ID="btn_search" runat="server" CssClass="btn btn-primary" 
                        OnClick="btn_search_Click" Text="Search" UseSubmitBehavior="False" ValidationGroup="g1" />
                    <asp:Button ID="btn_print" runat="server" CssClass="btn btn-primary" 
                        OnClick="btn_print_Click" Text="Print" OnClientClick="printData()" UseSubmitBehavior="False" ValidationGroup="g1" />
                    <button type="button" class="btn btn-danger" onclick="downloadPDF(); return false;">Download PDF</button>
                </div>
            </div>

            <asp:Panel ID="Panel1" runat="server" Visible="false">
                <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="100%"></rsweb:ReportViewer>
            </asp:Panel>

            <div class="grid-container" id="reportContainer">
                <asp:GridView ID="GridView1" runat="server" 
                    AutoGenerateColumns="false" 
                    CssClass="table table-bordered table-striped" 
                    ShowHeaderWhenEmpty="true" 
                    EmptyDataText="No Record Found"  
                    OnRowUpdating="GridView1_RowUpdating">
                    <Columns>
                        <asp:TemplateField HeaderText="Date">
                            <ItemTemplate>
                                <asp:Label ID="receipt_no" runat="server" Text='<%# Bind("Date","{0:dd-MM-yyyy}")%>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Particular">
                            <ItemTemplate>
                                <asp:Label ID="b_id" runat="server" Text='<%# Bind("Particular")%>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Transaction Ref">
                            <ItemTemplate>
                                <asp:Label ID="b_id1" runat="server" Text='<%# Bind("ref")%>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Maintenance">
                            <ItemTemplate>
                                <asp:Label ID="name1" runat="server" Text='<%# Bind("Maintenance")%>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Paid Maintenance">
                            <ItemTemplate>
                                <asp:Label ID="name" runat="server" Text='<%# Bind("Payment")%>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>

            <asp:Label runat="server" ID="lbl_owner_id" Visible="false"></asp:Label>
        </ContentTemplate>
    </asp:UpdatePanel>

    <script>
        function printData() {
            try {
                // Get filter values - using plain getElementById with the actual rendered IDs
                const buildingInput = document.querySelector('input[id*="TextBox1"]');
                const ownerInput = document.querySelector('input[id*="TextBox2"]');
                const fromDateInput = document.querySelector('input[id*="txt_from"]');
                const toDateInput = document.querySelector('input[id*="txt_to"]');

                const buildingName = buildingInput ? buildingInput.value : 'N/A';
                const ownerName = ownerInput ? ownerInput.value : 'N/A';
                const fromDate = fromDateInput ? fromDateInput.value : 'N/A';
                const toDate = toDateInput ? toDateInput.value : 'N/A';

                // Find the GridView table
                let table = document.querySelector('table[id*="GridView1"]');

                if (!table) {
                    alert("No data found to print. Please search for data first.");
                    return false;
                }

                // Clone the table to preserve original
                const tableClone = table.cloneNode(true);

                // Open print window first
                const printWindow = window.open('', '_blank', 'width=800,height=600');

                if (!printWindow) {
                    alert("Please allow pop-ups to print the report.");
                    return false;
                }

                // Write the document structure
                printWindow.document.open();
                printWindow.document.write('<!DOCTYPE html>');
                printWindow.document.write('<html><head>');
                printWindow.document.write('<title>Ownerwise Maintenance Bill Report</title>');
                printWindow.document.write('<style>');
                printWindow.document.write(`
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            @page {
                size: A4;
                margin: 15mm;
            }
            
            body {
                font-family: Arial, sans-serif;
                padding: 20px;
                background: white;
            }
            
            .report-header {
                text-align: center;
                margin-bottom: 25px;
                border-bottom: 2px solid #667eea;
                padding-bottom: 15px;
            }
            
            .report-header h1 {
                font-size: 22px;
                color: #333;
                font-weight: 600;
            }
            
            .filter-info {
                margin-bottom: 20px;
                padding: 12px;
                background-color: #f8f9fa;
                border-left: 4px solid #667eea;
            }
            
            .filter-info p {
                margin: 4px 0;
                font-size: 13px;
                color: #495057;
            }
            
            .filter-info strong {
                color: #212529;
                min-width: 120px;
                display: inline-block;
            }
            
            table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 15px;
            }
            
            table th {
                background-color: #667eea !important;
                color: white !important;
                padding: 10px 8px;
                text-align: left;
                font-weight: 600;
                font-size: 12px;
                border: 1px solid #5568d3;
            }
            
            table td {
                padding: 8px;
                border: 1px solid #dee2e6;
                font-size: 11px;
                color: #333;
            }
            
            table tr:nth-child(even) {
                background-color: #f8f9fa;
            }
            
            table tbody tr:nth-child(2) td {
                background-color: #e8f5e9 !important;
                font-weight: bold;
            }
            
            table tbody tr:nth-last-child(2) td {
                background-color: #e3f2fd !important;
                font-weight: bold;
            }
            
            table tbody tr:last-child td {
                background-color: #fff3e0 !important;
                font-weight: bold;
            }
            
            .footer {
                margin-top: 25px;
                text-align: center;
                font-size: 10px;
                color: #6c757d;
                border-top: 1px solid #dee2e6;
                padding-top: 10px;
            }
            
            @media print {
                body {
                    padding: 0;
                }
                .no-print {
                    display: none;
                }
            }
        `);
                printWindow.document.write('</style>');
                printWindow.document.write('</head><body>');

                // Write header
                printWindow.document.write('<div class="report-header">');
                printWindow.document.write('<h1>Ownerwise Maintenance Bill Report</h1>');
                printWindow.document.write('</div>');

                // Write filter info
                printWindow.document.write('<div class="filter-info">');
                printWindow.document.write('<p><strong>Building Name:</strong> ' + buildingName + '</p>');
                printWindow.document.write('<p><strong>Owner Name:</strong> ' + ownerName + '</p>');
                printWindow.document.write('<p><strong>Period:</strong> ' + fromDate + ' to ' + toDate + '</p>');
                printWindow.document.write('</div>');

                // Write table
                printWindow.document.write('<div class="table-container">');
                printWindow.document.write(tableClone.outerHTML);
                printWindow.document.write('</div>');

                // Write footer
                const currentDate = new Date().toLocaleString('en-IN', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
                printWindow.document.write('<div class="footer">');
                printWindow.document.write('<p>Generated on: ' + currentDate + '</p>');
                printWindow.document.write('</div>');

                printWindow.document.write('</body></html>');
                printWindow.document.close();

                // Wait for content to load then print
                printWindow.onload = function () {
                    printWindow.focus();
                    setTimeout(function () {
                        printWindow.print();
                    }, 250);
                };

                return false;

            } catch (error) {
                console.error("Print Error:", error);
                alert("Error printing report: " + error.message);
                return false;
            }
        }
    </script>

<script>




    function downloadPDF() {
        try {
            console.log("Starting PDF generation...");

            const { jsPDF } = window.jspdf;

            if (!jsPDF || !jsPDF.API.autoTable) {
                alert("jsPDF AutoTable plugin missing. PDF cannot be generated.");
                return;
            }

            const doc = new jsPDF('p', 'mm', 'a4');
            const margin = 15;

            // Identify the table
            let table =
                document.querySelector('table[id*="GridView1"]') ||
                document.querySelector('.grid-container table') ||
                document.querySelector('table.table');

            if (!table) {
                alert("No table found! Please search for data first.");
                return;
            }

            console.log("Table found:", table);

            // Extract filter inputs
            const buildingName = document.getElementById('<%= TextBox1.ClientID %>')?.value || 'N/A';
        const ownerName = document.getElementById('<%= TextBox2.ClientID %>')?.value || 'N/A';
        const fromDate = document.getElementById('<%= txt_from.ClientID %>')?.value || 'N/A';
        const toDate = document.getElementById('<%= txt_to.ClientID %>')?.value || 'N/A';

            // Page size
            const pageWidth = doc.internal.pageSize.getWidth();
            const pageHeight = doc.internal.pageSize.getHeight();

            let yPosition = margin;

            // TITLE
            doc.setFontSize(18);
            doc.setFont(undefined, 'bold');
            doc.text('Ownerwise Maintenance Bill Report', pageWidth / 2, yPosition, { align: 'center' });

            yPosition += 10;

            // FILTER INFO
            doc.setFontSize(10);
            doc.setFont(undefined, 'normal');
            doc.text(`Building: ${buildingName}`, margin, yPosition); yPosition += 6;
            doc.text(`Owner: ${ownerName}`, margin, yPosition); yPosition += 6;
            doc.text(`Period: ${fromDate} to ${toDate}`, margin, yPosition); yPosition += 10;

            /*
            ───────────────────────────────────────────
            Extract TABLE HEADERS
            ───────────────────────────────────────────
            */
            let headerCells = table.querySelectorAll("thead tr th");

            // Fallback if <thead> does not exist (GridView case)
            if (headerCells.length === 0) {
                console.warn("No <thead> found — using first <tr> for headers.");
                headerCells = table.querySelectorAll("tr th");
            }

            const headers = [];
            headerCells.forEach(cell => headers.push(cell.innerText.trim()));

            console.log("Headers extracted:", headers);


            /*
            ───────────────────────────────────────────
            Extract TABLE ROWS
            ───────────────────────────────────────────
            */
            let bodyRows = table.querySelectorAll("tbody tr");

            // Fallback if <tbody> not present (GridView case)
            if (bodyRows.length === 0) {
                console.warn("No <tbody> found — using all table <tr>.");
                bodyRows = table.querySelectorAll("tr");
            }

            const rows = [];

            bodyRows.forEach((row, index) => {
                const cells = row.querySelectorAll("td");

                if (cells.length === 0) return; // Skip header rows

                const rowData = [];

                cells.forEach(cell => {
                    let text = "";

                    // Extract from span/label if present
                    if (cell.querySelector("span")) {
                        text = cell.querySelector("span").innerText.trim();
                    }
                    else if (cell.querySelector("label")) {
                        text = cell.querySelector("label").innerText.trim();
                    }
                    else {
                        text = cell.innerText.trim();
                    }

                    rowData.push(text);
                });

                if (rowData.some(v => v.trim() !== "")) {
                    rows.push({ data: rowData });
                }
            });

            console.log("Total rows extracted:", rows.length);

            if (rows.length === 0) {
                alert("Table has no data. PDF generation cancelled.");
                return;
            }


            /*
            ───────────────────────────────────────────
            AUTO-TABLE RENDERING
            ───────────────────────────────────────────
            */
            doc.autoTable({
                head: [headers],
                body: rows.map(r => r.data),
                startY: yPosition,
                theme: 'grid',
                margin: { left: margin, right: margin },
                styles: {
                    fontSize: 9,
                    cellPadding: 4,
                    overflow: 'linebreak',
                    halign: 'left',
                    valign: 'middle'
                },
                headStyles: {
                    fillColor: [52, 73, 94],
                    textColor: 255,
                    fontStyle: 'bold'
                },
                alternateRowStyles: { fillColor: [245, 245, 245] },

                didDrawPage: function () {
                    const pageCount = doc.internal.getNumberOfPages();
                    const currentPage = doc.internal.getCurrentPageInfo().pageNumber;

                    doc.setFontSize(8);

                    // Page number
                    doc.text(
                        `Page ${currentPage} of ${pageCount}`,
                        pageWidth / 2,
                        pageHeight - 10,
                        { align: 'center' }
                    );

                    // Timestamp
                    doc.text(
                        "Generated: " + new Date().toLocaleString(),
                        margin,
                        pageHeight - 10
                    );
                }
            });

            // Save file
            const fileName =
                `Maintenance_Report_${ownerName.replace(/\s+/g, '_')}_${Date.now()}.pdf`;

            doc.save(fileName);

        } catch (error) {
            console.error("PDF Error:", error);
            alert("Error generating PDF: " + error.message);
        }
    }

</script>

    <script>
  

    function initDropdownEvents() {
        const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
        const repeaterContainer1 = document.getElementById("RepeaterContainer1");
        const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
        const repeaterContainer2 = document.getElementById("RepeaterContainer2");

        if (textBox1 && repeaterContainer1) {
            textBox1.addEventListener("focus", function () {
                repeaterContainer1.style.display = "block";
            });

            textBox1.addEventListener("input", function () {
                const input = textBox1.value.toLowerCase();
                filterSuggestions("category-link", input, repeaterContainer1);
            });
        }

        if (textBox2 && repeaterContainer2) {
            textBox2.addEventListener("focus", function () {
                repeaterContainer2.style.display = "block";
            });

            textBox2.addEventListener("input", function () {
                const input = textBox2.value.toLowerCase();
                filterSuggestions("category-link", input, repeaterContainer2);
            });
        }

        // Close dropdowns when clicking outside
        document.addEventListener("click", function (e) {
            if (textBox1 && repeaterContainer1) {
                if (!textBox1.contains(e.target) && !repeaterContainer1.contains(e.target)) {
                    repeaterContainer1.style.display = "none";
                }
            }
            if (textBox2 && repeaterContainer2) {
                if (!textBox2.contains(e.target) && !repeaterContainer2.contains(e.target)) {
                    repeaterContainer2.style.display = "none";
                }
            }
        });
    }

    function filterSuggestions(className, value, container) {
        const items = container.querySelectorAll("." + className);
        let matchFound = false;

        items.forEach(item => {
            if (item.innerText.toLowerCase().includes(value.toLowerCase())) {
                item.style.display = "block";
                matchFound = true;
            } else {
                item.style.display = "none";
            }
        });

        let noMatchMessage = container.querySelector("#no-match-message");

        if (!matchFound) {
            if (!noMatchMessage) {
                noMatchMessage = document.createElement("div");
                noMatchMessage.id = "no-match-message";
                noMatchMessage.className = "suggestion-item";
                noMatchMessage.innerText = "No matching suggestions.";
                container.appendChild(noMatchMessage);
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
    }

    function setTextBox2(value) {
        document.getElementById("<%= TextBox2.ClientID %>").value = value;
    document.getElementById("RepeaterContainer2").style.display = "none";
    }

    // Initialize on page load
    if (typeof Sys !== 'undefined') {
        Sys.Application.add_load(initDropdownEvents);
    } else {
        window.addEventListener('load', initDropdownEvents);
    }
    
        function initDropdownEvents() {
            const textBox1 = document.getElementById("<%= TextBox1.ClientID %>");
            const repeaterContainer1 = document.getElementById("RepeaterContainer1");
            const textBox2 = document.getElementById("<%= TextBox2.ClientID %>");
            const repeaterContainer2 = document.getElementById("RepeaterContainer2");

            if (textBox1 && repeaterContainer1) {
                textBox1.addEventListener("focus", function () {
                    repeaterContainer1.style.display = "block";
                });

                textBox1.addEventListener("input", function () {
                    const input = textBox1.value.toLowerCase();
                    filterSuggestions("category-link", input, repeaterContainer1);
                });
            }

            if (textBox2 && repeaterContainer2) {
                textBox2.addEventListener("focus", function () {
                    repeaterContainer2.style.display = "block";
                });

                textBox2.addEventListener("input", function () {
                    const input = textBox2.value.toLowerCase();
                    filterSuggestions("category-link", input, repeaterContainer2);
                });
            }

            // Close dropdowns when clicking outside
            document.addEventListener("click", function (e) {
                if (textBox1 && repeaterContainer1) {
                    if (!textBox1.contains(e.target) && !repeaterContainer1.contains(e.target)) {
                        repeaterContainer1.style.display = "none";
                    }
                }
                if (textBox2 && repeaterContainer2) {
                    if (!textBox2.contains(e.target) && !repeaterContainer2.contains(e.target)) {
                        repeaterContainer2.style.display = "none";
                    }
                }
            });
        }

        function filterSuggestions(className, value, container) {
            const items = container.querySelectorAll("." + className);
            let matchFound = false;

            items.forEach(item => {
                if (item.innerText.toLowerCase().includes(value.toLowerCase())) {
                    item.style.display = "block";
                    matchFound = true;
                } else {
                    item.style.display = "none";
                }
            });

            let noMatchMessage = container.querySelector("#no-match-message");

            if (!matchFound) {
                if (!noMatchMessage) {
                    noMatchMessage = document.createElement("div");
                    noMatchMessage.id = "no-match-message";
                    noMatchMessage.className = "suggestion-item";
                    noMatchMessage.innerText = "No matching suggestions.";
                    container.appendChild(noMatchMessage);
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
        }

        function setTextBox2(value) {
            document.getElementById("<%= TextBox2.ClientID %>").value = value;
            document.getElementById("RepeaterContainer2").style.display = "none";
        }

        // Initialize on page load
        if (typeof Sys !== 'undefined') {
            Sys.Application.add_load(initDropdownEvents);
        } else {
            window.addEventListener('load', initDropdownEvents);
        }
    </script>
</asp:Content>