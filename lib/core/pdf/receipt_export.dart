import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'receipt_pdf.dart';

/// Download, print and share one receipt.
///
/// The same three the bill sheets offer, and the same split between them:
/// Download writes a file the secretary can find again, Share opens the OS
/// sheet, Print goes to the system dialog.
class ReceiptExport {
  static Future<void> download(
    BuildContext context,
    ReceiptSheetData receipt,
  ) => _guard(context, (messenger) async {
    final bytes = await ReceiptPdf.build(receipt);
    final name = '${_fileName(receipt)}.pdf';

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
        content: Text('Saved $name'),
        // Saving is quiet by nature, so the confirmation carries the way to
        // act on it: a file the secretary cannot find again may as well not
        // have been written.
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => Printing.sharePdf(bytes: bytes, filename: name),
        ),
      ),
    );
  });

  static Future<void> print(BuildContext context, ReceiptSheetData receipt) =>
      _guard(context, (_) async {
        final bytes = await ReceiptPdf.build(receipt);
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _fileName(receipt),
        );
      });

  /// The OS share sheet — how a receipt actually reaches the resident who paid.
  static Future<void> share(BuildContext context, ReceiptSheetData receipt) =>
      _guard(context, (_) async {
        final bytes = await ReceiptPdf.build(receipt);
        final name = '${_fileName(receipt)}.pdf';

        await Share.shareXFiles(
          [XFile.fromData(bytes, name: name, mimeType: 'application/pdf')],
          subject: [
            'Maintenance receipt',
            if (receipt.receiptNo != null) receipt.receiptNo,
          ].whereType<String>().join(' '),
        );
      });

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

  static String _fileName(ReceiptSheetData receipt) {
    final slug = receipt.label.trim().replaceAll(RegExp(r'[^\w-]+'), '-');
    return slug.isEmpty ? 'maintenance-receipt' : 'receipt-$slug';
  }

  /// A failed export must say so. Silently doing nothing reads as a dead
  /// button, and the secretary retries instead of reporting it.
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
