import { useQuery } from '@tanstack/react-query';
import { useEffect, useRef, useState } from 'react';

import { catalog } from '../../core/api/endpoints';
import type { Drug, Product } from '../../core/api/types';
import { Field } from '../../core/ui';

export function AreaPicker({ onChange, required = true, error, dense }: { onChange: (governorateId: string | null, areaId: string | null) => void; required?: boolean; error?: string; dense?: boolean }) {
  const [gov, setGov] = useState('');
  const [area, setArea] = useState('');
  const govs = useQuery({ queryKey: ['governorates'], queryFn: catalog.governorates, staleTime: Infinity });
  const areas = useQuery({ queryKey: ['areas', gov], queryFn: () => catalog.areas(gov), enabled: !!gov, staleTime: Infinity });
  return (
    <div className={`grid gap-${dense ? 2 : 4} sm:grid-cols-2`}>
      <Field label="Governorate">
        <select className="input" value={gov} onChange={(e) => { setGov(e.target.value); setArea(''); onChange(e.target.value || null, null); }}>
          <option value="">{required ? 'Choose' : 'Any governorate'}</option>
          {govs.data?.map((g) => <option key={g.id} value={g.id}>{g.key}</option>)}
        </select>
      </Field>
      <Field label="Area" error={error}>
        <select className="input" value={area} disabled={!gov} onChange={(e) => { setArea(e.target.value); onChange(gov || null, e.target.value || null); }}>
          <option value="">{required ? 'Choose' : 'Any area'}</option>
          {areas.data?.map((a) => <option key={a.id} value={a.id}>{a.key}</option>)}
        </select>
      </Field>
    </div>
  );
}

export function SpecialtySelect({ value, onChange, required }: { value: string; onChange: (id: string) => void; required?: boolean }) {
  const q = useQuery({ queryKey: ['specialties'], queryFn: catalog.specialties, staleTime: Infinity });
  return (
    <Field label="Specialty">
      <select className="input" value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">{required ? 'Choose' : 'All specialties'}</option>
        {q.data?.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
      </select>
    </Field>
  );
}

function useDebounced<T>(value: T, ms = 300) {
  const [d, setD] = useState(value);
  useEffect(() => { const t = setTimeout(() => setD(value), ms); return () => clearTimeout(t); }, [value, ms]);
  return d;
}

/** Search-as-you-type with a dropdown. Used for drugs and products. */
function Suggest<T>({ label, placeholder, fetcher, render, keyOf, onPick }: { label: string; placeholder?: string; fetcher: (q: string) => Promise<T[]>; render: (t: T) => React.ReactNode; keyOf: (t: T) => string; onPick: (t: T) => void }) {
  const [text, setText] = useState('');
  const [open, setOpen] = useState(false);
  const q = useDebounced(text);
  const box = useRef<HTMLDivElement>(null);
  const results = useQuery({ queryKey: ['suggest', label, q], queryFn: () => fetcher(q), enabled: q.trim().length >= 2 });
  useEffect(() => {
    const close = (e: MouseEvent) => !box.current?.contains(e.target as Node) && setOpen(false);
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);
  return (
    <div ref={box} className="relative">
      <Field label={label}>
        <input className="input" placeholder={placeholder} value={text} role="combobox" aria-expanded={open} aria-autocomplete="list"
          onChange={(e) => { setText(e.target.value); setOpen(true); }} onFocus={() => setOpen(true)} />
      </Field>
      {open && q.trim().length >= 2 && (
        <ul role="listbox" className="pop absolute z-20 mt-1 max-h-72 w-full overflow-auto rounded-xl border border-line bg-white p-1 shadow-card">
          {results.isLoading && <li className="px-3 py-2 text-sm text-muted">Searching...</li>}
          {results.data?.length === 0 && <li className="px-3 py-2 text-sm text-muted">Nothing found</li>}
          {results.data?.map((t) => (
            <li key={keyOf(t)} role="option" aria-selected={false}>
              <button type="button" className="w-full rounded-lg px-3 py-2 text-left text-sm hover:bg-paper" onClick={() => { onPick(t); setText(''); setOpen(false); }}>{render(t)}</button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export const DrugSearch = ({ onPick, label = 'Add a drug' }: { onPick: (d: Drug) => void; label?: string }) => (
  <Suggest<Drug> label={label} placeholder="Type at least 2 letters" fetcher={catalog.drugs} keyOf={(d) => d.id} onPick={onPick} render={(d) => <span className="font-semibold">{d.name}</span>} />
);

export const ProductSearch = ({ onPick, label = 'Search by brand or ingredient' }: { onPick: (p: Product) => void; label?: string }) => (
  <Suggest<Product> label={label} placeholder="e.g. Panadol, Concor, metformin" fetcher={(q) => catalog.products({ q })} keyOf={(p) => String(p.id)} onPick={onPick}
    render={(p) => (
      <span className="flex items-center justify-between gap-3">
        <span><span className="font-semibold">{p.brand} {p.strength}</span><span className="block text-xs text-muted">{p.active_ingredient} · {p.manufacturer}</span></span>
        {p.price_egp > 0 && <span className="text-xs font-semibold">{p.price_egp} EGP</span>}
      </span>
    )} />
);
