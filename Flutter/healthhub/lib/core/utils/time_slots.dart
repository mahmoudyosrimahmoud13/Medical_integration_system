/// Booking slot logic. Kept free of Flutter so it can be unit tested on its own.
/// It mirrors the server rules: one-hour slots inside the doctor's working hours,
/// no slots in the past, and a slot is taken when another booking overlaps it.

const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String weekdayName(DateTime d) => weekdays[d.weekday - 1];

/// "09:30 AM" -> 570 (minutes after midnight). Also accepts "21:30". Returns null when unreadable.
int? parseClock(String value) {
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$').firstMatch(value);
  if (m == null) return null;
  var hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  final ampm = m.group(3)?.toUpperCase();
  if (minute > 59) return null;
  if (ampm != null) {
    if (hour < 1 || hour > 12) return null;
    if (ampm == 'AM') hour = hour == 12 ? 0 : hour;
    if (ampm == 'PM') hour = hour == 12 ? 12 : hour + 12;
  } else if (hour > 23) {
    return null;
  }
  return hour * 60 + minute;
}

/// 570 -> "09:30 AM"
String formatClock(int minutes) {
  final h24 = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  final ampm = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
}

class Slot {
  const Slot(this.start, {required this.available});

  final int start;
  final bool available;

  String get label => formatClock(start);
  String get endLabel => formatClock(start + 60);

  @override
  bool operator ==(Object other) => other is Slot && other.start == start && other.available == available;

  @override
  int get hashCode => Object.hash(start, available);

  @override
  String toString() => 'Slot($label, ${available ? 'free' : 'taken'})';
}

/// Hourly slots between [from] and [to] on [day].
/// [booked] holds the start times ("10:00 AM") already taken that day.
List<Slot> buildSlots({
  required String from,
  required String to,
  required DateTime day,
  required Iterable<String> booked,
  DateTime? now,
}) {
  final start = parseClock(from);
  final end = parseClock(to);
  if (start == null || end == null || end <= start) return const [];

  final taken = booked.map(parseClock).whereType<int>().toList();
  final current = now ?? DateTime.now();
  final isToday = day.year == current.year && day.month == current.month && day.day == current.day;
  final nowMinutes = current.hour * 60 + current.minute;

  final slots = <Slot>[];
  for (var t = start; t + 60 <= end; t += 60) {
    if (isToday && t <= nowMinutes) continue;
    final overlaps = taken.any((b) => b < t + 60 && t < b + 60);
    slots.add(Slot(t, available: !overlaps));
  }
  return slots;
}

/// The next [count] dates (starting tomorrow when today is over) on which the doctor works.
List<DateTime> workingDays(Iterable<String> dayNames, {int count = 14, DateTime? from}) {
  final names = dayNames.toSet();
  if (names.isEmpty) return const [];
  final base = from ?? DateTime.now();
  var d = DateTime(base.year, base.month, base.day);
  final out = <DateTime>[];
  for (var i = 0; i < 60 && out.length < count; i++) {
    if (names.contains(weekdayName(d))) out.add(d);
    d = d.add(const Duration(days: 1));
  }
  return out;
}
