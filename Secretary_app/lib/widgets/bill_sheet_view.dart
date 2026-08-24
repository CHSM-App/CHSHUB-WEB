import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../domain/models/bill_sheet.dart';

/// One flat's bill, drawn as the website draws it.
///
/// The layout is the printed document's, not a phone card's: a bill has to keep
/// its charge table whatever the screen width, so the table stays a table and
/// scrolls sideways if it must rather than collapsing into stacked rows.
class BillSheetView extends StatelessWidget {
  const BillSheetView({super.key, required this.bill});

  final BillSheetData bill;

  static const _line = Color(0xFFCBD5E1);
  static const _head = Color(0xFFF1F5F9);
  static const _grandFill = Color(0xFFFDF1F1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
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
            'MAINTENANCE BILL',
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(fontSize: 15, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          if (bill.societyName != null)
            Text(
              bill.societyName!,
              textAlign: TextAlign.center,
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
            ),
          if (bill.registrationNo != null)
            Text(
              'Registration No: ${bill.registrationNo}',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
          if (bill.address != null)
            Text(
              bill.address!,
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
          const SizedBox(height: 14),
          _particulars(),
          const SizedBox(height: 10),
          _charges(),
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

  Widget _particulars() {
    final cells = bill.particulars;
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

  Widget _charges() {
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
      // The amount column is fixed rather than intrinsic: sized to its content
      // it would stretch for a long charge name and leave the figures adrift
      // from the totals block below, which uses its own proportions.
      columnWidths: const {
        0: FixedColumnWidth(46),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(108),
      },
      children: [
        TableRow(
          children: [
            head('Sr. No'),
            head('Nature of Charges'),
            head('Amount', align: Alignment.centerRight),
          ],
        ),
        if (bill.lines.isEmpty)
          TableRow(
            children: [
              body(''),
              body('No charge lines on this bill.'),
              body(''),
            ],
          )
        else
          for (var i = 0; i < bill.lines.length; i++)
            TableRow(
              children: [
                body('${i + 1}'),
                body(bill.lines[i].name),
                body(
                  '₹ ${sheetAmount(bill.lines[i].amount)}',
                  align: Alignment.centerRight,
                ),
              ],
            ),
      ],
    );
  }

  Widget _totals() {
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
      // Both columns flex. IntrinsicColumnWidth on the figures would size that
      // column to the amount in words — the longest string on the bill — and
      // squeeze the labels down to one character per line.
      columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth()},
      children: [
        row('Total:', '₹ ${sheetAmount(bill.charges)}', bold: true),
        // Hidden when nothing is owed, as the legacy bill did: "Dues as of ...:
        // 0.00" tells a resident with a clean ledger nothing. Any arrears must
        // show — they are usually most of what is payable.
        if (bill.forward != 0)
          row('Dues as of ${bill.billDay}:', '₹ ${sheetAmount(bill.forward)}'),
        row(
          'Grand Total:',
          '₹ ${sheetAmount(bill.grandTotal)}',
          bold: true,
          fill: _grandFill,
        ),
        row('Amount in Words:', amountInWords(bill.grandTotal)),
      ],
    );
  }
}
