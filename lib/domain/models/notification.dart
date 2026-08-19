import 'package:json_annotation/json_annotation.dart';
part 'notification.g.dart';
 
@JsonSerializable(explicitToJson: true)
class SendNotification {
  final List<String> tokens;
  final String? title;
  final String? body;
  final String? clickAction;
  final String? visitorName;
  final int? visitorId;
  final String? purpose;
  final String? unit;
  final String? id;
   final String? image;              
  final String? staff_token;  
  final String? status; // ✅ add this 
  final String? entryType; // ✅ add this
  SendNotification({
     required this.tokens,
     this.status,
     this.title,
     this.body,
     this.clickAction,
     this.visitorName,
     this.visitorId,
     this.purpose,
     this.unit,
     this.id,
      this.image,
    this.staff_token,
    this.entryType,
  });
  factory SendNotification.fromJson(Map<String, dynamic> json) =>
      _$SendNotificationFromJson(json);


  Map<String, dynamic> toJson() => _$SendNotificationToJson(this); // ✅ add this
}