import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/facilities.dart';
import 'package:society_app/domain/usecase/facilities_usecase.dart';

class facilitiesState{
  final AsyncValue<List<Facilities>> facilities;

  final AsyncValue<List<Facilities>> bookedFacilities;

  final AsyncValue<List<Facilities>> availableSlots;
final Map<String, dynamic>? data;
final isLoading;
final String? error;

  



  const facilitiesState({
    this.facilities = const AsyncValue.loading(),
    this.bookedFacilities = const AsyncValue.loading(),
    this.availableSlots = const AsyncValue.loading(),
    this.data,
    this.isLoading = false,
    this.error,
  });

  facilitiesState copyWith({
    AsyncValue<List<Facilities>>? facilities,
    AsyncValue<List<Facilities>>? bookedFacilities,
    AsyncValue<List<Facilities>>? availableSlots,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return facilitiesState(
      facilities: facilities ?? this.facilities,

      bookedFacilities: bookedFacilities ?? this.bookedFacilities,

      availableSlots: availableSlots ?? this.availableSlots,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}


class FacilitiesViewModel extends StateNotifier<facilitiesState> {
  final FacilitiesUsecase usecase;

  FacilitiesViewModel(this.usecase) : super(const facilitiesState());
  Future<void> loadFacilities(String societyId,  ) async {
    state = state.copyWith(facilities: const AsyncValue.loading());
    try {
      final result = await usecase.getFacilities(societyId, );
      state = state.copyWith(facilities: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(facilities: AsyncValue.error(e, st));
    }
  }


  Future<void> loadBookedFacilities(int flatId,  ) async {
    state = state.copyWith(bookedFacilities: const AsyncValue.loading());
    try {
      final result = await usecase.getBookedAmenities(flatId,);
      state = state.copyWith(bookedFacilities: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(bookedFacilities: AsyncValue.error(e, st));
    }
  }

  Future<void> loadAvailableSlots(int facilityId, String date,) async {
    state = state.copyWith(availableSlots: const AsyncValue.loading());
    try {
      final result = await usecase.getAvailableSlots(facilityId, date,);
      state = state.copyWith(availableSlots: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(availableSlots: AsyncValue.error(e, st));
    }
  }

    Future<void> bookFacility(Facilities facility) async {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final result = await usecase.bookFacility(facility);

        // ✅ Save status code (200, 404, 500, etc.)
        state = state.copyWith(data: result, isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
      }
    }
}