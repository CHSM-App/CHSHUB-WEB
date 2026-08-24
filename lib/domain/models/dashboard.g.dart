// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      tickets: json['tickets'] == null
          ? const TicketCounts()
          : DashboardSummary._ticketsFromJson(json['tickets']),
      residentCount: json['residentCount'] == null
          ? 0
          : asIntOr(json['residentCount']),
      incomeSplit: json['incomeSplit'] == null
          ? const []
          : asRows(json['incomeSplit']),
      monthlyDues: json['monthlyDues'] == null
          ? const []
          : asRows(json['monthlyDues']),
      recentActivity: json['recentActivity'] == null
          ? const []
          : asRows(json['recentActivity']),
      weeklyUpdates: json['weeklyUpdates'] == null
          ? const []
          : asRows(json['weeklyUpdates']),
      defaulters: json['defaulters'] == null
          ? const DefaulterSummary()
          : DashboardSummary._defaultersFromJson(json['defaulters']),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'tickets': instance.tickets.toJson(),
      'residentCount': instance.residentCount,
      'incomeSplit': instance.incomeSplit,
      'monthlyDues': instance.monthlyDues,
      'recentActivity': instance.recentActivity,
      'weeklyUpdates': instance.weeklyUpdates,
      'defaulters': instance.defaulters.toJson(),
    };

TicketCounts _$TicketCountsFromJson(Map<String, dynamic> json) => TicketCounts(
  total: json['total'] == null ? 0 : asIntOr(json['total']),
  open: TicketCounts._readOpen(json, 'opened') == null
      ? 0
      : asIntOr(TicketCounts._readOpen(json, 'opened')),
  closed: TicketCounts._readClosed(json, 'resolved') == null
      ? 0
      : asIntOr(TicketCounts._readClosed(json, 'resolved')),
  pending: json['pending'] == null ? 0 : asIntOr(json['pending']),
);

Map<String, dynamic> _$TicketCountsToJson(TicketCounts instance) =>
    <String, dynamic>{
      'total': instance.total,
      'opened': instance.open,
      'resolved': instance.closed,
      'pending': instance.pending,
    };

DefaulterSummary _$DefaulterSummaryFromJson(Map<String, dynamic> json) =>
    DefaulterSummary(
      count: json['count'] == null ? 0 : asIntOr(json['count']),
      totalDue: json['totalDue'] == null ? 0 : asDoubleOr(json['totalDue']),
    );

Map<String, dynamic> _$DefaulterSummaryToJson(DefaulterSummary instance) =>
    <String, dynamic>{'count': instance.count, 'totalDue': instance.totalDue};
