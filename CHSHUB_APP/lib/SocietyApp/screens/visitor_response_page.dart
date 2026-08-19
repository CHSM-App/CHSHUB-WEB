import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';

class VisitorPermissionDialog extends ConsumerStatefulWidget {
  final String visitorName;
  final String entryType;
  final String unit;
  final String service;
  final String imageUrl;
  final int countdownSeconds;
  final int visitorId;
  final String staffToken;
  final Function(bool approved)? onResponse;

  const VisitorPermissionDialog({
    super.key,
    required this.visitorName,
    required this.entryType,
    required this.unit,
    required this.service,
    required this.imageUrl,
    this.countdownSeconds = 35,
    this.onResponse,

    required this.visitorId,
    required this.staffToken,
  });

  @override
  ConsumerState<VisitorPermissionDialog> createState() =>
      _VisitorPermissionDialogState();
}

class _VisitorPermissionDialogState
    extends ConsumerState<VisitorPermissionDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _autoDeny();
      }
    });
  }

  void _autoDeny() {
    widget.onResponse?.call(false);
    _visitorStatusupdate(5);
  }

  void _approveVisitor() {
    _timer?.cancel();
    _visitorStatusupdate(1);
  }

  void _denyVisitor() {
    _timer?.cancel();
    widget.onResponse?.call(false);
    _visitorStatusupdate(4);
  }

  Future<void> _visitorStatusupdate(int status) async {
    // widget.onResponse?.call(status == 1);
    _timer?.cancel();
    final visitor = Visitor(
      ownerId: ref.read(basicInfoViewModelProvider).ownerId ?? 0,
      visitorId: widget.visitorId,
      status: status == 5 ? 3 : status,
      societyId: ref.read(basicInfoViewModelProvider).societyID ?? '',
    );

    ref.read(visitorViewModelProvider.notifier).visitorAction(visitor);

    final message =
        "${widget.entryType} for ${widget.visitorName} has been Approved..";
    final notification = SendNotification(
      title: "Visitor Approved",
      body: message,
      tokens: widget.staffToken.isNotEmpty ? [widget.staffToken] : [],
      visitorName: widget.visitorName,
      unit: widget.unit ?? '',
      entryType: widget.entryType,
      status: status.toString(),
      visitorId: widget.visitorId,

      // image: _selectedImagePath,
    );

    debugPrint("Visitor Id to update: ${widget.visitorId}");

    debugPrint("📨 Sending message payload:\n${notification.toJson()}");

    try {
      await ref
          .read(alertViewModelProvider.notifier)
          .sendDataMessage(notification);

      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint("❌ Error sending notification: $e");
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Allow Visitor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B7C99),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Personal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.visitorName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.entryType,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.unit,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_laundry_service,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.service,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Live countdown text
            Text(
              'Take action in next $_remainingSeconds sec',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),

            const SizedBox(height: 24),

            // Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _approveVisitor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'APPROVE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _denyVisitor,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(
                        color: Color(0xFFE53935),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'DENY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
