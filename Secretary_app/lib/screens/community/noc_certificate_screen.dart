import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/pdf/noc_export.dart';
import '../../core/pdf/noc_pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';
import 'form_fields.dart';

/// Who this society has its certificates signed by, from account settings.
///
/// Read off the certificate list, which carries it alongside the rows — it is
/// one setting for the whole society, so a call per sheet would ask the same
/// question over and over. Falls back to both officers under their usual names
/// while the list is still loading, and against a server that does not send
/// it, which is what the sheet printed before this was configurable.
NocSignatories nocSignatoriesOf(WidgetRef ref) {
  final rows = ref
      .watch(communityViewModelProvider)
      .rows(CommunityKeys.nocCertificates)
      .valueOrNull;

  return NocSignatories.fromJson(rows?.signatories);
}

/// The kinds of NOC a society issues, and the clause each one turns on.
///
/// The wording follows the letter a registered co-operative housing society
/// actually puts out: it certifies a fact about the flat as on a date, and
/// records that the society has no objection to what the member asked for.
enum NocKind {
  noDues(
    'No dues',
    Icons.receipt_long_outlined,
    'to the issue of this certificate, all maintenance charges and other '
        'dues payable in respect of the said flat having been paid in full '
        'as on the date of this certificate.',
  ),
  saleTransfer(
    'Sale / transfer',
    Icons.swap_horiz_rounded,
    'to the sale and transfer of the said flat by the member, and holds no '
        'claim, charge or lien over the said flat other than its dues, '
        'if any.',
  ),
  renovation(
    'Renovation',
    Icons.handyman_outlined,
    'to the internal repairs and renovation work proposed by the member in '
        'the said flat, subject to no damage being caused to the structure '
        'of the building.',
  ),
  mortgage(
    'Mortgage / loan',
    Icons.account_balance_outlined,
    'to the member mortgaging the said flat to a bank or financial '
        'institution for the purpose of availing a loan.',
  ),
  general(
    'General',
    Icons.description_outlined,
    'to the requested purpose mentioned below in respect of the said flat.',
  ),

  /// For a NOC the society words itself. Its clause is empty because the
  /// sentence comes from the certificate, not from the type — see
  /// [NocRecord.clause].
  other('Other', Icons.edit_outlined, '');

  const NocKind(this.label, this.icon, this.clause);

  final String label;
  final IconData icon;

  /// What the society raises no objection to, completing the sentence
  /// "The society has no objection …" on the certificate. Empty for [other],
  /// which carries its wording on the record instead.
  final String clause;

  /// Whether the secretary types the certificate's wording themselves.
  bool get isCustom => this == NocKind.other;

  /// The value stored in noc_certificate.noc_type.
  String get code => switch (this) {
    NocKind.noDues => 'NoDues',
    NocKind.saleTransfer => 'SaleTransfer',
    NocKind.renovation => 'Renovation',
    NocKind.mortgage => 'Mortgage',
    NocKind.general => 'General',
    NocKind.other => 'Other',
  };

  /// Reads a stored noc_type back. Falls back to [general] rather than
  /// throwing: a row written by a newer build must still list and print.
  static NocKind fromCode(String? code) => NocKind.values.firstWhere(
    (k) => k.code.toLowerCase() == (code ?? '').toLowerCase(),
    orElse: () => NocKind.general,
  );
}

/// One issued certificate — a row of noc_certificate, as the screen reads it.
class NocRecord {
  NocRecord({
    required this.serial,
    required this.kind,
    required this.member,
    required this.flat,
    required this.building,
    required this.purpose,
    required this.issuedOn,
    required this.validTill,
    required this.remarks,
    this.customTitle = '',
    this.customClause = '',
    this.id,
  });

  /// One row of sp_noc_certificate 'Grid_Show'.
  factory NocRecord.fromRow(Map<String, dynamic> row) {
    String text(List<String> keys) => pick(row, keys) ?? '';

    return NocRecord(
      id: pickInt(row, ['noc_id']),
      serial: text(['serial_no']),
      kind: NocKind.fromCode(pick(row, ['noc_type'])),
      member: text(['member_name']),
      flat: text(['flat_no']),
      building: text(['building_name']),
      purpose: text(['purpose']),
      issuedOn: asDate(row['issued_on']) ?? DateTime.now(),
      validTill: asDate(row['valid_till']),
      remarks: text(['remarks']),
      customTitle: text(['custom_title']),
      customClause: text(['clause']),
    );
  }

  /// noc_certificate.noc_id, absent only for a record not yet saved.
  final int? id;

  final String serial;
  final NocKind kind;
  final String member;
  final String flat;

  /// Wing or building the flat sits in; blank when the society has none.
  final String building;
  final String purpose;
  final DateTime issuedOn;
  final DateTime? validTill;
  final String remarks;

