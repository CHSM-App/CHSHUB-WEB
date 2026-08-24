import 'package:json_annotation/json_annotation.dart';

import 'json_utils.dart';

part 'paged_rows.g.dart';

/// The website API's list envelope: `{ items, count, ... }`.
///
/// Many of these lists come from stored procedures that build their column set
/// dynamically (sp_maintanance_cal pivots each society's charge heads, so the
/// columns differ per society). Typing those rows would mean a model that is
/// wrong for the next society, so the rows stay as maps and the screens read
/// the keys they need.
@JsonSerializable()
class RowList {
  @JsonKey(name: 'items', fromJson: asRows)
  final List<Map<String, dynamic>> items;

  @JsonKey(name: 'count', fromJson: asIntOr)
  final int count;

  /// Present on receipts (`totalCollected`) and defaulters (`totalDue`).
  @JsonKey(name: 'totalCollected', fromJson: asDouble)
  final double? totalCollected;

  @JsonKey(name: 'totalDue', fromJson: asDouble)
  final double? totalDue;

  /// billing/bills/charges reports the flat count it divided by.
  @JsonKey(name: 'flats', fromJson: asInt)
  final int? flats;

  const RowList({
    this.items = const [],
    this.count = 0,
    this.totalCollected,
    this.totalDue,
    this.flats,
  });

  factory RowList.fromJson(Map<String, dynamic> json) =>
      _$RowListFromJson(json);

  Map<String, dynamic> toJson() => _$RowListToJson(this);

  bool get isEmpty => items.isEmpty;
}
