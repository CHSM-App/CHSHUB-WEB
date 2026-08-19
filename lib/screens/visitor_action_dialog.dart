import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/presentation/providers/viewModel_provider.dart';

enum OwnerResponseStatus {
  approved,
  rejected,
  notResponded,
}

class SecurityGuardVisitorDialog extends ConsumerStatefulWidget {
  final String visitorName;
  final String entryType;
  final String unit;
  final String service;
  final String imageUrl;
  final String ownerName;
  final OwnerResponseStatus ownerResponse;
  final int visitorId;
  final Function(String action)? onAction; // 'request_again', 'approve_by_guard', 'acknowledged', 'cancel'

  const SecurityGuardVisitorDialog({
    super.key,
    required this.visitorName,
    required this.entryType,
    required this.unit,
    required this.service,
    required this.imageUrl,
    required this.ownerName,
    required this.ownerResponse,
    required this.visitorId,
    this.onAction,
  });

  @override
  ConsumerState<SecurityGuardVisitorDialog> createState() =>
      _SecurityGuardVisitorDialogState();
}

class _SecurityGuardVisitorDialogState
    extends ConsumerState<SecurityGuardVisitorDialog> {
  
  void _handleRequestAgain() {
    widget.onAction?.call('request_again');
    // TODO: Add your request again logic here
    // This should send another notification/request to the owner
    Navigator.of(context).pop();
  }

  void _handleApproveByGuard() {
    widget.onAction?.call('approve_by_guard');
    debugPrint('Approving visitor by guard for visitor ID: ${widget.visitorId}');
    ref.read(visitormodelProvider.notifier).updateInsideStatus(widget.visitorId);
    Navigator.of(context).pop();
  }

  void _handleAcknowledge() {
    widget.onAction?.call('acknowledged');
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    widget.onAction?.call('cancel');
    // TODO: Add your cancel/reject logic here
    // This should cancel/reject the visitor entry
    Navigator.of(context).pop();
  }

  String _getStatusMessage() {
    switch (widget.ownerResponse) {
      case OwnerResponseStatus.approved:
        return '${widget.ownerName} approved the entry';
      case OwnerResponseStatus.rejected:
        return '${widget.ownerName} rejected the entry';
      case OwnerResponseStatus.notResponded:
        return '${widget.ownerName} did not respond';
    }
  }

  Color _getStatusColor() {
    switch (widget.ownerResponse) {
      case OwnerResponseStatus.approved:
        return const Color(0xFF00BFA5);
      case OwnerResponseStatus.rejected:
        return const Color(0xFFE53935);
      case OwnerResponseStatus.notResponded:
        return const Color(0xFFFFA726);
    }
  }

  IconData _getStatusIcon() {
    switch (widget.ownerResponse) {
      case OwnerResponseStatus.approved:
        return Icons.check_circle;
      case OwnerResponseStatus.rejected:
        return Icons.cancel;
      case OwnerResponseStatus.notResponded:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Visitor Status',
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apartment,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Owner Response Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusMessage(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons based on owner response
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (widget.ownerResponse) {
      case OwnerResponseStatus.approved:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );

      case OwnerResponseStatus.rejected:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );

      case OwnerResponseStatus.notResponded:
        return Column(
          children: [
            // SizedBox(
            //   width: double.infinity,
            //   height: 56,
            //   child: ElevatedButton(
            //     onPressed: _handleRequestAgain,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFF5B7C99),
            //       foregroundColor: Colors.white,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(16),
            //       ),
            //       elevation: 0,
            //     ),
            //     child: const Text(
            //       'REQUEST AGAIN',
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //         letterSpacing: 0.5,
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleApproveByGuard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'APPROVE BY YOURSELF',
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
                onPressed: _handleCancel,
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
                  'CANCEL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}