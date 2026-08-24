import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/json_utils.dart';

/// The printed vendor bill.
///
/// Mirrors what VendorBillsPage prints from the website — the same summary
/// grid, the same items, approvals and payments tables — so a bill filed from
/// the app and one filed from the portal are the same document.
class VendorBillPdf {
  static const _line = PdfColor.fromInt(0xFFCBD5E1); // slate-300
  static const _head = PdfColor.fromInt(0xFFF1F5F9); // slate-100
  static const _muted = PdfColor.fromInt(0xFF475569);
  static const _total = PdfColor.fromInt(0xFFEEF0FE); // the brand's surface

  /// The first non-empty value among [keys].
  ///
  /// Its own copy rather than app_widgets' `pick`: that lives in the widget
  /// layer, and a document builder has no business importing Flutter widgets
  /// to read a map. Same rule — stored procedures are not consistent about
  /// column names, so every spelling the row might use is asked for.
  static String? pick(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  /// What identifies a payment, by mode.
  ///
  /// A cheque is traced by its number and the date it carries, an online
  /// transfer by its transaction reference. Cash has neither — it is handed
  /// over, and the receipt number is the only record of it. Printing a bill
  /// without these leaves nothing to match against a bank statement.
  static String _reference(
    Map<String, dynamic> payment,
    String Function(dynamic) date,
  ) {
    final cheque = pick(payment, ['cheque_no']);
    if (cheque != null) {
      final on = payment['cheque_date'];
      final bank = pick(payment, ['bank_name']);
      return [
        'Cheque $cheque',
        if (on != null) date(on),
        if (bank != null) bank,
      ].join(' · ');
    }

    final txn = pick(payment, ['transaction_ref']);
    if (txn != null) return 'Ref $txn';

    return '—';
  }

  /// Approval status codes, as UPDATE_STATUS writes them.
  static String _approvalLabel(dynamic v) {
    final n = asIntOr(v);
    if (n == 2) return 'Approved';
    if (n == 4) return 'Rejected';
    return 'Pending';
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> approvals,
    required List<Map<String, dynamic>> payments,
    required String Function(dynamic) money,
    required String Function(dynamic) date,
  }) async {
    final doc = pw.Document();

    // The bundled font carries the rupee sign; the built-in Helvetica has no
    // such glyph and would print a blank box on every amount.
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'VENDOR BILL',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 14),

          _summary(bill, money, date),

          if (items.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _heading('Items'),
            _itemsTable(items, money),
          ],

          if (approvals.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _heading('Approvals'),
            _approvalsTable(approvals, date),
          ],

          if (payments.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _heading('Payments'),
            _paymentsTable(payments, money, date),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );

  /// The bill's own figures, three to a row.
  static pw.Widget _summary(
    Map<String, dynamic> bill,
    String Function(dynamic) money,
    String Function(dynamic) date,
  ) {
    final fields = <(String, String)>[
      ('Bill number', pick(bill, ['bill_number', 'bill_no']) ?? '—'),
      ('Bill date', date(bill['bill_date'])),
      ('Vendor / staff', pick(bill, ['vendor_name', 'name']) ?? '—'),
      ('Subtotal', money(bill['subtotal'])),
      ('Tax', money(bill['tax_amount'])),
      ('Total', money(bill['total_amount'])),
      ('Paid', money(bill['paid_amount'])),
      ('Outstanding', money(bill['remaining_amount'])),
      ('Status', pick(bill, ['bill_status']) ?? '—'),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line)),
      child: pw.Column(
        children: [
          for (var row = 0; row * 3 < fields.length; row++)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 3; col++)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          top: row == 0
                              ? pw.BorderSide.none
                              : const pw.BorderSide(color: _line),
                          left: col == 0
                              ? pw.BorderSide.none
                              : const pw.BorderSide(color: _line),
                        ),
                      ),
                      child: row * 3 + col < fields.length
                          ? pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  fields[row * 3 + col].$1.toUpperCase(),
                                  style: const pw.TextStyle(
                                    fontSize: 7,
                                    color: _muted,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  fields[row * 3 + col].$2,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            )
                          : pw.SizedBox(),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(
    List<Map<String, dynamic>> items,
    String Function(dynamic) money,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _line),
      headerDecoration: const pw.BoxDecoration(color: _head),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 16,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      headers: ['Item', 'Qty', 'Unit price', 'Tax %', 'Warranty', 'Amount'],
      data: [
        for (final it in items)
          [
            pick(it, ['item_name', 'name']) ?? '—',
            '${it['quantity'] ?? 0}',
            money(it['purchase_cost']),
            asDoubleOr(it['tax']) > 0 ? '${it['tax']}' : '—',
            asIntOr(it['warranty']) > 0 ? '${it['warranty']} mo' : '—',
            money(it['total_amount']),
          ],
      ],
    );
  }

  /// Who was asked, what they said and why — the remark matters most on a
  /// rejection, which is the one decision that stops the bill.
  static pw.Widget _approvalsTable(
    List<Map<String, dynamic>> approvals,
    String Function(dynamic) date,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _line),
      headerDecoration: const pw.BoxDecoration(color: _head),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellHeight: 16,
      headers: ['Approver', 'Status', 'Date', 'Reason'],
      data: [
        for (final a in approvals)
          [
            pick(a, ['name', 'user_name']) ?? '—',
            _approvalLabel(a['approval_status']),
            a['approval_date'] == null ? '—' : date(a['approval_date']),
            pick(a, ['remarks']) ?? '—',
          ],
      ],
    );
  }

  static pw.Widget _paymentsTable(
    List<Map<String, dynamic>> payments,
    String Function(dynamic) money,
    String Function(dynamic) date,
  ) {
    final total = payments.fold<double>(
      0,
      (sum, p) => sum + asDoubleOr(p['paid_amount']),
    );

    return pw.Column(
      children: [
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _line),
          headerDecoration: const pw.BoxDecoration(color: _head),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellHeight: 16,
          cellAlignments: {4: pw.Alignment.centerRight},
          headers: ['Payment no.', 'Date', 'Mode', 'Reference', 'Amount'],
          data: [
            for (final p in payments)
              [
                pick(p, ['payment_no']) ?? '—',
                date(p['payment_date']),
                pick(p, ['pay_mode']) ?? '—',
                _reference(p, date),
                money(p['paid_amount']),
              ],
          ],
        ),
        pw.Container(
          color: _total,
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total paid',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                money(total),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
