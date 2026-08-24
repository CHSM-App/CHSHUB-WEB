import 'package:json_annotation/json_annotation.dart';

import 'json_utils.dart';

part 'bill_preview.g.dart';

/// GET /api/web/billing/generate/preview.
///
/// Typed rather than read as a loose map, unlike most payloads in this app:
/// this one has a fixed shape the server builds by hand (see
/// backend/web/routes/billing/generation.js), and it is the screen a
/// secretary reads before writing charges that cannot be undone — worth
/// having the field names checked at compile time.
@JsonSerializable(explicitToJson: true)
class BillPreview {
  /// How many flats the run would bill.
  @JsonKey(name: 'flatCount', fromJson: asIntOr)
  final int flatCount;

  @JsonKey(name: 'settings', fromJson: _settingsFromJson)
  final BillSettings settings;

  /// The monthly charge heads — what gen_bill raises.
  @JsonKey(name: 'regular', fromJson: _groupFromJson)
  final ChargeGroup regular;

  /// One-off heads, billed by sp_new_maintenance instead.
  @JsonKey(name: 'addOn', fromJson: _groupFromJson)
  final ChargeGroup addOn;

  /// Bill runs already on file for this society.
  @JsonKey(name: 'existingRuns', fromJson: asIntOr)
  final int existingRuns;

  /// True when a regular run has already gone out this month, in which case
  /// gen_bill will skip it.
  @JsonKey(name: 'alreadyGeneratedThisMonth', fromJson: asBool)
  final bool alreadyGeneratedThisMonth;

  /// Things to read before generating. Shown verbatim — the server words
  /// these, and they explain why a run might do nothing.
  @JsonKey(name: 'warnings', fromJson: _stringsFromJson)
  final List<String> warnings;

  const BillPreview({
    this.flatCount = 0,
    this.settings = const BillSettings(),
    this.regular = const ChargeGroup(),
    this.addOn = const ChargeGroup(),
    this.existingRuns = 0,
    this.alreadyGeneratedThisMonth = false,
    this.warnings = const [],
  });

  factory BillPreview.fromJson(Map<String, dynamic> json) =>
      _$BillPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$BillPreviewToJson(this);

  /// What the run would raise in total, across both kinds of charge.
  double get grandTotal => regular.totalAmount + addOn.totalAmount;

  double get perFlatTotal => regular.perFlatTotal + addOn.perFlatTotal;

  bool get hasAnythingToBill =>
      regular.charges.isNotEmpty || addOn.charges.isNotEmpty;

  static BillSettings _settingsFromJson(dynamic v) =>
      v is Map ? BillSettings.fromJson(asRow(v)) : const BillSettings();

  static ChargeGroup _groupFromJson(dynamic v) =>
      v is Map ? ChargeGroup.fromJson(asRow(v)) : const ChargeGroup();

  static List<String> _stringsFromJson(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];
}

/// A set of charge heads and their totals.
@JsonSerializable(explicitToJson: true)
class ChargeGroup {
  @JsonKey(name: 'charges', fromJson: _chargesFromJson)
  final List<ChargeHead> charges;

  @JsonKey(name: 'totalAmount', fromJson: asDoubleOr)
  final double totalAmount;

  @JsonKey(name: 'perFlatTotal', fromJson: asDoubleOr)
  final double perFlatTotal;

  const ChargeGroup({
    this.charges = const [],
    this.totalAmount = 0,
    this.perFlatTotal = 0,
  });

  factory ChargeGroup.fromJson(Map<String, dynamic> json) =>
      _$ChargeGroupFromJson(json);

  Map<String, dynamic> toJson() => _$ChargeGroupToJson(this);

  static List<ChargeHead> _chargesFromJson(dynamic v) => v is List
      ? v.map((e) => ChargeHead.fromJson(asRow(e))).toList()
      : const [];
}

/// One charge head — "sinking", "gardening".
@JsonSerializable()
class ChargeHead {
  @JsonKey(name: 'charge_id', fromJson: asInt)
  final int? chargeId;

  @JsonKey(name: 'name')
  final String? name;

  /// The whole society's share of this head.
  @JsonKey(name: 'amount', fromJson: asDoubleOr)
  final double amount;

  /// Already divided by the flat count, server-side.
  @JsonKey(name: 'perFlat', fromJson: asDoubleOr)
  final double perFlat;

  const ChargeHead({
    this.chargeId,
    this.name,
    this.amount = 0,
    this.perFlat = 0,
  });

  factory ChargeHead.fromJson(Map<String, dynamic> json) =>
      _$ChargeHeadFromJson(json);

  Map<String, dynamic> toJson() => _$ChargeHeadToJson(this);
}

/// The society's billing configuration, as the run will apply it.
@JsonSerializable()
class BillSettings {
  @JsonKey(name: 'ratePerSqFt', fromJson: asDoubleOr)
  final double ratePerSqFt;

  @JsonKey(name: 'twoWheelerRate', fromJson: asDoubleOr)
  final double twoWheelerRate;

  @JsonKey(name: 'fourWheelerRate', fromJson: asDoubleOr)
  final double fourWheelerRate;

  @JsonKey(name: 'interestRate', fromJson: asDoubleOr)
  final double interestRate;

  /// Day of the month the automatic run fires on.
  @JsonKey(name: 'billGenerationDay', fromJson: asIntOr)
  final int billGenerationDay;

  @JsonKey(name: 'billDuePeriodDays', fromJson: asIntOr)
  final int billDuePeriodDays;

  @JsonKey(name: 'autoBillGeneration', fromJson: asBool)
  final bool autoBillGeneration;

  const BillSettings({
    this.ratePerSqFt = 0,
    this.twoWheelerRate = 0,
    this.fourWheelerRate = 0,
    this.interestRate = 0,
    this.billGenerationDay = 0,
    this.billDuePeriodDays = 0,
    this.autoBillGeneration = false,
  });

  factory BillSettings.fromJson(Map<String, dynamic> json) =>
      _$BillSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$BillSettingsToJson(this);
}
