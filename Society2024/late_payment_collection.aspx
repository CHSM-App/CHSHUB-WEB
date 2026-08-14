<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="late_payment_collection.aspx.cs" Inherits="Society.LatePaymentCollection" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <style>
    	/* GridView Container */
    	.gv-container {
    		width: 100% !important;
    		border-collapse: collapse !important;
    		font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif !important;
    		font-size: 14px !important;
    		color: #333 !important;
    		background-color: #fff !important;
    		border: 2px solid #2c5282 !important;
    		margin-bottom: 0 !important;
    	}

    		/* Header Styling */
    		.gv-container thead tr th,
    		.gv-container th,
    		.gv-header {
    			background-color: #2c5282 !important;
    			color: #ffffff !important;
    			padding: 12px 15px !important;
    			text-align: left !important;
    			font-weight: 600 !important;
    			border: 1px solid #2c5282 !important;
    			text-transform: uppercase !important;
    			font-size: 13px !important;
    			letter-spacing: 0.5px !important;
    		}

    		/* Regular Rows */
    		.gv-container tbody tr td,
    		.gv-container td,
    		.gv-row {
    			padding: 10px 15px !important;
    			border: 1px solid #d1d5db !important;
    			background-color: #ffffff !important;
    			vertical-align: middle !important;
    		}

    		/* Alternate Row Color - Very Subtle */
    		.gv-container tbody tr:nth-child(even) td,
    		.gv-alt-row {
    			background-color: #f9fafb !important;
    		}

    		/* Remove hover effect for government form look */
    		.gv-container tbody tr:hover td {
    			background-color: inherit !important;
    		}

    		/* Total Row Styling - Last Row */
    		.gv-container tbody tr:last-child td,
    		.gv-total-row {
    			background-color: #e6f2ff !important;
    			font-weight: 700 !important;
    			border-top: 2px solid #2c5282 !important;
    			border-bottom: 2px solid #2c5282 !important;

    			color: #1a365d !important;
    			font-size: 15px !important;
    		}

    		/* Second to Last Row (Empty Row) */
    		.gv-container tbody tr:nth-last-child(2) td,
    		.gv-empty-row {
    			border: none !important;
    			background-color: #ffffff !important;
    			padding: 5px !important;
    		}

    		/* Amount Columns Alignment */
    		.gv-container td:nth-child(2),
    		.gv-container td:nth-child(4),
    		.gv-container tbody tr td:nth-child(2),
    		.gv-container tbody tr td:nth-child(4),
    		.gv-amount {
    			text-align: right !important;
    			font-family: 'Courier New', monospace !important;
    		}

    		/* Header Alignment for Amount Columns */
    		.gv-container th:nth-child(2),
    		.gv-container th:nth-child(4),
    		.gv-container thead tr th:nth-child(2),
    		.gv-container thead tr th:nth-child(4),
    		.gv-header-amount {
    			text-align: right !important;
    		}

    	/* Print Friendly */
    	@media print {
    		.gv-container {
    			border: 1px solid #000 !important;
    		}

    			.gv-container th,
    			.gv-header {
    				background-color: #2c5282 !important;
    				-webkit-print-color-adjust: exact;
    				print-color-adjust: exact;
    			}

    			.gv-container tbody tr:last-child td,
    			.gv-total-row {
    				background-color: #e6f2ff !important;
    				-webkit-print-color-adjust: exact;
    				print-color-adjust: exact;
    			}
    	}

    	.pdf-page-break {
    		page-break-after: always;
    		padding: 20px;
    	}

    		.pdf-page-break:last-child {
    			page-break-after: auto;
    		}

    	/* Download Button Styling */
    	.download-btn {
    		background-color: #2c5282;
    		color: white;
    		padding: 10px 20px;
    		border: none;
    		border-radius: 5px;
    		font-size: 16px;
    		font-weight: 600;
    		cursor: pointer;
    		margin-bottom: 20px;
    		transition: background-color 0.3s ease;
    	}

    		.download-btn:hover {
    			background-color: #1a365d;
    		}

    		.download-btn:active {
    			transform: scale(0.98);
    		}
    </style>

    <table width="100%">
        <tr>
            <th width="100%">
                <h1 class="font-weight-bold" style="color: #012970;">Payment Due Report</h1>
            </th>
        </tr>
    </table>

    <button type="button" class="download-btn" onclick="downloadPDF()">Download PDF</button>

    <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" CssClass="gv-container" GridLines="Both" CellPadding="0" CellSpacing="0">
        <Columns>
            <asp:BoundField DataField="name" HeaderText="Name" />
              <asp:BoundField DataField="unit" HeaderText="Unit" />
              <asp:BoundField DataField="month" HeaderText="Month" />
              <asp:BoundField DataField="year" HeaderText="Year" />
            <asp:BoundField DataField="tax_interest_amt" HeaderText=" Tax Amount" DataFormatString="{0:N2}" />
            <asp:BoundField DataField="amt_forward" HeaderText="Due" DataFormatString="{0:N2}" />
             <asp:BoundField DataField="total" HeaderText="Total" DataFormatString="{0:N2}" />
        </Columns>
    </asp:GridView>

    <!-- jsPDF Library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js"></script>

    <script type="text/javascript">
        function downloadPDF() {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF('p', 'mm', 'a4');

            // Page dimensions
            const pageWidth = doc.internal.pageSize.getWidth();
            const pageHeight = doc.internal.pageSize.getHeight();
            const margin = 20; // 20mm margins from all sides

            // Add title
            doc.setFontSize(18);
            doc.setFont(undefined, 'bold');
            doc.setTextColor(1, 41, 112); // #012970
            doc.text('Late Payment Collection Report', margin, margin);

            // Get table data from GridView
            const table = document.getElementById('<%= GridView1.ClientID %>');
            const headers = [];
            const rows = [];

            // Extract headers
            const headerCells = table.querySelectorAll('thead tr th, tr:first-child th');
            headerCells.forEach(cell => {
                headers.push(cell.textContent.trim());
            });

            // Extract data rows
            const bodyRows = table.querySelectorAll('tbody tr');
            bodyRows.forEach(row => {
                const rowData = [];
                const cells = row.querySelectorAll('td');
                if (cells.length > 0) {
                    cells.forEach(cell => {
                        rowData.push(cell.textContent.trim());
                    });
                    rows.push(rowData);
                }
            });

            // Generate table with autoTable
            doc.autoTable({
                head: [headers],
                body: rows,
                startY: margin + 10,
                margin: { top: margin, right: margin, bottom: margin, left: margin },
                theme: 'grid',
                styles: {
                    fontSize: 10,
                    cellPadding: 5,
                    lineColor: [209, 213, 219],
                    lineWidth: 0.1,
                    textColor: [51, 51, 51],
                    font: 'helvetica'
                },
                headStyles: {
                    fillColor: [44, 82, 130], // #2c5282
                    textColor: [255, 255, 255],
                    fontStyle: 'bold',
                    halign: 'left',
                    fontSize: 11
                },
                bodyStyles: {
                    fillColor: [255, 255, 255]
                },
                alternateRowStyles: {
                    fillColor: [249, 250, 251] // #f9fafb
                },
                columnStyles: {
                    1: { halign: 'right', font: 'courier' }, // Amount columns
                    3: { halign: 'right', font: 'courier' }
                },
                didParseCell: function (data) {
                    // Check if this is the last row (Total row)
                    if (data.row.index === rows.length - 1) {
                        data.cell.styles.fillColor = [230, 242, 255]; // #e6f2ff
                        data.cell.styles.fontStyle = 'bold';
                        data.cell.styles.textColor = [26, 54, 93]; // #1a365d
                        data.cell.styles.fontSize = 11;
                    }
                    // Check if this is second to last row (empty row)
                    if (data.row.index === rows.length - 2) {
                        data.cell.styles.fillColor = [255, 255, 255];
                        data.cell.styles.lineWidth = 0;
                    }
                },
                // Prevent row breaking across pages
                rowPageBreak: 'avoid',
                // Add page numbers
                didDrawPage: function (data) {
                    // Footer with page number
                    doc.setFontSize(8);
                    doc.setTextColor(128);
                    doc.text(
                        'Page ' + doc.internal.getNumberOfPages(),
                        pageWidth / 2,
                        pageHeight - 10,
                        { align: 'center' }
                    );
                }
            });

            // Save the PDF
            const fileName = 'LatePaymentCollectionReport ' + new Date().toISOString().split('T')[0] + '.pdf';
            doc.save(fileName);
        }
    </script>
</asp:Content>