import { useQuery, useQueryClient } from '@tanstack/react-query';

import { doctorPortal } from '../../core/api/endpoints';
import { useAuthStore } from '../../core/auth/store';
import { Avatar, Empty, ErrorBox, PageHeader, Section, SkeletonList, Stat } from '../../core/ui';
import { AppointmentCard } from '../appointments/AppointmentsPage';

export function DoctorHomePage() {
  const user = useAuthStore((s) => s.user)!;
  const qc = useQueryClient();
  const stats = useQuery({ queryKey: ['doctor', 'stats'], queryFn: doctorPortal.stats });
  const appts = useQuery({ queryKey: ['doctor', 'appointments'], queryFn: () => doctorPortal.appointments() });
  const s = stats.data;
  return (
    <>
      <PageHeader eyebrow="Doctor workspace" title={`Dr. ${user.name.split(' ')[0]}`} right={<Avatar name={user.name} url={user.image_url} size={48} />} />
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        <div className="grid grid-cols-3 gap-3">
          <Stat label="Upcoming" value={s?.upcoming_appointments ?? 0} />
          <Stat label="Patients" value={s?.total ?? 0} tone="mint" />
          <Stat label="Women %" value={s && s.total ? Math.round((s.female * 100) / s.total) : 0} tone="danger" />
        </div>
        <Section title="Booked patients">
          {appts.isLoading ? <SkeletonList count={3} /> : appts.isError ? <ErrorBox message={(appts.error as Error).message} onRetry={() => appts.refetch()} /> : appts.data!.length === 0 ? (
            <Empty title="No bookings yet" text="Patients can book once your schedule is published." />
          ) : (
            <div className="space-y-3">
              {appts.data!.map((a, i) => (
                <AppointmentCard key={a.id} a={a} index={i} showPatient onCancel={async () => { await doctorPortal.cancel(a.id); qc.invalidateQueries({ queryKey: ['doctor'] }); }} />
              ))}
            </div>
          )}
        </Section>
      </div>
    </>
  );
}
