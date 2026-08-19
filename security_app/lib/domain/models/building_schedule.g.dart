// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildingSchedule _$BuildingScheduleFromJson(Map<String, dynamic> json) =>
    BuildingSchedule(
      building: json['building'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );

Map<String, dynamic> _$BuildingScheduleToJson(BuildingSchedule instance) =>
    <String, dynamic>{
      'building': instance.building,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
    };
