import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/bill_sheet.dart';

/// The printed maintenance bill.
///
/// Mirrors the website's BillSheet: same particulars grid, same charge table,
/// same totals block closing with the amount in words. A resident who gets the
/// PDF from the app and one who gets it from the portal must hold the same
/// document.
class BillPdf {
  static const _line = PdfColor.fromInt(0xFFCBD5E1); // slate-300
  static const _head = PdfColor.fromInt(0xFFF1F5F9); // slate-100
  static const _grand = PdfColor.fromInt(0xFFFDF1F1); // the total row's tint
  static const _muted = PdfColor.fromInt(0xFF475569);

  /// One page per flat, as the legacy print modal laid them out.
  static Future<Uint8List> build(List<BillSheetData> sheets) async {
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
          for (var i = 0; i < sheets.length; i++) ...[
            _sheet(sheets[i]),
            // A page break after every bill but the last, so no sheet starts
            // halfway down a page under the tail of another flat's bill.
            if (i != sheets.length - 1) pw.NewPage(),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _sheet(BillSheetData bill) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'MAINTENANCE BILL',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        if (bill.societyName != null)
          pw.Center(
            child: pw.Text(
              bill.societyName!,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        if (bill.registrationNo != null)
          pw.Center(
            child: pw.Text(
              'Registration No: ${bill.registrationNo}',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        if (bill.address != null)
          pw.Center(
            child: pw.Text(
              bill.address!,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        pw.SizedBox(height: 14),
        _particulars(bill),
        pw.SizedBox(height: 10),
        _charges(bill),
        pw.SizedBox(height: 10),
        _totals(bill),
      ],
    );
  }

  /// Six boxes, two to a row.
  static pw.Widget _particulars(BillSheetData bill) {
    final cells = bill.particulars;
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

  static pw.Widget _charges(BillSheetData bill) {
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

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(46),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(110),
      },
      children: [
        pw.TableRow(
          children: [
            cell('Sr. No', bold: true, fill: _head),
            cell('Nature of Charges', bold: true, fill: _head),
            cell('Amount', bold: true, right: true, fill: _head),
          ],
        ),
        if (bill.lines.isEmpty)
          pw.TableRow(
            children: [
              cell(''),
              cell('No charge lines on this bill.'),
              cell(''),
            ],
          )
        else
          for (var i = 0; i < bill.lines.length; i++)
            pw.TableRow(
              children: [
                cell('${i + 1}'),
                cell(bill.lines[i].name),
                cell('₹ ${sheetAmount(bill.lines[i].amount)}', right: true),
              ],
            ),
      ],
    );
  }

  /// Label left, figure right, with only the row rules drawn — a line between
  /// the two columns would cut a label off from its amount.
  static pw.Widget _totals(BillSheetData bill) {
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
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(190),
      },
      children: [
        row('Total:', '₹ ${sheetAmount(bill.charges)}', bold: true),
        if (bill.forward != 0)
          row(
            'Dues as of ${bill.billDay}:',
            '₹ ${sheetAmount(bill.forward)}',
            bold: true,
          ),
        row(
          'Grand Total:',
          '₹ ${sheetAmount(bill.grandTotal)}',
          bold: true,
          fill: _grand,
        ),
        // The grand total, not the month's charges. Words on a bill exist so
        // the payable figure cannot be altered, so they must name what is
        // actually payable.
        row('Amount in Words:', amountInWords(bill.grandTotal)),
      ],
    );
  }
}
