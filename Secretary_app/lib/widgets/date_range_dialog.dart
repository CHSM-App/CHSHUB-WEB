import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';

/// A compact date-range picker in a dialog.
///
/// Flutter's own `showDateRangePicker` takes over the whole screen, which is
/// a lot of ceremony for narrowing a report by a few weeks. This keeps the
/// month in view at the size it actually needs, so the range is picked
/// without leaving the page behind it.
///
/// Returns null if dismissed, so the caller keeps the range it had.
Future<DateTimeRange?> showDateRangeDialog({
  required BuildContext context,
  required DateTimeRange initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => _DateRangeDialog(
      initial: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

/// One date, from the same calendar.
///
/// The app's date fields all used `showDatePicker`, which is the full-screen
/// Material dialog; this is the single-date form of the range picker above,
/// so a form field and a report filter open the same thing.
///
/// Returns null if dismissed, so the caller keeps the date it had.
Future<DateTime?> showSingleDateDialog({
  required BuildContext context,
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  final first = firstDate ?? DateTime(2000);
  final last = lastDate ?? DateTime(2100);

  // A field that is not set yet opens on today, unless today falls outside
  // what the caller allows — a notice's end date cannot be in the past.
  var start = initial ?? DateTime.now();
  if (start.isBefore(first)) start = first;
  if (start.isAfter(last)) start = last;

  return showDialog<DateTime>(
    context: context,
    builder: (context) => _DateRangeDialog(
      initial: DateTimeRange(start: start, end: start),
      firstDate: first,
      lastDate: last,
      singleDate: true,
      title: title,
    ),
  );
}

class _DateRangeDialog extends StatefulWidget {
  const _DateRangeDialog({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    this.singleDate = false,
    this.title,
  });

  final DateTimeRange initial;
  final DateTime firstDate;
  final DateTime lastDate;

  /// One date rather than a span: a tap replaces the selection instead of
  /// closing a range, and Apply pops a DateTime.
  final bool singleDate;

  /// What the header calls the field. Defaults to the mode's own wording.
  final String? title;

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

/// What the body of the dialog is showing.
///
/// Tapping the month name walks up — days to months to years — and picking
/// one walks back down, so a date years away is three taps rather than
/// dozens of presses on the arrow.
enum _View { days, months, years }

class _DateRangeDialogState extends State<_DateRangeDialog> {
  /// The month the grid is showing.
  late DateTime _month;

  _View _view = _View.days;

  /// The block of years the year grid is showing, as its first year.
  late int _decade;

  /// The range being built. [_end] is null between the first and second tap,
  /// which is what tells the two apart.
  late DateTime _start;
  DateTime? _end;

  static final _monthName = DateFormat('MMMM yyyy');
  static final _dayName = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _start = _dayOf(widget.initial.start);
    _end = _dayOf(widget.initial.end);
    // Opens on the month the range starts in, not today's — the user is
    // usually adjusting the range they already have.
    _month = DateTime(_start.year, _start.month);
    _decade = _decadeOf(_start.year);
  }

  /// The 12-year block a year belongs to, so paging the year grid lands on
  /// the same blocks every time rather than drifting with the selection.
  static int _decadeOf(int year) => year - (year % 12);

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _complete => _end != null;

  void _tapDay(DateTime day) {
    setState(() {
      // One date: every tap simply moves the selection, and it stays
      // complete so Apply is always live.
      if (widget.singleDate) {
        _start = day;
        _end = day;
        return;
      }

      // A complete range means the next tap starts a new one. Otherwise this
      // is the second tap, which closes the range — backwards taps are
      // swapped rather than rejected, so picking end-then-start still works.
      if (_complete) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  /// The arrows page whatever is on screen: a month, a year, or a block of
  /// years.
  void _page(int by) {
    setState(() {
      switch (_view) {
        case _View.days:
          _month = DateTime(_month.year, _month.month + by);
        case _View.months:
          _month = DateTime(_month.year + by, _month.month);
        case _View.years:
          _decade += by * 12;
      }
    });
  }

  /// Steps up a level, or back down to days once the top is reached.
  void _tapTitle() {
    setState(() {
      switch (_view) {
        case _View.days:
          _view = _View.months;
        case _View.months:
          _decade = _decadeOf(_month.year);
          _view = _View.years;
        case _View.years:
          _view = _View.days;
      }
    });
  }

  void _tapYear(int year) {
    setState(() {
      // Keeps the month, so picking 2026 from a March view lands on March
      // 2026 rather than resetting to January.
      _month = DateTime(year, _month.month);
      _view = _View.months;
    });
  }

  void _tapMonth(int month) {
    setState(() {
      _month = DateTime(_month.year, month);
      _view = _View.days;
    });
  }

  bool get _canGoBack {
    switch (_view) {
      case _View.days:
        return _month.isAfter(
          DateTime(widget.firstDate.year, widget.firstDate.month),
        );
      case _View.months:
        return _month.year > widget.firstDate.year;
      case _View.years:
        return _decade > widget.firstDate.year;
    }
  }

  bool get _canGoForward {
    switch (_view) {
      case _View.days:
        return _month.isBefore(
          DateTime(widget.lastDate.year, widget.lastDate.month),
        );
      case _View.months:
        return _month.year < widget.lastDate.year;
      case _View.years:
        return _decade + 11 < widget.lastDate.year;
    }
  }

  /// What the title bar reads, and what tapping it will open.
  String get _titleLabel {
    switch (_view) {
      case _View.days:
        return _monthName.format(_month);
      case _View.months:
        return '${_month.year}';
      case _View.years:
        return '$_decade — ${_decade + 11}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      insetPadding: const EdgeInsets.all(AppTheme.space4),
      child: ConstrainedBox(
        // Wide enough for seven columns of tappable days, capped so it does
        // not sprawl on a tablet.
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space4,
                AppTheme.space3,
                AppTheme.space4,
                0,
              ),
              child: Column(
                children: [
                  _buildMonthBar(),
                  const SizedBox(height: AppTheme.space2),
                  // The weekday letters belong to the day grid alone; over a
                  // grid of months they would label nothing.
                  if (_view == _View.days) ...[
                    const _WeekdayRow(),
                    const SizedBox(height: 4),
                    _buildGrid(),
                  ] else if (_view == _View.months)
                    _buildMonthGrid()
                  else
                    _buildYearGrid(),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// The range as it stands, so the taps have somewhere to show up.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ??
                (widget.singleDate
                    ? 'Selected date'
                    : _complete
                    ? 'Selected range'
                    : 'Pick the end date'),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.onGradientMuted,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _complete && !widget.singleDate
                  ? '${_dayName.format(_start)}  —  ${_dayName.format(_end!)}'
                  : _dayName.format(_start),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBar() {
    return Row(
      children: [
        _MonthArrow(
          icon: Icons.chevron_left_rounded,
          onTap: _canGoBack ? () => _page(-1) : null,
        ),
        // The title is the way up a level. A caret marks it as something to
        // press — a bare month name reads as a label, not a control.
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InkWell(
              onTap: _tapTitle,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _titleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.title.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _view == _View.years
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _MonthArrow(
          icon: Icons.chevron_right_rounded,
          onTap: _canGoForward ? () => _page(1) : null,
        ),
      ],
    );
  }

  /// The years in the block on screen, as a grid.
  Widget _buildYearGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      childAspectRatio: 1.7,
      children: [
        for (var year = _decade; year < _decade + 12; year++)
          _PickerCell(
            label: '$year',
            selected: year == _month.year,
            enabled:
                year >= widget.firstDate.year && year <= widget.lastDate.year,
            onTap: () => _tapYear(year),
          ),
      ],
    );
  }

  /// The twelve months of the year on screen.
  Widget _buildMonthGrid() {
    final names = DateFormat().dateSymbols.SHORTMONTHS;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      childAspectRatio: 1.7,
      children: [
        for (var m = 1; m <= 12; m++)
          _PickerCell(
            label: names[m - 1],
            selected: m == _month.month,
            // A month outside the allowed span is not offered, so the year
            // the range starts in cannot be paged into before its first date.
            enabled:
                !DateTime(_month.year, m).isBefore(
                  DateTime(widget.firstDate.year, widget.firstDate.month),
                ) &&
                !DateTime(_month.year, m).isAfter(
                  DateTime(widget.lastDate.year, widget.lastDate.month),
                ),
            onTap: () => _tapMonth(m),
          ),
      ],
    );
  }

  Widget _buildGrid() {
    final first = DateTime(_month.year, _month.month);
    // Day 0 of the next month is the last day of this one.
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    // DateTime.weekday is 1..7 from Monday; the grid starts on Sunday.
    final leading = first.weekday % 7;

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        _buildDay(DateTime(_month.year, _month.month, d)),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: cells,
    );
  }

  Widget _buildDay(DateTime day) {
    final outOfRange =
        day.isBefore(_dayOf(widget.firstDate)) ||
        day.isAfter(_dayOf(widget.lastDate));

    final isStart = day == _start;
    final isEnd = _end != null && day == _end;
    final between = _end != null && day.isAfter(_start) && day.isBefore(_end!);

    return _DayCell(
      day: day.day,
      isStart: isStart,
      isEnd: isEnd,
      between: between,
      // A single-day range would otherwise draw the connecting bar out of
      // both sides of one circle.
      single: isStart && isEnd,
      enabled: !outOfRange,
      onTap: outOfRange ? null : () => _tapDay(day),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space3,
        AppTheme.space2,
        AppTheme.space3,
        AppTheme.space3,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          ElevatedButton(
            // Half a range is not a range: Apply waits for the second tap.
            // A single date is always complete, so it never blocks.
            onPressed: _complete
                ? () => Navigator.pop(
                    context,
                    widget.singleDate
                        ? _start
                        : DateTimeRange(start: _start, end: _end!),
                  )
                : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size(96, 40)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled ? AppTheme.primarySurface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: SizedBox(
          height: 32,
          width: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppTheme.primary : AppTheme.deactivatedText,
          ),
        ),
      ),
    );
  }
}

/// One year or month in the drill-down grids.
class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color text;
    if (!enabled) {
      text = AppTheme.deactivatedText;
    } else if (selected) {
      text = AppTheme.white;
    } else {
      text = AppTheme.darkText;
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: selected
                  ? null
                  : Border.all(
                      color: enabled ? AppTheme.border : Colors.transparent,
                    ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final l in _labels)
          Expanded(
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightText,
              ),
            ),
          ),
      ],
    );
  }
}

/// One day in the grid.
///
/// The ends of the range are filled circles; the days between carry a flat
/// band, so the span reads as one stretch rather than a scatter of marks.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isStart,
    required this.isEnd,
    required this.between,
    required this.single,
    required this.enabled,
    required this.onTap,
  });

  final int day;
  final bool isStart;
  final bool isEnd;
  final bool between;
  final bool single;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEdge = isStart || isEnd;

    final Color text;
    if (!enabled) {
      text = AppTheme.deactivatedText;
    } else if (isEdge) {
      text = AppTheme.white;
    } else if (between) {
      text = AppTheme.primaryDark;
    } else {
      text = AppTheme.darkText;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // The band runs edge to edge so adjacent days join up with no gap,
        // and is cut back to one side under the start and end circles.
        if (between || (isEdge && !single))
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: isStart && !single ? 16 : 0,
                right: isEnd && !single ? 16 : 0,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                color: AppTheme.primarySurface,
              ),
            ),
          ),
        Material(
          color: isEdge ? AppTheme.primary : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(2),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
                  color: text,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
