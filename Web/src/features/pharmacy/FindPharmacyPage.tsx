import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { chat, pharmacy } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Pharmacy, Product } from '../../core/api/types';
import { Button, Card, Empty, ErrorBox, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { AreaPicker, ProductSearch } from '../catalog/pickers';

export function PharmacyCard({ p, index, subject }: { p: Pharmacy; index?: number; subject?: string }) {
  const navigate = useNavigate();
  const toast = useToast();
  async function message() {
    if (!p.owner_id) return;
    try { const c = await chat.start(p.owner_id, subject ?? ''); navigate(`/messages/${c.id}`); } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not start the conversation', true); }
  }
  return (
    <Card index={index} className="flex items-center gap-4 p-4">
      <span className="flex size-12 shrink-0 items-center justify-center rounded-2xl bg-mint text-xl text-white" aria-hidden>✚</span>
      <div className="min-w-0 flex-1">
        <p className="font-bold">{p.name}</p>
        <p className="text-sm text-muted">{[p.address_description, p.area.key].filter(Boolean).join(', ')}</p>
        {p.phone && <p className="text-sm text-muted">{p.phone}</p>}
      </div>
      {p.item && (
        <div className="text-right">
          <p className="font-bold">{Math.round(p.item.price)} EGP</p>
          <p className={`text-xs font-semibold ${p.item.quantity < 10 ? 'text-[#8a5b00]' : 'text-[#0e8c6a]'}`}>{p.item.quantity < 10 ? `Only ${p.item.quantity} left` : 'In stock'}</p>
        </div>
      )}
      {p.owner_id && <Button variant="ghost" className="!px-3" onClick={message} aria-label={`Message ${p.name}`}>✉</Button>}
    </Card>
  );
}

export function FindPharmacyPage() {
  const [product, setProduct] = useState<Product | null>(null);
  const [loc, setLoc] = useState<{ g?: string; a?: string }>({});
  const q = useQuery({ queryKey: ['pharmacies', product?.drug_id, loc], queryFn: () => pharmacy.find({ drug_id: product?.drug_id, governorate_id: loc.g, area_id: loc.a }) });

  return (
    <>
      <PageHeader eyebrow="Pharmacies" title="Find a medicine near you" />
      <div className="mx-auto mt-6 grid max-w-5xl gap-6 px-4 md:grid-cols-[320px_1fr] md:px-0">
        <aside className="card h-fit space-y-4 p-4">
          <ProductSearch onPick={setProduct} label="Which medicine? (e.g. Panadol)" />
          {product && (
            <div className="pop flex items-center gap-2 rounded-xl bg-indigo-100 px-3 py-2 text-sm">
              <span className="min-w-0 flex-1"><span className="font-bold">{product.brand} {product.strength}</span><span className="block text-xs text-muted">showing pharmacies with {product.active_ingredient}</span></span>
              <button type="button" onClick={() => setProduct(null)} aria-label="Clear" className="font-bold">✕</button>
            </div>
          )}
          <AreaPicker required={false} dense onChange={(g, a) => setLoc({ g: g ?? undefined, a: a ?? undefined })} />
        </aside>
        <section>
          {q.isLoading ? <SkeletonList count={3} /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : q.data!.length === 0 ? (
            <Empty title={product ? `No pharmacy has ${product.active_ingredient} in stock nearby` : 'No pharmacies here yet'} text="Try another area." />
          ) : (
            <div className="space-y-3">{q.data!.map((p, i) => <PharmacyCard key={p.id} p={p} index={i} subject={product ? `About ${product.brand}` : ''} />)}</div>
          )}
        </section>
      </div>
    </>
  );
}
