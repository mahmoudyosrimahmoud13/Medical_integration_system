/** Light, dark, or follow the system. Saved in this browser; applied as the .dark class on <html>. */
import { create } from 'zustand';

export type ThemeMode = 'system' | 'light' | 'dark';
const KEY = 'healthhub-theme';

const systemDark = () => typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: dark)').matches;

function read(): ThemeMode {
  try {
    const v = localStorage.getItem(KEY);
    return v === 'light' || v === 'dark' ? v : 'system';
  } catch {
    return 'system';
  }
}

export function applyTheme(mode: ThemeMode) {
  const dark = mode === 'dark' || (mode === 'system' && systemDark());
  document.documentElement.classList.toggle('dark', !!dark);
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#0E1020' : '#1B1F3B');
}

export const useTheme = create<{ mode: ThemeMode; setMode: (m: ThemeMode) => void }>((set) => ({
  mode: read(),
  setMode: (mode) => {
    try {
      if (mode === 'system') localStorage.removeItem(KEY);
      else localStorage.setItem(KEY, mode);
    } catch {
      /* private mode: the choice lasts until the tab closes */
    }
    applyTheme(mode);
    set({ mode });
  },
}));

/** Call once at start-up: applies the saved choice and follows system changes while on "system". */
export function initTheme() {
  applyTheme(useTheme.getState().mode);
  window.matchMedia?.('(prefers-color-scheme: dark)').addEventListener?.('change', () => {
    if (useTheme.getState().mode === 'system') applyTheme('system');
  });
}
