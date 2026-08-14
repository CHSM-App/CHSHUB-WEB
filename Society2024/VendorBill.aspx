<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="VendorBill.aspx.cs" MasterPageFile="~/Site.Master" Inherits="Society.VendorBill" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* Payment Section Styles */
        #pnlStaffPayment input[type="text"],
        #pnlStaffPayment input[type="date"],
        #pnlStaffPayment input[type="number"],
        #pnlStaffPayment textarea {
            transition: all 0.3s ease;
        }

            #pnlStaffPayment input:focus,
            #pnlStaffPayment textarea:focus {
                border-color: #667eea !important;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1) !important;
                outline: none;
            }

        #pnlStaffPayment .form-label {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-bottom: 8px;
        }

            #pnlStaffPayment .form-label i {
                font-size: 16px;
            }

        .staff-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            color: white;
        }

        .section-header {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid rgba(255, 255, 255, 0.2);
        }

            .section-header i {
                font-size: 32px;
                background: rgba(255, 255, 255, 0.2);
                padding: 15px;
                border-radius: 15px;
                backdrop-filter: blur(10px);
            }

            .section-header h3 {
                margin: 0;
                font-size: 28px;
                font-weight: 700;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
            }

        .form-group-modern {
            background: rgba(255, 255, 255, 0.95);
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 25px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
        }

            .form-group-modern label {
                color: #2d3748;
                font-weight: 600;
                font-size: 14px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 10px;
                display: block;
            }

        .dropdown-modern {
            width: 100%;
            padding: 15px 20px;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 16px;
            transition: all 0.3s ease;
            background: white;
            cursor: pointer;
        }

            .dropdown-modern:focus {
                border-color: #667eea;
                outline: none;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

        .staff-list-container {
            background: rgba(255, 255, 255, 0.95);
            padding: 30px;
            border-radius: 20px;
            margin-top: 25px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
        }

        .select-all-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            border-radius: 15px;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 12px;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
        }

            .select-all-box label {
                color: white;
                font-size: 16px;
                font-weight: 600;
                margin: 0;
                cursor: pointer;
            }

        .modern-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0 10px;
        }

            .modern-table thead th {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 18px 20px;
                text-align: left;
                font-weight: 600;
                text-transform: uppercase;
                font-size: 13px;
                letter-spacing: 1px;
                border: none;
            }

                .modern-table thead th:first-child {
                    border-radius: 12px 0 0 12px;
                }

                .modern-table thead th:last-child {
                    border-radius: 0 12px 12px 0;
                }

            .modern-table tbody tr {
                background: white;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
                transition: all 0.3s ease;
            }

                .modern-table tbody tr:hover {
                    transform: translateY(-3px);
                    box-shadow: 0 8px 20px rgba(102, 126, 234, 0.2);
                }

            .modern-table tbody td {
                padding: 20px;
                border: none;
                color: #2d3748;
                font-size: 15px;
            }

            .modern-table tbody tr td:first-child {
                border-radius: 12px 0 0 12px;
            }

            .modern-table tbody tr td:last-child {
                border-radius: 0 12px 12px 0;
            }

        .checkbox-modern {
            width: 24px;
            height: 24px;
            cursor: pointer;
            accent-color: #667eea;
        }

        .salary-input {
            width: 100%;
            max-width: 180px;
            padding: 12px 15px;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 600;
            color: #2d3748;
            transition: all 0.3s ease;
        }

            .salary-input:focus {
                border-color: #667eea;
                outline: none;
                box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
            }

        .total-display {
            background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
            padding: 25px 30px;
            border-radius: 15px;
            margin-top: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 8px 25px rgba(72, 187, 120, 0.3);
            animation: slideIn 0.5s ease;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(20px);
            }

            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .total-label {
            color: white;
            font-size: 18px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .total-amount {
            color: white;
            font-size: 32px;
            font-weight: 800;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
        }

        .currency-symbol {
            font-size: 24px;
            margin-right: 5px;
        }

        .staff-name {
            font-weight: 600;
            color: #2d3748;
        }

        .delete-btn {
            background: linear-gradient(135deg, #fc8181 0%, #f56565 100%);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 600;
        }

            .delete-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(245, 101, 101, 0.4);
            }

        .required {
            color: #fc8181;
            font-weight: bold;
        }
        /* Payment Section - Remove ALL separate scrolling */
        #paymentSection {
            display: none;
        }
            /* Remove modal-body styling from payment section */
            #paymentSection .modal-body,
            #paymentSection > div[class*="modal-body"] {
                max-height: none !important;
                overflow-y: visible !important;
                overflow: visible !important;
                padding: 0 !important;
                background: transparent !important;
                flex: none !important;
            }
        /* Main Modal Body - Single unified scroll */
        #billModal > .modal-dialog > .modal-content > .modal-body {
            padding: 24px;
            overflow-y: auto;
            flex: 1;
            max-height: calc(90vh - 140px);
        }
        /* Payment section containers - no overflow */
        #paymentSection div,
        #paymentSection > * {
            overflow: visible !important;
        }
        /* UpdatePanel inside payment section */
        #UpdatePanel2,
        #UpdatePanel2 > div {
            overflow: visible !important;
            max-height: none !important;
        }
        /* Payment info sections */
        #paymentSection .row {
            margin-bottom: 1rem;
        }
        /* Remove nested modal elements */
        #paymentSection .modal-header,
        #paymentSection .modal-footer {
            display: none !important;
        }
        /* Modal Backdrop */
        .SB-modal-backdrop {
            background: rgba(0, 0, 0, 0.5);
        }
        /* Modal Container */
        .SB-payment-summary-modal .modal-content {
            border-radius: 12px;
            border: none;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
            overflow: hidden;
        }
        /* Modal Header - Purple Gradient */
        .SB-payment-summary-modal .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 24px;
            border: none;
        }

        .SB-payment-summary-modal .modal-title {
            font-size: 18px;
            font-weight: 600;
            color: white;
            display: flex;
            align-items: center;
            gap: 10px;
        }

            .SB-payment-summary-modal .modal-title i {
                font-size: 20px;
            }

        .SB-payment-summary-modal .close {
            color: white;
            opacity: 0.9;
            text-shadow: none;
            font-size: 28px;
            font-weight: 300;
        }

            .SB-payment-summary-modal .close:hover {
                opacity: 1;
                color: white;
            }
        /* Modal Body */
        .SB-payment-summary-modal .modal-body {
            padding: 24px;
            background: #f8f9fa;
        }
        /* Section Headers */
        .SB-section-header {
            font-size: 14px;
            font-weight: 600;
            color: #333;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

            .SB-section-header::before {
                content: '';
                width: 4px;
                height: 18px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 2px;
            }
        /* Info Cards */
        .SB-info-card {
            background: white;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            border: 0.5px solid #0000802e;
        }

        .SB-info-row {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 12px;
        }

            .SB-info-row:last-child {
                margin-bottom: 0;
            }

        .SB-info-item {
            flex: 1;
            min-width: 200px;
        }

        .SB-info-label {
            font-size: 12px;
            color: #666;
            font-weight: 500;
            margin-bottom: 4px;
            display: block;
        }

        .SB-info-value {
            font-size: 14px;
            color: #333;
            font-weight: 500;
        }
        /* GridView Styling */
        .SB-bills-table {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            margin-bottom: 16px;
            border: 0.5px solid #0000802e;
        }

            .SB-bills-table table {
                margin: 0;
                width: 100%;
            }

            .SB-bills-table th {
                background: #f8f9fa;
                color: #555;
                font-size: 13px;
                font-weight: 600;
                padding: 12px 16px;
                border: none;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .SB-bills-table td {
                padding: 14px 16px;
                font-size: 14px;
                color: #333;
                border-bottom: 1px solid #f0f0f0;
            }

            .SB-bills-table tr:last-child td {
                border-bottom: none;
            }
        /* Total Amount */
        .SB-total-amount {
            background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
            border-radius: 8px;
            padding: 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }

        .SB-total-label {
            font-size: 14px;
            font-weight: 600;
            color: #555;
        }

        .SB-total-value {
            font-size: 20px;
            font-weight: 700;
            color: #667eea;
        }
        /* Modal Footer */
        .SB-payment-summary-modal .modal-footer {
            background: white;
            border-top: 1px solid #e0e0e0;
            padding: 16px 24px;
        }
        /* Buttons */
        .SB-btn-back {
            background: white;
            border: 2px solid #e0e0e0;
            color: #666;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.3s ease;
        }

            .SB-btn-back:hover {
                background: #f8f9fa;
                border-color: #ccc;
                color: #333;
            }

        .SB-btn-confirm {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            color: white;
            padding: 10px 24px;
            border-radius: 6px;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }

            .SB-btn-confirm:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
                color: white;
            }
        /* Status Badges */
        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 8px;
            color: white;
            font-size: 13px;
            font-weight: 600;
            text-align: center;
            min-width: 80px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

            .status-badge.pending {
                background-color: #6c757d;
            }

            .status-badge.partial {
                background-color: #ffc107;
                color: #212529;
            }

            .status-badge.paid {
                background-color: #28a745;
            }

            .status-badge.approved {
                background-color: #20c997;
            }

            .status-badge.rejected {
                background-color: #dc3545;
            }

            .status-badge.unknown {
                background-color: #adb5bd;
            }
        /* Responsive */
        @media (max-width: 768px) {
            .SB-info-item {
                min-width: 100%;
            }

            .SB-payment-summary-modal .modal-body {
                padding: 16px;
            }

            .SB-total-amount {
                flex-direction: column;
                gap: 8px;
                text-align: center;
            }
        }
        /* Modal Title */
        .reject-modal-title {
            margin: 0;
            padding: 24px 24px 16px;
            font-size: 22px;
            font-weight: 600;
            color: #1f2937;
            border-bottom: 1px solid #e5e7eb;
        }
        /* Modal Body */
        .reject-modal-body {
            padding: 24px;
        }
        /* Label */
        .reject-modal-label {
            display: block;
            margin-bottom: 10px;
            font-size: 14px;
            font-weight: 500;
            color: #374151;
        }
        /* TextBox */
        .reject-modal-textbox,
        #txtRejectReason {
            width: 100% !important;
            padding: 12px 14px !important;
            font-size: 14px !important;
            line-height: 1.5 !important;
            color: #1f2937 !important;
            background-color: #f9fafb !important;
            border: 1px solid #d1d5db !important;
            border-radius: 8px !important;
            transition: all 0.2s ease !important;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif !important;
            resize: vertical !important;
            min-height: 100px !important;
            box-sizing: border-box !important;
            pointer-events: auto !important;
        }

            .reject-modal-textbox:focus,
            #txtRejectReason:focus {
                outline: none !important;
                background-color: #ffffff !important;
                border-color: #3b82f6 !important;
                box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1) !important;
            }
        /* Modal Footer */
        .reject-modal-footer {
            padding: 16px 24px 24px;
            display: flex;
            justify-content: flex-end;
        }
        /* Submit Button */
        .reject-modal-btn {
            padding: 11px 24px;
            font-size: 14px;
            font-weight: 600;
            color: #ffffff;
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 2px 8px rgba(239, 68, 68, 0.2);
        }

            .reject-modal-btn:hover {
                background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
                box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
                transform: translateY(-1px);
            }

            .reject-modal-btn:active {
                transform: translateY(0);
                box-shadow: 0 2px 6px rgba(239, 68, 68, 0.3);
            }
        /* Animations */
        @keyframes fadeIn {
            from {
                opacity: 0;
            }

            to {
                opacity: 1;
            }
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }

            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        /* Responsive Design */
        @media (max-width: 576px) {
            .reject-modal-content {
                width: 95%;
                margin: 20px;
            }

            .reject-modal-title {
                font-size: 20px;
                padding: 20px 20px 14px;
            }

            .reject-modal-body {
                padding: 20px;
            }

            .reject-modal-footer {
                padding: 14px 20px 20px;
            }
        }
        /*------------------------------------------------------*/
        .grid-btn {
            padding: 6px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease-in-out;
            color: #fff;
        }
        /* Approve button */
        .btn-approve {
            background-color: #4CAF50;
        }

            .btn-approve:hover {
                background-color: #43a047;
                transform: translateY(-1px);
                box-shadow: 0 2px 6px rgba(67, 160, 71, 0.4);
            }
        /* Reject button */
        .btn-reject {
            background-color: #f44336;
        }

            .btn-reject:hover {
                background-color: #e53935;
                transform: translateY(-1px);
                box-shadow: 0 2px 6px rgba(229, 57, 53, 0.4);
            }
        /* Optional: space between buttons */
        .grid-btn + .grid-btn {
            margin-left: 6px;
        }

        .modal {
            z-index: 1055 !important;
        }

        .modal-backdrop {
            z-index: 1050 !important;
        }

        .content-wrapper {
            padding: 30px;
            max-width: 1400px;
            margin: 0 auto;
        }

        .bills-grid {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-bottom: none;
        }

            .modal-header .btn-close {
                filter: brightness(0) invert(1);
            }

        .section-header {
            background-color: #f8f9fa;
            padding: 12px 20px;
            border-left: 4px solid #667eea;
            margin-bottom: 20px;
            font-weight: 600;
            color: #495057;
        }

        .info-row {
            padding: 12px 0;
            border-bottom: 1px solid #e9ecef;
        }

        .info-label {
            color: #6c757d;
            font-weight: 500;
            font-size: 0.9rem;
        }

        .info-value {
            color: #212529;
            font-weight: 600;
        }

        .gridview-custom {
            width: 100%;
            border-collapse: collapse;
        }

            .gridview-custom th {
                background-color: #f8f9fa;
                color: #495057;
                font-weight: 600;
                padding: 12px;
                text-align: left;
                border-bottom: 2px solid #dee2e6;
                font-size: 0.9rem;
            }

            .gridview-custom td {
                padding: 12px;
                border-bottom: 1px solid #e9ecef;
                color: #495057;
            }

            .gridview-custom tr:hover {
                background-color: #f8f9fa;
            }

        .total-section {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            margin-top: 20px;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 0.95rem;
        }

        .grand-total {
            font-size: 1.2rem;
            font-weight: 700;
            color: #667eea;
            padding-top: 12px;
            border-top: 2px solid #dee2e6;
            margin-top: 8px;
        }

        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }

        .status-approved {
            background-color: #d4edda;
            color: #155724;
        }

        .status-rejected {
            background-color: #f8d7da;
            color: #721c24;
        }

        .btn-view {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            padding: 6px 16px;
            border-radius: 6px;
            color: white;
            font-weight: 500;
            transition: all 0.3s ease;
        }

            .btn-view:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
                color: white;
            }

        .modal-body {
            max-height: 70vh;
            overflow-y: auto;
        }

        .page-header {
            background: white;
            padding: 24px 28px;
            border-radius: 12px;
            margin-bottom: 24px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            border-bottom: 3px solid #2563eb;
        }

            .page-header h1 {
                font-size: 26px;
                font-weight: 600;
                margin-bottom: 4px;
                color: #1a1a1a;
                display: flex;
                align-items: center;
                gap: 12px;
            }

                .page-header h1 i {
                    color: #2563eb;
                }

            .page-header p {
                color: #6b7280;
                font-size: 14px;
            }

        .action-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            gap: 15px;
            flex-wrap: wrap;
        }

        .search-box {
            flex: 1;
            min-width: 300px;
            position: relative;
        }

            .search-box input {
                width: 100%;
                padding: 11px 45px 11px 15px;
                border: 1px solid #e5e7eb;
                border-radius: 8px;
                font-size: 14px;
                transition: all 0.2s;
                background: white;
            }

                .search-box input:focus {
                    outline: none;
                    border-color: #2563eb;
                    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
                }

        .search-icon {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
        }

        .btn {
            padding: 11px 20px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-family: 'Inter', sans-serif;
        }

        .btn-primary {
            background: #2563eb;
            color: white;
        }

            .btn-primary:hover {
                background: #1d4ed8;
                box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
            }

        .btn-success {
            background: #10b981;
            color: white;
        }

            .btn-success:hover {
                background: #059669;
            }

        .btn-danger {
            background: #ef4444;
            color: white;
        }

            .btn-danger:hover {
                background: #dc2626;
            }

        .btn-secondary {
            background: #6b7280;
            color: white;
        }

            .btn-secondary:hover {
                background: #4b5563;
            }

        .card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
            overflow: hidden;
            border: 1px solid #e5e7eb;
        }

        .table-container {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        thead {
            background: #f9fafb;
            border-bottom: 2px solid #e5e7eb;
        }

            thead th {
                padding: 14px 16px;
                text-align: left;
                font-weight: 600;
                font-size: 12px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                color: #6b7280;
            }

        tbody tr {
            border-bottom: 1px solid #f3f4f6;
            transition: background 0.15s;
        }

            tbody tr:hover {
                background: #f9fafb;
            }

        tbody td {
            padding: 12px 16px;
            font-size: 14px;
            color: #1a1a1a;
        }

        .action-icons {
            display: flex;
            gap: 12px;
        }

        .action-icon {
            cursor: pointer;
            color: #6b7280;
            transition: all 0.2s;
            font-size: 16px;
        }

            .action-icon:hover {
                color: #2563eb;
                transform: scale(1.1);
            }
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.4);
            backdrop-filter: blur(2px);
            animation: fadeIn 0.2s;
            overflow-y: auto;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
            }

            to {
                opacity: 1;
            }
        }

        .modal-content {
            background: white;
            margin: 3% auto;
            width: 95%;
            max-width: 1200px;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
            animation: slideDown 0.3s;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
        }

            .modal-content.modal-sm {
                max-width: 600px;
            }

        @keyframes slideDown {
            from {
                transform: translateY(-30px);
                opacity: 0;
            }

            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .modal-header {
            background: white;
            color: #1a1a1a;
            padding: 20px 24px;
            border-radius: 12px 12px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-shrink: 0;
            border-bottom: 1px solid #e5e7eb;
        }

            .modal-header h2 {
                font-size: 20px;
                font-weight: 600;
                display: flex;
                align-items: center;
                gap: 10px;
            }

                .modal-header h2 i {
                    color: #2563eb;
                }

        .close {
            color: #9ca3af;
            font-size: 28px;
            font-weight: 300;
            cursor: pointer;
            transition: all 0.2s;
            line-height: 1;
            width: 32px;
            height: 32px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 6px;
        }

            .close:hover {
                background: #f3f4f6;
                color: #1a1a1a;
            }

        .modal-body {
            padding: 24px;
            overflow-y: auto;
            flex: 1;
        }

        .form-section {
            background: #f9fafb;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #e5e7eb;
        }

            .form-section h3 {
                color: #1a1a1a;
                font-size: 16px;
                font-weight: 600;
                margin-bottom: 16px;
                padding-bottom: 12px;
                border-bottom: 2px solid #e5e7eb;
                display: flex;
                align-items: center;
                gap: 8px;
            }

                .form-section h3 i {
                    color: #2563eb;
                }

        .form-group {
            margin-bottom: 18px;
        }

            .form-group label {
                display: block;
                margin-bottom: 6px;
                font-weight: 500;
                color: #374151;
                font-size: 13px;
            }

            .form-group input,
            .form-group select,
            .form-group textarea {
                width: 100%;
                padding: 10px 14px;
                border: 1px solid #e5e7eb;
                border-radius: 8px;
                transition: all 0.2s;
                background: white;
                font-family: 'Inter', sans-serif;
            }

                .form-group input:focus,
                .form-group select:focus,
                .form-group textarea:focus {
                    outline: none;
                    border-color: #2563eb;
                    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
                }

        .form-row-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        .form-row-3 {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 16px;
        }

        .modal-footer {
            padding: 16px 24px;
            background: #f9fafb;
            border-radius: 0 0 12px 12px;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            flex-shrink: 0;
            border-top: 1px solid #e5e7eb;
        }

        .required {
            color: #dc2626;
            margin-left: 2px;
        }

        .btn-small {
            padding: 7px 14px;
            font-size: 13px;
        }

        .total-section {
            background: #f9fafb;
            padding: 16px;
            border-radius: 8px;
            margin-top: 16px;
            border: 1px solid #e5e7eb;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 14px;
            color: #374151;
        }

            .total-row.grand-total {
                border-top: 2px solid #e5e7eb;
                padding-top: 12px;
                margin-top: 8px;
                font-weight: 600;
                font-size: 18px;
                color: #2563eb;
            }

        .dropdown-container {
            position: relative;
        }

        .suggestion-list {
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 100;
            display: none;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            margin-top: 4px;
        }

        .suggestion-item {
            display: block;
            padding: 10px 14px;
            color: #1a1a1a;
            text-decoration: none;
            font-size: 14px;
            transition: background 0.15s;
        }

            .suggestion-item:hover {
                background: #f3f4f6;
            }

        .link-button {
            background: none;
            border: none;
            cursor: pointer;
            text-align: left;
        }

        .add-vendor-link {
            display: block;
            padding: 10px 14px;
            color: #2563eb;
            text-decoration: none;
            font-size: 14px;
            border-top: 1px solid #e5e7eb;
            transition: background 0.15s;
            font-weight: 500;
        }

            .add-vendor-link:hover {
                background: #eff6ff;
            }

            .add-vendor-link i {
                margin-right: 6px;
            }

        .items-grid-table {
            width: 100%;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            overflow: hidden;
        }

            .items-grid-table input {
                width: 100%;
                padding: 8px 10px;
                border: 1px solid #e5e7eb;
                border-radius: 6px;
                font-size: 13px;
            }

                .items-grid-table input:focus {
                    outline: none;
                    border-color: #2563eb;
                    box-shadow: 0 0 0 2px rgba(37, 99, 235, 0.1);
                }

                .items-grid-table input[readonly] {
                    background: #f9fafb;
                    color: #6b7280;
                }

        .status-badge {
            display: inline-block;
            padding: 10px 13px;
            border-radius: 8px;
            color: white;
            font-size: 13px;
            font-weight: 600;
            text-align: center;
            min-width: 100px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

            .status-badge.pending {
                background-color: #6c757d;
            }

            .status-badge.partial {
                background-color: #ffc107;
                color: #212529;
            }

            .status-badge.paid {
                background-color: #28a745;
            }

            .status-badge.approved {
                background-color: #20c997;
            }

            .status-badge.rejected {
                background-color: #dc3545;
            }

            .status-badge.unknown {
                background-color: #adb5bd;
            }

        .payment-btn {
            transition: all 0.3s ease;
            cursor: pointer;
            text-decoration: none !important;
            position: relative;
            display: flex !important;
            flex-direction: column;
            align-items: center;
            padding: 24px;
            border: 2px solid #e9ecef !important;
            border-radius: 12px;
            background: white !important;
        }

            .payment-btn i {
                font-size: 2.5rem;
                color: #6c757d;
                transition: all 0.3s ease;
            }

            .payment-btn span {
                font-weight: 600;
                color: #6c757d;
                margin-top: 12px;
                transition: all 0.3s ease;
            }

            .payment-btn:hover {
                border-color: #667eea !important;
                transform: translateY(-3px);
                box-shadow: 0 6px 20px rgba(102, 126, 234, 0.15) !important;
            }

                .payment-btn:hover i,
                .payment-btn:hover span {
                    color: #667eea !important;
                }
            /* Active State - THE KEY FIX */
            .payment-btn.active {
                border-color: #667eea !important;
                border-width: 3px !important;
                background: linear-gradient(135deg, #f8f9ff 0%, #f0f2ff 100%) !important;
                box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3) !important;
                transform: scale(1.02);
            }

                .payment-btn.active i {
                    color: #667eea !important;
                    transform: scale(1.1);
                }

                .payment-btn.active span {
                    color: #667eea !important;
                    font-weight: 700 !important;
                }
                /* Checkmark indicator */
                .payment-btn.active::after {
                    content: '✓';
                    position: absolute;
                    top: 10px;
                    right: 10px;
                    background: #667eea;
                    color: white;
                    border-radius: 50%;
                    width: 28px;
                    height: 28px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 16px;
                    font-weight: bold;
                    line-height: 28px;
                    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.4);
                    animation: popIn 0.3s ease;
                }

        @keyframes popIn {
            0% {
                transform: scale(0);
                opacity: 0;
            }

            50% {
                transform: scale(1.2);
            }

            100% {
                transform: scale(1);
                opacity: 1;
            }
        }
    </style>

    <div style="margin: 15px 30px;">
        <table width="100%">
            <tr>
                <th width="100%" class="">
                    <h1 class=" tex0 font-weight-bold " style="color: #012970;">Vendor Bill
                    </h1>
                </th>
            </tr>
        </table>


        <div class="form-group">
            <div class="row">
                <div class="col-12">
                    <div class="top-row d-flex align-items-center">
                        <div class="search-container">

                            <asp:TextBox ID="txt_search" CssClass="aspNetTextBox" placeHolder="Search bills..." AutoCompleteType="Disabled" runat="server" TextMode="Search" onkeyup="filterTable()" />

                            <!-- Calendar and Search Buttons -->
                            <div class="input-buttons">


                                <button id="btn_search" type="submit" class="search-button2" runat="server">
                                    <span class="material-symbols-outlined">search</span>
                                </button>
                            </div>
                        </div>

                        &nbsp;&nbsp;
						<button type="button" class="btn btn-primary" data-toggle="modal" data-target="#billModal" onclick="clearAndOpenBillModal()" >
                            <i class="fas fa-plus"></i>New Vendor Bill
                        </button>


                    </div>
                </div>

            </div>
        </div>


        <div class="card">
            <div style="width: 100%; overflow: visible;" class="table-container">
                <asp:GridView ID="gvBills" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered table-hover table-striped" GridLines="None" OnRowCommand="gvBills_RowCommand">
                    <%--<HeaderStyle CssClass="thead" />--%>
                    <HeaderStyle BackColor="lightblue" CssClass="sticky-header" />
                    <Columns>
                        <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                            <ItemTemplate>
                                <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="bill_number" HeaderText="Bill Number" />
                        <asp:BoundField DataField="bill_date" HeaderText="Bill Date" DataFormatString="{0:dd-MMM-yyyy}" />
                        <asp:BoundField DataField="vendor_name" HeaderText="Vendor" />
                        <asp:BoundField DataField="total_amount" HeaderText="Amount" DataFormatString="₹{0:N2}" />
                        <asp:BoundField DataField="remaining_amount" HeaderText="Remaining " DataFormatString="₹{0:N2}" />
                        <asp:TemplateField HeaderText="Status">
                            <ItemTemplate>
                                <%# Eval("payment_status") %>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Pay">
                            <ItemTemplate>
                                <asp:Button
                                    ID="btnPay"
                                    runat="server"
                                    Text="Pay"
                                    CssClass="btn btn-success btn-sm"
                                    CommandArgument='<%# Eval("bill_id") + "," + (Eval("vendor_id") ?? "0") %>'
                                    OnClick="btnPay_Click"
                                    Visible='<%# 
                Eval("payment_status") != null && 
                (
                    Eval("payment_status").ToString() == "Pending" || 
                    Eval("payment_status").ToString() == "Partially Paid" || 
                    Eval("payment_status").ToString() == "Unpaid"
                ) 
            %>' />
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Payment Info">
                            <ItemTemplate>
                                <asp:Button ID="btnView" runat="server" Text="View" CssClass="btn btn-sm btn-info" CommandName="ViewDetails" CommandArgument='<%# Eval("bill_id") %>' />
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Actions">
                            <ItemTemplate>
                                <div class="action-icons">
                                    <asp:LinkButton ID="lnkEdit" runat="server" OnCommand="viewBill" CommandArgument='<%# Eval("bill_id") %>' Text="Edit" CssClass="btn btn-primary btn-sm">
										<i class="fas fa-eye action-icon" style="color:white" title="View"></i>
                                    </asp:LinkButton>
                                </div>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </div>

    <!-- Add/Edit Vendor Bill Modal -->
    <div id="billModal" class="modal fade" data-keyboard="false" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <!-- You can change modal-lg to modal-xl if needed -->
            <div class="modal-content">

                <!-- Modal Header -->
                <div class="modal-header">
                    <h2><i class="fas fa-file-invoice-dollar"></i><span id="modalTitle">New Vendor Bill</span></h2>
                    <%-- <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>--%>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close" onclick="clearBillModal();">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <asp:HiddenField ID="hdnBillId" runat="server" Value="0" />
                            <asp:HiddenField runat="server" ID="vendor_name_id" Value="0" />
                            <asp:HiddenField ID="HiddenField1" runat="server" />
                            <asp:HiddenField ID="hdnItemsData" runat="server" />

                            <asp:HiddenField ID="hdnSubtotal" runat="server" />
                            <asp:HiddenField ID="hdnTax" runat="server" />
                            <asp:HiddenField ID="hdnGrandTotal" runat="server" />
                            <asp:HiddenField ID="society_id" runat="Server"></asp:HiddenField>
                            <asp:HiddenField ID="staff_id" runat="Server"></asp:HiddenField>
                            <asp:HiddenField ID="build_id" runat="server" />
                            <asp:HiddenField ID="role_id" runat="server" />

                            <asp:HiddenField ID="society_name" runat="server" />
                            <asp:HiddenField ID="vendor_id" runat="server" />
                            <asp:HiddenField ID="hdnPaymentSectionHidden" runat="server" Value="false" />




                            <!-- Basic Bill Information -->
                            <div class="form-section">
                                <h3><i class="fas fa-info-circle"></i>Bill Information</h3>
                                <div class="form-row-3">

                                    <div class="form-group" id="billNumberDiv" runat="server" style="display: none;">
                                        <label>Bill Number <span class="required">*</span></label>
                                        <asp:TextBox ID="txtBillNumber" runat="server" CssClass="form-control" placeholder="Enter bill number"></asp:TextBox>
                                    </div>

                                    <div class="form-group" id="billDateDiv" runat="server" style="display: none;">
                                        <label>Bill Date <span class="required">*</span></label>
                                        <asp:TextBox ID="txtBillDate" runat="server" TextMode="Date"></asp:TextBox>
                                    </div>

                                    <div class="form-group" id="paymentMonthDiv" runat="server" style="display: none;">
                                        <label>Payment Month <span class="required">*</span></label>
                                        <asp:TextBox ID="txtPaymentMonth" runat="server" TextMode="Date"></asp:TextBox>
                                    </div>

                                    <div class="form-group">
                                        <label>Payment Type <span class="required">*</span></label>
                                        <asp:DropDownList ID="ddlSevice" runat="server" required="required" AutoPostBack="True" OnSelectedIndexChanged="ddlSevice_SelectedIndexChanged">
                                            <asp:ListItem Text="Select"></asp:ListItem>
                                            <asp:ListItem Text="Staff Payment" Value="0"></asp:ListItem>
                                            <asp:ListItem Text="Daily Expense" Value="1"></asp:ListItem>
                                            <asp:ListItem Text="Vendor-Inventory Payment" Value="2"></asp:ListItem>
                                            <asp:ListItem Text="Vendor-Service Payment" Value="3"></asp:ListItem>
                                        </asp:DropDownList>
                                    </div>

                                </div>
                            </div>


                            <!-- Vendor Information -->
                            <!-- Vendor Information -->
                            <div id="vendorSection" runat="server" class="form-section" style="display: none;">
                                <h3><i class="fas fa-truck"></i>Vendor Details</h3>
                                <div class="form-row-2">

                                    <!-- Vendor Name -->
                                    <div class="form-group">
                                        <label>Vendor name</label>
                                        <div class="dropdown-container">
                                            <asp:TextBox ID="TextBox2" runat="server" CssClass="form-control"
                                                placeholder="Select vendor" autocomplete="off"
                                                onfocus="showVendorDropdown();" />

                                            <asp:Panel ID="drp_Container" runat="server" ClientIDMode="Static" Style="display: block;">
                                                <div id="RepeaterContainer1" class="suggestion-list" style="width: 100%;">
                                                    <asp:Repeater ID="Repeater1" runat="server" OnItemCommand="CategoryRepeater_ItemCommand1">
                                                        <ItemTemplate>
                                                            <asp:LinkButton
                                                                ID="lnkCategory"
                                                                runat="server"
                                                                CssClass="suggestion-item"
                                                                Text='<%# Eval("vendor_name") + " (" + Eval("service_type") + ")" %>'
                                                                CommandArgument='<%# Eval("vendor_id") %>'
                                                                CommandName='<%# Eval("gst_no") %>' />
                                                        </ItemTemplate>
                                                    </asp:Repeater>
                                                </div>
                                            </asp:Panel>
                                        </div>
                                        <div style="margin-top: 8px;">
                                            <button type="button" class="btn btn-sm btn-success" onclick="showModal('addVendorModal');">
                                                <i class="fas fa-plus"></i>Add Vendor
                                            </button>
                                        </div>
                                    </div>

                                    <!-- GST Number -->
                                    <div class="form-group">
                                        <label>GST Number</label>
                                        <asp:TextBox ID="TextBox1" CssClass="form-control" runat="server"
                                            placeholder="GST Registration No" ReadOnly="true" />
                                    </div>

                                </div>
                            </div>



                            <!-- Service Section (shown only when Service Type is Service) -->
                            <div class="form-section" id="serviceSection" runat="server" style="display: none;">
                                <div>
                                    <h3><i class="fas fa-briefcase"></i>Service Details</h3>
                                    <div class="form-row-2">
                                        <div class="form-group">
                                            <label>Service Description</label>
                                            <asp:TextBox ID="txtServiceDescription" CssClass="form-control" runat="server" TextMode="MultiLine" Rows="4" placeholder="Enter detailed service description"></asp:TextBox>
                                        </div>
                                        <div class="form-group">
                                            <label>Service Cost </span></label>
                                            <asp:TextBox ID="txtServiceCost" runat="server" TextMode="Number" step="0.01" placeholder="0.00"></asp:TextBox>
                                        </div>
                                    </div>
                                </div>
                            </div>


                            <div class="staff-sectionn" id="staff" runat="server" style="display: none;">
                                <div class="section-header">
                                    <i class="fas fa-users"></i>
                                    <h3>Staff Management</h3>
                                </div>

                                <div class="form-group-modern">
                                    <label>Select Staff Type </label>
                                    <asp:DropDownList ID="ddlStaffType" runat="server" CssClass="dropdown-modern" AutoPostBack="True" OnSelectedIndexChanged="ddlStaffType_SelectedIndexChanged">
                                        <asp:ListItem Text="-- Choose Staff Type --" Value=""></asp:ListItem>
                                    </asp:DropDownList>
                                </div>

                                <!-- Staff List with Checkboxes and Editable Salary -->
                                <asp:Panel ID="pnlStaffList" runat="server" Visible="false">
                                    <div class="staff-list-container">
                                        <%-- <div class="select-all-box">
                                            <asp:CheckBox ID="chkSelectAllStaff" runat="server" CssClass="checkbox-modern" AutoPostBack="true" OnCheckedChanged="chkSelectAllStaff_CheckedChanged" />
                                            <label for="<%= chkSelectAllStaff.ClientID %>">
                                                <i class="fas fa-check-double"></i>Select All Staff Members
                                            </label>
                                        </div>--%>

                                        <asp:UpdatePanel ID="upStaffList" runat="server" UpdateMode="Conditional">
                                            <ContentTemplate>
                                                <asp:GridView ID="gvStaffList" runat="server" AutoGenerateColumns="false" CssClass="modern-table" GridLines="None" ShowHeader="true" OnRowDataBound="gvStaffList_RowDataBound">
                                                    <Columns>
                                                        <asp:TemplateField HeaderText="staff_id" Visible="false">
                                                            <ItemTemplate>
                                                                <asp:Label runat="server" ID="lblStaffId" Text='<%# Bind("staff_id")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>

                                                        <asp:TemplateField HeaderText="Select">
                                                            <ItemTemplate>
                                                                <asp:CheckBox runat="server" ID="chkStaff" CssClass="checkbox-modern" AutoPostBack="true" OnCheckedChanged="chkStaff_CheckedChanged" />
                                                            </ItemTemplate>
                                                        </asp:TemplateField>

                                                        <asp:TemplateField HeaderText="Staff Name">
                                                            <ItemTemplate>
                                                                <div class="staff-name">
                                                                    <i class="fas fa-user-circle" style="margin-right: 8px; color: #667eea;"></i>
                                                                    <asp:Label runat="server" ID="lblStaffName" Text='<%# Bind("name")%>'></asp:Label>
                                                                </div>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>

                                                        <asp:TemplateField HeaderText="Salary Amount">
                                                            <ItemTemplate>
                                                                <asp:TextBox runat="server" ID="txtSalary" Text='<%# Bind("salary")%>' CssClass="salary-input" AutoPostBack="true" placeholder="Enter amount" OnTextChanged="txtSalary_TextChanged" ReadOnly="true">
                                                                </asp:TextBox>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                    </Columns>
                                                </asp:GridView>

                                                <!-- Selected Staff Total -->
                                                <div class="total-display">
                                                    <div class="total-label">
                                                        <i class="fas fa-calculator"></i>Total Selected Salary
                                                    </div>
                                                    <div class="total-amount">
                                                        <span class="currency-symbol">₹</span>
                                                        <asp:Label ID="lblSelectedTotal" runat="server" Text="0.00"></asp:Label>
                                                    </div>
                                                </div>
                                            </ContentTemplate>
                                            <Triggers>
                                                <asp:AsyncPostBackTrigger ControlID="ddlStaffType" EventName="SelectedIndexChanged" />
                                                <%--    <asp:AsyncPostBackTrigger ControlID="chkSelectAllStaff" EventName="CheckedChanged" />--%>
                                            </Triggers>
                                        </asp:UpdatePanel>
                                    </div>
                                </asp:Panel>


                            </div>


                            <!-- Bill Items -->

                            <div class="form-section" id="itemSection" runat="server" style="display: none;">
                                <h3><i class="fas fa-list"></i>Bill Items</h3>

                                <table class="items-grid-table">
                                    <thead>
                                        <tr>
                                            <th style="width: 30%">Description</th>
                                            <th style="width: 15%">Quantity</th>
                                            <th style="width: 15%">Unit Price</th>
                                            <th style="width: 10%">Tax %</th>
                                            <th style="width: 15%">Warranty<br>
                                                (in month)</th>
                                            <th style="width: 20%">Amount</th>
                                            <th style="width: 10%">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody id="itemsTableBody">
                                        <!-- Items will be added here dynamically -->
                                    </tbody>
                                </table>

                                <button type="button" class="btn btn-success btn-small" onclick="addNewItem()" style="margin-top: 12px;">
                                    <i class="fas fa-plus"></i>Add New Item
                                </button>

                                <div class="total-section">
                                    <div class="total-row">
                                        <span>Subtotal:</span>
                                        <span>₹ <span id="subtotalAmount">0.00</span></span>
                                    </div>
                                    <div class="total-row">
                                        <span>Tax:</span>
                                        <span>₹ <span id="taxAmount">0.00</span></span>
                                    </div>
                                    <div class="total-row grand-total">
                                        <span>Grand Total:</span>
                                        <span>₹ <span id="grandTotal">0.00</span></span>
                                    </div>
                                </div>

                                <asp:HiddenField ID="hdnTotalAmount" runat="server" Value="0" />

                            </div>


                            <!-- Approvers Section -->
                            <div id="approvelSection" runat="server" style="display: none;">
                                <div class="form-section" runat="server">
                                    <h3><i class="fas fa-user-check"></i>Approval Workflow</h3>
                                    <div class="form-row-2">
                                        <div class="form-group">
                                            <label>&nbsp;</label>
                                            <button type="button" class="btn btn-success" onclick="showModal('approversModal')">
                                                <i class="fas fa-user-plus"></i>Add Approver
                                            </button>
                                        </div>
                                    </div>
                                    <div id="approversList">
                                        <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                            <ContentTemplate>


                                                <asp:GridView ID="GridView3" runat="server" AutoGenerateColumns="false" OnRowDeleting="GridView3_RowDeleting" OnRowDataBound="GridView3_RowDataBound" OnRowCommand="GridView3_RowCommand" GridLines="None" CssClass="table">

                                                    <Columns>

                                                        <asp:TemplateField HeaderText="user_id" Visible="false">
                                                            <ItemTemplate>
                                                                <asp:Label runat="server" ID="user_id" Text='<%# Bind("user_id")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>

                                                        <asp:TemplateField HeaderText="Approvers">
                                                            <ItemTemplate>
                                                                <asp:Label runat="server" ID="name1" Text='<%# Bind("name")%>'></asp:Label>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>


                                                        <asp:TemplateField ItemStyle-Width="20">
                                                            <ItemTemplate>
                                                                <asp:LinkButton runat="server" ID="edit551" CommandName="Delete" OnClientClick="return confirm('Are you sure want to delete?');">
																	<i class="fas fa-trash action-icon"></i>
                                                                </asp:LinkButton>
                                                            </ItemTemplate>
                                                        </asp:TemplateField>
                                                    </Columns>
                                                </asp:GridView>
                                            </ContentTemplate>
                                            <Triggers>
                                                <asp:AsyncPostBackTrigger ControlID="btn_confirm" EventName="Click" />
                                            </Triggers>
                                        </asp:UpdatePanel>
                                    </div>
                                    <asp:HiddenField ID="hdnApprovers" runat="server" />

                                </div>
                                <label>Description <span style="color: red;">*</span></label>

                                <asp:TextBox ID="txtDesc" CssClass="form-control" runat="server" TextMode="MultiLine" Rows="3" placeholder="Add Description"></asp:TextBox>
                            </div>

                            <div id="paymentSection" runat="server" style="display: none;">

                                <asp:UpdatePanel ID="UpdatePanel2" runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <asp:HiddenField runat="server" ID="HiddenField2" />
                                        <asp:HiddenField runat="server" ID="HiddenField3" />
                                        <asp:HiddenField ID="hdnActivePayment" runat="server" ClientIDMode="Static" />
                                        <div style="background: #f8f9fa; padding: 24px 0; margin-top: 20px;">


                                            <!-- Payment Mode -->
                                            <div style="background: white; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
                                                <h6 style="font-size: 15px; font-weight: 600; margin-bottom: 16px;">
                                                    <i class="fas fa-credit-card" style="color: #667eea;"></i>Select Payment Mode
                                                </h6>
                                                <div class="row">
                                                    <div class="col-md-4 mb-2">
                                                        <!-- Cheque Button -->

                                                        <asp:LinkButton ID="btncheque" runat="server" CssClass="payment-btn w-100"
                                                            OnClick="btncheque_Click"
                                                            OnClientClick="collectItemsData(); if(!togglePaymentMode(this.id, 'cheque')) return false; updatePaymentAmount('cheque'); return true;">
    <i class="fas fa-money-check" style="font-size: 2.5rem; color: #6c757d;"></i>
    <span style="font-weight: 600; color: #6c757d; margin-top: 12px;">Cheque Payment</span>
</asp:LinkButton>
                                                    </div>
                                                    <div class="col-md-4 mb-2">
                                                        <asp:LinkButton ID="btnonline" runat="server" CssClass="payment-btn w-100"
                                                            OnClick="btnonline_Click"
                                                            OnClientClick="collectItemsData(); if(!togglePaymentMode(this.id, 'online')) return false; updatePaymentAmount('online'); return true;">
    <i class="fas fa-mobile-alt" style="font-size: 2.5rem; color: #6c757d;"></i>
    <span style="font-weight: 600; color: #6c757d; margin-top: 12px;">Online/UPI</span>
</asp:LinkButton>
                                                    </div>
                                                    <div class="col-md-4 mb-2">
                                                        <asp:LinkButton ID="btncash" runat="server" CssClass="payment-btn w-100"
                                                            OnClick="btncash_Click"
                                                            OnClientClick="collectItemsData(); if(!togglePaymentMode(this.id, 'cash')) return false; updatePaymentAmount('cash'); return true;">
    <i class="fas fa-coins" style="font-size:2.5rem; color:#6c757d;"></i>
    <span style="font-weight:600; color:#6c757d; margin-top:12px;">Cash</span>
</asp:LinkButton>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Payment Details -->

                                            <div style="background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px;">
                                                <h6 style="font-size: 15px; font-weight: 600; margin-bottom: 20px;">
                                                    <i class="fas fa-file-invoice-dollar" style="color: #667eea;"></i>Payment Details
                                                </h6>

                                                <!-- Online Payment -->
                                                <asp:Panel ID="panelonline" runat="server" Visible="False">
                                                    <div class="row">
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-hashtag"></i>Transaction Reference <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txttrasaction" runat="server" CssClass="form-control" placeholder="Enter UPI/NEFT/RTGS Reference"></asp:TextBox>
                                                        </div>
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtonlineamount" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </asp:Panel>

                                                <!-- Cheque Payment -->
                                                <asp:Panel ID="Panelcheque" runat="server" Visible="false">
                                                    <div class="row">
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-hashtag"></i>Cheque Number <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtcheqno" runat="server" CssClass="form-control" placeholder="Enter cheque number"></asp:TextBox>
                                                        </div>
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="far fa-calendar-alt"></i>Cheque Date <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtcheqdate" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                    <div class="row">
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-university"></i>Bank Name <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtbank" runat="server" CssClass="form-control" placeholder="Enter bank name"></asp:TextBox>
                                                        </div>
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtcheqamount" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </asp:Panel>
                                                <!-- Cheque Payment -->
                                                <asp:Panel ID="Panelcash" runat="server" Visible="false">
                                                    <div class="row">
                                                        <div class="col-md-6 mb-3">
                                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                                            <asp:TextBox ID="txtcashamount" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                                        </div>
                                                    </div>
                                                </asp:Panel>

                                                <!-- Remarks -->
                                                <div class="mb-3">
                                                    <label class="form-label"><i class="fas fa-comment-dots"></i>Remarks (Optional)</label>
                                                    <asp:TextBox ID="txtre" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Add notes..."></asp:TextBox>
                                                </div>

                                                <!-- File Upload -->
                                                <div class="mb-0">
                                                    <label class="form-label"><i class="fas fa-file-upload"></i>Payment Proof <span style="color: #e74c3c;"></span></label>
                                                    <asp:FileUpload ID="FileUpload2" runat="server" accept=".pdf,.jpg,.jpeg,.png" CssClass="form-control" onchange="validateFileSize(this)" />
                                                    <small class="text-muted"><i class="fas fa-info-circle"></i>Upload receipt (PDF, JPG, PNG - Max 10 MB)</small>
                                                </div>
                                            </div>

                                            <!-- Message -->
                                            <asp:Label ID="Label11" runat="server" CssClass="alert" Visible="False"></asp:Label>
                                        </div>

                                    </ContentTemplate>
                                    <Triggers>
                                        <asp:AsyncPostBackTrigger ControlID="btnPayChequeMode" EventName="Click" />
                                        <asp:AsyncPostBackTrigger ControlID="btnPayOnlineMode" EventName="Click" />
                                        <asp:AsyncPostBackTrigger ControlID="btnSavePayment" EventName="Click" />
                                    </Triggers>
                                </asp:UpdatePanel>

                            </div>





                            <div class="form-group" style="margin-top: 16px;">


                                <label>Notes/Remarks</label>
                                <asp:TextBox ID="txtNotes" runat="server" TextMode="MultiLine" Rows="3" placeholder="Add any additional notes or remarks"></asp:TextBox>
                            </div>

                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnSaveVendor" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="ddlSevice" EventName="SelectedIndexChanged" />
                    </Triggers>
                </asp:UpdatePanel>
                <div class="modal-footer">

                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <asp:Button ID="btnSave" runat="server" Text="Save Bill" CssClass="btn btn-primary" OnClick="btnSave_Click" OnClientClick="collectItemsData(); return validateForm();" />
                    <%-- <asp:Button ID="btnSave" runat="server" Text="Save Bill" CssClass="btn btn-primary" OnClick="btnSave_Click" OnClientClick="return validateForm();" />--%>
                </div>

            </div>
        </div>
    </div>

    <!-- Add Vendor Modal -->
    <div id="addVendorModal" class="modal" data-keyboard="false" tabindex="-1" aria-hidden="true">
        <div class="modal-content modal-sm">
            <div class="modal-header">
                <h2><i class="fas fa-truck"></i>Add New Vendor</h2>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <asp:UpdatePanel ID="upAddVendor" runat="server" UpdateMode="Conditional">
                <ContentTemplate>
                    <div class="modal-body">
                        <div class="form-group">
                            <label>Vendor Name <span class="required">*</span></label>
                            <asp:TextBox ID="txtNewVendorName" runat="server" placeholder="Enter vendor name"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>Contact Number</label>
                            <asp:TextBox ID="txtNewVendorContact" runat="server" placeholder="Enter contact number" MaxLength="10" TextMode="Phone"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>Email</label>
                            <asp:TextBox ID="txtNewVendorEmail" runat="server" placeholder="vendor@example.com"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>GST Number</label>
                            <asp:TextBox ID="txtNewVendorGST" runat="server" placeholder="GST Registration No"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>Contact Person</label>
                            <asp:TextBox ID="txtContactPerson" runat="server" placeholder="Enter Contact Person name"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>Service Type</label>
                            <asp:TextBox ID="txtServiceType" runat="server" placeholder="Enter type of Service"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label>Address</label>
                            <asp:TextBox ID="txtNewVendorAddress" runat="server" TextMode="MultiLine" Rows="3" placeholder="Enter complete address"></asp:TextBox>
                        </div>
                    </div>
                </ContentTemplate>

            </asp:UpdatePanel>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <asp:Button ID="btnSaveVendor" runat="server" Text="Save Vendor" OnClick="btnSaveVendor_Click" CssClass="btn btn-primary" OnClientClick="return validateVendorForm();" />
            </div>

        </div>
    </div>

    <!-- Approvers Selection Modal -->
    <div class="modal fade" id="approversModal" tabindex="-1" role="dialog" aria-labelledby="approversModalLabel" aria-hidden="true" data-backdrop="static" data-keyboard="false">
        <div class="modal-dialog modal-sm" role="document">
            <div class="modal-content">

                <!-- Modal Header -->
                <div class="modal-header">
                    <h5 class="modal-title" id="approversModalLabel">
                        <i class="fas fa-user-check"></i>Select Approvers
                    </h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <!-- Modal Body -->
                <asp:UpdatePanel ID="upApprovers" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">

                            <div class="form-group d-flex align-items-center">
                                <label class="mb-0 mr-2">Select All</label>
                                <asp:CheckBox ID="CheckAll" runat="server" AutoPostBack="true" OnCheckedChanged="CheckAll_CheckedChanged" />
                            </div>

                            <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="false" OnRowDataBound="GridView2_RowDataBound" CssClass="table table-bordered table-hover table-sm" GridLines="None" ShowHeader="true">
                                <Columns>
                                    <asp:TemplateField HeaderText="user_id" Visible="false">
                                        <ItemTemplate>
                                            <asp:Label runat="server" ID="user_id" Text='<%# Bind("user_id")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:TemplateField HeaderText="Name">
                                        <ItemTemplate>
                                            <asp:Label runat="server" ID="name" Text='<%# Bind("name")%>'></asp:Label>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Select">
                                        <ItemTemplate>
                                            <asp:CheckBox runat="server" ID="chk" AutoPostBack="true" OnCheckedChanged="name_CheckedChanged" />
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                            </asp:GridView>

                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>

                <!-- Modal Footer -->
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    <asp:Button ID="btn_confirm" runat="server" Text="Confirm" CssClass="btn btn-primary" OnClick="btn_confirm_Click" UseSubmitBehavior="true" />
                </div>

            </div>
        </div>
    </div>


    <!-- view bills -->
    <div class="modal fade" id="billModal2" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-file-invoice"></i>Vendor Bill Details
                    </h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <div class="modal-body">
                    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                        <ContentTemplate>

                            <!-- Bill Information -->
                            <div class="section-header">
                                <i class="fas fa-info-circle"></i>Bill Information
                            </div>
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="info-row">
                                        <div class="info-label">Bill Number</div>
                                        <div class="info-value">
                                            <asp:Label ID="lblBillNumber" runat="server" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="info-row">
                                        <div class="info-label">Bill Date</div>
                                        <div class="info-value">
                                            <asp:Label ID="lblBillDate" runat="server" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="info-row">
                                        <div class="info-label">Service Type</div>
                                        <div class="info-value">
                                            <asp:Label ID="lblServiceType" runat="server" />
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Vendor Details -->
                            <div class="section-header mt-4">
                                <i class="fas fa-building"></i>Vendor Details
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="info-row">
                                        <div class="info-label">Vendor Name</div>
                                        <div class="info-value">
                                            <asp:Label ID="lblVendorName" runat="server" />
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="info-row">
                                        <div class="info-label">GST Number</div>
                                        <div class="info-value">
                                            <asp:Label ID="lblGSTNumber" runat="server" />
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Service Details -->
                            <asp:Panel runat="server" ID="servicePanel" Visible="false">
                                <div class="section-header mt-4">
                                    <i class="fas fa-tasks"></i>Service Details
                                </div>
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="info-row">
                                            <div class="info-label">Service Description</div>
                                            <div class="info-value">
                                                <asp:Label ID="lblServiceDescription" runat="server" />
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="info-row">
                                            <div class="info-label">Service Cost</div>
                                            <div class="info-value">
                                                <asp:Label ID="lblServiceCost" runat="server" />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </asp:Panel>
                            <asp:Panel runat="server" ID="billItems">
                                <!-- Bill Items -->
                                <div class="section-header mt-4">
                                    <i class="fas fa-list"></i>Bill Items
                                </div>
                                <div class="table-responsive">
                                    <asp:GridView ID="gvBillItems" runat="server" AutoGenerateColumns="False" CssClass="gridview-custom" GridLines="None">
                                        <Columns>
                                            <asp:BoundField DataField="item_name" HeaderText="Name" />
                                            <asp:BoundField DataField="quantity" HeaderText="Quantity" />
                                            <asp:BoundField DataField="purchase_cost" HeaderText="Unit Price" DataFormatString="₹ {0:N2}" />
                                            <asp:BoundField DataField="tax" HeaderText="Tax %" />
                                            <asp:BoundField DataField="warranty" HeaderText="Warranty(in month)" />
                                            <asp:TemplateField HeaderText="Amount">
                                                <ItemTemplate>
                                                    <%# 
                                                    Eval("purchase_cost") != DBNull.Value && Eval("quantity") != DBNull.Value && Eval("tax") != DBNull.Value
                                                        ? string.Format("₹ {0:N2} <br/><span style='color:#6b7280;font-size:12px;'>(Tax: ₹ {1:N2})</span>",
                                                            Convert.ToDecimal(Eval("purchase_cost")) * Convert.ToDecimal(Eval("quantity")) + 
                                                            (Convert.ToDecimal(Eval("purchase_cost")) * Convert.ToDecimal(Eval("quantity")) * Convert.ToDecimal(Eval("tax")) / 100),
                                                            (Convert.ToDecimal(Eval("purchase_cost")) * Convert.ToDecimal(Eval("quantity")) * Convert.ToDecimal(Eval("tax")) / 100)
                                                        )
                                                        : "₹ 0.00"
                                                    %>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                        </Columns>
                                    </asp:GridView>
                                </div>

                                <!-- Totals -->
                                <div class="total-section">
                                    <div class="total-row">
                                        <span>Subtotal:</span>
                                        <span><strong>
                                            <asp:Label ID="lblSubtotal" runat="server" />
                                        </strong></span>
                                    </div>
                                    <div class="total-row">
                                        <span>Tax:</span>
                                        <span><strong>
                                            <asp:Label ID="lblTax" runat="server" />
                                        </strong></span>
                                    </div>
                                    <div class="total-row grand-total">
                                        <span>Grand Total:</span>
                                        <span>
                                            <asp:Label ID="lblGrandTotal" runat="server" />
                                        </span>
                                    </div>
                                </div>

                                <!-- Approvals -->
                                <div class="section-header mt-4">
                                    <i class="fas fa-check-circle"></i>Approval Workflow
                                </div>
                                <div class="table-responsive">
                                    <asp:GridView ID="gvApprovals" runat="server" AutoGenerateColumns="False" CssClass="gridview-custom" GridLines="None" OnRowDataBound="GridView1_RowDataBound" OnRowCommand="gvApprovals_RowCommand">

                                        <Columns>
                                            <asp:TemplateField HeaderText="No" ItemStyle-Width="50">
                                                <ItemTemplate>
                                                    <asp:Label ID="lblRowNumber" Text='<%# Container.DataItemIndex + 1 %>' runat="server" />
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:BoundField DataField="name" HeaderText="Approver" />

                                            <asp:TemplateField HeaderText="Approval Status">
                                                <ItemTemplate>
                                                    <asp:Label ID="lblStatus" runat="server" Text='<%# 
                                                        Eval("approval_status").ToString() == "1" ? "Pending" :
                                                        Eval("approval_status").ToString() == "2" ? "Approved" :
                                                        Eval("approval_status").ToString() == "4" ? "Rejected" :
                                                        "Unknown"
                                                    %>' />
                                                    <asp:Button ID="btnApprove" CssClass="grid-btn btn-approve" runat="server" Text="Approve" Visible="false" CommandName="Approve" CommandArgument='<%# Eval("approval_id") + "%" + Eval("bill_id") %>' />
                                                    <asp:Button ID="btnReject" CssClass="grid-btn btn-reject" runat="server" Text="Reject" Visible="false" CommandArgument='<%# Eval("approval_id") + "%" + Eval("bill_id") %>' />
                                                </ItemTemplate>
                                            </asp:TemplateField>

                                            <asp:BoundField DataField="remarks" HeaderText="Remarks" />
                                        </Columns>
                                    </asp:GridView>

                                </div>
                            </asp:Panel>
                            <asp:Panel ID="pnlPaymentSummary" runat="server" CssClass="SB-payment-summary-panel" Visible="true">
                                <br />
                                <!-- Header -->
                                <%-- <div class="SB-panel-header">
        <h5>
            <i class="fas fa-file-invoice"></i> Payment Summary
        </h5>
    </div>--%>
                                <div class="section-header mt-4">
                                    <i class="fas fa-file-invoice"></i>Payment Summary
                                </div>

                                <!-- Body -->
                                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                                    <ContentTemplate>
                                        <div class="SB-panel-body">
                                            <!-- Resident Info -->
                                            <h6 class="SB-section-header">Resident Information</h6>
                                            <div class="SB-info-card">
                                                <div class="SB-info-row">
                                                    <div class="SB-info-item">
                                                        <span class="SB-info-label">Resident Name:</span>
                                                        <asp:Label ID="Label2" runat="server" CssClass="SB-info-value"></asp:Label>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Selected Bills -->
                                            <h6 class="SB-section-header">Paid Bills</h6>
                                            <div class="SB-bills-table">
                                                <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" CssClass="table-hover" GridLines="None" ShowHeaderWhenEmpty="True">
                                                    <Columns>
                                                        <asp:BoundField DataField="bill_number" HeaderText="Bill No" />
                                                        <asp:BoundField DataField="payment_date" HeaderText="Bill Date" DataFormatString="{0:dd MMM yyyy}" />
                                                        <asp:BoundField DataField="paid_amount" HeaderText="Amount (₹)" DataFormatString="{0:N2}" />
                                                        <asp:BoundField DataField="payment_status" HeaderText="Status" />
                                                    </Columns>
                                                </asp:GridView>
                                            </div>

                                            <!-- Payment Details -->
                                            <h6 class="SB-section-header">Payment Details</h6>
                                            <div class="SB-info-card">
                                                <div class="SB-info-row">
                                                    <div class="SB-info-item">
                                                        <span class="SB-info-label">Payment Mode:</span>
                                                        <asp:Label ID="Label3" runat="server" CssClass="SB-info-value"></asp:Label>
                                                    </div>
                                                    <asp:Panel ID="Panel1" runat="server">
                                                        <div class="SB-info-item">
                                                            <span class="SB-info-label">Transaction Reference:</span>
                                                            <asp:Label ID="Label4" runat="server" CssClass="SB-info-value"></asp:Label>
                                                        </div>
                                                    </asp:Panel>
                                                </div>
                                                <asp:Panel runat="server" ID="Panel2">
                                                    <div class="SB-info-row">
                                                        <div class="SB-info-item">
                                                            <span class="SB-info-label">Cheque Number:</span>
                                                            <asp:Label ID="Label5" runat="server" CssClass="SB-info-value"></asp:Label>
                                                        </div>
                                                        <div class="SB-info-item">
                                                            <span class="SB-info-label">Cheque Date:</span>
                                                            <asp:Label ID="Label6" runat="server" CssClass="SB-info-value"></asp:Label>
                                                        </div>
                                                        <div class="SB-info-item">
                                                            <span class="SB-info-label">Bank Name:</span>
                                                            <asp:Label ID="Label7" runat="server" CssClass="SB-info-value"></asp:Label>
                                                        </div>
                                                    </div>
                                                </asp:Panel>
                                                <div class="SB-info-row">
                                                    <div class="SB-info-item">
                                                        <span class="SB-info-label">Amount:</span>
                                                        <asp:Label ID="Label8" runat="server" CssClass="SB-info-value"></asp:Label>
                                                    </div>
                                                </div>
                                                <div class="SB-info-row">
                                                    <div class="SB-info-item" style="flex: 1 1 100%;">
                                                        <span class="SB-info-label">Remarks:</span>
                                                        <asp:Label ID="Label9" runat="server" CssClass="SB-info-value text-muted"></asp:Label>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </ContentTemplate>
                                </asp:UpdatePanel>
                            </asp:Panel>

                            <!-- Notes/Remarks -->
                            <div class="section-header mt-4">
                                <i class="fas fa-sticky-note"></i>Notes/Remarks
                            </div>
                            <div class="p-3 bg-light rounded">
                                <asp:Label ID="lblRemarks" runat="server" CssClass="text-muted" />
                            </div>
                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="gvBills" EventName="RowCommand" />
                            <asp:AsyncPostBackTrigger ControlID="gvApprovals" EventName="RowCommand" />
                        </Triggers>
                    </asp:UpdatePanel>
                </div>

                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">
                        <i class="fas fa-times"></i>Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Reject Reason Modal -->

    <div class="modal fade" id="rejectModal" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h1 class="modal-title fs-5" id="exampleModalLabel">Reject Approval</h1>
                    <button type="button" class="btn-close text-black" onclick="closeRejectModal()" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                        <ContentTemplate>
                            <asp:HiddenField runat="server" ID="approval_id_hd" />
                            <asp:HiddenField runat="server" ID="bill_id_hd" />
                            <label for="txtRejectReason" class="reject-modal-label">Enter Reason:</label>
                            <asp:TextBox ID="txtRemark" runat="server" TextMode="MultiLine" Rows="4" CssClass="reject-modal-textbox"></asp:TextBox>
                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="Button1" EventName="Click" />
                        </Triggers>
                    </asp:UpdatePanel>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeRejectModal()">Close</button>
                    <asp:Button ID="Button1" runat="server" Text="Submit" CssClass="btn btn-primary" OnClick="btnSubmitReject_Click" CommandArgument='<%# approval_id_hd.Value %>' />
                </div>
            </div>
        </div>
    </div>



    <div class="modal fade" id="paymentModal" data-backdrop="static" data-keyboard="false" tabindex="-1" aria-labelledby="paymentModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                    <h5 class="modal-title" id="paymentModalLabel">
                        <i class="fas fa-wallet me-2"></i><strong>Vendor Bill Payment</strong>
                    </h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color: white;">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>

                <asp:UpdatePanel ID="UpdatePanelPayment" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:HiddenField runat="server" ID="hfPayBillId" />
                        <asp:HiddenField runat="server" ID="hfPayVendorId" />

                        <div class="modal-body" style="background: #f8f9fa; padding: 24px;">

                            <!-- Vendor Information -->
                            <div style="background: white; border-radius: 12px; padding: 20px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                                <h6 style="font-size: 15px; font-weight: 600; margin-bottom: 16px;">
                                    <i class="fas fa-building" style="color: #667eea;"></i>Vendor Information
                                </h6>
                                <div class="row">
                                    <div class="col-md-6">
                                        <small style="font-size: 12px; color: #666;">Vendor Name</small>
                                        <asp:Label ID="lblPayVendorName" runat="server" CssClass="d-block" Style="font-size: 14px; font-weight: 600;"></asp:Label>
                                    </div>
                                    <div class="col-md-6">
                                        <small style="font-size: 12px; color: #666;">Service Type</small>
                                        <asp:Label ID="lblPayServiceType" runat="server" CssClass="d-block" Style="font-size: 14px; font-weight: 600;"></asp:Label>
                                    </div>
                                </div>
                            </div>

                            <!-- Bill Display -->
                            <div style="background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%); border: 2px solid #667eea; border-radius: 16px; padding: 24px; margin-bottom: 24px;">
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 20px; border-bottom: 2px solid rgba(102, 126, 234, 0.2);">
                                    <div style="display: flex; align-items: center; gap: 12px;">
                                        <div style="background: #667eea; width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center;">
                                            <i class="fas fa-file-invoice" style="font-size: 24px; color: white;"></i>
                                        </div>
                                        <div>
                                            <small style="font-size: 12px; color: #666;">Bill Number</small>
                                            <asp:Label ID="lblPayBillNumber" runat="server" Style="font-size: 20px; font-weight: 700; display: block;"></asp:Label>
                                        </div>
                                    </div>
                                    <div style="text-align: right;">
                                        <small style="font-size: 12px; color: #666;">Total Amount</small>
                                        <div style="font-size: 28px; font-weight: 700; color: #667eea;">
                                            ₹
											<asp:Label ID="lblPayBillAmount" runat="server"></asp:Label>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-4">
                                        <div style="background: white; padding: 16px; border-radius: 10px;">
                                            <small style="font-size: 12px; color: #666;">Bill Date</small>
                                            <strong style="font-size: 14px; display: block;">
                                                <asp:Label ID="lblPayBillDate" runat="server"></asp:Label>
                                            </strong>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div style="background: white; padding: 16px; border-radius: 10px;">
                                            <small style="font-size: 12px; color: #666;">Bill Type</small>
                                            <strong style="font-size: 14px; display: block;">
                                                <asp:Label ID="lblPayBillType" runat="server"></asp:Label>
                                            </strong>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div style="background: white; padding: 16px; border-radius: 10px;">
                                            <small style="font-size: 12px; color: #666;">Status</small>
                                            <asp:Label ID="lblPayBillStatus" runat="server" CssClass="status-badge"></asp:Label>
                                        </div>
                                    </div>
                                </div>

                                <!-- Payment Amount Details -->
                                <div class="row">
                                    <div class="col-md-6">
                                        <div style="background: white; padding: 16px; border-radius: 10px; border-left: 3px solid #28a745;">
                                            <small style="font-size: 12px; color: #666;">
                                                <i class="fas fa-check-circle" style="color: #28a745;"></i>Paid Amount
                                            </small>
                                            <strong style="font-size: 18px; display: block; color: #28a745;">₹
												<asp:Label ID="lblPaidAmount" runat="server" Text="0.00"></asp:Label>
                                            </strong>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div style="background: white; padding: 16px; border-radius: 10px; border-left: 3px solid #dc3545;">
                                            <small style="font-size: 12px; color: #666;">
                                                <i class="fas fa-exclamation-circle" style="color: #dc3545;"></i>Remaining Amount
                                            </small>
                                            <strong style="font-size: 18px; display: block; color: #dc3545;">₹
												<asp:Label ID="lblRemainingAmount" runat="server" Text="0.00"></asp:Label>
                                            </strong>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Payment Mode -->
                            <div style="background: white; border-radius: 12px; padding: 20px; margin-bottom: 20px;">
                                <h6 style="font-size: 15px; font-weight: 600; margin-bottom: 16px;">
                                    <i class="fas fa-credit-card" style="color: #667eea;"></i>Select Payment Mode
                                </h6>
                                <div class="row">
                                    <div class="col-md-4 mb-2">
                                        <asp:LinkButton ID="btnPayChequeMode" runat="server" CssClass="payment-btn w-100" OnClick="btnPayChequeMode_Click" OnClientClick="setActivePayment(this.id);" Style="display: flex; flex-direction: column; align-items: center; padding: 24px; border: 2px solid #e9ecef; border-radius: 12px; background: white; text-decoration: none;">
											<i class="fas fa-money-check" style="font-size: 2.5rem; color: #6c757d;"></i>
											<span style="font-weight: 600; color: #6c757d; margin-top: 12px;">Cheque Payment</span>
                                        </asp:LinkButton>

                                    </div>
                                    <div class="col-md-4 mb-2">

                                        <asp:LinkButton ID="btnPayOnlineMode" runat="server" CssClass="payment-btn w-100" OnClick="btnPayOnlineMode_Click" OnClientClick="setActivePayment(this.id);" Style="display: flex; flex-direction: column; align-items: center; padding: 24px; border: 2px solid #e9ecef; border-radius: 12px; background: white; text-decoration: none;">
											<i class="fas fa-mobile-alt" style="font-size: 2.5rem; color: #6c757d;"></i>
											<span style="font-weight: 600; color: #6c757d; margin-top: 12px;">Online/UPI</span>
                                        </asp:LinkButton>
                                    </div>
                                    <div class="col-md-4 mb-2">
                                        <asp:LinkButton ID="btnCashMode" runat="server" CssClass="payment-btn w-100" OnClick="btnCashMode_Click" OnClientClick="setActivePayment(this.id);" Style="display: flex; flex-direction: column; align-items: center; padding: 24px; border: 2px solid #e9ecef; border-radius: 12px; background: white; text-decoration: none;">
											<i class="fas fa-coins" style="font-size:2.5rem; color:#6c757d;"></i>
											<span style="font-weight:600; color:#6c757d; margin-top:12px;">Cash</span>
                                        </asp:LinkButton>
                                    </div>
                                </div>
                            </div>

                            <!-- Payment Details -->
                            <div style="background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px;">
                                <h6 style="font-size: 15px; font-weight: 600; margin-bottom: 20px;">
                                    <i class="fas fa-file-invoice-dollar" style="color: #667eea;"></i>Payment Details
                                </h6>

                                <!-- Online Payment -->
                                <asp:Panel ID="pnlPayOnline" runat="server" Visible="False">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-hashtag"></i>Transaction Reference <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtPayTransactionRef" runat="server" CssClass="form-control" placeholder="Enter UPI/NEFT/RTGS Reference"></asp:TextBox>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtAmtOl" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Cheque Payment -->
                                <asp:Panel ID="pnlPayCheque" runat="server">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-hashtag"></i>Cheque Number <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtChequeNo" runat="server" CssClass="form-control" placeholder="Enter cheque number"></asp:TextBox>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="far fa-calendar-alt"></i>Cheque Date <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtChequeDate" runat="server" CssClass="form-control" TextMode="Date"></asp:TextBox>
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-university"></i>Bank Name <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtBankName" runat="server" CssClass="form-control" placeholder="Enter bank name"></asp:TextBox>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtAmtCqu" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                        </div>
                                    </div>
                                </asp:Panel>
                                <!-- Cheque Payment -->
                                <asp:Panel ID="pnlCash" runat="server">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label"><i class="fas fa-rupee-sign"></i>Amount <span style="color: #e74c3c;">*</span></label>
                                            <asp:TextBox ID="txtamtcash" runat="server" CssClass="form-control" TextMode="Number" step="0.01"></asp:TextBox>
                                        </div>
                                    </div>
                                </asp:Panel>

                                <!-- Remarks -->
                                <div class="mb-3">
                                    <label class="form-label"><i class="fas fa-comment-dots"></i>Remarks (Optional)</label>
                                    <asp:TextBox ID="txtPayRemarks" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Add notes..."></asp:TextBox>
                                </div>

                                <!-- File Upload -->
                                <div class="mb-0">
                                    <label class="form-label"><i class="fas fa-file-upload"></i>Payment Proof <span style="color: #e74c3c;"></span></label>
                                    <asp:FileUpload ID="FileUpload1" runat="server" accept=".pdf,.jpg,.jpeg,.png" CssClass="form-control" />
                                    <small class="text-muted"><i class="fas fa-info-circle"></i>Upload receipt (PDF, JPG, PNG - Max 5MB)</small>
                                </div>
                            </div>

                            <!-- Message -->
                            <asp:Label ID="lblPayMessage" runat="server" CssClass="alert" Visible="False"></asp:Label>
                        </div>

                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnPayChequeMode" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnPayOnlineMode" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnSavePayment" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">
                        <i class="fas fa-times"></i>Cancel
                    </button>
                    <asp:Button ID="btnSavePayment" runat="server" Text="Process Payment" CssClass="btn btn-primary" OnClick="btnSavePayment_Click" OnClientClick="return validatePaymentForm();" Style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none;" />
                </div>
            </div>
        </div>
    </div>


    <!-- Payment Summary Modal -->
    <div class="modal fade SB-payment-summary-modal" id="paymentSummaryModal" tabindex="-1" role="dialog" aria-labelledby="paymentSummaryModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <!-- Header -->
                <div class="modal-header">
                    <h5 class="modal-title" id="paymentSummaryModalLabel">
                        <i class="fas fa-file-invoice"></i>Payment Summary
                    </h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <!-- Body -->
                <asp:UpdatePanel runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <div class="modal-body">
                            <!-- Resident Info -->
                            <h6 class="SB-section-header">Resident Information</h6>
                            <div class="SB-info-card">
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Resident Name:</span>
                                        <asp:Label ID="lblResidentName" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
                            </div>

                            <!-- Selected Bills -->
                            <h6 class="SB-section-header">Paid Bills</h6>
                            <div class="SB-bills-table">
                                <asp:GridView ID="gvSelectedBills" runat="server" AutoGenerateColumns="False" CssClass="table-hover" GridLines="None" ShowHeaderWhenEmpty="True">

                                    <Columns>
                                        <asp:BoundField DataField="bill_number" HeaderText="Bill No" />
                                        <%--<asp:BoundField DataField= <%# Convert.ToBoolean(Eval("service_type")) ? "Service" : "Inventory" %> HeaderText="Description" />--%>

                                        <asp:BoundField DataField="payment_date" HeaderText="Bill Date" DataFormatString="{0:dd MMM yyyy}" />
                                        <%--<asp:BoundField DataField="Status" HeaderText="Status" />--%>
                                        <asp:BoundField DataField="paid_amount" HeaderText="Amount (₹)" DataFormatString="{0:N2}" />
                                        <asp:BoundField DataField="payment_status" HeaderText="Status" />
                                    </Columns>
                                </asp:GridView>
                            </div>

                            <!-- Payment Details -->
                            <h6 class="SB-section-header">Payment Details</h6>
                            <div class="SB-info-card">
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Payment Mode:</span>
                                        <asp:Label ID="lblPaymentMode" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                    <asp:Panel ID="pnlTransactionRef" runat="server">
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Transaction Referance</span>
                                            <asp:Label ID="lblTransaction" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                    </asp:Panel>
                                </div>
                                <asp:Panel runat="server" ID="pnlBankPayInfo">
                                    <div class="SB-info-row">
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Cheque Number:</span>
                                            <asp:Label ID="lblChequeNumber" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Cheque Date:</span>
                                            <asp:Label ID="lblChequeDate" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                        <div class="SB-info-item">
                                            <span class="SB-info-label">Bank Name:</span>
                                            <asp:Label ID="lblBankName" runat="server" CssClass="SB-info-value"></asp:Label>
                                        </div>
                                    </div>
                                </asp:Panel>
                                <div class="SB-info-row">
                                    <div class="SB-info-item">
                                        <span class="SB-info-label">Amount:</span>
                                        <asp:Label ID="lblPaymentAmount" runat="server" CssClass="SB-info-value"></asp:Label>
                                    </div>
                                </div>
                                <div class="SB-info-row">
                                    <div class="SB-info-item" style="flex: 1 1 100%;">
                                        <span class="SB-info-label">Remarks:</span>
                                        <asp:Label ID="Label1" runat="server" CssClass="SB-info-value text-muted"></asp:Label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="gvBills" EventName="RowCommand" />
                    </Triggers>
                </asp:UpdatePanel>
                <!-- Footer -->
                <div class="modal-footer">
                    <button type="button" class="btn SB-btn-back" data-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

    <!-- Custom scripts for all pages-->
    <script src="js/sb-admin-2.min.js"></script>


    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <script>

        function openRejectModal(approval_id, bill_id) {
            document.getElementById('<%= approval_id_hd.ClientID %>').value = approval_id;
            document.getElementById('<%= bill_id_hd.ClientID %>').value = bill_id;
            $('#rejectModal').modal('show');
        }
        function clearBillModal() {
            console.log('🧹 Clearing bill modal...');

            // ✅ 1. Clear all textboxes
            const textboxIds = [
        '<%= txtBillNumber.ClientID %>',
        '<%= txtNotes.ClientID %>',
        '<%= txtDesc.ClientID %>',
        '<%= txtServiceCost.ClientID %>',
        '<%= txtServiceDescription.ClientID %>',
        '<%= TextBox2.ClientID %>',
        '<%= TextBox1.ClientID %>',
        '<%= txtcheqno.ClientID %>',
        '<%= txtcheqdate.ClientID %>',
        '<%= txtbank.ClientID %>',
        '<%= txtcheqamount.ClientID %>',
        '<%= txttrasaction.ClientID %>',
        '<%= txtonlineamount.ClientID %>',
        '<%= txtcashamount.ClientID %>',
        '<%= txtre.ClientID %>'
            ];

            textboxIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = '';
            });

            // ✅ 2. Reset dates to today
            const today = new Date().toISOString().split('T')[0];
            const dateIds = ['<%= txtBillDate.ClientID %>', '<%= txtPaymentMonth.ClientID %>', '<%= txtcheqdate.ClientID %>'];
            dateIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = today;
            });

            // ✅ 3. Clear hidden fields
            const hiddenIds = [
        '<%= hdnItemsData.ClientID %>',
        '<%= hdnSubtotal.ClientID %>',
        '<%= hdnTax.ClientID %>',
        '<%= hdnGrandTotal.ClientID %>',
        '<%= hdnBillId.ClientID %>',
        '<%= vendor_name_id.ClientID %>',
        '<%= hdnActivePayment.ClientID %>'  // 🔥 CRITICAL: Clear payment mode selection
            ];

            hiddenIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) {
                    if (id.includes('vendor_name_id') || id.includes('hdnBillId')) {
                        el.value = '0';
                    } else {
                        el.value = '';  // 🔥 This clears hdnActivePayment too
                    }
                }
            });

            // ✅ 4. Reset dropdown
            const ddl = document.getElementById('<%= ddlSevice.ClientID %>');
            if (ddl) ddl.selectedIndex = 0;

            // ✅ 5. Clear items table
            const tbody = document.getElementById('itemsTableBody');
            if (tbody) tbody.innerHTML = '';

            // ✅ 6. Reset totals
            document.getElementById('subtotalAmount').innerText = '0.00';
            document.getElementById('taxAmount').innerText = '0.00';
            document.getElementById('grandTotal').innerText = '0.00';

            // ✅ 7. Hide all sections
            hideAllSections();

            // 🔥 8. CRITICAL: Clear ALL payment mode active states
            document.querySelectorAll('.payment-btn').forEach(btn => {
                btn.classList.remove('active');
            });

            // 🔥 9. CRITICAL: Hide all payment panels server-side state
            var panelCheque = document.getElementById('<%= Panelcheque.ClientID %>');
            var panelOnline = document.getElementById('<%= panelonline.ClientID %>');
            var panelCash = document.getElementById('<%= Panelcash.ClientID %>');

            if (panelCheque) panelCheque.style.display = 'none';
            if (panelOnline) panelOnline.style.display = 'none';
            if (panelCash) panelCash.style.display = 'none';

            // ✅ 10. Reset staff checkboxes
            document.querySelectorAll('[id*="chkStaff"]').forEach(cb => {
                cb.checked = false;
            });

            // ✅ 11. Reset total label
            const lblTotal = document.getElementById('<%= lblSelectedTotal.ClientID %>');
            if (lblTotal) lblTotal.innerText = '0.00';

            console.log('✅ Bill modal completely cleared including payment mode selection');
        }
        function setActivePayment(btnId) {


            // Remove active from all
            document.querySelectorAll('.payment-btn').forEach(btn => {
                btn.classList.remove('active');
            });

            // Add active to clicked
            var btn = document.getElementById(btnId);
            if (btn) {
                btn.classList.add('active');
            }

            // Save state for postback
            document.getElementById('hdnActivePayment').value = btnId;
        }

        function restoreActivePayment() {
            console.log("restoreActivePayment called");

            var btnId = document.getElementById('hdnActivePayment')?.value;
            if (!btnId) return;

            document.querySelectorAll('.payment-btn').forEach(btn => {
                btn.classList.remove('active');
            });

            var btn = document.getElementById(btnId);
            if (btn) {
                btn.classList.add('active');
            }
        }

        // Normal page load
        document.addEventListener('DOMContentLoaded', restoreActivePayment);

        // UpdatePanel support
        if (typeof Sys !== "undefined") {
            Sys.WebForms.PageRequestManager.getInstance()
                .add_endRequest(restoreActivePayment);
        }

        let keepPaymentHidden = false;
        let keepApproversModalOpen = false;
        let keepMainModalOpen = false;
        let storedFormData = {};


        function showModal(id) {
            $('#' + id).modal('show');
        }

        function hideModal(id) {
            $('#' + id).modal('hide');
        }

        function hideAllModals() {
            $('.modal').modal('hide');
            $('body').removeClass('modal-open');
            $('.modal-backdrop').remove();
        }

        /* =========================================================
           SECTION VISIBILITY HANDLING
        ========================================================= */
        function hideAllSections() {
            const ids = [
				'<%= billNumberDiv.ClientID %>',
				'<%= billDateDiv.ClientID %>',
				'<%= paymentMonthDiv.ClientID %>',
				'<%= staff.ClientID %>',
				'<%= vendorSection.ClientID %>',
				'<%= itemSection.ClientID %>',
				'<%= approvelSection.ClientID %>',
				'<%= paymentSection.ClientID %>',
				'<%= serviceSection.ClientID %>'
            ];

            ids.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.style.display = 'none';
            });
        }

        function toggleBillFields() {
            var ddl = document.getElementById('<%= ddlSevice.ClientID %>');
            if (!ddl) {
                console.log('❌ Dropdown not found');
                return;
            }

            console.log('🔄 Toggle called, dropdown value:', ddl.value);

            var billNumberDiv = document.getElementById('<%= billNumberDiv.ClientID %>');
            var billDateDiv = document.getElementById('<%= billDateDiv.ClientID %>');
            var paymentMonthDiv = document.getElementById('<%= paymentMonthDiv.ClientID %>');
            var staffSection = document.getElementById('<%= staff.ClientID %>');
            var vendorSection = document.getElementById('<%= vendorSection.ClientID %>');
            var itemSection = document.getElementById('<%= itemSection.ClientID %>');
            var approvelSection = document.getElementById('<%= approvelSection.ClientID %>');
            var paymentSection = document.getElementById('<%= paymentSection.ClientID %>');
            var serviceSection = document.getElementById('<%= serviceSection.ClientID %>');

            [billNumberDiv, billDateDiv, paymentMonthDiv, staffSection,
                vendorSection, itemSection, approvelSection, paymentSection, serviceSection]
                .forEach(e => { if (e) e.style.display = 'none'; });


            if (ddl.value === "0") {
                // 💼 Staff Payment
                console.log('→ Showing Staff Payment sections');
                if (paymentMonthDiv) paymentMonthDiv.style.display = 'block';
                if (staffSection) staffSection.style.display = 'block';
                keepPaymentHidden = true;
            }
            else if (ddl.value === "1" || ddl.value === "2") {
                // 🏢 Daily Expense OR Vendor Payment
                console.log('→ Showing Vendor/Daily Expense sections');
                if (billNumberDiv) billNumberDiv.style.display = 'block';
                if (billDateDiv) billDateDiv.style.display = 'block';
                if (vendorSection) vendorSection.style.display = 'block';
                if (itemSection) itemSection.style.display = 'block';
                if (approvelSection) approvelSection.style.display = 'block';

                // Payment section (unless approvers added)
                if (paymentSection && !keepPaymentHidden) {
                    paymentSection.style.display = 'block';
                }

                keepPaymentHidden = false;
            }
            else if (ddl.value === "3") {
                // 🔧 Service Payment - ONLY 4 sections
                console.log('→ Showing Service Payment sections');
                if (billNumberDiv) billNumberDiv.style.display = 'block';
                if (billDateDiv) billDateDiv.style.display = 'block';
                if (serviceSection) serviceSection.style.display = 'block';
                if (paymentSection) paymentSection.style.display = 'block';
                if (vendorSection) vendorSection.style.display = 'block';
                // ✅ NO vendor, items, or approvers
                keepPaymentHidden = false;
            }
            else {

                console.log('→ No payment type selected, all hidden');
            }
        }

        function show(id) {
            const el = document.getElementById(id);
            if (el) el.style.display = 'block';
        }


        function addNewItem() {
            const tbody = document.getElementById('itemsTableBody');
            if (!tbody) return;

            tbody.insertAdjacentHTML('beforeend', `<tr>
            <td><input class="item-desc" /></td>
            <td><input class="item-qty" type="number" value="1" onchange="calculateItemTotal(this)" /></td>
            <td><input class="item-price" type="number" value="0" onchange="calculateItemTotal(this)" /></td>
            <td><input class="item-tax" type="number" value="0" onchange="calculateItemTotal(this)" /></td>
            <td><input class="item-warranty" type="number" value="0" /></td>
            <td><input class="item-amount" readonly value="0.00" /></td>
            <td><button type="button" onclick="removeItem(this)">✖</button></td></tr>`);

            calculateGrandTotal();
        }

        function removeItem(btn) {
            btn.closest('tr').remove();
            calculateGrandTotal();
        }

        /* =========================================================
           CALCULATIONS
        ========================================================= */
        function calculateItemTotal(input) {
            const row = input.closest('tr');

            const qty = +row.querySelector('.item-qty').value || 0;
            const price = +row.querySelector('.item-price').value || 0;
            const tax = +row.querySelector('.item-tax').value || 0;

            const subtotal = qty * price;
            const total = subtotal + (subtotal * tax / 100);

            row.querySelector('.item-amount').value = total.toFixed(2);
            calculateGrandTotal();
        }

        function calculateGrandTotal() {

            let subtotal = 0,
                tax = 0;

            document.querySelectorAll('#itemsTableBody tr').forEach(row => {
                const qty = +row.querySelector('.item-qty').value || 0;
                const price = +row.querySelector('.item-price').value || 0;
                const taxRate = +row.querySelector('.item-tax').value || 0;

                const itemSubtotal = qty * price;
                subtotal += itemSubtotal;
                tax += itemSubtotal * taxRate / 100;
            });

            document.getElementById('subtotalAmount').innerText = subtotal.toFixed(2);
            document.getElementById('taxAmount').innerText = tax.toFixed(2);
            document.getElementById('grandTotal').innerText = (subtotal + tax).toFixed(2);
        }

        /* =========================================================
           COLLECT DATA FOR BACKEND
        ========================================================= */
        function collectItemsData() {
            // Calculate grand total
            calculateGrandTotal();

            // Get calculated values from DOM
            var subtotal = document.getElementById('subtotalAmount').innerText || '0';
            var tax = document.getElementById('taxAmount').innerText || '0';
            var grandTotal = document.getElementById('grandTotal').innerText || '0';

            // Update hidden fields
            document.getElementById('<%= hdnSubtotal.ClientID %>').value = subtotal;
            document.getElementById('<%= hdnTax.ClientID %>').value = tax;
            document.getElementById('<%= hdnGrandTotal.ClientID %>').value = grandTotal;

            // ✅ DEBUG LOG
            console.log('✅ collectItemsData called:');
            console.log('  Subtotal:', subtotal);
            console.log('  Tax:', tax);
            console.log('  Grand Total:', grandTotal);

            // Collect items array
            const items = [];
            document.querySelectorAll('#itemsTableBody tr').forEach(row => {
                const desc = row.querySelector('.item-desc').value.trim();
                if (!desc) return;

                items.push({
                    description: desc,
                    quantity: +row.querySelector('.item-qty').value || 0,
                    unit_price: +row.querySelector('.item-price').value || 0,
                    tax_percent: +row.querySelector('.item-tax').value || 0,
                    warranty: +row.querySelector('.item-warranty').value || 0,
                    amount: +row.querySelector('.item-amount').value || 0
                });
            });

            document.getElementById('<%= hdnItemsData.ClientID %>').value = JSON.stringify(items);
            console.log('  Items:', items.length);
        }



        function validateForm() {
            console.log('🔍 validateForm() called');

            var ddl = document.getElementById('<%= ddlSevice.ClientID %>');
            if (!ddl || ddl.value === "") {
                alert('⚠️ Please select Payment Type');
                return false;
            }

            console.log('Selected Payment Type:', ddl.value);

            // ✅ STAFF PAYMENT (0)
            if (ddl.value === "0") {
                if (!validateStaffPayment()) return false;

                // ✅ Validate payment for staff
                if (!validatePaymentBeforeSave()) {
                    return false;
                }
                return true;
            }

            // ✅ DAILY EXPENSE (1) - Items Optional
            if (ddl.value === "1") {
                if (!validateVendorSelection()) return false;
                let hasValidItem = false;
                document.querySelectorAll('#itemsTableBody tr').forEach(row => {
                    let desc = row.querySelector('.item-desc')?.value.trim();
                    let qty = parseFloat(row.querySelector('.item-qty')?.value) || 0;
                    if (desc && qty > 0) hasValidItem = true;
                });

                if (!hasValidItem) {
                    alert('⚠️ Please add at least ONE valid item for Daily Payment');
                    return false;
                }
                // ✅ CRITICAL: Collect items data BEFORE returning
                collectItemsData();
                console.log('Items Data:', document.getElementById("<%= hdnItemsData.ClientID %>").value);

                // ✅ Validate payment if payment section is visible
                if (!validatePaymentBeforeSave()) {
                    return false;
                }

                return true;
            }

            // ✅ VENDOR PAYMENT (2) - Items MANDATORY
            if (ddl.value === "2") {
                if (!validateVendorSelection()) return false;

                // Check for at least ONE valid item
                let hasValidItem = false;
                document.querySelectorAll('#itemsTableBody tr').forEach(row => {
                    let desc = row.querySelector('.item-desc')?.value.trim();
                    let qty = parseFloat(row.querySelector('.item-qty')?.value) || 0;
                    if (desc && qty > 0) hasValidItem = true;
                });

                if (!hasValidItem) {
                    alert('⚠️ Please add at least ONE valid item for Vendor Payment');
                    return false;
                }

                // ✅ CRITICAL: Collect items data BEFORE returning
                collectItemsData();
                console.log('Items Data:', document.getElementById("<%= hdnItemsData.ClientID %>").value);

                // ✅ Validate payment if payment section is visible
                if (!validatePaymentBeforeSave()) {
                    return false;
                }

                return true;
            }

            // ✅ SERVICE PAYMENT (3)
            if (ddl.value === "3") {
                // Service Description is mandatory
                var serviceDesc = document.getElementById('<%= txtServiceDescription.ClientID %>');
                if (!serviceDesc || !serviceDesc.value.trim()) {
                    alert('⚠️ Please enter Service Description');
                    return false;
                }

                // Service Cost is mandatory
                var serviceCost = document.getElementById('<%= txtServiceCost.ClientID %>');
                if (!serviceCost || !serviceCost.value.trim() || parseFloat(serviceCost.value) <= 0) {
                    alert('⚠️ Please enter valid Service Cost');
                    return false;
                }

                // ✅ Validate payment for service
                if (!validatePaymentBeforeSave()) {
                    return false;
                }

                console.log('✅ Service Payment validation passed');
                return true;
            }

            return false;
        }

        // ✅ Helper function for vendor validation
        function validateVendorSelection() {
            const vendorId = document.getElementById('<%= vendor_name_id.ClientID %>');
            if (!vendorId || vendorId.value === "0") {
                alert('⚠️ Please select Vendor');
                return false;
            }
            return true;
        }

        // ✅ Enhanced validation for payment before save
        function validatePaymentBeforeSave() {
            console.log('🔍 validatePaymentBeforeSave() called');

            // Check if payment section is visible
            var paymentSection = document.getElementById('<%= paymentSection.ClientID %>');
            if (!paymentSection || paymentSection.style.display === 'none') {
                console.log('ℹ️ Payment section not visible, skipping validation');
                return true; // Payment section not visible, skip validation
            }

            console.log('✅ Payment section is visible, checking if user started filling...');

            // Check which payment panel is visible
            var chequePanel = document.getElementById('<%= Panelcheque.ClientID %>');
            var onlinePanel = document.getElementById('<%= panelonline.ClientID %>');
            var cashPanel = document.getElementById('<%= Panelcash.ClientID %>');

            // ✅ CHEQUE VALIDATION - Only if user started filling
            if (chequePanel && chequePanel.style.display !== 'none' && chequePanel.style.visibility !== 'hidden') {
                console.log('→ Checking Cheque Payment');

                var chequeNo = document.getElementById('<%= txtcheqno.ClientID %>');
              var chequeDate = document.getElementById('<%= txtcheqdate.ClientID %>');
              var bankName = document.getElementById('<%= txtbank.ClientID %>');
              var chequeAmount = document.getElementById('<%= txtcheqamount.ClientID %>');

                // ✅ Check if user started filling ANY field
                var hasAnyValue =
                    (chequeNo && chequeNo.value.trim()) ||
                    (chequeDate && chequeDate.value.trim()) ||
                    (bankName && bankName.value.trim()) ||
                    (chequeAmount && chequeAmount.value.trim() && parseFloat(chequeAmount.value) > 0);

                // ✅ If user started filling, then validate all fields
                if (hasAnyValue) {
                    console.log('→ User started filling cheque details, validating...');

                    if (!chequeNo || !chequeNo.value.trim()) {
                        alert('⚠️ Please enter Cheque Number!');
                        if (chequeNo) chequeNo.focus();
                        return false;
                    }

                    if (!chequeDate || !chequeDate.value.trim()) {
                        alert('⚠️  Please select Cheque Date!');
                        if (chequeDate) chequeDate.focus();
                        return false;
                    }

                    if (!bankName || !bankName.value.trim()) {
                        alert('⚠️ Please enter Bank Name!');
                        if (bankName) bankName.focus();
                        return false;
                    }

                    if (!chequeAmount || !chequeAmount.value.trim() || parseFloat(chequeAmount.value) <= 0) {
                        alert('⚠️ Please enter valid Amount!');
                        if (chequeAmount) chequeAmount.focus();
                        return false;
                    }

                    console.log('✅ Cheque validation passed');
                } else {
                    console.log('ℹ️ No cheque data entered, skipping validation');
                }

                return true;
            }

            // ✅ ONLINE VALIDATION - Only if user started filling
            if (onlinePanel && onlinePanel.style.display !== 'none' && onlinePanel.style.visibility !== 'hidden') {
                console.log('→ Checking Online Payment');

                var transactionRef = document.getElementById('<%= txttrasaction.ClientID %>');
        var onlineAmount = document.getElementById('<%= txtonlineamount.ClientID %>');

                // ✅ Check if user started filling ANY field
                var hasAnyValue =
                    (transactionRef && transactionRef.value.trim()) ||
                    (onlineAmount && onlineAmount.value.trim() && parseFloat(onlineAmount.value) > 0);

                // ✅ If user started filling, then validate all fields
                if (hasAnyValue) {
                    console.log('→ User started filling online details, validating...');

                    if (!transactionRef || !transactionRef.value.trim()) {
                        alert('⚠️ Please enter Transaction Reference!');
                        if (transactionRef) transactionRef.focus();
                        return false;
                    }

                    if (!onlineAmount || !onlineAmount.value.trim() || parseFloat(onlineAmount.value) <= 0) {
                        alert('⚠️ Please enter valid Amount!');
                        if (onlineAmount) onlineAmount.focus();
                        return false;
                    }

                    console.log('✅ Online validation passed');
                } else {
                    console.log('ℹ️ No online data entered, skipping validation');
                }

                return true;
            }

            // ✅ CASH VALIDATION - Only if user started filling
            if (cashPanel && cashPanel.style.display !== 'none' && cashPanel.style.visibility !== 'hidden') {
                console.log('→ Checking Cash Payment');

                var cashAmount = document.getElementById('<%= txtcashamount.ClientID %>');

                // ✅ Check if user started filling
                var hasAnyValue = cashAmount && cashAmount.value.trim() && parseFloat(cashAmount.value) > 0;

                // ✅ If user started filling, then validate
                if (hasAnyValue) {
                    console.log('→ User started filling cash details, validating...');

                    if (parseFloat(cashAmount.value) <= 0) {
                        alert('⚠️ Please enter valid Cash Amount!');
                        cashAmount.focus();
                        return false;
                    }

                    console.log('✅ Cash validation passed');
                } else {
                    console.log('ℹ️ No cash data entered, skipping validation');
                }

                return true;
            }

            // ✅ If no payment panel is visible, skip validation
            console.log('ℹ️ No payment mode selected or visible, skipping validation');
            return true;
        }

        // ✅ Validate staff payment
        function validateStaffPayment() {
            const staffType = document.getElementById('<%= ddlStaffType.ClientID %>');
            if (!staffType || staffType.value === "") {
                alert('⚠️ Please select Staff Type');
                return false;
            }

            let selected = false;
            document.querySelectorAll('[id*="chkStaff"]').forEach(cb => {
                if (cb.checked) selected = true;
            });

            if (!selected) {
                alert('⚠️ Please select at least one staff');
                return false;
            }

            return true;
        }
        function validateVendorPayment(requireItem) {

            const vendorId = document.getElementById('<%= vendor_name_id.ClientID %>');
            if (!vendorId || vendorId.value === "0") {
                alert('⚠️ Please select Vendor');
                return false;
            }

            if (requireItem) {
                let hasItem = false;
                document.querySelectorAll('#itemsTableBody tr').forEach(row => {
                    if (row.querySelector('.item-desc').value.trim()) hasItem = true;
                });
                if (!hasItem) {
                    alert('⚠️ Please add at least one item');
                    return false;
                }
            }

            collectItemsData();
            return true;
        }

        function validateStaffPayment() {

            const staffType = document.getElementById('<%= ddlStaffType.ClientID %>');
            if (!staffType || staffType.value === "") {
                alert('⚠️ Please select Staff Type');
                return false;
            }

            let selected = false;
            document.querySelectorAll('[id*="chkStaff"]').forEach(cb => {
                if (cb.checked) selected = true;
            });

            if (!selected) {
                alert('⚠️ Please select at least one staff');
                return false;
            }

            return true;
        }

        /* =========================================================
           INITIALIZATION (PAGE LOAD + UPDATE PANEL SAFE)
        ========================================================= */
        function initBillUI() {
            toggleBillFields();
        }

        function initDropdownEvents() {
            const categoryBox = document.getElementById("<%= TextBox2.ClientID %>");
               const categorySuggestions = document.getElementById("RepeaterContainer1");

               if (categoryBox && categorySuggestions) {
                   categoryBox.addEventListener("focus", function () {
                       categorySuggestions.style.display = "block";
                   });

                   categoryBox.addEventListener("input", function () {
                       const input = categoryBox.value.toLowerCase();
                       filterSuggestions("category-link", input);
                   });

                   // Close dropdown when clicking outside
                   document.addEventListener("click", function (e) {
                       if (!categoryBox.contains(e.target) && !categorySuggestions.contains(e.target)) {
                           categorySuggestions.style.display = "none";
                       }
                   });
               }
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
                       noMatchMessage.className = "suggestion-item";
                       noMatchMessage.style.color = "#9ca3af";
                       noMatchMessage.innerHTML = `No matching vendors found.<a href="javascript:void(0)" onclick="openAddVendorModal()" class="add-vendor-link"><i class="fas fa-plus"></i> Add New</a> `;
                       items[0]?.parentNode?.appendChild(noMatchMessage);
                   }
                   noMatchMessage.style.display = "block";
               } else {
                   if (noMatchMessage) {
                       noMatchMessage.style.display = "none";
                   }
               }
           }


           function setCategoryBox1(vendorText, vendorId) {
               document.getElementById('<%= TextBox2.ClientID %>').value = vendorText;
            document.getElementById('<%= vendor_name_id.ClientID %>').value = vendorId;
               document.getElementById('RepeaterContainer1').style.display = 'none';
           }
           // Initialize on Sys.Application load
           Sys.Application.add_load(function () {
               initDropdownEvents();
           });




           function clearBillModal() {
               console.log('🧹 Clearing bill modal...');

               // Clear all textboxes by ID
               const textboxIds = [
        '<%= txtBillNumber.ClientID %>',
        '<%= txtNotes.ClientID %>',
        '<%= txtDesc.ClientID %>',
        '<%= txtServiceCost.ClientID %>',
        '<%= txtServiceDescription.ClientID %>',
        '<%= TextBox2.ClientID %>',
        '<%= TextBox1.ClientID %>',
        '<%= txtcheqno.ClientID %>',
        '<%= txtcheqdate.ClientID %>',
        '<%= txtbank.ClientID %>',
        '<%= txtcheqamount.ClientID %>',
        '<%= txttrasaction.ClientID %>',
        '<%= txtonlineamount.ClientID %>',
        '<%= txtcashamount.ClientID %>',
        '<%= txtre.ClientID %>'
            ];

            textboxIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = '';
            });

            // Reset dates to today
            const today = new Date().toISOString().split('T')[0];
            const dateIds = ['<%= txtBillDate.ClientID %>', '<%= txtPaymentMonth.ClientID %>'];
            dateIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = today;
            });

            // Clear hidden fields
            const hiddenIds = [
        '<%= hdnItemsData.ClientID %>',
        '<%= hdnSubtotal.ClientID %>',
        '<%= hdnTax.ClientID %>',
        '<%= hdnGrandTotal.ClientID %>',
        '<%= hdnBillId.ClientID %>',
        '<%= vendor_name_id.ClientID %>'
            ];

            hiddenIds.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = id.includes('vendor_name_id') || id.includes('hdnBillId') ? '0' : '';
            });

            // Reset dropdown
            const ddl = document.getElementById('<%= ddlSevice.ClientID %>');
            if (ddl) ddl.selectedIndex = 0;

            // Clear items table
            const tbody = document.getElementById('itemsTableBody');
            if (tbody) tbody.innerHTML = '';

            // Reset totals
            document.getElementById('subtotalAmount').innerText = '0.00';
            document.getElementById('taxAmount').innerText = '0.00';
            document.getElementById('grandTotal').innerText = '0.00';

            // Hide all sections
            hideAllSections();

            // Clear payment mode active state
            document.querySelectorAll('.payment-btn').forEach(btn => {
                btn.classList.remove('active');
            });

            // Reset staff checkboxes
            document.querySelectorAll('[id*="chkStaff"]').forEach(cb => {
                cb.checked = false;
            });

    // Reset select all checkbox
   <%-- const chkSelectAll = document.getElementById('<%= chkSelectAllStaff.ClientID %>');
    if (chkSelectAll) chkSelectAll.checked = false;--%>

            // Reset total label
            const lblTotal = document.getElementById('<%= lblSelectedTotal.ClientID %>');
               if (lblTotal) lblTotal.innerText = '0.00';

               console.log('✅ Bill modal cleared');
           }





           $(document).ready(function () {
               // Clear form when modal is closed by ANY method (X button, Close button, or ESC key)
               $('#billModal').on('hidden.bs.modal', function () {
                   clearBillModal();
                   hideAllSections();
                   console.log('✅ Modal closed - form cleared');
               });
           });

           function showVendorDropdown() {
               var drp = document.getElementById('drp_Container');
               if (drp) drp.style.display = 'block';
           }

           function hideVendorDropdown() {
               var drp = document.getElementById('drp_Container');
               if (drp) drp.style.display = 'none';
           }

           // Click outside = hide dropdown
           document.addEventListener('click', function (e) {
               var container = document.querySelector('.dropdown-container');
               if (!container.contains(e.target)) {
                   hideVendorDropdown();
               }
           });




           // ✅ ADD this function to your existing JavaScript
           function getPaymentAmount() {
               var ddl = document.getElementById('<%= ddlSevice.ClientID %>');
            var amount = '';

            if (ddl && ddl.value === "3") {
                // ✅ Service Payment - use service cost
                var serviceCost = document.getElementById('<%= txtServiceCost.ClientID %>');
        if (serviceCost && serviceCost.value) {
            amount = parseFloat(serviceCost.value).toFixed(2);
        }
        console.log('📊 Service Cost:', amount);
    } else {
        // ✅ All others - use grand total
        var grandTotal = document.getElementById('<%= hdnGrandTotal.ClientID %>');
                   if (grandTotal && grandTotal.value) {
                       amount = parseFloat(grandTotal.value).toFixed(2);
                   }
                   console.log('📊 Grand Total:', amount);
               }

               return amount;
           }


           // ✅ UPDATE payment amount when button clicked
           function updatePaymentAmount(mode) {
               var amount = getPaymentAmount();

               if (amount && parseFloat(amount) > 0) {
                   switch (mode) {
                       case 'cheque':
                           document.getElementById('<%= txtcheqamount.ClientID %>').value = amount;
                break;
            case 'online':
                document.getElementById('<%= txtonlineamount.ClientID %>').value = amount;
                break;
            case 'cash':
                document.getElementById('<%= txtcashamount.ClientID %>').value = amount;
                           break;
                   }
                   console.log(`✅ ${mode} amount set: ₹${amount}`);
               }
           }



           // ✅ UPDATED: Toggle payment mode (Click again to deselect)
           function togglePaymentMode(btnId, panelType) {
               console.log('🔄 togglePaymentMode called:', btnId, panelType);

               var btn = document.getElementById(btnId);
               var hdnActive = document.getElementById('hdnActivePayment');

               // Check if this button is already active
               var isCurrentlyActive = btn && btn.classList.contains('active');

               if (isCurrentlyActive) {
                   // ✅ Deselect - Remove active state
                   btn.classList.remove('active');
                   hdnActive.value = '';
                   console.log('❌ Payment mode deselected');

                   // Hide all panels
                   hideAllPaymentPanels();
                   return false; // Prevent postback
               } else {
                   // ✅ Select - Set as active
                   document.querySelectorAll('.payment-btn').forEach(b => b.classList.remove('active'));
                   btn.classList.add('active');
                   hdnActive.value = btnId;
                   console.log('✅ Payment mode selected:', panelType);
                   return true; // Allow postback to show panel
               }
           }

           // ✅ NEW: Hide all payment panels
           function hideAllPaymentPanels() {
               var panelCheque = document.getElementById('<%= Panelcheque.ClientID %>');
            var panelOnline = document.getElementById('<%= panelonline.ClientID %>');
            var panelCash = document.getElementById('<%= Panelcash.ClientID %>');

               if (panelCheque) panelCheque.style.display = 'none';
               if (panelOnline) panelOnline.style.display = 'none';
               if (panelCash) panelCash.style.display = 'none';

               console.log('🚫 All payment panels hidden');
           }

           // ✅ KEEP existing setActivePayment for other scenarios
           function setActivePayment(btnId) {
               document.querySelectorAll('.payment-btn').forEach(btn => {
                   btn.classList.remove('active');
               });

               var btn = document.getElementById(btnId);
               if (btn) {
                   btn.classList.add('active');
               }

               document.getElementById('hdnActivePayment').value = btnId;
           }

           // ✅ KEEP existing restoreActivePayment
           function restoreActivePayment() {
               console.log("restoreActivePayment called");

               var btnId = document.getElementById('hdnActivePayment')?.value;
               if (!btnId) return;

               document.querySelectorAll('.payment-btn').forEach(btn => {
                   btn.classList.remove('active');
               });

               var btn = document.getElementById(btnId);
               if (btn) {
                   btn.classList.add('active');
               }
           }

           // Normal page load
           document.addEventListener('DOMContentLoaded', restoreActivePayment);

           // UpdatePanel support
           if (typeof Sys !== "undefined") {
               Sys.WebForms.PageRequestManager.getInstance()
                   .add_endRequest(restoreActivePayment);
        }


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
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

</asp:Content>
