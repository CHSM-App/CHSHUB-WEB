import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/visitor_response_page.dart';

import 'package:society_app/domain/usecase/visitor_usecase.dart';
import 'package:society_app/main.dart';

import '../../domain/models/visitor.dart';

@immutable
class VisitorState {
  final AsyncValue<List<Visitor>> visitorList;
  final AsyncValue<Visitor?> operationStatus;
  final AsyncValue<int> addVisitor;
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const VisitorState({
    this.data,
    this.addVisitor = const AsyncValue.data(0),
    this.visitorList = const AsyncValue.data([]),
    this.operationStatus = const AsyncValue.data(null),
    this.isLoading = false,
    this.error,
  });

  VisitorState copyWith({
    Map<String, dynamic>? data,
    AsyncValue<int>? addVisitor,
    AsyncValue<List<Visitor>>? visitorList,
    AsyncValue<Visitor?>? operationStatus,
    bool? isLoading,
    String? error,
  }) {
    return VisitorState(
      addVisitor: addVisitor ?? this.addVisitor,
      visitorList: visitorList ?? this.visitorList,
      operationStatus: operationStatus ?? this.operationStatus,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VisitorViewModel extends StateNotifier<VisitorState> {
  final VisitorUsecase usecase;
  final FirebaseMessaging _messaging;

  VisitorViewModel(this.usecase, this._messaging)
    : super(const VisitorState()) {
    initListeners();
  }

  /// Optimistically updates visitor status in UI, then syncs with backend
  Future<bool> updateWaitingStatusOptimistic(int visitorId) async {
    debugPrint("🔵 [ViewModel] Starting optimistic update for visitor: $visitorId");
    
    // Store the current list for potential rollback
    final currentState = state.visitorList;
    List<Visitor>? previousVisitors;
    
    currentState.whenData((visitors) {
      debugPrint("🔵 [ViewModel] Current visitors count: ${visitors.length}");
      
      // Store a copy for rollback
      previousVisitors = List<Visitor>.from(visitors);
      
      // Find and log the visitor being updated
      final targetVisitor = visitors.firstWhere(
        (v) => v.visitorId == visitorId,
        orElse: () => visitors.first,
      );
      debugPrint("🔵 [ViewModel] Found visitor: ${targetVisitor.vName}, current status: ${targetVisitor.status}");
      
      final updatedVisitors = visitors.map((visitor) {
        if (visitor.visitorId == visitorId) {
          debugPrint("🔵 [ViewModel] Updating visitor status from ${visitor.status} to 1");

          return _createUpdatedVisitor(visitor, newStatus: 1);
        }
        return visitor;
      }).toList();

      debugPrint("🔵 [ViewModel] Updated visitors count: ${updatedVisitors.length}");
      
      // Update state with the new list - this should trigger UI rebuild
      state = state.copyWith(
        visitorList: AsyncValue.data(updatedVisitors),
        isLoading: true,
        error: null,
      );
      
      debugPrint("🔵 [ViewModel] State updated, new state visitors count: ${state.visitorList.value?.length}");
    });

    // Small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final result = await usecase.updateWaitingStatus(visitorId);
      if(result['message'] == 'Successfully')
      {
        state = state.copyWith(isLoading: false);
        return true;
      }else{
        // Backend update failed - rollback the optimistic update
        if (previousVisitors != null) {
          state = state.copyWith(
            visitorList: AsyncValue.data(previousVisitors!),
            isLoading: false,
            error: 'Failed to update status on server',
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint("❌ [ViewModel] Exception occurred: $e");
      
      // Error occurred - rollback the optimistic update
      if (previousVisitors != null) {
        state = state.copyWith(
          visitorList: AsyncValue.data(previousVisitors!),
          isLoading: false,
          error: ErrorMessageMapper.map(e),
        );
      }
      return false;
    }
  }

  // Helper method to create a new visitor with updated status
  Visitor _createUpdatedVisitor(Visitor visitor, {required int newStatus}) {
    return Visitor(
      visitorId: visitor.visitorId,
      vName: visitor.vName,
      contactNo: visitor.contactNo,
      type: visitor.type,
      company: visitor.company,
      vehicleNo: visitor.vehicleNo,
      purpose: visitor.purpose,
      preDate: visitor.preDate,
      inDate: visitor.inDate,
      outDate: visitor.outDate,
      image: visitor.image,
      gateOtp: visitor.gateOtp,
      status: newStatus, // The updated status
      flatId: visitor.flatId,
      ownerId: visitor.ownerId,
      societyId: visitor.societyId,
    );
  }

  Future<void> updateWaitingStatus(int visitorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.updateWaitingStatus(visitorId);
      state = state.copyWith(operationStatus: AsyncValue.data(result));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> getVisitorList(String predate, int flatId) async {
    state = state.copyWith(visitorList: const AsyncValue.loading());
    try {
      final result = await usecase.getVisitorList(predate, flatId);
      state = state.copyWith(visitorList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(visitorList: AsyncValue.error(e, st));
    }
  }


  Future<void> addCab(
    String cabName,
    String vehicleNo,
    String preDate,
    String contactNo,
    String company,
    String societyId,
    int ownerId,
    int flatId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addCab(
        cabName,
        vehicleNo,
        preDate,
        contactNo,
        company,
        societyId,
        ownerId,
        flatId,
      );
     
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> addService(
    String serviceName,
    String preDate,
    String contactNo,
    String company,
    String societyId,
    int ownerId,
    int flatId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addService(
        serviceName,
        preDate,
        contactNo,
        company,
        societyId,
        ownerId,
        flatId,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> addDelivery(
    String deliveryName,
    String preDate,
    String contactNo,
    String preference,
    String company,
    String societyId,
    int ownerId,
    int flatId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addDelivery(
        deliveryName,
        preDate,
        contactNo,
        preference,
        company,
        societyId,
        ownerId,
        flatId,
      );

      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> addGuest(
    String guestName,
    String preDate,
    String contactNo,
    String societyId,
    int ownerId,
    int flatId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addGuest(
        guestName,
        preDate,
        contactNo,
        societyId,
        ownerId,
        flatId,
      );

      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> deleteExpectedVisitor(int visitorId) async {
    state = state.copyWith(operationStatus: const AsyncValue.loading());
    try {
      final result = await usecase.deleteExpectedVisitor(visitorId);
      state = state.copyWith(operationStatus: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(operationStatus: AsyncValue.error(e, st));
    }
  }

  void clearStatus() {
    state = state.copyWith(operationStatus: const AsyncValue.data(null));
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    // state = VisitorState.initial();
  }

  Future<void> visitorAction(Visitor visitor) async {
    state = state.copyWith(operationStatus: const AsyncValue.loading());
    try {
      final result = await usecase.visitorAction(visitor);
      state = state.copyWith(operationStatus: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(operationStatus: AsyncValue.error(e, st));
    }
  }

  void initListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // When app opened from background (tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // When app opened from terminated state
    _checkInitialMessage();
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("Message: ${message.toMap()}");
    Map<String, String> data = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final context = navigatorKey.currentContext;

    if (context != null) {
      if (message.data["messageType"] != "visitor_entry") {
        showNotification(
          message.notification?.title ?? 'Notification',
          message.notification?.body ?? '',
        );
      } else {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => VisitorPermissionDialog(
              visitorId: int.tryParse(message.data['visitorId'] ?? '0') ?? 0,
              visitorName: message.data['visitorName'] ?? 'Visitor',
              entryType: data['entryType'] ?? '',
              unit: data['unit'] ?? 'Unknown',
              service: data['service'] ?? 'General',
              imageUrl:
                  data['imageUrl'] ??
                  'https://www.w3schools.com/howto/img_avatar.png',
              countdownSeconds: 30,
              staffToken: data['staff_token'] ?? '',
              onResponse: (approved) {
                if (approved) {
                  debugPrint("Visitor approved from notification");
                  // Call API to approve visitor
                } else {
                  debugPrint("Visitor denied or timed out");
                  // Call API to deny visitor
                }
              },
            ),
          ),
        );
      }
    } else {
      debugPrint("⚠️ Context is null, cannot show dialog");
    }
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel_id',
          'General Notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }
}