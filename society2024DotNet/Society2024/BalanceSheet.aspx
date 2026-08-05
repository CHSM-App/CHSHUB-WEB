<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BalanceSheet.aspx.cs" Inherits="Society.BalanceSheet" MasterPageFile="~/Site.Master" %>

<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .balance-sheet-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
            background: #f8f9fa;
            min-height: 100vh;
        }

        .page-header {
            background: white;
            padding: 20px 30px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            margin-bottom: 25px;
        }

        .page-header h1 {
            color: #012970;
            font-weight: bold;
            margin: 0;
            font-size: 28px;
        }

        .action-bar {
            background: white;
            padding: 20px 30px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            margin-bottom: 25px;
        }

        .btn-primary {
            background: #012970 !important;
            border: none !important;
            padding: 10px 24px !important;
            border-radius: 8px !important;
            font-weight: 500 !important;
            transition: all 0.3s !important;
        }

        .btn-primary:hover {
            background: #01204e !important;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(1,41,112,0.3);
        }

        .content-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        /* Balance Sheet Grid */
        .balance-sheet-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 20px;
        }

        .grid-column {
            border: 2px solid #012970;
            border-radius: 8px;
            overflow: hidden;
        }

        .column-header {
            background: linear-gradient(135deg, #012970 0%, #024298 100%);
            color: white;
            padding: 15px 20px;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
        }

        .header-section {
            background: #f0f4f8;
            border-bottom: 2px solid #012970;
            cursor: move;
        }

        .header-title {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 20px;
            background: white;
            border-bottom: 1px solid #e0e0e0;
        }

        .header-title h5 {
            margin: 0;
            font-size: 16px;
            font-weight: 600;
            color: #012970;
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 1;
        }

        .header-title-right {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .drag-handle {
            display: inline-flex !important;
            align-items: center;
            justify-content: center;
            cursor: grab;
            padding: 4px 8px;
            background-color: #f0f4f8;
            border-radius: 4px;
            font-size: 18px;
            min-width: 28px;
            color: #012970;
        }

        .drag-handle:active {
            cursor: grabbing;
        }

        .header-amount {
            font-weight: 600;
            color: #012970;
            font-size: 15px;
        }

        .btn-edit-icon {
    background: transparent;
    border: none;
    color: #012970;
    cursor: pointer;
    font-size: 13px;
    /* padding: 4px 8px; */
    transition: all 0.3s;
    /* border-radius: 4px;*/
        }

        .btn-edit-icon:hover {
            background: #f0f4f8;
            transform: scale(1.1);
        }

        .subpoint-list {
            padding: 0;
            margin: 0;
        }

        .subpoint-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 20px;
            border-bottom: 1px solid #f0f0f0;
            background: white;
        }

        .subpoint-item:last-child {
            border-bottom: none;
        }

        .subpoint-name {
            flex: 1;
            color: #333;
            font-size: 14px;
            padding-left: 30px;
        }

        .subpoint-amount {
            font-weight: 500;
            color: #555;
            min-width: 80px;
            text-align: right;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 20px;
            background: #f8f9fa;
            border-top: 2px solid #012970;
            font-weight: bold;
            color: #012970;
        }

        .total-label {
            font-size: 15px;
        }

        .total-amount {
            font-size: 16px;
        }

        .btn-edit {
            background: white;
            color: #012970;
            border: 1px solid #012970;
            padding: 6px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-edit:hover {
            background: #012970;
            color: white;
        }

        /* Modal Styles */
        .type-selector {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }

        .type-option {
            flex: 1;
            padding: 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            cursor: pointer;
            text-align: center;
            transition: all 0.3s;
        }

        .type-option:hover {
            border-color: #012970;
            background: #f0f4f8;
        }

        .type-option.selected {
            border-color: #012970;
            background: #012970;
            color: white;
        }

        .type-option input[type="radio"] {
            margin-right: 8px;
        }

        .subpoint-row {
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            background: #fafafa;
        }

        .subpoint-row .form-group label {
            font-weight: 600;
            color: #012970;
        }

        @media (max-width: 991px) {
            .balance-sheet-grid {
                grid-template-columns: 1fr;
            }
        }

        .sortable-placeholder {
            background: #f0f4f8;
            border: 2px dashed #012970;
            visibility: visible !important;
            height: 60px;
        }
    </style>

    <input type="password" style="display: none" autocomplete="new-password" />

    <table width="100%">
        <tr>
            <th width="100%">
                <h1 class=" font-weight-bold " style="color: #012970;">Balance Sheet - Liabilities & Assets</h1>
            </th>
        </tr>
    </table>
    <br />

    <div class="balance-sheet-containerr">

        <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="upMain">
            <ContentTemplate>
                <div class="d-flex gap-2 mb-3">
                    <asp:Button ID="btnAddNew" runat="server" CssClass="btn btn-primary" Text="+ Add New Entry" OnClick="btnAddNew_Click" />
                    <asp:Button ID="btnSaveSequence" runat="server" Text="Save Sequence" OnClick="btnSaveSequence_Click" Style="display: none;" CssClass="btn btn-primary ml-3" />
                    <button type="button" class="btn btn-success" onclick="exportBalanceSheetToExcel()">Export to Excel</button>
                </div>

                <asp:HiddenField ID="hfSequenceData" runat="server" />
                <asp:HiddenField ID="hdSubpointsJson" runat="server" />
                <asp:HiddenField ID="hdHeaderId" runat="server" />
                <asp:HiddenField ID="hdEntryType" runat="server" />

                <div class="content-sectionn">
                    <div class="balance-sheet-grid">
                        <!-- Liabilities Column -->
                        <div class="grid-column">
                            <div class="column-header">Liabilities</div>
                            <div id="sortableLiabilities">
                                <asp:Repeater ID="rptLiabilities" runat="server" OnItemDataBound="rptBalance_ItemDataBound" OnItemCommand="rptBalance_ItemCommand">
                                    <ItemTemplate>
                                        <div class="header-section sortable-item" data-id='<%# Eval("bal_head_id") %>' data-type="liability">
                                            <div class="header-title">
                                                <h5>
                                                    <span class="drag-handle">⇅</span>
                                                    <%# Eval("bal_header_desc") %>
                                                    <asp:LinkButton ID="btnEdit" runat="server" CssClass="btn-edit-icon" CommandName="EditHeader" CommandArgument='<%# Eval("bal_head_id") %>' ToolTip="Edit">✏️</asp:LinkButton>
                                                </h5>
                                                <div class="header-title-right">
                                                    <span class="header-amount"><%# Eval("amount") %></span>
                                                </div>
                                            </div>
                                            <div class="subpoint-list">
                                                <asp:Repeater ID="rptSubpoints" runat="server">
                                                    <ItemTemplate>
                                                        <div class="subpoint-item">
                                                            <span class="subpoint-name"><%# Eval("subpoint_desc") %></span>
                                                            <span class="subpoint-amount"><%# Eval("amount") %></span>
                                                        </div>
                                                    </ItemTemplate>
                                                </asp:Repeater>
                                                <div class="total-row">
                                                    <span class="total-label">Total:</span>
                                                    <%--<span class="total-amount"><%# Eval("amount") %></span>--%>
                                                    <asp:Label runat="server" ID="lblTotal"></asp:Label>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>

                        <!-- Assets Column -->
                        <div class="grid-column">
                            <div class="column-header">Assets</div>
                            <div id="sortableAssets">
                                <asp:Repeater ID="rptAssets" runat="server" OnItemDataBound="rptBalance_ItemDataBound" OnItemCommand="rptBalance_ItemCommand">
                                    <ItemTemplate>
                                        <div class="header-section sortable-item" data-id='<%# Eval("bal_head_id") %>' data-type="asset">
                                            <div class="header-title">
                                                <h5>
                                                    <span class="drag-handle">⇅</span>
                                                    <%# Eval("bal_header_desc") %>
                                                    <asp:LinkButton ID="btnEdit" runat="server" CssClass="btn-edit-icon" CommandName="EditHeader" CommandArgument='<%# Eval("bal_head_id") %>' ToolTip="Edit">✏️</asp:LinkButton>
                                                </h5>
                                                <div class="header-title-right">
                                                    <span class="header-amount"><%# Eval("amount") %></span>
                                                </div>
                                            </div>
                                            <div class="subpoint-list">
                                                <asp:Repeater ID="rptSubpoints" runat="server">
                                                    <ItemTemplate>
                                                        <div class="subpoint-item">
                                                            <span class="subpoint-name"><%# Eval("subpoint_desc") %></span>
                                                            <span class="subpoint-amount"><%# Eval("amount") %></span>
                                                        </div>
                                                    </ItemTemplate>
                                                </asp:Repeater>
                                                <div class="total-row">
                                                    <span class="total-label">Total:</span>
                                                    <%--<span class="total-amount"><%# Eval("amount") %></span>--%>

                                                    <asp:Label runat="server" ID="lblTotal"></asp:Label>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>

    <!-- Edit/Add Modal -->
    <div class="modal fade" id="balanceModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content p-3" style="border-radius: 12px;">
                <div class="modal-header">
                    <h5 class="modal-title" id="balanceModalTitle">Add Balance Sheet Entry</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel runat="server" ID="upnEdit" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <asp:HiddenField ID="hdHeaderId_Server" runat="server" />

                            <!-- Type Selector -->
                            <div class="type-selector">
                                <div class="type-option" data-type="liability">
                                    <asp:RadioButton ID="rbLiability" runat="server" GroupName="EntryType" />
                                    Liability
                                </div>
                                <div class="type-option" data-type="asset">
                                    <asp:RadioButton ID="rbAsset" runat="server" GroupName="EntryType" />
                                    Asset
                                </div>
                            </div>

                            <!-- Header Title and Amount in Row -->
                            <div class="row">
                                <div class="col-md-8">
                                    <div class="form-group">
                                        <label><strong>Header Title:</strong></label>
                                        <asp:TextBox ID="txtHeaderTitle" runat="server" CssClass="form-control" Placeholder="Enter header title..." />
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label><strong>Header Amount:</strong></label>
                                        <asp:TextBox ID="txtHeaderAmount" runat="server" CssClass="form-control" TextMode="Number" Placeholder="Enter header amount..." />
                                    </div>
                                </div>
                            </div>

                            <!-- Subpoints Container -->
                            <div id="subpointsContainer">
                                <asp:Repeater ID="rptModalSubpoints" runat="server">
                                    <ItemTemplate>
                                        <div class="card mb-3 p-3 subpoint-row">
                                            <asp:HiddenField ID="hfSubpointId" runat="server" Value='<%# Eval("balance_subpoint_id") %>' />
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <strong><%# Container.ItemIndex + 1 %>)</strong>
                                                <button type="button" class="btn btn-sm btn-danger btn-delete-row">Delete</button>
                                            </div>

                                            <div class="row">
                                                <div class="col-md-8">
                                                    <div class="form-group">
                                                        <label>Description:</label>
                                                        <asp:TextBox ID="txtSubpointDesc" runat="server" Text='<%# Eval("subpoint_desc") %>' CssClass="form-control" />
                                                    </div>
                                                </div>
                                                <div class="col-md-4">
                                                    <div class="form-group">
                                                        <label>Amount:</label>
                                                        <asp:TextBox ID="txtAmount" runat="server" Text='<%# Eval("amount") %>' CssClass="form-control" TextMode="Number" />
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>

                            <!-- Client-side Template -->
                            <div id="subpointTemplate" style="display: none;">
                                <div class="card mb-3 p-3 subpoint-row">
                                    <input type="hidden" class="hfSubpointId" value="" />
                                    <div class="d-flex justify-content-between align-items-center mb-2">
                                        <strong class="row-index">#</strong>
                                        <button type="button" class="btn btn-sm btn-danger btn-delete-row">Delete</button>
                                    </div>

                                    <div class="row">
                                        <div class="col-md-8">
                                            <div class="form-group">
                                                <label>Description:</label>
                                                <input class="form-control txtSubpointDesc" placeholder="Enter description..." />
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>Amount:</label>
                                                <input type="number" class="form-control txtAmount" placeholder="0" />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="text-right">
                                <button id="btnAddSubpoint" type="button" class="btn btn-success">+ Add Subpoint</button>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Save" OnClick="btnSave_Click" OnClientClick="prepareSubpointsForSave(); return true;" />
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>


<!-- Remove SheetJS and add ExcelJS instead -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/exceljs/4.3.0/exceljs.min.js"></script>
    <!-- Scripts -->
<%--    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>--%>
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>
<%--    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" />--%>
<%--    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>--%>
<%--    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css" />--%>


    <script>

async function exportBalanceSheetToExcel() {
    try {
        // Parse data from DOM
        const liabilities = parseColumnData('#sortableLiabilities');
        const assets = parseColumnData('#sortableAssets');
        
        console.log('Liabilities:', liabilities);
        console.log('Assets:', assets);
        
        // Create workbook and worksheet
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Balance Sheet');
        
        // Set column widths
        worksheet.columns = [
            { width: 35 }, // A - Liability descriptions
            { width: 15 }, // B - Liability sub-amounts
            { width: 18 }, // C - Liability totals
            { width: 3 },  // D - Spacing
            { width: 35 }, // E - Asset descriptions
            { width: 15 }, // F - Asset sub-amounts
            { width: 18 }  // G - Asset totals
        ];
        
        // First row - Headers with year
        const row1 = worksheet.getRow(1);
        row1.getCell(1).value = 'LIABILITIES';
        row1.getCell(1).font = { bold: true, size: 14 };
        row1.getCell(1).alignment = { horizontal: 'center' };
        
        row1.getCell(2).value = '2025-26';
        row1.getCell(2).font = { bold: true, size: 12 };
        row1.getCell(2).alignment = { horizontal: 'center' };
        
        row1.getCell(3).font = { bold: true };
        
        row1.getCell(5).value = 'ASSETS';
        row1.getCell(5).font = { bold: true, size: 14 };
        row1.getCell(5).alignment = { horizontal: 'center' };
        
        row1.getCell(6).value = '2025-26';
        row1.getCell(6).font = { bold: true, size: 12 };
        row1.getCell(6).alignment = { horizontal: 'center' };
        
        row1.getCell(7).font = { bold: true };
        
        let currentRow = 3; // Start data from row 3
        
        // Process both columns
        let liabRow = currentRow;
        let assetRow = currentRow;
        
        const liabTotalRows = [];
        const assetTotalRows = [];
        
        // Build Liabilities column
        liabilities.forEach((head) => {
            const result = addHeaderSection(worksheet, head, liabRow, 1, 2, 3); // cols A, B, C
            liabRow = result.nextRow;
            liabTotalRows.push(result.totalRow);
        });
        
        // Build Assets column
        assets.forEach((head) => {
            const result = addHeaderSection(worksheet, head, assetRow, 5, 6, 7); // cols E, F, G
            assetRow = result.nextRow;
            assetTotalRows.push(result.totalRow);
        });
        
        // Grand totals
        const finalRow = Math.max(liabRow, assetRow) + 1;
        
        // Liabilities grand total
        const liabGrandRow = worksheet.getRow(finalRow);
        liabGrandRow.getCell(1).value = 'GRAND TOTAL';
        liabGrandRow.getCell(1).font = { bold: true, size: 12 };
        
        if (liabTotalRows.length > 0) {
            const formula = liabTotalRows.map(r => `C${r}`).join('+');
            liabGrandRow.getCell(3).value = { formula };
            liabGrandRow.getCell(3).font = { bold: true, size: 12 };
            liabGrandRow.getCell(3).numFmt = '₹#,##0.00';
        }
        
        // Assets grand total
        assetGrandRow = worksheet.getRow(finalRow);
        assetGrandRow.getCell(5).value = 'GRAND TOTAL';
        assetGrandRow.getCell(5).font = { bold: true, size: 12 };
        
        if (assetTotalRows.length > 0) {
            const formula = assetTotalRows.map(r => `G${r}`).join('+');
            assetGrandRow.getCell(7).value = { formula };
            assetGrandRow.getCell(7).font = { bold: true, size: 12 };
            assetGrandRow.getCell(7).numFmt = '₹#,##0.00';
        }
        
        // Generate and download
        const buffer = await workbook.xlsx.writeBuffer();
        const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'Balance_Sheet.xlsx';
        a.click();
        window.URL.revokeObjectURL(url);
        
        console.log('Export completed successfully');
        
    } catch (error) {
        console.error('Export failed:', error);
        alert('Failed to export Balance Sheet: ' + error.message);
    }
}

// Parse data from a column container
function parseColumnData(selector) {
    const container = document.querySelector(selector);
    if (!container) return [];
    
    const headers = [];
    const headerSections = container.querySelectorAll('.header-section');
    
    headerSections.forEach(section => {
        const titleElement = section.querySelector('h5');
        const headerAmountElement = section.querySelector('.header-amount');
        
        // Extract main head title
        let title = titleElement ? titleElement.textContent.trim() : '';
        title = title.replace(/^⇅\s*/, '').replace(/✏️$/, '').trim();
        
        // Extract main head's own amount
        let headerAmount = 0;
        if (headerAmountElement) {
            const amtText = headerAmountElement.textContent.trim();
            if (amtText && amtText !== '' && amtText !== '0' && amtText !== '0.00') {
                headerAmount = parseAmount(amtText);
            }
        }
        
        // Extract sub-points
        const subpoints = [];
        const subpointItems = section.querySelectorAll('.subpoint-item');
        subpointItems.forEach(item => {
            const name = item.querySelector('.subpoint-name')?.textContent.trim() || '';
            const amount = parseAmount(item.querySelector('.subpoint-amount')?.textContent || '0');
            if (name) {
                subpoints.push({ name, amount });
            }
        });
        
        headers.push({
            title,
            headerAmount,
            subpoints
        });
    });
    
    return headers;
}

// Add a complete header section with proper total calculation
function addHeaderSection(worksheet, head, startRow, colDesc, colSubAmt, colTotal) {
    let row = startRow;
    let mainHeadAmountRow = null;
    
    // CASE 1: Main head has its own amount + subpoints
    if (head.headerAmount > 0 && head.subpoints.length > 0) {
        // Main head title with its own amount in middle column
        const mainRow = worksheet.getRow(row);
        mainRow.getCell(colDesc).value = head.title;
        mainRow.getCell(colDesc).font = { bold: true };
        mainRow.getCell(colSubAmt).value = head.headerAmount;
        mainRow.getCell(colSubAmt).numFmt = '₹#,##0.00';
        const mainAmountRow = row;
        row++;
        
        // Add subpoints with indentation
        const subpointStartRow = row;
        head.subpoints.forEach(sub => {
            const subRow = worksheet.getRow(row);
            subRow.getCell(colDesc).value = `    ${sub.name}`;
            subRow.getCell(colSubAmt).value = sub.amount;
            subRow.getCell(colSubAmt).numFmt = '₹#,##0.00';
            row++;
        });
        const subpointEndRow = row - 1;
        
        // Total
        const totalRow = worksheet.getRow(row);
        totalRow.getCell(colDesc).value = 'Total';
        totalRow.getCell(colDesc).font = { bold: true };
        
        const colLetter = String.fromCharCode(64 + colSubAmt);
        const formula = `SUM(${colLetter}${mainAmountRow}:${colLetter}${subpointEndRow})`;
        totalRow.getCell(colTotal).value = { formula };
        totalRow.getCell(colTotal).font = { bold: true };
        totalRow.getCell(colTotal).numFmt = '₹#,##0.00';
        
        const totalRowNum = row;
        row += 2;
        
        return { nextRow: row, totalRow: totalRowNum };
    }
    
    // CASE 2: Main head has only its own amount (no subpoints)
    else if (head.headerAmount > 0 && head.subpoints.length === 0) {
        const mainRow = worksheet.getRow(row);
        mainRow.getCell(colDesc).value = head.title;
        mainRow.getCell(colDesc).font = { bold: true };
        mainRow.getCell(colSubAmt).value = head.headerAmount;
        mainRow.getCell(colSubAmt).numFmt = '₹#,##0.00';
        const mainAmountRow = row;
        row++;
        
        // Total
        const totalRow = worksheet.getRow(row);
        totalRow.getCell(colDesc).value = 'Total';
        totalRow.getCell(colDesc).font = { bold: true };
        
        const colLetter = String.fromCharCode(64 + colSubAmt);
        totalRow.getCell(colTotal).value = { formula: `${colLetter}${mainAmountRow}` };
        totalRow.getCell(colTotal).font = { bold: true };
        totalRow.getCell(colTotal).numFmt = '₹#,##0.00';
        
        const totalRowNum = row;
        row += 2;
        
        return { nextRow: row, totalRow: totalRowNum };
    }
    
    // CASE 3: Main head has only subpoints (no own amount)
    else if (head.subpoints.length > 0) {
        const mainRow = worksheet.getRow(row);
        mainRow.getCell(colDesc).value = head.title;
        mainRow.getCell(colDesc).font = { bold: true };
        row++;
        
        const subpointStartRow = row;
        head.subpoints.forEach(sub => {
            const subRow = worksheet.getRow(row);
            subRow.getCell(colDesc).value = `    ${sub.name}`;
            subRow.getCell(colSubAmt).value = sub.amount;
            subRow.getCell(colSubAmt).numFmt = '₹#,##0.00';
            row++;
        });
        const subpointEndRow = row - 1;
        
        // Total
        const totalRow = worksheet.getRow(row);
        totalRow.getCell(colDesc).value = 'Total';
        totalRow.getCell(colDesc).font = { bold: true };
        
        const colLetter = String.fromCharCode(64 + colSubAmt);
        const formula = `SUM(${colLetter}${subpointStartRow}:${colLetter}${subpointEndRow})`;
        totalRow.getCell(colTotal).value = { formula };
        totalRow.getCell(colTotal).font = { bold: true };
        totalRow.getCell(colTotal).numFmt = '₹#,##0.00';
        
        const totalRowNum = row;
        row += 2;
        
        return { nextRow: row, totalRow: totalRowNum };
    }
    
    // CASE 4: Empty section
    else {
        const mainRow = worksheet.getRow(row);
        mainRow.getCell(colDesc).value = head.title;
        mainRow.getCell(colDesc).font = { bold: true };
        row++;
        
        const totalRow = worksheet.getRow(row);
        totalRow.getCell(colDesc).value = 'Total';
        totalRow.getCell(colDesc).font = { bold: true };
        totalRow.getCell(colTotal).value = 0;
        totalRow.getCell(colTotal).font = { bold: true };
        totalRow.getCell(colTotal).numFmt = '₹#,##0.00';
        
        const totalRowNum = row;
        row += 2;
        
        return { nextRow: row, totalRow: totalRowNum };
    }
}

// Parse amount from text
function parseAmount(text) {
    if (!text) return 0;
    const cleaned = text.replace(/[₹,\s]/g, '').trim();
    const num = parseFloat(cleaned);
    return isNaN(num) ? 0 : num;
}

// Button will be added manually in ASP.NET markup
    </script>


    <script type="text/javascript">
        function initBalanceSheetScripts() {

            // Type selector click
            $('.type-option').off('click').on('click', function () {
                $('.type-option').removeClass('selected');
                $(this).addClass('selected');
                $(this).find('input[type="radio"]').prop('checked', true);
            });

            // Sortable for Liabilities
            $("#sortableLiabilities").sortable({
                cursor: "move",
                placeholder: "sortable-placeholder",
                connectWith: "#sortableAssets",
                update: function (event, ui) {
                    saveSequence();
                }
            });

            // Sortable for Assets
            $("#sortableAssets").sortable({
                cursor: "move",
                placeholder: "sortable-placeholder",
                connectWith: "#sortableLiabilities",
                update: function (event, ui) {
                    saveSequence();
                }
            });

            // Add subpoint
            $('#btnAddSubpoint').off('click').on('click', function () {
                var tpl = $('#subpointTemplate').html();
                $('#subpointsContainer').append(tpl);
                reIndexSubpoints();
            });

            // Delete subpoint
            $('#subpointsContainer').off('click', '.btn-delete-row').on('click', '.btn-delete-row', function () {
                $(this).closest('.subpoint-row').remove();
                reIndexSubpoints();
            });
        }

        function saveSequence() {
            var items = [];

            // Liabilities
            $("#sortableLiabilities .sortable-item").each(function (index) {
                items.push({
                    Id: $(this).data("id"),
                    Type: "liability",
                    SequenceOrder: index + 1
                });
            });

            // Assets
            $("#sortableAssets .sortable-item").each(function (index) {
                items.push({
                    Id: $(this).data("id"),
                    Type: "asset",
                    SequenceOrder: index + 1
                });
            });

            $("#<%= hfSequenceData.ClientID %>").val(JSON.stringify(items));
            $("#<%= btnSaveSequence.ClientID %>").show();
        }

        function reIndexSubpoints() {
            $('#subpointsContainer .subpoint-row').each(function (idx) {
                $(this).find('.row-index').text((idx + 1) + ')');
                $(this).find('strong').first().text((idx + 1) + ')');
            });
        }

        function prepareSubpointsForSave() {
            var items = [];
            $('#subpointsContainer .subpoint-row').each(function () {
                var subId = $(this).find("input[id*='hfSubpointId']").val() || $(this).find('.hfSubpointId').val() || '';
                var desc = $(this).find("input[id*='txtSubpointDesc']").val() || $(this).find('.txtSubpointDesc').val() || '';
                var amount = $(this).find("input[id*='txtAmount']").val() || $(this).find('.txtAmount').val() || '0';

                items.push({
                    balance_subpoint_id: subId,
                    subpoint_desc: desc,
                    amount: amount
                });
            });

            var headerTitle = $('#<%= txtHeaderTitle.ClientID %>').val();
            var headerAmount = $('#<%= txtHeaderAmount.ClientID %>').val() || '0';
            var entryType = $('input[name$="EntryType"]:checked').length > 0 ?
                ($('#<%= rbLiability.ClientID %>').is(':checked') ? 'liability' : 'asset') : '';

            var payload = {
                headerTitle: headerTitle,
                headerAmount: headerAmount,
                entryType: entryType,
                subpoints: items
            };

            $('#<%= hdSubpointsJson.ClientID %>').val(JSON.stringify(payload));
        }

        $(document).ready(function () {
            initBalanceSheetScripts();
        });

        if (typeof (Sys) !== "undefined" && Sys.WebForms && Sys.WebForms.PageRequestManager) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                initBalanceSheetScripts();
            });
        }
    </script>

</asp:Content>