  /// What an [NocKind.other] certificate calls itself, shown where the type
  /// name would otherwise appear. Empty for every built-in kind.
  final String customTitle;

  /// The wording an [NocKind.other] certificate certifies. Empty for every
  /// built-in kind, which take their sentence from [NocKind.clause].
  final String customClause;

  /// What the certificate calls itself on the letter and in the list.
  String get typeLabel =>
      kind.isCustom && customTitle.isNotEmpty ? customTitle : kind.label;

  /// The sentence completing "The society has no objection …".
  ///
  /// The wording written onto the certificate wins: it starts as the type's
  /// standard clause and the secretary may rewrite it. Falls back to the
  /// type's own wording only if it somehow arrived blank.
  String get clause {
    if (customClause.isNotEmpty) return customClause;
    return kind.clause.isNotEmpty
        ? kind.clause
        : 'to the requested purpose mentioned below in respect of the said '
              'flat.';
  }

  /// A certificate with no end date does not lapse; one with a past end date
  /// has. Drives the chip on the list row.
  bool get isExpired =>
      validTill != null &&
      validTill!.isBefore(DateUtils.dateOnly(DateTime.now()));
}

/// NOC certificates — the list of what the society has issued, and the form
/// that issues a new one.
class NocCertificateScreen extends ConsumerStatefulWidget {
  const NocCertificateScreen({super.key, this.embedded = false});

  /// Set when this sits inside [NocScreen]'s tabs, which carry the app bar and
  /// the "new certificate" button for both halves. Left false, the screen
  /// stands on its own with an app bar of its own — how it is still opened
  /// from a deep link or a test.
  final bool embedded;

  @override
  ConsumerState<NocCertificateScreen> createState() =>
      _NocCertificateScreenState();
}

/// The filter menu's two non-type entries. Plain strings rather than an enum:
/// the menu is keyed by [NocKind]?, and these only have to be distinguishable
/// from a kind and from null.
const _dateFilterKey = 'pick-dates';
const _clearDatesKey = 'clear-dates';

class _NocCertificateScreenState extends ConsumerState<NocCertificateScreen> {
  /// Which kind the list is narrowed to; null is all of them.
  NocKind? _filter;

  final _searchController = TextEditingController();

  /// Narrows the loaded rows in the client rather than refetching: the list is
  /// one society's certificates, small enough that a round trip per keystroke
  /// would be slower than filtering what is already here.
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Issue dates the list is narrowed to; null is every date.
  DateTimeRange? _dateRange;

