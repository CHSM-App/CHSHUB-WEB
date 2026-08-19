// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      details: json['details'] as String,
      payMode: json['pay_mode'] as String,
      type: json['type'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      balance: (json['balance'] as num).toDouble(),
      nMId: (json['n_m_id'] as num).toInt(),
      oId: (json['o_id'] as num).toInt(),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'details': instance.details,
      'pay_mode': instance.payMode,
      'type': instance.type,
      'total_amount': instance.totalAmount,
      'date': instance.date.toIso8601String(),
      'balance': instance.balance,
      'n_m_id': instance.nMId,
      'o_id': instance.oId,
    };
