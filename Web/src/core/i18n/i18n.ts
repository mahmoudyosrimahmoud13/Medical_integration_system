/**
 * English and Arabic. The English text is the key: t('Book a doctor') returns the Arabic when Arabic
 * is on, and the English otherwise (also when a translation is missing). {name} placeholders are
 * filled from the second argument. The choice is saved in this browser and sets <html lang dir>.
 */
import { create } from 'zustand';

import { ar } from './ar';

export type Lang = 'en' | 'ar';
const KEY = 'healthhub-lang';

function initial(): Lang {
  try {
    const saved = localStorage.getItem(KEY);
    if (saved === 'ar' || saved === 'en') return saved;
  } catch {
    /* no storage: fall through */
  }
  return typeof navigator !== 'undefined' && navigator.language?.toLowerCase().startsWith('ar') ? 'ar' : 'en';
}

export function applyLang(lang: Lang) {
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
}

export const useLang = create<{ lang: Lang; setLang: (l: Lang) => void }>((set) => ({
  lang: initial(),
  setLang: (lang) => {
    try {
      localStorage.setItem(KEY, lang);
    } catch {
      /* the choice lasts until the tab closes */
    }
    applyLang(lang);
    set({ lang });
  },
}));

export function initLang() {
  applyLang(useLang.getState().lang);
}

function fill(text: string, vars?: Record<string, string | number>) {
  return vars ? text.replace(/\{(\w+)\}/g, (_, k: string) => String(vars[k] ?? `{${k}}`)) : text;
}

/** Translate outside React (or where re-rendering on language change is handled elsewhere). */
export function tr(text: string, vars?: Record<string, string | number>): string {
  const out = useLang.getState().lang === 'ar' ? (ar[text] ?? text) : text;
  return fill(out, vars);
}

/** Hook: components using it re-render when the language changes. */
export function useT() {
  const lang = useLang((s) => s.lang);
  return (text: string, vars?: Record<string, string | number>) => fill(lang === 'ar' ? (ar[text] ?? text) : text, vars);
}

/** The locale for dates and numbers. Arabic uses Egyptian formatting. */
export const locale = () => (useLang.getState().lang === 'ar' ? 'ar-EG' : 'en-GB');

const placeNames = new Map<string, string>();

/** A governorate or area in the current language (the database stores the Arabic name). Some API
 * answers only carry the English name as text; those use the Arabic names already seen. */
export function place(p?: { key: string; name_ar?: string | null } | string | null): string {
  if (!p) return '';
  const ar = useLang.getState().lang === 'ar';
  if (typeof p === 'string') return ar ? (placeNames.get(p) ?? p) : p;
  if (p.name_ar) placeNames.set(p.key, p.name_ar);
  return ar && p.name_ar ? p.name_ar : p.key;
}

/** Remember Arabic names from a list (for example all governorates) without showing them. */
export function rememberPlaces(list?: { key: string; name_ar?: string | null }[]) {
  list?.forEach((p) => p.name_ar && placeNames.set(p.key, p.name_ar));
}

/** Clock times from the server ("01:00 PM") with ص / م in Arabic. Only for showing; send the original to the server. */
export function clock(t?: string | null): string {
  if (!t) return '';
  return useLang.getState().lang === 'ar' ? t.replace(/\bAM\b/, 'ص').replace(/\bPM\b/, 'م') : t;
}
