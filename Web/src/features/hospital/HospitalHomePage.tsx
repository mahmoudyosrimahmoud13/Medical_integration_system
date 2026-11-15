import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

import { hospital } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Hospital } from '../../core/api/types';
import { Button, Empty, ErrorBox, Field, Modal, PageHeader, Section, SkeletonList, Tabs, useToast } from '../../core/ui';
import { AppointmentCard } from '../appointments/AppointmentsPage';
import { StatusCard } from '../doctorPortal/DoctorApplyPage';
import { DoctorCard } from '../doctors/DoctorCard';
import { FacilityForm } from '../pharmacy/FacilityForm';
import { departmentsOf } from './HospitalsPage';

export function HospitalHomePage() {
  const q = useQuery({ queryKey: ['hospital', 'mine'], queryFn: hospital.mine });
  if (q.isLoading) return <div className="p-6"><SkeletonList count={2} /></div>;
  if (q.isError) return <div className="p-6"><ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /></div>;
  const { status, access_token, hospital: mine } = q.data!;
  if (status === 'none' || status === 'rejected') {
    return (<><PageHeader eyebrow="For hospitals" title="Register your hospital" /><div className="mx-auto mt-6 max-w-2xl px-4 md:px-0"><FacilityForm kind="hospital" withDescription onSubmit={async (b) => { await hospital.apply(b); q.refetch(); }} /></div></>);
  }
  if (status !== 'accepted') return (<><PageHeader eyebrow="For hospitals" title="Your hospital" /><div className="mt-6 px-4"><StatusCard status={status} kind="hospital" token={access_token} /></div></>);
  return <Manage h={mine!} onChanged={() => q.refetch()} />;
}

function Manage({ h, onChanged }: { h: Hospital; onChanged: () => void }) {
  const [tab, setTab] = useState<'doctors' | 'appointments'>('doctors');
  const [adding, setAdding] = useState(false);
  const [email, setEmail] = useState('');
  const [dept, setDept] = useState('');
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const appts = useQuery({ queryKey: ['hospital', 'appointments'], queryFn: hospital.appointments, enabled: tab === 'appointments' });

  async function add() {
    setBusy(true);
    try { await hospital.addDoctor(email, dept); toast('Doctor added'); setAdding(false); setEmail(''); setDept(''); onChanged(); }
    catch (e) { toast(e instanceof ApiError ? e.message : 'Could not add', true); } finally { setBusy(false); }
  }
  async function remove(id: string) {
    try { await hospital.removeDoctor(id); onChanged(); } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not remove', true); }
  }
  const depts = departmentsOf(h);

  return (
    <>
      <PageHeader eyebrow="Hospital workspace" title={h.name} right={<Button variant="amber" onClick={() => setAdding(true)}>Add doctor</Button>}>
        <Tabs value={tab} onChange={setTab} items={[{ value: 'doctors', label: 'Doctors' }, { value: 'appointments', label: 'Appointments' }]} />
      </PageHeader>
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        {tab === 'doctors' ? (
          depts.size === 0 ? <Empty title="No doctors yet" text="Add doctors by their HealthHub email and group them into departments." action={<Button onClick={() => setAdding(true)}>Add a doctor</Button>} /> : (
            [...depts.entries()].map(([d, docs]) => (
              <Section key={d} title={d}>
                <div className="space-y-2">{docs.map((x, i) => <DoctorCard key={x.doctor.id} d={x.doctor} index={i} right={<Button variant="danger" className="!px-3 !py-1.5" onClick={(e) => { e.stopPropagation(); remove(x.doctor.id); }}>Remove</Button>} />)}</div>
              </Section>
            ))
          )
        ) : appts.isLoading ? <SkeletonList /> : (appts.data ?? []).length === 0 ? <Empty title="No upcoming appointments" text="Bookings with your doctors show up here." /> : (
          <div className="space-y-3">{appts.data!.map((a, i) => <AppointmentCard key={a.id} a={a} index={i} showPatient />)}</div>
        )}
      </div>
      <Modal open={adding} onClose={() => setAdding(false)} title="Add a doctor">
        <div className="space-y-3">
          <Field label="Doctor's HealthHub email"><input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></Field>
          <Field label="Department"><input className="input" value={dept} onChange={(e) => setDept(e.target.value)} /></Field>
          <Button className="w-full" busy={busy} onClick={add}>Add</Button>
        </div>
      </Modal>
    </>
  );
}
