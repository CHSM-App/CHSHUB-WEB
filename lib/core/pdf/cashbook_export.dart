import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'cashbook_pdf.dart';

/// Download, print and share — the three ways a cashbook leaves the app.
///
/// The same shape as VendorBillExport: all three build one document rather
/// than printing the live view, which gave a sheet cut wherever the scroll
/// box happened to end.
class CashbookExport {
  /// Everything the three actions need, gathered once by the caller.
  ///
  /// The lines arrive already formatted so the document reads exactly as the
  /// screen it was printed from.
  static Future<Uint8List> _pdf(CashbookExportData data) => CashbookPdf.build(
    opening: data.opening,
    closing: data.closing,
    entries: data.entries,
    debitTotal: data.debitTotal,
    creditTotal: data.creditTotal,
    period: data.period,
    societyName: data.societyName,
  );

  /// Save the PDF where the user can find it again.
  ///
  /// Deliberately not the share sheet: with share as its own action beside
  /// this one, a Download that opened the same dialog would leave two buttons
  /// doing one thing and no way to simply keep the file.
  static Future<void> download(BuildContext context, CashbookExportData data) =>
      _guard(context, (messenger) async {
        final bytes = await _pdf(data);
        final name = '${_fileName(data)}.pdf';

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
  static Future<void> print(BuildContext context, CashbookExportData data) =>
      _guard(context, (_) async {
        final bytes = await _pdf(data);
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _fileName(data),
        );
      });

  /// The OS share sheet — WhatsApp, mail, anything the device offers.
  static Future<void> share(BuildContext context, CashbookExportData data) =>
      _guard(context, (_) async {
        final bytes = await _pdf(data);
        final name = '${_fileName(data)}.pdf';

        await Share.shareXFiles([
          XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
        ], subject: 'Cashbook ${data.period}');
      });

  /// Where a saved cashbook lands.
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

  /// "cashbook-2026-01-01-to-2026-08-22.pdf" — the period is what makes one
  /// saved file tell itself apart from the next.
  static String _fileName(CashbookExportData data) {
    final slug = data.fileStamp.replaceAll(RegExp(r'[^A-Za-z0-9-]+'), '-');
    return slug.isEmpty ? 'cashbook' : 'cashbook-$slug';
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

/// The formatted cashbook, ready to print.
class CashbookExportData {
  const CashbookExportData({
    required this.opening,
    required this.closing,
    required this.entries,
    required this.debitTotal,
    required this.creditTotal,
    required this.period,
    required this.fileStamp,
    this.societyName,
  });

  final List<CashbookLine> opening;
  final List<CashbookLine> closing;
  final List<CashbookLine> entries;
  final String debitTotal;
  final String creditTotal;

  /// "01 Jan 2026 — 22 Aug 2026", printed under the title.
  final String period;

  /// The same period in a form that survives a filename.
  final String fileStamp;

  final String? societyName;
}
