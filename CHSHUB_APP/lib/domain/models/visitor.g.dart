// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Visitor _$VisitorFromJson(Map<String, dynamic> json) => Visitor(
      buildId: (json['build_id'] as num?)?.toInt(),
      flatId: (json['flat_id'] as num?)?.toInt(),
      inDate: json['in_date'] as String?,
      inTime: json['in_time'] as String?,
      outDate: json['out_date'] as String?,
      outTime: json['out_time'] as String?,
      societyId: json['society_id'] as String?,
      visitorId: (json['visitor_id'] as num?)?.toInt(),
      vName: json['v_name'] as String?,
      preDate: json['pre_date'] as String?,
      vehicleNo: json['vehicle_no'] as String?,
      contactNo: json['contact_no'] as String?,
      type: json['type'] as String?,
      preference: json['preference'] as String?,
      userName: json['UserName'] as String?,
      image: json['image'] as String?,
      status: (json['status'] as num?)?.toInt(),
      approverName: json['Approver_Name'] as String?,
      gateOtp: (json['gateOtp'] as num?)?.toInt(),
      company: json['company'] as String?,
      purpose: json['purpose'] as String?,
      ownerId: (json['owner_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VisitorToJson(Visitor instance) => <String, dynamic>{
      'build_id': instance.buildId,
      'flat_id': instance.flatId,
      'in_date': instance.inDate,
      'in_time': instance.inTime,
      'out_date': instance.outDate,
      'out_time': instance.outTime,
      'society_id': instance.societyId,
      'visitor_id': instance.visitorId,
      'v_name': instance.vName,
      'pre_date': instance.preDate,
      'vehicle_no': instance.vehicleNo,
      'contact_no': instance.contactNo,
      'type': instance.type,
      'preference': instance.preference,
      'UserName': instance.userName,
      'image': instance.image,
      'status': instance.status,
      'Approver_Name': instance.approverName,
      'gateOtp': instance.gateOtp,
      'company': instance.company,
      'purpose': instance.purpose,
      'owner_id': instance.ownerId,
    };
