import { useTheme, type ThemeMode } from '../theme/theme';
import { Icon, type IconName } from './icons';
import { tr } from '../i18n/i18n';

const OPTIONS = (): { mode: ThemeMode; label: string; icon: IconName }[] => [
  { mode: 'light', label: tr('Light'), icon: 'sun' },
  { mode: 'system', label: tr('Auto'), icon: 'monitor' },
  { mode: 'dark', label: tr('Dark'), icon: 'moon' },
];

/** Three-way switch: light, follow the system, dark. */
export function ThemeSwitch({ className = '', showLabels = false }: { className?: string; showLabels?: boolean }) {
  const { mode, setMode } = useTheme();
  return (
    <div role="group" aria-label={tr('Appearance')} className={`flex rounded-xl border border-line bg-surface-2 p-1 ${className}`}>
      {OPTIONS().map((o) => (
        <button
          key={o.mode}
          type="button"
          aria-pressed={mode === o.mode}
          title={o.mode === 'system' ? tr('Follow this device') : tr('{mode} mode', { mode: o.label })}
          onClick={() => setMode(o.mode)}
          className={`flex flex-1 items-center justify-center gap-1.5 rounded-lg px-2 py-1.5 text-xs font-semibold transition-colors ${
            mode === o.mode ? 'bg-surface text-indigo shadow-card' : 'text-muted hover:text-ink'
          }`}
        >
          <Icon name={o.icon} size={16} />
          {(showLabels || mode === o.mode) && <span>{o.label}</span>}
        </button>
      ))}
    </div>
  );
}
