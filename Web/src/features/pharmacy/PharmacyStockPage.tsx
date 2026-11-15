import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

import { pharmacy } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Drug, StockItem } from '../../core/api/types';
import { Button, Card, Empty, ErrorBox, Field, Modal, PageHeader, SkeletonList, useToast } from '../../core/ui';
import { DrugSearch } from '../catalog/pickers';
import { tr } from '../../core/i18n/i18n';

export function PharmacyStockPage() {
  const q = useQuery({ queryKey: ['pharmacy', 'stock'], queryFn: pharmacy.stock });
  const [editing, setEditing] = useState<{ drug: Drug; item?: StockItem } | 'new' | null>(null);
  const toast = useToast();

  async function remove(it: StockItem) {
    if (!window.confirm(`Remove ${it.drug_name} from your stock?`)) return;
    try { await pharmacy.removeStock(it.drug_id); q.refetch(); } catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not remove'), true); }
  }

  return (
    <>
      <PageHeader eyebrow={tr('Pharmacy')} title={tr('Stock')} right={<Button variant="amber" onClick={() => setEditing('new')}>{tr('Add medicine')}</Button>} />
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : q.data!.length === 0 ? (
          <Empty title={tr('No stock yet')} text={tr('Add the medicines you carry so patients can find you.')} action={<Button onClick={() => setEditing('new')}>{tr('Add medicine')}</Button>} />
        ) : (
          <div className="space-y-2">
            {q.data!.map((it, i) => (
              <Card key={it.drug_id} index={i} className="flex items-center gap-3 p-3">
                <div className="min-w-0 flex-1"><p className="font-bold">{it.drug_name}</p><p className="text-sm text-muted">{tr('{n} EGP', { n: it.price.toFixed(2) })}</p></div>
                <span className={`badge ${it.quantity === 0 ? 'bg-danger-100 text-danger' : it.quantity < 10 ? 'bg-amber-100 text-[#8a5b00]' : 'bg-mint-100 text-[#0e8c6a]'}`}>{it.quantity}</span>
                <Button variant="ghost" className="!px-3 !py-1.5" onClick={() => setEditing({ drug: { id: it.drug_id, name: it.drug_name }, item: it })}>{tr('Edit')}</Button>
                <Button variant="danger" className="!px-3 !py-1.5" onClick={() => remove(it)}>{tr('Remove')}</Button>
              </Card>
            ))}
          </div>
        )}
      </div>
      <StockModal state={editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); q.refetch(); }} />
    </>
  );
}

function StockModal({ state, onClose, onSaved }: { state: { drug: Drug; item?: StockItem } | 'new' | null; onClose: () => void; onSaved: () => void }) {
  const [drug, setDrug] = useState<Drug | null>(null);
  const [qty, setQty] = useState('10');
  const [price, setPrice] = useState('');
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const open = state !== null;
  const current = state && state !== 'new' ? state.drug : drug;
  const existing = state && state !== 'new' ? state.item : undefined;
  if (!open) return null;
  async function save() {
    const q = Number(existing && qty === '10' ? existing.quantity : qty);
    const p = Number(price || existing?.price || NaN);
    if (!current || !Number.isFinite(q) || !Number.isFinite(p) || q < 0 || p < 0) return toast(tr('Pick a drug and enter quantity and price'), true);
    setBusy(true);
    try { await pharmacy.setStock(current.id, q, p); toast(`${current.name} updated`); setDrug(null); setPrice(''); onSaved(); }
    catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Could not save'), true); } finally { setBusy(false); }
  }
  return (
    <Modal open onClose={onClose} title={existing ? tr('Update stock') : tr('Add medicine')}>
      <div className="space-y-3">
        {current ? <p className="rounded-xl bg-indigo-100 px-3 py-2 font-bold">{current.name}</p> : <DrugSearch label={tr('Medicine (active ingredient)')} onPick={setDrug} />}
        <div className="grid grid-cols-2 gap-3">
          <Field label={tr('Quantity')}><input className="input" type="number" min={0} defaultValue={existing?.quantity ?? 10} onChange={(e) => setQty(e.target.value)} /></Field>
          <Field label={tr('Price (EGP)')}><input className="input" type="number" min={0} step="0.5" defaultValue={existing?.price ?? ''} onChange={(e) => setPrice(e.target.value)} /></Field>
        </div>
        <Button className="w-full" busy={busy} onClick={save}>{tr('Save')}</Button>
      </div>
    </Modal>
  );
}
