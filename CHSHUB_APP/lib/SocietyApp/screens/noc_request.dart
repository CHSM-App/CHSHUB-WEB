import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/noc_request.dart';

import '../../presentation/providers/viewModel_provider.dart';

/// The palette the rest of the resident app draws from — the amenities, polls
/// and document screens all use these.
const _canvas = Color(0xFFF8FAFC);
const _heading = Color(0xFF1E293B);
const _muted = Color(0xFF64748B);

/// The kinds of NOC a member can ask for.
///
/// The codes are the society's — `sp_noc_request` and the committee's apps use
/// the same six — so the label is free to read the way a member would say it
/// while the code stays fixed.
enum NocKind {
  noDues(
    'NoDues',
    'No dues',
    Icons.receipt_long_outlined,
    'Certifies that all maintenance and other dues on your flat are paid.',
  ),
  saleTransfer(
    'SaleTransfer',
    'Sale / transfer',
    Icons.swap_horiz_rounded,
    'For selling or transferring your flat.',
  ),
  renovation(
    'Renovation',
    'Renovation',
    Icons.handyman_outlined,
    'For interior repairs or renovation work in your flat.',
  ),
  mortgage(
    'Mortgage',
    'Mortgage / loan',
    Icons.account_balance_outlined,
    'For a bank loan against your flat.',
  ),
  general(
    'General',
    'General',
    Icons.description_outlined,
    'For any other purpose you can describe below.',
  ),
  other(
    'Other',
    'Other',
    Icons.edit_outlined,
    'For a certificate you would like titled yourself.',
  );

  const NocKind(this.code, this.label, this.icon, this.hint);

  /// What the server stores in noc_request.noc_type.
  final String code;
  final String label;
  final IconData icon;

  /// One line telling the member what this kind is for.
  final String hint;

  bool get isCustom => this == NocKind.other;

  static NocKind fromCode(String? code) => NocKind.values.firstWhere(
    (k) => k.code == code,
    orElse: () => NocKind.general,
  );
}

/// Where a request has got to, as the member sees it.
///
/// The codes are vendor_bills': 1 Pending, 2 Approved, 4 Rejected, with 5 and
/// 6 added for the two steps that happen on paper. Approved deliberately does
/// not say "come and collect it" — the letter still has to be signed, and the
/// society gives out the appointment separately.
enum NocStatus {
  pending(1, 'Pending', 'With the committee', Color(0xFFFF9800)),
  approved(2, 'Approved', 'Approved — being signed', Color(0xFF2196F3)),
  rejected(4, 'Rejected', 'Not approved', Color(0xFFE31837)),
  ready(5, 'Ready', 'Ready to collect', Color(0xFF008116)),
  collected(6, 'Collected', 'Collected', Color(0xFF64748B));

  const NocStatus(this.code, this.label, this.description, this.color);

  final int code;
  final String label;

  /// The fuller line shown on the card, which says what the member should do.
  final String description;
  final Color color;

  static NocStatus fromCode(int? code) => NocStatus.values.firstWhere(
    (s) => s.code == code,
    orElse: () => NocStatus.pending,
  );
}

/// A member's NOC requests, and the form that raises a new one.
class NocRequestScreen extends ConsumerStatefulWidget {
  const NocRequestScreen({super.key});

  @override
  ConsumerState<NocRequestScreen> createState() => _NocRequestScreenState();
}

