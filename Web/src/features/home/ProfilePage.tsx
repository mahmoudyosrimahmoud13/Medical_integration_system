import { useQuery } from '@tanstack/react-query';
import { useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import { workspaceHome } from '../../app/Shell';
import { auth, notifications } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { Workspace } from '../../core/api/types';
import { workspacesOf } from '../../core/api/types';
import { useAuthStore } from '../../core/auth/store';
import { Avatar, Button, Card, Section, useToast, Wordmark } from '../../core/ui';
import { ThemeSwitch } from '../../core/ui/ThemeSwitch';
import { LangSwitch } from '../../core/ui/LangSwitch';
import { fmtDate, fmtTime } from '../../core/time';
import { tr, place } from '../../core/i18n/i18n';

export function ProfilePage() {
  const { user, workspace, switchWorkspace, setUser, logout } = useAuthStore();
  const toast = useToast();
  const navigate = useNavigate();
  const file = useRef<HTMLInputElement>(null);
  const notes = useQuery({ queryKey: ['notifications'], queryFn: notifications.all });
  if (!user) return null;
  const ws = workspacesOf(user);

  async function photo(f?: File) {
    if (!f) return;
    try { setUser(await auth.changePhoto(f)); toast(tr('Photo updated')); } catch (e) { toast(e instanceof ApiError ? tr(e.message) : tr('Upload failed'), true); }
  }

  return (
    <div className="mx-auto max-w-3xl">
      <header className="hero rounded-b-3xl px-6 py-10 text-center text-white md:rounded-3xl">
        <button type="button" className="pop relative inline-block" onClick={() => file.current?.click()} aria-label={tr('Change photo')}>
          <Avatar name={user.name} url={user.image_url} size={96} />
          <span className="absolute -bottom-1 -end-1 flex size-8 items-center justify-center rounded-full bg-surface text-ink shadow">✎</span>
        </button>
        <input ref={file} type="file" accept="image/*" hidden onChange={(e) => photo(e.target.files?.[0])} />
        <h1 className="rise mt-4 text-2xl font-bold">{user.name}</h1>
        <p className="rise text-white/70">{user.email}{user.area ? ` · ${place(user.area)}${tr(', ')}${place(user.governorate)}` : ''}</p>
      </header>
      <div className="px-4 md:px-0">
        {ws.length > 1 && (
          <Section title={tr('Workspace')}>
            <div className="flex flex-wrap gap-2">
              {ws.map((w) => (
                <button key={w} type="button" onClick={() => { switchWorkspace(w as Workspace); navigate(workspaceHome[w as Workspace]); }}
                  className={`rounded-full px-4 py-2 text-sm font-semibold capitalize transition-colors ${workspace === w ? 'bg-indigo text-white' : 'border border-line bg-surface hover:bg-surface-2'}`}>{w}</button>
              ))}
            </div>
          </Section>
        )}
        <Section title={tr('Appearance')}>
          <Card className="flex flex-wrap items-center justify-between gap-3 p-4">
            <span className="text-sm text-muted">{tr('Light, dark, or follow this device')}</span>
            <ThemeSwitch showLabels className="w-full sm:w-72" />
          </Card>
          <Card className="mt-3 flex flex-wrap items-center justify-between gap-3 p-4">
            <span className="text-sm text-muted">{tr('Language')}</span>
            <LangSwitch />
          </Card>
        </Section>
        <Section title={tr('Account')}>
          <Card className="divide-y divide-line p-0">
            {!user.roles.includes('Doctor') && <Link to="/join/doctor" className="block px-5 py-3.5 font-semibold hover:bg-surface-2">{tr('Join as a doctor')}</Link>}
            {!user.roles.includes('Pharmacy') && <Link to="/pharmacy" className="block px-5 py-3.5 font-semibold hover:bg-surface-2">{tr('Register a pharmacy')}</Link>}
            {!user.roles.includes('Hospital') && <Link to="/hospital" className="block px-5 py-3.5 font-semibold hover:bg-surface-2">{tr('Register a hospital')}</Link>}
            <button type="button" onClick={() => { logout(); navigate('/login'); }} className="block w-full px-5 py-3.5 text-start font-semibold text-danger hover:bg-surface-2">{tr('Log out')}</button>
          </Card>
        </Section>
        <Section title={tr('Notifications')}>
          {notes.data?.length === 0 && <Card className="p-4 text-sm text-muted">{tr("You're all caught up.")}</Card>}
          <div className="space-y-2">
            {notes.data?.map((n, i) => (
              <Card key={n.id} index={i} className={`flex items-start gap-3 p-4 ${n.is_read ? '' : 'border-indigo/30 bg-indigo-100/40'}`}>
                <span className={`mt-1.5 size-2 shrink-0 rounded-full ${n.is_read ? 'bg-line' : 'bg-indigo'}`} />
                <div className="min-w-0 flex-1"><p className={`text-sm ${n.is_read ? '' : 'font-semibold'}`}>{n.message}</p><p className="text-xs text-muted">{fmtDate(n.created_at)} {fmtTime(n.created_at)}</p></div>
                {!n.is_read && <Button variant="ghost" className="!px-2 !py-1 text-xs" onClick={async () => { await notifications.read(n.id); notes.refetch(); }}>{tr('Mark read')}</Button>}
              </Card>
            ))}
          </div>
        </Section>
        <div className="my-10 flex justify-center opacity-60"><Wordmark size={24} /></div>
      </div>
    </div>
  );
}
