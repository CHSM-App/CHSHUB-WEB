import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../domain/models/paged_rows.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';

/// One defaulter's dues, month by month.
///
/// The legacy Defaulter page's Payment Details modal: the resident at the top,
/// then a row per outstanding month with its interest and the amount carried
/// forward, and the total of the two underneath. That total is what the flat
/// actually owes — the tax and the forward amount added, as the legacy page
/// computed it.
class DefaulterDetailScreen extends ConsumerStatefulWidget {
  const DefaulterDetailScreen({
    super.key,
    required this.flatId,
    required this.row,
  });

  final int flatId;

  /// The list row this was opened from. Carries the name, unit and contact
  /// details, which the dues lookup itself does not return.
  final Map<String, dynamic> row;

  @override
  ConsumerState<DefaulterDetailScreen> createState() =>
      _DefaulterDetailScreenState();
}

class _DefaulterDetailScreenState extends ConsumerState<DefaulterDetailScreen> {
  RowList? _dues;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dues = await ref
          .read(billingViewModelProvider.notifier)
          .ownerDues(widget.flatId);
      if (!mounted) return;
      setState(() {
        _dues = dues;
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

  String? get _owner =>
      pick(widget.row, ['owner_name', 'owner', 'name', 'resident_name']);

  String? get _unit =>
      pick(widget.row, ['Unit', 'flat_no', 'unit_no', 'flat', 'flat_name']);

  String? get _mobile =>
      pick(widget.row, ['pre_mob', 'contact_no', 'mobile_no', 'phone']);

  String? get _email => pick(widget.row, ['email']);

  /// Interest and carried-forward amounts, added — what the flat owes.
  ///
  /// The legacy page summed both columns and printed the pair as "Total Amount
  /// Forward"; the forward figure alone understates the debt by every rupee of
  /// interest on it.
  double get _total {
    final rows = _dues?.items ?? const <Map<String, dynamic>>[];
    return rows.fold<double>(
      0,
      (sum, r) =>
          sum +
          asDoubleOr(r['amt_forward']) +
          asDoubleOr(r['tax_interest_amt']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment details'),
        actions: [
          if (_mobile != null)
            IconButton(
              tooltip: 'Call',
              icon: const Icon(Icons.phone_outlined),
              onPressed: () => _launch(Uri(scheme: 'tel', path: _mobile)),
            ),
          if (_mobile != null)
            IconButton(
              tooltip: 'SMS',
              icon: const Icon(Icons.sms_outlined),
              onPressed: () => _launch(
                Uri(
                  scheme: 'sms',
                  path: _mobile,
                  queryParameters: {'body': _reminder()},
                ),
              ),
            ),
          if (_email != null)
            IconButton(
              tooltip: 'Email',
              icon: const Icon(Icons.mail_outline_rounded),
              onPressed: () => _launch(
                Uri(
                  scheme: 'mailto',
                  path: _email,
                  queryParameters: {
                    'subject': 'Maintenance dues reminder',
                    'body': _reminder(),
                  },
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  /// The reminder text, with the figure filled in.
  String _reminder() {
    final owner = _owner ?? 'Resident';
    final unit = _unit == null ? '' : ' ($_unit)';
    return 'Dear $owner$unit, our records show maintenance dues of '
        '${money(_total)} outstanding. Kindly arrange payment at your '
        'earliest convenience. Thank you.';
  }

  Future<void> _launch(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await launchUrl(uri);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No app on this device can open that.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open: $e')));
    }
  }

  Widget _buildBody() {
    if (_loading && _dues == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _dues == null) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.error,
        title: 'Could not load the dues',
        message: errorText(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }

    final months = _dues?.items ?? const <Map<String, dynamic>>[];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
        children: [
          PageConstraints(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: AppTheme.space4),
                _monthsTable(months),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        gradient: AppTheme.duesGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.glow(AppTheme.error, opacity: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _owner ?? 'Resident',
            style: AppTheme.title.copyWith(fontSize: 17, color: AppTheme.white),
          ),
          if (_unit != null) ...[
            const SizedBox(height: 2),
            Text(
              _unit!,
              style: AppTheme.caption.copyWith(color: AppTheme.onGradientMuted),
            ),
          ],
          const SizedBox(height: AppTheme.space4),
          Text(
            'TOTAL OUTSTANDING',
            style: AppTheme.overline.copyWith(color: AppTheme.onGradientMuted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(_total),
              style: AppTheme.headline.copyWith(color: AppTheme.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Month, interest, carried forward — the legacy grid's three columns.
  Widget _monthsTable(List<Map<String, dynamic>> months) {
    const line = Color(0xFFCBD5E1);
    const head = Color(0xFFF1F5F9);

    Widget cell(
      String text, {
      bool bold = false,
      bool right = false,
      Color? fill,
    }) => Container(
      color: fill,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: bold ? AppTheme.darkerText : null,
        ),
      ),
    );

    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            months.isEmpty
                ? 'OUTSTANDING MONTHS'
                : 'OUTSTANDING MONTHS (${months.length})',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          if (months.isEmpty)
            Text('No payment details available.', style: AppTheme.caption)
          else
            Table(
              border: TableBorder.all(color: line, width: 0.5),
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FixedColumnWidth(84),
                2: FixedColumnWidth(96),
              },
              children: [
                TableRow(
                  children: [
                    cell('Month', bold: true, fill: head),
                    cell('Tax', bold: true, right: true, fill: head),
                    cell('Amount Forward', bold: true, right: true, fill: head),
                  ],
                ),
                for (final month in months)
                  TableRow(
                    children: [
                      cell(pick(month, ['month']) ?? '—'),
                      cell(money(month['tax_interest_amt']), right: true),
                      cell(money(month['amt_forward']), right: true),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
