import 'package:json_annotation/json_annotation.dart';
part 'owner_document.g.dart';

@JsonSerializable()
class OwnerDocument {
  @JsonKey(name: "vehicle_id")
  final int? vehicleId;
  @JsonKey(name: "vehicle_no")
  final String? vehicleNo;
  @JsonKey(name: "model_name")
  final String? modelName;
  @JsonKey(name: "society_id")
  final String? societyId;
  @JsonKey(name: 'flat_id')
  final int? flatId;
  @JsonKey(name:'owner_id')
  final int? ownerId;
  @JsonKey(name:'vehicle_type')
  final String? vehicleType;
 @JsonKey(name:'park_palce_id')
  final int? parkPlaceId;
 @JsonKey(name:'parking_status')
  final String? parkingStatus;
  OwnerDocument({
    this.vehicleType,
    this.vehicleId,
    this.vehicleNo,
    this.modelName,
    this.societyId,
    this.ownerId,
    this.flatId,
    this.parkPlaceId,
    this.parkingStatus,
  });

  factory OwnerDocument.fromJson(Map<String, dynamic> json) {
    return _$OwnerDocumentFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$OwnerDocumentToJson(this);
  }
}
