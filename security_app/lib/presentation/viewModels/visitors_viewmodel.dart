import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:security_app/core/storage/token_storage.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/usecase/visitors_usercase.dart';
import 'package:security_app/core/utils/error_formatter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:security_app/main.dart';
import 'package:security_app/screens/visitor_action_dialog.dart';

class VisitorState {
  final AsyncValue<List<Visitors>> visitorsList;
  final AsyncValue<List<Visitors>> RegularvisitorsList;
  final AsyncValue<List<Visitors>> visitorHistoryList;
  final Map<String, dynamic> data;
  final bool isLoading;
  final String? error;
  const VisitorState({
    this.visitorsList = const AsyncValue.loading(),
    this.RegularvisitorsList = const AsyncValue.loading(),
    this.visitorHistoryList = const AsyncValue.loading(),
    this.data = const {},
    this.isLoading = false,
    this.error,
  });
  VisitorState copyWith({
    AsyncValue<List<Visitors>>? visitorsList,
    AsyncValue<List<Visitors>>? RegularvisitorsList,
    AsyncValue<List<Visitors>>? visitorHistoryList,
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return VisitorState(
      visitorsList: visitorsList ?? this.visitorsList,
      RegularvisitorsList: RegularvisitorsList ?? this.RegularvisitorsList,
      visitorHistoryList: visitorHistoryList ?? this.visitorHistoryList,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VisitorsViewModel extends StateNotifier<VisitorState> {
  final VisitorsUsercase usercase;
  final FirebaseMessaging _firebaseMessaging;

  VisitorsViewModel(this.usercase, this._firebaseMessaging)
    : super(const VisitorState()) {
    loadData();
  }

  Future<void> loadData() async {
    initListerners();
  }

  Future<void> insertToken(int ownerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission();
      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        await TokenStorage.saveValue("token", token);
        final response = await usercase.insertToken(ownerId, token);
        state = state.copyWith(data: response);
      }
    } catch (e) {
      state = state.copyWith(error: getErrorMessage(e));
      debugPrint("Error inserting token: $e");
    }
  }

  void initListerners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle the received message
      _handleMessage(message);
      print(
        '📩 Received a message while in the foreground: ${message.messageId}',
      );
      // You can also update the state or perform actions based on the message
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message); // context will be available here
    });

    _checkInitialMessage();
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("Message: ${message.toMap()}");

    final data = message.data;
    final context = navigatorKey.currentContext;

    if (context == null) {
      debugPrint("⚠️ Context is null, cannot show dialog");
      return;
    }

    debugPrint("✅ Context available, opening dialog");

    final ownerResponse = getOwnerResponse(data['status']);

    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => SecurityGuardVisitorDialog(
          visitorName: data['visitorName'] ?? "Visitor",
          entryType: data['entryType'] ?? "Guest",
          unit: data['unit'] ?? "Unknown",
          service: "Guest",
          imageUrl: data['imageUrl'] ?? "",
          ownerName: "Owner",
          ownerResponse: ownerResponse,
          visitorId: int.tryParse(data['visitorId'] ?? "0") ?? 0,
          onAction: (action) {
            debugPrint("Action taken: $action");
          },
        ),
      ),
    );
  }

  OwnerResponseStatus getOwnerResponse(String? status) {
    switch (status) {
      case "1":
        return OwnerResponseStatus.approved;
      case "4":
        return OwnerResponseStatus.rejected;
      default:
        return OwnerResponseStatus.notResponded;
    }
  }

  Future<void> getRegularVisitor(String society) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitors = await usercase.getRegularVisitor(society);
      state = state.copyWith(
        RegularvisitorsList: AsyncValue.data(visitors),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  // Future<void> getVisitorList(String society) async {
  //   state = state.copyWith(isLoading: true, error: null);

  //   try {
  //     final visitors = await usercase.getVisitorsList(society);

  //     // Keep only visitors whose status == 1
  //     final filteredVisitors = visitors.where((v) => v.status == 0).toList();

  //     state = state.copyWith(
  //       visitorsList: AsyncValue.data(filteredVisitors),
  //       isLoading: false,
  //     );
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: getErrorMessage(e));
  //   }
  // }
  Future<void> getVisitorList(String society) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final visitors = await usercase.getVisitorsList(society);

      // ✅ Keep all visitors, let UI handle status filtering
      state = state.copyWith(
        visitorsList: AsyncValue.data(visitors),
        isLoading: false,
      );

      // Debug print
      print("DEBUG Visitors fetched: ${visitors.map((v) => v.name).toList()}");
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> getVisitorHistory(
    String society,
    DateTime startDate,
    DateTime endDate,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final history = await usercase.getVisitorHistory(
        society,
        fmt(startDate),
        fmt(endDate),
      );
      state = state.copyWith(
        visitorHistoryList: AsyncValue.data(history),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addVisitor(Visitors visitors) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newVisitor = await usercase.insertVisitor(visitors);
      final currentVisitors = state.visitorsList.value ?? [];
      final updatedVisitors = List<Visitors>.from(currentVisitors)
        ..add(newVisitor);
      state = state.copyWith(
        visitorsList: AsyncValue.data(updatedVisitors),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> modifyVisitor(Vid, caption, userid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedVisitor = await usercase.updateVisitor(Vid, caption, userid);
      final currentVisitors = state.visitorsList.value ?? [];
      final updatedVisitors = currentVisitors.map((visitor) {
        return visitor.visitorId == Vid ? updatedVisitor : visitor;
      }).toList();
      state = state.copyWith(
        visitorsList: AsyncValue.data(updatedVisitors),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addGuest(
    int flatId,
    String guestName,
    String preDate,
    String contactNo,
    String purpose,
    String societyId,
    String location,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.addGuest(
        flatId,
        guestName,
        preDate,
        contactNo,
        purpose,
        societyId,
        location,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addCab(
    int flatId,
    String cabName,
    String vehicleNo,
    String preDate,
    String contactNo,
    String company,
    String societyId,
    String location,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.addCab(
        flatId,
        cabName,
        vehicleNo,
        preDate,
        contactNo,
        company,
        societyId,
        location,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addService(
    int flatId,
    String serviceName,
    String preDate,
    String contactNo,
    String company,
    String vehicleNo,
    String societyId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.addService(
        flatId,
        serviceName,
        preDate,
        contactNo,
        company,
        vehicleNo,
        societyId,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> addDelivery(
    int flatId,
    String deliveryName,
    String preDate,
    String contactNo,
    String purpose,
    String vehicleNo,
    String company,
    String societyId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.addDelivery(
        flatId,
        deliveryName,
        preDate,
        contactNo,
        purpose,
        vehicleNo,
        company,
        societyId,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<dynamic> addVisitorProfile(File image, int visitorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usercase.addVisitorProfile(image, visitorId);
      state = state.copyWith(isLoading: false, data: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
    return null;
  }

  Future<void> updateInsideStatus(int visitorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitors = await usercase.updateInsideStatus(visitorId);
      state = state.copyWith(
        RegularvisitorsList: AsyncValue.data(visitors),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> updateWaitingStatus(int visitorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final visitors = await usercase.updateWaitingStatus(visitorId);
      state = state.copyWith(
        RegularvisitorsList: AsyncValue.data(visitors),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> updateVisitor(
    int? visitor_id,
    String guestName,
    String contactNo,
    String entryType,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedVisitor = await usercase.updatePreVisitor(
        visitor_id,
        guestName,
        contactNo,
        entryType,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getErrorMessage(e));
    }
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }
}
