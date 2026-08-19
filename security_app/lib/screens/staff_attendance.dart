import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class StaffAttendancePage extends ConsumerStatefulWidget {
  const StaffAttendancePage({super.key});

  @override
  ConsumerState<StaffAttendancePage> createState() =>
      _StaffAttendancePageState();
}

class _StaffAttendancePageState extends ConsumerState<StaffAttendancePage> {
  DateTime today = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffmodelProvider.notifier).fetchStaffAttendance(
            ref.read(securitymodelProvider).SocietyId.toString(),
          );
    });
  }

  Future<void> _updateAttendance(int staffId, int statusCode, int previousStatus) async {
    final notifier = ref.read(staffmodelProvider.notifier);

    // 1. Optimistically update UI immediately
    notifier.updateLocalStatus(staffId, statusCode);

    // 2. Call API in background
    final body = StaffAttendance(
      staffId: staffId,
      inDate: _formatDate(today),
      status: statusCode,
    );

    final success = await notifier.updateAttendance(body);

    // 3. If API failed, revert the UI change and show error
    if (!success) {
      if (mounted) {
        // Revert to previous status
        notifier.updateLocalStatus(staffId, previousStatus);
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Status not updated, try again')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Attendance updated successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int _getStatusCode(String? status) {
    if (status == null) return 1;
    switch (status.toLowerCase()) {
      case 'present':
      case '1':
        return 1;
      case 'absent':
      case '2':
        return 2;
      case 'leave':
      case '3':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 1:
        return 'Present';
      case 2:
        return 'Absent';
      case 3:
        return 'Leave';
      default:
        return 'Present';
    }
  }

  Color _getStatusColor(int statusCode) {
    switch (statusCode) {
      case 1:
        return Colors.green.shade600;
      case 2:
        return Colors.red.shade600;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  IconData _getStatusIcon(int statusCode) {
    switch (statusCode) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      case 3:
        return Icons.event_busy;
      default:
        return Icons.check_circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isSameDate(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2].split(' ')[0]);
        
        return year == today.year && month == today.month && day == today.day;
      }
      return false;
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffmodelProvider);
    final staffAttendanceAsync = state.staffAttendanceList;
    final isCheckedIn = state.isCheckedIn;

    // Only show full page loader on initial load
    final isInitialLoading = state.isLoading && staffAttendanceAsync.value == null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          Opacity(
            opacity: isCheckedIn ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !isCheckedIn,
              child: isInitialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && staffAttendanceAsync.value == null
                      ? _buildErrorState(state.error!)
                      : staffAttendanceAsync.when(
                          data: (staffList) {
                            if (staffList.isEmpty) {
                              return _buildEmptyState();
                            }

                            final todayAttendance =
                                staffList.where((s) => _isSameDate(s.inDate)).toList();

                            final displayList = todayAttendance.isEmpty ? staffList : todayAttendance;

                            int presentCount = displayList
                                .where((s) => _getStatusCode(s.status.toString()) == 1)
                                .length;
                            int absentCount = displayList
                                .where((s) => _getStatusCode(s.status.toString()) == 2)
                                .length;
                            int leaveCount = displayList
                                .where((s) => _getStatusCode(s.status.toString()) == 3)
                                .length;

                            return Column(
                              children: [
                                // Stats Section
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.shade600,
                                        Colors.indigo.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people_alt_rounded,
                                            color: Colors.white.withOpacity(0.9),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Today\'s Overview',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatCard(
                                            'Present',
                                            presentCount,
                                            Colors.green.shade600,
                                            Icons.check_circle,
                                          ),
                                          Container(
                                            height: 45,
                                            width: 1,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          _buildStatCard(
                                            'Absent',
                                            absentCount,
                                            Colors.red.shade600,
                                            Icons.cancel,
                                          ),
                                          Container(
                                            height: 45,
                                            width: 1,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          _buildStatCard(
                                            'On Leave',
                                            leaveCount,
                                            Colors.orange.shade600,
                                            Icons.event_busy,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // List Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Staff Members (${displayList.length})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Staff List
                                Expanded(
                                  child: RefreshIndicator(
                                    color: Colors.indigo,
                                    onRefresh: () async {
                                      await ref
                                          .read(staffmodelProvider.notifier)
                                          .fetchStaffAttendance(
                                            ref
                                                .read(securitymodelProvider)
                                                .SocietyId
                                                .toString(),
                                          );
                                    },
                                    child: displayList.isEmpty
                                        ? _buildNoRecordsState()
                                        : ListView.builder(
                                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            itemCount: displayList.length,
                                            itemBuilder: (context, index) {
                                              final attendance = displayList[index];
                                              final statusCode =
                                                  _getStatusCode(attendance.status.toString());

                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                margin: const EdgeInsets.only(bottom: 8),
                                                child: Card(
                                                  elevation: 2,
                                                  shadowColor: Colors.black.withOpacity(0.1),
                                                  color: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    side: BorderSide(
                                                      color: Colors.grey.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Staff Name and Current Status
                                                        Row(
                                                          children: [
                                                            CircleAvatar(
                                                              backgroundColor:
                                                                  _getStatusColor(statusCode)
                                                                      .withOpacity(0.15),
                                                              radius: 20,
                                                              child: Icon(
                                                                Icons.person,
                                                                color: _getStatusColor(statusCode),
                                                                size: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    attendance.name??"",
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 15,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        _getStatusIcon(statusCode),
                                                                        size: 14,
                                                                        color: _getStatusColor(statusCode),
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        _getStatusText(statusCode),
                                                                        style: TextStyle(
                                                                          color: _getStatusColor(statusCode),
                                                                          fontSize: 13,
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 10),
                                                        const Divider(height: 1),
                                                        const SizedBox(height: 8),
                                                        
                                                        // Status Selection
                                                        Text(
                                                          'Mark Attendance',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [1, 2, 3].map((status) {
                                                            final isSelected = statusCode == status;
                                                            return Expanded(
                                                              child: Padding(
                                                                padding: EdgeInsets.only(
                                                                  right: status < 3 ? 8 : 0,
                                                                ),
                                                                child: InkWell(
                                                                  onTap: () {
                                                                    if (!isSelected) {
                                                                      _updateAttendance(
                                                                        attendance.staffId,
                                                                        status,
                                                                        statusCode,
                                                                      );
                                                                    }
                                                                  },
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  child: AnimatedContainer(
                                                                    duration: const Duration(milliseconds: 200),
                                                                    padding: const EdgeInsets.symmetric(
                                                                      vertical: 8,
                                                                      horizontal: 6,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: isSelected
                                                                          ? _getStatusColor(status)
                                                                          : Colors.grey[100],
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(
                                                                        color: isSelected
                                                                            ? _getStatusColor(status)
                                                                            : Colors.grey.shade300,
                                                                        width: isSelected ? 2 : 1,
                                                                      ),
                                                                    ),
                                                                    child: Column(
                                                                      children: [
                                                                        Icon(
                                                                          _getStatusIcon(status),
                                                                          size: 18,
                                                                          color: isSelected
                                                                              ? Colors.white
                                                                              : Colors.grey[600],
                                                                        ),
                                                                        const SizedBox(height: 3),
                                                                        Text(
                                                                          _getStatusText(status),
                                                                          style: TextStyle(
                                                                            fontSize: 11,
                                                                            fontWeight: isSelected
                                                                                ? FontWeight.bold
                                                                                : FontWeight.w500,
                                                                            color: isSelected
                                                                                ? Colors.white
                                                                                : Colors.grey[700],
                                                                          ),
                                                                          textAlign: TextAlign.center,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorState(getErrorMessage(error)),
                        ),
            ),
          ),
          
          // Overlay for disabled state
          if (!isCheckedIn)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please check in to manage staff attendance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E3B62),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Check in Required',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(staffmodelProvider.notifier).fetchStaffAttendance(
                      ref.read(securitymodelProvider).SocietyId.toString(),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staff Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no staff members to display',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecordsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance records found for today',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}