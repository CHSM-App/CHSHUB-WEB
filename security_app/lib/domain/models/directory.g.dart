// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Directory _$DirectoryFromJson(Map<String, dynamic> json) => Directory(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  contact: json['contact'] as String?,
  email: json['email'] as String,
  unit: json['Unit'] as String,
);

Map<String, dynamic> _$DirectoryToJson(Directory instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'contact': instance.contact,
  'email': instance.email,
  'Unit': instance.unit,
};
