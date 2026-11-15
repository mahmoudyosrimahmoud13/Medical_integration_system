import { useNavigate } from 'react-router-dom';

import type { DoctorSummary } from '../../core/api/types';
import { Avatar, Card, Stars } from '../../core/ui';
import { tr, place } from '../../core/i18n/i18n';

export function DoctorCard({ d, index, right }: { d: DoctorSummary; index?: number; right?: React.ReactNode }) {
  const navigate = useNavigate();
  return (
    <Card index={index} onClick={() => navigate(`/doctors/${d.id}`)} className="flex items-center gap-4 p-4">
      <Avatar name={d.name} url={d.image_url} size={56} />
      <div className="min-w-0 flex-1">
        <p className="truncate font-bold">{tr('Dr. {name}', { name: d.name })}</p>
        <p className="text-sm font-semibold text-indigo">{tr(d.specialty.name)}</p>
        <div className="mt-1 flex items-center justify-between gap-2">
          <Stars value={d.rating_stars} count={d.review_count} />
          {d.price_session > 0 && <span className="text-sm font-bold">{tr('{n} EGP', { n: Math.round(d.price_session) })}</span>}
        </div>
        <p className="truncate text-xs text-muted">{place(d.area)}{tr(', ')}{place(d.governorate)}</p>
      </div>
      {right}
    </Card>
  );
}
