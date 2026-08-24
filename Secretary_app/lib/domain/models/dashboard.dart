import 'package:json_annotation/json_annotation.dart';

import 'json_utils.dart';

part 'dashboard.g.dart';

/// GET /api/web/reports/dashboard.
///
/// Every branch of sp_dashboard is fetched independently on the server and a
/// failing one degrades to an empty list, so each field here has to tolerate
/// being absent — hence the defaults rather than required fields.
@JsonSerializable(explicitToJson: true)
class DashboardSummary {
  @JsonKey(name: 'tickets', fromJson: _ticketsFromJson)
  final TicketCounts tickets;

  @JsonKey(name: 'residentCount', fromJson: asIntOr)
  final int residentCount;

  @JsonKey(name: 'incomeSplit', fromJson: asRows)
  final List<Map<String, dynamic>> incomeSplit;

  @JsonKey(name: 'monthlyDues', fromJson: asRows)
  final List<Map<String, dynamic>> monthlyDues;

  @JsonKey(name: 'recentActivity', fromJson: asRows)
  final List<Map<String, dynamic>> recentActivity;

  @JsonKey(name: 'weeklyUpdates', fromJson: asRows)
  final List<Map<String, dynamic>> weeklyUpdates;

  @JsonKey(name: 'defaulters', fromJson: _defaultersFromJson)
  final DefaulterSummary defaulters;

  const DashboardSummary({
    this.tickets = const TicketCounts(),
    this.residentCount = 0,
    this.incomeSplit = const [],
    this.monthlyDues = const [],
    this.recentActivity = const [],
    this.weeklyUpdates = const [],
    this.defaulters = const DefaulterSummary(),
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);

  static TicketCounts _ticketsFromJson(dynamic v) =>
      v is Map ? TicketCounts.fromJson(asRow(v)) : const TicketCounts();

  static DefaulterSummary _defaultersFromJson(dynamic v) =>
      v is Map ? DefaulterSummary.fromJson(asRow(v)) : const DefaulterSummary();
}

/// Helpdesk ticket tallies.
///
/// The column names come straight from sp_dashboard 'Get_Ticket', which
/// against a live society returns `{ opened, resolved }` — not the
/// open/closed/total set the names here suggest. Both spellings are accepted
/// rather than picking one, because the procedure's column list is not
/// something this app controls.
@JsonSerializable()
class TicketCounts {
  @JsonKey(name: 'total', fromJson: asIntOr)
  final int total;

  @JsonKey(name: 'opened', readValue: _readOpen, fromJson: asIntOr)
  final int open;

  @JsonKey(name: 'resolved', readValue: _readClosed, fromJson: asIntOr)
  final int closed;

  @JsonKey(name: 'pending', fromJson: asIntOr)
  final int pending;

  const TicketCounts({
    this.total = 0,
    this.open = 0,
    this.closed = 0,
    this.pending = 0,
  });

  static Object? _readOpen(Map json, String key) => json[key] ?? json['open'];

  static Object? _readClosed(Map json, String key) =>
      json[key] ?? json['closed'];

  factory TicketCounts.fromJson(Map<String, dynamic> json) =>
      _$TicketCountsFromJson(json);

  Map<String, dynamic> toJson() => _$TicketCountsToJson(this);
}

@JsonSerializable()
class DefaulterSummary {
  @JsonKey(name: 'count', fromJson: asIntOr)
  final int count;

  @JsonKey(name: 'totalDue', fromJson: asDoubleOr)
  final double totalDue;

  const DefaulterSummary({this.count = 0, this.totalDue = 0});

  factory DefaulterSummary.fromJson(Map<String, dynamic> json) =>
      _$DefaulterSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DefaulterSummaryToJson(this);
}
