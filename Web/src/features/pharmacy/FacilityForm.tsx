import { useState, type FormEvent } from 'react';

import { ApiError } from '../../core/api/client';
import { Button, Field, useToast } from '../../core/ui';
import { AreaPicker } from '../catalog/pickers';

/** Shared "register your pharmacy / hospital" form. */
export function FacilityForm({ kind, withDescription, onSubmit }: { kind: string; withDescription?: boolean; onSubmit: (body: Record<string, unknown>) => Promise<unknown> }) {
  const [f, setF] = useState({ name: '', area_id: '', address_description: '', phone: '', description: '' });
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (f.name.trim().length < 3 || !f.area_id || !f.address_description.trim()) return toast('Fill in the name, area and address', true);
    setBusy(true);
    try { await onSubmit({ ...f, phone: f.phone.trim() || null }); toast('Request sent'); }
    catch (err) { toast(err instanceof ApiError ? err.message : 'Could not send', true); } finally { setBusy(false); }
  }
  return (
    <form onSubmit={submit} className="card space-y-4 p-6">
      <p className="text-sm text-muted">Tell us about your {kind}. Our team reviews every request before it goes live.</p>
      <Field label={`${kind[0]!.toUpperCase()}${kind.slice(1)} name`}><input className="input" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
      <AreaPicker onChange={(_, a) => setF((x) => ({ ...x, area_id: a ?? '' }))} />
      <Field label="Street address"><input className="input" value={f.address_description} onChange={(e) => setF({ ...f, address_description: e.target.value })} /></Field>
      <Field label="Phone"><input className="input" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></Field>
      {withDescription && <Field label="Description (services, departments)"><textarea className="input" rows={3} value={f.description} onChange={(e) => setF({ ...f, description: e.target.value })} /></Field>}
      <Button type="submit" busy={busy} className="w-full">Send request</Button>
    </form>
  );
}
