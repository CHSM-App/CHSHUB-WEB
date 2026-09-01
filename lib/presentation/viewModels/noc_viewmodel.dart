import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/noc_request.dart';
import 'package:society_app/domain/usecase/noc_usecase.dart';

@immutable
class NocState {
  /// The flat's requests, newest first.
  final AsyncValue<List<NocRequest>> requestList;

  /// The reply to the last raise, carrying the new `request_id`.
  final Map<String, dynamic>? data;

  final bool isLoading;
  final String? error;

  const NocState({
    this.requestList = const AsyncValue.loading(),
    this.data,
    this.isLoading = false,
    this.error,
  });

  NocState copyWith({
    AsyncValue<List<NocRequest>>? requestList,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return NocState(
      requestList: requestList ?? this.requestList,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NocViewModel extends StateNotifier<NocState> {
  final NocUsecase useCases;

  NocViewModel(this.useCases) : super(const NocState());

  /// The flat's own requests, for the list the member's screen opens on.
  Future<void> getNocRequests(int flatId) async {
    state = state.copyWith(requestList: const AsyncValue.loading());
    try {
      final result = await useCases.getNocRequests(flatId);
      state = state.copyWith(requestList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(requestList: AsyncValue.error(e, st));
    }
  }

  /// Raise a request, then reload the list so it appears straight away.
  ///
  /// The reload is skipped when the raise failed: the list on screen is still
  /// correct, and refetching would only replace an error the member needs to
  /// read with a spinner.
  Future<void> insertNocRequest(NocRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.insertNocRequest(request);
      state = state.copyWith(
        isLoading: false,
        data: result is Map ? Map<String, dynamic>.from(result) : null,
      );
      if (request.flatId != null) await getNocRequests(request.flatId!);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }
}
