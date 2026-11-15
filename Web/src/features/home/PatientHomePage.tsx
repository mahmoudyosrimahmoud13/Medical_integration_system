import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { Link } from 'react-router-dom';

import { appointments, catalog } from '../../core/api/endpoints';
import { useAuthStore } from '../../core/auth/store';
import { Avatar, Card, PageHeader } from '../../core/ui';
import { fmtDate } from '../../core/time';
import { ShareCodeModal } from '../records/RecordsPage';

const ACTIONS = [
  { to: '/doctors', title: 'Book a doctor', text: 'By specialty, area and rating', cls: 'hero text-white' },
  { to: '/pharmacies', title: 'Find a medicine', text: 'Which pharmacy has it, and the price', cls: 'bg-mint text-navy' },
  { to: '/hospitals', title: 'Hospitals', text: 'Departments and their doctors', cls: 'bg-amber text-navy' },
];

export function PatientHomePage() {
  const user = useAuthStore((s) => s.user)!;
  const appts = useQuery({ queryKey: ['appointments'], queryFn: () => appointments.mine() });
  const specs = useQuery({ queryKey: ['specialties'], queryFn: catalog.specialties, staleTime: Infinity });
  const [share, setShare] = useState(false);
  const next = appts.data?.[0];
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  return (
    <>
      <PageHeader eyebrow={greeting} title={user.name.split(' ')[0]!} right={<Avatar name={user.name} url={user.image_url} size={48} />}>
        <Link to="/doctors" className="pressable flex items-center gap-3 rounded-2xl bg-white px-4 py-3.5 text-muted shadow-card">
          <span aria-hidden>⌕</span> Search doctors, specialties...
        </Link>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-5xl space-y-6 px-4 md:px-0">
        {next && (
          <Link to="/appointments" className="block">
            <Card index={0} className="flex items-center gap-4 border-mint/40 bg-mint-100 p-4">
              <Avatar name={next.doctor?.name ?? ''} url={next.doctor?.image_url} size={48} />
              <div className="min-w-0 flex-1">
                <p className="font-bold">Next visit · {fmtDate(next.day, { weekday: 'short', month: 'short', day: 'numeric' })} at {next.time_from}</p>
                {next.doctor && <p className="text-sm">Dr. {next.doctor.name}, {next.doctor.specialty} · {next.doctor.area}</p>}
              </div>
              <span aria-hidden>›</span>
            </Card>
          </Link>
        )}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {ACTIONS.map((a, i) => (
            <Link key={a.to} to={a.to} className={`pressable rise flex min-h-32 flex-col justify-between rounded-3xl p-5 ${a.cls}`} style={{ ['--i' as string]: i + 1 } as React.CSSProperties}>
              <span className="text-lg font-bold">{a.title}</span><span className="text-sm opacity-80">{a.text}</span>
            </Link>
          ))}
          <button type="button" onClick={() => setShare(true)} className="pressable rise flex min-h-32 flex-col justify-between rounded-3xl bg-danger-100 p-5 text-left text-navy" style={{ ['--i' as string]: 4 } as React.CSSProperties}>
            <span className="text-lg font-bold">Share prescriptions</span><span className="text-sm opacity-80">A 30-minute code for the pharmacy</span>
          </button>
        </div>
        {specs.data && (
          <section>
            <h2 className="mb-3 text-lg font-bold">Browse by specialty</h2>
            <div className="flex flex-wrap gap-2">
              {specs.data.map((s, i) => (
                <Link key={s.id} to={`/doctors?specialty=${s.id}`} className="rise rounded-full border border-line bg-white px-3.5 py-1.5 text-sm font-semibold hover:border-indigo hover:text-indigo" style={{ ['--i' as string]: Math.min(i, 12) } as React.CSSProperties}>{s.name}</Link>
              ))}
            </div>
          </section>
        )}
      </div>
      <ShareCodeModal open={share} onClose={() => setShare(false)} />
    </>
  );
}
