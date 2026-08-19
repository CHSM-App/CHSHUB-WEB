// models/receipt.dart
import 'package:json_annotation/json_annotation.dart';

part 'receipt.g.dart';

@JsonSerializable()
class Receipt {
  @JsonKey(name: 'society_id')
  final String societyId;
  @JsonKey(name: 'flat_id')
  final int flatId;
   @JsonKey(name: 'receipt_date')
  final String? receiptDate;
   @JsonKey(name: 'pay_mode')
  final String payMode;
   @JsonKey(name: 'cheque_no')
  final String? chequeNo;
   @JsonKey(name: 'cheque_date')
  final String? chequeDate;
   @JsonKey(name: 'bank_name')
  final String? bankName;
   @JsonKey(name: 'transaction_ref')
  final String? transactionRef;
   @JsonKey(name: 'bill_details')
  final String billDetails;
   @JsonKey(name: 'paid_amount')
  final double paidAmount;
   @JsonKey(name: 'remarks')
  final String? remarks;
   @JsonKey(name: 'status')
  final int status;
   @JsonKey(name: 'created_by')
  final int createdBy;
 @JsonKey(name: 'receipt_id')
  final int? receiptId;
  @JsonKey(name:'transaction')
  final String? transaction;

  Receipt({
    required this.societyId,
    required this.flatId,
    this.receiptDate,
    required this.payMode,
    this.chequeNo,
    this.chequeDate,
    this.bankName,
    this.transactionRef,
    required this.billDetails,
    required this.paidAmount,
    this.remarks,
    required this.status,
    required this.createdBy,
   this.receiptId,
   this.transaction
  });

 
  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptToJson(this);
}
