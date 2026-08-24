// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptRequest _$ReceiptRequestFromJson(Map<String, dynamic> json) =>
    ReceiptRequest(
      flatId: (json['flatId'] as num).toInt(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      payMode: json['payMode'] as String,
      billNos: (json['billNos'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      chequeNo: json['chequeNo'] as String?,
      chequeDate: json['chequeDate'] as String?,
      bankName: json['bankName'] as String?,
      transactionRef: json['transactionRef'] as String?,
      remarks: json['remarks'] as String?,
      receiptDate: json['receiptDate'] as String?,
    );

Map<String, dynamic> _$ReceiptRequestToJson(ReceiptRequest instance) =>
    <String, dynamic>{
      'flatId': instance.flatId,
      'paidAmount': instance.paidAmount,
      'payMode': instance.payMode,
      'billNos': instance.billNos,
      'chequeNo': ?instance.chequeNo,
      'chequeDate': ?instance.chequeDate,
      'bankName': ?instance.bankName,
      'transactionRef': ?instance.transactionRef,
      'remarks': ?instance.remarks,
      'receiptDate': ?instance.receiptDate,
    };
