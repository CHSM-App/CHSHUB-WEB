import 'package:flutter/material.dart';

import '../core/pdf/receipt_pdf.dart';
import '../core/theme/app_theme.dart';
import '../domain/models/bill_sheet.dart'
    show amountInWords, sheetAmount, sheetDay;

/// One receipt, drawn as a document.
///
/// The same shape the maintenance bill uses: centred title, the society under
/// it, a bordered grid of particulars, then the table of what was settled and
/// a totals block closing with the amount in words. A receipt and a bill are
/// the two halves of one transaction, so they should read as one pair of
/// documents rather than two unrelated screens.
class ReceiptSheetView extends StatelessWidget {
  const ReceiptSheetView({super.key, required this.receipt});

  final ReceiptSheetData receipt;

  static const _line = Color(0xFFCBD5E1);
  static const _head = Color(0xFFF1F5F9);
  static const _totalFill = Color(0xFFEAF7EF);

  bool get _cancelled =>
      receipt.status?.toLowerCase().contains('cancel') ?? false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MAINTENANCE RECEIPT',
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(fontSize: 15, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          if (receipt.societyName != null)
            Text(
              receipt.societyName!,
              textAlign: TextAlign.center,
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
            ),
          // A cancelled receipt says so across the head of the document, not in
          // a chip at the side: it is the single most important thing about the
          // sheet, and anyone reading a reversed payment as collected money has
          // been misled by the layout.
          if (_cancelled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.errorSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.error),
              ),
              child: Text(
                'CANCELLED',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _particulars(),
          const SizedBox(height: 10),
          _bills(),
          const SizedBox(height: 10),
          _totals(),
        ],
      ),
    );
  }

  static Widget _cell(
    Widget child, {
    Color? fill,
    Alignment align = Alignment.centerLeft,
  }) => Container(
    color: fill,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    alignment: align,
    child: child,
  );

  /// The boxes above the table, two to a row — the bill's own particulars grid.
  Widget _particulars() {
    final cells = <MapEntry<String, String>>[
      MapEntry('Receipt No', receipt.receiptNo ?? '—'),
      MapEntry('Date', receipt.date == null ? '—' : sheetDay(receipt.date)),
      MapEntry('Resident', receipt.residentName ?? '—'),
      MapEntry('Unit', receipt.unit ?? '—'),
      MapEntry('Pay Mode', receipt.payMode ?? '—'),
      MapEntry('Bank', receipt.bankName ?? '—'),
      if (receipt.reference != null)
        MapEntry('Cheque / Ref', receipt.reference!),
      // Keeps the grid rectangular: an odd number of cells would leave the
      // last row with a hole where a bordered box should be.
      if (receipt.reference != null)
        MapEntry('Status', receipt.status ?? 'Paid'),
    ];

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      children: [
        for (var i = 0; i < cells.length; i += 2)
          TableRow(
            children: [
              for (final cell in cells.skip(i).take(2))
                _cell(
                  Text(
                    '${cell.key}: ${cell.value}',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkerText,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _bills() {
    Widget head(String text, {Alignment align = Alignment.centerLeft}) => _cell(
      Text(
        text,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.darkerText,
        ),
      ),
      fill: _head,
      align: align,
    );

    Widget body(String text, {Alignment align = Alignment.centerLeft}) =>
        _cell(Text(text, style: AppTheme.caption), align: align);

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      // Fixed rather than intrinsic on the figures: sized to their content the
      // column would stretch for a long period label and leave the amounts
      // adrift from the totals block below.
      columnWidths: const {
        // Wide enough for "Sr. No" on one line: at 46 it wrapped, which made
        // the header row twice the height of every row under it.
        0: FixedColumnWidth(58),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(0.9),
        3: FixedColumnWidth(96),
      },
      children: [
        TableRow(
          children: [
            head('Sr. No'),
            head('Bill No'),
            head('Period'),
            head('Amount', align: Alignment.centerRight),
          ],
        ),
        if (receipt.lines.isEmpty)
          TableRow(
            children: [
              body(''),
              body('No bill lines recorded for this receipt.'),
              body(''),
              body(''),
            ],
          )
        else
          for (var i = 0; i < receipt.lines.length; i++)
            TableRow(
              children: [
                body('${i + 1}'),
                body(receipt.lines[i].billNo ?? '—'),
                body(receipt.lines[i].period ?? '—'),
                body(
                  '₹ ${sheetAmount(receipt.lines[i].amount)}',
                  align: Alignment.centerRight,
                ),
              ],
            ),
      ],
    );
  }

  /// Label left, figure right — the bill's totals block, closing with the
  /// amount in words so the sum cannot be altered after the fact.
  Widget _totals() {
    final settled = receipt.lines.fold<double>(0, (s, l) => s + l.amount);

    TableRow row(
      String label,
      String value, {
      bool bold = false,
      Color? fill,
    }) => TableRow(
      decoration: fill == null ? null : BoxDecoration(color: fill),
      children: [
        _cell(
          Text(
            label,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.darkerText,
            ),
          ),
        ),
        _cell(
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTheme.caption.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppTheme.darkerText : null,
            ),
          ),
          align: Alignment.centerRight,
        ),
      ],
    );

    return Table(
      border: TableBorder.all(color: _line, width: 0.5),
      // The words run long, so the figures column takes the larger share here —
      // at 1.6/1 the amount in words wrapped over four lines against a mostly
      // empty label column.
      columnWidths: const {0: FlexColumnWidth(0.8), 1: FlexColumnWidth()},
      children: [
        // Only when the lines disagree with the receipt: on a receipt that
        // settled exactly what it lists, two identical figures stacked above
        // each other is noise.
        if (receipt.lines.isNotEmpty &&
            (settled - receipt.paidAmount).abs() >= 0.005)
          row('Bills settled:', '₹ ${sheetAmount(settled)}'),
        row(
          'Amount Received:',
          '₹ ${sheetAmount(receipt.paidAmount)}',
          bold: true,
          fill: _cancelled ? null : _totalFill,
        ),
        row('Amount in Words:', amountInWords(receipt.paidAmount)),
      ],
    );
  }
}
