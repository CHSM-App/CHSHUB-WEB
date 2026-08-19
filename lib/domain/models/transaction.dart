import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  final String details;

  @JsonKey(name: 'pay_mode')
  final String payMode;

  final String type;

  @JsonKey(name: 'total_amount')
  final double totalAmount;

  final DateTime date;
  

  final double balance;

  @JsonKey(name: 'n_m_id')
  final int nMId;

  @JsonKey(name: 'o_id')
  final int oId;

  Transaction({
    required this.details,
    required this.payMode,
    required this.type,
    required this.totalAmount,
    required this.date,
    required this.balance,
    required this.nMId,
    required this.oId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
