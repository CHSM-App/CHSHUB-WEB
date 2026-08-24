import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/bill_sheet.dart'
    show amountInWords, sheetAmount, sheetDay;

/// One receipt, as a printable sheet.
///
/// Mirrors the website's receipt PDF: the society in the heading, the receipt
/// number and amount in the box that leads, the payment details as rows, and
/// the bills it settled listed underneath — so the sheet says what was paid
/// for and not just the total.
class ReceiptPdf {
  static const _line = PdfColor.fromInt(0xFFCBD5E1);
  static const _head = PdfColor.fromInt(0xFFF1F5F9);

  /// The screen's own tints, so paper and glass agree.
  static const _totalTint = PdfColor.fromInt(0xFFEAF7EF);
  static const _error = PdfColor.fromInt(0xFFD92D20);
  static const _errorTint = PdfColor.fromInt(0xFFFEECEB);

  static Future<Uint8List> build(ReceiptSheetData receipt) async {
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
              'MAINTENANCE RECEIPT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          if (receipt.societyName != null)
            pw.Center(
              child: pw.Text(
                receipt.societyName!,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (_isCancelled(receipt)) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                color: _errorTint,
                border: pw.Border.all(color: _error, width: 0.5),
              ),
              child: pw.Center(
                child: pw.Text(
                  'CANCELLED',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _error,
                  ),
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          _particulars(receipt),
          pw.SizedBox(height: 10),
          _bills(receipt),
          pw.SizedBox(height: 10),
          _totals(receipt),
        ],
      ),
    );

    return doc.save();
  }

  static bool _isCancelled(ReceiptSheetData r) =>
      r.status?.toLowerCase().contains('cancel') ?? false;

  /// The boxes above the table, two to a row — the same particulars grid the
  /// screen draws, so a printed receipt and the one on screen are the same
  /// document.
  static pw.Widget _particulars(ReceiptSheetData r) {
    final cells = <MapEntry<String, String>>[
      MapEntry('Receipt No', r.receiptNo ?? '—'),
      MapEntry('Date', r.date == null ? '—' : sheetDay(r.date)),
      MapEntry('Resident', r.residentName ?? '—'),
      MapEntry('Unit', r.unit ?? '—'),
      MapEntry('Pay Mode', r.payMode ?? '—'),
      MapEntry('Bank', r.bankName ?? '—'),
      // Kept in pairs: an odd cell would leave the last row with a hole where
      // a bordered box should be.
      if (r.reference != null) MapEntry('Cheque / Ref', r.reference!),
      if (r.reference != null) MapEntry('Status', r.status ?? 'Paid'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      children: [
        for (var i = 0; i < cells.length; i += 2)
          pw.TableRow(
            children: [
              for (final cell in cells.skip(i).take(2))
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: pw.Text(
                    '${cell.key}: ${cell.value}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Label left, figure right, closing with the amount in words — the bill's
  /// totals block, so the sum cannot be altered after the fact.
  static pw.Widget _totals(ReceiptSheetData r) {
    final settled = r.lines.fold<double>(0, (s, l) => s + l.amount);

    pw.TableRow row(
      String label,
      String value, {
      bool bold = false,
      PdfColor? fill,
    }) {
      pw.Widget box(String text, {bool right = false}) => pw.Container(
        color: fill,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
      return pw.TableRow(children: [box(label), box(value, right: true)]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(0.8), 1: pw.FlexColumnWidth()},
      children: [
        // Only when the lines disagree with the receipt: two identical figures
        // stacked above each other is noise.
        if (r.lines.isNotEmpty && (settled - r.paidAmount).abs() >= 0.005)
          row('Bills settled:', '₹ ${sheetAmount(settled)}'),
        row(
          'Amount Received:',
          '₹ ${sheetAmount(r.paidAmount)}',
          bold: true,
          fill: _isCancelled(r) ? null : _totalTint,
        ),
        row('Amount in Words:', amountInWords(r.paidAmount)),
      ],
    );
  }

  static pw.Widget _bills(ReceiptSheetData r) {
    pw.Widget cell(
      String text, {
      bool bold = false,
      bool right = false,
      PdfColor? fill,
    }) => pw.Container(
      color: fill,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

    // The screen's own four columns, in its order — Sr. No, Bill No, Period,
    // Amount. A printed receipt that listed different columns from the one on
    // screen would read as a different document.
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(46),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FixedColumnWidth(96),
      },
      children: [
        pw.TableRow(
          children: [
            cell('Sr. No', bold: true, fill: _head),
            cell('Bill No', bold: true, fill: _head),
            cell('Period', bold: true, fill: _head),
            cell('Amount', bold: true, right: true, fill: _head),
          ],
        ),
        if (r.lines.isEmpty)
          pw.TableRow(
            children: [
              cell(''),
              cell('No bill lines recorded for this receipt.'),
              cell(''),
              cell(''),
            ],
          )
        else
          for (var i = 0; i < r.lines.length; i++)
            pw.TableRow(
              children: [
                cell('${i + 1}'),
                cell(r.lines[i].billNo ?? '—'),
                cell(r.lines[i].period ?? '—'),
                cell('₹ ${sheetAmount(r.lines[i].amount)}', right: true),
              ],
            ),
      ],
    );
  }
}

/// One receipt, in the shape the printed sheet and the view screen both need.
class ReceiptSheetData {
  const ReceiptSheetData({
    required this.receiptNo,
    required this.date,
    required this.status,
    required this.residentName,
    required this.unit,
    required this.societyName,
    required this.payMode,
    required this.reference,
    required this.bankName,
    required this.paidAmount,
    required this.lines,
  });

  final String? receiptNo;
  final DateTime? date;
  final String? status;
  final String? residentName;
  final String? unit;
  final String? societyName;
  final String? payMode;
  final String? reference;
  final String? bankName;
  final double paidAmount;
  final List<ReceiptLine> lines;

  /// A label for files and share sheets.
  String get label => receiptNo ?? 'receipt';
}

class ReceiptLine {
  const ReceiptLine({
    required this.billNo,
    required this.period,
    required this.dueDate,
    required this.amount,
  });

  final String? billNo;
  final String? period;
  final DateTime? dueDate;
  final double amount;
}
