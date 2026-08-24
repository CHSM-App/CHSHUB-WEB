import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/accounts_viewmodel.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';

// ── The three books, and the columns each one actually returns ────────────
//
// These tabs are not one shape in three colours. Each is a different stored
// procedure with its own column names, and sp_ManageOtherCredits answers in
// PascalCase where the other two are lower_snake. A single "guess the column"
// row builder read none of them correctly — every card fell back to the word
// "Entry" against a zero — so each tab reads the names its own SP returns,
// taken from the columns the website's grids declare:
//
//   Ledger            led_description, led_status, date        (sp_ledger)
//   Other credits     Description, Amount, PaymentDate         (sp_ManageOtherCredits)
//   Shop maintenance  mrep_no, m_date, led_description,        (sp_shop_maintenance)
//                     amt, pay_method
//
// Society receipts had a fourth tab here. It was dropped: sp_SocietyReceipt
// holds a handful of rows society-wide, and its insert path fails on a
// missing MonthwiseCharges table, so the tab could only ever read empty.
enum _Book {
  ledger(
    label: 'Ledger',
    icon: Icons.menu_book_rounded,
    accent: AppTheme.primary,
    emptyTitle: 'Ledger is empty',
    emptyMessage: 'Heads of account appear here once they are created.',
  ),
  otherCredits(
    label: 'Other credits',
    icon: Icons.savings_rounded,
    accent: AppTheme.violet,
    emptyTitle: 'No other credits',
    emptyMessage: 'Income that is not maintenance shows here.',
  ),
  shopMaintenance(
    label: 'Shop',
    icon: Icons.storefront_rounded,
    accent: AppTheme.teal,
    emptyTitle: 'No shop maintenance',
    emptyMessage: 'Maintenance billed to commercial units shows here.',
  );

  const _Book({
    required this.label,
    required this.icon,
    required this.accent,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String emptyTitle;
  final String emptyMessage;

  String get key => switch (this) {
    _Book.ledger => AccountsKeys.ledger,
    _Book.otherCredits => AccountsKeys.otherCredits,
    _Book.shopMaintenance => AccountsKeys.shopMaintenance,
  };

  /// What one row of this book is worth, read from the column the SP returns.
  ///
  /// The ledger is a list of account heads rather than transactions, so it has
  /// no amount at all — hence the nullable return, which is what stops a
  /// column of ₹0.00 being printed against every head.
  double? amountOf(Map<String, dynamic> row) => switch (this) {
    _Book.ledger => null,
    _Book.otherCredits => asDouble(row['Amount']),
    _Book.shopMaintenance => asDouble(row['amt']),
  };

  /// Every value a search should match, so filtering works on what is read.
  String haystack(Map<String, dynamic> row) => switch (this) {
    _Book.ledger => [row['led_description'], row['led_status']].join(' '),
    _Book.otherCredits => [row['Description'], row['Amount']].join(' '),
    _Book.shopMaintenance => [
      row['mrep_no'],
      row['led_description'],
      row['pay_method'],
    ].join(' '),
  }.toLowerCase();
}

/// The read-only money views, grouped because they are all "dated rows with a
/// figure" — three hub entries would cost a trip to the hub to move between
/// them, where tabs cost one tap.
class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: _Book.values.length,
    vsync: this,
  );
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Narrowed here rather than at the API. Two of the three SPs do take a
  /// search term, but sp_ManageOtherCredits takes none — the website filters
  /// that one in the browser for the same reason. Filtering all three the same
  /// way keeps the box behaving identically whichever tab is in front, and
  /// spares a round trip per keystroke on lists already in hand.
  String _query = '';

  _Book get _book => _Book.values[_tabs.index];

