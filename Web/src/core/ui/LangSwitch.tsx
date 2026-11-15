import { useLang } from '../i18n/i18n';

/** Switches between English and Arabic. Shows the other language's name, in that language. */
export function LangSwitch({ className = '', onDark = false }: { className?: string; onDark?: boolean }) {
  const { lang, setLang } = useLang();
  const next = lang === 'ar' ? 'en' : 'ar';
  return (
    <button
      type="button"
      onClick={() => setLang(next)}
      lang={next}
      aria-label={next === 'ar' ? 'التبديل إلى العربية' : 'Switch to English'}
      className={`inline-flex items-center justify-center gap-2 rounded-xl border px-3 py-2 text-sm font-semibold transition-colors ${
        onDark ? 'border-white/25 text-white hover:bg-white/10' : 'border-line bg-surface text-ink hover:bg-surface-2'
      } ${className}`}
    >
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18ZM3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3Z" />
      </svg>
      {next === 'ar' ? 'العربية' : 'English'}
    </button>
  );
}
