import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/utils/error_formatter.dart';
import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';

class GateKeeperAttendanceScreen extends ConsumerStatefulWidget {
  final int staffId;

  const GateKeeperAttendanceScreen({super.key, required this.staffId});

  @override
  ConsumerState<GateKeeperAttendanceScreen> createState() =>
      _GateKeeperAttendanceScreenState();
}

class _GateKeeperAttendanceScreenState
    extends ConsumerState<GateKeeperAttendanceScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(staffmodelProvider.notifier)
          .fetchMyAttendanceHistory(widget.staffId);
    });
  }

  int _statusCode(StaffAttendance a) => a.status ?? 1;

  String _statusText(int code) {
    switch (code) {
      case 1:
        return 'Present';
      case 2:
        return 'Absent';
      case 3:
        return 'Leave';
      default:
        return 'No Record';
    }
  }

  Color _statusColor(int code) {
    switch (code) {
      case 1:
        return Colors.green.shade600;
      case 2:
        return Colors.red.shade600;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final datePart = dateStr.split(' ')[0];
      final parts = datePart.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<DateTime, StaffAttendance> _indexByDay(List<StaffAttendance> records) {
    final map = <DateTime, StaffAttendance>{};
    for (final record in records) {
      final date = _parseDate(record.inDate);
      if (date == null) continue;
      map[DateTime(date.year, date.month, date.day)] = record;
    }
    return map;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffmodelProvider);
    final historyAsync = state.myAttendanceHistory;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: const Color(0xFF5E72E4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5E72E4),
        onRefresh: () => ref
            .read(staffmodelProvider.notifier)
            .fetchMyAttendanceHistory(widget.staffId),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(getErrorMessage(error)),
          data: (records) {
            final byDay = _indexByDay(records);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildMonthCalendar(byDay),
                const SizedBox(height: 16),
                _buildSelectedDayCard(byDay[_selectedDate]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(Map<DateTime, StaffAttendance> byDay) {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday % 7; // Sunday-first grid

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final today = DateTime.now();
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          Row(
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          for (int row = 0; row < rowCount; row++)
            Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - leadingBlanks + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final date =
                    DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
                final record = byDay[date];
                final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, today);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isFuture
                          ? null
                          : () => setState(() => _selectedDate = date),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5E72E4)
                              : record != null
                                  ? _statusColor(_statusCode(record)).withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: const Color(0xFF5E72E4), width: 1.5)
                              : null,
                        ),
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                    ? Colors.grey[350]
                                    : record != null
                                        ? _statusColor(_statusCode(record))
                                        : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendItem('Present', Colors.green.shade600),
              _legendItem('Absent', Colors.red.shade600),
              _legendItem('Leave', Colors.orange.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSelectedDayCard(StaffAttendance? record) {
    const weekdayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateLabel =
        '${weekdayNames[_selectedDate.weekday - 1]}, ${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';

    final statusCode = record != null ? _statusCode(record) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(statusCode).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(statusCode),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(statusCode),
                  ),
                ),
              ),
            ],
          ),
          if (record != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _timeInfo('In Time', record.inTime ?? '--'),
                ),
                Expanded(
                  child: _timeInfo('Out Time', record.outTime ?? '--'),
                ),
              ],
            ),
            if (record.workingHours != null) ...[
              const SizedBox(height: 12),
              _timeInfo('Working Hours',
                  '${record.workingHours!.toStringAsFixed(1)} hrs'),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'No attendance record for this date',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Could not load attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(staffmodelProvider.notifier)
                  .fetchMyAttendanceHistory(widget.staffId),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E72E4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
