// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Facilities _$FacilitiesFromJson(Map<String, dynamic> json) => Facilities(
      userName: json['u_name'] as String?,
      token: json['Token'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      contact: json['contact'] as String?,
      flatNo: (json['flat_no'] as num?)?.toInt(),
      fromDate: json['from_date'] as String?,
      fromTime: json['from_time'] as String?,
      name: json['name'] as String?,
      toDate: json['to_date'] as String?,
      toTime: json['to_time'] as String?,
      facilityId: (json['facility_id'] as num?)?.toInt(),
      slotId: (json['slot_id'] as num?)?.toInt(),
      endTime: json['end_time'] as String?,
      startTime: json['start_time'] as String?,
      societyId: json['society_id'] as String?,
      status: (json['status'] as num?)?.toInt(),
      cost: (json['cost'] as num?)?.toInt(),
      description: json['description'] as String?,
      slot: (json['slot'] as num?)?.toInt(),
      activeStatus: (json['active_status'] as num?)?.toInt(),
      bookDate: json['book_date'] as String?,
      flatId: (json['flat_id'] as num?)?.toInt(),
      transactionRef: json['transaction_ref'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$FacilitiesToJson(Facilities instance) =>
    <String, dynamic>{
      'flat_no': instance.flatNo,
      'from_date': instance.fromDate,
      'Token': instance.token,
      'u_name': instance.userName,
      'from_time': instance.fromTime,
      'name': instance.name,
      'to_date': instance.toDate,
      'to_time': instance.toTime,
      'facility_id': instance.facilityId,
      'slot_id': instance.slotId,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'society_id': instance.societyId,
      'status': instance.status,
      'cost': instance.cost,
      'description': instance.description,
      'slot': instance.slot,
      'contact': instance.contact,
      'amount': instance.amount,
      'active_status': instance.activeStatus,
      'flat_id': instance.flatId,
      'book_date': instance.bookDate,
      'transaction_ref': instance.transactionRef,
      'note': instance.note,
    };
