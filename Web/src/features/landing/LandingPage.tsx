import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

import { Logo, Wordmark } from '../../core/ui';
import { LangSwitch } from '../../core/ui/LangSwitch';
import { tr } from '../../core/i18n/i18n';

/*
  Design notes
  - One memorable thing: a live, animated "care loop" in the hero. A visit becomes a prescription,
    the prescription becomes a share code, the pharmacy fills it. The product's actual flow, drawn.
  - Everything else is quiet: paper background, navy type, amber only where the eye should land.
  - Instrument Sans throughout, one family, two weights. No eyebrow labels in caps, no numbered steps
    unless the content is a sequence (the care loop is one, so it gets numbers).
*/

const ROLES = () => [
  { to: '/register', title: tr('Patients'), text: tr('Book a doctor in seconds, keep every prescription and scan in one record, and show a pharmacy a 30-minute code instead of a paper slip.') },
  { to: '/join/doctor', title: tr('Doctors'), text: tr('Publish your hours, see who booked, open a patient\'s full history before they sit down, and check drug interactions before you sign.') },
  { to: '/pharmacy', title: tr('Pharmacies'), text: tr('Read the exact prescription from the patient\'s code, keep your stock and prices listed, and let people nearby find what you carry.') },
  { to: '/hospital', title: tr('Hospitals'), text: tr('Put your departments and doctors on the map, and watch the appointments booked with them.') },
];

const LOOP = () => [
  { n: 1, who: tr('Dr. Heba Mahmoud'), what: tr('writes the visit'), detail: tr('Hypothyroidism · Levothyroxine 50 mcg, daily'), tone: 'bg-indigo-100 text-indigo' },
  { n: 2, who: tr('Sara'), what: tr('sees it on her record'), detail: tr('Current medicines: 1 · next refill in 28 days'), tone: 'bg-mint-100 text-[#0e8c6a]' },
  { n: 3, who: tr('Sara'), what: tr('makes a share code'), detail: tr('K7M2PX · valid 30 minutes'), tone: 'bg-amber-100 text-[#8a5b00]' },
  { n: 4, who: tr('El Nour Pharmacy'), what: tr('fills it'), detail: tr('Eltroxin 50 mcg · 80 EGP · in stock'), tone: 'bg-navy text-white' },
];

function CareLoop() {
  const [step, setStep] = useState(0);
  useEffect(() => {
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) return setStep(3);
    const t = setInterval(() => setStep((s) => (s + 1) % LOOP().length), 2200);
    return () => clearInterval(t);
  }, []);
  return (
    <ol className="relative space-y-3" aria-label={tr('How a prescription travels through HealthHub')}>
      {LOOP().map((s, i) => {
        const active = i === step;
        const done = i < step;
        return (
          <li key={s.n} className={`flex items-start gap-4 rounded-2xl border p-4 transition-all duration-500 ${active ? 'scale-[1.02] border-navy/20 bg-surface shadow-card' : done ? 'border-transparent bg-surface/60' : 'border-transparent bg-surface/30 opacity-60'}`}>
            <span className={`flex size-9 shrink-0 items-center justify-center rounded-full text-sm font-bold transition-colors ${active || done ? s.tone : 'bg-line text-muted'}`}>{done ? '✓' : s.n}</span>
            <span className="min-w-0">
              <span className="block font-semibold">{s.who} <span className="font-normal text-muted">{s.what}</span></span>
              <span className={`block truncate text-sm transition-opacity duration-500 ${active ? 'opacity-100' : 'opacity-60'}`}>{s.detail}</span>
            </span>
          </li>
        );
      })}
    </ol>
  );
}

