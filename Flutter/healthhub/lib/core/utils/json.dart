/// Small, forgiving JSON readers so one odd field never crashes a screen.

String str(dynamic v, [String fallback = '']) => v == null ? fallback : v.toString();

String? strOrNull(dynamic v) => v == null || v.toString().isEmpty ? null : v.toString();

int integer(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(str(v)) ?? fallback;
}

double number(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse(str(v)) ?? fallback;
}

bool boolean(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v == null) return fallback;
  return str(v).toLowerCase() == 'true';
}

DateTime? date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<Map<String, dynamic>> list(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

Map<String, dynamic> map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : const {};

/// "2026-11-15"
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
