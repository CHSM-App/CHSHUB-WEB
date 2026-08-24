// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseRequest _$ExpenseRequestFromJson(Map<String, dynamic> json) =>
    ExpenseRequest(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      date: json['date'] as String?,
      expenseType: json['expenseType'] as String?,
      details: json['details'] as String?,
      comments: json['comments'] as String?,
      tax: (json['tax'] as num?)?.toDouble(),
      tds: (json['tds'] as num?)?.toDouble(),
      regular: (json['regular'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExpenseRequestToJson(ExpenseRequest instance) =>
    <String, dynamic>{
      'date': ?instance.date,
      'expenseType': ?instance.expenseType,
      'name': instance.name,
      'details': ?instance.details,
      'comments': ?instance.comments,
      'amount': instance.amount,
      'tax': ?instance.tax,
      'tds': ?instance.tds,
      'finalAmount': instance.finalAmount,
      'regular': ?instance.regular,
    };
