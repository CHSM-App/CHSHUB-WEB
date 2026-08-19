

import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/receipt.dart';
import 'package:society_app/domain/usecase/due_history_use_case.dart';

class DueHistoryState {
   final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<DueHistory>> dueHistory;
  final AsyncValue<List<DueHistory>> receipt;

  const DueHistoryState({
        this.isLoading = false,
    this.data,
    this.error,
    this.dueHistory = const AsyncValue.loading(),
    this.receipt = const AsyncValue.loading(),
  });

  DueHistoryState copyWith({
     bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<DueHistory>>? dueHistory,
    AsyncValue<List<DueHistory>>? receipt,
  }) {
    return DueHistoryState(
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      dueHistory: dueHistory ?? this.dueHistory,
      receipt: receipt ?? this.receipt,
    );
  }
  
}

class DueHistoryViewModel extends StateNotifier<DueHistoryState> {
    final DueHistoryUseCase getDueHistory;

    DueHistoryViewModel(this.getDueHistory) : super(const DueHistoryState());

    Future<void> loadDueHistory(int  ownerId,  ) async {
      state = state.copyWith(dueHistory: const AsyncValue.loading());
      try {
        final result = await getDueHistory.getDueHistory(ownerId, );
        state = state.copyWith(dueHistory: AsyncValue.data(result));
      } catch (e, st) {
        state = state.copyWith(dueHistory: AsyncValue.error(e, st));
      }
    }

    Future<void> loadReceipt(int receiptId) async {
      state = state.copyWith(receipt: const AsyncValue.loading());
      try {
        final result = await getDueHistory.getReceipt(receiptId);
        state = state.copyWith(receipt: AsyncValue.data(result));
      } catch (e, st) {
        state = state.copyWith(receipt: AsyncValue.error(e, st));
      }
    }
    
  // Future<int?> addReceipt(Receipt receipt) async {
  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     final result = await getDueHistory.addReceipt(receipt);
  //     state = state.copyWith(isLoading: false, data: result);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
  //   }
  //   return null;
  // }
  Future<int?> addReceipt(Receipt receipt) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final result = await getDueHistory.addReceipt(receipt);

    // Update state with result if needed
    state = state.copyWith(isLoading: false, data: result);

    // Return the receipt ID to the caller
    return result['receipt'] as int?;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    return null; // only return null on error
  }
}

  
}