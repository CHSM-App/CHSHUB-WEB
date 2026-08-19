import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/broadcast.dart';
import '../../domain/usecase/broadcast_usecase.dart';

@immutable
class BroadcastState {
  final AsyncValue<List<Broadcast>> broadcastList;
  final AsyncValue<List<Broadcast>> notificationList;
  final AsyncValue<List<Broadcast>> notificationDetails;
 final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;

  const BroadcastState({
    this.broadcastList = const AsyncValue.loading(),
    this.notificationList = const AsyncValue.loading(),
    this.notificationDetails = const AsyncValue.loading(),
    this.data,
    this.isLoading = false, 
    this.error,
  });

  BroadcastState copyWith({
    AsyncValue<List<Broadcast>>? broadcastList,
    AsyncValue<List<Broadcast>>? notificationList,
   
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return BroadcastState(
      broadcastList: broadcastList ?? this.broadcastList,
      notificationList: notificationList ?? this.notificationList,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BroadcastViewModel extends StateNotifier<BroadcastState> {
  final BroadcastUsecase usecase;

  BroadcastViewModel(this.usecase) : super(const BroadcastState());

  Future<void> getBroadcast(String societyId,int ownerId  ) async {
    state = state.copyWith(broadcastList: const AsyncValue.loading());
    try {
      final result = await usecase.getBroadcast(societyId, ownerId);
      state = state.copyWith(broadcastList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(broadcastList: AsyncValue.error(e, st));
    }
  }

  Future<void> getNotification(
      String societyId, int ownerId,  ) async {
    state = state.copyWith(notificationList: const AsyncValue.loading());
    try {
      final result = await usecase.getNotification(societyId, ownerId, );
      state = state.copyWith(notificationList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(notificationList: AsyncValue.error(e, st));
    }
  }

  Future<void> updateNotificationStatus(int id, String society,int OwnerId  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.updateNotificationStatus(id, );
      await Future.wait([
        getBroadcast(society, OwnerId),
        getNotification(society, OwnerId),
      ]);
      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e), isLoading: false);
    }
  }

  // Marks every unseen notification of a given type (e.g. "Maintenance") as
  // seen in one call. Used by entry points that open a content screen
  // directly (e.g. Home's Payment quick-access card) without a specific
  // notify_status_id to update, so the related badge still clears.
  Future<void> markAllNotificationsSeenByType(
    String society,
    int ownerId,
    String notificationType,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.markAllNotificationsSeenByType(
        society,
        ownerId,
        notificationType,
      );
      await Future.wait([
        getBroadcast(society, ownerId),
        getNotification(society, ownerId),
      ]);
      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e), isLoading: false);
    }
  }

  // Future<void> getNotificationDetails(
  //     String society, String type, int id,  ) async {
  //   state = state.copyWith(notificationDetails: const AsyncValue.loading());
  //   try {
  //     final result =
  //         await usecase.getNotificationDetails(society, type, id,);
  //     state = state.copyWith(notificationDetails: AsyncValue.data(result));
  //   } catch (e, st) {
  //     state = state.copyWith(notificationDetails: AsyncValue.error(e, st));
  //   }
  // }

  Future<void> insertNotification(Broadcast broadcast) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.insertNotification(broadcast);
      state = state.copyWith(data: result);
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
    }
  }
     
}
