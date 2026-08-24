import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/billing_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'defaulter_detail_screen.dart';

/// Flats whose dues are past their due date.
class DefaultersScreen extends ConsumerStatefulWidget {
  const DefaultersScreen({super.key});

  @override
  ConsumerState<DefaultersScreen> createState() => _DefaultersScreenState();
}

class _DefaultersScreenState extends ConsumerState<DefaultersScreen> {
  /// Flats ticked for a reminder, keyed by flat id.
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() =>
      ref.read(billingViewModelProvider.notifier).loadDefaulters();

  static int? _flatId(Map<String, dynamic> row) =>
      pickInt(row, ['flat_id', 'flatId', 'FlatID']);

  static String? _mobile(Map<String, dynamic> row) =>
      pick(row, ['pre_mob', 'contact_no', 'mobile_no', 'phone']);

  static String? _email(Map<String, dynamic> row) => pick(row, ['email']);

  /// The reminder the legacy page's message box carried, with the society's
  /// own figure filled in per flat.
  static String _reminder(Map<String, dynamic> row) {
    final owner =
        pick(row, ['owner_name', 'owner', 'name', 'resident_name']) ??
        'Resident';
    final unit = pick(row, ['Unit', 'flat_no', 'unit_no', 'flat']);
    final due = money(row['due'] ?? row['due_amount'] ?? row['total_due']);

    return 'Dear $owner${unit == null ? '' : ' ($unit)'}, our records show '
        'maintenance dues of $due outstanding. Kindly arrange payment at your '
        'earliest convenience. Thank you.';
  }

