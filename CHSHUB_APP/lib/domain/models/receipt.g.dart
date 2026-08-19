// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Receipt _$ReceiptFromJson(Map<String, dynamic> json) => Receipt(
      societyId: json['society_id'] as String,
      flatId: (json['flat_id'] as num).toInt(),
      receiptDate: json['receipt_date'] as String?,
      payMode: json['pay_mode'] as String,
      chequeNo: json['cheque_no'] as String?,
      chequeDate: json['cheque_date'] as String?,
      bankName: json['bank_name'] as String?,
      transactionRef: json['transaction_ref'] as String?,
      billDetails: json['bill_details'] as String,
      paidAmount: (json['paid_amount'] as num).toDouble(),
      remarks: json['remarks'] as String?,
      status: (json['status'] as num).toInt(),
      createdBy: (json['created_by'] as num).toInt(),
      receiptId: (json['receipt_id'] as num?)?.toInt(),
      transaction: json['transaction'] as String?,
    );

Map<String, dynamic> _$ReceiptToJson(Receipt instance) => <String, dynamic>{
      'society_id': instance.societyId,
      'flat_id': instance.flatId,
      'receipt_date': instance.receiptDate,
      'pay_mode': instance.payMode,
      'cheque_no': instance.chequeNo,
      'cheque_date': instance.chequeDate,
      'bank_name': instance.bankName,
      'transaction_ref': instance.transactionRef,
      'bill_details': instance.billDetails,
      'paid_amount': instance.paidAmount,
      'remarks': instance.remarks,
      'status': instance.status,
      'created_by': instance.createdBy,
      'receipt_id': instance.receiptId,
      'transaction': instance.transaction,
    };
