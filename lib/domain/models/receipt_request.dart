import 'package:json_annotation/json_annotation.dart';

part 'receipt_request.g.dart';

/// Body of POST /api/web/billing/receipts.
///
/// `billNos` is the set of bills the payment settles. The server joins them
/// with commas into receipt.bill_details, which is nvarchar(20) — so a long
/// selection is rejected rather than silently truncated. The UI surfaces that
/// message as-is.
@JsonSerializable(includeIfNull: false)
class ReceiptRequest {
  @JsonKey(name: 'flatId')
  final int flatId;

  @JsonKey(name: 'paidAmount')
  final double paidAmount;

  /// 'Cash' | 'Cheque' | 'Online' — free text, max 20 chars server-side.
  @JsonKey(name: 'payMode')
  final String payMode;

  @JsonKey(name: 'billNos')
  final List<String> billNos;

  @JsonKey(name: 'chequeNo')
  final String? chequeNo;

  /// ISO yyyy-MM-dd.
  @JsonKey(name: 'chequeDate')
  final String? chequeDate;

  @JsonKey(name: 'bankName')
  final String? bankName;

  @JsonKey(name: 'transactionRef')
  final String? transactionRef;

  @JsonKey(name: 'remarks')
  final String? remarks;

  @JsonKey(name: 'receiptDate')
  final String? receiptDate;

  const ReceiptRequest({
    required this.flatId,
    required this.paidAmount,
    required this.payMode,
    required this.billNos,
    this.chequeNo,
    this.chequeDate,
    this.bankName,
    this.transactionRef,
    this.remarks,
    this.receiptDate,
  });

  factory ReceiptRequest.fromJson(Map<String, dynamic> json) =>
      _$ReceiptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptRequestToJson(this);
}
