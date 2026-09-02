// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noc_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NocRequest _$NocRequestFromJson(Map<String, dynamic> json) => NocRequest(
      requestId: (json['request_id'] as num?)?.toInt(),
      societyId: json['society_id'] as String?,
      flatId: (json['flat_id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      memberName: json['member_name'] as String?,
      flatNo: json['flat_no'] as String?,
      buildingName: json['building_name'] as String?,
      nocType: json['noc_type'] as String?,
      customTitle: json['custom_title'] as String?,
      purpose: json['purpose'] as String?,
      status: (json['status'] as num?)?.toInt(),
      serialNo: json['serial_no'] as String?,
      clause: json['clause'] as String?,
      remarks: json['remarks'] as String?,
      requestedOn: json['requested_on'] as String?,
      approvedOn: json['approved_on'] as String?,
      rejectReason: json['reject_reason'] as String?,
      collectionDate: json['collection_date'] as String?,
      collectionTime: json['collection_time'] as String?,
      collectionNote: json['collection_note'] as String?,
      collectedOn: json['collected_on'] as String?,
      collectedBy: json['collected_by'] as String?,
      validTill: json['valid_till'] as String?,
    );

Map<String, dynamic> _$NocRequestToJson(NocRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('request_id', instance.requestId);
  writeNotNull('society_id', instance.societyId);
  writeNotNull('flat_id', instance.flatId);
  writeNotNull('user_id', instance.userId);
  writeNotNull('member_name', instance.memberName);
  writeNotNull('flat_no', instance.flatNo);
  writeNotNull('building_name', instance.buildingName);
  writeNotNull('noc_type', instance.nocType);
  writeNotNull('custom_title', instance.customTitle);
  writeNotNull('purpose', instance.purpose);
  writeNotNull('status', instance.status);
  writeNotNull('serial_no', instance.serialNo);
  writeNotNull('clause', instance.clause);
  writeNotNull('remarks', instance.remarks);
  writeNotNull('requested_on', instance.requestedOn);
  writeNotNull('approved_on', instance.approvedOn);
  writeNotNull('reject_reason', instance.rejectReason);
  writeNotNull('collection_date', instance.collectionDate);
  writeNotNull('collection_time', instance.collectionTime);
  writeNotNull('collection_note', instance.collectionNote);
  writeNotNull('collected_on', instance.collectedOn);
  writeNotNull('collected_by', instance.collectedBy);
  writeNotNull('valid_till', instance.validTill);
  return val;
}
