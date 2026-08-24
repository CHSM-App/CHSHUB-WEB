// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VisitorRequest _$VisitorRequestFromJson(Map<String, dynamic> json) =>
    VisitorRequest(
      name: json['name'] as String,
      type: json['type'] as String,
      contactNo: json['contactNo'] as String?,
      flatId: (json['flatId'] as num?)?.toInt(),
      buildId: (json['buildId'] as num?)?.toInt(),
      vehicleNo: json['vehicleNo'] as String?,
      company: json['company'] as String?,
      location: json['location'] as String?,
      purpose: json['purpose'] as String?,
      preference: json['preference'] as String?,
      image: json['image'] as String?,
      inDate: json['inDate'] as String?,
      outDate: json['outDate'] as String?,
      expectedDate: json['expectedDate'] as String?,
      inTime: json['inTime'] as String?,
      outTime: json['outTime'] as String?,
      status: (json['status'] as num?)?.toInt(),
      ownerId: (json['ownerId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VisitorRequestToJson(VisitorRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'contactNo': ?instance.contactNo,
      'flatId': ?instance.flatId,
      'buildId': ?instance.buildId,
      'vehicleNo': ?instance.vehicleNo,
      'company': ?instance.company,
      'location': ?instance.location,
      'purpose': ?instance.purpose,
      'preference': ?instance.preference,
      'image': ?instance.image,
      'inDate': ?instance.inDate,
      'outDate': ?instance.outDate,
      'expectedDate': ?instance.expectedDate,
      'inTime': ?instance.inTime,
      'outTime': ?instance.outTime,
      'status': ?instance.status,
      'ownerId': ?instance.ownerId,
    };
