import 'package:json_annotation/json_annotation.dart';

part 'all_spinner.g.dart';

@JsonSerializable()
class AllSpinner {
  @JsonKey(name: 'v_type_id')
  final int? vTypeId;

  @JsonKey(name: 'v_type_name')
  final String? vTypeName;

  @JsonKey(name: 'f_id')
  final int? fId;

  final String? block;

  @JsonKey(name: 'place_id')
  final int? placeId;

  @JsonKey(name: 'parking_no')
  final String? parkingNo;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'p_type_name')
  final String? pTypeName;

  @JsonKey(name: 'p_type_id')
  final int? pTypeId;
  @JsonKey(name: 'c_type_id')
  final int? cTypeId;

    @JsonKey(name: 'c_type_name')
  final String? cTypeName;
  
    @JsonKey(name: 'decription')
  final String? decription;

  AllSpinner({
    this.pTypeName,
    this.pTypeId,
    this.vTypeId,
    this.vTypeName,
    this.fId,
    this.block,
    this.placeId,
    this.parkingNo,
    this.societyId,
    this.cTypeId,
    this.cTypeName,
    this.decription
  });

  factory AllSpinner.fromJson(Map<String, dynamic> json) =>
      _$AllSpinnerFromJson(json);

  Map<String, dynamic> toJson() => _$AllSpinnerToJson(this);
}
