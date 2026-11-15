import { useNavigate } from 'react-router-dom';

import type { DoctorSummary } from '../../core/api/types';
import { Avatar, Card, Stars } from '../../core/ui';

export function DoctorCard({ d, index, right }: { d: DoctorSummary; index?: number; right?: React.ReactNode }) {
  const navigate = useNavigate();
  return (
    <Card index={index} onClick={() => navigate(`/doctors/${d.id}`)} className="flex items-center gap-4 p-4">
      <Avatar name={d.name} url={d.image_url} size={56} />
      <div className="min-w-0 flex-1">
        <p className="truncate font-bold">Dr. {d.name}</p>
        <p className="text-sm font-semibold text-indigo">{d.specialty.name}</p>
        <div className="mt-1 flex items-center justify-between gap-2">
          <Stars value={d.rating_stars} count={d.review_count} />
          {d.price_session > 0 && <span className="text-sm font-bold">{Math.round(d.price_session)} EGP</span>}
        </div>
        <p className="truncate text-xs text-muted">{d.area.key}, {d.governorate.key}</p>
      </div>
      {right}
    </Card>
  );
}
