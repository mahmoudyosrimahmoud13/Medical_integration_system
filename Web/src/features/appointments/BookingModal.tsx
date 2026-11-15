import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useMemo, useState } from 'react';

import { appointments, doctors } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Appointment, Doctor } from '../../core/api/types';
import { Button, Modal, useToast } from '../../core/ui';
import { buildSlots, isoDay, sameDay, weekdayName, workingDays, type Slot } from '../../core/time';

/** Day strip + hourly slots. Pass `move` to reschedule an existing appointment instead of booking a new one. */
export function BookingModal({ open, onClose, doctor, move }: { open: boolean; onClose: () => void; doctor: Doctor; move?: Appointment }) {
  const days = useMemo(() => workingDays(doctor.schedule.map((s) => s.day_name)), [doctor.schedule]);
  const [day, setDay] = useState<Date | null>(null);
  const [slot, setSlot] = useState<Slot | null>(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState<Appointment | null>(null);
  const toast = useToast();
  const qc = useQueryClient();

  useEffect(() => { if (open) { setDay(days[0] ?? null); setSlot(null); setDone(null); } }, [open, days]);

  const booked = useQuery({ queryKey: ['slots', doctor.id, day && isoDay(day)], queryFn: () => doctors.bookedSlots(doctor.id, isoDay(day!)), enabled: open && !!day });
  const slots = useMemo(() => {
    if (!day) return [];
    const window = doctor.schedule.find((s) => s.day_name === weekdayName(day));
    if (!window) return [];
    let taken = (booked.data ?? []).map((b) => b.time_from);
    if (move && sameDay(new Date(move.day), day)) taken = taken.filter((t) => t !== move.time_from);
    return buildSlots(window.time_from, window.time_to, day, taken);
  }, [day, doctor.schedule, booked.data, move]);

  async function confirm() {
    if (!day || !slot) return;
    setBusy(true);
    try {
      const a = move ? await appointments.move(move.id, isoDay(day), slot.label) : await appointments.book(doctor.id, isoDay(day), slot.label);
      setDone(a);
      qc.invalidateQueries({ queryKey: ['appointments'] });
      setTimeout(onClose, 1600);
    } catch (e) {
      toast(e instanceof ApiError ? e.message : 'Could not book', true);
      booked.refetch();
    } finally { setBusy(false); }
  }

  return (
    <Modal open={open} onClose={onClose} title={move ? 'Move your appointment' : `Book with Dr. ${doctor.name}`}>
      {done ? (
        <div className="py-6 text-center">
          <div className="pop mx-auto flex size-24 items-center justify-center rounded-full bg-mint text-5xl text-white">✓</div>
          <p className="rise mt-4 text-xl font-bold">You're booked!</p>
          <p className="rise text-sm text-muted">{done.day_name}, {done.day} at {done.time_from}</p>
        </div>
      ) : (
        <>
          <p className="mb-3 text-sm text-muted">Each visit is one hour.</p>
          <p className="label">Day</p>
          <div className="-mx-1 flex gap-2 overflow-x-auto px-1 pb-2">
            {days.map((d) => {
              const sel = day && sameDay(d, day);
              return (
                <button key={d.toISOString()} type="button" onClick={() => { setDay(d); setSlot(null); }}
                  className={`pressable flex w-16 shrink-0 flex-col items-center rounded-2xl py-3 transition-colors ${sel ? 'hero text-white' : 'bg-paper text-ink hover:bg-indigo-100'}`}>
                  <span className="text-[11px] opacity-70">{d.toLocaleDateString(undefined, { weekday: 'short' })}</span>
                  <span className="text-xl font-bold">{d.getDate()}</span>
                  <span className="text-[11px] opacity-70">{d.toLocaleDateString(undefined, { month: 'short' })}</span>
                </button>
              );
            })}
          </div>
          <p className="label mt-4">Time</p>
          {booked.isLoading ? <p className="py-6 text-center text-sm text-muted">Loading hours...</p> : slots.length === 0 ? <p className="py-6 text-center text-sm text-muted">No free hours on this day.</p> : (
            <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
              {slots.map((s, i) => (
                <button key={s.start} type="button" disabled={!s.available} onClick={() => setSlot(s)}
                  className={`rise pressable rounded-xl py-2.5 text-sm font-bold transition-colors ${!s.available ? 'bg-line text-muted line-through' : slot?.start === s.start ? 'bg-indigo text-white' : 'bg-indigo-100 text-indigo hover:bg-indigo/20'}`}
                  style={{ ['--i' as string]: i } as React.CSSProperties}>
                  {s.label}
                </button>
              ))}
            </div>
          )}
          <Button className="mt-5 w-full" disabled={!slot} busy={busy} onClick={confirm}>{slot ? `${move ? 'Move to' : 'Book'} ${slot.label}` : 'Pick a time'}</Button>
        </>
      )}
    </Modal>
  );
}
