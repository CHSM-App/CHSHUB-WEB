import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:society_app/SocietyApp/navigation_home_screen.dart';
import 'package:society_app/SocietyApp/screens/demo.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/domain/models/facilities.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class Facilityslot extends ConsumerStatefulWidget {
  final int facilityId;
  final int slot;
  final int cost;
  final String name;
  final String? description;
  final IconData? icon;
  final Color? color;

  const Facilityslot({
    super.key,
    required this.facilityId,
    required this.slot,
    required this.cost,
    required this.name,
    this.description,
    this.icon,
    this.color, 
    required String bookingTypeText,
  });

  @override
  ConsumerState<Facilityslot> createState() => _FacilityslotState();
}

class _FacilityslotState extends ConsumerState<Facilityslot> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
 late Razorpay _razorpay;
  DateTime selectedDate = DateTime.now().add(Duration(days: 2));
  String? fromDate;
  String? toDate;
  String fromTime = "";
  String toTime = "";
  int selectedSlotId = 0;
  double amount = 0;

  // UI Colors
  Color get facilityColor => widget.color ?? Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadData();
   
  
  }
   void _loadData() {
     Future.microtask(() {
      if (widget.slot == 3) {
        ref
            .read(facilitiesViewModelProvider.notifier)
            .loadAvailableSlots(
              widget.facilityId,
              DateFormat('yyyy-MM-dd').format(selectedDate),
            );
      }
    });
  }
