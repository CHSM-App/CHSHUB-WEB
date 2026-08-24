import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewModels/accounts_viewmodel.dart';
import '../viewModels/auth_viewmodel.dart';
import '../viewModels/billing_viewmodel.dart';
import '../viewModels/community_viewmodel.dart';
import '../viewModels/dashboard_viewmodel.dart';
import '../viewModels/list_state.dart';
import 'usecase_provider.dart';

/// Layer 3 of 3: usecase -> ViewModel.
///
/// These are the only providers screens import.

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  // Reads the cached session immediately so the app bar can show the society
  // name before /auth/me returns.
  return AuthViewModel(ref.watch(authUsecaseProvider), ref)..loadFromStorage();
});

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(ref.watch(dashboardUsecaseProvider)),
    );

final billingViewModelProvider =
    StateNotifierProvider<BillingViewModel, ListState>(
      (ref) => BillingViewModel(ref.watch(billingUsecaseProvider)),
    );

final accountsViewModelProvider =
    StateNotifierProvider<AccountsViewModel, ListState>(
      (ref) => AccountsViewModel(ref.watch(accountsUsecaseProvider)),
    );

final communityViewModelProvider =
    StateNotifierProvider<CommunityViewModel, ListState>(
      (ref) => CommunityViewModel(ref.watch(communityUsecaseProvider)),
    );
