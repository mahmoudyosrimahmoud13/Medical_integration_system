import { useState, type FormEvent } from 'react';

import { records } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { MedicalRecord } from '../../core/api/types';
import { Avatar, Button, Card, Empty, ErrorBox, PageHeader, SkeletonList } from '../../core/ui';
import { v } from '../../core/validators';
import { RecordView } from '../records/RecordView';
import { WriteSessionModal } from './WriteSessionModal';
import { tr } from '../../core/i18n/i18n';

export function DoctorPatientsPage() {
  const [email, setEmail] = useState('');
  const [record, setRecord] = useState<MedicalRecord | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [writing, setWriting] = useState(false);

  async function lookup(e?: FormEvent, target = email) {
    e?.preventDefault();
    if (v.email(target)) return setError("Enter the patient's email");
    setLoading(true); setError('');
    try { setRecord(await records.patient(target)); }
    catch (err) { setRecord(null); setError(err instanceof ApiError && err.isNotFound ? tr('No patient with this email.') : (err as Error).message); }
    finally { setLoading(false); }
  }

  return (
    <>
      <PageHeader eyebrow={tr('Patients')} title={tr('Medical records')}>
        <form onSubmit={lookup} className="flex max-w-xl gap-2">
          <input className="input" type="email" placeholder={tr("Patient's email")} value={email} onChange={(e) => setEmail(e.target.value)} aria-label={tr("Patient's email")} />
          <Button type="submit" variant="amber" busy={loading}>{tr('Open')}</Button>
        </form>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        {loading ? <SkeletonList /> : error ? <ErrorBox message={error} /> : !record ? (
          <Empty title={tr('Find a patient')} text={tr('Enter the email the patient registered with to open their record.')} />
        ) : (
          <>
            <Card index={0} className="flex items-center gap-4 p-4">
              <Avatar name={record.patient.name} url={record.patient.image_url} size={52} />
              <div className="flex-1"><p className="text-lg font-bold">{record.patient.name}</p><p className="text-sm text-muted">{[record.patient.gender && tr(record.patient.gender), record.patient.age && tr('{n} years', { n: record.patient.age }), record.patient.phone].filter(Boolean).join(' · ')}</p></div>
              <Button onClick={() => setWriting(true)}>{tr('New visit')}</Button>
            </Card>
            <RecordView r={record} />
            <WriteSessionModal open={writing} onClose={() => setWriting(false)} record={record} onSaved={() => { setWriting(false); lookup(undefined, record.patient.email); }} />
          </>
        )}
      </div>
    </>
  );
}
