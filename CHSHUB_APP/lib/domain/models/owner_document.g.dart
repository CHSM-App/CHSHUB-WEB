// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnerDocument _$OwnerDocumentFromJson(Map<String, dynamic> json) =>
    OwnerDocument(
      vehicleType: json['vehicle_type'] as String?,
      vehicleId: (json['vehicle_id'] as num?)?.toInt(),
      vehicleNo: json['vehicle_no'] as String?,
      modelName: json['model_name'] as String?,
      societyId: json['society_id'] as String?,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      flatId: (json['flat_id'] as num?)?.toInt(),
      parkPlaceId: (json['park_palce_id'] as num?)?.toInt(),
      parkingStatus: json['parking_status'] as String?,
    );

Map<String, dynamic> _$OwnerDocumentToJson(OwnerDocument instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'vehicle_no': instance.vehicleNo,
      'model_name': instance.modelName,
      'society_id': instance.societyId,
      'flat_id': instance.flatId,
      'owner_id': instance.ownerId,
      'vehicle_type': instance.vehicleType,
      'park_palce_id': instance.parkPlaceId,
      'parking_status': instance.parkingStatus,
    };
