import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecase/accounts_usecase.dart';
import '../../domain/usecase/auth_usecase.dart';
import '../../domain/usecase/billing_usecase.dart';
import '../../domain/usecase/community_usecase.dart';
import '../../domain/usecase/dashboard_usecase.dart';
import 'repository_provider.dart';

/// Layer 2 of 3: repository -> usecase.

final authUsecaseProvider = Provider<AuthUsecase>(
  (ref) => AuthUsecase(ref.watch(authRepositoryProvider)),
);

final dashboardUsecaseProvider = Provider<DashboardUsecase>(
  (ref) => DashboardUsecase(ref.watch(dashboardRepositoryProvider)),
);

final billingUsecaseProvider = Provider<BillingUsecase>(
  (ref) => BillingUsecase(ref.watch(billingRepositoryProvider)),
);

final accountsUsecaseProvider = Provider<AccountsUsecase>(
  (ref) => AccountsUsecase(ref.watch(accountsRepositoryProvider)),
);

final communityUsecaseProvider = Provider<CommunityUsecase>(
  (ref) => CommunityUsecase(ref.watch(communityRepositoryProvider)),
);
