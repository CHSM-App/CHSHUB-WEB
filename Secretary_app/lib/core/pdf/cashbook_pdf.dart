import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// The printed cashbook.
///
/// Mirrors what CashbookPage prints from the website — the same four columns
/// (Date, Particular, Debit, Credit), the opening and closing balances
/// framing the entries, and the totals row underneath — so a cashbook filed
/// from the app and one filed from the portal are the same document.
class CashbookPdf {
  static const _line = PdfColor.fromInt(0xFFCBD5E1); // slate-300
  static const _head = PdfColor.fromInt(0xFFF1F5F9); // slate-100
  static const _muted = PdfColor.fromInt(0xFF475569);
  static const _balance = PdfColor.fromInt(0xFFEEF0FE); // the brand's surface
  static const _total = PdfColor.fromInt(0xFFFDF1F1); // the web page's foot

  /// One line of the printed grid, already formatted.
  ///
  /// The rows arrive formatted rather than raw so the document reads exactly
  /// as the screen it was printed from — the app's own `money` and date
  /// formatters come in from the caller.
  static Future<Uint8List> build({
    required List<CashbookLine> opening,
    required List<CashbookLine> closing,
    required List<CashbookLine> entries,
    required String debitTotal,
    required String creditTotal,
    required String period,
    String? societyName,
  }) async {
    final doc = pw.Document();
    // Noto, as the bill and receipt documents use — it carries the rupee sign
    // and Devanagari, which a particular copied from the ledger may hold.
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) =>
            // Repeated on every page: a cashbook running to several sheets
            // needs each one to say what it is and what period it covers.
            context.pageNumber == 1
            ? pw.SizedBox()
            : _header(period, societyName, continued: true),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (context) => [
          _header(period, societyName),
          pw.SizedBox(height: 14),
          _table(
            opening: opening,
            closing: closing,
            entries: entries,
            debitTotal: debitTotal,
            creditTotal: creditTotal,
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    String period,
    String? societyName, {
    bool continued = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (societyName != null)
          pw.Text(
            societyName,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 2),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              continued ? 'Cashbook (continued)' : 'Cashbook',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Spacer(),
            pw.Text(
              period,
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _line, height: 1),
      ],
    );
  }

  static pw.Widget _table({
    required List<CashbookLine> opening,
    required List<CashbookLine> closing,
    required List<CashbookLine> entries,
    required String debitTotal,
    required String creditTotal,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(70),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(85),
        3: pw.FixedColumnWidth(85),
      },
      children: [
        _headRow(),
        for (final l in opening) _row(l, background: _balance, bold: true),
        if (entries.isEmpty)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: pw.Text(
                  'No cash moved in this period',
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ),
              pw.SizedBox(),
              pw.SizedBox(),
              pw.SizedBox(),
            ],
          )
        else
          for (final l in entries) _row(l),
        _totalRow(debitTotal, creditTotal),
        for (final l in closing) _row(l, background: _balance, bold: true),
      ],
    );
  }

  static pw.TableRow _headRow() {
    pw.Widget cell(String text, {bool right = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _head),
      children: [
        cell('Date'),
        cell('Particular'),
        cell('Debit', right: true),
        cell('Credit', right: true),
      ],
    );
  }

  static pw.TableRow _row(
    CashbookLine line, {
    PdfColor? background,
    bool bold = false,
  }) {
    final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;

    pw.Widget cell(String text, {bool right = false, double size = 9}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(fontSize: size, fontWeight: weight),
          ),
        );

    return pw.TableRow(
      decoration: background == null
          ? null
          : pw.BoxDecoration(color: background),
      children: [
        cell(line.date, size: 8),
        cell(line.particular),
        // A zero side prints blank, as it does on the web grid — a column of
        // zeroes is harder to scan than an empty one.
        cell(line.debit, right: true),
        cell(line.credit, right: true),
      ],
    );
  }

  static pw.TableRow _totalRow(String debit, String credit) {
    pw.Widget cell(String text, {bool right = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
      ),
    );

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _total),
      children: [
        pw.SizedBox(),
        cell('Total'),
        cell(debit, right: true),
        cell(credit, right: true),
      ],
    );
  }
}

/// A formatted cashbook line, ready to print.
class CashbookLine {
  const CashbookLine({
    required this.date,
    required this.particular,
    required this.debit,
    required this.credit,
  });

  final String date;
  final String particular;
  final String debit;
  final String credit;
}
