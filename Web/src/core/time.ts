/** Booking slot maths, same rules as the server and the mobile app. Pure functions, unit tested. */

export const WEEKDAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] as const;

export const weekdayName = (d: Date) => WEEKDAYS[(d.getDay() + 6) % 7];

/** "09:30 AM" or "21:30" -> minutes after midnight, or null when unreadable. */
export function parseClock(value: string): number | null {
  const m = /^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$/.exec(value);
  if (!m) return null;
  let hour = Number(m[1]);
  const minute = Number(m[2]);
  const ampm = m[3]?.toUpperCase();
  if (minute > 59) return null;
  if (ampm) {
    if (hour < 1 || hour > 12) return null;
    if (ampm === 'AM') hour = hour === 12 ? 0 : hour;
    else hour = hour === 12 ? 12 : hour + 12;
  } else if (hour > 23) return null;
  return hour * 60 + minute;
}

export function formatClock(minutes: number): string {
  const h24 = Math.floor(minutes / 60) % 24;
  const m = minutes % 60;
  const h12 = h24 % 12 === 0 ? 12 : h24 % 12;
  return `${String(h12).padStart(2, '0')}:${String(m).padStart(2, '0')} ${h24 < 12 ? 'AM' : 'PM'}`;
}

export interface Slot { start: number; label: string; available: boolean }

export function buildSlots(from: string, to: string, day: Date, booked: string[], now = new Date()): Slot[] {
  const start = parseClock(from);
  const end = parseClock(to);
  if (start === null || end === null || end <= start) return [];
  const taken = booked.map(parseClock).filter((x): x is number => x !== null);
  const isToday = sameDay(day, now);
  const nowMin = now.getHours() * 60 + now.getMinutes();
  const out: Slot[] = [];
  for (let t = start; t + 60 <= end; t += 60) {
    if (isToday && t <= nowMin) continue;
    const overlaps = taken.some((b) => b < t + 60 && t < b + 60);
    out.push({ start: t, label: formatClock(t), available: !overlaps });
  }
  return out;
}

export function workingDays(dayNames: string[], count = 14, from = new Date()): Date[] {
  const names = new Set(dayNames);
  const out: Date[] = [];
  const d = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  for (let i = 0; i < 60 && out.length < count; i++) {
    if (names.has(weekdayName(d))) out.push(new Date(d));
    d.setDate(d.getDate() + 1);
  }
  return out;
}

export const sameDay = (a: Date, b: Date) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
export const isoDay = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
export const fmtDate = (s: string | Date, opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric', year: 'numeric' }) =>
  new Date(s).toLocaleDateString(undefined, opts);
export const fmtTime = (s: string | Date) => new Date(s).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
