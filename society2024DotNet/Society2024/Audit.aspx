<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Audit.aspx.cs" Inherits="Society.Audit" MasterPageFile="~/Site.Master" %>
<asp:Content ID="content1" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* (Same CSS as you had; trimmed only for clarity) */
        .audit-container {
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

        .qa-section {
            margin-bottom: 25px;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            transition: all 0.3s;
            cursor: move;
        }

            .qa-section:hover {
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                border-color: #012970;
                transform: translateY(-2px);
            }

        .qa-header {
            background: linear-gradient(135deg,#012970 0%,#024298 100%);
            color: white;
            padding: 15px 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

            .qa-header h5 {
                margin: 0;
                font-size: 16px;
                font-weight: 600;
                display: flex;
                align-items: center;
                gap: 12px;
            }

        .drag-handle {
            display: inline-flex !important;
            align-items: center;
            justify-content: center;
            cursor: grab;
            padding: 4px 8px;
            transition: all 0.2s;
            background-color: rgba(255,255,255);
            border-radius: 4px;
            font-size: 20px;
            min-width: 30px;
        }

        .qa-body {
            padding: 20px 25px;
            display: none;
            overflow: hidden;
            transition: max-height 1s ease;
        }

            .qa-body.open {
                max-height: 1000px;
            }

        .qa-item {
            display: flex;
            padding: 12px 0;
            border-bottom: 1px solid #f0f0f0;
            align-items: flex-start;
            gap: 20px;
        }

        .qa-question {
            flex: 1;
            color: #333;
            font-size: 14px;
            line-height: 1.6;
            padding-right: 20px;
        }

        .qa-answer {
            flex: 0 0 300px;
            background: #f8f9fa;
            padding: 10px 15px;
            border-radius: 6px;
            border-left: 3px solid #012970;
        }

        .btn-edit {
            background: white;
            color: #012970;
            border: none;
            padding: 6px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
        }

        .view-audit-btn {
            background: linear-gradient(135deg,#28a745 0%,#20c997 100%);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 3px 10px rgba(40,167,69,0.3);
        }

            .view-audit-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(40,167,69,0.4);
            }

    .info-row {
    display: flex;
    align-items: flex-start;
    margin-bottom: 6px;
    gap: 30px
}
        /* GridView container styles (kept as-is) */
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

        /* modal related small styles */
        .modal-body {
            max-height: 70vh;
            overflow-y: auto;
        }

        .download-btn {
            position: absolute;
            top: 15px;
            right: 60px;
            z-index: 1050;
        }

        .signature-line {
            display: inline-block;
            border-bottom: 1px solid #000;
            width: 200px;
            margin-top: 40px;
        }

        @media print {
            .download-btn, .close, .modal-header button, .modal-footer {
                display: none !important;
            }

            .modal-body {
                max-height: none !important;
                overflow: visible !important;
            }
        }

        /* Modal container - tighter, more focused content width for modal-xl */
        #auditFormModal .modal-dialog {
            max-width: 1100px;
            margin: 30px auto;
        }

        /* Modal content padding and subtle shadow */
        #auditFormModal .modal-content {
            border-radius: 12px;
            padding: 0;
            overflow: hidden;
            box-shadow: 0 8px 30px rgba(10, 30, 60, 0.12);
        }

        /* Header area inside modal body - keep compact and centered */
        .audit-form-content {
            background: #ffffff;
            color: #111;
            font-family: 'Nirmala UI', 'Mangal', 'Segoe UI', Roboto, Arial, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            padding: 22px;
            box-sizing: border-box;
        }

        /* Title + society meta */
        .audit-form-header {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 1px solid #e6e6e6;
            margin-bottom: 18px;
        }

            .audit-form-header h4 {
                font-size: 20px;
                font-weight: 700;
                margin: 2px 0 6px;
            }

            .audit-form-header h5,
            .audit-form-header p {
                margin: 0;
                font-size: 13px;
                color: #333;
            }

        /* Society info block - two column grid */
        .society-info {
            border: 1px solid #dedede;
            padding: 14px;
            margin: 12px 0 18px;
            border-radius: 6px;
            background: #fafafa;
        }

            .society-info .row {
                margin: 0;
            }

            .society-info p {
                margin: 6px 0;
                font-size: 13px;
                color: #222;
            }

            .society-info strong {
                display: inline-block;
                min-width: 90px;
                color: #0b3b66;
            }

        /* Main points (header boxes) */
        .main-point {
            font-weight: 700;
            font-size: 15px;
            margin: 18px 0 8px;
            padding: 10px 12px;
            border-radius: 6px;
            border: 1px solid #d0d7e6;
            background: linear-gradient(180deg, #f7fbff 0%, #ffffff 100%);
            color: #0b3b66;
            box-shadow: 0 1px 0 rgba(12, 40, 80, 0.02) inset;
        }

        /* Question list - keep neat rows */
        .question-item {
            padding: 10px 0;
            border-bottom: 1px dashed #eee;
            page-break-inside: avoid;
        }

            .question-item:last-child {
                border-bottom: none;
            }

        .question-row {
            display: flex;
            gap: 18px;
            align-items: flex-start;
            width: 100%;
        }

        /* Question text takes majority, answer sits to the right */
        .question-label {
            flex: 1 1 70%;
            font-size: 14px;
            color: #222;
        }

        .answer-label {
            flex: 0 0 28%;
            text-align: left;
            font-size: 14px;
            color: #333;
            background: #f7fafc;
            padding: 8px 10px;
            border-radius: 6px;
            border-left: 3px solid #0b3b66;
        }

        /* For very long answers keep wrapping and readable */
        .answer-label, .question-label {
            word-break: break-word;
        }

        /* Signature / footer layout */
        .footer-section {
            margin-top: 26px;
            padding-top: 18px;
            border-top: 1px solid #e6e6e6;
        }

        .signature-section {
            display: flex;
            justify-content: space-between;
            gap: 20px;
            align-items: center;
            margin-top: 18px;
        }

        .signature-left, .signature-right {
            flex: 1 1 50%;
            font-size: 13px;
            color: #222;
        }

        .signature-right {
            text-align: right;
        }

        /* Signature line */
        .signature-line {
            display: inline-block;
            border-bottom: 1px solid #000;
            width: 220px;
            height: 2px;
            margin-top: 36px;
        }

        /* Download button placement (keeps inside modal header) */
        #auditFormModal .download-btn {
            position: absolute;
            right: 26px;
            top: 12px;
            z-index: 1100;
        }

        /* Responsive adjustments */
        @media (max-width: 991px) {
            #auditFormModal .modal-dialog {
                max-width: 95%;
                margin: 12px;
            }

            .question-row {
                flex-direction: column;
            }

            .answer-label {
                width: 100%;
                flex: 1 1 auto;
                margin-top: 8px;
            }

            .signature-section {
                flex-direction: column;
                text-align: left;
            }

            .signature-right {
                text-align: left;
            }
        }

        /* Print friendly fine-tuning */
        @media print {
            body * {
                visibility: visible;
            }

            #auditFormModal .modal-dialog {
                max-width: 100%;
            }

            #auditFormModal .modal-content {
                box-shadow: none;
                border: none;
            }

            .download-btn, .close, .modal-footer, .modal-header button {
                display: none !important;
            }

            .audit-form-content {
                padding: 8px;
            }

            .question-item {
                page-break-inside: avoid;
            }

            .main-point {
                page-break-after: avoid;
            }

            .signature-section {
                page-break-inside: avoid;
            }
        }
    </style>

    <%--<asp:ScriptManager runat="server" ID="ScriptManager1" EnablePageMethods="true" />--%>

    <!-- Hidden autofill blocker -->
    <input type="password" style="display:none" autocomplete="new-password" />

    <table class="w-100">
        <tr>
            <th>
                <h1 class="font-weight-bold mr-l" style="color: #012970;">Audit Q&A</h1>
            </th>
        </tr>
    </table>

    <asp:UpdatePanel runat="server" UpdateMode="Conditional" ID="upMain">
        <ContentTemplate>
            <div class="row">
                <div class="col-12">
                    <div class="top-row d-flex align-items-center flex-wrap mr-l">
                        <asp:Button type="button" ID="btnviewAudit" class="view-audit-btn" runat="server" OnClick="viewAudit" Text="📄 View Audit Form" />
                        &nbsp;&nbsp;
                        <asp:Button ID="btnAddNew" runat="server" CssClass="btn btn-primary" Text="+ Add New" OnClick="btnAddNew_Click" />
                    </div>
                </div>
            </div>

            <div class="audit-container">
                <!-- Hidden Fields -->
                <asp:HiddenField ID="role_id" runat="server" />
                <asp:HiddenField ID="society_id" runat="Server" />
                <asp:HiddenField ID="hfSequenceData" runat="server" />
                <asp:HiddenField ID="hdSubpointsJson" runat="server" />
                <asp:HiddenField ID="hdHeaderId" runat="server" />

                <!-- Content Section -->
                <div class="content-section">
                    <!-- Parent Repeater -->
                    <div id="sortableMain">
                        <asp:Repeater ID="rptMain" runat="server" OnItemDataBound="rptMain_ItemDataBound" OnItemCommand="rptMain_ItemCommand">
                            <ItemTemplate>
                                <div class="qa-section sortable-item" data-id='<%# Eval("audt_header_id") %>'>
                                    <div class="qa-header toggle-header">
                                        <h5>
                                            <span class="drag-handle">⇅</span>
                                            <%# Eval("audt_header_desc") %>
                                        </h5>
                                        <asp:LinkButton ID="btnEdit" runat="server" CssClass="btn-edit" CommandName="EditHeader" CommandArgument='<%# Eval("audt_header_id") %>'>✏️ Edit</asp:LinkButton>
                                    </div>

                                    <div class="qa-body">
                                        <asp:Repeater ID="rptSub" runat="server">
                                            <ItemTemplate>
                                                <div class="qa-item">
                                                    <div class="qa-question">
                                                        <strong><%# Container.ItemIndex + 1 %>)</strong>
                                                        <%# Eval("question_desc") %>
                                                    </div>
                                                    <div class="qa-answer">
                                                        <span><%# Eval("answer_desc") %></span>
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>

                    <!-- SAVE SEQUENCE (hidden until reorder) -->
                    <asp:Button ID="btnSaveSequence" runat="server" Text="Save Sequence" OnClick="btnSaveSequence_Click" Style="display:none;" CssClass="btn btn-primary" />
                </div>
            </div>
        </ContentTemplate>
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="btnviewAudit" EventName="Click" />
            <asp:AsyncPostBackTrigger ControlID="btnAddNew" EventName="Click" />
        </Triggers>
    </asp:UpdatePanel>

    <!-- Edit/Add modal -->
    <div class="modal fade" id="auditModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content p-3" style="border-radius:12px;">
                <div class="modal-header">
                    <h5 class="modal-title" id="auditModalTitle">Edit Audit Header</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel runat="server" ID="upnEdit" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <asp:HiddenField ID="hdHeaderId_Server" runat="server" />
                            <div class="form-group d-flex">
                                <asp:TextBox ID="txtHeaderTitle" runat="server" CssClass="form-control" Placeholder="मुख्य मुद्दा शीर्षक..." />
                            </div>

                            <!-- Subpoints area -->
                            <div id="subpointsContainer">
                                <asp:Repeater ID="rptModalSubpoints" runat="server" OnItemCommand="rptModalSubpoints_ItemCommand">
                                    <ItemTemplate>
                                        <div class="card mb-3 p-3 subpoint-row">
                                            <!-- Server-rendered fields -->
                                            <asp:HiddenField ID="hfQuesId" runat="server" Value='<%# Eval("audt_ques_id") %>' />
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <strong><%# Container.ItemIndex + 1 %>)</strong>
                                                <button type="button" class="btn btn-sm btn-danger btn-delete-row">Delete</button>
                                            </div>

                                            <div class="form-group">
                                                <label>प्रश्न:</label>
                                                <asp:TextBox ID="txtQuestion" runat="server" Text='<%# Eval("question_desc") %>' CssClass="form-control" TextMode="MultiLine" Rows="2" />
                                            </div>

                                            <div class="form-group">
                                                <label>उत्तर:</label>
                                                <asp:TextBox ID="txtAnswer" runat="server" Text='<%# Eval("answer_desc") %>' CssClass="form-control" />
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>

                            <!-- Pure-HTML template used for client-side new rows (no server controls) -->
                            <div id="subpointTemplate" style="display:none;">
                                <div class="card mb-3 p-3 subpoint-row">
                                    <input type="hidden" class="hfQuesId" value="" />
                                    <div class="d-flex justify-content-between align-items-center mb-2">
                                        <strong class="row-index">#</strong>
                                        <button type="button" class="btn btn-sm btn-danger btn-delete-row">Delete</button>
                                    </div>

                                    <div class="form-group">
                                        <label>प्रश्न:</label>
                                        <textarea class="form-control txtQuestion" rows="2" placeholder="प्रश्न लिहा..."></textarea>
                                    </div>

                                    <div class="form-group">
                                        <label>उत्तर:</label>
                                        <input class="form-control txtAnswer" placeholder="उत्तर लिहा..." />
                                    </div>
                                </div>
                            </div>

                            <div class="text-right">
                                <button id="btnAddSubpoint" type="button" class="btn btn-success">+ उप मुद्दा जोडा</button>
                            </div>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <asp:Button ID="btnSaveAudit" runat="server" CssClass="btn btn-primary" Text="Save" OnClick="btnSaveAudit_Click" OnClientClick="prepareSubpointsForSave(); return true;" />
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                </div>

            </div>
        </div>
    </div>

    <!-- View Audit modal -->
    <div class="modal fade" id="auditFormModal" tabindex="-1" role="dialog" aria-labelledby="auditFormModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">लेखापरिक्षण अहवाल</h5>
                    <button type="button" class="btn btn-success download-btn" onclick="downloadPDF()">
                        <i class="fas fa-download"></i>Download PDF
                    </button>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <div class="audit-form-content" id="auditFormContent">
                                <div class="audit-form-header">
                                    <h4>वैयक्तिक लेखापरिक्षण अहवाल</h4>
                                    <h5 id="societyName" runat="server"></h5>
                                    <p id="societyAddress" runat="server"></p>
                                    <p id="societyPhone" runat="server"></p>
                                    <p>लेखापरिक्षण कालावधी</p>
                                    <p id="auditPeriod" runat="server"></p>
                                    <p><strong>लेखापरिक्षण वर्ग: 'ब'</strong></p>
                                </div>

                               <%-- <div class="society-info">
                                    <p><strong>सोसायटी माहिती:</strong></p>
                                    <div class="row">
                                        <div class="col-md-6">
                                            <p><strong>नाव:</strong> <span id="societyFullName" runat="server"></span></p>
                                            <p><strong>पत्ता:</strong> <span id="societyFullAddress" runat="server"></span></p>
                                        </div>
                                        <div class="col-md-6">
                                            <p><strong>दूरध्वनी:</strong> <span id="societyContactPhone" runat="server"></span></p>
                                            <p><strong>जिल्हा:</strong> <span id="societyDistrict" runat="server"></span></p>
                                        </div>
                                    </div>
                                </div>--%>
                                <div class="society-info">
    <p><strong>सोसायटी माहिती:</strong></p>

    <div class="row">
        <div class="col-md-6">
            <div class="info-row">
                <span class="info-label">नाव:</span>
                <span id="societyFullName" runat="server"></span>
            </div>

            <div class="info-row">
                <span class="info-label">पत्ता:</span>
                <span id="societyFullAddress" runat="server"></span>
            </div>
        </div>

        <div class="col-md-6">
            <div class="info-row">
                <span class="info-label">दूरध्वनी:</span>
                <span id="societyContactPhone" runat="server"></span>
            </div>

            <div class="info-row">
                <span class="info-label">जिल्हा:</span>
                <span id="societyDistrict" runat="server"></span>
            </div>
        </div>
    </div>
