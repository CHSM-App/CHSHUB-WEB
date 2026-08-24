import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pdf/receipt_export.dart';
import '../../core/pdf/receipt_pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/receipt_sheet_view.dart';

/// One receipt and everything it settled.
///
/// The website's view modal, as a page: identity first, then who paid, then
/// how, then the bills it cleared — the order the legacy Payment Summary modal
/// used, and the order a reader checks a receipt in.
class ReceiptDetailScreen extends ConsumerStatefulWidget {
  const ReceiptDetailScreen({super.key, required this.receiptId});

  final int receiptId;

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  Map<String, dynamic>? _detail;
  Object? _error;
  bool _loading = true;

  /// True while a PDF is being built, so the three actions can show progress
  /// without the bar shifting under the finger that tapped one.
  final ValueNotifier<bool> _exporting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _exporting.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ref
          .read(billingViewModelProvider.notifier)
          .receiptDetail(widget.receiptId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// The receipt in the shape the sheet and the PDF both read.
  ReceiptSheetData? get _sheet {
    final receipt = asRow(_detail?['receipt']);
    if (receipt.isEmpty) return null;

    // A row with no bill number is the receipt header repeating, not a settled
    // bill — GETRECEIPT returns both in one result set.
    final lines = asRows(_detail?['lines'])
        .where((l) => pick(l, ['Billno', 'bill_no', 'bill_ref']) != null)
        .map(
          (l) => ReceiptLine(
            billNo: pick(l, ['Billno', 'bill_no']),
            period: pick(l, ['bill_ref']),
            dueDate: asDate(l['gen_date']),
            amount: asDoubleOr(l['amount']),
          ),
        )
        .toList();

    return ReceiptSheetData(
      receiptNo: pick(receipt, ['receipt_no', 'voucher_no']),
      date: asDate(receipt['date'] ?? receipt['receipt_date']),
      status: pick(receipt, ['bill_status', 'status']),
      // GETRECEIPT returns `name`; Grid_Show calls the same thing `owner`, so
      // both are read rather than assuming which procedure fed this row.
      residentName: pick(receipt, [
        'name',
        'owner',
        'owner_name',
        'resident_name',
      ]),
      unit: pick(receipt, ['unit', 'flat_no']),
      societyName: pick(receipt, ['society_name']),
      payMode: pick(receipt, ['pay_mode', 'payment_mode']),
      reference: pick(receipt, ['transaction_ref', 'cheque_no']),
      bankName: pick(receipt, ['bank_name']),
      paidAmount: asDoubleOr(receipt['paid_amount'] ?? receipt['amount']),
      lines: lines,
    );
  }

  Future<void> _export(
    ReceiptSheetData receipt, {
    bool print = false,
    bool share = false,
  }) async {
    if (_exporting.value) return;
    _exporting.value = true;
    try {
      if (print) {
        await ReceiptExport.print(context, receipt);
      } else if (share) {
        await ReceiptExport.share(context, receipt);
      } else {
        await ReceiptExport.download(context, receipt);
      }
    } finally {
      if (mounted) _exporting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        // Only once there is a receipt to export — three live-looking actions
        // over a failed load would each do nothing when tapped.
        actions: sheet == null
            ? null
            : [
                ListenableBuilder(
                  listenable: _exporting,
                  builder: (_, _) => Row(
                    children: [
                      _AppBarAction(
                        icon: Icons.download_rounded,
                        tooltip: 'Download',
                        color: AppTheme.primary,
                        busy: _exporting.value,
                        onTap: () => _export(sheet),
                      ),
                      const SizedBox(width: 6),
                      _AppBarAction(
                        icon: Icons.print_rounded,
                        tooltip: 'Print',
                        color: AppTheme.violet,
                        busy: _exporting.value,
                        onTap: () => _export(sheet, print: true),
                      ),
                      const SizedBox(width: 6),
                      _AppBarAction(
                        icon: Icons.share_rounded,
                        tooltip: 'Share',
                        color: AppTheme.teal,
                        busy: _exporting.value,
                        onTap: () => _export(sheet, share: true),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _detail == null) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.error,
        title: 'Could not load the receipt',
        message: errorText(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    final sheet = _sheet;
    if (sheet == null) {
      return const StateMessage(
        icon: Icons.receipt_outlined,
        title: 'Receipt details unavailable',
        message: 'The server returned no detail for it.',
      );
    }

    // The document itself, in the same format the maintenance bill uses — a
    // receipt and a bill are two halves of one transaction, so they read as a
    // pair rather than as two unrelated screens.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
        children: [PageConstraints(child: ReceiptSheetView(receipt: sheet))],
      ),
    );
  }
}

/// One export action in the app bar, on its own tinted plate — the same
/// treatment the bill sheets use, so the two screens read as one app.
class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm + 2);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: !busy,
        label: tooltip,
        child: Opacity(
          opacity: busy ? 0.55 : 1,
          child: Material(
            color: AppTheme.surfaceFor(color),
            borderRadius: radius,
            child: InkWell(
              onTap: busy ? null : onTap,
              borderRadius: radius,
              child: SizedBox(
                height: 38,
                width: 38,
                child: Center(
                  child: busy
                      ? SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(icon, size: 19, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
