import 'package:json_annotation/json_annotation.dart';

part 'alert_notification.g.dart';

@JsonSerializable()
class AlertNotification {
  final String society_id;
  final List<int> buildings;
  final int staff_id;
  final String notification_type;
  final String title;
  final String body;

  AlertNotification({
    required this.society_id,
    required this.buildings,
    required this.staff_id,
    required this.notification_type,
    required this.title,
    required this.body,
  });
  factory AlertNotification.fromJson(Map<String, dynamic> json) =>
      _$AlertNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AlertNotificationToJson(this); 


}