  /// Hand the selection to the device's own SMS or mail app.
  ///
  /// There is no send endpoint on the server — the legacy page had .NET's mail
  /// service behind it, which the app cannot call. Composing locally is also
  /// the better fit on a phone: the reminder goes from the secretary's own
  /// number or address, where a reply reaches a person rather than a server.
  Future<void> _remind(
    List<Map<String, dynamic>> rows, {
    required bool email,
  }) async {
    final picked = rows.where((r) {
      final id = _flatId(r);
      return id != null && _selected.contains(id);
    }).toList();

    final recipients = picked
        .map((r) => email ? _email(r) : _mobile(r))
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .toList();

    final messenger = ScaffoldMessenger.of(context);

    if (recipients.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            email
                ? 'None of the selected flats has an email address on file.'
                : 'None of the selected flats has a mobile number on file.',
          ),
        ),
      );
      return;
    }

    // One recipient gets their own figure; several share a general reminder,
    // since a single message cannot quote a different amount to each.
    final body = picked.length == 1
        ? _reminder(picked.first)
        : 'Dear resident, our records show maintenance dues outstanding '
              'against your flat. Kindly arrange payment at your earliest '
              'convenience. Thank you.';

    final uri = email
        ? Uri(
            scheme: 'mailto',
            path: recipients.join(','),
            queryParameters: {
              'subject': 'Maintenance dues reminder',
              'body': body,
            },
          )
        : Uri(
            scheme: 'sms',
            path: recipients.join(','),
            queryParameters: {'body': body},
          );

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

  void _openDetail(Map<String, dynamic> row) {
    final id = _flatId(row);
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DefaulterDetailScreen(flatId: id, row: row),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingViewModelProvider);
    final rows = state.rows(BillingKeys.defaulters);
    final data = rows.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Defaulters')),
      body: SafeArea(
        child: Column(
          children: [
            if (data != null && data.items.isNotEmpty)
              PageConstraints(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space4),
                  child: _buildSummary(data.count, data.totalDue ?? 0),
                ),
              ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.verified_outlined,
                emptyTitle: 'No defaulters',
                emptyMessage: 'Every flat is up to date on its dues.',
                builder: (items) => Column(
                  children: [
                    _selectionBar(items),
                    Expanded(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: Breakpoints.pagePadding(
                          context,
                        ).copyWith(bottom: 110),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _buildRow(items[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The total owed, on one line.
  ///
  /// Label, figure and flat count sat stacked over three rows and took most of
  /// a phone's first screen before a single defaulter showed. The figure is
  /// what the panel is for; the rest rides beside it.
  Widget _buildSummary(int count, double totalDue) {
    return GradientPanel(
      // Crimson for the same reason the dashboard hero is: this whole screen is
      // money the society has not been paid.
      gradient: AppTheme.duesGradient,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL OUTSTANDING',
                  style: AppTheme.overline.copyWith(
                    color: AppTheme.onGradientMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    moneyFlat(totalDue),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: AppTheme.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Text(
            '$count ${count == 1 ? 'flat' : 'flats'}',
            style: AppTheme.caption.copyWith(color: AppTheme.onGradientMuted),
          ),
        ],
      ),
    );
  }

  /// Select-all and the two reminder actions.
  ///
  /// Hidden until something is ticked, apart from Select all: a bar of dead
  /// buttons over a list nobody has touched is just lost height.
  Widget _selectionBar(List<Map<String, dynamic>> items) {
    final ids = items.map(_flatId).whereType<int>().toSet();
    if (ids.isEmpty) return const SizedBox.shrink();

    final allSelected = ids.every(_selected.contains);
    final count = _selected.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        0,
        AppTheme.space3,
        AppTheme.space2,
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              if (allSelected) {
                _selected.removeAll(ids);
              } else {
                _selected.addAll(ids);
              }
            }),
            icon: Icon(
              allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded,
              size: 18,
            ),
            label: Text(allSelected ? 'Clear all' : 'Select all'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          if (count > 0) ...[
            Text('$count selected', style: AppTheme.caption),
            const SizedBox(width: AppTheme.space2),
            IconButton(
              tooltip: 'Send SMS',
              icon: const Icon(Icons.sms_outlined, size: 20),
              color: AppTheme.primary,
              visualDensity: VisualDensity.compact,
              onPressed: () => _remind(items, email: false),
            ),
            IconButton(
              tooltip: 'Send email',
              icon: const Icon(Icons.mail_outline_rounded, size: 20),
              color: AppTheme.primary,
              visualDensity: VisualDensity.compact,
              onPressed: () => _remind(items, email: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final flat = pick(row, ['Unit', 'flat_no', 'unit_no', 'flat', 'flat_name']);
    final owner = pick(row, ['owner_name', 'owner', 'name', 'resident_name']);
    final contact = _mobile(row);
    final bed = pick(row, ['bed']);
    final id = _flatId(row);
    final selected = id != null && _selected.contains(id);

    return AppCard(
      accent: AppTheme.error,
      // The card opens the breakdown; the checkbox is a target of its own, so
      // ticking for a reminder does not navigate away from the list.
      onTap: id == null ? null : () => _openDetail(row),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (id != null)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Checkbox(
                value: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selected.add(id);
                  } else {
                    _selected.remove(id);
                  }
                }),
              ),
            ),
          InitialsAvatar(name: owner),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner ?? 'Resident',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  [flat, bed].where((e) => e != null).join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption,
                ),
                if (contact != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppTheme.lightText,
                      ),
                      const SizedBox(width: 4),
                      // Expanded, not a bare Text: a long number on a narrow
                      // phone otherwise pushes the Row past its width.
                      Expanded(
                        child: Text(
                          contact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(row['due'] ?? row['due_amount'] ?? row['total_due']),
                style: AppTheme.numeralSm.copyWith(color: AppTheme.error),
              ),
              const SizedBox(height: AppTheme.space2),
              const StatusChip(label: 'Overdue', color: AppTheme.error),
              if (id != null) ...[
                const SizedBox(height: 2),
                // The legacy page's "View Details" link, in the app's own
                // shape — the card already opens it, and this names the action.
                Text(
                  'View details',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
