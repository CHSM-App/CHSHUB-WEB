import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/domain/models/directory.dart';
import 'package:security_app/domain/usecase/directory_usecase.dart';
import 'package:security_app/core/utils/error_formatter.dart';

class DirectoryState {
  final AsyncValue<List<Directory>> directoryList;
  final bool isLoading;
  final String? error;
  const DirectoryState({
    this.directoryList = const AsyncValue.loading(),
    this.isLoading = false,
    this.error,
  });

  DirectoryState copyWith({
    AsyncValue<List<Directory>>? directoryList,
    bool? isLoading,
    String? error,
  }) {
    return DirectoryState(
      directoryList: directoryList ?? this.directoryList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
class DirectoryViewModel extends StateNotifier<DirectoryState> {
  final DirectoryUsecase usercase;
  DirectoryViewModel(this.usercase) : super(const DirectoryState());

  Future<void> getEmergencyContacts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final directory = await usercase.getEmergencyContacts();
      state = state.copyWith(
        directoryList: AsyncValue.data(directory),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }


  Future<void> getNeighbours(int bId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final directory = await usercase.getNeighbours(bId);
      state = state.copyWith(
        directoryList: AsyncValue.data(directory),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }
  Future<void> getCommitteeMembers(String societyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final directory = await usercase.getCommitteeMembers(societyId);
      state = state.copyWith(
        directoryList: AsyncValue.data(directory),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }
} 