  /// Matched on the four things a caller asking about a certificate knows:
  /// whose it is, which flat, the number on the paper, and when it was issued.
  bool _matches(NocRecord r) {
    if (_dateRange != null) {
      final on = DateUtils.dateOnly(r.issuedOn);
      // Inclusive at both ends: a range picked as 1st–5th must include a
      // certificate issued on the 5th, which a plain isBefore would drop.
      if (on.isBefore(DateUtils.dateOnly(_dateRange!.start)) ||
          on.isAfter(DateUtils.dateOnly(_dateRange!.end))) {
        return false;
      }
    }

    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return r.member.toLowerCase().contains(q) ||
        r.flat.toLowerCase().contains(q) ||
        r.serial.toLowerCase().contains(q);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    // The app's own calendar, as the report filters use — not Flutter's
    // full-screen showDateRangePicker.
    final picked = await showDateRangeDialog(
      context: context,
      initial:
          _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateUtils.dateOnly(now),
          ),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() => _dateRange = picked);
  }

  @override
  void initState() {
    super.initState();
    // Awaited, not fired and forgotten: an unawaited failure here escapes the
    // view model's own catch and surfaces as an unhandled exception over the
    // page, instead of the "Could not load" the list is built to show.
    Future.microtask(() async {
      final vm = ref.read(communityViewModelProvider.notifier);
      await vm.loadNocCertificates();
      // The form picks a member and flat from the same lookup the booking
      // form uses, so it is fetched here and the form opens ready.
      await vm.loadBookingLookups();
    });
  }

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadNocCertificates();

  /// Opens the form, which saves and shows the certificate itself — see
  /// [_NocCertificateFormScreenState._submit] for why the save does not
  /// happen here.
  Future<void> _issueNew() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NocCertificateFormScreen()));
    // Whatever route the form ended on, the list behind it may now be stale.
    if (mounted) await _refresh();
  }

  void _view(NocRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NocCertificateViewScreen(record: record),
      ),
    );
  }

  /// Confirmed first: a certificate may already be in someone's hands, and
  /// the delete is a soft one the secretary cannot undo from this screen.
  Future<void> _delete(NocRecord record) async {
    final id = record.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this certificate?'),
        content: Text(
          '${record.serial} for ${record.member} will no longer be listed. '
          'Any copy already given out stays valid on paper.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref
        .read(communityViewModelProvider.notifier)
        .deleteNocCertificate(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.nocCertificates);

    final body = SafeArea(
      child: PageConstraints(
        padded: false,
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.verified_outlined,
          emptyTitle: 'No certificates issued',
          emptyMessage:
              'Issue a no-objection certificate for a member and it will '
              'be listed here.',
          emptyActionLabel: 'New NOC',
          emptyAction: _issueNew,
          builder: (items) {
            final all = items.map(NocRecord.fromRow).toList();
            final shown = all
                .where(_matches)
                .where((r) => _filter == null || r.kind == _filter)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space4,
                AppTheme.space4,
                AppTheme.space4,
                AppTheme.space8,
              ),
              children: [
                _buildSummary(all),
                const SizedBox(height: AppTheme.space3),
                _buildSearchAndFilter(all),
                const SizedBox(height: AppTheme.space3),

                // One column on a phone, more as the window allows — a full
                // width row of one card reads as a mistake on a desktop.
                // Wrap rather than a grid: the cards vary in height with the
                // length of a name, and a grid's fixed aspect ratio would
                // clip the taller ones.
                if (shown.isEmpty)
                  _buildNoMatches()
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = AppTheme.space3;
                      final columns = (constraints.maxWidth / 340)
                          .floor()
                          .clamp(1, 3);
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final record in shown)
                            SizedBox(
                              width: width,
                              child: _NocListCard(
                                record: record,
                                onTap: () => _view(record),
                                onDelete: () => _delete(record),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('NOC certificates')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _issueNew,
        icon: const Icon(Icons.add),
        label: const Text('New NOC'),
      ),
      body: body,
    );
  }

  /// Search with the type filter beside it — a menu rather than the chip row
  /// it replaces, which took a whole line to say what one button now does.
  Widget _buildSearchAndFilter(List<NocRecord> all) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search member, flat or no.',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space2),
        _buildFilterMenu(all),
      ],
    );
  }

  /// Type and date-range filters. Only the kinds actually issued are offered,
  /// so the menu never opens onto choices that would empty the list.
  ///
  /// Keyed by [NocKind]? with a sentinel for the date entry rather than by an
  /// enum of its own: the menu is a filter picker, and a second type would
  /// have to be mapped back at every use.
  Widget _buildFilterMenu(List<NocRecord> all) {
    final active = _filter != null || _dateRange != null;
    final kinds = NocKind.values
        .where((k) => all.any((r) => r.kind == k))
        .toList();

    return Material(
      color: active
          ? AppTheme.surfaceFor(AppTheme.primary)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: PopupMenuButton<Object?>(
        tooltip: 'Filter',
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == _dateFilterKey) {
            _pickDateRange();
          } else if (value == _clearDatesKey) {
            setState(() => _dateRange = null);
          } else {
            setState(() => _filter = value as NocKind?);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: null, child: Text('All types (${all.length})')),
          for (final kind in kinds)
            PopupMenuItem(
              value: kind,
              child: Text(
                '${kind.label} (${all.where((r) => r.kind == kind).length})',
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _dateFilterKey,
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 18),
                const SizedBox(width: AppTheme.space2),
                Text(
                  _dateRange == null
                      ? 'Issued between…'
                      : '${DateFormat('d MMM').format(_dateRange!.start)} – '
                            '${DateFormat('d MMM yy').format(_dateRange!.end)}',
                ),
              ],
            ),
          ),
          if (_dateRange != null)
            const PopupMenuItem(
              value: _clearDatesKey,
              child: Row(
                children: [
                  Icon(Icons.event_busy_outlined, size: 18),
                  SizedBox(width: AppTheme.space2),
                  Text('Any date'),
                ],
              ),
            ),
        ],
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Icon(
            active ? Icons.filter_alt : Icons.filter_alt_outlined,
            size: 20,
            color: active ? AppTheme.primary : AppTheme.lightText,
          ),
        ),
      ),
    );
  }

  /// The three figures a secretary opens this page to check: how many
  /// certificates exist, how many still stand, and how many have lapsed.
  Widget _buildSummary(List<NocRecord> all) {
    final expired = all.where((r) => r.isExpired).length;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          _SummaryFigure(
            label: 'Issued',
            value: '${all.length}',
            color: AppTheme.primary,
            icon: Icons.workspace_premium_outlined,
          ),
          _summaryDivider(),
          _SummaryFigure(
            label: 'Valid',
            value: '${all.length - expired}',
            color: AppTheme.success,
            icon: Icons.verified_outlined,
          ),
          _summaryDivider(),
          _SummaryFigure(
            label: 'Expired',
            value: '$expired',
            color: expired > 0 ? AppTheme.error : AppTheme.lightText,
            icon: Icons.event_busy_outlined,
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 34, color: AppTheme.border);

  /// Shown when a filter chip hides every row — distinct from the page-level
  /// empty state, which means the society has issued nothing at all.
  Widget _buildNoMatches() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: StateMessage(
        icon: Icons.search_off_rounded,
        title: 'Nothing matches',
        message: 'No certificate matches the search or filter you set.',
        actionLabel: 'Show all',
        onAction: () {
          _searchController.clear();
          setState(() {
            _filter = null;
            _search = '';
            _dateRange = null;
          });
        },
      ),
    );
  }
}

