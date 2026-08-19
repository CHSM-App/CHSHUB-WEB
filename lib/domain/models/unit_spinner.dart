import 'package:json_annotation/json_annotation.dart';

part 'unit_spinner.g.dart';

@JsonSerializable()
class UnitSpinner {
  final String unit;

  @JsonKey(name: 'flat_id')
  final int flatId;

  UnitSpinner({
    required this.unit,
    required this.flatId,
  });

  factory UnitSpinner.fromJson(Map<String, dynamic> json) =>
      _$UnitSpinnerFromJson(json);

  Map<String, dynamic> toJson() => _$UnitSpinnerToJson(this);
}
