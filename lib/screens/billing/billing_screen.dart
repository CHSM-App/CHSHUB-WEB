import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../hub_scaffold.dart';
import 'bills_screen.dart';
import 'defaulters_screen.dart';
import 'generate_bills_screen.dart';
import 'pdc_screen.dart';
import 'receipts_screen.dart';

/// The billing hub — ordered the way the work actually runs: raise the bills,
/// take the money, chase what is missing.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HubScaffold(
      title: 'Billing & Collection',
      intro:
          'Raise maintenance bills, record what comes in, and follow up on '
          'what has not.',
      entries: [
        HubEntry(
          icon: Icons.playlist_add_check_circle_outlined,
          color: AppTheme.primary,
          title: 'Generate bills',
          subtitle: 'Preview and raise this period’s maintenance',
          builder: () => const GenerateBillsScreen(),
        ),
        HubEntry(
          icon: Icons.receipt_long_outlined,
          color: AppTheme.info,
          title: 'Maintenance bills',
          subtitle: 'Past runs and flat-wise detail',
          builder: () => const BillsScreen(),
        ),
        // One entry, not two. Recording a payment is what produces a receipt,
        // so the form lives as a sheet over the list rather than behind its
        // own hub tile — the arrangement the website uses.
        HubEntry(
          icon: Icons.request_quote_outlined,
          color: AppTheme.teal,
          title: 'Receipts',
          subtitle: 'Payments collected, and record a new one',
          builder: () => const ReceiptsScreen(),
        ),
        HubEntry(
          icon: Icons.report_gmailerrorred_outlined,
          color: AppTheme.error,
          title: 'Defaulters',
          subtitle: 'Flats with dues past their due date',
          builder: () => const DefaultersScreen(),
        ),
        HubEntry(
          icon: Icons.event_note_outlined,
          color: AppTheme.warning,
          title: 'PDC & clearing',
          subtitle: 'Post-dated cheques on file',
          builder: () => const PdcScreen(),
        ),
      ],
    );
  }
}