  @override
  void initState() {
    super.initState();
    // The pills read the controller's index, so a swipe has to repaint them —
    // otherwise the filled pill and the list on screen disagree.
    _tabs.addListener(_onTabChanged);
    Future.microtask(_refreshAll);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() =>
      ref.read(accountsViewModelProvider.notifier).loadBooks();

  Future<void> _refresh(_Book book) {
    final vm = ref.read(accountsViewModelProvider.notifier);
    return switch (book) {
      _Book.ledger => vm.loadLedger(),
      _Book.otherCredits => vm.loadOtherCredits(),
      _Book.shopMaintenance => vm.loadShopMaintenance(),
    };
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  List<Map<String, dynamic>> _filter(
    _Book book,
    List<Map<String, dynamic>> rows,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) => book.haystack(r).contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ledger & credits')),
      body: SafeArea(
        child: Column(
          children: [
            // A pill switcher rather than Material's underline tabs, matching
            // Vendors & bills: it sits on the page as a control of its own,
            // states the pick with a filled plate, and carries the row count
            // so the choice is informed before it is made.
            _PillTabs(
              index: _tabs.index,
              onChanged: (i) => setState(() => _tabs.index = i),
              tabs: [
                for (final b in _Book.values)
                  (
                    label: b.label,
                    icon: b.icon,
                    count: state.items(b.key).length,
                  ),
              ],
            ),
            SearchBarArea(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: 'Search ${_book.label.toLowerCase()}',
            ),
            _buildSummary(state.items(_book.key)),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [for (final b in _Book.values) _buildTab(b, state)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Count and total for the book in front.
  ///
  /// The ledger is left without a total on purpose — it lists heads of
  /// account, not transactions, so a sum over it would be a number with no
  /// meaning behind it.
  Widget _buildSummary(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final book = _book;
    final shown = _filter(book, rows);
    final amounts = shown
        .map(book.amountOf)
        .whereType<double>()
        .toList(growable: false);
    final total = amounts.fold<double>(0, (s, a) => s + a);

    return PageConstraints(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space2),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MiniStat(
                  label: _query.trim().isEmpty ? 'Entries' : 'Matches',
                  value: '${shown.length}',
                  icon: book.icon,
                  color: book.accent,
                ),
              ),
              if (amounts.isNotEmpty) ...[
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  flex: 2,
                  child: _MiniStat(
                    label: 'Total',
                    value: compactMoney(total),
                    icon: Icons.currency_rupee_rounded,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(_Book book, ListState state) {
    return RowsView(
      rows: state.rows(book.key),
      onRefresh: () => _refresh(book),
      emptyIcon: book.icon,
      emptyTitle: book.emptyTitle,
      emptyMessage: book.emptyMessage,
      builder: (items) {
        final matches = _filter(book, items);

        // A search that matches nothing is not an empty book, and saying so
        // keeps the secretary from reading it as the rows having gone.
        if (matches.isEmpty) {
          return StateMessage(
            icon: Icons.search_off_rounded,
            title: 'Nothing matches',
            message:
                '${items.length} entr${items.length == 1 ? 'y' : 'ies'} here, '
                'none matching "${_query.trim()}".',
            actionLabel: 'Clear search',
            onAction: _clearSearch,
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space4,
            AppTheme.space1,
            AppTheme.space4,
            AppTheme.space6,
          ),
          itemCount: matches.length,
          itemBuilder: (context, i) => _buildRow(book, matches[i], i),
        );
      },
    );
  }

  Widget _buildRow(_Book book, Map<String, dynamic> row, int index) {
    return switch (book) {
      _Book.ledger => _buildLedgerRow(row),
      _Book.otherCredits => _buildCreditRow(row, index),
      _Book.shopMaintenance => _buildShopRow(row),
    };
  }

  /// A head of account: its description, and the status it carries.
  Widget _buildLedgerRow(Map<String, dynamic> row) {
    final description = pick(row, ['led_description']);
    final status = pick(row, ['led_status']);

    return _BookCard(
      accent: AppTheme.primary,
      icon: Icons.menu_book_rounded,
      title: description ?? 'Untitled head',
      subtitle: [
        if (status != null) status,
        prettyDate(row['date']),
      ].where((s) => s != '—').join(' · '),
      trailing: status == null
          ? null
          : StatusChip(label: status, color: statusColor(status)),
    );
  }

  /// Income that is not maintenance. PascalCase columns, per its SP.
  Widget _buildCreditRow(Map<String, dynamic> row, int index) {
    final description = pick(row, ['Description']);

    return _BookCard(
      accent: AppTheme.violet,
      icon: Icons.savings_rounded,
      // The legacy grid numbered these by position and had no other handle on
      // a row, so the number is kept as the leading badge.
      leadingText: '${index + 1}',
      title: description ?? 'Credit',
      subtitle: prettyDate(row['PaymentDate']),
      amount: asDouble(row['Amount']),
      amountColor: AppTheme.violet,
    );
  }

  /// Maintenance billed to a commercial unit.
  Widget _buildShopRow(Map<String, dynamic> row) {
    final reportNo = pick(row, ['mrep_no']);
    final head = pick(row, ['led_description']);
    final method = pick(row, ['pay_method']);
    final cheque = pick(row, ['cheq_no']);

    return _BookCard(
      accent: AppTheme.teal,
      icon: Icons.storefront_rounded,
      title: head ?? 'Shop maintenance',
      subtitle: [
        if (reportNo != null) 'Receipt $reportNo',
        prettyDate(row['m_date']),
        // Cheque and UPI both land in cheq_no — the SP has one column for the
        // reference whichever way it was paid.
        if (cheque != null) 'Ref $cheque',
      ].where((s) => s != '—').join(' · '),
      amount: asDouble(row['amt']),
      amountColor: AppTheme.teal,
      trailing: method == null
          ? null
          : StatusChip(label: method, color: AppTheme.info),
    );
  }
}

/// One row of any book.
///
/// Shared across the four tabs so they read as one page: a coloured spine and
/// icon plate for the book, the title and its details on the left, the figure
/// and a chip on the right. Each tab fills it from its own columns — the
/// layout is common, the field names are not.
class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.amount,
    this.amountColor,
    this.trailing,
    this.leadingText,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final double? amount;
  final Color? amountColor;
  final Widget? trailing;
  final String? leadingText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceFor(accent),
              borderRadius: BorderRadius.circular(9),
            ),
            child: leadingText != null
                ? Text(
                    leadingText!,
                    style: AppTheme.title.copyWith(fontSize: 13, color: accent),
                  )
                : Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.title.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          // The right column is only built when there is something to put in
          // it — a book without amounts (the ledger) must not print ₹0.00.
          if (amount != null || trailing != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (amount != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        money(amount),
                        maxLines: 1,
                        style: AppTheme.title.copyWith(
                          fontSize: 15,
                          color: amountColor ?? AppTheme.darkText,
                        ),
                      ),
                    ),
                  if (trailing != null) ...[
                    if (amount != null) const SizedBox(height: 5),
                    trailing!,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A pill switcher — one filled plate per book, with its count.
///
/// The same control Vendors & bills uses, scrolling here because four tabs do
/// not fit a phone's width as equal shares: at four, "Shop maintenance" would
/// be squeezed to an ellipsis. Each pill sizes to its own label instead, and
/// the strip scrolls if the four together are wider than the screen.
class _PillTabs extends StatelessWidget {
  const _PillTabs({
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<({String label, IconData icon, int count})> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PageConstraints(
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.space3),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.spacer,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Wide windows have room to spare, so the strip fills it rather
            // than huddling at the left edge.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    MediaQuery.sizeOf(context).width > Breakpoints.readableWidth
                    ? Breakpoints.readableWidth - 42
                    : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, tab) in tabs.indexed)
                    _Pill(
                      tab: tab,
                      selected: i == index,
                      onTap: () => onChanged(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.tab, required this.selected, required this.onTap});

  final ({String label, IconData icon, int count}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        elevation: selected ? 2 : 0,
        shadowColor: AppTheme.primary.withValues(alpha: 0.35),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 16,
                  color: selected ? AppTheme.white : AppTheme.lightText,
                ),
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  maxLines: 1,
                  style: AppTheme.body2.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.white : AppTheme.lightText,
                  ),
                ),
                // Hidden while a list is still empty, so a loading tab does
                // not claim it holds nothing.
                if (tab.count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.white.withValues(alpha: 0.24)
                          : AppTheme.border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      '${tab.count}',
                      style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppTheme.white : AppTheme.lightText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A figure with its label, in a bordered plate — the header stat from
/// Vendors & bills, so the two Accounts pages head themselves the same way.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFor(color),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 7),
          // The figure has to survive a narrow share of a phone, so it scales
          // down rather than overflowing — an overflow here would abort layout
          // for the whole header.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTheme.title.copyWith(fontSize: 14),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
