import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../hub_scaffold.dart';
import 'cashbook_screen.dart';
import 'expenses_screen.dart';
import 'ledger_screen.dart';
import 'vendor_bills_screen.dart';

/// Day-to-day money entry.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HubScaffold(
      title: 'Accounts',
      intro: 'What the society spends and receives, and the vendors behind it.',
      entries: [
        HubEntry(
          icon: Icons.payments_outlined,
          color: AppTheme.error,
          title: 'Society expenses',
          subtitle: 'Record and review what the society spends',
          builder: () => const ExpensesScreen(),
        ),
        HubEntry(
          icon: Icons.menu_book_outlined,
          color: AppTheme.primary,
          title: 'Cashbook',
          subtitle: 'Cash in and out over a date range',
          builder: () => const CashbookScreen(),
        ),
        HubEntry(
          icon: Icons.account_balance_outlined,
          color: AppTheme.info,
          title: 'Ledger & credits',
          subtitle: 'Ledger, other credits and shop maintenance',
          builder: () => const LedgerScreen(),
        ),
        HubEntry(
          icon: Icons.storefront_outlined,
          color: AppTheme.warning,
          title: 'Vendors & bills',
          subtitle: 'Vendor bills, approvals and payments',
          builder: () => const VendorBillsScreen(),
        ),
      ],
    );
  }
}
