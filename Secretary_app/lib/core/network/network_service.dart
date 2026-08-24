import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// "Has a network interface" and "can actually reach the internet" are
/// different questions — captive portals answer the first and not the second.
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged async* {
    yield await checkConnection(); // emit immediately on cold start
    yield await checkRealInternet(); // then a real reachability check
    await for (final result in _connectivity.onConnectivityChanged) {
      yield !result.contains(ConnectivityResult.none);
    }
  }

  Future<bool> checkConnection() async =>
      !(await _connectivity.checkConnectivity()).contains(
        ConnectivityResult.none,
      );

  Future<bool> checkRealInternet() async {
    try {
      final r = await InternetAddress.lookup('google.com');
      return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