Future<void> pickDate(
  Function(String) onSelected, {
  bool isFromDate = true,
}) async {
  DateTime initialDate = DateTime.now().add(const Duration(days: 2));
  DateTime firstDate = DateTime.now().add(const Duration(days: 2));
  DateTime lastDate = DateTime(2100);

  // For slot 1, To Date must be after From Date
  if (widget.slot == 1 && !isFromDate && fromDate != null) {
    try {
      final parsedFromDate = DateFormat('yyyy-MM-dd').parse(fromDate!);
      firstDate = parsedFromDate.add(const Duration(days: 1));
      initialDate = firstDate;
    } catch (_) {}
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (picked == null) return;

  final formatted = DateFormat('yyyy-MM-dd').format(picked);

  // Validation: To Date should be after From Date
  if (widget.slot == 1 && !isFromDate && fromDate != null) {
    final parsedFromDate = DateFormat('yyyy-MM-dd').parse(fromDate!);
    if (!picked.isAfter(parsedFromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("End date must be after start date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  onSelected(formatted);

  // Slot 3 specific logic
  if (widget.slot == 3 && isFromDate) {
    selectedDate = picked;
    ref
        .read(facilitiesViewModelProvider.notifier)
        .loadAvailableSlots(widget.facilityId, formatted);
  }

  calculateAmount();
}

Future<void> pickTime(Function(String) onSelected) async {
  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime == null) return;

  final formatted = pickedTime.format(context);
  onSelected(formatted);
  calculateAmount();
}

void calculateAmount() {
  amount = 0;

  // SLOT 1 : Date wise calculation
  if (widget.slot == 1 && fromDate != null && toDate != null) {
    try {
      final start = DateFormat('yyyy-MM-dd').parse(fromDate!);
      final end = DateFormat('yyyy-MM-dd').parse(toDate!);

      if (!end.isAfter(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("End date must be greater than start date"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {});
        return;
      }

      final days = end.difference(start).inDays + 1;
      amount = widget.cost * days.toDouble();
    } catch (_) {
      amount = widget.cost.toDouble();
    }
  }

  // SLOT 2 : Time wise calculation
  else if (widget.slot == 2 &&
      fromDate != null &&
      fromTime.isNotEmpty &&
      toTime.isNotEmpty) {
    try {
      final start =
          DateFormat('yyyy-MM-dd hh:mm a').parse('$fromDate $fromTime');
      final end =
          DateFormat('yyyy-MM-dd hh:mm a').parse('$fromDate $toTime');

      final totalMinutes = end.difference(start).inMinutes;

      if (totalMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("End time must be after start time"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {});
        return;
      }

      final totalHours = totalMinutes / 60;
      amount = widget.cost * totalHours;
    } catch (_) {
      amount = widget.cost.toDouble();
    }
  }

  // SLOT 3 : Fixed cost
  else if (widget.slot == 3) {
    amount = widget.cost.toDouble();
  }

  setState(() {});
}

  void _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // Manual validation
    if ((widget.slot == 1 && (fromDate == null || toDate == null)) ||
        (widget.slot == 2 &&
            (fromDate == null || fromTime.isEmpty || toTime.isEmpty)) ||
        (widget.slot == 3 && selectedSlotId == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
 
    final success= await PaymentService.startPayment(context, ref, amount);
   if (success["success"] == false) {
  debugPrint("❌ Payment Failed");
  return;
} else {
  // Show failure or do nothing
}
    final basicInfo = ref.watch(basicInfoViewModelProvider);

    final facilities = Facilities(
      facilityId: widget.facilityId,
      slotId: selectedSlotId,
      fromTime: fromTime,
      toTime: toTime,
      status: 0,
      amount: amount,
      flatId: basicInfo.flatId ?? 0,
      note: _noteController.text.trim(),
      fromDate: fromDate ?? DateFormat('yyyy-MM-dd').format(selectedDate),
      societyId: basicInfo.societyID ?? '',
      toDate: toDate ?? '',
      name: basicInfo.name ?? '',
      contact: basicInfo.mobile ?? '',
      transactionRef: success["rrn"]?.toString()
    );

    await ref
        .read(facilitiesViewModelProvider.notifier)
        .bookFacility(facilities);

    final facility = ref.watch(facilitiesViewModelProvider);

    if (facility.data != null && facility.data?["success"] == true) {  
      if (!context.mounted) return;
      _showSuccessDialog();
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking failed. Status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your ${widget.name} booking has been confirmed.'),
            SizedBox(height: 8),
            Text('Amount: ₹${amount.toStringAsFixed(2)}'),
            SizedBox(height: 8),
            Text(
              'Booking ID: #AMT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnimatedBottomNavScreen(initialIndex: 4,),
                ),
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Future<void> pickDate(
  //   Function(String) onSelected, {
  //   bool isFromDate = true,
  // }) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now().add(Duration(days: 2)),
  //     firstDate: DateTime.now().add(Duration(days: 2)),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null) {
  //     final formatted = DateFormat('yyyy-MM-dd').format(picked);
  //     onSelected(formatted);
  //     if (widget.slot == 3 && isFromDate) {
  //       selectedDate = picked;
  //       ref
  //           .read(facilitiesViewModelProvider.notifier)
  //           .loadAvailableSlots(widget.facilityId, formatted);
  //     }
  //     calculateAmount();
  //   }
  // }

  // Future<void> pickTime(Function(String) onSelected) async {
  //   final TimeOfDay? pickedTime = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //   );
  //   if (pickedTime != null) {
  //     final formatted = pickedTime.format(context);
  //     onSelected(formatted);
  //     calculateAmount();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.name,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAmenityHeader(),
              SizedBox(height: 24),
              _buildBookingContent(),
              SizedBox(height: 24),
              _buildNotesSection(),
              SizedBox(height: 24),
              _buildPricingSummary(),
              SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBookButton(),
    );
  }

  Widget _buildAmenityHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: facilityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              widget.icon ?? Icons.apartment,
              size: 40,
              color: facilityColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '${widget.name[0].toUpperCase()}${widget.name.substring(1)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.description ??
                "Maximum Capacity 50 people\nBook before at least 2 days",
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getBookingTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getBookingTypeText(),
              style: TextStyle(
                fontSize: 12,
                color: _getBookingTypeColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingContent() {
    switch (widget.slot) {
      case 1:
        return _buildHourlyBooking();
      case 2:
        return _buildDailyBooking();
      case 3:
        return _buildSlotBooking();
      default:
        return Container();
    }
  }

  Widget _buildHourlyBooking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: fromDate ?? 'From Date',
                icon: Icons.calendar_today,
                onTap: () => pickDate((val) => setState(() => fromDate = val)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: toDate ?? 'To Date',
                icon: Icons.calendar_today,
                onTap: () => pickDate(
                  (val) => setState(() => toDate = val),
                  isFromDate: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyBooking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select From Date and Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: fromDate ?? 'From Date',
                icon: Icons.calendar_today,
                onTap: () => pickDate((val) => setState(() => fromDate = val)),
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Select To Date and Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: fromTime.isNotEmpty ? fromTime : 'From Time',
                icon: Icons.access_time,
                onTap: () => pickTime((val) => setState(() => fromTime = val)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: toTime.isNotEmpty ? toTime : 'To Time',
                icon: Icons.access_time,
                onTap: () => pickTime((val) => setState(() => toTime = val)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotBooking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelection(),
        SizedBox(height: 24),
        _buildTimeSlotSelection(),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              DateTime date = DateTime.now().add(Duration(days: index + 2));
              bool isSelected =
                  selectedDate.day == date.day &&
                  selectedDate.month == date.month &&
                  selectedDate.year == date.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                    selectedSlotId = 0;
                    fromTime = '';
                    toTime = '';
                    amount = 0;
                  });
                  ref
                      .read(facilitiesViewModelProvider.notifier)
                      .loadAvailableSlots(
                        widget.facilityId,
                        DateFormat('yyyy-MM-dd').format(date),
                      );
                },
                child: Container(
                  width: 70,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? facilityColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? facilityColor : Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF000000).withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 20,
                          color: isSelected ? Colors.white : Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getMonthName(date.month),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    final slotsState = ref.watch(facilitiesViewModelProvider).availableSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        slotsState.when(
          data: (slots) {
            if (slots.isEmpty) {
              return Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No available slots for the selected date",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final int slotId = slot.slotId ?? 0;
                final String startTime = slot.startTime ?? '--';
                final String endTime = slot.endTime ?? '--';
                final int status = slot.status ?? 1;
                final bool isSelected = selectedSlotId == slotId;
                final bool isBooked = status != 0;
                final String timeSlot = '$startTime-$endTime';

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () {
                          setState(() {
                            selectedSlotId = slotId;
                            fromTime = startTime;
                            toTime = endTime;
                            calculateAmount();
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Color(0xFFFFEBEE)
                          : isSelected
                          ? facilityColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBooked
                            ? Color(0xFFEF4444)
                            : isSelected
                            ? facilityColor
                            : Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isBooked) ...[
                            Icon(
                              Icons.block,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(
                            timeSlot,
                            style: TextStyle(
                              fontSize: 14,
                              color: isBooked
                                  ? Color(0xFFEF4444)
                                  : isSelected
                                  ? Colors.white
                                  : Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: facilityColor)),
          error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF000000).withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter any additional notes or requirements...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF000000).withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: facilityColor, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16),
          _buildSummaryRow('Facility', widget.name),
          SizedBox(height: 8),
          if (widget.slot == 1) ...[
            _buildSummaryRow('From Date', fromDate ?? 'Not selected'),
            SizedBox(height: 8),
            _buildSummaryRow('To Date', toDate ?? 'Not selected'),
            SizedBox(height: 8),
            _buildSummaryRow(
              'Duration',
              fromDate != null && toDate != null
                  ? '${DateFormat('yyyy-MM-dd').parse(toDate!).difference(DateFormat('yyyy-MM-dd').parse(fromDate!)).inDays + 1} days'
                  : 'Not calculated',
            ),
          ] else if (widget.slot == 2) ...[
            _buildSummaryRow(
              'From',
              fromDate != null && fromTime.isNotEmpty
                  ? '$fromDate $fromTime'
                  : 'Not selected',
            ),
            SizedBox(height: 8),
            _buildSummaryRow(
              'To',
              fromDate != null && toTime.isNotEmpty
                  ? '$fromDate $toTime'
                  : 'Not selected',
            ),
            SizedBox(height: 8),
            _buildSummaryRow(
              'Duration',
              fromDate != null && fromTime.isNotEmpty && toTime.isNotEmpty
                  ? () {
                      final start = DateFormat(
                        'yyyy-MM-dd hh:mm a',
                      ).parse('$fromDate $fromTime');
                      final end = DateFormat(
                        'yyyy-MM-dd hh:mm a',
                      ).parse('$fromDate $toTime');
                      final diff = end.difference(start);

                      final hours = diff.inHours;
                      final minutes = diff.inMinutes % 60;

                      if (hours > 0 && minutes > 0) {
                        return '$hours hr $minutes min';
                      } else if (hours > 0) {
                        return '$hours hr';
                      } else {
                        return '$minutes min';
                      }
                    }()
                  : 'Not calculated',
            ),
          ] else if (widget.slot == 3) ...[
            _buildSummaryRow(
              'Date',
              DateFormat('dd MMM, yyyy').format(selectedDate),
            ),
            SizedBox(height: 8),
            _buildSummaryRow(
              'Time Slot',
              fromTime.isNotEmpty && toTime.isNotEmpty
                  ? '$fromTime - $toTime'
                  : 'Not selected',
            ),
          ],
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: facilityColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    bool canBook = _canProceedWithBooking();
    final state = ref.watch(facilitiesViewModelProvider);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canBook ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canBook ? facilityColor : Color(0xFFE2E8F0),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Proceed to Pay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canBook ? Colors.white : Color(0xFF94A3B8),
                  ),
                ),
        ),
      ),
    );
  }

  bool _canProceedWithBooking() {
    if (widget.slot == 1) {
      return fromDate != null && toDate != null;
    } else if (widget.slot == 2) {
      return fromDate != null && fromTime.isNotEmpty && toTime.isNotEmpty;
    } else if (widget.slot == 3) {
      return selectedSlotId != 0;
    }
    return false;
  }

  Color _getBookingTypeColor() {
    switch (widget.slot) {
      case 1:
        return Color(0xFF059669); // Green for hourly
      case 2:
        return Color(0xFFD97706); // Orange for daily
      case 3:
        return Color(0xFF7C3AED); // Purple for slots
      default:
        return facilityColor;
    }
  }

  String _getBookingTypeText() {
    switch (widget.slot) {
      case 1:
        return 'Daily Booking Available';
      case 2:
        return 'Hourly Booking Available';
      case 3:
        return 'Slot Booking Available';
      default:
        return 'Booking Available';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
  
  

}
