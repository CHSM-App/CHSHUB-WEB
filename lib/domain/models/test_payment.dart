import 'package:json_annotation/json_annotation.dart';
part 'test_payment.g.dart';
@JsonSerializable()
class TestPayment {

  final double? amount ;
final String? currency;
final String? receipt;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  TestPayment({
    this.amount,
    this.currency,
    this.receipt,
    this.razorpayOrderId,
     this.razorpayPaymentId,
     this.razorpaySignature,
  });
  
  factory TestPayment.fromJson(Map<String, dynamic> json) =>
      _$TestPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$TestPaymentToJson(this);
}
