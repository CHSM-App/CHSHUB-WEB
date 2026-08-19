import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/helper.dart';

import '../../domain/usecase/helper_use_case.dart';

@immutable
class HelperState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<Helper>> helpers;
  final AsyncValue<List<Helper>> helperDetails;
  final AsyncValue<List<Helper>> WorkDetails;
  final AsyncValue<List<Helper>> helperReviewDetails;
  final AsyncValue<List<Helper>> deleteHelperReview;
   final AsyncValue<List<Helper>> assignFlat;
 final AsyncValue<List<Helper>> unassignFlat;

  // Local review-count overrides keyed by usefullContactId. Applied on top
  // of whatever `helpers` currently holds (including while a background
  // refresh is loading/erroring), so a just-added review always shows up
  // immediately and can't be discarded by a stale or in-flight fetch.
  final Map<int, int> reviewCountOverrides;

  const HelperState({
     this.isLoading = false,
    this.data,
    this.error,
    this.helpers = const AsyncValue.loading(),
    this.helperDetails = const AsyncValue.loading(),
    this.WorkDetails = const AsyncValue.loading(),
    this.helperReviewDetails = const AsyncValue.loading(),
    this.deleteHelperReview = const AsyncValue.loading(),
      this.assignFlat = const AsyncValue.loading(),
       this.unassignFlat = const AsyncValue.loading(),
    this.reviewCountOverrides = const {},
  });

//  const HelperState.initial() : helpers = const AsyncValue.loading();


  HelperState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Helper>>? helpers,
    AsyncValue<List<Helper>>? helperDetails,
    AsyncValue<List<Helper>>? WorkDetails,
    AsyncValue<List<Helper>>? helperReviewDetails,
    AsyncValue<List<Helper>>? deleteHelperReview,
     AsyncValue<List<Helper>>? assignFlat,
         AsyncValue<List<Helper>>? unassignFlat,
    Map<int, int>? reviewCountOverrides,
  }) {
    return HelperState(
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      helpers: helpers ?? this.helpers,
      helperDetails: helperDetails ?? this.helperDetails,
      WorkDetails: WorkDetails ?? this.WorkDetails,
      helperReviewDetails: helperReviewDetails ?? this.helperReviewDetails,
      deleteHelperReview: deleteHelperReview ?? this.deleteHelperReview,
        assignFlat: assignFlat ?? this.assignFlat,
       unassignFlat: unassignFlat ?? this.unassignFlat,
      reviewCountOverrides: reviewCountOverrides ?? this.reviewCountOverrides,
    );
  }

  // The list a screen should actually render: `helpers` data with any
  // pending local review-count overrides applied on top. Falls back to
  // `fallback` (e.g. a previous snapshot) while helpers is loading/erroring,
  // so the UI never regresses to a stale count during a background refresh.
  List<Helper> displayHelpers(List<Helper> fallback) {
    final base = helpers.value ?? fallback;
    if (reviewCountOverrides.isEmpty) return base;
    return base.map((h) {
      final override = reviewCountOverrides[h.usefullContactId];
      debugPrint('🔎 displayHelpers: id=${h.usefullContactId}, '
          'reviewCount=${h.reviewCount}, override=$override');
      if (override == null || override <= (h.reviewCount ?? 0)) return h;
      return h.copyWith(reviewCount: override);
    }).toList();
  }

    @override
  List<Object?> get props => [isLoading, data, error];
}


class HelperViewModel extends StateNotifier<HelperState> {
  final HelperUseCases useCases;

  HelperViewModel(this.useCases) : super(const HelperState());

