import { useQuery } from '@tanstack/react-query';
import { NavLink, Outlet, useLocation } from 'react-router-dom';

import { catalog, chat } from '../core/api/endpoints';
import type { Workspace } from '../core/api/types';
import { workspacesOf } from '../core/api/types';
import { useAuthStore } from '../core/auth/store';
import { Avatar, Wordmark } from '../core/ui';
import { Icon, type IconName } from '../core/ui/icons';
import { ThemeSwitch } from '../core/ui/ThemeSwitch';
import { LangSwitch } from '../core/ui/LangSwitch';
import { tr, rememberPlaces } from '../core/i18n/i18n';

type Item = { to: string; label: string; icon: IconName; end?: boolean };

const NAV = (): Record<Workspace, Item[]> => ({
  patient: [
    { to: '/home', label: tr('Home'), icon: 'home', end: true },
    { to: '/doctors', label: tr('Doctors'), icon: 'doctor' },
    { to: '/appointments', label: tr('Visits'), icon: 'calendar' },
    { to: '/record', label: tr('Record'), icon: 'record' },
    { to: '/pharmacies', label: tr('Pharmacies'), icon: 'pill' },
    { to: '/hospitals', label: tr('Hospitals'), icon: 'hospital' },
    { to: '/messages', label: tr('Messages'), icon: 'message' },
  ],
  doctor: [
    { to: '/doctor', label: tr('Today'), icon: 'home', end: true },
    { to: '/doctor/patients', label: tr('Patients'), icon: 'users' },
    { to: '/doctor/schedule', label: tr('Schedule'), icon: 'clock' },
    { to: '/messages', label: tr('Messages'), icon: 'message' },
  ],
  pharmacy: [
    { to: '/pharmacy', label: tr('Counter'), icon: 'counter', end: true },
    { to: '/pharmacy/stock', label: tr('Stock'), icon: 'box' },
    { to: '/messages', label: tr('Messages'), icon: 'message' },
  ],
  hospital: [
    { to: '/hospital', label: tr('Hospital'), icon: 'hospital', end: true },
    { to: '/messages', label: tr('Messages'), icon: 'message' },
  ],
  admin: [
    { to: '/admin', label: tr('Requests'), icon: 'check', end: true },
    { to: '/messages', label: tr('Messages'), icon: 'message' },
  ],
});

export const workspaceHome: Record<Workspace, string> = { patient: '/home', doctor: '/doctor', pharmacy: '/pharmacy', hospital: '/hospital', admin: '/admin' };

/** Side navigation on desktop, bottom bar on phones. Items depend on the active workspace. */
export function Shell() {
  const { user, workspace, switchWorkspace } = useAuthStore();
  const location = useLocation();
  const unread = useQuery({ queryKey: ['chat', 'unread'], queryFn: chat.unread, refetchInterval: 15_000, select: (d) => d.unread });
  // Arabic governorate names for places that some answers only send as English text
  const govs = useQuery({ queryKey: ['governorates'], queryFn: catalog.governorates, staleTime: Infinity });
  rememberPlaces(govs.data);
  if (!user) return null;
  const items = NAV()[workspace];
  const workspaces = workspacesOf(user);

  const link = (it: Item, mobile: boolean) => (
    <NavLink key={it.to} to={it.to} end={it.end} className={({ isActive }) =>
      mobile
        ? `relative flex flex-1 flex-col items-center gap-1 py-2 text-[11px] font-semibold transition-colors ${isActive ? 'text-indigo' : 'text-muted'}`
        : `relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${isActive ? 'bg-indigo-100 text-indigo before:absolute before:-start-4 before:top-2 before:bottom-2 before:w-1 before:rounded-e-full before:bg-indigo' : 'text-ink hover:bg-surface-2'}`}>
      <span className="relative" aria-hidden>
        <Icon name={it.icon} size={mobile ? 22 : 20} />
        {it.to === '/messages' && !!unread.data && <span className="absolute -end-1.5 -top-1 size-2.5 rounded-full bg-amber ring-2 ring-surface" />}
      </span>
      <span>{it.label}</span>
    </NavLink>
  );

  return (
    <div className="min-h-dvh md:flex">
      <aside className="hidden w-64 shrink-0 flex-col border-e border-line bg-surface p-4 md:flex md:sticky md:top-0 md:h-dvh">
        <NavLink to={workspaceHome[workspace]} className="mb-6 block px-2"><Wordmark size={34} /></NavLink>
        {workspaces.length > 1 && (
          <select aria-label={tr('Workspace')} value={workspace} onChange={(e) => switchWorkspace(e.target.value as Workspace)} className="input mb-4 capitalize">
            {workspaces.map((w) => <option key={w} value={w}>{tr('{w} workspace', { w: tr(w) })}</option>)}
          </select>
        )}
        <nav className="flex flex-col gap-1">{items.map((it) => link(it, false))}</nav>
        <div className="mt-auto mb-3 flex flex-col gap-2"><LangSwitch /><ThemeSwitch /></div>
        <NavLink to="/profile" className={({ isActive }) => `flex items-center gap-3 rounded-xl px-3 py-2 ${isActive ? 'bg-indigo-100' : 'hover:bg-surface-2'}`}>
          <Avatar name={user.name} url={user.image_url} size={36} />
          <span className="min-w-0"><span className="block truncate text-sm font-semibold">{user.name}</span><span className="block text-xs capitalize text-muted">{tr(workspace)}</span></span>
        </NavLink>
      </aside>

      <main className="min-w-0 flex-1 pb-20 md:pb-8">
        <div key={location.pathname} className="rise md:p-6">
          <Outlet />
        </div>
      </main>

      <nav className="fixed inset-x-0 bottom-0 z-30 flex border-t border-line bg-surface/90 backdrop-blur-md md:hidden" aria-label={tr('Main')}>
        {items.slice(0, 4).map((it) => link(it, true))}
        <NavLink to="/profile" className={({ isActive }) => `flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-semibold ${isActive ? 'text-indigo' : 'text-muted'}`}>
          <Avatar name={user.name} url={user.image_url} size={20} /><span>{tr('Profile')}</span>
        </NavLink>
      </nav>
    </div>
  );
}
