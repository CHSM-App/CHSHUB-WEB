import 'package:json_annotation/json_annotation.dart';
part 'due_History.g.dart';

@JsonSerializable()
class DueHistory {
  @JsonKey(name: 'n_m_id')
  final int? n_M_Id;

  @JsonKey(name: 'owner_id')
  final int? owner_Id;

  @JsonKey(name: 'receipt_id')
  final int? receipt_Id;

  final String? date; // "2025-08-05T00:00:00.000Z"

  @JsonKey(name: 'total_amount')
  final double? total_Amount;

  final double? amount;
  @JsonKey(name:'bill_ref')
final String? billRef;
  final String? type; // "Owner"

  // @JsonKey(name: 'pay_mode')
  // final int? pay_Mode; // API gives 2 (int)

  @JsonKey(name: 'due_date')
  final String? due_Date;

  @JsonKey(name: 'due_name')
  final String? due_Name;

  // ✅ New fields from your JSON
  @JsonKey(name: 'receipt_no')
  final String? receipt_No; // "RPT0015"

  @JsonKey(name: 'bill_no')
  final int? bill_No; // 8

  @JsonKey(name: 'build_id')
  final int? build_Id; // 1

  @JsonKey(name: 'build_name')
  final String? build_Name; // "Arambh Chs"

  @JsonKey(name: 'wing_id')
  final int? wing_Id; // 4

  @JsonKey(name: 'w_name')
  final String? w_Name; // "A-2"

  final String? address1; // "Adeli"
  final String? address2; // "Kutwalwadi"

  @JsonKey(name: 'print_name')
  final String? print_Name; // "Petronas Tower"

  @JsonKey(name: 'registration_no')
  final String? registration_No; // "13000"

  @JsonKey(name: 'pay_mode_name')
  final String? pay_Mode_Name; // "Cheque"

  final String? chqno; // "123123123123"
  final String? remarks; // ""

  @JsonKey(name: 'society_id')
  final String? society_Id; // "C10001"

  @JsonKey(name: 'flat_no')
  final String? flat_No; // "104"

  final String? name; // "Sagar Dhargalkar"

  @JsonKey(name: 'received_amt')
  final double? received_Amt; // 2345 (int but safe as double)

  final String? email; // "dharaglkarsagar@gmail.com"

  @JsonKey(name: 'Building_wing')
  final String? building_Wing; // "Arambh Chs  ,  A-2"

  final String? dob; // "1995-05-20T00:00:00.000Z"

  @JsonKey(name: 'pre_mob')
  final String? pre_Mob; // "8262878298"

  @JsonKey(name: 'society_name')
  final String? society_Name; // "Gokuldham"

  @JsonKey(name: 'Full_name')
  final String? full_Name; // "A-2,Arambh Chs-Adeli,Kutwalwadi"

  final String? chqdate; // "2025-08-06T00:00:00.000Z

  final String? timestamp; // "2025-08-05T13:54:00.000Z"
    @JsonKey(name: "bill_id")
  final int? billId;
  @JsonKey(name: "bill_type")
  final int? billType;
    @JsonKey(name: 'paid_amount')
  final double? paidAmount;
   @JsonKey(name: 'unit')
  final String? unit; 
 @JsonKey(name: 'pay_mode')
  final String? payMode;
   @JsonKey(name: 'status')
  final String? status ;
  @JsonKey(name:'transaction')
  final String? transaction;
  @JsonKey(name:'bill_status')
  final String? billStatus;
    @JsonKey(name: 'transaction_ref')
  final String? transactionRef;
    @JsonKey(name: 'Billno')
  final String? billno;
    @JsonKey(name: 'due')
  final double? due;
    @JsonKey(name: 'seen_status')
  final int? seenStatus;
   @JsonKey(name: 'notify_status_id')
  final int? notifyStatusId;
  @JsonKey(name: 'tax_interest_amt')
  final double? taxInterestAmt;


  DueHistory({
    this.n_M_Id,
    this.owner_Id,
    this.receipt_Id,
    this.date,
    this.total_Amount,
    this.type,
    this.due_Date,
    this.due_Name,
    this.receipt_No,
    this.bill_No,
    this.build_Id,
    this.build_Name,
    this.wing_Id,
    this.w_Name,
    this.address1,
    this.address2,
    this.print_Name,
    this.registration_No,
    this.pay_Mode_Name,
    this.chqno,
    this.remarks,
    this.society_Id,
    this.flat_No,
    this.name,
    this.received_Amt,
    this.email,
    this.building_Wing,
    this.dob,
    this.pre_Mob,
    this.society_Name,
    this.full_Name,
    this.chqdate,
    this.timestamp,
    this.billId,
    this.billType,
    this.paidAmount,
    this.unit,
    this.payMode,
    this.status,
    this.transaction,
    this.billStatus,
    this.amount,
    this.billRef,
    this.transactionRef,
    this.billno,
    this.due,
    this.seenStatus,
    this.notifyStatusId,
    this.taxInterestAmt

  });

  factory DueHistory.fromJson(Map<String, dynamic> json) =>
      _$DueHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$DueHistoryToJson(this);
}
