import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A clock face in a dialog, matching the app's calendar.
///
/// Flutter's `showTimePicker` is the full-screen Material dialog — the same
/// mismatch `showSingleDateDialog` was written to fix for dates. A form that
/// asks for a date and a time should not open two different-looking things,
/// so this borrows the calendar's chrome: the gradient header carrying the
/// current value, the same width, the same Cancel/Apply bar.
///
/// Returns null if dismissed, so the caller keeps the time it had.
Future<TimeOfDay?> showTimeDialog({
  required BuildContext context,
  TimeOfDay? initial,
  String? title,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) =>
        _TimeDialog(initial: initial ?? TimeOfDay.now(), title: title),
  );
}

class _TimeDialog extends StatefulWidget {
  const _TimeDialog({required this.initial, this.title});

  final TimeOfDay initial;

  /// What the header calls the field, e.g. "Arrived at".
  final String? title;

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  late int _hour;
  late int _minute;

  /*
   * Each list opens scrolled to the value already set, rather than at the top:
   * a form defaulted to 3:47pm would otherwise open showing 1 and 00, and the
   * current time — the thing most likely to be kept — would be off screen.
   *
   * The offset is computed rather than animated to, so the list is already in
   * place on the first frame.
   */
  late final ScrollController _hourScroll;
  late final ScrollController _minuteScroll;

  /// Row height and the padding above the list, which together decide where a
  /// given index sits. Shared with _WheelList so the two cannot drift.
  static const _rowHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;

    // Two rows above the selection, so it lands a little below the top edge
    // with its neighbours visible rather than flush against it.
    double offsetFor(int index) =>
        ((index - 2) * _rowHeight).clamp(0.0, double.infinity);

    _hourScroll = ScrollController(initialScrollOffset: offsetFor(_hour12 - 1));
    _minuteScroll = ScrollController(initialScrollOffset: offsetFor(_minute));
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    _minuteScroll.dispose();
    super.dispose();
  }

  TimeOfDay get _value => TimeOfDay(hour: _hour, minute: _minute);

  /// 24h to the 1–12 shown on the dial.
  int get _hour12 => _hour % 12 == 0 ? 12 : _hour % 12;

  bool get _isPm => _hour >= 12;

  void _setHour12(int shown) {
    // The half of the day is held by the AM/PM control, so moving the hour
    // must not flip it: 9 stays 9pm rather than jumping to 9am.
    final base = shown % 12;
    setState(() => _hour = _isPm ? base + 12 : base);
  }

  void _setHalf(bool pm) {
    if (pm == _isPm) return;
    setState(() => _hour = pm ? _hour + 12 : _hour - 12);
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
        // The same cap as the calendar, so the two are the same width when a
        // form opens them one after the other.
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
              child: _buildColumns(),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// The time as it stands, in the calendar's gradient bar.
  Widget _buildHeader() {
    final label = MaterialLocalizations.of(context).formatTimeOfDay(_value);

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
            widget.title ?? 'Selected time',
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
              label,
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

  /// Hours and minutes as two scrolling lists, side by side.
  ///
  /// A list rather than a clock face: the dial could only offer twelve hours
  /// and a handful of minutes without the targets becoming too small to hit,
  /// so an odd minute like 3:02 needed a separate stepper to reach. Two lists
  /// hold all 12 hours and all 60 minutes at a tappable size, and each opens
  /// scrolled to the value already set.
  Widget _buildColumns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Hour', style: AppTheme.overline)),
            const SizedBox(width: AppTheme.space3),
            Expanded(child: Text('Minute', style: AppTheme.overline)),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        SizedBox(
          // Tall enough to show five rows, so it reads as a list that scrolls
          // rather than a box that happens to be cut off.
          height: 208,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WheelList(
                  controller: _hourScroll,
                  count: 12,
                  // 1..12 on the face; the stored hour is 24h.
                  labelOf: (i) => '${i + 1}',
                  selectedIndex: _hour12 - 1,
                  onTap: (i) => _setHour12(i + 1),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: _WheelList(
                  controller: _minuteScroll,
                  count: 60,
                  labelOf: (i) => i.toString().padLeft(2, '0'),
                  selectedIndex: _minute,
                  onTap: (i) => setState(() => _minute = i),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Center(child: _buildHalfToggle()),
        const SizedBox(height: AppTheme.space3),
      ],
    );
  }

  /// AM and PM, as a pair of pills.
  Widget _buildHalfToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final pm in [false, true])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: _isPm == pm ? AppTheme.primary : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                onTap: () => _setHalf(pm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space5,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: _isPm == pm ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    pm ? 'PM' : 'AM',
                    style: AppTheme.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isPm == pm ? AppTheme.white : AppTheme.lightText,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space3,
        AppTheme.space3,
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
            onPressed: () => Navigator.pop(context, _value),
            style: ElevatedButton.styleFrom(minimumSize: const Size(96, 40)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

/// A scrolling column of numbers, one of which is selected.
///
/// Used for the hour and the minute. Bordered like a field rather than drawn
/// as a bare list, so the two read as one control beside each other.
class _WheelList extends StatelessWidget {
  const _WheelList({
    required this.controller,
    required this.count,
    required this.labelOf,
    required this.selectedIndex,
    required this.onTap,
  });

  final ScrollController controller;
  final int count;
  final String Function(int index) labelOf;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        controller: controller,
        padding: EdgeInsets.zero,
        itemCount: count,
        itemExtent: _TimeDialogState._rowHeight,
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;

          return Material(
            color: selected ? AppTheme.primary : Colors.transparent,
            child: InkWell(
              onTap: () => onTap(i),
              child: Center(
                child: Text(
                  labelOf(i),
                  style: AppTheme.body2.copyWith(
                    fontSize: 15,
                    color: selected ? AppTheme.white : AppTheme.darkText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
