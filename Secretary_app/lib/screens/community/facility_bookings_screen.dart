import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../domain/models/json_utils.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/community_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import 'book_facility_screen.dart';

/// Facility bookings — the clubhouse, hall and other amenities.
///
/// A search box with a facility filter beside it, a compact summary bar, and
/// then one card per booking. The booking form is a page of its own
/// ([BookFacilityScreen]) rather than the bottom sheet it used to be — a
/// booking asks for more than a sheet shows without scrolling inside a sheet
/// that is itself being dragged.
class FacilityBookingsScreen extends ConsumerStatefulWidget {
  const FacilityBookingsScreen({super.key});

  @override
  ConsumerState<FacilityBookingsScreen> createState() =>
      _FacilityBookingsScreenState();
}

class _FacilityBookingsScreenState
    extends ConsumerState<FacilityBookingsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  /// Which facility the list is narrowed to; null is all of them.
  String? _facilityFilter;

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

  /// Drop both filters at once — what the empty state's button offers when a
  /// search and a chip between them have hidden every row.
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _facilityFilter = null;
    });
  }

  Future<void> _refresh() =>
      ref.read(communityViewModelProvider.notifier).loadBookings();

  /// The booking form, as a page.
  ///
  /// The list reloads from the viewmodel on success, so nothing is refetched
  /// here — the page only has to be dismissed.
  Future<void> _book() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const BookFacilityScreen()),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await confirmAction(
      context,
      title: 'Cancel this booking?',
      message: 'The slot will be free for someone else.',
      confirmLabel: 'Cancel booking',
      cancelLabel: 'Keep it',
      destructive: true,
    );

    if (!confirmed) return;
    await ref.read(communityViewModelProvider.notifier).deleteBooking(id);
  }

  bool _matches(Map<String, dynamic> row) {
    if (_search.isEmpty) return true;
    return [
      pick(row, ['facility_name', 'facility', 'name']),
      pick(row, ['name', 'owner_name', 'booked_by']),
      pick(row, ['flat_no', 'unit_no', 'Unit', 'flat']),
      pick(row, ['build_name', 'building_name']),
      pick(row, ['pre_mob', 'contact']),
    ].any((f) => f != null && f.toLowerCase().contains(_search));
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, communityViewModelProvider);

    final rows = ref
        .watch(communityViewModelProvider)
        .rows(CommunityKeys.bookings);

    return Scaffold(
      appBar: AppBar(title: const Text('Facility bookings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _book,
        icon: const Icon(Icons.add),
        label: const Text('New booking'),
      ),
      body: SafeArea(
        child: PageConstraints(
          padded: false,
          child: RowsView(
            rows: rows,
            onRefresh: _refresh,
            emptyIcon: Icons.event_available_outlined,
            emptyTitle: 'No bookings',
            emptyMessage: 'Facilities are free at the moment.',
            builder: (items) {
              // The search and the chips both narrow what is already loaded,
              // so the summary above them counts what is on screen rather than
              // what came back from the server — a total that disagrees with
              // the list under it reads as a bug.
              final searched = items.where(_matches).toList();
              final byFacility = _countByFacility(searched);
              final shown = _facilityFilter == null
                  ? searched
                  : searched
                        .where(
                          (r) =>
                              (pick(r, [
                                'facility_name',
                                'facility',
                                'name',
                              ]) ??
                              '—') ==
                              _facilityFilter,
                        )
                        .toList();

              final revenue = shown.fold<double>(
                0,
                (sum, r) => sum + asDoubleOr(r['amount']),
              );

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  Breakpoints.pagePadding(context).left,
                  AppTheme.space3,
                  Breakpoints.pagePadding(context).right,
                  118,
                ),
                children: [
                  // Search and the facility filter share a row: the filter is
                  // the same act of narrowing the list, and as a chip strip it
                  // wrapped onto three rows once a society had a handful of
                  // amenities. It drops under the search box on a narrow phone,
                  // where two controls side by side leave each too small.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final search = SearchField(
                        controller: _searchController,
                        hint: 'Search bookings…',
                        onChanged: (v) =>
                            setState(() => _search = v.trim().toLowerCase()),
                      );

                      // Nothing to filter with fewer than two facilities.
                      if (byFacility.length < 2) return search;

                      final filter = _FacilityFilter(
                        counts: byFacility,
                        total: searched.length,
                        selected: _facilityFilter,
                        onSelect: (name) =>
                            setState(() => _facilityFilter = name),
                      );

                      if (constraints.maxWidth < 480) {
                        return Column(
                          children: [
                            search,
                            const SizedBox(height: AppTheme.space2),
                            filter,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: AppTheme.space2),
                          SizedBox(width: 190, child: filter),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.space3),

                  // A single compact bar rather than two tall tiles: these are
                  // two figures read in passing, and as StatTiles they took a
                  // third of the screen before a booking was visible.
                  _SummaryBar(count: shown.length, revenue: revenue),

                  const SizedBox(height: AppTheme.space4),

                  if (shown.isEmpty)
                    StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Nothing matches',
                      message: _facilityFilter != null
                          ? 'No bookings for $_facilityFilter.'
                          : 'No booking matches “$_search”.',
                      actionLabel: 'Clear filters',
                      onAction: _clearFilters,
                    )
                  else
                    // A grid rather than a column: on a tablet or in the
                    // browser one card per row leaves most of the width empty,
                    // and these cards are short enough to sit two or three
                    // abreast.
                    _BookingLayout(
                      children: [
                        for (final row in shown)
                          _BookingCard(
                            row: row,
                            onCancel: () {
                              final id = pickInt(row, [
                                'facility_book_id',
                                'booking_id',
                                'id',
                              ]);
                              if (id != null) _confirmDelete(id);
                            },
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Facility name -> how many bookings, most-booked first.
  List<MapEntry<String, int>> _countByFacility(
    List<Map<String, dynamic>> rows,
  ) {
    final counts = <String, int>{};
    for (final r in rows) {
      final name = pick(r, ['facility_name', 'facility', 'name']) ?? '—';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────

/// One column on a phone, two or three side by side above it.
///
/// A Wrap rather than a GridView: the cards vary in height with how much of a
/// booking is filled in, and a grid would size every one of them to the
/// tallest.
class _BookingLayout extends StatelessWidget {
  const _BookingLayout({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isPhone(context)) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTheme.space3),
            children[i],
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // 320 is about the narrowest a booking card stays readable at — below
        // it the facility name and the amount start fighting for the top row.
        final columns = (available / 320).floor().clamp(1, 3);
        final width =
            (available - AppTheme.space3 * (columns - 1)) / columns;

        return Wrap(
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space3,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// The two figures over the list, on one compact bar.
///
/// They were a pair of [StatTile]s, which are sized for a dashboard where the
/// figure is the content. Here the content is the bookings underneath, and two
/// tall tiles pushed the first card most of the way off a phone screen — so
/// the same numbers are laid out along a single row instead.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.count, required this.revenue});

  final int count;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              icon: Icons.event_note_rounded,
              color: AppTheme.primary,
              label: 'Bookings',
              value: '$count',
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.spacer,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
          ),
          Expanded(
            child: _Figure(
              icon: Icons.payments_rounded,
              color: AppTheme.success,
              label: 'Revenue',
              value: money(revenue),
            ),
          ),
        ],
      ),
    );
  }
}

/// One figure on the summary bar — a tinted icon, the number, its label.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: AppTheme.surfaceFor(color),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppTheme.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The revenue figure runs long on a wide society; scaling it
              // down beats letting it overflow the bar or wrap under its own
              // label.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTheme.title.copyWith(fontSize: 16),
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
    );
  }
}

/// The facility filter, as a dropdown beside the search box.
///
/// It was a strip of count chips. One per facility reads well for three or
/// four, but a society with a dozen amenities wrapped it onto three rows above
/// the list — so the same choice, and the same counts, are folded into a menu
/// that occupies one field.
class _FacilityFilter extends StatelessWidget {
  const _FacilityFilter({
    required this.counts,
    required this.total,
    required this.selected,
    required this.onSelect,
  });

  final List<MapEntry<String, int>> counts;
  final int total;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final active = selected != null;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
      decoration: BoxDecoration(
        color: active ? AppTheme.primarySurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: active ? AppTheme.primary : AppTheme.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          menuMaxHeight: 340,
          icon: Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: active ? AppTheme.primary : AppTheme.lightText,
          ),
          // `null` is the unfiltered state, which a DropdownButton would
          // otherwise render as an empty field rather than as a choice.
          hint: _Label(
            icon: Icons.filter_list_rounded,
            text: 'All facilities',
            count: total,
            active: false,
          ),
          selectedItemBuilder: (context) => [
            _Label(
              icon: Icons.filter_list_rounded,
              text: 'All facilities',
              count: total,
              active: false,
            ),
            for (final entry in counts)
              _Label(
                icon: Icons.meeting_room_rounded,
                text: entry.key,
                count: entry.value,
                active: true,
              ),
          ],
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All facilities ($total)', style: AppTheme.body2),
            ),
            for (final entry in counts)
              DropdownMenuItem<String?>(
                value: entry.key,
                child: Text(
                  '${entry.key} (${entry.value})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body2,
                ),
              ),
          ],
          onChanged: onSelect,
        ),
      ),
    );
  }
}