/// One issued certificate in the list.
class _NocListCard extends StatelessWidget {
  const _NocListCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final NocRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dates = DateFormat('d MMM yyyy');
    // Status colours the whole card, not just the chip: a lapsed certificate
    // is the one thing on this page a reader must not miss at a glance.
    final tone = record.isExpired ? AppTheme.error : AppTheme.success;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceFor(tone),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(record.kind.icon, size: 18, color: tone),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.member,
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.typeLabel} · Flat ${record.flat}',
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              StatusChip(
                label: record.isExpired ? 'Expired' : 'Valid',
                color: tone,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.space2),
          // The reference line, in the small print where a document's number
          // belongs — it is looked up, not scanned.
          Row(
            children: [
              Icon(
                Icons.tag_rounded,
                size: 13,
                color: AppTheme.deactivatedText,
              ),
              const SizedBox(width: 3),
              // Flexible, not Expanded: Expanded would swallow the slack the
              // Spacer below needs to push delete out to the card's edge.
              Flexible(
                child: Text(
                  record.serial,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.deactivatedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              Icon(
                Icons.event_outlined,
                size: 13,
                color: AppTheme.deactivatedText,
              ),
              const SizedBox(width: 3),
              // Flexible, so a narrow tile shortens the date rather than
              // pushing the row past the card's edge.
              Flexible(
                child: Text(
                  dates.format(record.issuedOn),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.deactivatedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Pushed to the card's edge, under the status chip it lines up
              // with. Deleting is the rarest thing done here, so it sits away
              // from the date rather than crowding it.
              const Spacer(),
              SizedBox(
                height: 22,
                width: 22,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  color: AppTheme.error,
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the certificate's document actions, as a tinted plate in the app
/// bar rather than a bare glyph.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: AppTheme.space2,
      ),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppTheme.surfaceFor(color),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 38,
              width: 38,
              child: Icon(icon, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// One figure in the summary bar above the list.
class _SummaryFigure extends StatelessWidget {
  const _SummaryFigure({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTheme.title.copyWith(fontSize: 16, color: color),
          ),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}

// ── Form ───────────────────────────────────────────────────────────────────

/// The form that issues a certificate. Returns the [NocRecord] it built.
class NocCertificateFormScreen extends ConsumerStatefulWidget {
  const NocCertificateFormScreen({super.key});

  @override
  ConsumerState<NocCertificateFormScreen> createState() =>
      _NocCertificateFormScreenState();
}

class _NocCertificateFormScreenState
    extends ConsumerState<NocCertificateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberController = TextEditingController();
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();
  final _customTitleController = TextEditingController();
  final _customClauseController = TextEditingController();

  NocKind _kind = NocKind.noDues;
  DateTime _issuedOn = DateTime.now();

  /// Left unset until a society picks one — a NOC without an end date does
  /// not lapse, which is a real and common choice, so this is not defaulted.
  DateTime? _validTill;

  /// True while the certificate is being saved, so the button says so and
  /// cannot be pressed twice into two certificates.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Start on the default kind's standard wording rather than an empty box,
    // so the common case is issue-as-is and editing is the exception.
    _customClauseController.text = _kind.clause;
  }

  /// Whether the clause on screen differs from the type's standard wording.
  /// Drives the reset button, which is pointless when nothing was changed.
  bool get _clauseEdited =>
      _customClauseController.text.trim() != _kind.clause.trim();

  /// Switch type and load that type's wording into the clause box.
  ///
  /// Overwrites whatever was typed: the box holds one type's sentence, and
  /// carrying a no-dues clause onto a sale NOC would certify the wrong thing.
  /// Re-selecting the current type is how the reset button restores it.
  void _selectKind(NocKind kind) {
    setState(() {
      _kind = kind;
      _customClauseController.text = kind.clause;
    });
  }

  @override
  void dispose() {
    _memberController.dispose();
    _flatController.dispose();
    _buildingController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    _customTitleController.dispose();
    _customClauseController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool issued}) async {
    // The app's own calendar, as every other date field opens — Flutter's
    // showDatePicker is a full-screen Material dialog that looks nothing like
    // the rest of the app's date fields.
    final picked = await showSingleDateDialog(
      context: context,
      initial: issued ? _issuedOn : _validTill,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      title: issued ? 'Issued on' : 'Valid till',
    );
    if (picked == null) return;
    setState(() {
      if (issued) {
        _issuedOn = picked;
      } else {
        _validTill = picked;
      }
    });
  }

  /// Hands the filled form back to the list, which saves it. Serial is not
  /// sent: the server allocates it, so two secretaries certifying at the same
  /// moment cannot land on one number.
  /// Saves, then replaces this route with the issued certificate.
  ///
  /// The save runs here rather than after popping: popping first would leave
  /// the list on screen for the whole round trip, so the secretary saw the
  /// list flash by on the way to the certificate. pushReplacement means the
  /// form is gone by the time the letter appears, and back from the letter
  /// reaches the list — never the form again.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? orNull(String s) => s.isEmpty ? null : s;
    final iso = DateFormat('yyyy-MM-dd');

    final request = NocRequest(
      nocType: _kind.code,
      clause: _customClauseController.text.trim(),
      memberName: _memberController.text.trim(),
      flatNo: _flatController.text.trim(),
      customTitle: orNull(_customTitleController.text.trim()),
      buildingName: orNull(_buildingController.text.trim()),
      purpose: orNull(_purposeController.text.trim()),
      remarks: orNull(_remarksController.text.trim()),
      issuedOn: iso.format(_issuedOn),
      validTill: _validTill == null ? null : iso.format(_validTill!),
    );

    setState(() => _saving = true);
    final vm = ref.read(communityViewModelProvider.notifier);
    final saved = await vm.createNocCertificate(request);
    if (!mounted) return;
    setState(() => _saving = false);

    // Stay on the form when the save failed: the snackbar says why, and the
    // secretary keeps everything they typed.
    if (!saved) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NocCertificateViewScreen(
          record: NocRecord(
            id: asInt(vm.issuedNoc?['noc_id']),
            serial: asString(vm.issuedNoc?['serial_no']) ?? '',
            kind: _kind,
            member: request.memberName,
            flat: request.flatNo,
            building: request.buildingName ?? '',
            purpose: request.purpose ?? '',
            issuedOn: _issuedOn,
            validTill: _validTill,
            remarks: request.remarks ?? '',
            customTitle: request.customTitle ?? '',
            customClause: request.clause,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _lookup(String key) {
    final raw = ref.read(communityViewModelProvider.notifier).bookingLookups;
    final list = raw?[key];
    if (list is! List) return const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    // The save happens on this page now, so a failure has to be reported
    // here — the list behind it may never come back into view.
    listenForFeedback(ref, context, communityViewModelProvider);

    // Watched so the pickers fill in as soon as the lookup lands.
    ref.watch(communityViewModelProvider);
    final flats = _lookup('flats');
    final residents = _lookup('residents');

    return Scaffold(
      appBar: AppBar(title: const Text('New NOC certificate')),
      body: SafeArea(
        child: PageConstraints(
          child: Form(
            key: _formKey,
            // Rebuild on every keystroke so the preview tracks the form
            // without a listener per controller.
            onChanged: () => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space5,
                AppTheme.space4,
                AppTheme.space5,
                AppTheme.space8,
              ),
              children: [
                _buildKindPicker(),
                const SizedBox(height: AppTheme.space4),
                _buildDetailsForm(residents, flats),
                const SizedBox(height: AppTheme.space4),
                NocCertificateDocument(record: _draft()),
                const SizedBox(height: AppTheme.space5),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Disabled while saving: a second tap would file a second
                    // certificate, each with its own number.
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined, size: 18),
                    label: Text(_saving ? 'Issuing…' : 'Issue certificate'),
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  'The certificate number is allocated when it is issued.',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What the preview renders as the form is filled in. The serial reads as
  /// pending because the server allocates it when the certificate is issued.
  NocRecord _draft() => NocRecord(
    serial: 'To be allocated',
    kind: _kind,
    member: _memberController.text.trim(),
    flat: _flatController.text.trim(),
    building: _buildingController.text.trim(),
    purpose: _purposeController.text.trim(),
    issuedOn: _issuedOn,
    validTill: _validTill,
    remarks: _remarksController.text.trim(),
    customTitle: _customTitleController.text.trim(),
    customClause: _customClauseController.text.trim(),
  );

  Widget _buildKindPicker() {
    return FormSection(
      title: 'Certificate type',
      icon: Icons.verified_outlined,
      children: [
        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            for (final kind in NocKind.values)
              ChoiceChip(
                selected: _kind == kind,
                avatar: Icon(
                  kind.icon,
                  size: 16,
                  color: _kind == kind ? AppTheme.primary : AppTheme.lightText,
                ),
                label: Text(kind.label),
                onSelected: (_) => _selectKind(kind),
              ),
          ],
        ),

        // Only a society-worded certificate names itself; the built-in kinds
        // are titled by their type.
        if (_kind.isCustom) ...[
          const SizedBox(height: AppTheme.space4),
          TextFormField(
            controller: _customTitleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Certificate title',
              hintText: 'Pet ownership NOC',
              helperText: 'What this certificate is called',
            ),
            validator: (v) => _kind.isCustom && (v == null || v.trim().isEmpty)
                ? 'Enter a title for the certificate'
                : null,
          ),
        ],

        // The operative sentence, for every type. Picking a kind fills in its
        // standard wording, which the secretary is then free to rewrite —
        // societies word the same NOC differently, and the alternative is
        // retyping the whole clause to change one condition.
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _customClauseController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'The society has no objection…',
            helperText: 'Completes the sentence printed on the certificate',
            alignLabelWithHint: true,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Enter what the society has no objection to'
              : null,
        ),
        if (!_kind.isCustom && _clauseEdited) ...[
          const SizedBox(height: AppTheme.space2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _selectKind(_kind),
              icon: const Icon(Icons.undo_rounded, size: 16),
              label: const Text('Reset to standard wording'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsForm(
    List<Map<String, dynamic>> residents,
    List<Map<String, dynamic>> flats,
  ) {
    final dates = DateFormat('d MMM yyyy');

    return FormSection(
      title: 'Certificate details',
      icon: Icons.edit_note_outlined,
      children: [
        if (residents.isNotEmpty) ...[
          AppDropdown<int>(
            value: null,
            label: 'Pick a member',
            helperText: 'Fills in the name and flat below',
            icon: Icons.person_outline,
            isDense: false,
            options: [
              for (final r in residents)
                if (pickInt(r, ['owner_id', 'id']) != null)
                  AppOption(
                    pickInt(r, ['owner_id', 'id'])!,
                    pick(r, ['name', 'owner_name']) ?? 'Member',
                  ),
            ],
            onChanged: (v) {
              final r = residents
                  .where((x) => pickInt(x, ['owner_id', 'id']) == v)
                  .firstOrNull;
              if (r == null) return;
              setState(() {
                _memberController.text = pick(r, ['name', 'owner_name']) ?? '';
                final flat = pick(r, ['flat_no', 'unit_no']);
                if (flat != null) _flatController.text = flat;
                final building = pick(r, ['building_name', 'build_name']);
                if (building != null) _buildingController.text = building;
              });
            },
          ),
          const SizedBox(height: AppTheme.space4),
        ],
        TextFormField(
          controller: _memberController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Member name',
            hintText: 'Who the certificate is issued to',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter the member name' : null,
        ),
        const SizedBox(height: AppTheme.space4),
        if (flats.isNotEmpty) ...[
          // Keyed by position, not by flat number: the option has to carry the
          // building back too, and two wings can repeat a flat number.
          AppDropdown<int>(
            value: null,
            label: 'Pick a flat',
            icon: Icons.home_outlined,
            isDense: false,
            options: [
              for (var i = 0; i < flats.length; i++)
                if (pick(flats[i], ['flat_no', 'unit_no']) != null)
                  AppOption(
                    i,
                    [
                      pick(flats[i], ['building_name', 'build_name']),
                      pick(flats[i], ['flat_no', 'unit_no']),
                    ].where((e) => e != null).join(' · '),
                  ),
            ],
            onChanged: (v) {
              if (v == null) return;
              final f = flats[v];
              setState(() {
                _flatController.text = pick(f, ['flat_no', 'unit_no']) ?? '';
                final building = pick(f, ['building_name', 'build_name']);
                if (building != null) _buildingController.text = building;
              });
            },
          ),
          const SizedBox(height: AppTheme.space4),
        ],
        TextFormField(
          controller: _flatController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Flat number',
            hintText: 'A-101',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter the flat number' : null,
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _buildingController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Building / wing',
            hintText: 'Building A',
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _purposeController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Purpose',
            hintText: 'What the member needs the NOC for',
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Row(
          children: [
            Expanded(
              child: PickerField(
                label: 'Issued on',
                icon: Icons.event_outlined,
                value: dates.format(_issuedOn),
                onTap: () => _pickDate(issued: true),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: PickerField(
                label: 'Valid till',
                icon: Icons.event_available_outlined,
                value: _validTill == null
                    ? 'No expiry'
                    : dates.format(_validTill!),
                onTap: () => _pickDate(issued: false),
                onClear: _validTill == null
                    ? null
                    : () => setState(() => _validTill = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _remarksController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Additional content',
            hintText: 'Anything else the society wants printed on the letter',
            helperText: 'Added as a further paragraph on the certificate',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

// ── The certificate itself ─────────────────────────────────────────────────

/// An issued certificate, on its own page.
class NocCertificateViewScreen extends ConsumerWidget {
  const NocCertificateViewScreen({super.key, required this.record});

  final NocRecord record;

  /// What the exported sheet prints — the record, plus the two things it does
  /// not carry itself: the society the secretary is signed in to, and who that
  /// society has its certificates signed by.
  NocSheetData _sheet(String society, NocSignatories signatories) => NocSheetData(
    serial: record.serial,
    typeLabel: record.typeLabel,
    clause: record.clause,
    member: record.member,
    flat: record.flat,
    building: record.building,
    purpose: record.purpose,
    issuedOn: record.issuedOn,
    validTill: record.validTill,
    remarks: record.remarks,
    societyName: society,
    isCustomType: record.kind.isCustom,
    signatories: signatories,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = DateFormat('dd MMM yyyy');
    final society =
        ref.watch(authViewModelProvider).user?.societyName ?? 'The society';
    final sheet = _sheet(society, nocSignatoriesOf(ref));

    return Scaffold(
      // The three actions sit in the title bar, to the right — icons rather
      // than labelled buttons, which wrapped mid-word on a narrow phone. Each
      // on its own tinted plate, so they read as actions rather than as the
      // grey furniture an app bar usually carries.
      appBar: AppBar(
        title: const Text('NOC Certificate'),
        actions: [
          _BarAction(
            icon: Icons.print_outlined,
            tooltip: 'Print',
            color: AppTheme.info,
            onTap: () => NocExport.print(context, sheet),
          ),
          _BarAction(
            icon: Icons.file_download_outlined,
            tooltip: 'Download PDF',
            color: AppTheme.violet,
            onTap: () => NocExport.download(context, sheet),
          ),
          _BarAction(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            color: AppTheme.success,
            onTap: () => NocExport.share(context, sheet),
          ),
          const SizedBox(width: AppTheme.space2),
        ],
      ),
      body: SafeArea(
        child: PageConstraints(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space4,
              AppTheme.space4,
              AppTheme.space4,
              AppTheme.space5,
            ),
            children: [
              _buildStatusBanner(dates),
              const SizedBox(height: AppTheme.space4),
              NocCertificateDocument(record: record),
              const SizedBox(height: AppTheme.space4),
              _buildAboutNote(),
            ],
          ),
        ),
      ),
    );
  }

  /// The approval strip above the document — the first thing a reader checks.
  Widget _buildStatusBanner(DateFormat dates) {
    final expired = record.isExpired;
    final color = expired ? AppTheme.error : AppTheme.success;

    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(
            expired ? Icons.error_outline : Icons.check_circle,
            color: color,
            size: 22,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired ? 'NOC Expired' : 'NOC Approved',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.validTill == null
                      ? 'This NOC does not expire'
                      : '${expired ? 'This NOC expired on' : 'This NOC is valid till'} '
                            '${dates.format(record.validTill!)}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          StatusChip(label: expired ? 'Expired' : 'Approved', color: color),
        ],
      ),
    );
  }

  Widget _buildAboutNote() {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppTheme.success),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Certificate',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This digitally generated certificate is valid and does '
                  'not require any physical signature.',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The certificate as it reads on paper.
///
/// Laid out as a society letter rather than a form dump: a crested letterhead
/// carrying the society's own name, the title, the reference number and date
/// on one line, the recital naming the member and flat, the operative "no
/// objection" sentence, and then the particulars as a labelled table — which
/// is where a reader looks to check a detail, so they are listed rather than
/// buried in the prose. A seal and signature block close it.
class NocCertificateDocument extends ConsumerWidget {
  const NocCertificateDocument({super.key, required this.record});

  final NocRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The letterhead names the society the secretary is signed in to; there
    // is no per-certificate society to choose.
    final society =
        ref.watch(authViewModelProvider).user?.societyName ?? 'The society';
    final signatories = nocSignatoriesOf(ref);

    final dates = DateFormat('dd MMM yyyy');
    final member = record.member.isEmpty ? '____________' : record.member;
    final flat = record.flat.isEmpty ? '______' : record.flat;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppTheme.space2),
      // A double rule inside the card, matching the printed sheet — it is
      // what makes the block read as a certificate rather than a panel.
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.warning, width: 1.2),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLetterhead(society),
              const SizedBox(height: AppTheme.space5),

              // Reference and date, as typed at the head of the letter.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Stacked(
                      label: 'Certificate No.',
                      value: record.serial,
                    ),
                  ),
                  _Stacked(
                    label: 'Date of Issue',
                    value: dates.format(record.issuedOn),
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space5),

              Text(
                'This is to certify that $member, residing in Flat No. $flat'
                '${record.building.isEmpty ? '' : ', ${record.building}'}, '
                '$society, is a registered member/resident of our society.',
                style: AppTheme.body2.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppTheme.space3),
              Text.rich(
                TextSpan(
                  style: AppTheme.body2.copyWith(height: 1.6),
                  children: [
                    const TextSpan(text: 'The society has '),
                    TextSpan(
                      text: 'no objection',
                      style: AppTheme.body2.copyWith(
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    TextSpan(text: ' ${record.clause}'),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space5),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space4),

              // The particulars, as a labelled table.
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Member Name',
                value: member,
              ),
              _DetailRow(
                icon: Icons.home_outlined,
                label: 'Flat No.',
                value: flat,
              ),
              if (record.building.isNotEmpty)
                _DetailRow(
                  icon: Icons.apartment_outlined,
                  label: 'Building / Wing',
                  value: record.building,
                ),
              if (record.purpose.isNotEmpty)
                _DetailRow(
                  icon: Icons.assignment_outlined,
                  label: 'Purpose',
                  value: record.purpose,
                ),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Valid Until',
                value: record.validTill == null
                    ? 'No expiry'
                    : dates.format(record.validTill!),
              ),
              _DetailRow(
                icon: Icons.verified_user_outlined,
                label: 'Issued By',
                value: society,
              ),

              // Anything the society added itself, as a further paragraph of the
              // letter — same weight as the rest, not a footnote.
              if (record.remarks.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space3),
                Text(
                  record.remarks,
                  style: AppTheme.body2.copyWith(height: 1.6),
                ),
              ],

              const SizedBox(height: AppTheme.space6),
              _buildSealAndSignature(society, signatories),
              const SizedBox(height: AppTheme.space5),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space3),
              // Says what this sheet is, not what makes it valid — and no
              // longer "does not require a manual signature", which is the
              // opposite of true for a certificate the society stands behind.
              // How many signatures it needs is the society's own rule, so
              // nothing here asserts one.
              Text(
                'Issued by the society. Please sign and affix the society seal '
                'before handing this certificate over.',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.deactivatedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterhead(String society) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppTheme.warningSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 24,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            society,
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(
              fontSize: 17,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'NO OBJECTION CERTIFICATE',
            textAlign: TextAlign.center,
            style: AppTheme.title.copyWith(
              fontSize: 16,
              color: AppTheme.darkerText,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          // A rule broken by a diamond, the ornament the printed sheet
          // carries under its title.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 46, height: 1, color: AppTheme.warning),
              const SizedBox(width: 5),
              Transform.rotate(
                angle: 0.785398, // 45°, so the square reads as a diamond.
                child: Container(width: 5, height: 5, color: AppTheme.warning),
              ),
              const SizedBox(width: 5),
              Container(width: 46, height: 1, color: AppTheme.warning),
            ],
          ),
          // A society-worded certificate names itself under the title; the
          // built-in kinds are already evident from the clause below.
          if (record.kind.isCustom && record.customTitle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space2),
            Text(
              record.customTitle,
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seal on the left, the signature lines on the right — where they sit on
  /// the letter, and matching what the printed sheet leaves blank for ink.
  ///
  /// One line per signing officer, from the society's own setting. This read
  /// "Authorised Signatory" on a single line while the PDF printed two named
  /// ones, so the screen and the paper disagreed about the document they were
  /// showing.
  Widget _buildSealAndSignature(String society, NocSignatories signatories) {
    Widget block(String role) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(width: 110, height: 1, color: AppTheme.border),
        const SizedBox(height: AppTheme.space2),
        Text(
          role,
          textAlign: TextAlign.right,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        Text(
          society,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.caption.copyWith(color: AppTheme.deactivatedText),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // A double ring, as a rubber stamp carries — a single outline reads
        // as a drawn circle rather than a seal.
        Container(
          height: 74,
          width: 74,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.success, width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                'SOCIETY\nSEAL',
                textAlign: TextAlign.center,
                style: AppTheme.overline.copyWith(
                  color: AppTheme.success,
                  fontSize: 8,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space3),
        // Expanded, not a Spacer: the blocks have to share what is left of the
        // row rather than push it past the card's edge, and a long society
        // name under two of them is what would do it.
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final role in signatories.roles) ...[
                Flexible(child: block(role)),
                if (role != signatories.roles.last)
                  const SizedBox(width: AppTheme.space3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A label over its value — the certificate's reference and date pair.
class _Stacked extends StatelessWidget {
  const _Stacked({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.body2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
      ],
    );
  }
}

/// One particular in the certificate's table: icon, label, value.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.lightText),
          const SizedBox(width: AppTheme.space2),
          Expanded(child: Text(label, style: AppTheme.caption)),
          const SizedBox(width: AppTheme.space3),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
