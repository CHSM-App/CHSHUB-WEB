import 'package:json_annotation/json_annotation.dart';
part 'emergency_alert.g.dart';
@JsonSerializable()
class EmergencyAlert {
  @JsonKey(name: "society_id")
  String societyId;

  @JsonKey(name: "alert_type")
  String alertType;

  @JsonKey(name: "alert_scope")
  String alertScope;

  @JsonKey(name: "selected_buildings")
  List<int>? selectedBuildings;

  @JsonKey(name: "start_time")
  String? startTime;

  @JsonKey(name: "end_time")
  String? endTime;

  @JsonKey(name: "morning_start_time")
  String? morningStartTime;

  @JsonKey(name: "morning_end_time")
  String? morningEndTime;

  @JsonKey(name: "evening_start_time")
  String? eveningStartTime;

  @JsonKey(name: "evening_end_time")
  String? eveningEndTime;

  @JsonKey(name: "has_evening")
  bool hasEvening;

  @JsonKey(name: "created_by")
  int createdBy;

 @JsonKey(name: "alert_title")
  String? alertTitle;

  @JsonKey(name: "message")
  String? alertMessage;


  EmergencyAlert({
    required this.societyId,
    required this.alertType,
    required this.alertScope,
    this.selectedBuildings,
    this.startTime,
    this.endTime,
    this.morningStartTime,
    this.morningEndTime,
    this.eveningStartTime,
    this.eveningEndTime,
    this.hasEvening = false,
    required this.createdBy,
    this.alertTitle ,
    this.alertMessage ,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) =>
      _$EmergencyAlertFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyAlertToJson(this);
}
