import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/directory.dart';
import '../../domain/usecase/directory_usecase.dart';

@immutable
class DirectoryState {
  final AsyncValue<List<Directory>> committeeMembers;
  final AsyncValue<List<Directory>> allTokens;
  final AsyncValue<List<Directory>> emergencyContacts;
  final AsyncValue<List<Directory>> neighbours;
  final AsyncValue<List<Directory>> vendors;

  const DirectoryState({
    this.committeeMembers = const AsyncValue.loading(),
    this.allTokens = const AsyncValue.loading(),
    this.emergencyContacts = const AsyncValue.loading(),
    this.neighbours = const AsyncValue.loading(),
    this.vendors = const AsyncValue.loading(),
  });

  DirectoryState copyWith({
    AsyncValue<List<Directory>>? committeeMembers,
    AsyncValue<List<Directory>>? allTokens,
    AsyncValue<List<Directory>>? emergencyContacts,
    AsyncValue<List<Directory>>? neighbours,
    AsyncValue<List<Directory>>? vendors,
  }) {
    return DirectoryState(
      committeeMembers: committeeMembers ?? this.committeeMembers,
      allTokens: allTokens ?? this.allTokens,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      neighbours: neighbours ?? this.neighbours,
      vendors: vendors ?? this.vendors,
    );
  }
}

class DirectoryViewModel extends StateNotifier<DirectoryState> {
  final DirectoryUsecase usecase;

  DirectoryViewModel(this.usecase) : super(const DirectoryState());

  Future<void> loadCommitteeMembers(String societyId,  ) async {
    state = state.copyWith(committeeMembers: const AsyncValue.loading());
    try {
      final result = await usecase.getCommitteeMembers(societyId,);
      state = state.copyWith(committeeMembers: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(committeeMembers: AsyncValue.error(e, st));
    }
  }

  Future<void> loadAllTokens(String societyId,  ) async {
    state = state.copyWith(allTokens: const AsyncValue.loading());
    try {
      final result = await usecase.getAllTokens(societyId, );
      state = state.copyWith(allTokens: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(allTokens: AsyncValue.error(e, st));
    }
  }

  Future<void> loadEmergencyContacts( ) async {
    state = state.copyWith(emergencyContacts: const AsyncValue.loading());
    try {
      final result = await usecase.getEmergencyContacts();
      state = state.copyWith(emergencyContacts: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(emergencyContacts: AsyncValue.error(e, st));
    }
  }

  Future<void> loadNeighbours(String wName,  ) async {
    state = state.copyWith(neighbours: const AsyncValue.loading());
    try {
      final result = await usecase.getNeighbours(wName, );
      state = state.copyWith(neighbours: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(neighbours: AsyncValue.error(e, st));
    }
  }

  Future<void> loadVendors(String societyId,  ) async {
    state = state.copyWith(vendors: const AsyncValue.loading());
    try {
      final result = await usecase.getVendors(societyId, );
      state = state.copyWith(vendors: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(vendors: AsyncValue.error(e, st));
    }
  }
}
