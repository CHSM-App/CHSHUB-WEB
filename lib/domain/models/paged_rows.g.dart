// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_rows.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RowList _$RowListFromJson(Map<String, dynamic> json) => RowList(
  items: json['items'] == null ? const [] : asRows(json['items']),
  count: json['count'] == null ? 0 : asIntOr(json['count']),
  totalCollected: asDouble(json['totalCollected']),
  totalDue: asDouble(json['totalDue']),
  flats: asInt(json['flats']),
);

Map<String, dynamic> _$RowListToJson(RowList instance) => <String, dynamic>{
  'items': instance.items,
  'count': instance.count,
  'totalCollected': instance.totalCollected,
  'totalDue': instance.totalDue,
  'flats': instance.flats,
};
