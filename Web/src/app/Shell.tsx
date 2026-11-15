import { useQuery } from '@tanstack/react-query';
import { NavLink, Outlet, useLocation } from 'react-router-dom';

import { chat } from '../core/api/endpoints';
import type { Workspace } from '../core/api/types';
import { workspacesOf } from '../core/api/types';
import { useAuthStore } from '../core/auth/store';
import { Avatar, Wordmark } from '../core/ui';

type Item = { to: string; label: string; icon: string; end?: boolean };

const NAV: Record<Workspace, Item[]> = {
  patient: [
    { to: '/home', label: 'Home', icon: '⌂', end: true },
    { to: '/doctors', label: 'Doctors', icon: '⚕' },
    { to: '/appointments', label: 'Visits', icon: '▦' },
    { to: '/record', label: 'Record', icon: '▤' },
    { to: '/pharmacies', label: 'Pharmacies', icon: '✚' },
    { to: '/hospitals', label: 'Hospitals', icon: '▣' },
    { to: '/messages', label: 'Messages', icon: '✉' },
  ],
  doctor: [
    { to: '/doctor', label: 'Today', icon: '⌂', end: true },
    { to: '/doctor/patients', label: 'Patients', icon: '☺' },
    { to: '/doctor/schedule', label: 'Schedule', icon: '◷' },
    { to: '/messages', label: 'Messages', icon: '✉' },
  ],
  pharmacy: [
    { to: '/pharmacy', label: 'Counter', icon: '✚', end: true },
    { to: '/pharmacy/stock', label: 'Stock', icon: '▤' },
    { to: '/messages', label: 'Messages', icon: '✉' },
  ],
  hospital: [
    { to: '/hospital', label: 'Hospital', icon: '▣', end: true },
    { to: '/messages', label: 'Messages', icon: '✉' },
  ],
  admin: [
    { to: '/admin', label: 'Requests', icon: '☑', end: true },
    { to: '/messages', label: 'Messages', icon: '✉' },
  ],
};

export const workspaceHome: Record<Workspace, string> = { patient: '/home', doctor: '/doctor', pharmacy: '/pharmacy', hospital: '/hospital', admin: '/admin' };

/** Side navigation on desktop, bottom bar on phones. Items depend on the active workspace. */
export function Shell() {
  const { user, workspace, switchWorkspace } = useAuthStore();
  const location = useLocation();
  const unread = useQuery({ queryKey: ['chat', 'unread'], queryFn: chat.unread, refetchInterval: 15_000, select: (d) => d.unread });
  if (!user) return null;
  const items = NAV[workspace];
  const workspaces = workspacesOf(user);

  const link = (it: Item, mobile: boolean) => (
    <NavLink key={it.to} to={it.to} end={it.end} className={({ isActive }) =>
      mobile
        ? `flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-semibold ${isActive ? 'text-indigo' : 'text-muted'}`
        : `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${isActive ? 'bg-indigo-100 text-indigo' : 'text-ink hover:bg-paper'}`}>
      <span className="relative text-lg leading-none" aria-hidden>
        {it.icon}
        {it.to === '/messages' && !!unread.data && <span className="absolute -right-2 -top-1 size-2.5 rounded-full bg-amber ring-2 ring-white" />}
      </span>
      <span>{it.label}</span>
    </NavLink>
  );

  return (
    <div className="min-h-dvh md:flex">
      <aside className="hidden w-64 shrink-0 flex-col border-r border-line bg-white p-4 md:flex md:sticky md:top-0 md:h-dvh">
        <NavLink to={workspaceHome[workspace]} className="mb-6 block px-2"><Wordmark size={34} /></NavLink>
        {workspaces.length > 1 && (
          <select aria-label="Workspace" value={workspace} onChange={(e) => switchWorkspace(e.target.value as Workspace)} className="input mb-4 capitalize">
            {workspaces.map((w) => <option key={w} value={w}>{w} workspace</option>)}
          </select>
        )}
        <nav className="flex flex-col gap-1">{items.map((it) => link(it, false))}</nav>
        <NavLink to="/profile" className={({ isActive }) => `mt-auto flex items-center gap-3 rounded-xl px-3 py-2 ${isActive ? 'bg-indigo-100' : 'hover:bg-paper'}`}>
          <Avatar name={user.name} url={user.image_url} size={36} />
          <span className="min-w-0"><span className="block truncate text-sm font-semibold">{user.name}</span><span className="block text-xs capitalize text-muted">{workspace}</span></span>
        </NavLink>
      </aside>

      <main className="min-w-0 flex-1 pb-20 md:pb-8">
        <div key={location.pathname} className="rise md:p-6">
          <Outlet />
        </div>
      </main>

      <nav className="fixed inset-x-0 bottom-0 z-30 flex border-t border-line bg-white md:hidden" aria-label="Main">
        {items.slice(0, 4).map((it) => link(it, true))}
        <NavLink to="/profile" className={({ isActive }) => `flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-semibold ${isActive ? 'text-indigo' : 'text-muted'}`}>
          <Avatar name={user.name} url={user.image_url} size={20} /><span>Profile</span>
        </NavLink>
      </nav>
    </div>
  );
}
