// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Maintenance _$MaintenanceFromJson(Map<String, dynamic> json) => Maintenance(
      nMId: (json['n_m_id'] as num?)?.toInt(),
      sqFt: json['sq_ft'] as String?,
      amtForward: (json['amt_forward'] as num?)?.toDouble(),
      taxInterestAmt: (json['tax_interest_amt'] as num?)?.toDouble(),
      buildName: json['build_name'] as String?,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      ownerName: json['owner_name'] as String?,
      wName: json['w_name'] as String?,
      flatNo: json['flat_no'] as String?,
      billNo: (json['bill_no'] as num?)?.toInt(),
      genDate: json['gen_date'] as String?,
      dueDate: json['due_date'] as String?,
      societyName: json['society_name'] as String?,
      registrationNo: json['registration_no'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      printName: json['print_name'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      name: json['name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      advance: (json['advance'] as num?)?.toDouble(),
      terms: json['terms'] as String?,
      charges: (json['charges'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      billId: (json['bill_id'] as num?)?.toInt(),
      due: json['due'] as String?,
    );

Map<String, dynamic> _$MaintenanceToJson(Maintenance instance) =>
    <String, dynamic>{
      'n_m_id': instance.nMId,
      'sq_ft': instance.sqFt,
      'amt_forward': instance.amtForward,
      'tax_interest_amt': instance.taxInterestAmt,
      'build_name': instance.buildName,
      'owner_id': instance.ownerId,
      'owner_name': instance.ownerName,
      'w_name': instance.wName,
      'flat_no': instance.flatNo,
      'bill_no': instance.billNo,
      'gen_date': instance.genDate,
      'due_date': instance.dueDate,
      'society_name': instance.societyName,
      'registration_no': instance.registrationNo,
      'address1': instance.address1,
      'address2': instance.address2,
      'print_name': instance.printName,
      'total_amount': instance.totalAmount,
      'name': instance.name,
      'amount': instance.amount,
      'advance': instance.advance,
      'terms': instance.terms,
      'charges': instance.charges,
      'bill_id': instance.billId,
      'due': instance.due,
    };
