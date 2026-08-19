// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyAlert _$EmergencyAlertFromJson(Map<String, dynamic> json) =>
    EmergencyAlert(
      societyId: json['society_id'] as String,
      alertType: json['alert_type'] as String,
      alertScope: json['alert_scope'] as String,
      selectedBuildings: (json['selected_buildings'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      morningStartTime: json['morning_start_time'] as String?,
      morningEndTime: json['morning_end_time'] as String?,
      eveningStartTime: json['evening_start_time'] as String?,
      eveningEndTime: json['evening_end_time'] as String?,
      hasEvening: json['has_evening'] as bool? ?? false,
      createdBy: (json['created_by'] as num).toInt(),
      alertTitle: json['alert_title'] as String?,
      alertMessage: json['message'] as String?,
    );

Map<String, dynamic> _$EmergencyAlertToJson(EmergencyAlert instance) =>
    <String, dynamic>{
      'society_id': instance.societyId,
      'alert_type': instance.alertType,
      'alert_scope': instance.alertScope,
      'selected_buildings': instance.selectedBuildings,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'morning_start_time': instance.morningStartTime,
      'morning_end_time': instance.morningEndTime,
      'evening_start_time': instance.eveningStartTime,
      'evening_end_time': instance.eveningEndTime,
      'has_evening': instance.hasEvening,
      'created_by': instance.createdBy,
      'alert_title': instance.alertTitle,
      'message': instance.alertMessage,
    };
