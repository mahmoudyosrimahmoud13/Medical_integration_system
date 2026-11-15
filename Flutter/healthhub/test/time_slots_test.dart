import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/utils/time_slots.dart';

void main() {
  group('parseClock', () {
    test('reads 12-hour times', () {
      expect(parseClock('09:30 AM'), 9 * 60 + 30);
      expect(parseClock('12:00 AM'), 0);
      expect(parseClock('12:15 PM'), 12 * 60 + 15);
      expect(parseClock('5:00 pm'), 17 * 60);
    });

    test('reads 24-hour times', () {
      expect(parseClock('21:30'), 21 * 60 + 30);
      expect(parseClock('00:00'), 0);
    });

    test('rejects nonsense', () {
      expect(parseClock('13:00 PM'), isNull);
      expect(parseClock('25:00'), isNull);
      expect(parseClock('9:60 AM'), isNull);
      expect(parseClock('noon'), isNull);
    });
  });

  test('formatClock round-trips', () {
    for (final s in ['09:00 AM', '12:00 PM', '12:00 AM', '11:45 PM']) {
      expect(formatClock(parseClock(s)!), s);
    }
  });

  group('buildSlots', () {
    final day = DateTime(2030, 1, 7); // a Monday, far in the future
    final now = DateTime(2026, 1, 1, 8);

    test('one slot per hour inside the window', () {
      final slots = buildSlots(from: '09:00 AM', to: '12:00 PM', day: day, booked: const [], now: now);
      expect(slots.map((s) => s.label), ['09:00 AM', '10:00 AM', '11:00 AM']);
      expect(slots.every((s) => s.available), isTrue);
    });

    test('a half-hour tail does not make a slot', () {
      final slots = buildSlots(from: '09:00 AM', to: '11:30 AM', day: day, booked: const [], now: now);
      expect(slots.length, 2);
    });

    test('booked hours are marked taken, overlaps included', () {
      final slots = buildSlots(from: '09:00 AM', to: '01:00 PM', day: day, booked: const ['10:30 AM'], now: now);
      final byLabel = {for (final s in slots) s.label: s.available};
      expect(byLabel['09:00 AM'], isTrue);
      expect(byLabel['10:00 AM'], isFalse, reason: '10:00-11:00 overlaps 10:30-11:30');
      expect(byLabel['11:00 AM'], isFalse, reason: '11:00-12:00 overlaps 10:30-11:30');
      expect(byLabel['12:00 PM'], isTrue);
    });

    test('past hours today are hidden', () {
      final today = DateTime(2026, 5, 5);
      final slots = buildSlots(from: '09:00 AM', to: '05:00 PM', day: today, booked: const [], now: DateTime(2026, 5, 5, 13, 10));
      expect(slots.first.label, '02:00 PM');
    });

    test('bad window gives no slots', () {
      expect(buildSlots(from: '05:00 PM', to: '09:00 AM', day: day, booked: const []), isEmpty);
      expect(buildSlots(from: 'x', to: '09:00 AM', day: day, booked: const []), isEmpty);
    });
  });

  test('workingDays lists only the days the doctor works, in order', () {
    final from = DateTime(2026, 1, 5); // Monday
    final days = workingDays(['Wednesday', 'Saturday'], count: 4, from: from);
    expect(days.map(weekdayName), ['Wednesday', 'Saturday', 'Wednesday', 'Saturday']);
    expect(days.first, DateTime(2026, 1, 7));
    expect(workingDays(const [], from: from), isEmpty);
  });
}
