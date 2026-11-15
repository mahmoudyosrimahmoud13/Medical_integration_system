import { useState } from 'react';

import type { MedicalRecord, Prescription, Session } from '../../core/api/types';
import { Avatar, Card, Section, Stat } from '../../core/ui';
import { fmtDate } from '../../core/time';
import { tr } from '../../core/i18n/i18n';

export function PrescriptionRow({ p }: { p: Prescription }) {
  const dates = [p.start_date && tr('from {date}', { date: fmtDate(p.start_date, { month: 'short', day: 'numeric' }) }), p.end_date && tr('until {date}', { date: fmtDate(p.end_date) })].filter(Boolean).join(' ');
  return (
    <div className="flex items-start gap-3">
      <span className="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-xl bg-mint-100 text-mint" aria-hidden>✚</span>
      <div className="min-w-0">
        <p className="font-semibold">{p.drug_name}</p>
        <p className="text-sm">{[p.repeat && tr(p.repeat), tr('{n} times', { n: p.repeat_count })].filter(Boolean).join(' · ')}</p>
        {dates && <p className="text-xs text-muted">{dates}</p>}
        {p.note && <p className="text-xs italic text-muted">{p.note}</p>}
      </div>
    </div>
  );
}

function SessionRow({ s }: { s: Session }) {
  const [open, setOpen] = useState(false);
  return (
    <Card className="p-0">
      <button type="button" className="flex w-full items-center gap-3 p-4 text-start" onClick={() => setOpen(!open)} aria-expanded={open}>
        <Avatar name={s.doctor.name} url={s.doctor.image_url} size={40} />
        <span className="min-w-0 flex-1"><span className="block font-bold">{s.disease_name}</span><span className="block text-sm text-muted">{tr('Dr. {name}', { name: s.doctor.name })} · {fmtDate(s.session_date)}</span></span>
        <span className={`transition-transform ${open ? 'rotate-180' : ''}`} aria-hidden>⌄</span>
      </button>
      {open && (
        <div className="rise space-y-2 border-t border-line px-4 py-3 text-sm">
          {s.notes && <p>{s.notes}</p>}
          <ul className="list-disc ps-5">{s.prescriptions.map((p) => <li key={p.id}>{p.drug_name}{p.repeat ? ` · ${p.repeat}` : ''}</li>)}</ul>
          {s.doctor.phone && <p className="text-muted">{s.doctor.phone}</p>}
        </div>
      )}
    </Card>
  );
}

export function RecordView({ r }: { r: MedicalRecord }) {
  const chronic = r.diseases.filter((d) => d.persistent && !d.cured).length;
  return (
    <div>
      <div className="grid grid-cols-3 gap-3">
        <Stat label={tr('Active drugs')} value={r.current_prescriptions.length} />
        <Stat label={tr('Visits')} value={r.sessions.length} tone="mint" />
        <Stat label={tr('Chronic')} value={chronic} tone="danger" />
      </div>
      <Section title={tr('Current medicines')}>
        {r.current_prescriptions.length === 0 ? <Card className="p-4 text-sm text-muted">{tr('No active prescriptions.')}</Card> : (
          <div className="space-y-3">{r.current_prescriptions.map((p, i) => <Card key={p.id} index={i} className="p-4"><PrescriptionRow p={p} /></Card>)}</div>
        )}
      </Section>
      {r.diseases.length > 0 && (
        <Section title={tr('Conditions')}>
          <div className="flex flex-wrap gap-2">
            {r.diseases.map((d) => (
              <span key={d.id} className={`badge px-3 py-1 ${d.cured ? 'bg-mint-100 text-[#0e8c6a] dark:text-mint' : d.persistent ? 'bg-danger-100 text-danger' : 'bg-amber-100 text-[#8a5b00] dark:text-amber'}`}>{d.name}{d.persistent && !d.cured ? ` · ${tr('chronic')}` : d.cured ? ` · ${tr('cured')}` : ''}</span>
            ))}
          </div>
        </Section>
      )}
      <Section title={tr('Visit history')}>
        {r.sessions.length === 0 ? <Card className="p-4 text-sm text-muted">{tr('No visits recorded yet.')}</Card> : <div className="space-y-3">{r.sessions.map((s) => <SessionRow key={s.id} s={s} />)}</div>}
      </Section>
      {r.ct_scans.length > 0 && (
        <Section title={tr('Scans')}>
          <div className="flex gap-3 overflow-x-auto pb-2">
            {r.ct_scans.map((c) => (
              <a key={c.id} href={c.url} target="_blank" rel="noreferrer" className="pressable relative block size-32 shrink-0 overflow-hidden rounded-2xl bg-line">
                <img src={c.url} alt={tr('Scan')} className="size-full object-cover" />
                <span className="absolute inset-x-0 bottom-0 bg-navy/60 py-1 text-center text-[11px] text-white">{fmtDate(c.uploaded_at)}</span>
              </a>
            ))}
          </div>
        </Section>
      )}
    </div>
  );
}
