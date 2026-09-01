import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/community_requests.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../presentation/viewModels/list_state.dart';
import '../../widgets/app_widgets.dart';
import 'form_fields.dart';
import 'noc_certificate_screen.dart' show NocKind;

/// Where a request has got to.
///
/// The codes are vendor_bills': 1 Pending, 2 Approved, 4 Rejected, with 5
/// Ready and 6 Collected for the two steps that happen on paper. 3 is skipped
/// — it means Paid there and nothing here.
///
/// Approved deliberately does not read "ready to collect". The letter still
/// has to be printed and signed, and the member is given a day separately;
/// telling them to come before that is what fills the office with people
/// collecting certificates nobody has signed yet.
enum NocStage {
  pending(1, 'Pending', 'Awaiting a decision', Icons.hourglass_top_rounded),
  approved(2, 'Approved', 'To be printed and signed', Icons.task_alt_rounded),
  rejected(4, 'Rejected', 'Not approved', Icons.cancel_outlined),
  ready(
    5,
    'Ready',
    'Waiting to be collected',
    Icons.local_post_office_outlined,
  ),
  collected(6, 'Collected', 'Handed over', Icons.done_all_rounded);

  const NocStage(this.code, this.label, this.description, this.icon);

  final int code;
  final String label;

  /// The fuller line shown on the card, saying what happens next.
  final String description;
  final IconData icon;

  Color get color => switch (this) {
    NocStage.pending => AppTheme.warning,
    NocStage.approved => AppTheme.info,
    NocStage.rejected => AppTheme.error,
    NocStage.ready => AppTheme.success,
    NocStage.collected => AppTheme.grey,
  };

  static NocStage fromCode(dynamic code) {
    final n = asIntOr(code, 1);
    return NocStage.values.firstWhere(
      (s) => s.code == n,
      orElse: () => NocStage.pending,
    );
  }
}

/// One row of sp_noc_request 'Grid_Show'.
class NocRequestRecord {
  NocRequestRecord({
    required this.id,
    required this.stage,
    required this.kind,
    required this.member,
    required this.flat,
    required this.building,
    required this.purpose,
    required this.requestedOn,
    required this.serial,
    required this.customTitle,
    required this.clause,
    required this.remarks,
    required this.validTill,
    required this.rejectReason,
    required this.approverCount,
    required this.approvedCount,
    required this.collectionDate,
    required this.collectionTime,
    required this.collectionNote,
    required this.collectedOn,
    required this.collectedBy,
  });

  factory NocRequestRecord.fromRow(Map<String, dynamic> row) {
    String text(String key) => asString(row[key]) ?? '';

    return NocRequestRecord(
      id: asIntOr(row['request_id']),
      stage: NocStage.fromCode(row['status']),
      kind: NocKind.fromCode(asString(row['noc_type'])),
      member: text('member_name'),
      flat: text('flat_no'),
      building: text('building_name'),
      purpose: text('purpose'),
      requestedOn: asDate(row['requested_on']),
      serial: text('serial_no'),
      customTitle: text('custom_title'),
      clause: text('clause'),
      remarks: text('remarks'),
      validTill: asDate(row['valid_till']),
      rejectReason: text('reject_reason'),
      approverCount: asIntOr(row['approver_count']),
      approvedCount: asIntOr(row['approved_count']),
      collectionDate: asDate(row['collection_date']),
      collectionTime: text('collection_time'),
      collectionNote: text('collection_note'),
      collectedOn: asDate(row['collected_on']),
      collectedBy: text('collected_by'),
    );
  }

  final int id;
  final NocStage stage;
  final NocKind kind;
  final String member;
  final String flat;
  final String building;
  final String purpose;
  final DateTime? requestedOn;

  /// The certificate's number, once the request has produced one.
  final String serial;

  final String customTitle;
  final String clause;
  final String remarks;
  final DateTime? validTill;

  /// Why it was refused. Empty unless [stage] is rejected.
  final String rejectReason;

  final int approverCount;
  final int approvedCount;

  final DateTime? collectionDate;
  final String collectionTime;
  final String collectionNote;
  final DateTime? collectedOn;
  final String collectedBy;

  /// What the request calls itself in a list.
  String get typeLabel =>
      kind.isCustom && customTitle.isNotEmpty ? customTitle : kind.label;

  String get flatLabel =>
      [building, flat].where((s) => s.isNotEmpty).join(' · ');
}

/// NOC requests — what members have asked for, and what each one needs next.
class NocRequestScreen extends ConsumerStatefulWidget {
  const NocRequestScreen({super.key, this.embedded = false});

