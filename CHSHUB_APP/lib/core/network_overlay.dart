import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

enum _BannerType { none, offline, backOnline }

/// YouTube-style connectivity banner.
///
/// A flat, full-width strip that appears directly below the bottom nav bar
/// when the connection drops, and briefly shows "Back online" when it is
/// restored before auto-dismissing. Place this after the nav bar inside the
/// `bottomNavigationBar` slot's `Column` so it never covers the nav bar.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  _BannerType _banner = _BannerType.none;
  bool? _wasConnected;
  Timer? _autoHideTimer;

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _handleNetworkState(bool isInitialized, bool isConnected) {
    if (!isInitialized) return;

    if (_wasConnected == null) {
      // First reading after init: only announce if we start out offline.
      _wasConnected = isConnected;
      if (!isConnected) {
        _autoHideTimer?.cancel();
        _banner = _BannerType.offline;
      }
      return;
    }

    if (_wasConnected == true && !isConnected) {
      _autoHideTimer?.cancel();
      _banner = _BannerType.offline;
    } else if (_wasConnected == false && isConnected) {
      _banner = _BannerType.backOnline;
      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _banner = _BannerType.none);
      });
    }

    _wasConnected = isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkStateProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final previous = _banner;
      _handleNetworkState(networkState.isInitialized, networkState.isConnected);
      if (previous != _banner) setState(() {});
    });

    return _ConnectivityBannerView(type: _banner);
  }
}

class _ConnectivityBannerView extends StatelessWidget {
  final _BannerType type;

  const _ConnectivityBannerView({required this.type});

  @override
  Widget build(BuildContext context) {
    final visible = type != _BannerType.none;
    final isOffline = type == _BannerType.offline;

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: !visible
            ? const SizedBox(width: double.infinity, height: 0)
            : Container(
                width: double.infinity,
                color: isOffline ? const Color(0xFF212121) : const Color(0xFF2E7D32),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOffline ? 'No internet connection' : 'Back online',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
