import 'package:json_annotation/json_annotation.dart';

part 'pdc_request.g.dart';

/// Body of POST/PUT /api/web/billing/pdc — a post-dated cheque on file.
@JsonSerializable(includeIfNull: false)
class PdcRequest {
  @JsonKey(name: 'ownerId')
  final int? ownerId;

  /// The resident's wing. The API defaults it to 0 when absent, which files
  /// the cheque against no wing at all — so it travels with the owner.
  @JsonKey(name: 'wingId')
  final int? wingId;

  @JsonKey(name: 'chequeNo')
  final String? chequeNo;

  /// ISO yyyy-MM-dd — the date the cheque may be banked.
  @JsonKey(name: 'chequeDate')
  final String? chequeDate;

  @JsonKey(name: 'amount')
  final double? amount;

  @JsonKey(name: 'bankName')
  final String? bankName;

  @JsonKey(name: 'remarks')
  final String? remarks;

  @JsonKey(name: 'deposited')
  final bool? deposited;

  @JsonKey(name: 'returned')
  final bool? returned;

  @JsonKey(name: 'cancelled')
  final bool? cancelled;

  const PdcRequest({
    this.ownerId,
    this.wingId,
    this.chequeNo,
    this.chequeDate,
    this.amount,
    this.bankName,
    this.remarks,
    this.deposited,
    this.returned,
    this.cancelled,
  });

  factory PdcRequest.fromJson(Map<String, dynamic> json) =>
      _$PdcRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PdcRequestToJson(this);
}

/// Body of POST /api/web/billing/pdc/:id/clear.
///
/// `confirm` is mandatory when `deposited` is true: depositing also raises a
/// receipt, so the server refuses the call without an explicit acknowledgement.
@JsonSerializable(includeIfNull: false)
class PdcClearRequest {
  @JsonKey(name: 'deposited')
  final bool deposited;

  @JsonKey(name: 'returned')
  final bool returned;

  @JsonKey(name: 'cancelled')
  final bool cancelled;

  @JsonKey(name: 'confirm')
  final bool confirm;

  const PdcClearRequest({
    this.deposited = false,
    this.returned = false,
    this.cancelled = false,
    this.confirm = false,
  });

  factory PdcClearRequest.fromJson(Map<String, dynamic> json) =>
      _$PdcClearRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PdcClearRequestToJson(this);
}