  Future<void> getHelperList(String societyID) async {
    // Keep the previous data visible while refreshing instead of flipping
    // to a bare loading state, so any active review-count override still
    // has a base list to apply on top of via displayHelpers().
    try {
      final result = await useCases.getHelperList(societyID);
      state = state.copyWith(helpers: AsyncValue.data(result));
      // Drop overrides the server has now caught up with.
      if (state.reviewCountOverrides.isNotEmpty) {
        final stillPending = <int, int>{};
        for (final entry in state.reviewCountOverrides.entries) {
          final serverHelper = result.firstWhere(
            (h) => h.usefullContactId == entry.key,
            orElse: () => Helper(),
          );
          if ((serverHelper.reviewCount ?? 0) < entry.value) {
            stillPending[entry.key] = entry.value;
          }
        }
        state = state.copyWith(reviewCountOverrides: stillPending);
      }
    } catch (e, st) {
      state = state.copyWith(helpers: AsyncValue.error(e, st));
    }
  }
  // Future<void> getHelperDetails(String societyID, ) async {
  //   state = state.copyWith(helpers: const AsyncValue.loading());
  //   try {
  //     final result = await useCases.getHelperDetails(societyID);
  //     state = state.copyWith(helpers: AsyncValue.data(result));
  //   } catch (e, st) {
  //     state = state.copyWith(helpers: AsyncValue.error(e, st));
  //   }
  // }
  // Future<void> findHelperDetails(int helperId, String type) async {
  //   state = state.copyWith(helperDetails: const AsyncValue.loading());
  //   try {
  //     final result = await useCases.FindHelperDetails(helperId, type);
  //     state = state.copyWith(helperDetails: AsyncValue.data(result));
  //   } catch (e, st) {
  //     state = state.copyWith(helperDetails: AsyncValue.error(e, st));
  //   }
  // }
  Future<void> getHelperWorkDetails(int helperId, String type) async {
    state = state.copyWith(WorkDetails: const AsyncValue.loading());
    try {
      final result = await useCases.FindHelperInfo(helperId, type);
      state = state.copyWith(WorkDetails: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(WorkDetails: AsyncValue.error(e, st));
    }
  }
  Future<void> helperReview(int helperId, String type) async {
    // Keep whatever is currently shown (including an optimistic prepend
    // from addReviewOptimistically) visible while refetching, instead of
    // flipping to a bare loading state and losing it for the round-trip.
    state = state.copyWith(
      helperReviewDetails: AsyncValue<List<Helper>>.loading().copyWithPrevious(
        state.helperReviewDetails,
      ),
    );
    try {
      final result = await useCases.HelperReview(helperId, type);
      state = state.copyWith(helperReviewDetails: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(helperReviewDetails: AsyncValue.error(e, st));
    }
  }

  Future<void> addReview(Helper helper) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.addReview(helper);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  // Optimistically prepends the just-submitted review to the currently
  // loaded review list, so the "Reviews (N)" sheet reflects it instantly
  // instead of waiting on the background helperReview() network round-trip
  // (which also briefly flips helperReviewDetails to loading()).
  void addReviewOptimistically(Helper review) {
    final current = state.helperReviewDetails.value ?? const <Helper>[];
    state = state.copyWith(
      helperReviewDetails: AsyncValue.data([review, ...current]),
    );
  }

  // Optimistically increments the review count for a helper. This is
  // stored as an override (not baked into `helpers`), so it survives
  // `helpers` being loading/error/stale and is applied live wherever a
  // screen reads state.displayHelpers(...).
  void bumpReviewCount(int? usefullContactId) {
    debugPrint('🔎 bumpReviewCount called with id=$usefullContactId, '
        'helpers.value is null=${state.helpers.value == null}, '
        'helpers.value length=${state.helpers.value?.length}');
    if (usefullContactId == null) return;
    final currentList = state.helpers.value ?? const <Helper>[];
    final existing = currentList.firstWhere(
      (h) => h.usefullContactId == usefullContactId,
      orElse: () => Helper(),
    );
    debugPrint('🔎 existing helper found: usefullContactId=${existing.usefullContactId}, '
        'reviewCount=${existing.reviewCount}');
    final baseCount =
        state.reviewCountOverrides[usefullContactId] ?? existing.reviewCount ?? 0;
    state = state.copyWith(
      reviewCountOverrides: {
        ...state.reviewCountOverrides,
        usefullContactId: baseCount + 1,
      },
    );
    debugPrint('🔎 new reviewCountOverrides: ${state.reviewCountOverrides}');
  }

  Future<void> deleteHelperReview(int reviewId) async {
    state = state.copyWith(deleteHelperReview: const AsyncValue.loading());
    try {
      final result = await useCases.deleteHelperReview(reviewId);
      state = state.copyWith(deleteHelperReview: AsyncValue.data([result]));
    } catch (e, st) {
      state = state.copyWith(deleteHelperReview: AsyncValue.error(e, st));
    }
  }
  Future<void> helperAssignFlat(Helper helper) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.helperAssignFlat(helper);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }
  Future<void> unAssignflat(int usefullContactId,int workId,int flatId) async {
    state = state.copyWith(deleteHelperReview: const AsyncValue.loading());
    try {
      final result = await useCases.unAssignflat(usefullContactId,workId,flatId);
      state = state.copyWith(deleteHelperReview: AsyncValue.data([result]));
    } catch (e, st) {
      state = state.copyWith(deleteHelperReview: AsyncValue.error(e, st));
    }
  }
   Future<void> flatunAssign(int workId) async {
    state = state.copyWith(deleteHelperReview: const AsyncValue.loading());
    try {
      final result = await useCases.flatunAssign(workId);
      state = state.copyWith(deleteHelperReview: AsyncValue.data([result]));
    } catch (e, st) {
      state = state.copyWith(deleteHelperReview: AsyncValue.error(e, st));
    }
  }
  void onItemTapped(Helper helper) {
    // You can log, update state, or call analytics here
    debugPrint("Tapped on: ${helper.pName}");
  }
}