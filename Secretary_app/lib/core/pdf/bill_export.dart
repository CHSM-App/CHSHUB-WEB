import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/bill_sheet.dart';
import 'bill_pdf.dart';

/// Download, print and share — the three ways a bill leaves the app.
///
/// All build the same PDF rather than one printing the screen: printing the
/// live view gave a sheet cut wherever the scroll box happened to end, so every
/// route hands over one document.
class BillExport {
  /// Save the PDF where the user can find it again.
  ///
  /// Deliberately not the share sheet, which is what `Printing.sharePdf` shows
  /// on mobile: with share as its own action beside this one, a Download that
  /// opened the same dialog would leave two buttons doing one thing and no way
  /// to simply keep the file.
  static Future<void> download(
    BuildContext context,
    List<BillSheetData> sheets, {
    required String period,
  }) => _guard(context, (messenger) async {
    final bytes = await BillPdf.build(sheets);
    final name = '${_fileName(sheets, period)}.pdf';

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
        // Saving is quiet by nature, so the confirmation carries the way to act
        // on it: a file the secretary cannot find again may as well not have
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
    BuildContext context,
    List<BillSheetData> sheets, {
    required String period,
  }) => _guard(context, (_) async {
    final bytes = await BillPdf.build(sheets);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _fileName(sheets, period),
    );
  });

  /// The OS share sheet — WhatsApp, mail, anything the device offers.
  ///
  /// This is how a bill actually reaches a resident: the secretary sends it,
  /// rather than printing and handing over paper.
  static Future<void> share(
    BuildContext context,
    List<BillSheetData> sheets, {
    required String period,
  }) => _guard(context, (_) async {
    final bytes = await BillPdf.build(sheets);
    final name = '${_fileName(sheets, period)}.pdf';

    await Share.shareXFiles([
      XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
    ], subject: _subject(sheets, period));
  });

  /// What the mail client puts on the subject line.
  static String _subject(List<BillSheetData> sheets, String period) {
    if (sheets.length == 1) {
      final flat = sheets.single.label;
      return flat.isEmpty
          ? 'Maintenance bill — $period'
          : 'Maintenance bill $flat — $period';
    }
    return 'Maintenance bills — $period';
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

  /// "maintenance-bills-August-2026.pdf", or the flat's own name for a single
  /// sheet — a secretary saving twenty bills should not get twenty files all
  /// called the same thing.
  static String _fileName(List<BillSheetData> sheets, String period) {
    final slug = period.trim().replaceAll(RegExp(r'\s+'), '-');
    final one = sheets.length == 1 ? sheets.single.label : '';
    return [
      'maintenance-bill',
      if (one.isNotEmpty) one,
      if (slug.isNotEmpty) slug,
    ].join('-');
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
