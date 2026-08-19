import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/domain/usecase/alert_usecase.dart';
import 'package:society_app/main.dart';

@immutable
class AlertState {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;

  const AlertState({this.data, this.isLoading = false, this.error});

  AlertState copyWith({
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return AlertState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AlertViewmodel extends StateNotifier<AlertState> {
  final AlertUsecase usecase;
  final FirebaseMessaging _messaging;
  AlertViewmodel(this.usecase, this._messaging) : super(const AlertState()) {
    loadData();
  }

  Future<void> loadData() async {
    // Any initial data loading can be done here
    // initListeners();
  }

  Future<Map<String, dynamic>> addOwnerMessage(
    int flatId,
    String message,
    String type,
    String societyId,
    String messageSub,
    int ownerId,
    int ownerType,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addOwnerMessage(
        flatId,
        message,
        type,
        societyId,
        messageSub,
        ownerId,
        ownerType,
      );
      state = state.copyWith(data: result);
      return result; // ✅ return response map here
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
      rethrow;
    }
  }

  // inside AlertViewModel
  Future<Map<String, dynamic>?> addAlertMessage(
    int flatId,
    String alertType,
    String societyId,
  ) async {
    try {
      final response = await usecase.addAlertMessage(
        flatId,
        alertType,
        societyId,
      );
      // keep updating state as before if needed
      state = state.copyWith(data: response);
      return response; // <--- return the response to caller
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
      return null;
    }
  }

  Future<Map<String, dynamic>?> alertmessage(
    int flatId,
    String alertType,
    String societyId,
  ) async {
    try {
      final response = await usecase.addAlertMessage(
        flatId,
        alertType,
        societyId,
      );
      // keep updating state as before if needed
      state = state.copyWith(data: response);
      return response; // <--- return the response to caller
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
      return null;
    }
  }

  Future<void> sendNotification(notification) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await usecase.sendNotification(notification);
      state = state.copyWith(data: response);
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> insertToken(int ownerId, String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      NotificationSettings settings = await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        final response = await usecase.insertToken(ownerId, type, token);
        state = state.copyWith(data: response);
      }
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
    }
  }

  // void initListeners() {
  //   // Foreground messages
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     debugPrint("Foreground message received");
  //     _handleMessage(message);
  //   });

  //   // When app opened from background (tapped notification)
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     debugPrint("App opened from background state");
  //     _handleMessage(message);
  //   });

  //   // When app opened from terminated state
  //   _checkInitialMessage();
  // }

  // void _handleMessage(RemoteMessage message) {
  //   debugPrint("Message: ${message.toMap()}");
  //   Map<String, String> data = message.data.map(
  //     (key, value) => MapEntry(key, value.toString()),
  //   );
  //   final context = navigatorKey.currentContext;

  //   if (context != null) {
  //     if (message.data["messageType"] != "visitor_entry") {
  //       showNotification(
  //         message.notification?.title ?? 'Notification',
  //         message.notification?.body ?? '',
  //       );
  //     } else {
  //       navigatorKey.currentState!.push(
  //         MaterialPageRoute(
  //           builder: (_) => VisitorPermissionDialog(
  //             visitorId: int.tryParse(message.data['visitorId'] ?? '0') ?? 0,
  //             visitorName: message.data['visitorName'] ?? 'Visitor',
  //             entryType: data['entryType'] ?? '',
  //             unit: data['unit'] ?? 'Unknown',
  //             service: data['service'] ?? 'General',
  //             imageUrl:
  //                 data['imageUrl'] ??
  //                 'https://www.w3schools.com/howto/img_avatar.png',
  //             countdownSeconds: 30,
  //             staffToken: data['staff_token'] ?? '',
  //             onResponse: (approved) {
  //               if (approved) {
  //                 debugPrint("Visitor approved from notification");
  //                 // Call API to approve visitor
  //               } else {
  //                 debugPrint("Visitor denied or timed out");
  //                 // Call API to deny visitor
  //               }
  //             },
  //           ),
  //         ),
  //       );
  //     }
  //     // showNotificationDialog(context, title, body);
  //   } else {
  //     debugPrint("⚠️ Context is null, cannot show dialog");
  //   }
  // }

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

    await flutterLocalNotificationsPlugin.show(
      0, // notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: 'custom_payload',
    );
  }

  // Future<void> _checkInitialMessage() async {
  //   final initialMessage = await _messaging.getInitialMessage();
  //   if (initialMessage != null) {
  //     debugPrint("called from terminated state");
  //     _handleMessage(initialMessage);
  //   }
  // }

  Future<void> sendDataMessage(SendNotification notification) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await usecase.sendDataMessage(notification);
      state = state.copyWith(isLoading: false,data: {"sendDataMessage": response,});
    } catch (e) {
      state = state.copyWith(error: ErrorMessageMapper.map(e));
    }
  }

}
