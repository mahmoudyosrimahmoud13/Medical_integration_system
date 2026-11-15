import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';

import { chat, doctors } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Avatar, Button, Card, ErrorBox, Modal, Section, SkeletonList, Stars, useToast } from '../../core/ui';
import { fmtDate } from '../../core/time';
import { BookingModal } from '../appointments/BookingModal';
import { tr, place, clock } from '../../core/i18n/i18n';

export function DoctorDetailsPage() {
  const { id = '' } = useParams();
  const q = useQuery({ queryKey: ['doctor', id], queryFn: () => doctors.get(id) });
  const reviews = useQuery({ queryKey: ['doctor', id, 'reviews'], queryFn: () => doctors.reviews(id) });
  const [booking, setBooking] = useState(false);
  const [rating, setRating] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();
  const qc = useQueryClient();

  const message = useMutation({
    mutationFn: () => chat.start(q.data!.user_id, tr('Question for Dr. {name}', { name: q.data!.name })),
    onSuccess: (c) => navigate(`/messages/${c.id}`),
    onError: (e) => toast(e instanceof ApiError ? tr(e.message) : tr('Could not start the conversation'), true),
  });

  if (q.isLoading) return <div className="mx-auto max-w-4xl p-4"><SkeletonList count={3} /></div>;
  if (q.isError || !q.data) return <div className="mx-auto max-w-4xl p-4"><ErrorBox message={(q.error as Error)?.message ?? tr('Not found')} onRetry={() => q.refetch()} /></div>;
  const d = q.data;

  return (
    <div className="mx-auto max-w-4xl">
      <header className="hero rounded-b-3xl px-6 py-10 text-center text-white md:rounded-3xl">
        <div className="pop inline-block rounded-full ring-4 ring-surface/30"><Avatar name={d.name} url={d.image_url} size={104} /></div>
        <h1 className="rise mt-4 text-3xl font-bold">{tr('Dr. {name}', { name: d.name })}</h1>
        <p className="rise text-white/80" style={{ ['--i' as string]: 1 } as React.CSSProperties}>{tr(d.specialty.name)}</p>
        <div className="rise mt-2 flex justify-center" style={{ ['--i' as string]: 2 } as React.CSSProperties}><Stars value={d.rating_stars} count={d.review_count} size={18} /></div>
        <div className="rise mt-6 flex flex-wrap justify-center gap-3" style={{ ['--i' as string]: 3 } as React.CSSProperties}>
          {d.schedule.length > 0 && <Button variant="amber" onClick={() => setBooking(true)}>{tr('Book an appointment')}</Button>}
          <Button variant="ghost" onClick={() => message.mutate()} busy={message.isPending}>{tr('Message')}</Button>
        </div>
      </header>

      <div className="px-4 md:px-0">
        <div className="mt-6 grid grid-cols-3 gap-3">
          {[[tr('Visit'), d.price_session > 0 ? tr('{n} EGP', { n: Math.round(d.price_session) }) : tr('Ask clinic')], [tr('Reviews'), String(d.review_count)], [tr('Area'), place(d.area)]].map(([l, val], i) => (
            <Card key={l} index={i} className="p-4 text-center"><p className="truncate text-lg font-bold">{val}</p><p className="text-xs text-muted">{l}</p></Card>
          ))}
        </div>
        {d.summary_career && <Section title={tr('About')}><Card className="p-5 leading-relaxed">{d.summary_career}</Card></Section>}
        <Section title={tr('Clinic')}>
          <Card className="space-y-1 p-5 text-sm">
            <p>{[d.address_description, place(d.area), place(d.governorate)].filter(Boolean).join(tr(', '))}</p>
            {d.phone && <p>{d.phone}</p>}
            {d.college_name && <p className="text-muted">{d.college_name}{d.graduation_year ? `, class of ${new Date(d.graduation_year).getFullYear()}` : ''}</p>}
          </Card>
        </Section>
        <Section title={tr('Working hours')}>
          <Card className="divide-y divide-line p-0">
            {d.schedule.length === 0 ? <p className="p-5 text-sm text-muted">{tr('No published hours yet.')}</p> : d.schedule.map((s) => (
              <div key={s.day_name} className="flex justify-between px-5 py-3 text-sm"><span className="font-semibold">{tr(s.day_name)}</span><span>{clock(s.time_from)} - {clock(s.time_to)}</span></div>
            ))}
          </Card>
        </Section>
        <Section title={tr('Reviews')} action={<Button variant="ghost" onClick={() => setRating(true)}>{tr('Rate')}</Button>}>
          {reviews.data?.length === 0 && <Card className="p-5 text-sm text-muted">{tr('No reviews yet. Be the first after your visit.')}</Card>}
          <div className="space-y-3">
            {reviews.data?.map((r, i) => (
              <Card key={r.id} index={i} className="p-4">
                <div className="flex items-center gap-3"><Avatar name={r.patient_name} size={32} /><span className="flex-1 font-semibold">{r.patient_name}</span><Stars value={r.rate} /></div>
                {r.message && <p className="mt-2 text-sm">{r.message}</p>}
                <p className="mt-1 text-xs text-muted">{fmtDate(r.sent_at)}</p>
              </Card>
            ))}
          </div>
        </Section>
      </div>

      <BookingModal open={booking} onClose={() => setBooking(false)} doctor={d} />
      <RateModal open={rating} onClose={() => setRating(false)} onDone={async (rate, text) => {
        try {
          await doctors.review(id, rate, text);
          toast(tr('Thanks for your review!'));
          qc.invalidateQueries({ queryKey: ['doctor', id] });
          setRating(false);
        } catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not send review'), true); }
      }} />
    </div>
  );
}

function RateModal({ open, onClose, onDone }: { open: boolean; onClose: () => void; onDone: (rate: number, text: string) => Promise<void> }) {
  const [rate, setRate] = useState(5);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  return (
    <Modal open={open} onClose={onClose} title={tr('Rate your visit')}>
      <div className="mb-4 flex justify-center gap-1">
        {[1, 2, 3, 4, 5].map((i) => (
          <button key={i} type="button" aria-label={`${i} stars`} onClick={() => setRate(i)} className={`text-4xl transition-transform ${i <= rate ? 'scale-110 text-amber' : 'text-line'}`}>★</button>
        ))}
      </div>
      <textarea className="input" rows={3} placeholder={tr('Tell others about your visit (optional)')} value={text} onChange={(e) => setText(e.target.value)} />
      <Button className="mt-4 w-full" busy={busy} onClick={async () => { setBusy(true); await onDone(rate, text); setBusy(false); }}>{tr('Send')}</Button>
    </Modal>
  );
}
