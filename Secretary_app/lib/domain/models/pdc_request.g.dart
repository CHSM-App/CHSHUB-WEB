// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdc_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PdcRequest _$PdcRequestFromJson(Map<String, dynamic> json) => PdcRequest(
  ownerId: (json['ownerId'] as num?)?.toInt(),
  wingId: (json['wingId'] as num?)?.toInt(),
  chequeNo: json['chequeNo'] as String?,
  chequeDate: json['chequeDate'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  bankName: json['bankName'] as String?,
  remarks: json['remarks'] as String?,
  deposited: json['deposited'] as bool?,
  returned: json['returned'] as bool?,
  cancelled: json['cancelled'] as bool?,
);

Map<String, dynamic> _$PdcRequestToJson(PdcRequest instance) =>
    <String, dynamic>{
      'ownerId': ?instance.ownerId,
      'wingId': ?instance.wingId,
      'chequeNo': ?instance.chequeNo,
      'chequeDate': ?instance.chequeDate,
      'amount': ?instance.amount,
      'bankName': ?instance.bankName,
      'remarks': ?instance.remarks,
      'deposited': ?instance.deposited,
      'returned': ?instance.returned,
      'cancelled': ?instance.cancelled,
    };

PdcClearRequest _$PdcClearRequestFromJson(Map<String, dynamic> json) =>
    PdcClearRequest(
      deposited: json['deposited'] as bool? ?? false,
      returned: json['returned'] as bool? ?? false,
      cancelled: json['cancelled'] as bool? ?? false,
      confirm: json['confirm'] as bool? ?? false,
    );

Map<String, dynamic> _$PdcClearRequestToJson(PdcClearRequest instance) =>
    <String, dynamic>{
      'deposited': instance.deposited,
      'returned': instance.returned,
      'cancelled': instance.cancelled,
      'confirm': instance.confirm,
    };
