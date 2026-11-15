import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

import { appointments, doctors } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Appointment, Doctor } from '../../core/api/types';
import { Avatar, Badge, Button, Card, Empty, ErrorBox, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { fmtDate } from '../../core/time';
import { BookingModal } from './BookingModal';
import { tr, place, locale, clock } from '../../core/i18n/i18n';

export function AppointmentCard({ a, index, showPatient, onCancel, onMove }: { a: Appointment; index?: number; showPatient?: boolean; onCancel?: () => Promise<unknown>; onMove?: () => void }) {
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const d = a.doctor;
  const p = a.patient;
  const day = new Date(a.day);
  async function cancel() {
    if (!onCancel || !window.confirm(tr('Cancel the appointment on {day} {date} at {time}?', { day: tr(a.day_name), date: fmtDate(a.day), time: clock(a.time_from) }))) return;
    setBusy(true);
    try { await onCancel(); toast(tr('Appointment cancelled')); } catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not cancel'), true); } finally { setBusy(false); }
  }
  return (
    <Card index={index} className="p-4">
      <div className="flex items-center gap-4">
        <div className="flex w-16 shrink-0 flex-col items-center rounded-2xl bg-indigo-100 py-2 text-indigo">
          <span className="text-[11px] font-bold uppercase">{day.toLocaleDateString(locale(), { month: 'short' })}</span>
          <span className="text-2xl font-bold leading-none">{day.getDate()}</span>
          <span className="text-[11px]">{day.toLocaleDateString(locale(), { weekday: 'short' })}</span>
        </div>
        <div className="min-w-0 flex-1">
          {showPatient && p ? (
            <><p className="font-bold">{p.name}</p><p className="text-xs text-muted">{[p.gender && tr(p.gender), p.age && tr('{n} years', { n: p.age }), p.phone].filter(Boolean).join(' · ')}</p></>
          ) : d ? (
            <><p className="font-bold">{tr('Dr. {name}', { name: d.name })}</p><p className="text-sm text-indigo">{tr(d.specialty)}</p><p className="text-xs text-muted">{place({ key: d.area, name_ar: d.area_ar })}{tr(', ')}{place({ key: d.governorate, name_ar: d.governorate_ar })}</p></>
          ) : null}
          <p className="mt-1 text-sm font-semibold">{clock(a.time_from)} - {clock(a.time_to)}</p>
        </div>
        {showPatient && d && <Avatar name={d.name} url={d.image_url} size={32} />}
        <Badge status={a.status} />
      </div>
      {(onCancel || onMove) && (
        <div className="mt-3 flex gap-2">
          {onMove && <Button variant="ghost" className="flex-1" onClick={onMove}>{tr('Move')}</Button>}
          {onCancel && <Button variant="danger" className="flex-1" busy={busy} onClick={cancel}>{tr('Cancel')}</Button>}
        </div>
      )}
    </Card>
  );
}

export function AppointmentsPage() {
  const qc = useQueryClient();
  const q = useQuery({ queryKey: ['appointments'], queryFn: () => appointments.mine() });
  const [moving, setMoving] = useState<{ a: Appointment; d: Doctor } | null>(null);
  const toast = useToast();
  const openMove = useMutation({
    mutationFn: async (a: Appointment) => ({ a, d: await doctors.get(a.doctor!.id) }),
    onSuccess: setMoving,
    onError: (e) => toast(e instanceof ApiError ? tr(e.message) : tr('Could not load the doctor'), true),
  });
  return (
    <>
      <PageHeader eyebrow={tr('Your visits')} title={tr('Appointments')} />
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : q.data!.length === 0 ? (
          <Empty title={tr('No upcoming appointments')} text={tr('Find a doctor and book a time that suits you.')} />
        ) : (
          <div className="space-y-3">
            {q.data!.map((a, i) => (
              <AppointmentCard key={a.id} a={a} index={i} onMove={() => openMove.mutate(a)}
                onCancel={async () => { await appointments.cancel(a.id); qc.invalidateQueries({ queryKey: ['appointments'] }); }} />
            ))}
          </div>
        )}
      </div>
      {moving && <BookingModal open onClose={() => setMoving(null)} doctor={moving.d} move={moving.a} />}
    </>
  );
}
