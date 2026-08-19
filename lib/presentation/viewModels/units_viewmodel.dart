import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/unit_spinner.dart';
import 'package:security_app/domain/usecase/units_usecase.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class UnitState {
  final AsyncValue<List<UnitSpinner>> unitsList;
  final Map<String, dynamic> data;
  final bool isLoading;
  final String? error;
  const UnitState({
    this.unitsList = const AsyncValue.loading(),
    this.data = const {},
    this.isLoading = false,
    this.error,

  });
  UnitState copyWith({
    AsyncValue<List<UnitSpinner>>? unitsList,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return UnitState(
      unitsList: unitsList ?? this.unitsList,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UnitsViewModel extends StateNotifier<UnitState> {
  final UnitsUsecase unitsUsecase;
  UnitsViewModel(this.unitsUsecase) : super(const UnitState());

  Future<void> fetchUnits(String societyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final units = await unitsUsecase.getAllUnits(societyId);
      state = state.copyWith(
        unitsList: AsyncValue.data(units),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  
}