class _NocRequestScreenState extends ConsumerState<NocRequestScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final flatId = ref.read(basicInfoViewModelProvider).flatId;
    if (flatId != null) {
      await ref.read(NocViewModelProvider.notifier).getNocRequests(flatId);
    }
  }

  Future<void> _openForm() async {
    final raised = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NocRequestFormScreen()),
    );
    // The form reloads the list on success itself; this only covers the member
    // coming back some other way.
    if (raised != true && mounted) await _load();
  }

  /// Matched on the type, the purpose and the serial — what a member
  /// remembers about a certificate they asked for.
  bool _matches(NocRequest r) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return NocKind.fromCode(r.nocType).label.toLowerCase().contains(q) ||
        (r.customTitle ?? '').toLowerCase().contains(q) ||
        (r.purpose ?? '').toLowerCase().contains(q) ||
        (r.serialNo ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(NocViewModelProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _canvas,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'NOC Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Request NOC'),
      ),
      body: state.requestList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStatePage(error: err, onRetry: _load),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _load,
              child: _buildEmptyState(searching: false),
            );
          }

          final shown = items.where(_matches).toList();

          return RefreshIndicator(
            onRefresh: _load,
            child: Column(
              children: [
                // The search box only earns its place once there is a list to
                // search; on a member's first visits it is one more thing
                // between them and the button they came for.
                if (items.length > 2) _buildSearch(),
                Expanded(
                  child: shown.isEmpty
                      ? _buildEmptyState(searching: true)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                          itemCount: shown.length,
                          itemBuilder: (_, i) =>
                              _RequestCard(request: shown[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search your requests...',
          hintStyle: const TextStyle(color: _muted),
          prefixIcon: const Icon(Icons.search, color: _muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  /// Nothing raised yet, or nothing matching a search — the two need different
  /// words, and offering "Request NOC" to somebody mid-search answers a
  /// question they did not ask.
  Widget _buildEmptyState({required bool searching}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      searching ? Icons.search_off : Icons.verified_outlined,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    searching ? 'Nothing Matches' : 'No NOC Requests Yet',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searching
                        ? 'Try a different word.'
                        : 'Ask the society for a no-objection\ncertificate — '
                              'for a bank loan, a sale,\nor renovation work',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _muted,
                      height: 1.5,
                    ),
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

/// One request, with whatever the member needs to do about it.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final NocRequest request;

  @override
  Widget build(BuildContext context) {
    final kind = NocKind.fromCode(request.nocType);
    final status = NocStatus.fromCode(request.status);
    final title = kind.isCustom && (request.customTitle?.isNotEmpty ?? false)
        ? request.customTitle!
        : kind.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(kind.icon, size: 21, color: status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _heading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.serialNo?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            request.serialNo!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status.color,
                    ),
                  ),
                ),
              ],
            ),

            if (request.purpose?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                request.purpose!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              status.description,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),

            // Ready: the appointment is the whole point of the card, so it is
            // spelled out rather than left as a date on a line.
            if (status == NocStatus.ready) _CollectionPanel(request: request),

            if (status == NocStatus.rejected &&
                (request.rejectReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31837).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.rejectReason!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC62828),
                    height: 1.5,
                  ),
                ),
              ),
            ],

            if (status == NocStatus.collected &&
                (request.collectedOn?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                'Collected on ${_prettyDate(request.collectedOn)}'
                '${(request.collectedBy?.isNotEmpty ?? false) ? ' by ${request.collectedBy}' : ''}',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],

            if (request.requestedOn?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Requested ${_prettyDate(request.requestedOn)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// When and where to come for the signed letter.
class _CollectionPanel extends StatelessWidget {
  const _CollectionPanel({required this.request});

  final NocRequest request;

  @override
  Widget build(BuildContext context) {
    final rows = <_CollectionRow>[
      if (request.collectionDate?.isNotEmpty ?? false)
        _CollectionRow(Icons.event, _prettyDate(request.collectionDate)),
      if (request.collectionTime?.isNotEmpty ?? false)
        _CollectionRow(Icons.schedule, request.collectionTime!),
      if (request.collectionNote?.isNotEmpty ?? false)
        _CollectionRow(Icons.info_outline, request.collectionNote!),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF008116).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collect from the society office',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00610F),
            ),
          ),
          if (rows.isNotEmpty) const SizedBox(height: 10),
          ...rows,
          const SizedBox(height: 6),
          const Text(
            'The signed copy is the valid certificate — please collect it in '
            'person.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF00610F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF00610F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// yyyy-MM-dd or an ISO timestamp as "18 Sep 2026".
String _prettyDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

/// The form that raises a request.
///
/// Only the type, the title of an `Other` request and the purpose are asked
/// for. The member's name and flat come from their login, and everything else
/// — the wording, who approves it, when it can be collected — is the society's
/// to decide.
class NocRequestFormScreen extends ConsumerStatefulWidget {
  const NocRequestFormScreen({super.key});

  @override
  ConsumerState<NocRequestFormScreen> createState() =>
      _NocRequestFormScreenState();
}

class _NocRequestFormScreenState extends ConsumerState<NocRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _titleController = TextEditingController();

  NocKind _kind = NocKind.noDues;
  bool _submitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final info = ref.read(basicInfoViewModelProvider);
    if (info.flatId == null || info.societyID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your flat details are still loading. Please retry.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final request = NocRequest(
      societyId: info.societyID,
      flatId: info.flatId,
      userId: info.ownerId,
      memberName: info.name,
      flatNo: info.unit,
      nocType: _kind.code,
      customTitle: _kind.isCustom ? _titleController.text.trim() : null,
      purpose: _purposeController.text.trim(),
    );

    await ref.read(NocViewModelProvider.notifier).insertNocRequest(request);
    if (!mounted) return;

    final state = ref.read(NocViewModelProvider);
    setState(() => _submitting = false);

    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
      return;
    }

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request sent. The society will review it.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(basicInfoViewModelProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _canvas,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Request NOC',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            // Shown, not editable: a NOC is issued against the flat on record,
            // so letting the member type a different one would only produce a
            // certificate the society cannot sign.
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(info.name),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Certificate will be issued to',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          info.name ?? '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _heading,
                          ),
                        ),
                        if (info.unit?.isNotEmpty ?? false)
                          Text(
                            'Flat ${info.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const _SectionLabel('What do you need the NOC for?'),
            const SizedBox(height: 10),

            // A dropdown, not a radio list: six kinds down the page took most
            // of the screen before the member reached the field that actually
            // needs typing.
            _Card(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NocKind>(
                  value: _kind,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: _muted),
                  // The collapsed field shows the kind alone; the hint below
                  // the card carries the explanation, so the row does not have
                  // to hold two lines of text.
                  selectedItemBuilder: (_) => [
                    for (final kind in NocKind.values)
                      Row(
                        children: [
                          Icon(kind.icon, size: 20, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            kind.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _heading,
                            ),
                          ),
                        ],
                      ),
                  ],
                  items: [
                    for (final kind in NocKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Row(
                          children: [
                            Icon(kind.icon, size: 19, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kind.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _heading,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _kind = v ?? _kind),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                _kind.hint,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  height: 1.4,
                ),
              ),
            ),

            if (_kind.isCustom) ...[
              const SizedBox(height: 20),
              const _SectionLabel('What should the certificate be called?'),
              const SizedBox(height: 10),
              _Card(
                child: TextFormField(
                  controller: _titleController,
                  enabled: !_submitting,
                  maxLength: 150,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'e.g. NOC for gas connection',
                    hintStyle: TextStyle(fontSize: 14, color: _muted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please give the certificate a title'
                      : null,
                ),
              ),
            ],

            const SizedBox(height: 20),
            const _SectionLabel('Why do you need it?'),
            const SizedBox(height: 10),
            _Card(
              child: TextFormField(
                controller: _purposeController,
                enabled: !_submitting,
                maxLines: 4,
                maxLength: 300,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: const InputDecoration(
                  hintText:
                      'e.g. For a home loan from State Bank of India, '
                      'Andheri branch',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _muted,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please say what the certificate is for'
                    : null,
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 17, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The committee will review your request. Once it is '
                      'approved the society will sign the certificate and tell '
                      'you when to collect it from the office.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1565C0),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two letters for the avatar, or a single one from a mononym.
String _initials(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _heading,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
