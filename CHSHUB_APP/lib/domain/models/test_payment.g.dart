// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestPayment _$TestPaymentFromJson(Map<String, dynamic> json) => TestPayment(
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      receipt: json['receipt'] as String?,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpaySignature: json['razorpaySignature'] as String?,
    );

Map<String, dynamic> _$TestPaymentToJson(TestPayment instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'currency': instance.currency,
      'receipt': instance.receipt,
      'razorpayOrderId': instance.razorpayOrderId,
      'razorpayPaymentId': instance.razorpayPaymentId,
      'razorpaySignature': instance.razorpaySignature,
    };
