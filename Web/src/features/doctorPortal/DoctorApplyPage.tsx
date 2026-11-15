import { useQuery } from '@tanstack/react-query';
import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';

import { workspaceHome } from '../../app/Shell';
import { auth, doctorPortal } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { ApplicationStatus } from '../../core/api/types';
import { useAuthStore } from '../../core/auth/store';
import { Button, Card, ErrorBox, Field, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { AreaPicker, SpecialtySelect } from '../catalog/pickers';

/** "Under review" / "Approved" card shared by doctor, pharmacy and hospital applications. */
export function StatusCard({ status, kind, token }: { status: ApplicationStatus['status']; kind: string; token?: string | null }) {
  const { setUser, setToken } = useAuthStore();
  const navigate = useNavigate();
  const accepted = status === 'accepted';
  async function openWorkspace() {
    if (token) setToken(token);
    const me = await auth.me();
    setUser(me);
    navigate(workspaceHome[useAuthStore.getState().workspace]);
  }
  return (
    <Card className="mx-auto max-w-md p-8 text-center">
      <div className={`pop mx-auto flex size-24 items-center justify-center rounded-full text-4xl ${accepted ? 'bg-mint text-white' : 'bg-amber-100 text-[#8a5b00]'}`}>{accepted ? '✓' : '⏳'}</div>
      <h2 className="rise mt-5 text-2xl font-bold">{accepted ? 'You are approved' : 'Under review'}</h2>
      <p className="rise mt-2 text-sm text-muted">{accepted ? `Your ${kind} workspace is ready.` : `Our team checks every ${kind} request. You'll get a notification when it is reviewed.`}</p>
      {accepted && <Button className="mt-6" onClick={openWorkspace}>Open my workspace</Button>}
    </Card>
  );
}

export function DoctorApplyPage() {
  const q = useQuery({ queryKey: ['doctor', 'status'], queryFn: doctorPortal.status });
  return (
    <>
      <PageHeader eyebrow="For doctors" title="Join HealthHub as a doctor" />
      <div className="mx-auto mt-6 max-w-2xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList count={2} /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> :
          q.data!.status === 'none' || q.data!.status === 'rejected' ? <ApplyForm rejected={q.data!.status === 'rejected'} onDone={() => q.refetch()} /> : <StatusCard status={q.data!.status} kind="doctor" token={q.data!.access_token} />}
      </div>
    </>
  );
}

function ApplyForm({ rejected, onDone }: { rejected: boolean; onDone: () => void }) {
  const [f, setF] = useState({ specialty_id: '', area_id: '', college_name: '', graduation_year: '', summary_career: '', address_description: '' });
  const [files, setFiles] = useState<File[]>([]);
  const [busy, setBusy] = useState(false);
  const toast = useToast();

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!f.specialty_id || !f.area_id || f.college_name.trim().length < 3) return toast('Fill in specialty, area and medical school', true);
    if (files.length === 0) return toast('Add at least one certificate', true);
    const form = new FormData();
    Object.entries(f).forEach(([k, val]) => val && form.append(k, k === 'graduation_year' ? `${val}-06-01` : val));
    files.forEach((file) => form.append('certificates', file));
    setBusy(true);
    try { await doctorPortal.apply(form); toast('Request sent'); onDone(); }
    catch (err) { toast(err instanceof ApiError ? err.message : 'Could not send', true); } finally { setBusy(false); }
  }

  return (
    <form onSubmit={submit} className="card space-y-4 p-6">
      {rejected && <p className="rounded-xl bg-danger-100 p-3 text-sm text-danger">Your previous request was not approved. You can send a new one with updated details.</p>}
      <SpecialtySelect required value={f.specialty_id} onChange={(id) => setF({ ...f, specialty_id: id })} />
      <AreaPicker onChange={(_, a) => setF((x) => ({ ...x, area_id: a ?? '' }))} />
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Medical school"><input className="input" value={f.college_name} onChange={(e) => setF({ ...f, college_name: e.target.value })} /></Field>
        <Field label="Graduation year"><input className="input" type="number" min={1960} max={new Date().getFullYear()} value={f.graduation_year} onChange={(e) => setF({ ...f, graduation_year: e.target.value })} /></Field>
      </div>
      <Field label="Clinic address"><input className="input" value={f.address_description} onChange={(e) => setF({ ...f, address_description: e.target.value })} /></Field>
      <Field label="About you (shown to patients)"><textarea className="input" rows={3} value={f.summary_career} onChange={(e) => setF({ ...f, summary_career: e.target.value })} /></Field>
      <Field label="Certificates (PDF or photo)"><input type="file" multiple accept=".pdf,image/*" className="input" onChange={(e) => setFiles(Array.from(e.target.files ?? []))} /></Field>
      <Button type="submit" busy={busy} className="w-full">Send request</Button>
    </form>
  );
}
