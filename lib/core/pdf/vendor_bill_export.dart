import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'vendor_bill_pdf.dart';

/// Download, print and share — the three ways a vendor bill leaves the app.
///
/// The same shape as BillExport, which does this for maintenance bills: all
/// three build one document rather than printing the live view, which gave a
/// sheet cut wherever the scroll box happened to end.
class VendorBillExport {
  /// Everything the three actions need, gathered once by the caller.
  ///
  /// The formatters come in rather than being built here: `money` and
  /// `prettyDate` are the app's own, and a bill printed with different
  /// formatting from the screen it was printed off is a bill that looks wrong.
  static Future<Uint8List> _pdf({
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> approvals,
    required List<Map<String, dynamic>> payments,
    required String Function(dynamic) money,
    required String Function(dynamic) date,
  }) => VendorBillPdf.build(
    bill: bill,
    items: items,
    approvals: approvals,
    payments: payments,
    money: money,
    date: date,
  );

  /// Save the PDF where the user can find it again.
  ///
  /// Deliberately not the share sheet: with share as its own action beside
  /// this one, a Download that opened the same dialog would leave two buttons
  /// doing one thing and no way to simply keep the file.
  static Future<void> download(
    BuildContext context, {
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> approvals,
    required List<Map<String, dynamic>> payments,
    required String Function(dynamic) money,
    required String Function(dynamic) date,
  }) => _guard(context, (messenger) async {
    final bytes = await _pdf(
      bill: bill,
      items: items,
      approvals: approvals,
      payments: payments,
      money: money,
      date: date,
    );
    final name = '${_fileName(bill)}.pdf';

    // The web build has no filesystem to write to; its download is the
    // browser's own, which is what sharePdf triggers there.
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: name);
      return;
    }

    final dir = await _saveDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Saved to ${dir.path.split(Platform.pathSeparator).last}/$name',
        ),
        // Saving is quiet by nature, so the confirmation carries the way to
        // act on it: a file that cannot be found again may as well not have
        // been written.
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => Printing.sharePdf(bytes: bytes, filename: name),
        ),
      ),
    );
  });

  /// The system print dialog.
  static Future<void> print(
    BuildContext context, {
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> approvals,
    required List<Map<String, dynamic>> payments,
    required String Function(dynamic) money,
    required String Function(dynamic) date,
  }) => _guard(context, (_) async {
    final bytes = await _pdf(
      bill: bill,
      items: items,
      approvals: approvals,
      payments: payments,
      money: money,
      date: date,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _fileName(bill),
    );
  });

  /// The OS share sheet — WhatsApp, mail, anything the device offers.
  ///
  /// This is how a bill reaches the vendor or the committee: it is sent,
  /// rather than printed and handed over on paper.
  static Future<void> share(
    BuildContext context, {
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> approvals,
    required List<Map<String, dynamic>> payments,
    required String Function(dynamic) money,
    required String Function(dynamic) date,
  }) => _guard(context, (_) async {
    final bytes = await _pdf(
      bill: bill,
      items: items,
      approvals: approvals,
      payments: payments,
      money: money,
      date: date,
    );
    final name = '${_fileName(bill)}.pdf';

    await Share.shareXFiles([
      XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
    ], subject: _subject(bill));
  });

  /// What the mail client puts on the subject line.
  static String _subject(Map<String, dynamic> bill) {
    final number = VendorBillPdf.pick(bill, ['bill_number', 'bill_no']);
    final vendor = VendorBillPdf.pick(bill, ['vendor_name', 'name']);
    return [
      'Vendor bill',
      if (number != null) number,
      if (vendor != null) '— $vendor',
    ].join(' ');
  }

  /// Where a saved bill lands.
  ///
  /// Downloads on Android when it exists, so the file shows up where the user
  /// expects a download to be; the app's own documents directory otherwise,
  /// which is the only writable place on iOS.
  static Future<Directory> _saveDirectory() async {
    if (Platform.isAndroid) {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  /// "vendor-bill-SRV-202608-101500.pdf" — the bill number is what makes one
  /// saved file tell itself apart from the next.
  static String _fileName(Map<String, dynamic> bill) {
    final number = VendorBillPdf.pick(bill, ['bill_number', 'bill_no']) ?? '';
    final slug = number.trim().replaceAll(RegExp(r'[^A-Za-z0-9-]+'), '-');
    return slug.isEmpty ? 'vendor-bill' : 'vendor-bill-$slug';
  }

  /// A failed export must say so. Silently doing nothing reads as a dead
  /// button, and the user retries instead of reporting it.
  static Future<void> _guard(
    BuildContext context,
    Future<void> Function(ScaffoldMessengerState) action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(messenger);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create the PDF: $e')),
      );
    }
  }
}
