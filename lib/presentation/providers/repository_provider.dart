import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import '../../data/repositories/accounts_impl.dart';
import '../../data/repositories/auth_impl.dart';
import '../../data/repositories/billing_impl.dart';
import '../../data/repositories/community_impl.dart';
import '../../data/repositories/dashboard_impl.dart';
import '../../domain/repository/accounts_repo.dart';
import '../../domain/repository/auth_repo.dart';
import '../../domain/repository/billing_repo.dart';
import '../../domain/repository/community_repo.dart';
import '../../domain/repository/dashboard_repo.dart';

/// Layer 1 of 3: ApiService -> repository implementation.
///
/// Every provider here reuses `apiServiceProvider` rather than building its own
/// `ApiService(dio)`; a second instance would mean a second Dio, and so a
/// second set of interceptors and a refresh that no longer collapses.

/// The signed-in user's auth surface.
///
/// Distinct from `authRepoProvider` in dio_provider.dart: that one is built on
/// an interceptor-free Dio for the interceptor's own refresh call. This one
/// goes through the full stack, which is what the login screen wants.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthImpl(ref.watch(apiServiceProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardImpl(ref.watch(apiServiceProvider)),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingImpl(ref.watch(apiServiceProvider)),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsImpl(ref.watch(apiServiceProvider)),
);

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityImpl(ref.watch(apiServiceProvider)),
);
