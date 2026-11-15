import { describe, expect, it } from 'vitest';
import { buildSlots, formatClock, parseClock, weekdayName, workingDays } from './time';

describe('parseClock', () => {
  it('reads 12-hour and 24-hour times', () => {
    expect(parseClock('09:30 AM')).toBe(570);
    expect(parseClock('12:00 AM')).toBe(0);
    expect(parseClock('12:15 PM')).toBe(735);
    expect(parseClock('21:30')).toBe(1290);
  });
  it('rejects nonsense', () => {
    expect(parseClock('13:00 PM')).toBeNull();
    expect(parseClock('10:75')).toBeNull();
    expect(parseClock('soon')).toBeNull();
  });
});

describe('formatClock', () => {
  it('writes the same format the server uses', () => {
    expect(formatClock(0)).toBe('12:00 AM');
    expect(formatClock(13 * 60)).toBe('01:00 PM');
  });
});

describe('buildSlots', () => {
  const day = new Date(2030, 0, 7); // a Monday far in the future
  it('makes one-hour slots inside working hours', () => {
    const slots = buildSlots('09:00 AM', '12:00 PM', day, []);
    expect(slots.map((s) => s.label)).toEqual(['09:00 AM', '10:00 AM', '11:00 AM']);
    expect(slots.every((s) => s.available)).toBe(true);
  });
  it('marks booked hours as taken', () => {
    const slots = buildSlots('09:00 AM', '12:00 PM', day, ['10:00 AM']);
    expect(slots.find((s) => s.label === '10:00 AM')?.available).toBe(false);
  });
  it('hides past hours today', () => {
    const now = new Date(2030, 0, 7, 10, 30);
    const slots = buildSlots('09:00 AM', '01:00 PM', day, [], now);
    expect(slots.map((s) => s.label)).toEqual(['11:00 AM', '12:00 PM']);
  });
  it('returns nothing when hours are backwards', () => {
    expect(buildSlots('05:00 PM', '09:00 AM', day, [])).toEqual([]);
  });
});

describe('workingDays', () => {
  it('lists only the doctor working days', () => {
    const days = workingDays(['Monday', 'Wednesday'], 4, new Date(2030, 0, 7));
    expect(days.map(weekdayName)).toEqual(['Monday', 'Wednesday', 'Monday', 'Wednesday']);
  });
});