export function LandingPage() {
  return (
    <div className="min-h-dvh bg-paper text-ink">
      <header className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Wordmark size={34} />
        <nav className="flex items-center gap-2">
          <LangSwitch />
          <Link to="/login" className="btn-ghost">{tr('Log in')}</Link>
          <Link to="/register" className="btn-primary">{tr('Create account')}</Link>
        </nav>
      </header>

      <section className="mx-auto grid max-w-6xl items-center gap-12 px-6 pb-20 pt-10 md:grid-cols-2 md:pt-16">
        <div>
          <h1 className="rise text-5xl font-bold leading-[1.05] tracking-tight md:text-6xl">
            {tr('Your doctor, your pharmacy and your record, finally talking to each other.')}
          </h1>
          <p className="rise mt-6 max-w-lg text-lg leading-relaxed text-muted" style={{ ['--i' as string]: 2 } as React.CSSProperties}>
            {tr('HealthHub connects patients, doctors, hospitals and pharmacies around one medical record. Book a visit, get the prescription on your phone, and fill it anywhere with a code.')}
          </p>
          <div className="rise mt-8 flex flex-wrap gap-3" style={{ ['--i' as string]: 4 } as React.CSSProperties}>
            <Link to="/register" className="btn-amber !px-6 !py-3 !text-base">{tr('Start for free')}</Link>
            <Link to="/doctors" className="btn-ghost !px-6 !py-3 !text-base">{tr('Browse doctors')}</Link>
          </div>
          <p className="rise mt-4 text-sm text-muted" style={{ ['--i' as string]: 5 } as React.CSSProperties}>{tr('Free for patients. Doctors, pharmacies and hospitals join after a short review.')}</p>
        </div>
        <div className="rise rounded-3xl bg-gradient-to-br from-indigo-100 via-paper to-amber-100 p-5 md:p-8" style={{ ['--i' as string]: 3 } as React.CSSProperties}>
          <p className="mb-4 text-sm font-semibold text-muted">{tr('One prescription, start to finish')}</p>
          <CareLoop />
        </div>
      </section>

      <section className="hero text-white">
        <div className="mx-auto grid max-w-6xl gap-8 px-6 py-16 md:grid-cols-4">
          {ROLES().map((r, i) => (
            <Link key={r.title} to={r.to} className="rise group rounded-2xl p-1 transition-colors hover:bg-white/5" style={{ ['--i' as string]: i } as React.CSSProperties}>
              <h2 className="text-2xl font-bold text-amber">{r.title}</h2>
              <p className="mt-2 text-sm leading-relaxed text-white/80">{r.text}</p>
              <span className="mt-3 inline-block text-sm font-semibold text-white/90 group-hover:underline">{tr('Get started')}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-20">
        <div className="grid gap-10 md:grid-cols-3">
          <div>
            <h2 className="text-2xl font-bold">{tr('Medicines by the names you know')}</h2>
            <p className="mt-3 leading-relaxed text-muted">{tr('Search Panadol, Concor or Augmentin, and HealthHub finds the pharmacies that stock the ingredient, with price and quantity. 165 products from the Egyptian market, linked to 1,700 active ingredients.')}</p>
          </div>
          <div>
            <h2 className="text-2xl font-bold">{tr('A safety check before every prescription')}</h2>
            <p className="mt-3 leading-relaxed text-muted">{tr('When a doctor adds a drug, HealthHub checks it against everything the patient already takes. Interactions show up before the visit is saved, not after.')}</p>
          </div>
          <div>
            <h2 className="text-2xl font-bold">{tr('Messages that follow the care')}</h2>
            <p className="mt-3 leading-relaxed text-muted">{tr('Patients write to the doctors they booked, pharmacies answer stock questions, hospitals coordinate with their teams. No cold messages, no spam.')}</p>
          </div>
        </div>
      </section>

      <footer className="border-t border-line">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-8 text-sm text-muted md:flex-row">
          <span className="flex items-center gap-2"><Logo size={22} /> {tr('HealthHub')}</span>
          <span>{tr('Built by Mahmoud Yosri. Open source.')}</span>
          <nav className="flex gap-4"><Link to="/login" className="hover:text-ink">{tr('Log in')}</Link><Link to="/register" className="hover:text-ink">{tr('Create account')}</Link></nav>
        </div>
      </footer>
    </div>
  );
}
