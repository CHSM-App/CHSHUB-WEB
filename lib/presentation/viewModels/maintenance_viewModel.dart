import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/maintenance.dart';
import 'package:society_app/domain/usecase/maintenance_usecase.dart';

@immutable
class MaintenanceState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<Maintenance>> maintenanceList;

  const MaintenanceState({
     this.isLoading = false,
    this.data,
    this.error,
    this.maintenanceList = const AsyncValue.loading(),
  });

  MaintenanceState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Maintenance>>? maintenanceList,
  }) {
    return MaintenanceState(
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      maintenanceList: maintenanceList ?? this.maintenanceList,
      
    );
  }
    @override
  List<Object?> get props => [isLoading, data, error];
}
class MaintenanceViewModel extends StateNotifier<MaintenanceState> {
  final MaintenanceUseCase useCase;

  MaintenanceViewModel(this.useCase) : super(const MaintenanceState());

  Future<void> getMaintenanceList(int flatId, int billId)async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenanceList = await useCase.getMaintenanceList(flatId, billId);
      state = state.copyWith(
        isLoading: false,
        maintenanceList: AsyncValue.data(maintenanceList),
      );
    } catch (e,st) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMessageMapper.map(e), 
        maintenanceList: AsyncValue.error(e,st),
      );
    }
  }
}