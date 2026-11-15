import { useQuery } from '@tanstack/react-query';
import { useEffect, useState } from 'react';

import { doctorPortal } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Button, Card, ErrorBox, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { formatClock, parseClock, WEEKDAYS } from '../../core/time';

type Win = { from: number; to: number };
const toInput = (m: number) => `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;

export function DoctorSchedulePage() {
  const q = useQuery({ queryKey: ['doctor', 'schedule'], queryFn: doctorPortal.schedule });
  const [days, setDays] = useState<Partial<Record<string, Win>>>({});
  const [dirty, setDirty] = useState(false);
  const [busy, setBusy] = useState(false);
  const [price, setPrice] = useState('');
  const toast = useToast();

  useEffect(() => {
    if (!q.data) return;
    const next: Partial<Record<string, Win>> = {};
    for (const d of q.data) { const f = parseClock(d.time_from), t = parseClock(d.time_to); if (f !== null && t !== null) next[d.day_name] = { from: f, to: t }; }
    setDays(next);
  }, [q.data]);

  function set(day: string, w: Win | null) { setDays((x) => { const n = { ...x }; if (w) n[day] = w; else delete n[day]; return n; }); setDirty(true); }

  async function save() {
    for (const [d, w] of Object.entries(days)) if (w && w.to <= w.from) return toast(`${d}: end time must be after start time`, true);
    setBusy(true);
    try {
      await doctorPortal.saveSchedule(Object.entries(days).filter(([, w]) => w).map(([d, w]) => ({ day_name: d, time_from: formatClock(w!.from), time_to: formatClock(w!.to) })));
      setDirty(false); toast('Schedule saved. Patients see the new hours now.');
    } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not save', true); } finally { setBusy(false); }
  }

  async function savePrice() {
    const p = Number(price);
    if (!Number.isFinite(p) || p < 0) return toast('Enter a valid price', true);
    try { await doctorPortal.setPrice(p); toast('Price updated'); } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not save', true); }
  }

  return (
    <>
      <PageHeader eyebrow="Schedule" title="Working hours">
        <div className="flex max-w-sm gap-2">
          <input className="input" type="number" min={0} placeholder="Visit price (EGP)" value={price} onChange={(e) => setPrice(e.target.value)} aria-label="Visit price" />
          <Button variant="amber" onClick={savePrice}>Set price</Button>
        </div>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        <p className="mb-4 text-sm text-muted">Turn a day on, then set the hours. Visits are one hour each.</p>
        {q.isLoading ? <SkeletonList count={7} /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : (
          <div className="space-y-2">
            {WEEKDAYS.map((day, i) => {
              const w = days[day];
              return (
                <Card key={day} index={i} className={`flex flex-wrap items-center gap-3 p-3 transition-colors ${w ? 'border-indigo/30 bg-indigo-100/40' : ''}`}>
                  <label className="flex flex-1 items-center gap-3 font-semibold">
                    <input type="checkbox" className="size-5 accent-indigo" checked={!!w} onChange={(e) => set(day, e.target.checked ? { from: 9 * 60, to: 17 * 60 } : null)} />
                    {day}
                  </label>
                  {w && (
                    <span className="rise flex items-center gap-2 text-sm">
                      <input type="time" className="input !w-32" value={toInput(w.from)} onChange={(e) => set(day, { ...w, from: parseClock(e.target.value) ?? w.from })} aria-label={`${day} start`} />
                      to
                      <input type="time" className="input !w-32" value={toInput(w.to)} onChange={(e) => set(day, { ...w, to: parseClock(e.target.value) ?? w.to })} aria-label={`${day} end`} />
                    </span>
                  )}
                </Card>
              );
            })}
          </div>
        )}
        <div className={`sticky bottom-20 mt-6 transition-all md:bottom-4 ${dirty ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-4 opacity-0'}`}>
          <Button className="w-full shadow-lg" busy={busy} onClick={save}>Save schedule</Button>
        </div>
      </div>
    </>
  );
}
