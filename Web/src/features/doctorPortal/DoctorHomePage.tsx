import { useQuery, useQueryClient } from '@tanstack/react-query';

import { doctorPortal } from '../../core/api/endpoints';
import { useAuthStore } from '../../core/auth/store';
import { Avatar, Empty, ErrorBox, PageHeader, Section, SkeletonList, Stat } from '../../core/ui';
import { AppointmentCard } from '../appointments/AppointmentsPage';
import { tr } from '../../core/i18n/i18n';

export function DoctorHomePage() {
  const user = useAuthStore((s) => s.user)!;
  const qc = useQueryClient();
  const stats = useQuery({ queryKey: ['doctor', 'stats'], queryFn: doctorPortal.stats });
  const appts = useQuery({ queryKey: ['doctor', 'appointments'], queryFn: () => doctorPortal.appointments() });
  const s = stats.data;
  return (
    <>
      <PageHeader eyebrow={tr('Doctor workspace')} title={tr('Dr. {name}', { name: user.name.split(' ')[0] })} right={<Avatar name={user.name} url={user.image_url} size={48} />} />
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        <div className="grid grid-cols-3 gap-3">
          <Stat label={tr('Upcoming')} value={s?.upcoming_appointments ?? 0} />
          <Stat label={tr('Patients')} value={s?.total ?? 0} tone="mint" />
          <Stat label={tr('Women %')} value={s && s.total ? Math.round((s.female * 100) / s.total) : 0} tone="danger" />
        </div>
        <Section title={tr('Booked patients')}>
          {appts.isLoading ? <SkeletonList count={3} /> : appts.isError ? <ErrorBox message={(appts.error as Error).message} onRetry={() => appts.refetch()} /> : appts.data!.length === 0 ? (
            <Empty title={tr('No bookings yet')} text={tr('Patients can book once your schedule is published.')} />
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
