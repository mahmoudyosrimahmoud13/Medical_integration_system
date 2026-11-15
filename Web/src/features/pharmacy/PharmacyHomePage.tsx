import { useQuery } from '@tanstack/react-query';
import { useState, type FormEvent } from 'react';

import { pharmacy } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Button, Card, Empty, ErrorBox, PageHeader, SkeletonList } from '../../core/ui';
import { StatusCard } from '../doctorPortal/DoctorApplyPage';
import { PrescriptionRow } from '../records/RecordView';
import { FacilityForm } from './FacilityForm';

export function PharmacyHomePage() {
  const q = useQuery({ queryKey: ['pharmacy', 'mine'], queryFn: pharmacy.mine });
  if (q.isLoading) return <div className="p-6"><SkeletonList count={2} /></div>;
  if (q.isError) return <div className="p-6"><ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /></div>;
  const { status, access_token, pharmacy: mine } = q.data!;
  if (status === 'none' || status === 'rejected') {
    return (<><PageHeader eyebrow="For pharmacies" title="Register your pharmacy" /><div className="mx-auto mt-6 max-w-2xl px-4 md:px-0"><FacilityForm kind="pharmacy" onSubmit={async (b) => { await pharmacy.apply(b); q.refetch(); }} /></div></>);
  }
  if (status !== 'accepted') return (<><PageHeader eyebrow="For pharmacies" title="Your pharmacy" /><div className="mt-6 px-4"><StatusCard status={status} kind="pharmacy" token={access_token} /></div></>);
  return <Counter name={mine!.name} />;
}

function Counter({ name }: { name: string }) {
  const [code, setCode] = useState('');
  const [result, setResult] = useState<Awaited<ReturnType<typeof pharmacy.byCode>> | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  async function lookup(e: FormEvent) {
    e.preventDefault();
    if (code.trim().length < 4) return;
    setBusy(true); setError('');
    try { setResult(await pharmacy.byCode(code)); } catch (err) { setResult(null); setError(err instanceof ApiError ? err.message : 'Lookup failed'); } finally { setBusy(false); }
  }
  return (
    <>
      <PageHeader eyebrow={name} title="Counter">
        <form onSubmit={lookup} className="flex max-w-md gap-2">
          <input className="input !text-xl !font-bold !tracking-[0.3em] uppercase" placeholder="PATIENT CODE" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} aria-label="Patient code" />
          <Button type="submit" variant="amber" busy={busy}>Open</Button>
        </form>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        {error ? <ErrorBox message={error} /> : !result ? (
          <Empty title="Ask the patient for their code" text="Patients make a 6-character code in the HealthHub app. It shows their current prescriptions for 30 minutes." />
        ) : (
          <>
            <h2 className="rise mb-3 text-lg font-bold">Prescriptions for {result.patient_name}</h2>
            {result.prescriptions.length === 0 && <Card className="p-4 text-sm text-muted">This patient has no active prescriptions.</Card>}
            <div className="space-y-3">{result.prescriptions.map((p, i) => <Card key={p.id} index={i} className="p-4"><PrescriptionRow p={p} /></Card>)}</div>
          </>
        )}
      </div>
    </>
  );
}
