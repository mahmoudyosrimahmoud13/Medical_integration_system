import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import type { User, Workspace } from '../api/types';
import { workspacesOf } from '../api/types';

interface AuthState {
  token: string | null;
  user: User | null;
  workspace: Workspace;
  login: (token: string, user: User) => void;
  setUser: (user: User) => void;
  setToken: (token: string) => void;
  switchWorkspace: (w: Workspace) => void;
  logout: () => void;
}

/** Login token, user and chosen workspace. Saved in localStorage so a refresh keeps you logged in. */
export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      user: null,
      workspace: 'patient',
      login: (token, user) => {
        const allowed = workspacesOf(user);
        set({ token, user, workspace: allowed[allowed.length - 1] });
      },
      setUser: (user) => {
        const allowed = workspacesOf(user);
        set({ user, workspace: allowed.includes(get().workspace) ? get().workspace : allowed[allowed.length - 1] });
      },
      setToken: (token) => set({ token }),
      switchWorkspace: (w) => {
        const u = get().user;
        if (u && workspacesOf(u).includes(w)) set({ workspace: w });
      },
      logout: () => set({ token: null, user: null, workspace: 'patient' }),
    }),
    { name: 'healthhub-auth' },
  ),
);
