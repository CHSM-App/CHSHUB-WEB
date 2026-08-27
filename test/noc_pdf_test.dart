import 'package:flutter_test/flutter_test.dart';
import 'package:secretary_app/core/pdf/noc_pdf.dart';

/// The certificate sheet is built entirely in code, so a broken layout only
/// shows up when the bytes are actually produced — which is what these do.
void main() {
  // PdfGoogleFonts reads the asset manifest, which needs the binding up.
  TestWidgetsFlutterBinding.ensureInitialized();

  NocSheetData sheet({
    String building = 'Building A',
    String purpose = 'Visa Application',
    String remarks = '',
    DateTime? validTill,
  }) => NocSheetData(
    serial: 'NOC/2026/00125',
    typeLabel: 'Sale / transfer',
    clause:
        'to the sale and transfer of the said flat by the member, and holds '
        'no claim, charge or lien over the said flat other than its dues, '
        'if any.',
    member: 'Rahul Sharma',
    flat: 'A-1203',
    building: building,
    purpose: purpose,
    issuedOn: DateTime(2026, 8, 26),
    validTill: validTill ?? DateTime(2027, 8, 25),
    remarks: remarks,
    societyName: 'Green Valley CHS Ltd.',
  );

  test('builds a certificate PDF', () async {
    final bytes = await NocPdf.build(sheet());

    expect(bytes.lengthInBytes, greaterThan(0));
    // Every PDF opens with %PDF; anything else is not a document.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('builds when the optional parts are absent', () async {
    final bytes = await NocPdf.build(
      sheet(building: '', purpose: '', validTill: DateTime(2020, 1, 1)),
    );

    expect(bytes.lengthInBytes, greaterThan(0));
  });

  test('builds with added content', () async {
    final bytes = await NocPdf.build(
      sheet(remarks: 'Subject to the member clearing the transfer fee.'),
    );

    expect(bytes.lengthInBytes, greaterThan(0));
  });
}
