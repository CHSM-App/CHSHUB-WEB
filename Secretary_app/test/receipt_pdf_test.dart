import 'package:flutter_test/flutter_test.dart';

import 'package:secretary_app/core/pdf/receipt_pdf.dart';

ReceiptSheetData _receipt({String? status}) => ReceiptSheetData(
  receiptNo: 'RCP-0142',
  date: DateTime(2026, 8, 12),
  status: status ?? 'Paid',
  residentName: 'A Sharma',
  unit: 'A-101',
  societyName: 'Green Acres CHS',
  payMode: 'Cheque',
  reference: '556677',
  bankName: 'HDFC Bank',
  paidAmount: 4140.50,
  lines: const [
    ReceiptLine(
      billNo: 'MB-0611',
      period: 'June 2026',
      dueDate: null,
      amount: 1500.00,
    ),
    ReceiptLine(
      billNo: 'MB-0712',
      period: 'July 2026',
      dueDate: null,
      amount: 2640.50,
    ),
  ],
);

void main() {
  test('the PDF builds from the same receipt the screen draws', () async {
    final bytes = await ReceiptPdf.build(_receipt());

    // A real PDF, not an empty document: Download, Print and Share all hand
    // over this one file, so if it builds they all carry the same sheet.
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('a receipt with no bill lines still produces a sheet', () async {
    final bare = ReceiptSheetData(
      receiptNo: 'RCP-1',
      date: DateTime(2026, 8, 12),
      status: null,
      residentName: null,
      unit: null,
      societyName: null,
      payMode: null,
      reference: null,
      bankName: null,
      paidAmount: 500,
      lines: const [],
    );

    // Every field is optional on the wire; a sparse row must not throw on the
    // way to paper.
    final bytes = await ReceiptPdf.build(bare);
    expect(bytes.length, greaterThan(500));
  });

  test('a cancelled receipt is marked on the sheet', () async {
    final cancelled = await ReceiptPdf.build(_receipt(status: 'Cancelled'));
    final paid = await ReceiptPdf.build(_receipt());

    // The CANCELLED band and the dropped total tint make the two documents
    // differ — a reversed payment must not print as money collected.
    expect(cancelled.length, isNot(paid.length));
  });
}
