import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'poll_form_screen.dart';

/// Polls put to the society, and what they are asking.
///
/// Its own screen rather than a tab inside Community › More, which is where it
/// used to sit: More lists things the committee reads, while a poll is
/// something the committee starts — and starting one there meant three taps
/// and no way to actually create anything.
///
/// Kept apart from Announcements deliberately. A notice, a meeting and an
/// event all say "this is happening"; a poll asks a question and collects
/// answers, and its rows carry a vote count rather than a date to keep.
class PollsScreen extends ConsumerStatefulWidget {
  const PollsScreen({super.key});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  /// Loads the polls and, as part of the same call, each one's options.
  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadPolls();

  Future<void> _openForm() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const PollFormScreen()));
  }

  Future<void> _confirmDelete(int id, String topic) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this poll?',
      message: '"$topic" and the votes cast on it will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) return;
    await ref.read(communityViewModelProvider.notifier).deletePoll(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.polls);

    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('New poll'),
        backgroundColor: AppTheme.violet,
      ),
      body: SafeArea(
        child: RowsView(
          rows: rows,
          onRefresh: _refresh,
          emptyIcon: Icons.how_to_vote_rounded,
          emptyTitle: 'No polls',
          emptyMessage: 'Start one to put a decision to the society.',
          emptyActionLabel: 'New poll',
          emptyAction: _openForm,
          builder: _buildList,
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 118),
      children: [
        PageConstraints(
          child: Column(children: [for (final row in items) _buildCard(row)]),
        ),
      ],
    );
  }

  /// Send a tap on an option to the server.
  ///
  /// Nothing is decided here: whether this user may vote at all, and whether
  /// they have already voted, are sp_PollVoting's rules, and a refusal comes
  /// back as its own message — which `listenForFeedback` shows.
  Future<void> _vote(int pollId, int optionId) async {
    await ref
        .read(communityViewModelProvider.notifier)
        .votePoll(pollId, optionId);
  }

  Widget _buildCard(Map<String, dynamic> row) {
    final id = pickInt(row, ['PollId', 'poll_id', 'pollId', 'id']);
    final topic = pick(row, [
      'Topic',
      'topic',
      'question',
      'poll_name',
      'name',
    ]);
    final description = pick(row, ['Description', 'description', 'details']);
    final expiry = row['ExpiryDate'] ?? row['expiry_date'] ?? row['expiryDate'];
    // Prefer the total summed from the options, falling back to the column on
    // the poll row until they have loaded. Read only off the row, the chip and
    // the bars below it are two different counts of the same thing and can
    // disagree — after a vote the row is a refetch behind the options.
    final votes =
        (id == null ? null : _optionTotal(id)) ??
        pickInt(row, ['TotalVotes', 'total_votes', 'votes', 'VoteCount']);

    final closed = _isClosed(expiry);
    final accent = closed ? AppTheme.lightText : AppTheme.violet;

    return AppCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPlate(icon: Icons.how_to_vote_rounded, color: accent),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topic ?? 'Poll',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(
                          fontSize: 15,
                          height: 1.25,
                          color: closed ? AppTheme.grey : AppTheme.darkerText,
                        ),
                      ),
                    ),
                    if (id != null) ...[
                      const SizedBox(width: AppTheme.space2),
                      // No Edit: sp_polls has no update branch, and a poll
                      // whose question changed after people had voted would
                      // make the votes already cast answer something else.
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17),
                          color: AppTheme.error,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(id, topic ?? 'Poll'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body2.copyWith(
                      height: 1.4,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
                // Only the state sits above the options. How many have voted
                // and how long is left are what the options add up to, so they
                // read better under them — the same order the vote page uses.
                const SizedBox(height: AppTheme.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(
                    label: closed ? 'Closed' : 'Open',
                    color: closed ? AppTheme.lightText : AppTheme.success,
                  ),
                ),
                if (id != null) _buildOptions(id, closed),
                const SizedBox(height: AppTheme.space3),
                // A hairline splits the result from its tally, so the footer
                // does not read as one more option.
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                const SizedBox(height: AppTheme.space2),
                Row(
                  children: [
                    Icon(
                      Icons.how_to_reg_rounded,
                      size: 14,
                      color: votes != null && votes > 0
                          ? accent
                          : AppTheme.lightText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      votes == null || votes == 0
                          ? 'No votes yet'
                          : '$votes ${votes == 1 ? 'vote' : 'votes'}',
                      style: AppTheme.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: votes != null && votes > 0
                            ? accent
                            : AppTheme.lightText,
                      ),
                    ),
                    if (expiry != null) ...[
                      const Spacer(),
                      const Icon(
                        Icons.event_outlined,
                        size: 13,
                        color: AppTheme.lightText,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${closed ? 'Closed' : 'Closes'} '
                          '${prettyDate(expiry)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The poll's options, each a tappable bar showing its share of the vote.
  ///
  /// Laid out like a chat-app poll: the option text, its percentage, and a
  /// fill behind it, with the option this user picked marked with a tick.
  Widget _buildOptions(int pollId, bool closed) {
    final options = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.pollOptions(pollId));

    return options.when(
      // Two plain bars, not shimmering Skeletons. A Skeleton repeats its
      // animation for as long as it is on screen, and these sit inside a card
      // that stays put while its options load — which never lets the frame
      // queue drain. It also measures itself with a LayoutBuilder when given
      // no width, and AppCard puts an accented card's contents inside an
      // IntrinsicHeight, which cannot measure one.
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppTheme.space2),
        child: Column(
          children: [
            for (var i = 0; i < 2; i++)
              Container(
                height: 34,
                margin: EdgeInsets.only(bottom: i == 0 ? 6 : 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
          ],
        ),
      ),
      // The poll itself still reads fine without its options, so a failed
      // options call says so quietly instead of taking the card down.
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(top: AppTheme.space2),
        child: Text(
          'Options could not be loaded. Pull down to retry.',
          style: AppTheme.caption.copyWith(fontSize: 11.5),
        ),
      ),
      data: (list) {
        if (list.items.isEmpty) return const SizedBox.shrink();

        // The total is summed from the options rather than read off the poll
        // row, so the percentages and the count below them always agree.
        final counts = [for (final o in list.items) pickInt(o, _voteKeys) ?? 0];
        final total = counts.fold<int>(0, (sum, v) => sum + v);

        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.space2),
          child: Column(
            children: [
              for (var i = 0; i < list.items.length; i++)
                _PollOption(
                  label:
                      pick(list.items[i], [
                        'text',
                        'Text',
                        'OptionText',
                        'option_text',
                        'Option',
                      ]) ??
                      'Option ${i + 1}',
                  votes: counts[i],
                  percent: total == 0 ? 0 : counts[i] / total,
                  selected: _isSelected(list.items[i]),
                  // A closed poll still shows its result, it just cannot be
                  // voted on any more.
                  onTap: closed
                      ? null
                      : () {
                          final optionId = pickInt(list.items[i], [
                            'OptionId',
                            'option_id',
                            'optionId',
                            'id',
                          ]);
                          if (optionId != null) _vote(pollId, optionId);
                        },
                ),
            ],
          ),
        );
      },
    );
  }

  /// The keys a vote count arrives under, in order of preference.
  static const _voteKeys = ['votes', 'Votes', 'VoteCount', 'vote_count'];

  /// Votes cast on a poll, summed from its options, or null while they have
  /// not loaded — which is the caller's cue to fall back to the poll row.
  int? _optionTotal(int pollId) {
    // watch, not read: the chip is built before the options arrive, and has to
    // rebuild with the summed total once they do.
    final options = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.pollOptions(pollId))
        .valueOrNull;
    if (options == null) return null;

    return options.items.fold<int>(
      0,
      (sum, o) => sum + (pickInt(o, _voteKeys) ?? 0),
    );
  }

  /// Whether this user voted for the option. The flag arrives as a bool from
  /// JSON but as 0/1 from the procedure, so both spellings are read.
  static bool _isSelected(Map<String, dynamic> option) {
    final raw =
        option['isSelected'] ?? option['IsSelected'] ?? option['is_selected'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return raw?.toString().toLowerCase() == 'true' || raw?.toString() == '1';
  }

  /// Whether voting has closed.
  ///
  /// Compared by day rather than by instant: a poll expiring today is still
  /// open for the whole of today, which is how the vote page reads it.
  static bool _isClosed(dynamic raw) {
    if (raw == null) return false;
    final date = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
    if (date == null) return false;

    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }
}

