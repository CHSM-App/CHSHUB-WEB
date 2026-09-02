import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/json_utils.dart';

/// What the certificate needs to print, free of any Flutter widget types so
/// the screen's record and the sheet do not have to share a class.
/// Which officers sign the society's certificate, and what they are called.
///
/// Set per society, in account settings: how many officers sign is fixed by a
/// society's own bye-laws and by whoever is being asked to act on the
/// certificate. One society signs with both, another with the secretary alone,
/// and plenty print "President" where this code says chairman.
///
/// The defaults are what the sheet printed before this was configurable, so a
/// society that has never opened the setting sees no change.
class NocSignatories {
  const NocSignatories({
    this.mode = 'Both',
    this.secretary = 'Secretary',
    this.chairman = 'Chairman',
  });

  /// The `signatories` object the certificate list carries.
  ///
  /// An empty map — an older server, or any other list — leaves the defaults,
  /// which is what the sheet printed before this was configurable.
  factory NocSignatories.fromJson(Map<String, dynamic>? json) {
    String or(String? v, String fallback) =>
        (v == null || v.trim().isEmpty) ? fallback : v.trim();

    return NocSignatories(
      mode: or(asString(json?['mode']), 'Both'),
      secretary: or(asString(json?['secretary']), 'Secretary'),
      chairman: or(asString(json?['chairman']), 'Chairman'),
    );
  }

  /// 'Both', 'Secretary' or 'Chairman'.
  final String mode;
  final String secretary;
  final String chairman;

  /// The lines the sheet leaves for ink, in the order they are printed.
  ///
  /// A line for an officer who does not sign leaves a blank the member is
  /// asked about at the bank; one missing for an officer who does means
  /// reprinting the letter.
  List<String> get roles => switch (mode) {
    'Secretary' => [secretary],
    'Chairman' => [chairman],
    _ => [secretary, chairman],
  };
}

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
    this.signatories = const NocSignatories(),
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

  /// Who signs this society's certificates.
  final NocSignatories signatories;
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
                // States what this sheet is, not what makes it valid.
                //
                // It used to read "does not require manual signature", which
                // is wrong — a NOC is signed in ink. It was then changed to
                // "valid only when signed by the Secretary and the Chairman",
                // which is a legal claim this code is in no position to make:
                // how many signatures a society's certificate carries is set
                // by its own bye-laws and by whoever is being asked to act on
                // it, and a society that signs with one officer would have
                // this line declaring its own certificates invalid.
                //
                // The block above leaves a line for each officer. A society
                // that uses only one leaves the other blank; nothing here
                // asserts that it had to be filled.
                pw.Center(
                  child: pw.Text(
                    'Issued by the society. Please sign and affix the society '
                    'seal before handing this certificate over.',
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

  /// Seal left, the signature lines right — where they sit on the letter.
  ///
  /// A line for the secretary and one for the chairman, both blank for ink.
  /// Nothing here is a digital signature: the printed page is what the society
  /// actually issues, and it is signed by hand.
  ///
  /// Two lines rather than one because societies commonly have both officers
  /// sign a certificate, and a bank or sub-registrar may look for both. How
  /// many are actually required is the society's own rule, so a society that
  /// signs with one officer simply leaves the other line empty — an unused
  /// line costs nothing, while a missing one means reprinting the letter.
  static pw.Widget _signature(NocSheetData noc) {
    pw.Widget block(String role) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // The gap above the rule is the space signed into.
        pw.SizedBox(height: 30),
        pw.Container(width: 120, height: 0.8, color: _line),
        pw.SizedBox(height: 5),
        pw.Text(
          role,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          noc.societyName,
          textAlign: pw.TextAlign.center,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: const pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ],
    );

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
        // One block per signing officer, from the society's own setting.
        for (final role in noc.signatories.roles) ...[
          block(role),
          if (role != noc.signatories.roles.last) pw.SizedBox(width: 18),
        ],
      ],
    );
  }
}
