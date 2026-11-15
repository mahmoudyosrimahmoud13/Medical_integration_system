import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { chat, hospital } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Hospital } from '../../core/api/types';
import { Button, Card, Empty, ErrorBox, Modal, PageHeader, Section, SkeletonList, useToast } from '../../core/ui';
import { DoctorCard } from '../doctors/DoctorCard';

export function departmentsOf(h: Hospital) {
  const out = new Map<string, Hospital['doctors']>();
  for (const d of h.doctors) { const k = d.department || 'General'; out.set(k, [...(out.get(k) ?? []), d]); }
  return out;
}

export function HospitalsPage() {
  const q = useQuery({ queryKey: ['hospitals'], queryFn: () => hospital.find() });
  const [open, setOpen] = useState<Hospital | null>(null);
  const navigate = useNavigate();
  const toast = useToast();
  async function message(h: Hospital) {
    try { const c = await chat.start(h.owner_id, `Question about ${h.name}`); navigate(`/messages/${c.id}`); } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not start the conversation', true); }
  }
  return (
    <>
      <PageHeader eyebrow="Hospitals" title="Departments and their doctors" />
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList count={3} /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : q.data!.length === 0 ? (
          <Empty title="No hospitals yet" text="Hospitals appear here once they join HealthHub." />
        ) : (
          <div className="grid gap-3 sm:grid-cols-2">
            {q.data!.map((h, i) => (
              <Card key={h.id} index={i} onClick={() => setOpen(h)} className="flex items-center gap-4 p-4">
                <span className="hero flex size-14 shrink-0 items-center justify-center rounded-2xl text-2xl text-white" aria-hidden>▣</span>
                <div className="min-w-0 flex-1">
                  <p className="font-bold">{h.name}</p>
                  <p className="text-sm text-muted">{h.area.key}, {h.governorate.key}</p>
                  <p className="text-xs font-semibold text-indigo">{h.doctors.length} doctor{h.doctors.length === 1 ? '' : 's'} · {departmentsOf(h).size} department{departmentsOf(h).size === 1 ? '' : 's'}</p>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
      <Modal open={!!open} onClose={() => setOpen(null)} title={open?.name ?? ''}>
        {open && (
          <>
            {open.description && <p className="text-sm">{open.description}</p>}
            <p className="mt-1 text-sm text-muted">{[open.address_description, open.area.key, open.governorate.key].filter(Boolean).join(', ')}{open.phone ? ` · ${open.phone}` : ''}</p>
            <Button variant="ghost" className="mt-3" onClick={() => message(open)}>Message the hospital</Button>
            {[...departmentsOf(open).entries()].map(([dept, docs]) => (
              <Section key={dept} title={dept}>
                <div className="space-y-2">{docs.map((d, i) => <DoctorCard key={d.doctor.id} d={d.doctor} index={i} />)}</div>
              </Section>
            ))}
          </>
        )}
      </Modal>
    </>
  );
}
