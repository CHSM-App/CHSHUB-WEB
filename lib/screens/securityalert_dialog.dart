import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';
import 'package:flutter/services.dart'; // For haptic feedback
class TimeHelper {
  /// Convert TimeOfDay → "HH:mm:ss" (SQL Server TIME format)
  static String? timeOfDayToString(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// Convert "HH:mm:ss" or "HH:mm" → TimeOfDay
  static TimeOfDay? stringToTimeOfDay(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class SecurityAlertDialog extends StatefulWidget {
  const SecurityAlertDialog({super.key});

  @override
  _SecurityAlertDialogState createState() => _SecurityAlertDialogState();
}

class _SecurityAlertDialogState extends State<SecurityAlertDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final titleSize = isSmallScreen ? 18.0 : 20.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 20 : 40,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.85,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[600],
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Security Alert',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Send emergency alerts to residents',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Alerts',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Water Supply',
                                icon: Icons.water_drop,
                                color: Colors.blue[50]!,
                                iconColor: Colors.blue[700]!,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertTargetDialog(
                                      alertType: "Water",
                                      alertTitle: 'Water Supply Alert',
                                      message:
                                          'URGENT: Water supply will Start soon!',
                                      level: AlertLevel.medium,
                                      showTimeFields: true,
                                    ),
                                  );
                                },
                                isSmall: isSmallScreen,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Gas Outage',
                                icon: Icons.gas_meter,
                                color: Colors.red[50]!,
                                iconColor: Colors.red[600]!,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertTargetDialog(
                                      alertType: "Gas",
                                      alertTitle: 'Gas Outage',
                                      message:
                                          'Gas Outage detected in the building. Please evacuate immediately!',
                                      level: AlertLevel.critical,
                                      showTimeFields: true,
                                    ),
                                  );
                                },
                                isSmall: isSmallScreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Fire Alert',
                                icon: Icons.local_fire_department,
                                color: Colors.red[50]!,
                                iconColor: Colors.red[600]!,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertTargetDialog(
                                      alertType: "Fire",
                                      alertTitle: 'Fire Alert',
                                      message:
                                          'URGENT: Fire detected in the building. Please evacuate immediately!',
                                      level: AlertLevel.critical,
                                      showTimeFields: false,
                                    ),
                                  );
                                },
                                isSmall: isSmallScreen,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildAlertCard(
                                title: 'Power Outage',
                                icon: Icons.power_off,
                                color: Colors.grey[200]!,
                                iconColor: Colors.grey[700]!,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertTargetDialog(
                                      alertType: "Power",
                                      alertTitle: 'Power Outage',
                                      message:
                                          'Temporary power outage. Backup power will be restored shortly.',
                                      level: AlertLevel.medium,
                                      showTimeFields: true,
                                    ),
                                  );
                                },
                                isSmall: isSmallScreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Custom Message',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildCustomMessageCard(isSmallScreen),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isSmall,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: isSmall ? 28 : 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMessageCard(bool isSmall) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => CustomMessageDialog(),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isSmall ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.edit_note,
                color: Colors.green[700],
                size: isSmall ? 24 : 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Custom Message',
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Write your own alert message',
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class AlertTargetDialog extends ConsumerStatefulWidget {
  final String alertType;
  final String alertTitle;
  final String message;
  final AlertLevel level;
  final bool showTimeFields;

  const AlertTargetDialog({
    super.key,
    required this.alertType,
    required this.alertTitle,
    required this.message,
    required this.level,
    this.showTimeFields = false,
  });

  @override
  ConsumerState<AlertTargetDialog> createState() => _AlertTargetDialogState();
}

class _AlertTargetDialogState extends ConsumerState<AlertTargetDialog> {
  List<LoginData> buildings = [];
  String? alertScope;
  Set<int> selectedBuildingIds = {};
  bool _isInitialLoading = true;

