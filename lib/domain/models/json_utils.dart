/// Coercion helpers for a backend that is not consistent about types.
///
/// The website API returns whatever the stored procedures produce: SQL money
/// columns arrive as numbers on one route and as strings on another, bit
/// columns as 0/1 or true/false, and any column can be null. Rather than
/// making every model's fromJson defensive by hand, models tag their fields
/// with @JsonKey(fromJson: asDouble) and so on.
library;

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

int asIntOr(dynamic v, [int fallback = 0]) => asInt(v) ?? fallback;

double? asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim().replaceAll(',', ''));
}

double asDoubleOr(dynamic v, [double fallback = 0]) => asDouble(v) ?? fallback;

String? asString(dynamic v) {
  if (v == null) return null;
  return v is String ? v : v.toString();
}

/// SQL bit columns surface as 0/1, "0"/"1", or a real bool depending on driver
/// and procedure.
bool asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

/// Month names as SQL Server's style 106 writes them — "25 Aug 2026".
const _monthNames = <String, int>{
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// "25 Aug 2026" and "25-Aug-2026", which DateTime.tryParse rejects.
final _style106 = RegExp(r'^(\d{1,2})[\s-]+([A-Za-z]{3,})[\s-]+(\d{4})$');

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;

  final s = v.toString().trim();
  if (s.isEmpty) return null;

  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  /*
   * Several views hand dates back already formatted rather than as a date:
   * the `visitor` view selects CONVERT(varchar, in_date, 106), which is
   * "25 Aug 2026". tryParse returns null for that, so every screen reading
   * one of those views rendered a dash where the date should be — the gate
   * log showed "In —" against every entry.
   */
  final match = _style106.firstMatch(s);
  if (match == null) return null;

  final month = _monthNames[match.group(2)!.toLowerCase().substring(0, 3)];
  if (month == null) return null;

  return DateTime(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(1)!),
  );
}

/// Rows come back from `sp_*` with whatever casing the procedure used. Models
/// that need a raw row keep it as-is; this just guarantees a typed map.
Map<String, dynamic> asRow(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> asRows(dynamic v) =>
    v is List ? v.map(asRow).toList() : const [];
