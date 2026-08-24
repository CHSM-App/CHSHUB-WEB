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

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// Rows come back from `sp_*` with whatever casing the procedure used. Models
/// that need a raw row keep it as-is; this just guarantees a typed map.
Map<String, dynamic> asRow(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> asRows(dynamic v) =>
    v is List ? v.map(asRow).toList() : const [];
