import 'package:json_annotation/json_annotation.dart';

part 'broadcast.g.dart';

@JsonSerializable()
class Broadcast {
  @JsonKey(name: 'from_date')
  final String? fromDate;

  @JsonKey(name: 'to_date')
  final String? toDate;

  final String? description;
  final String? name;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'user_type')
  final String? userType;

  @JsonKey(name: 'notification_id')
  final int? notificationId;

  @JsonKey(name: 'notification_type')
  final String? notificationType;

  @JsonKey(name: 'notify_status_id')
  final int? notifyStatusId;

  final String? title;
  final String? body;
  final String? timestamp;

  @JsonKey(name: 'seen_status')
  int? seenStatus;
  @JsonKey(name: 'owner_id')
  final int? ownerId;
    @JsonKey(name: 'record')
  final int? record;
  Broadcast({
    this.fromDate,
    this.toDate,
    this.description,
    this.name,
    this.societyId,
    this.userId,
    this.userType,
    this.notificationId,
    this.notificationType,
    this.notifyStatusId,
    this.title,
    this.body,
    this.timestamp,
    this.seenStatus,
    this.ownerId,
    this.record
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) =>
      _$BroadcastFromJson(json);
  Map<String, dynamic> toJson() => _$BroadcastToJson(this);
}
