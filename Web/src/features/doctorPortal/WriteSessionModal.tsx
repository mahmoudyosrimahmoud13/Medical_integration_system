import { useState } from 'react';

import { records } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { InteractionReport, MedicalRecord } from '../../core/api/types';
import { Button, Field, Modal, useToast } from '../../core/ui';
import { isoDay } from '../../core/time';
import { DrugSearch } from '../catalog/pickers';
import { tr } from '../../core/i18n/i18n';

type Line = { drug_id: string; drug_name: string; repeat: string; repeat_count: number; days: number; note: string };
const REPEATS = ['daily', 'every 12 hours', 'every 8 hours', 'weekly', 'when needed'];

export function WriteSessionModal({ open, onClose, record, onSaved }: { open: boolean; onClose: () => void; record: MedicalRecord; onSaved: () => void }) {
  const [disease, setDisease] = useState('');
  const [notes, setNotes] = useState('');
  const [chronic, setChronic] = useState(false);
  const [cured, setCured] = useState(false);
  const [lines, setLines] = useState<Line[]>([]);
  const [report, setReport] = useState<InteractionReport | null>(null);
  const [checking, setChecking] = useState(false);
  const [busy, setBusy] = useState(false);
  const toast = useToast();

  function update(i: number, patch: Partial<Line>) { setLines((xs) => xs.map((l, k) => (k === i ? { ...l, ...patch } : l))); setReport(null); }

  async function check() {
    setChecking(true);
    try { setReport(await records.checkInteractions(record.patient.email, lines.map((l) => l.drug_id))); }
    catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Check failed'), true); } finally { setChecking(false); }
  }

  async function save() {
    if (disease.trim().length < 2) return toast(tr('Enter the condition'), true);
    if (report?.impact && !window.confirm(tr('The check flagged a possible interaction. Save anyway?'))) return;
    setBusy(true);
    const today = new Date();
    try {
      await records.writeSession({
        patient_email: record.patient.email, disease_name: disease.trim(), session_notes: notes.trim() || null, persistent: chronic, cured,
        prescriptions: lines.map((l) => ({ drug_id: l.drug_id, repeat: l.repeat, repeat_count: l.repeat_count, note: l.note || null, start_date: isoDay(today), end_date: isoDay(new Date(today.getTime() + l.days * 86400000)) })),
      });
      toast(tr('Visit saved. The patient was notified.'));
      onSaved();
      setDisease(''); setNotes(''); setLines([]); setReport(null);
    } catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not save'), true); } finally { setBusy(false); }
  }

  const tone = !report ? '' : !report.available ? 'bg-amber-100 text-[#8a5b00]' : report.impact ? 'bg-danger-100 text-danger' : 'bg-mint-100 text-[#0e8c6a]';

  return (
    <Modal open={open} onClose={onClose} title={tr('New visit: {name}', { name: record.patient.name.split(' ')[0] })}>
      {record.current_prescriptions.length > 0 && (
        <p className="mb-4 rounded-xl bg-amber-100 p-3 text-sm"><span className="font-bold">{tr('Currently taking:')}</span> {record.current_prescriptions.map((p) => p.drug_name).join(', ')}</p>
      )}
      <div className="space-y-3">
        <Field label={tr('Condition')}><input className="input" value={disease} onChange={(e) => setDisease(e.target.value)} /></Field>
        <Field label={tr('Visit notes')}><textarea className="input" rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} /></Field>
        <div className="flex gap-6 text-sm font-semibold">
          <label className="flex items-center gap-2"><input type="checkbox" className="accent-indigo" checked={chronic} onChange={(e) => setChronic(e.target.checked)} /> {tr('Chronic')}</label>
          <label className="flex items-center gap-2"><input type="checkbox" className="accent-indigo" checked={cured} onChange={(e) => setCured(e.target.checked)} /> {tr('Cured')}</label>
        </div>
        <DrugSearch label={tr('Prescription: add a drug')} onPick={(d) => { setLines((xs) => [...xs, { drug_id: d.id, drug_name: d.name, repeat: 'daily', repeat_count: 1, days: 7, note: '' }]); setReport(null); }} />
        {lines.map((l, i) => (
          <div key={`${l.drug_id}-${i}`} className="pop rounded-xl border border-line p-3">
            <div className="flex items-center justify-between"><p className="font-bold">{l.drug_name}</p><button type="button" className="text-sm font-semibold text-danger" onClick={() => { setLines((xs) => xs.filter((_, k) => k !== i)); setReport(null); }}>{tr('Remove')}</button></div>
            <div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-4">
              <select className="input col-span-2" value={l.repeat} onChange={(e) => update(i, { repeat: e.target.value })} aria-label={tr('How often')}>{REPEATS.map((r) => <option key={r}>{r}</option>)}</select>
              <input className="input" type="number" min={1} value={l.repeat_count} onChange={(e) => update(i, { repeat_count: Number(e.target.value) || 1 })} aria-label={tr('Per dose')} />
              <input className="input" type="number" min={1} value={l.days} onChange={(e) => update(i, { days: Number(e.target.value) || 1 })} aria-label={tr('Days')} />
              <input className="input col-span-2 sm:col-span-4" placeholder={tr('Note, e.g. after food')} value={l.note} onChange={(e) => update(i, { note: e.target.value })} />
            </div>
          </div>
        ))}
        {lines.length > 0 && (
          <>
            <Button variant="ghost" busy={checking} onClick={check}>{tr('Check interactions')}</Button>
            {report && (
              <div className={`pop rounded-xl p-3 text-sm ${tone}`} role="status">
                <p className="font-bold">{!report.available ? tr('Interaction model not available') : report.impact ? tr('Possible interaction') : tr('No interactions found')}</p>
                {report.results.filter((r) => r.interacts !== false).map((r) => <p key={r.drugA + r.drugB}>{r.drugA} + {r.drugB}: {r.description}</p>)}
              </div>
            )}
          </>
        )}
        <Button className="w-full" busy={busy} onClick={save}>{tr('Save visit')}</Button>
      </div>
    </Modal>
  );
}
