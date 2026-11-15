import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

import { admin } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { PendingRequest } from '../../core/api/types';
import { Button, Card, Empty, ErrorBox, PageHeader, SkeletonList, Tabs, useToast } from '../../core/ui';
import { tr } from '../../core/i18n/i18n';

export function AdminPage() {
  const [tab, setTab] = useState<PendingRequest['kind']>('doctor');
  const q = useQuery({ queryKey: ['admin', 'pending'], queryFn: admin.pending });
  const toast = useToast();
  const items = (q.data ?? []).filter((r) => r.kind === tab);
  const counts = (k: PendingRequest['kind']) => (q.data ?? []).filter((r) => r.kind === k).length;

  async function review(r: PendingRequest, accept: boolean) {
    try { await admin.review(r.kind, r.id, accept); toast(tr(accept ? '{name} accepted' : '{name} rejected', { name: r.title })); q.refetch(); }
    catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not review'), true); }
  }

  return (
    <>
      <PageHeader eyebrow={tr('Admin')} title={tr('Requests to review')}>
        <Tabs value={tab} onChange={setTab} items={[{ value: 'doctor', label: tr('Doctors ({n})', { n: counts('doctor') }) }, { value: 'pharmacy', label: tr('Pharmacies ({n})', { n: counts('pharmacy') }) }, { value: 'hospital', label: tr('Hospitals ({n})', { n: counts('hospital') }) }]} />
      </PageHeader>
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : items.length === 0 ? (
          <Empty title={tr('Nothing to review')} text={tr('New requests show up here.')} />
        ) : (
          <div className="space-y-3">
            {items.map((r, i) => (
              <Card key={r.id} index={i} className="p-5">
                <p className="text-lg font-bold">{r.title}</p>
                <p className="text-sm font-semibold text-indigo">{r.subtitle}</p>
                {r.details.map((d) => <p key={d} className="mt-1 text-sm">{d}</p>)}
                {r.files.length > 0 && <div className="mt-2 flex flex-wrap gap-2">{r.files.map((f, k) => <a key={f} href={f} target="_blank" rel="noreferrer" className="badge bg-indigo-100 text-indigo underline-offset-2 hover:underline">{tr('Certificate {n}', { n: k + 1 })}</a>)}</div>}
                <div className="mt-4 flex gap-2"><Button variant="ghost" className="flex-1" onClick={() => review(r, false)}>{tr('Reject')}</Button><Button className="flex-1" onClick={() => review(r, true)}>{tr('Accept')}</Button></div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
