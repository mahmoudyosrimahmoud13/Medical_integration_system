import { useInfiniteQuery } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { doctors, type DoctorFilter } from '../../core/api/endpoints';
import { Button, Empty, ErrorBox, PageHeader, SkeletonList } from '../../core/ui';
import { AreaPicker, SpecialtySelect } from '../catalog/pickers';
import { DoctorCard } from './DoctorCard';

export function FindDoctorsPage() {
  const [params] = useSearchParams();
  const [filter, setFilter] = useState<DoctorFilter>({ specialty_id: params.get('specialty') ?? undefined, sort: 'none' });
  const [name, setName] = useState('');
  useEffect(() => {
    const t = setTimeout(() => setFilter((f) => ({ ...f, name: name.trim().length >= 2 ? name.trim() : undefined })), 350);
    return () => clearTimeout(t);
  }, [name]);

  const q = useInfiniteQuery({
    queryKey: ['doctors', filter],
    queryFn: ({ pageParam }) => doctors.search({ ...filter, page: pageParam }),
    initialPageParam: 0,
    getNextPageParam: (last, all) => (all.flatMap((p) => p.items).length < last.total ? last.page + 1 : undefined),
  });
  const items = q.data?.pages.flatMap((p) => p.items) ?? [];
  const total = q.data?.pages[0]?.total ?? 0;

  return (
    <>
      <PageHeader eyebrow="Find a doctor" title="Who do you need today?">
        <div className="grid gap-3 md:grid-cols-[1fr_auto]">
          <input className="input" placeholder="Search by doctor name" value={name} onChange={(e) => setName(e.target.value)} aria-label="Search by doctor name" />
          <select className="input md:w-44" value={filter.sort} onChange={(e) => setFilter({ ...filter, sort: e.target.value as DoctorFilter['sort'] })} aria-label="Sort">
            <option value="none">Sort: name</option><option value="rate">Sort: top rated</option><option value="join">Sort: experience</option>
          </select>
        </div>
      </PageHeader>
      <div className="mx-auto mt-6 grid max-w-5xl gap-6 px-4 md:grid-cols-[280px_1fr] md:px-0">
        <aside className="card h-fit space-y-4 p-4">
          <SpecialtySelect value={filter.specialty_id ?? ''} onChange={(id) => setFilter({ ...filter, specialty_id: id || undefined })} />
          <AreaPicker required={false} dense onChange={(g, a) => setFilter({ ...filter, governorate_id: g ?? undefined, area_id: a ?? undefined })} />
        </aside>
        <section>
          {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : items.length === 0 ? (
            <Empty title="No doctors found" text="Try another specialty or a wider area." />
          ) : (
            <>
              <p className="mb-3 text-sm font-semibold text-muted">{total} doctor{total === 1 ? '' : 's'} found</p>
              <div className="space-y-3">{items.map((d, i) => <DoctorCard key={d.id} d={d} index={i % 10} />)}</div>
              {q.hasNextPage && <div className="mt-4 text-center"><Button variant="ghost" busy={q.isFetchingNextPage} onClick={() => q.fetchNextPage()}>Show more</Button></div>}
            </>
          )}
        </section>
      </div>
    </>
  );
}
