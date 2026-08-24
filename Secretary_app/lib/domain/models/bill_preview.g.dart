// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillPreview _$BillPreviewFromJson(Map<String, dynamic> json) => BillPreview(
  flatCount: json['flatCount'] == null ? 0 : asIntOr(json['flatCount']),
  settings: json['settings'] == null
      ? const BillSettings()
      : BillPreview._settingsFromJson(json['settings']),
  regular: json['regular'] == null
      ? const ChargeGroup()
      : BillPreview._groupFromJson(json['regular']),
  addOn: json['addOn'] == null
      ? const ChargeGroup()
      : BillPreview._groupFromJson(json['addOn']),
  existingRuns: json['existingRuns'] == null
      ? 0
      : asIntOr(json['existingRuns']),
  alreadyGeneratedThisMonth: json['alreadyGeneratedThisMonth'] == null
      ? false
      : asBool(json['alreadyGeneratedThisMonth']),
  warnings: json['warnings'] == null
      ? const []
      : BillPreview._stringsFromJson(json['warnings']),
);

Map<String, dynamic> _$BillPreviewToJson(BillPreview instance) =>
    <String, dynamic>{
      'flatCount': instance.flatCount,
      'settings': instance.settings.toJson(),
      'regular': instance.regular.toJson(),
      'addOn': instance.addOn.toJson(),
      'existingRuns': instance.existingRuns,
      'alreadyGeneratedThisMonth': instance.alreadyGeneratedThisMonth,
      'warnings': instance.warnings,
    };

ChargeGroup _$ChargeGroupFromJson(Map<String, dynamic> json) => ChargeGroup(
  charges: json['charges'] == null
      ? const []
      : ChargeGroup._chargesFromJson(json['charges']),
  totalAmount: json['totalAmount'] == null
      ? 0
      : asDoubleOr(json['totalAmount']),
  perFlatTotal: json['perFlatTotal'] == null
      ? 0
      : asDoubleOr(json['perFlatTotal']),
);

Map<String, dynamic> _$ChargeGroupToJson(ChargeGroup instance) =>
    <String, dynamic>{
      'charges': instance.charges.map((e) => e.toJson()).toList(),
      'totalAmount': instance.totalAmount,
      'perFlatTotal': instance.perFlatTotal,
    };

ChargeHead _$ChargeHeadFromJson(Map<String, dynamic> json) => ChargeHead(
  chargeId: asInt(json['charge_id']),
  name: json['name'] as String?,
  amount: json['amount'] == null ? 0 : asDoubleOr(json['amount']),
  perFlat: json['perFlat'] == null ? 0 : asDoubleOr(json['perFlat']),
);

Map<String, dynamic> _$ChargeHeadToJson(ChargeHead instance) =>
    <String, dynamic>{
      'charge_id': instance.chargeId,
      'name': instance.name,
      'amount': instance.amount,
      'perFlat': instance.perFlat,
    };

BillSettings _$BillSettingsFromJson(Map<String, dynamic> json) => BillSettings(
  ratePerSqFt: json['ratePerSqFt'] == null
      ? 0
      : asDoubleOr(json['ratePerSqFt']),
  twoWheelerRate: json['twoWheelerRate'] == null
      ? 0
      : asDoubleOr(json['twoWheelerRate']),
  fourWheelerRate: json['fourWheelerRate'] == null
      ? 0
      : asDoubleOr(json['fourWheelerRate']),
  interestRate: json['interestRate'] == null
      ? 0
      : asDoubleOr(json['interestRate']),
  billGenerationDay: json['billGenerationDay'] == null
      ? 0
      : asIntOr(json['billGenerationDay']),
  billDuePeriodDays: json['billDuePeriodDays'] == null
      ? 0
      : asIntOr(json['billDuePeriodDays']),
  autoBillGeneration: json['autoBillGeneration'] == null
      ? false
      : asBool(json['autoBillGeneration']),
);

Map<String, dynamic> _$BillSettingsToJson(BillSettings instance) =>
    <String, dynamic>{
      'ratePerSqFt': instance.ratePerSqFt,
      'twoWheelerRate': instance.twoWheelerRate,
      'fourWheelerRate': instance.fourWheelerRate,
      'interestRate': instance.interestRate,
      'billGenerationDay': instance.billGenerationDay,
      'billDuePeriodDays': instance.billDuePeriodDays,
      'autoBillGeneration': instance.autoBillGeneration,
    };
