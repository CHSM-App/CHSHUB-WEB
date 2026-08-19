// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staffs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Staffs _$StaffsFromJson(Map<String, dynamic> json) => Staffs(
  staffId: (json['staff_id'] as num).toInt(),
  name: json['name'] as String,
  address: json['address'] as String,
  contactNo: json['contact_no'] as String,
  email: json['email'] as String,
  dateOfJoin: json['date_of_join'] as String,
  bId: (json['b_id'] as num).toInt(),
  buildName: json['build_name'] as String,
  role: json['Role'] as String,
  societyId: json['society_id'] as String,
  inDate: json['in_date'] as String,
  inTime: json['in_time'] as String,
  outDate: json['out_date'] as String,
  outTime: json['out_time'] as String,
  image: json['image'] as String,
  id: (json['id'] as num).toInt(),
);

Map<String, dynamic> _$StaffsToJson(Staffs instance) => <String, dynamic>{
  'staff_id': instance.staffId,
  'name': instance.name,
  'address': instance.address,
  'contact_no': instance.contactNo,
  'email': instance.email,
  'date_of_join': instance.dateOfJoin,
  'b_id': instance.bId,
  'build_name': instance.buildName,
  'Role': instance.role,
  'society_id': instance.societyId,
  'in_date': instance.inDate,
  'in_time': instance.inTime,
  'out_date': instance.outDate,
  'out_time': instance.outTime,
  'image': instance.image,
  'id': instance.id,
};
