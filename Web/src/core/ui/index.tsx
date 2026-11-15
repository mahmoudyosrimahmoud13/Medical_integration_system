import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';

/* ------------------------------------------------------------------ logo */

export function Logo({ size = 36, className = '' }: { size?: number; className?: string }) {
  return <img src="/logo.svg" width={size} height={size} alt="HealthHub" className={`rounded-[22%] ${className}`} />;
}

export function Wordmark({ size = 32, onDark = false }: { size?: number; onDark?: boolean }) {
  return (
    <span className="inline-flex items-center gap-2.5">
      <Logo size={size} />
      <span className={`font-bold tracking-tight ${onDark ? 'text-white' : 'text-navy'}`} style={{ fontSize: size * 0.62 }}>HealthHub</span>
    </span>
  );
}

/* ------------------------------------------------------------------ toasts */

type Toast = { id: number; text: string; error?: boolean };
const ToastCtx = createContext<(text: string, error?: boolean) => void>(() => {});
export const useToast = () => useContext(ToastCtx);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<Toast[]>([]);
  const push = useCallback((text: string, error = false) => {
    const id = Date.now() + Math.random();
    setItems((xs) => [...xs, { id, text, error }]);
    setTimeout(() => setItems((xs) => xs.filter((x) => x.id !== id)), 3200);
  }, []);
  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="pointer-events-none fixed inset-x-0 bottom-4 z-50 flex flex-col items-center gap-2 px-4" aria-live="polite">
        {items.map((t) => (
          <div key={t.id} role="status" className={`pop pointer-events-auto flex max-w-md items-center gap-2 rounded-xl px-4 py-3 text-sm font-medium text-white shadow-lg ${t.error ? 'bg-danger' : 'bg-navy'}`}>
            <span aria-hidden>{t.error ? '!' : '✓'}</span>
            {t.text}
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

/* ------------------------------------------------------------------ primitives */

export function Avatar({ name, url, size = 40 }: { name: string; url?: string | null; size?: number }) {
  const initials = name.trim().split(/\s+/).filter(Boolean).slice(0, 2).map((p) => p[0]!.toUpperCase()).join('') || '?';
  const real = url && !url.endsWith('/default.png');
  return real ? (
    <img src={url} alt="" width={size} height={size} className="shrink-0 rounded-full object-cover" style={{ width: size, height: size }} />
  ) : (
    <span className="inline-flex shrink-0 items-center justify-center rounded-full bg-indigo-100 font-bold text-indigo" style={{ width: size, height: size, fontSize: size * 0.38 }} aria-hidden>
      {initials}
    </span>
  );
}

export function Card({ children, className = '', onClick, index }: { children: ReactNode; className?: string; onClick?: () => void; index?: number }) {
  const cls = `card ${onClick ? 'pressable cursor-pointer hover:border-indigo/40' : ''} ${index !== undefined ? 'rise' : ''} ${className}`;
  const style = index !== undefined ? ({ ['--i' as string]: index } as React.CSSProperties) : undefined;
  return onClick ? (
    <button type="button" onClick={onClick} className={`${cls} w-full text-left`} style={style}>{children}</button>
  ) : (
    <div className={cls} style={style}>{children}</div>
  );
}

export function Button({ busy, variant = 'primary', className = '', children, ...rest }: React.ButtonHTMLAttributes<HTMLButtonElement> & { busy?: boolean; variant?: 'primary' | 'amber' | 'ghost' | 'danger' }) {
  const v = { primary: 'btn-primary', amber: 'btn-amber', ghost: 'btn-ghost', danger: 'btn-danger' }[variant];
  return (
    <button {...rest} disabled={busy || rest.disabled} className={`${v} ${className}`}>
      {busy && <span className="size-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden />}
      {children}
    </button>
  );
}

export function Field({ label, error, children, hint }: { label: string; error?: string; hint?: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="label">{label}</span>
      {children}
      {error ? <span className="mt-1 block text-xs font-medium text-danger">{error}</span> : hint ? <span className="mt-1 block text-xs text-muted">{hint}</span> : null}
    </label>
  );
}

export function Badge({ status }: { status: string }) {
  const map: Record<string, [string, string]> = {
    accepted: ['bg-mint-100 text-[#0e8c6a]', 'Accepted'],
    pending: ['bg-amber-100 text-[#8a5b00]', 'Under review'],
    rejected: ['bg-danger-100 text-danger', 'Rejected'],
    booked: ['bg-indigo-100 text-indigo', 'Booked'],
    cancelled: ['bg-danger-100 text-danger', 'Cancelled'],
    done: ['bg-line text-muted', 'Done'],
  };
  const [cls, label] = map[status] ?? ['bg-line text-muted', status];
  return <span className={`badge ${cls}`}>{label}</span>;
}

export function Stars({ value, count, size = 14 }: { value: number; count?: number; size?: number }) {
  return (
    <span className="inline-flex items-center gap-0.5 text-amber" aria-label={`${value} out of 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <svg key={i} width={size} height={size} viewBox="0 0 24 24" fill={value >= i - 0.25 ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={1.8} aria-hidden>
          <path d="M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6L2.5 9.4l6.6-.8z" />
        </svg>
      ))}
      {count !== undefined && <span className="ml-1 text-xs text-muted">({count})</span>}
    </span>
  );
}

export function Skeleton({ className = 'h-4 w-full' }: { className?: string }) {
  return <div className={`skeleton ${className}`} aria-hidden />;
}

export function SkeletonList({ count = 4 }: { count?: number }) {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Loading">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="card flex items-center gap-4 p-4">
          <Skeleton className="size-12 rounded-full" />
          <div className="flex-1 space-y-2"><Skeleton className="h-4 w-1/2" /><Skeleton className="h-3 w-3/4" /><Skeleton className="h-3 w-1/3" /></div>
        </div>
      ))}
    </div>
  );
}

export function Empty({ title, text, action }: { title: string; text?: string; action?: ReactNode }) {
  return (
    <div className="rise flex flex-col items-center gap-3 py-16 text-center">
      <img src="/empty.svg" alt="" width={140} height={140} className="opacity-90" />
      <h3 className="text-lg font-bold">{title}</h3>
      {text && <p className="max-w-sm text-sm text-muted">{text}</p>}
      {action}
    </div>
  );
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="rise rounded-xl border border-danger/30 bg-danger-100 p-4 text-sm text-danger">
      <p className="font-semibold">Something went wrong</p>
      <p>{message}</p>
      {onRetry && <button type="button" onClick={onRetry} className="mt-2 font-semibold underline">Try again</button>}
    </div>
  );
}

export function PageHeader({ eyebrow, title, children, right }: { eyebrow?: string; title: string; children?: ReactNode; right?: ReactNode }) {
  return (
    <header className="hero rounded-b-3xl px-6 pb-8 pt-10 text-white md:rounded-3xl md:px-10">
      <div className="mx-auto flex max-w-5xl items-start justify-between gap-6">
        <div className="rise">
          {eyebrow && <p className="text-sm text-white/70">{eyebrow}</p>}
          <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">{title}</h1>
        </div>
        {right && <div className="rise" style={{ ['--i' as string]: 2 } as React.CSSProperties}>{right}</div>}
      </div>
      {children && <div className="rise mx-auto mt-6 max-w-5xl" style={{ ['--i' as string]: 3 } as React.CSSProperties}>{children}</div>}
    </header>
  );
}

export function Section({ title, action, children }: { title: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="mt-8">
      <div className="mb-3 flex items-center justify-between">
        <h2 className="text-lg font-bold">{title}</h2>
        {action}
      </div>
      {children}
    </section>
  );
}

/** A number that counts up when it first appears. */
export function Stat({ label, value, tone = 'indigo' }: { label: string; value: number; tone?: 'indigo' | 'mint' | 'amber' | 'danger' }) {
  const [shown, setShown] = useState(0);
  useEffect(() => {
    let frame = 0;
    const start = performance.now();
    const tick = (t: number) => {
      const p = Math.min(1, (t - start) / 800);
      setShown(Math.round(value * (1 - Math.pow(1 - p, 3))));
      if (p < 1) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [value]);
  const bar = { indigo: 'bg-indigo', mint: 'bg-mint', amber: 'bg-amber', danger: 'bg-danger' }[tone];
  return (
    <div className="card p-4">
      <div className={`mb-3 h-1.5 w-8 rounded-full ${bar}`} />
      <p className="text-3xl font-bold tabular-nums">{shown}</p>
      <p className="text-sm text-muted">{label}</p>
    </div>
  );
}

export function Modal({ open, onClose, title, children }: { open: boolean; onClose: () => void; title: string; children: ReactNode }) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-40 flex items-end justify-center bg-navy/40 p-0 backdrop-blur-[2px] sm:items-center sm:p-4" onClick={onClose}>
      <div role="dialog" aria-modal="true" aria-label={title} className="pop max-h-[92vh] w-full max-w-lg overflow-y-auto rounded-t-3xl bg-white p-6 shadow-2xl sm:rounded-3xl" onClick={(e) => e.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-xl font-bold">{title}</h2>
          <button type="button" onClick={onClose} aria-label="Close" className="rounded-full p-2 hover:bg-paper">✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Tabs<T extends string>({ value, onChange, items }: { value: T; onChange: (v: T) => void; items: { value: T; label: string }[] }) {
  return (
    <div role="tablist" className="inline-flex rounded-xl bg-white/15 p-1">
      {items.map((it) => (
        <button key={it.value} role="tab" aria-selected={value === it.value} type="button" onClick={() => onChange(it.value)}
          className={`rounded-lg px-4 py-1.5 text-sm font-semibold transition-colors ${value === it.value ? 'bg-white text-navy' : 'text-white hover:bg-white/10'}`}>
          {it.label}
        </button>
      ))}
    </div>
  );
}