/// One option on a poll: its text, its share of the vote, and a fill behind
/// both showing that share.
///
/// The fill is drawn as a sized box behind the row rather than as a
/// LinearProgressIndicator so the text sits on top of it, which is how a poll
/// in a chat app reads — the bar is the row, not a separate line under it.
class _PollOption extends StatelessWidget {
  const _PollOption({
    required this.label,
    required this.votes,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int votes;

  /// 0..1 — this option's share of the votes cast.
  final double percent;

  /// Whether this user voted for this option.
  final bool selected;

  /// Null once voting has closed, which also removes the ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);
    final pct = (percent * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppTheme.violet : AppTheme.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  // The fill. Positioned.fill + FractionallySizedBox so it is
                  // measured against the row's own width, whatever that is.
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent.clamp(0.0, 1.0),
                      // A gradient rather than a flat block: the bar fades out
                      // towards its leading edge, so where it ends reads as a
                      // measurement instead of a second background colour.
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: selected
                                ? [
                                    AppTheme.violet.withValues(alpha: 0.22),
                                    AppTheme.violet.withValues(alpha: 0.10),
                                  ]
                                : const [Color(0xFFE9EEF6), Color(0xFFF4F7FB)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space3,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppTheme.violet,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body2.copyWith(
                              fontSize: 13,
                              height: 1.3,
                              color: AppTheme.darkerText,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space2),
                        // The count as well as the share: 50% of two votes and
                        // 50% of two hundred are the same bar otherwise.
                        Text(
                          '$votes',
                          style: AppTheme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          // Fixed so the percentages line up down the card
                          // instead of shifting with the option's text.
                          width: 34,
                          child: Text(
                            '$pct%',
                            textAlign: TextAlign.right,
                            style: AppTheme.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppTheme.violet : AppTheme.grey,
                            ),
                          ),
                        ),
                      ],
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
