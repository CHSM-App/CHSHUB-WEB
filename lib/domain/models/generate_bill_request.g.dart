// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_bill_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateBillRequest _$GenerateBillRequestFromJson(Map<String, dynamic> json) =>
    GenerateBillRequest(
      confirm: json['confirm'] as bool? ?? true,
      duePeriodMonths: (json['duePeriodMonths'] as num?)?.toInt(),
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      allowDuplicate: json['allowDuplicate'] as bool?,
    );

Map<String, dynamic> _$GenerateBillRequestToJson(
  GenerateBillRequest instance,
) => <String, dynamic>{
  'confirm': instance.confirm,
  'duePeriodMonths': ?instance.duePeriodMonths,
  'interestRate': ?instance.interestRate,
  'allowDuplicate': ?instance.allowDuplicate,
};
