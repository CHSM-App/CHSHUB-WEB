import 'package:json_annotation/json_annotation.dart';

part 'building_schedule.g.dart';

@JsonSerializable()
class BuildingSchedule {
  @JsonKey(name: "building")
  String building;

  @JsonKey(name: "start_time")
  DateTime startTime;

  @JsonKey(name: "end_time")
  DateTime endTime;

  BuildingSchedule({
    required this.building,
    required this.startTime,
    required this.endTime,
  });

  factory BuildingSchedule.fromJson(Map<String, dynamic> json) =>
      _$BuildingScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$BuildingScheduleToJson(this);
}
