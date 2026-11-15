import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { Link } from 'react-router-dom';

import { appointments, catalog } from '../../core/api/endpoints';
import { useAuthStore } from '../../core/auth/store';
import { Avatar, PageHeader } from '../../core/ui';
import { fmtDate } from '../../core/time';
import { ShareCodeModal } from '../records/RecordsPage';
import { Icon } from '../../core/ui/icons';
import { tr, place, clock } from '../../core/i18n/i18n';

// Small line icons for the four actions (stroke uses the card's accent colour).
const icon = (d: string, color: string) => (
  <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke={color} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
    <path d={d} />
  </svg>
);
const ICONS = {
  doctor: 'M6 3v6a4 4 0 0 0 8 0V3M10 13v3a5 5 0 0 0 10 0v-2M20 12a2 2 0 1 0 0-.01',
  medicine: 'M10.5 20.5 3.5 13.5a5 5 0 0 1 7-7l7 7a5 5 0 0 1-7 7ZM8.5 8.5l7 7',
  hospital: 'M4 21V7l8-4 8 4v14M9 21v-5h6v5M12 8v5M9.5 10.5h5',
  share: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2v2h-2zM18 18h2v2h-2zM14 18h2M18 14h2',
};

const ACTIONS = () => [
  { to: '/doctors', title: tr('Book a doctor'), text: tr('By specialty, area and rating'), tint: 'clay-lilac', icon: icon(ICONS.doctor, '#4f5bea') },
  { to: '/pharmacies', title: tr('Find a medicine'), text: tr('Which pharmacy has it, and the price'), tint: 'clay-mint', icon: icon(ICONS.medicine, '#12a383') },
  { to: '/hospitals', title: tr('Hospitals'), text: tr('Departments and their doctors'), tint: 'clay-butter', icon: icon(ICONS.hospital, '#c98a00') },
];

export function PatientHomePage() {
  const user = useAuthStore((s) => s.user)!;
  const appts = useQuery({ queryKey: ['appointments'], queryFn: () => appointments.mine() });
  const specs = useQuery({ queryKey: ['specialties'], queryFn: catalog.specialties, staleTime: Infinity });
  const [share, setShare] = useState(false);
  const next = appts.data?.[0];
  const hour = new Date().getHours();
  const greeting = hour < 12 ? tr('Good morning') : hour < 18 ? tr('Good afternoon') : tr('Good evening');

  return (
    <>
      <PageHeader eyebrow={greeting} title={user.name.split(' ')[0]!} right={<Avatar name={user.name} url={user.image_url} size={48} />}>
        <Link to="/doctors" className="pressable flex items-center gap-3 rounded-2xl bg-surface px-4 py-3.5 text-muted shadow-card">
          <Icon name="search" size={18} /> {tr('Search doctors, specialties...')}
        </Link>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-5xl space-y-7 px-4 pb-4 md:px-0">
        {next && (
          <Link to="/appointments" className="block">
            <div className="clay clay-mint rise flex items-center gap-4 p-4">
              <Avatar name={next.doctor?.name ?? ''} url={next.doctor?.image_url} size={48} />
              <div className="min-w-0 flex-1">
                <p className="font-bold">{tr('Next visit · {date} at {time}', { date: fmtDate(next.day, { weekday: 'short', month: 'short', day: 'numeric' }), time: clock(next.time_from) })}</p>
                {next.doctor && <p className="text-sm">{tr('Dr. {name}', { name: next.doctor.name })}{tr(', ')}{tr(next.doctor.specialty)} · {place({ key: next.doctor.area, name_ar: next.doctor.area_ar })}</p>}
              </div>
              <Icon name="chevron" size={18} className="text-muted" />
            </div>
          </Link>
        )}
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {ACTIONS().map((a, i) => (
            <Link key={a.to} to={a.to} className={`clay ${a.tint} rise flex min-h-44 flex-col gap-5 p-5`} style={{ ['--i' as string]: i + 1 } as React.CSSProperties}>
              <span className="clay-bubble">{a.icon}</span>
              <span><span className="block text-lg font-bold">{a.title}</span><span className="text-sm text-ink/70">{a.text}</span></span>
            </Link>
          ))}
          <button type="button" onClick={() => setShare(true)} className="clay clay-blush rise flex min-h-44 flex-col gap-5 p-5 text-start" style={{ ['--i' as string]: 4 } as React.CSSProperties}>
            <span className="clay-bubble">{icon(ICONS.share, '#e5484d')}</span>
            <span><span className="block text-lg font-bold">{tr('Share prescriptions')}</span><span className="text-sm text-ink/70">{tr('A 30-minute code for the pharmacy')}</span></span>
          </button>
        </div>
        {specs.data && (
          <section>
            <h2 className="mb-3 text-lg font-bold">{tr('Browse by specialty')}</h2>
            <div className="flex flex-wrap gap-2">
              {specs.data.map((s, i) => (
                <Link key={s.id} to={`/doctors?specialty=${s.id}`} className="rise rounded-full border border-line bg-surface px-3.5 py-1.5 text-sm font-semibold hover:border-indigo hover:text-indigo" style={{ ['--i' as string]: Math.min(i, 12) } as React.CSSProperties}>{tr(s.name)}</Link>
              ))}
            </div>
          </section>
        )}
      </div>
      <ShareCodeModal open={share} onClose={() => setShare(false)} />
    </>
  );
}
