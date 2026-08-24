import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_formatter.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/usecase/dashboard_usecase.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final AsyncValue<DashboardSummary> summary;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.summary = const AsyncValue.loading(),
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    AsyncValue<DashboardSummary>? summary,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      summary: summary ?? this.summary,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DashboardUsecase usecase;

  DashboardViewModel(this.usecase) : super(const DashboardState());

  /// Load the landing page figures.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await usecase.getDashboard();
      state = state.copyWith(
        isLoading: false,
        summary: AsyncValue.data(summary),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: formatError(e),
        summary: AsyncValue.error(e, st),
      );
    }
  }
}
