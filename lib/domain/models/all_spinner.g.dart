// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_spinner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllSpinner _$AllSpinnerFromJson(Map<String, dynamic> json) => AllSpinner(
      pTypeName: json['p_type_name'] as String?,
      pTypeId: (json['p_type_id'] as num?)?.toInt(),
      vTypeId: (json['v_type_id'] as num?)?.toInt(),
      vTypeName: json['v_type_name'] as String?,
      fId: (json['f_id'] as num?)?.toInt(),
      block: json['block'] as String?,
      placeId: (json['place_id'] as num?)?.toInt(),
      parkingNo: json['parking_no'] as String?,
      societyId: json['society_id'] as String?,
      cTypeId: (json['c_type_id'] as num?)?.toInt(),
      cTypeName: json['c_type_name'] as String?,
      decription: json['decription'] as String?,
    );

Map<String, dynamic> _$AllSpinnerToJson(AllSpinner instance) =>
    <String, dynamic>{
      'v_type_id': instance.vTypeId,
      'v_type_name': instance.vTypeName,
      'f_id': instance.fId,
      'block': instance.block,
      'place_id': instance.placeId,
      'parking_no': instance.parkingNo,
      'society_id': instance.societyId,
      'p_type_name': instance.pTypeName,
      'p_type_id': instance.pTypeId,
      'c_type_id': instance.cTypeId,
      'c_type_name': instance.cTypeName,
      'decription': instance.decription,
    };