  // Duration variables
  int selectedHours = 0;
  int selectedMinutes = 0;
  int selectedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() => _isInitialLoading = true);

    try {
      final societyId = ref.read(securitymodelProvider).SocietyId ?? "";
      await ref
          .read(emergencymodelProvider.notifier)
          .fetchBuildingList(societyId);

      final emergencyState = ref.read(emergencymodelProvider);
      if (mounted) {
        setState(() {
          buildings = emergencyState.buildingList ?? [];
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load building data: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }
          
Widget _buildInlineDurationPicker(Color color) {
  return Container(
    height: 100,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hours Picker
        Expanded(
          child: Column(
            children: [
              Text(
                'Hours',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: selectedHours,
                  ),
                  itemExtent: 45,
                  diameterRatio: 1.5,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick(); // ✅ Haptic feedback
                    setState(() => selectedHours = index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 99) return null;
                      final isSelected = index == selectedHours;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    childCount: 100,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Separator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        
        // Minutes Picker
        Expanded(
          child: Column(
            children: [
              Text(
                'Minutes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: selectedMinutes,
                  ),
                  itemExtent: 45,
                  diameterRatio: 1.5,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick(); // ✅ Haptic feedback
                    setState(() => selectedMinutes = index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 59) return null;
                      final isSelected = index == selectedMinutes;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    childCount: 60,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Separator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        
        // Seconds Picker
        Expanded(
          child: Column(
            children: [
              Text(
                'Seconds',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: selectedSeconds,
                  ),
                  itemExtent: 45,
                  diameterRatio: 1.5,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick(); // ✅ Haptic feedback
                    setState(() => selectedSeconds = index);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index > 59) return null;
                      final isSelected = index == selectedSeconds;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 20,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    childCount: 60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Don't forget to add this import at the top of your file:
// import 'package:flutter/services.dart';

// And replace the old duration selection section in _buildDirectSendDialog with:

  String _formatDuration() {
    if (selectedHours == 0 && selectedMinutes == 0 && selectedSeconds == 0) {
      return 'Select Duration';
    }
    return '${selectedHours.toString().padLeft(2, '0')}:${selectedMinutes.toString().padLeft(2, '0')}:${selectedSeconds.toString().padLeft(2, '0')}';
  }

  String _getMessageWithDuration() {
    if (!widget.showTimeFields ||
        (selectedHours == 0 && selectedMinutes == 0 && selectedSeconds == 0)) {
      return widget.message;
    }

    String duration = '';
    if (selectedHours > 0) {
      duration += '${selectedHours} hour${selectedHours > 1 ? 's' : ''}';
    }
    if (selectedMinutes > 0) {
      if (duration.isNotEmpty) duration += ' ';
      duration += '${selectedMinutes} minute${selectedMinutes > 1 ? 's' : ''}';
    }
    if (selectedSeconds > 0) {
      if (duration.isNotEmpty) duration += ' ';
      duration += '${selectedSeconds} second${selectedSeconds > 1 ? 's' : ''}';
    }

    // Add duration to message based on alert type
    if (widget.alertType == "Water") {
      return 'Water supply will Start soon! Water will be available starting $duration.';
    } else if (widget.alertType == "Gas") {
      return 'URGENT: Gas Outage detected in the building. Please evacuate immediately!\n\nGas outage expected for approximately $duration.';
    } else if (widget.alertType == "Power") {
      return 'URGENT: Temporary power outage. Backup power will be restored shortly.\n\nPower outage expected for approximately $duration.';
    } else {
      return '${widget.message}\n\nOutage Duration: $duration';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Dialog(
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    return _buildDirectSendDialog();
  }

  Widget _buildDirectSendDialog() {
    final color = _getAlertColor(widget.level);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: screenSize.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAlertIcon(widget.level),
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.alertTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Send emergency alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        _getMessageWithDuration(),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    if (widget.showTimeFields) ...[
                      SizedBox(height: 16),
                      Text(
                        'Outage Duration',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      // InkWell(
                      //   onTap: () => _showDurationPicker(context),
                      //   child: Container(
                      //     padding: EdgeInsets.all(16),
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey[100],
                      //       borderRadius: BorderRadius.circular(10),
                      //       border: Border.all(color: Colors.grey[300]!),
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Text(
                      //               'Duration',
                      //               style: TextStyle(
                      //                 fontSize: 11,
                      //                 color: Colors.grey[600],
                      //               ),
                      //             ),
                      //             SizedBox(height: 4),
                      //             Row(
                      //               children: [
                      //                 Icon(Icons.timer, size: 16, color: color),
                      //                 SizedBox(width: 6),
                      //                 Text(
                      //                   _formatDuration(),
                      //                   style: TextStyle(
                      //                     fontSize: 14,
                      //                     fontWeight: FontWeight.w600,
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ],
                      //         ),
                      //         Icon(
                      //           Icons.arrow_forward_ios,
                      //           size: 16,
                      //           color: Colors.grey[400],
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      _buildInlineDurationPicker(color)
                    ],

                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 16),

                    Text(
                      'Send Alert To',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),

                    _buildScopeOption(
                      title: 'Entire Society',
                      subtitle: 'Alert all residents',
                      icon: Icons.apartment,
                      color: Colors.blue,
                      isSelected: alertScope == 'society',
                      onTap: () {
                        setState(() {
                          alertScope = 'society';
                          selectedBuildingIds.clear();
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    _buildScopeOption(
                      title: 'Specific Buildings',
                      subtitle: 'Select buildings',
                      icon: Icons.business,
                      color: Colors.orange,
                      isSelected: alertScope == 'building',
                      onTap: () {
                        setState(() {
                          alertScope = 'building';
                        });
                      },
                    ),

                    if (alertScope == 'building' && buildings.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Select Buildings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: buildings.map((building) {
                          final isSelected = selectedBuildingIds.contains(
                            building.buildId,
                          );
                          return FilterChip(
                            label: Text(building.buildName ?? ""),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedBuildingIds.add(
                                    building.buildId ?? 0,
                                  );
                                } else {
                                  selectedBuildingIds.remove(building.buildId);
                                }
                              });
                            },
                            selectedColor: Colors.orange[600],
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed:
                          (alertScope == null ||
                              (alertScope == 'building' &&
                                  selectedBuildingIds.isEmpty) ||
                              (widget.showTimeFields &&
                                  (selectedHours == 0 &&
                                      selectedMinutes == 0 &&
                                      selectedSeconds == 0)))
                          ? null
                          : _sendAlert,
                      icon: Icon(Icons.send),
                      label: Text(
                        alertScope == 'society'
                            ? 'Send to All'
                            : selectedBuildingIds.isEmpty
                            ? 'Select Buildings'
                            : 'Send to ${selectedBuildingIds.length} Building(s)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  void _sendAlert() {
    Navigator.of(context).pop();

    Set<String> buildingNames = {};
    if (alertScope == 'building') {
      buildingNames = selectedBuildingIds
          .map(
            (id) =>
                buildings.firstWhere((b) => b.buildId == id).buildName ?? "",
          )
          .toSet();
    }

    showDialog(
      context: context,
      builder: (context) => AlertConfirmationDialog(
        alertType: widget.alertType,
        alertTitle: widget.alertTitle,
        message: _getMessageWithDuration(), // Send message WITH duration
        level: widget.level,
        alertScope: alertScope!,
        selectedBuildings: buildingNames,
        durationHours: selectedHours,
        durationMinutes: selectedMinutes,
        durationSeconds: selectedSeconds,
      ),
    );
  }

  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Icons.warning;
      case AlertLevel.high:
        return Icons.priority_high;
      case AlertLevel.medium:
        return Icons.info;
    }
  }

  Color _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Colors.red[600]!;
      case AlertLevel.high:
        return Colors.orange[600]!;
      case AlertLevel.medium:
        return Colors.blue[600]!;
    }
  }
}

enum AlertLevel { critical, high, medium }
class AlertConfirmationDialog extends ConsumerStatefulWidget {
  final String alertType;
  final String alertTitle;
  final String message;
  final AlertLevel level;
  final String alertScope;
  final Set<String> selectedBuildings;
  final int durationHours;
  final int durationMinutes;
  final int durationSeconds;

  const AlertConfirmationDialog({
    super.key,
    required this.alertType,
    required this.alertTitle,
    required this.message,
    required this.level,
    required this.alertScope,
    required this.selectedBuildings,
    this.durationHours = 0,
    this.durationMinutes = 0,
    this.durationSeconds = 0,
  });

  @override
  ConsumerState<AlertConfirmationDialog> createState() => _AlertConfirmationDialogState();
}

class _AlertConfirmationDialogState extends ConsumerState<AlertConfirmationDialog> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final color = _getAlertColor(widget.level);
    String targetText = widget.alertScope == 'society'
        ? 'all residents'
        : 'Building(s) ${widget.selectedBuildings.join(", ")}';

    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getAlertIcon(widget.level), color: color, size: 48),
            SizedBox(height: 16),
            Text(
              'Confirm ${widget.alertTitle}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(widget.message, textAlign: TextAlign.center),
            SizedBox(height: 12),
            Text(
              'Sending to: $targetText',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendAlert,
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                    child: _isSending
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Send', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAlert() async {
    if (_isSending) return; // Guard clause
    
    setState(() => _isSending = true);
    
    try {
      final societyId = ref.read(securitymodelProvider).SocietyId!;
      final staffId = ref.read(securitymodelProvider).userId!;

      final List<int> buildingIds = widget.alertScope == 'society'
          ? []
          : ref
              .read(emergencymodelProvider)
              .buildingList!
              .where((b) => widget.selectedBuildings.contains(b.buildName))
              .map((b) => b.buildId!)
              .toList();

      final body = AlertNotification(
        society_id: societyId,
        buildings: buildingIds,
        staff_id: 1,
        notification_type: widget.alertType,
        title: widget.alertTitle,
        body: widget.message, // Message WITH duration text
      );

      // Print to check what's being sent
      debugPrint('📤 Sending Alert:');
      debugPrint('Type: ${widget.alertType}');
      debugPrint('Title: ${widget.alertTitle}');
      debugPrint('Message: ${widget.message}');
      debugPrint(
        'Duration: ${widget.durationHours}h ${widget.durationMinutes}m ${widget.durationSeconds}s',
      );

      await ref
          .read(securitymodelProvider.notifier)
          .sendAlertNotifications(body);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert sent successfully'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error sending alert: $e');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Icons.warning;
      case AlertLevel.high:
        return Icons.priority_high;
      case AlertLevel.medium:
        return Icons.info;
    }
  }

  Color _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Colors.red[600]!;
      case AlertLevel.high:
        return Colors.orange[600]!;
      case AlertLevel.medium:
        return Colors.blue[600]!;
    }
  }
}
class CustomMessageDialog extends ConsumerStatefulWidget {
  const CustomMessageDialog({super.key});

  @override
  ConsumerState<CustomMessageDialog> createState() =>
      _CustomMessageDialogState();
}

class _CustomMessageDialogState extends ConsumerState<CustomMessageDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<LoginData> buildings = []; // Buildings from API
  String? alertScope;
  Set<int> selectedBuildingIds = {};
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    }); // ✅ Fetch buildings + preferences
  }

  /// Fetch building list and load saved preference
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() => _isInitialLoading = true);

    try {
      final societyId = ref.read(securitymodelProvider).SocietyId ?? "";

      // Fetch building list from API
      await ref
          .read(emergencymodelProvider.notifier)
          .fetchBuildingList(societyId);

      final emergencyState = ref.read(emergencymodelProvider);
      if (mounted) {
        setState(() {
          buildings = emergencyState.buildingList ?? [];
        });
      }

      // Load saved preference
      await _loadSavedPreference();
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load building data: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  /// Load saved alert preference
  Future<void> _loadSavedPreference() async {
    if (!mounted) return;

    try {
      final societyId = ref.read(securitymodelProvider).SocietyId ?? "";

      final preference = await ref
          .read(emergencymodelProvider.notifier)
          .fetchEmergencyAlertPreference(societyId, "Custom");

      if (preference != null && mounted) {
        setState(() {
          alertScope = preference.alertScope;

          if (preference.alertScope == 'building' &&
              preference.selectedBuildings != null &&
              preference.selectedBuildings!.isNotEmpty) {
            selectedBuildingIds = preference.selectedBuildings!.toSet();
          } else {
            selectedBuildingIds = {};
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading preference: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendCustomMessage() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and message')),
      );
      return;
    }

    if (alertScope == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select target for the alert')),
      );
      return;
    }

    if (alertScope == 'building' && selectedBuildingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one building')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final societyId = ref.read(securitymodelProvider).SocietyId ?? "C10001";
      final createdBy = ref.read(securitymodelProvider).userId ?? 1;

      final alert = EmergencyAlert(
        societyId: societyId,
        alertType: "Custom",
        alertScope: alertScope!,
        selectedBuildings: selectedBuildingIds.toList(),
        alertTitle: title,
        alertMessage: message,
        createdBy: 1,
      );

      final success = await ref
          .read(emergencymodelProvider.notifier)
          .addCustomMessage(alert);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Custom message sent successfully!'
                : 'Failed to send message',
          ),
          backgroundColor: success ? Colors.green[600] : Colors.red[600],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = screenSize.height < 700;
  bool _isSending = false;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 450,
            maxHeight: screenSize.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.green[600], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Custom Alert Message',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 17 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Alert Title',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Important Announcement',
                          hintStyle: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      Text(
                        'Message',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type your message here...',
                          hintStyle: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Target Selection
                      Text(
                        'Send To',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTargetChip(
                              'All Buildings',
                              Icons.apartment,
                              alertScope == 'society',
                              () => setState(() {
                                alertScope = 'society';
                                selectedBuildingIds.clear();
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTargetChip(
                              'Specific Buildings',
                              Icons.business,
                              alertScope == 'building',
                              () async {
                                setState(() => alertScope = 'building');
                                if (buildings.isEmpty) {
                                  await _loadInitialData(); // Fetch buildings
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Building Chips
                      if (alertScope == 'building' && buildings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: buildings.map((building) {
                            final isSelected = selectedBuildingIds.contains(
                              building.buildId,
                            );
                            return FilterChip(
                              label: Text(building.buildName ?? ""),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedBuildingIds.add(
                                      building.buildId ?? 0,
                                    );
                                  } else {
                                    selectedBuildingIds.remove(
                                      building.buildId ?? 0,
                                    );
                                  }
                                });
                              },
                              selectedColor: Colors.green[600],
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                           onPressed: _isLoading ? null : _sendCustomAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: isSmallScreen ? 16 : 18,
                                width: isSmallScreen ? 16 : 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Send Alert',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                ),
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
    );
  }

  Future<void> _sendCustomAlert() async {
  // Validation
  final title = _titleController.text.trim();
  final message = _messageController.text.trim();

  if (title.isEmpty || message.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both title and message')),
    );
    return;
  }

  if (alertScope == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select target for the alert')),
    );
    return;
  }

  if (alertScope == 'building' && selectedBuildingIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one building')),
    );
    return;
  }

  // Guard clause
  if (_isLoading) return;

  setState(() => _isLoading = true);

  try {
    final securityVM = ref.read(securitymodelProvider);
    final emergencyVM = ref.read(emergencymodelProvider);

    final societyId = securityVM.SocietyId!;
    final staffId = securityVM.userId!;

    final List<int> buildingIds = alertScope == 'society'
        ? []
        : emergencyVM.buildingList!
            .where((b) => selectedBuildingIds.contains(b.buildId))
            .map((b) => b.buildId!)
            .toList();

    final body = AlertNotification(
      society_id: societyId,
      buildings: buildingIds,
      staff_id: 1,
      notification_type: "Custom",
      title: title,
      body: message,
    );

    await ref.read(securitymodelProvider.notifier).sendAlertNotifications(body);

    if (!mounted) return;

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Alert sent successfully'),
        backgroundColor: Colors.green[600]!,
      ),
    );
  } catch (e) {
    debugPrint('❌ Error sending custom alert: $e');
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send alert: $e'),
        backgroundColor: Colors.red[600],
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Widget _buildTargetChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.green[700] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.green[900] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Alert Card
class AnimatedAlertCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isSmall;

  const AnimatedAlertCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    required this.isSmall,
  });

  @override
  _AnimatedAlertCardState createState() => _AnimatedAlertCardState();
}

class _AnimatedAlertCardState extends State<AnimatedAlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(widget.isSmall ? 12 : 16),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: widget.isSmall ? 24 : 28,
                    color: widget.iconColor,
                  ),
                  SizedBox(height: widget.isSmall ? 6 : 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.isSmall ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
