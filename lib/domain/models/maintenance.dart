import 'package:json_annotation/json_annotation.dart';

part 'maintenance.g.dart';

@JsonSerializable()
class Maintenance {
  @JsonKey(name: "n_m_id")
  final int? nMId;

  @JsonKey(name: "sq_ft")
  final String? sqFt;

  @JsonKey(name: "amt_forward")
  final double? amtForward;

  @JsonKey(name: "tax_interest_amt")
  final double? taxInterestAmt;

  @JsonKey(name: "build_name")
  final String? buildName;

  @JsonKey(name: "owner_id")
  final int? ownerId;

  @JsonKey(name: "owner_name")
  final String? ownerName;

  @JsonKey(name: "w_name")
  final String? wName;

  @JsonKey(name: "flat_no")
  final String? flatNo;

  @JsonKey(name: "bill_no")
  final int? billNo;

  @JsonKey(name: "gen_date")
  final String? genDate;

  @JsonKey(name: "due_date")
  final String? dueDate;

  @JsonKey(name: "society_name")
  final String? societyName;

  @JsonKey(name: "registration_no")
  final String? registrationNo;

  @JsonKey(name: "address1")
  final String? address1;

  @JsonKey(name: "address2")
  final String? address2;

  @JsonKey(name: "print_name")
  final String? printName;

  @JsonKey(name: "total_amount")
  final double? totalAmount;

  @JsonKey(name: "name")
  final String? name;

  @JsonKey(name: "amount")
  final double? amount;

  final double? advance;
  @JsonKey(name: "terms")
  final String? terms;
  final Map<String, double> charges;

    @JsonKey(name: "bill_id")
  final int? billId;
    @JsonKey(name: "due")
  final String? due;
    @JsonKey(name: "bill_status")
  final String? billStatus;
  Maintenance({
    this.nMId,
    this.sqFt,
    this.amtForward,
    this.taxInterestAmt,
    this.buildName,
    this.ownerId,
    this.ownerName,
    this.wName,
    this.flatNo,
    this.billNo,
    this.genDate,
    this.dueDate,
    this.societyName,
    this.registrationNo,
    this.address1,
    this.address2,
    this.printName,
    this.totalAmount,
    this.name,
    this.amount,
    this.advance,
    this.terms,
    required this.charges,
    this.billId,
    this.due,
    this.billStatus,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    final Map<String, double> extractedCharges = {};
    for (int i = 1; i <= 30; i++) {
      final name = json['col${i}_name'];
      final amount = json['col${i}_amount'];
      if (name != null &&
          name.toString().trim().isNotEmpty &&
          amount != null &&
          amount != 0) {
        extractedCharges[name] = (amount as num).toDouble();
      }
    }
    return Maintenance(
      nMId: json['n_m_id'] as int?,
      sqFt: json['sq_ft'] as String?,
      amtForward: (json['amt_forward'] as num?)?.toDouble(),
      taxInterestAmt: (json['tax_interest_amt'] as num?)?.toDouble(),
      buildName: json['build_name'] as String?,
      ownerId: json['owner_id'] as int?,
      ownerName: json['owner_name'] as String?,
      wName: json['w_name'] as String?,
      flatNo: json['flat_no'] as String?,
      billNo: json['bill_no'] as int?,
      genDate: json['gen_date'] as String?,
      dueDate: json['due_date'] as String?,
      societyName: json['society_name'] as String?,
      registrationNo: json['registration_no'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      printName: json['print_name'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      name: json['name'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      terms: json['terms'] as String?,
      charges: extractedCharges,
      billId: json['bill_id'] as int?,
      due: json['due']?.toString(),
      billStatus: json['bill_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$MaintenanceToJson(this);

}
