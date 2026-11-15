import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import { auth } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { useAuthStore } from '../../core/auth/store';
import { Button, Field, Logo } from '../../core/ui';
import { v } from '../../core/validators';
import { workspaceHome } from '../../app/Shell';
import { LangSwitch } from '../../core/ui/LangSwitch';
import { tr } from '../../core/i18n/i18n';

export function AuthFrame({ title, subtitle, children, footer }: { title: string; subtitle: string; children: React.ReactNode; footer?: React.ReactNode }) {
  return (
    <div className="hero min-h-dvh px-4 py-10">
      <div className="mx-auto flex max-w-md justify-end"><LangSwitch onDark /></div>
      <div className="mx-auto max-w-md">
        <div className="rise mb-8 flex flex-col items-center text-center text-white">
          <Logo size={72} className="shadow-2xl" />
          <h1 className="mt-5 text-3xl font-bold tracking-tight">{title}</h1>
          <p className="mt-1 text-white/70">{subtitle}</p>
        </div>
        <div className="card rise p-6 md:p-8" style={{ ['--i' as string]: 3 } as React.CSSProperties}>{children}</div>
        {footer && <p className="rise mt-6 text-center text-sm text-white/80" style={{ ['--i' as string]: 5 } as React.CSSProperties}>{footer}</p>}
      </div>
    </div>
  );
}

export function LoginPage() {
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [touched, setTouched] = useState(false);
  const signIn = useAuthStore((s) => s.login);
  const navigate = useNavigate();

  const loginError = touched ? v.required(login, 'Email or username') : '';
  const passwordError = touched && !password ? tr('Password is required') : '';

  async function submit(e: FormEvent) {
    e.preventDefault();
    setTouched(true);
    if (!login.trim() || !password) return;
    setBusy(true);
    setError('');
    try {
      const res = await auth.login(login, password);
      signIn(res.access_token, res.user);
      navigate(workspaceHome[useAuthStore.getState().workspace], { replace: true });
    } catch (err) {
      setError(err instanceof ApiError ? tr(err.message) : tr('Something went wrong'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthFrame title={tr('Welcome back')} subtitle={tr('Log in to continue to HealthHub')} footer={<>{tr('New to HealthHub?')} <Link to="/register" className="font-semibold text-amber underline-offset-2 hover:underline">{tr('Create an account')}</Link></>}>
      <form onSubmit={submit} noValidate className="space-y-4">
        <Field label={tr('Email or username')} error={loginError}>
          <input className="input" autoComplete="username" value={login} onChange={(e) => setLogin(e.target.value)} />
        </Field>
        <Field label={tr('Password')} error={passwordError}>
          <input type="password" className="input" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} />
        </Field>
        <div className="text-end"><Link to="/forgot-password" className="text-sm font-semibold text-indigo">{tr('Forgot password?')}</Link></div>
        {error && <p role="alert" className="pop rounded-xl bg-danger-100 px-3 py-2 text-sm font-medium text-danger">{error}</p>}
        <Button type="submit" busy={busy} className="w-full">{tr('Log in')}</Button>
      </form>
    </AuthFrame>
  );
}
