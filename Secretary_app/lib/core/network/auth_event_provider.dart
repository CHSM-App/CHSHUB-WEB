import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot signals raised by the network layer for the UI to act on.
enum AuthEvent { sessionExpired }

/// Set by TokenInterceptor when a refresh fails; the root widget listens and
/// navigates to login, then resets this to null.
final authEventProvider = StateProvider<AuthEvent?>((ref) => null);
