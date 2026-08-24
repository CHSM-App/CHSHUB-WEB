import 'package:json_annotation/json_annotation.dart';

part 'generate_bill_request.g.dart';

/// Body of POST /api/web/billing/generate/regular and /addon.
///
/// `confirm` is not optional in practice: both endpoints reject the call
/// without it, because generation raises real charges against every flat. The
/// UI shows GET /generate/preview first and sets this only after the secretary
/// accepts.
@JsonSerializable(includeIfNull: false)
class GenerateBillRequest {
  @JsonKey(name: 'confirm')
  final bool confirm;

  // ===== ADD-ON ONLY =====
  @JsonKey(name: 'duePeriodMonths')
  final int? duePeriodMonths;

  @JsonKey(name: 'interestRate')
  final double? interestRate;

  /// The add-on run blocks a second run on the same day; this overrides it.
  @JsonKey(name: 'allowDuplicate')
  final bool? allowDuplicate;

  const GenerateBillRequest({
    this.confirm = true,
    this.duePeriodMonths,
    this.interestRate,
    this.allowDuplicate,
  });

  factory GenerateBillRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateBillRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateBillRequestToJson(this);
}
