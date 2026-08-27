import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// What the certificate needs to print, free of any Flutter widget types so
/// the screen's record and the sheet do not have to share a class.
class NocSheetData {
  const NocSheetData({
    required this.serial,
    required this.typeLabel,
    required this.clause,
    required this.member,
    required this.flat,
    required this.building,
    required this.purpose,
    required this.issuedOn,
    required this.validTill,
    required this.remarks,
    required this.societyName,
    this.isCustomType = false,
  });

  final String serial;
  final String typeLabel;

  /// Completes "The society has no objection …".
  final String clause;

  final String member;
  final String flat;
  final String building;
  final String purpose;
  final DateTime issuedOn;
  final DateTime? validTill;
  final String remarks;
  final String societyName;

  /// Whether the society worded this certificate itself, in which case
  /// [typeLabel] is its own title and worth printing under the heading.
  final bool isCustomType;
}

/// One NOC, as a printable letter.
///
/// Mirrors the certificate on screen: crested heading with the society's name,
/// the title, the reference and date, the recital, the operative clause, the
/// particulars as a table, and a seal and signature block — so the paper and
/// the glass are the same document.
class NocPdf {
  static const _line = PdfColor.fromInt(0xFFCBD5E1);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _accent = PdfColor.fromInt(0xFF12A150);
  static const _rule = PdfColor.fromInt(0xFFE08700);

  static final _dates = DateFormat('dd MMM yyyy');

  /// The smaller of A4 and Letter in each direction, so the sheet fits either
  /// tray at full size.
  ///
  /// A4 is the narrower of the two but also the taller: an A4 page on Letter
  /// paper loses its foot, and a Letter page on A4 loses its right edge. On a
  /// bordered certificate that frame is the whole design, and letting the
  /// printer scale to fit shrinks the type instead. Taking each dimension's
  /// minimum gives one page that prints whole on both.
  static final _format = PdfPageFormat(
    PdfPageFormat.a4.width < PdfPageFormat.letter.width
        ? PdfPageFormat.a4.width
        : PdfPageFormat.letter.width,
    PdfPageFormat.a4.height < PdfPageFormat.letter.height
        ? PdfPageFormat.a4.height
        : PdfPageFormat.letter.height,
    marginAll: 0,
  );

  static Future<Uint8List> build(NocSheetData noc) async {
    final doc = pw.Document();

    // The same bundled face the other sheets use, so the exports match.
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.Page(
        pageFormat: _format,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        // A double rule around the whole sheet, as a certificate carries and
        // a letter does not — it is what makes the page read as a document
        // rather than a printout.
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _rule, width: 1.4),
          ),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _rule, width: 0.5),
            ),
            padding: const pw.EdgeInsets.fromLTRB(30, 26, 30, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _heading(noc),
                pw.SizedBox(height: 20),
                _reference(noc),
                pw.SizedBox(height: 20),
                _body(noc),
                pw.SizedBox(height: 18),
                _particulars(noc),
                pw.Spacer(),
                _signature(noc),
                pw.SizedBox(height: 14),
                pw.Divider(color: _line, height: 1),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'This is a system generated certificate and does not '
                    'require manual signature.',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _heading(NocSheetData noc) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            noc.societyName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'NO OBJECTION CERTIFICATE',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 7),
          // A rule broken by a diamond, the ornament a certificate carries
          // under its title.
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(width: 52, height: 0.8, color: _rule),
              pw.SizedBox(width: 5),
              pw.Transform.rotate(
                angle: 0.785398, // 45°, so the square reads as a diamond.
                child: pw.Container(width: 4, height: 4, color: _rule),
              ),
              pw.SizedBox(width: 5),
              pw.Container(width: 52, height: 0.8, color: _rule),
            ],
          ),
          // Only a society-worded certificate names itself here; the built-in
          // kinds are already evident from the clause below.
          if (noc.isCustomType) ...[
            pw.SizedBox(height: 7),
            pw.Text(
              noc.typeLabel,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  /// Reference left, date right — as typed at the head of the letter.
  static pw.Widget _reference(NocSheetData noc) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _stacked('Certificate No.', noc.serial),
        _stacked(
          'Date of Issue',
          _dates.format(noc.issuedOn),
          alignEnd: true,
        ),
      ],
    );
  }

  static pw.Widget _stacked(
    String label,
    String value, {
    bool alignEnd = false,
  }) {
    return pw.Column(
      crossAxisAlignment: alignEnd
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _body(NocSheetData noc) {
    final where = noc.building.isEmpty ? '' : ', ${noc.building}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'This is to certify that ${noc.member}, residing in Flat No. '
          '${noc.flat}$where, ${noc.societyName}, is a registered '
          'member/resident of our society.',
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 10),
        pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
            children: [
              const pw.TextSpan(text: 'The society has '),
              pw.TextSpan(
                text: 'no objection',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: ' ${noc.clause}'),
            ],
          ),
        ),
        if (noc.remarks.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            noc.remarks,
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ],
    );
  }

  /// The particulars, as the bordered table the other sheets use.
  static pw.Widget _particulars(NocSheetData noc) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Member Name', noc.member),
      MapEntry('Flat No.', noc.flat),
      if (noc.building.isNotEmpty) MapEntry('Building / Wing', noc.building),
      if (noc.purpose.isNotEmpty) MapEntry('Purpose', noc.purpose),
      MapEntry(
        'Valid Until',
        noc.validTill == null ? 'No expiry' : _dates.format(noc.validTill!),
      ),
      MapEntry('Issued By', noc.societyName),
    ];

    // Hairline separators rather than a full grid: the screen lists these as
    // open rows, and a boxed table would make paper and glass disagree.
    return pw.Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.Container(
            decoration: i == rows.length - 1
                ? null
                : const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _line, width: 0.5),
                    ),
                  ),
            padding: const pw.EdgeInsets.symmetric(vertical: 7),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    rows[i].key,
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    rows[i].value,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Seal left, signature right — where they sit on the printed letter.
  static pw.Widget _signature(NocSheetData noc) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // A double ring, as a rubber stamp carries — a single outline reads
        // as a drawn circle rather than a seal.
        pw.Container(
          height: 66,
          width: 66,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: _accent, width: 1.2),
          ),
          padding: const pw.EdgeInsets.all(3),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _accent, width: 0.5),
            ),
            child: pw.Center(
              child: pw.Text(
                'SOCIETY\nSEAL',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  color: _accent,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                  lineSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(width: 150, height: 0.8, color: _line),
            pw.SizedBox(height: 5),
            pw.Text(
              'Authorised Signatory',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              noc.societyName,
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ],
    );
  }
}
