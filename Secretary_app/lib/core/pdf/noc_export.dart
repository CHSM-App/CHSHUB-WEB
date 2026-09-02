import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'noc_pdf.dart';

/// Download, print and share one NOC certificate.
///
/// The same three the receipts and bill sheets offer, and the same split:
/// Download writes a file the secretary can find again, Print goes to the
/// system dialog, Share opens the OS sheet — which is how the certificate
/// actually reaches the member who asked for it.
class NocExport {
  static Future<void> download(BuildContext context, NocSheetData noc) =>
      _guard(context, (messenger) async {
        final bytes = await NocPdf.build(noc);
        final name = '${_fileName(noc)}.pdf';

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
            // A file the secretary cannot find again may as well not have
            // been written, so the confirmation carries the way to open it.
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => Printing.sharePdf(bytes: bytes, filename: name),
            ),
          ),
        );
      });

  static Future<void> print(BuildContext context, NocSheetData noc) =>
      _guard(context, (_) async {
        final bytes = await NocPdf.build(noc);
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _fileName(noc),
        );
      });

  static Future<void> share(BuildContext context, NocSheetData noc) =>
      _guard(context, (_) async {
        final bytes = await NocPdf.build(noc);
        final name = '${_fileName(noc)}.pdf';

        await Share.shareXFiles(
          [XFile.fromData(bytes, name: name, mimeType: 'application/pdf')],
          subject: 'No Objection Certificate ${noc.serial}',
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

  /// The serial carries slashes, which are path separators — slugged so the
  /// certificate number still reads in the file name without breaking it.
  static String _fileName(NocSheetData noc) {
    final slug = noc.serial.trim().replaceAll(RegExp(r'[^\w-]+'), '-');
    return slug.isEmpty ? 'noc-certificate' : 'noc-$slug';
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
