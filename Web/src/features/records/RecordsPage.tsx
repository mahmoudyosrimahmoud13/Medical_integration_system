import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useRef, useState } from 'react';

import { records } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { ShareCode } from '../../core/api/types';
import { Button, ErrorBox, Modal, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { RecordView } from './RecordView';

export function RecordsPage() {
  const q = useQuery({ queryKey: ['record'], queryFn: records.mine });
  const qc = useQueryClient();
  const toast = useToast();
  const [share, setShare] = useState(false);
  const file = useRef<HTMLInputElement>(null);

  async function upload(f: File | undefined) {
    if (!f) return;
    try { await records.uploadCt(f); toast('Scan added to your record'); qc.invalidateQueries({ queryKey: ['record'] }); }
    catch (e) { toast(e instanceof ApiError ? e.message : 'Upload failed', true); }
  }

  return (
    <>
      <PageHeader eyebrow="Medical record" title="Your health, in one place">
        <div className="flex flex-wrap gap-3">
          <Button variant="amber" onClick={() => setShare(true)}>Share with a pharmacy</Button>
          <Button variant="ghost" onClick={() => file.current?.click()}>Add a scan</Button>
          <input ref={file} type="file" accept="image/*,.pdf" hidden onChange={(e) => upload(e.target.files?.[0])} />
        </div>
      </PageHeader>
      <div className="mx-auto mt-6 max-w-4xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : <RecordView r={q.data!} />}
      </div>
      <ShareCodeModal open={share} onClose={() => setShare(false)} />
    </>
  );
}

export function ShareCodeModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [code, setCode] = useState<ShareCode | null>(null);
  const [error, setError] = useState('');
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!open) return;
    setCode(null);
    records.shareCode().then(setCode).catch((e) => setError(e instanceof ApiError ? e.message : 'Could not create a code'));
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, [open]);

  const left = code ? Math.max(0, Math.floor((new Date(code.expires_at).getTime() - now) / 1000)) : 0;
  const expired = !!code && left === 0;
  const pct = code ? left / (30 * 60) : 0;

  return (
    <Modal open={open} onClose={onClose} title="Show this code at the pharmacy">
      <p className="text-sm text-muted">The pharmacist can see your current prescriptions for 30 minutes.</p>
      <div className="my-6 flex flex-col items-center">
        {error && <p className="text-danger">{error}</p>}
        {!code && !error && <p className="text-sm text-muted">Creating your code...</p>}
        {code && (
          <div className="relative flex size-52 items-center justify-center">
            <svg className="absolute inset-0 -rotate-90" viewBox="0 0 100 100" aria-hidden>
              <circle cx="50" cy="50" r="44" fill="none" stroke="#E5E7F0" strokeWidth="8" />
              <circle cx="50" cy="50" r="44" fill="none" stroke={expired ? '#E5484D' : '#2BD4A4'} strokeWidth="8" strokeLinecap="round" strokeDasharray={`${pct * 276.5} 276.5`} style={{ transition: 'stroke-dasharray 1s linear' }} />
            </svg>
            <div className="text-center">
              <p className="pop text-4xl font-bold tracking-[0.3em]">{code.code}</p>
              <p className={`mt-1 text-sm font-semibold ${expired ? 'text-danger' : 'text-muted'}`}>{expired ? 'Expired' : `${Math.floor(left / 60)}:${String(left % 60).padStart(2, '0')} left`}</p>
            </div>
          </div>
        )}
      </div>
      {expired && <Button className="w-full" onClick={() => { setCode(null); records.shareCode().then(setCode); }}>Get a new code</Button>}
    </Modal>
  );
}
