import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/network/error_message_mapper.dart';

class ErrorStatePage extends ConsumerStatefulWidget {
  final String? errorTitle;
  final String? errorMessage;
  final Object? error;
  final VoidCallback onRetry;

  const ErrorStatePage({
    super.key,
    this.errorTitle,
    this.errorMessage,
    this.error,
    required this.onRetry,
    String? message,
  });

  @override
  ConsumerState<ErrorStatePage> createState() => _ErrorStatePageState();
}

class _ErrorStatePageState extends ConsumerState<ErrorStatePage>
    with SingleTickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildErrorState(String title, String errorMessage, bool isConnectivityIssue) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isConnectivityIssue ? Colors.orange.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnectivityIssue ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 64,
              color: isConnectivityIssue ? Colors.orange.shade400 : Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          _isRetrying
              ? Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isRetrying = true;
                    });
                    
                   widget.onRetry();
                    
                    // Wait a bit to ensure the loading state is visible
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    if (mounted) {
                      setState(() {
                        _isRetrying = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
          if (!_isRetrying && Navigator.of(context).canPop()) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final isConnectivityIssue =
        error != null && ErrorMessageMapper.isConnectivityError(error);

    final title = widget.errorTitle ??
        (isConnectivityIssue ? 'No Internet Connection' : 'Oops! Something went wrong');

    final message = widget.errorMessage ??
        (error != null
            ? ErrorMessageMapper.map(error)
            : 'We encountered an issue while processing your request.\nPlease try again.');

    return Container(
      color: Colors.grey.shade50,
      child: _buildErrorState(title, message, isConnectivityIssue),
    );
  }
}

// Usage Example:
// 
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => ErrorStatePage(
//       errorTitle: 'Connection Failed',
//       errorMessage: 'Unable to connect to the server.\nPlease check your internet connection.',
//       onRetry: () {
//         // Your retry logic
//         print('Retrying...');
//         // Navigate or reload data
//       },
//     ),
//   ),
// );