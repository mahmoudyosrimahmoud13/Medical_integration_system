import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import { auth } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Button, Field, useToast } from '../../core/ui';
import { v } from '../../core/validators';
import { AuthFrame } from './LoginPage';
import { tr } from '../../core/i18n/i18n';

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      if (!sent) {
        if (v.email(email)) return toast(v.email(email), true);
        await auth.forgot(email);
        setSent(true);
        toast(tr('If this email is registered, a code is on its way.'));
      } else {
        if (v.password(password)) return toast(v.password(password), true);
        await auth.reset(code, password);
        toast(tr('Password changed. Log in with your new password.'));
        navigate('/login');
      }
    } catch (err) {
      toast(err instanceof ApiError ? tr(err.message) : tr('Something went wrong'), true);
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthFrame title={tr('Reset password')} subtitle={sent ? tr('We sent a code to {email}', { email }) : tr("We'll email you a reset code")} footer={<Link to="/login" className="font-semibold text-amber hover:underline">{tr('Back to log in')}</Link>}>
      <form onSubmit={submit} noValidate className="space-y-4">
        {!sent ? (
          <Field label={tr('Email')}><input type="email" className="input" value={email} onChange={(e) => setEmail(e.target.value)} /></Field>
        ) : (
          <div key="step2" className="rise space-y-4">
            <Field label={tr('Reset code')}><input className="input" value={code} onChange={(e) => setCode(e.target.value)} /></Field>
            <Field label={tr('New password')}><input type="password" className="input" value={password} onChange={(e) => setPassword(e.target.value)} /></Field>
          </div>
        )}
        <Button type="submit" busy={busy} className="w-full">{sent ? tr('Change password') : tr('Send code')}</Button>
      </form>
    </AuthFrame>
  );
}