/// What the filter field shows once closed.
class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.text,
    required this.count,
    required this.active,
  });

  final IconData icon;
  final String text;
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tint = active ? AppTheme.primary : AppTheme.lightText;

    return Row(
      children: [
        Icon(icon, size: 16, color: tint),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: active ? AppTheme.primary : AppTheme.grey,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.chipBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            '$count',
            style: AppTheme.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? AppTheme.white : AppTheme.grey,
            ),
          ),
        ),
      ],
    );
  }
}


/// One booking.
class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.row, required this.onCancel});

  final Map<String, dynamic> row;
  final VoidCallback onCancel;

  /// Midnight today, for deciding whether a booking has already happened.
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final facility = pick(row, ['facility_name', 'facility', 'name']);
    final person = pick(row, ['name', 'owner_name', 'booked_by']);
    final flat = pick(row, ['flat_no', 'unit_no', 'Unit', 'flat']);
    final building = pick(row, ['build_name', 'building_name']);
    final phone = pick(row, ['pre_mob', 'contact']);
    final fromDate = row['from_date'] ?? row['book_date'];
    final toDate = row['to_date'];
    final fromTime = pick(row, ['from_time']);
    final toTime = pick(row, ['to_time']);

    final where = [
      building,
      flat,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    /*
     * Upcoming or done, from the last day the booking covers. It is the one
     * thing about a booking that is not written on it, and it is what a
     * secretary is scanning the list for — a past booking is history, an
     * upcoming one may still need chasing. It drives the spine colour, the
     * chip, and whether Cancel is offered at all.
     */
    final last = asDate(toDate) ?? asDate(fromDate);
    final past = last != null && last.isBefore(_today);
    final accent = past ? AppTheme.lightText : AppTheme.primary;

    return AppCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A tinted band behind the facility and the amount, so the two
          // things read first — which amenity, and what it cost — are lifted
          // off the details under them instead of sharing their weight.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space4,
              AppTheme.space3,
              AppTheme.space4,
              AppTheme.space3,
            ),
            decoration: BoxDecoration(
              color: past ? AppTheme.spacer : AppTheme.primarySurface,
              border: const Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconPlate(
                  icon: Icons.meeting_room_rounded,
                  color: accent,
                  size: 40,
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility ?? 'Facility',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(
                          fontSize: 16,
                          color: past ? AppTheme.grey : AppTheme.darkerText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      StatusChip(
                        label: past ? 'Completed' : 'Upcoming',
                        color: past ? AppTheme.lightText : AppTheme.success,
                        icon: past
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space2),
                // The amount on its own plate rather than as loose text: it is
                // the figure the secretary quotes, and a white chip on the
                // tinted band is what makes it findable at a glance.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    money(row['amount']),
                    style: AppTheme.title.copyWith(
                      fontSize: 15,
                      color: past ? AppTheme.grey : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space4,
              AppTheme.space3,
              AppTheme.space4,
              AppTheme.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Who booked it, with Cancel at the end of the same row — the
                // action belongs to this person's booking, and putting it here
                // saves the card a line of its own at the foot.
                Row(
                  children: [
                    if (person != null && person.isNotEmpty) ...[
                      InitialsAvatar(name: person, size: 28),
                      const SizedBox(width: AppTheme.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (where.isNotEmpty)
                              Text(
                                where,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.caption,
                              ),
                          ],
                        ),
                      ),
                    ] else
                      // Nothing to name the booking by, but the button still
                      // has to sit at the right-hand edge rather than the left.
                      const Spacer(),
                    const SizedBox(width: AppTheme.space2),
                    _CancelButton(onPressed: onCancel),
                  ],
                ),

                const SizedBox(height: AppTheme.space3),

                // When and who to ring, each on its own tinted plate. Wrapped
                // rather than laid out in a fixed row so a long date range
                // does not squeeze the phone number out.
                Wrap(
                  spacing: AppTheme.space2,
                  runSpacing: AppTheme.space2,
                  children: [
                    _Fact(
                      icon: Icons.event_rounded,
                      text: toDate == null
                          ? prettyDate(fromDate)
                          : '${prettyDate(fromDate)} — ${prettyDate(toDate)}',
                      color: AppTheme.info,
                    ),
                    if (fromTime != null)
                      _Fact(
                        icon: Icons.schedule_rounded,
                        text: toTime == null
                            ? fromTime
                            : '$fromTime – $toTime',
                        color: AppTheme.violet,
                      ),
                    if (phone != null && phone.isNotEmpty)
                      _Fact(
                        icon: Icons.call_rounded,
                        text: phone,
                        color: AppTheme.teal,
                      ),
                  ],
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

/// Cancel, sat at the end of the booking's owner row.
///
/// Offered on every booking, past or upcoming: one already gone by can still
/// have been entered by mistake, or be cancelled after the fact when the money
/// is refunded — the record is the society's to remove either way.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.close_rounded, size: 15),
      label: const Text('Cancel booking'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        // White rather than a tint: the button sits on the card's own white,
        // so the outline is what draws it and a fill only made it heavier
        // than the booking it belongs to.
        backgroundColor: AppTheme.cardBackground,
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.35)),
        /*
         * Compact, and shorter than the 44 a standalone control wants: it
         * shares a row with the owner's name rather than owning a line, so a
         * full-height button would set the row's height and push the name's
         * two lines out of alignment with the avatar beside them.
         */
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
        textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }
}

/// An icon and a value on a tinted plate — one of the facts on a booking card.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
