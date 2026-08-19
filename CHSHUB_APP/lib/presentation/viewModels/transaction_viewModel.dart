// ignore: file_name
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/test_payment.dart';
import 'package:society_app/domain/usecase/transaction_use_case.dart';

@immutable
class TransancationState {
  final AsyncValue<String> transaction;
final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  const TransancationState({
    this.transaction = const AsyncValue.loading(),
     this.isLoading = false,
    this.data,
    this.error,
  });

  const TransancationState.initial(this.isLoading, this.data, this.error) : transaction = const AsyncValue.loading();

  TransancationState copyWith({
    AsyncValue<String>? transaction,
       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return TransancationState(
      transaction: transaction ?? this.transaction,
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}


class TransactionViewmodel extends StateNotifier<TransancationState> {
  final TransactionUseCase useCases;

  TransactionViewmodel(this.useCases) : super(const TransancationState.initial(false, null, null));

  Future<void> getTransactionDue(int flatId) async {
    state = state.copyWith(transaction: const AsyncValue.loading());
    try {
      final result = await useCases.getTransaction(flatId);
      state = state.copyWith(transaction: AsyncValue.data(result.toString()));
    } catch (e, st) {
      state = state.copyWith(transaction: AsyncValue.error(e, st));
    }
  }
  Future<void> createPaymentOrder(TestPayment payment) async {
     state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.createPaymentOrder(payment);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }
    Future<void> verifyPayment(TestPayment payment) async {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final result = await useCases.verifyPayment(payment);
        state = state.copyWith(isLoading: false, data: result);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
      }
    }

}