  /// Set when this sits inside [NocScreen]'s tabs, which carry the app bar for
  /// both halves. Left false, the screen stands on its own.
  final bool embedded;

  @override
  ConsumerState<NocRequestScreen> createState() => _NocRequestScreenState();
}

class _NocRequestScreenState extends ConsumerState<NocRequestScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  NocStage? _filter;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadNocRequests();

  bool _matches(NocRequestRecord r) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return r.member.toLowerCase().contains(q) ||
        r.flat.toLowerCase().contains(q) ||
        r.serial.toLowerCase().contains(q) ||
        r.typeLabel.toLowerCase().contains(q);
  }

  Future<void> _open(NocRequestRecord record) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _RequestPage(record: record)));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.nocRequests);

    final body = SafeArea(
      child: PageConstraints(
        padded: false,
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.mark_email_unread_outlined,
          emptyTitle: 'No NOC requests',
          emptyMessage:
              'Requests members raise from their app are listed here, with '
              'whatever each one needs next.',
          builder: (items) {
            // A collected request is finished — the letter is signed and in
            // the member's hands, and the record of it is the certificate on
            // the next tab. Leaving it here would grow this list forever with
            // rows nobody has to act on, and the two requests waiting for an
            // answer would sit below every NOC the society has ever issued.
            final all = items
                .map(NocRequestRecord.fromRow)
                .where((r) => r.stage != NocStage.collected)
                .toList();

            final shown = all
                .where(_matches)
                .where((r) => _filter == null || r.stage == _filter)
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
                _buildSearch(),
                const SizedBox(height: AppTheme.space3),
                if (shown.isEmpty)
                  const StateMessage(
                    icon: Icons.search_off_rounded,
                    title: 'Nothing matches',
                    message: 'Try a different name, flat or status.',
                  )
                else
                  // One column on a phone, more as the window allows. Wrap
                  // rather than a grid: the cards vary in height with what
                  // each request needs, and a grid's fixed ratio would clip
                  // the taller ones.
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
                              child: _RequestCard(
                                record: record,
                                onTap: () => _open(record),
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
      appBar: AppBar(title: const Text('NOC requests')),
      body: body,
    );
  }

  /// The counts that say what the secretary has to do today, each one a filter.
  Widget _buildSummary(List<NocRequestRecord> all) {
    int count(NocStage s) => all.where((r) => r.stage == s).length;

    Widget tile(NocStage stage, String label) {
      final selected = _filter == stage;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _filter = selected ? null : stage),
          child: AppCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space3,
              horizontal: AppTheme.space2,
            ),
            accent: selected ? stage.color : null,
            child: Column(
              children: [
                Icon(stage.icon, size: 18, color: stage.color),
                const SizedBox(height: 6),
                Text(
                  '${count(stage)}',
                  style: AppTheme.title.copyWith(color: stage.color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(NocStage.pending, 'To decide'),
        const SizedBox(width: AppTheme.space2),
        tile(NocStage.approved, 'To sign'),
        const SizedBox(width: AppTheme.space2),
        tile(NocStage.ready, 'To collect'),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _search = v.trim()),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search member, flat or serial',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.record, required this.onTap});

  final NocRequestRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      accent: record.stage.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: record.member, size: 36),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.member.isEmpty ? 'Member' : record.member,
                      style: AppTheme.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.flatLabel.isNotEmpty)
                      Text(
                        record.flatLabel,
                        style: AppTheme.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              StatusChip(
                label: record.stage.label,
                color: record.stage.color,
                icon: record.stage.icon,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Icon(record.kind.icon, size: 14, color: AppTheme.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  record.typeLabel,
                  style: AppTheme.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (record.serial.isNotEmpty)
                Text(record.serial, style: AppTheme.caption),
            ],
          ),
          if (record.purpose.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              record.purpose,
              style: AppTheme.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: Text(
                  _cardFooter(record),
                  style: AppTheme.caption.copyWith(color: record.stage.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(prettyDate(record.requestedOn), style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// The one line on the card that says where the request stands.
String _cardFooter(NocRequestRecord r) => switch (r.stage) {
  NocStage.pending when r.approverCount > 0 =>
    '${r.approvedCount} of ${r.approverCount} approved',
  NocStage.pending => 'Needs approvers',
  NocStage.ready when r.collectionDate != null =>
    'Collect on ${prettyDate(r.collectionDate)}',
  NocStage.collected when r.collectedOn != null =>
    'Collected ${prettyDate(r.collectedOn)}',
  _ => r.stage.description,
};

/// One request, and whatever it needs next.
///
/// What is on offer follows the stage rather than being shown all at once: a
/// pending request needs a decision, an approved one a certificate, a ready
/// one marking as handed over. Showing every control at every stage would
/// leave most of them disabled most of the time.
///
/// A page rather than the bottom sheet this used to be. The sheet capped
/// itself at 95% of the screen and scrolled inside that, so a request with a
/// certificate on it — the summary, the sheet, the approvals — read through a
/// window with its own scrollbar inside the page's. The website opens the same
/// thing full width; this now matches it.
class _RequestPage extends ConsumerStatefulWidget {
  const _RequestPage({required this.record});

  final NocRequestRecord record;

  @override
  ConsumerState<_RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<_RequestPage> {
  Map<String, dynamic>? _detail;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final detail = await ref
          .read(communityViewModelProvider.notifier)
          .getNocRequest(widget.record.id);
      if (mounted) setState(() => _detail = detail);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Run one action, then close on success — the list behind reloads.
  Future<void> _act(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> get _approvals =>
      asRows(_detail?['approvals'] ?? const <dynamic>[]);

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.member.isEmpty ? 'NOC request' : record.member),
        actions: [
          // The stage, in the bar rather than repeated over the summary card
          // below it — it is the one thing true of the whole page.
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space4),
            child: Center(
              child: StatusChip(
                label: record.stage.label,
                color: record.stage.color,
                icon: record.stage.icon,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PageConstraints(
          padded: false,
          child: _error != null
              ? StateMessage(
                  icon: Icons.cloud_off_rounded,
                  iconColor: AppTheme.error,
                  title: 'Could not load',
                  message: errorText(_error!),
                  actionLabel: 'Try again',
                  onAction: _load,
                )
              : _detail == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space4,
                    AppTheme.space4,
                    AppTheme.space4,
                    AppTheme.space8,
                  ),
                  children: [
                    _Summary(record: record),
                    const SizedBox(height: AppTheme.space3),

                    if (record.stage == NocStage.pending)
                      _PendingSection(
                        record: record,
                        approvals: _approvals,
                        busy: _busy,
                        act: _act,
                      ),

                    // Approved, in two steps: write the certificate, then give
                    // the member a day to collect the signed copy. The
                    // collection date is no use before the letter exists —
                    // there is nothing to print.
                    if (record.stage == NocStage.approved)
                      record.serial.isEmpty
                          ? _IssueSection(record: record, onIssued: _load)
                          : _ReadySection(
                              record: record,
                              busy: _busy,
                              act: _act,
                            ),

                    if (record.stage == NocStage.ready)
                      _CollectSection(record: record, busy: _busy, act: _act),

                    if (record.stage == NocStage.rejected &&
                        record.rejectReason.isNotEmpty)
                      _NoticePanel(
                        color: AppTheme.error,
                        icon: Icons.cancel_outlined,
                        title: 'Rejected',
                        body: record.rejectReason,
                      ),

                    if (record.stage == NocStage.collected)
                      _NoticePanel(
                        color: AppTheme.grey,
                        icon: Icons.done_all_rounded,
                        title: 'Collected',
                        body:
                            'Handed over on '
                            '${prettyDate(record.collectedOn)}'
                            '${record.collectedBy.isEmpty ? '' : ' to ${record.collectedBy}'}.',
                      ),

                    if (_approvals.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space3),
                      _ApprovalList(approvals: _approvals),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.record});

  final NocRequestRecord record;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Request',
      icon: Icons.assignment_outlined,
      children: [
        _Detail('Type', record.typeLabel),
        if (record.flatLabel.isNotEmpty) _Detail('Flat', record.flatLabel),
        if (record.purpose.isNotEmpty) _Detail('Purpose', record.purpose),
        _Detail('Requested', prettyDate(record.requestedOn)),
        if (record.serial.isNotEmpty) _Detail('Certificate', record.serial),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: AppTheme.caption)),
          Expanded(child: Text(value, style: AppTheme.body2)),
        ],
      ),
    );
  }
}

/// A pending request: approve it or refuse it.
///
/// Nothing is chosen here first. The request went to every office the society
/// has — admin, secretary, chairman — the moment the member raised it, because
/// it goes to the same offices every time and asking the committee to "send"
/// it to themselves settled nothing.
///
/// The wording is not settled here either. It belongs on the certificate,
/// which is written from the issue form once the request is approved — that is
/// also where the issue date, the wing and whether it lapses are set, none of
/// which the request carries.
class _PendingSection extends ConsumerStatefulWidget {
  const _PendingSection({
    required this.record,
    required this.approvals,
    required this.busy,
    required this.act,
  });

  final NocRequestRecord record;
  final List<Map<String, dynamic>> approvals;
  final bool busy;
  final Future<void> Function(Future<bool> Function()) act;

  @override
  ConsumerState<_PendingSection> createState() => _PendingSectionState();
}

class _PendingSectionState extends ConsumerState<_PendingSection> {
  final _rejectReason = TextEditingController();
  bool _rejecting = false;

  @override
  void dispose() {
    _rejectReason.dispose();
    super.dispose();
  }

  /// The approval this signed-in officer was asked for, if it is unanswered.
  ///
  /// The server only accepts a decision from the officer it was asked of, so
  /// there is nothing to gain by showing anyone else's as actionable.
  Map<String, dynamic>? get _mine {
    final me = ref.read(authViewModelProvider).user?.userId;
    if (me == null) return null;
    for (final a in widget.approvals) {
      if (asIntOr(a['user_id']) == me && asIntOr(a['approval_status']) == 1) {
        return a;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(communityViewModelProvider.notifier);
    final mine = _mine;

    // Signed in as somebody the request did not go to — a treasurer or an
    // ordinary committee member — or as an officer who has already answered.
    if (mine == null) {
      return AppCard(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: AppTheme.warning,
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Text(
                widget.approvals.isEmpty
                    ? 'This request has not reached any officer yet. Reopen '
                          'it in a moment.'
                    : 'Waiting on the officers listed below.',
                style: AppTheme.body2,
              ),
            ),
          ],
        ),
      );
    }

    return FormSection(
      title: 'Your decision',
      icon: Icons.gavel_rounded,
      children: [
        if (_rejecting) ...[
          TextField(
            controller: _rejectReason,
            enabled: !widget.busy,
            maxLines: 2,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Reason',
              helperText: 'The member is shown this.',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                  onPressed: widget.busy || _rejectReason.text.trim().isEmpty
                      ? null
                      : () => widget.act(
                          () => vm.decideNocRequest(
                            widget.record.id,
                            asIntOr(mine['approval_id']),
                            NocDecisionRequest(
                              decision: 'reject',
                              remarks: _rejectReason.text.trim(),
                            ),
                          ),
                        ),
                  child: const Text('Confirm rejection'),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              TextButton(
                onPressed: widget.busy
                    ? null
                    : () => setState(() => _rejecting = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  onPressed: widget.busy
                      ? null
                      : () => widget.act(
                          () => vm.decideNocRequest(
                            widget.record.id,
                            asIntOr(mine['approval_id']),
                            const NocDecisionRequest(decision: 'approve'),
                          ),
                        ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                  onPressed: widget.busy
                      ? null
                      : () => setState(() => _rejecting = true),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Approved: print it, get it signed, then tell the member when to come.
class _ReadySection extends ConsumerStatefulWidget {
  const _ReadySection({
    required this.record,
    required this.busy,
    required this.act,
  });

  final NocRequestRecord record;
  final bool busy;
  final Future<void> Function(Future<bool> Function()) act;

  @override
  ConsumerState<_ReadySection> createState() => _ReadySectionState();
}

class _ReadySectionState extends ConsumerState<_ReadySection> {
  DateTime _date = DateTime.now();
  final _time = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(communityViewModelProvider.notifier);

    return FormSection(
      title: 'Ready for collection',
      icon: Icons.local_post_office_outlined,
      children: [
        Text(
          // "Get it signed", not "have the chairman and secretary sign it":
          // which officers sign is the society's own rule, and the sheet
          // leaves a line for each rather than requiring both.
          'Print the certificate'
          '${widget.record.serial.isEmpty ? '' : ' (${widget.record.serial})'}, '
          'get it signed and sealed, then give the member a day to collect '
          'it. They are told as soon as you save this.',
          style: AppTheme.caption,
        ),
        const SizedBox(height: AppTheme.space3),
        PickerField(
          label: 'Collection date',
          icon: Icons.event_outlined,
          value: prettyDate(_date),
          onTap: widget.busy ? () {} : _pickDate,
        ),
        const SizedBox(height: AppTheme.space3),
        TextField(
          controller: _time,
          enabled: !widget.busy,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Office hours',
            hintText: '10 AM – 1 PM',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        TextField(
          controller: _note,
          enabled: !widget.busy,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Anything to bring',
            hintText: 'Carry your Aadhaar card',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        FilledButton.icon(
          onPressed: widget.busy
              ? null
              : () => widget.act(
                  () => vm.setNocRequestReady(
                    widget.record.id,
                    NocReadyRequest(
                      collectionDate: DateFormat('yyyy-MM-dd').format(_date),
                      collectionTime: _time.text.trim().isEmpty
                          ? null
                          : _time.text.trim(),
                      collectionNote: _note.text.trim().isEmpty
                          ? null
                          : _note.text.trim(),
                    ),
                  ),
                ),
          icon: const Icon(Icons.notifications_active_outlined, size: 18),
          label: const Text('Notify the member'),
        ),
      ],
    );
  }
}

/// Ready: record who took it away, or move the appointment.
class _CollectSection extends ConsumerStatefulWidget {
  const _CollectSection({
    required this.record,
    required this.busy,
    required this.act,
  });

  final NocRequestRecord record;
  final bool busy;
  final Future<void> Function(Future<bool> Function()) act;

  @override
  ConsumerState<_CollectSection> createState() => _CollectSectionState();
}

class _CollectSectionState extends ConsumerState<_CollectSection> {
  final _collectedBy = TextEditingController();
  late DateTime _date;
  late final TextEditingController _time;
  late final TextEditingController _note;
  bool _rescheduling = false;

  @override
  void initState() {
    super.initState();
    _date = widget.record.collectionDate ?? DateTime.now();
    _time = TextEditingController(text: widget.record.collectionTime);
    _note = TextEditingController(text: widget.record.collectionNote);
  }

  @override
  void dispose() {
    _collectedBy.dispose();
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(communityViewModelProvider.notifier);
    final r = widget.record;

    return FormSection(
      title: 'Waiting to be collected',
      icon: Icons.local_post_office_outlined,
      children: [
        Text(
          [
            prettyDate(r.collectionDate),
            if (r.collectionTime.isNotEmpty) r.collectionTime,
            if (r.collectionNote.isNotEmpty) r.collectionNote,
          ].join(' · '),
          style: AppTheme.caption.copyWith(color: AppTheme.success),
        ),
        const SizedBox(height: AppTheme.space3),

        if (_rescheduling) ...[
          PickerField(
            label: 'Collection date',
            icon: Icons.event_outlined,
            value: prettyDate(_date),
            onTap: widget.busy ? () {} : _pickDate,
          ),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: _time,
            enabled: !widget.busy,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Office hours',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: _note,
            enabled: !widget.busy,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Anything to bring',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: widget.busy
                      ? null
                      : () => widget.act(
                          () => vm.setNocRequestReady(
                            r.id,
                            NocReadyRequest(
                              collectionDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(_date),
                              collectionTime: _time.text.trim().isEmpty
                                  ? null
                                  : _time.text.trim(),
                              collectionNote: _note.text.trim().isEmpty
                                  ? null
                                  : _note.text.trim(),
                            ),
                          ),
                        ),
                  child: const Text('Save new date'),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              TextButton(
                onPressed: widget.busy
                    ? null
                    : () => setState(() => _rescheduling = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ] else ...[
          TextField(
            controller: _collectedBy,
            enabled: !widget.busy,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Collected by',
              hintText: r.member.isEmpty ? 'The member' : r.member,
              helperText: 'Leave blank if the member collected it themselves.',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  onPressed: widget.busy
                      ? null
                      : () => widget.act(
                          () => vm.setNocRequestCollected(
                            r.id,
                            NocCollectedRequest(
                              collectedBy: _collectedBy.text.trim().isEmpty
                                  ? null
                                  : _collectedBy.text.trim(),
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark collected'),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              TextButton(
                onPressed: widget.busy
                    ? null
                    : () => setState(() => _rescheduling = true),
                child: const Text('Change date'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Who was asked to decide, and what they said.
class _ApprovalList extends StatelessWidget {
  const _ApprovalList({required this.approvals});

  final List<Map<String, dynamic>> approvals;

  @override
  Widget build(BuildContext context) {
    (String, Color) verdict(int code) => switch (code) {
      2 => ('Approved', AppTheme.success),
      4 => ('Rejected', AppTheme.error),
      _ => ('Waiting', AppTheme.grey),
    };

    return FormSection(
      title: 'Approvals',
      icon: Icons.groups_outlined,
      children: [
        for (final a in approvals)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asString(a['name']) ?? 'Member',
                        style: AppTheme.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final (label, color) = verdict(
                          asIntOr(a['approval_status'], 1),
                        );
                        return Text(
                          a['approval_date'] == null
                              ? label
                              : '$label · ${prettyDate(a['approval_date'])}',
                          style: AppTheme.caption.copyWith(color: color),
                        );
                      },
                    ),
                  ],
                ),
                if ((asString(a['remarks']) ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      asString(a['remarks'])!,
                      style: AppTheme.caption,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A settled request's outcome, with nothing left to do about it.
class _NoticePanel extends StatelessWidget {
  const _NoticePanel({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      accent: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.subtitle.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(body, style: AppTheme.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
