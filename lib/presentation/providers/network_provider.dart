import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_service.dart';

final networkServiceProvider = Provider((ref) => NetworkService());

final networkStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(networkServiceProvider).onConnectivityChanged,
);

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);