</div>


                                <asp:Repeater ID="rptHeaders" runat="server" OnItemDataBound="rptHeaders_ItemDataBound">
                                    <ItemTemplate>
                                        <div  class="main-point">
                                            <%# Eval("audt_header_desc") %>
                                        </div>
                                        <div class="ml-3">
                                            <asp:Repeater ID="rptQuestions" runat="server">
                                                <ItemTemplate>
                                                    <div class="question-item">
                                                        <div class="question-row">
                                                            <div class="question-label">
                                                                <strong><%# Container.ItemIndex + 1 %>)</strong> <%# Eval("question_desc") %>
                                                            </div>
                                                            <div class="answer-label">
                                                                <%# Eval("answer_desc") %>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </ItemTemplate>
                                            </asp:Repeater>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>

                                <div class="footer-section">
                                    <div class="signature-section">
                                        <div class="signature-left">
                                            <p><strong>दिनांक:</strong> <span id="auditDate" runat="server"></span></p>
                                        </div>
                                        <div class="signature-right">
                                            <p><strong>लेखापरिक्षकांची सही</strong></p>
                                            <div class="signature-line"></div>
                                        </div>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnviewAudit" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnAddNew" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                </div>

            </div>
        </div>
    </div>

    <!-- libs -->
<%--    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css">

    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>
    --%>
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>



    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>

    <!-- small helper JS: PDF generation (kept) -->
    <script>
        async function downloadPDF() {
            const element = document.getElementById('auditFormContent');
            try {
                const canvas = await html2canvas(element, {
                    scale: 3,
                    useCORS: true,
                    logging: false,
                    backgroundColor: '#ffffff',
                    allowTaint: true,
                    letterRendering: true
                });

                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pageWidth = 210, pageHeight = 297, margin = 15;
                const contentWidth = pageWidth - (2 * margin), contentHeight = pageHeight - (2 * margin);
                const imgWidth = contentWidth;
                const imgHeight = (canvas.height * imgWidth) / canvas.width;
                const totalPages = Math.ceil(imgHeight / contentHeight);
                const imgData = canvas.toDataURL('image/jpeg', 0.95);

                for (let page = 0; page < totalPages; page++) {
                    if (page > 0) pdf.addPage();
                    const sourceY = page * contentHeight * (canvas.width / imgWidth);
                    const sourceHeight = contentHeight * (canvas.width / imgWidth);

                    const pageCanvas = document.createElement('canvas');
                    pageCanvas.width = canvas.width;
                    pageCanvas.height = Math.min(sourceHeight, canvas.height - sourceY);

                    const pageCtx = pageCanvas.getContext('2d');
                    pageCtx.fillStyle = '#ffffff';
                    pageCtx.fillRect(0, 0, pageCanvas.width, pageCanvas.height);

                    pageCtx.drawImage(canvas, 0, sourceY, canvas.width, pageCanvas.height, 0, 0, canvas.width, pageCanvas.height);
                    const pageImgData = pageCanvas.toDataURL('image/jpeg', 0.95);

                    const heightToAdd = Math.min(contentHeight, imgHeight - (page * contentHeight));
                    pdf.addImage(pageImgData, 'JPEG', margin, margin, imgWidth, heightToAdd);
                }

                pdf.save('Audit_Report_' + new Date().getTime() + '.pdf');
            } catch (error) {
                console.error('Error generating PDF:', error);
                alert('त्रुटी: PDF तयार करताना समस्या आली. कृपया पुन्हा प्रयत्न करा.');
            }
        }
    </script>

    <!-- CLEAN, STABLE JS: bind handlers, survive UpdatePanel refresh -->
    <script type="text/javascript">
        function initAuditScripts() {

            // delegated toggle - works after DOM changes
            $(document).off("click", ".toggle-header").on("click", ".toggle-header", function () {
                $(this).next(".qa-body").slideToggle();
            });

            // sortable
            $("#sortableMain").sortable({
                cursor: "move",
                placeholder: "ui-sortable-placeholder",
                update: function () {
                    var items = [];
                    $("#sortableMain .sortable-item").each(function (index) {
                        items.push({
                            Id: $(this).data("id"),
                            SequenceOrder: index + 1
                        });
                    });
                    $("#<%= hfSequenceData.ClientID %>").val(JSON.stringify(items));
                    $("#<%= btnSaveSequence.ClientID %>").show();
                }
            });

            // add subpoint (client-side)
            $('#btnAddSubpoint').off('click').on('click', function () {
                var tpl = $('#subpointTemplate').html();
                $('#subpointsContainer').append(tpl);
                reIndexSubpoints();
            });

            // delete subpoint (works for both server and client rows)
            $('#subpointsContainer').off('click', '.btn-delete-row').on('click', '.btn-delete-row', function () {
                $(this).closest('.subpoint-row').remove();
                reIndexSubpoints();
            });
        }

        function reIndexSubpoints() {
            $('#subpointsContainer .subpoint-row').each(function (idx) {
                $(this).find('.row-index').text((idx + 1) + ')');
                // also update first strong if server-side row used
                $(this).find('strong').first().text((idx + 1) + ')');
            });
        }

        // Prepare JSON payload and put into hidden field before postback
        function prepareSubpointsForSave() {
            var items = [];
            $('#subpointsContainer .subpoint-row').each(function () {

                var qId = $(this).find("input[id*='hfQuesId']").val() || $(this).find('.hfQuesId').val() || '';
                var question = $(this).find("textarea[id*='txtQuestion']").val() || $(this).find('.txtQuestion').val() || '';
                var answer = $(this).find("input[id*='txtAnswer']").val() || $(this).find('.txtAnswer').val() || '';

                items.push({
                    audt_ques_id: qId,
                    question_desc: question,
                    answer_desc: answer
                });
            });

            var headerTitle = $('#<%= txtHeaderTitle.ClientID %>').val();
            var payload = {
                headerTitle: headerTitle,
                subpoints: items
            };

            $('#<%= hdSubpointsJson.ClientID %>').val(JSON.stringify(payload));
        }

        $(document).ready(function () {
            initAuditScripts();
        });

        // Re-run init after partial postbacks (UpdatePanel)
        if (typeof (Sys) !== "undefined" && Sys.WebForms && Sys.WebForms.PageRequestManager) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                initAuditScripts();
            });
        }
    </script>

</asp:Content>
