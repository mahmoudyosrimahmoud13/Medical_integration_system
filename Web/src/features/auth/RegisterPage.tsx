import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';

import { auth } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Button, Field, useToast } from '../../core/ui';
import { v } from '../../core/validators';
import { AreaPicker } from '../catalog/pickers';
import { AuthFrame } from './LoginPage';
import { tr } from '../../core/i18n/i18n';

export function RegisterPage() {
  const [f, setF] = useState({ name: '', email: '', phone: '', national_id: '', birth_date: '', gender: 'male', password: '', confirm: '', area_id: '' });
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const navigate = useNavigate();
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setF({ ...f, [k]: e.target.value });

  const errors = {
    name: v.name(f.name), email: v.email(f.email), phone: v.phone(f.phone), national_id: v.nationalId(f.national_id),
    birth_date: f.birth_date ? '' : tr('Pick your birth date'), password: v.password(f.password),
    confirm: f.confirm === f.password ? '' : "Passwords don't match", area_id: f.area_id ? '' : tr('Pick your area'),
  };
  const show = (k: keyof typeof errors) => (touched ? errors[k] : '');

  async function submit(e: FormEvent) {
    e.preventDefault();
    setTouched(true);
    if (Object.values(errors).some(Boolean)) return;
    setBusy(true);
    try {
      const { confirm: _c, ...body } = f;
      await auth.register(body);
      toast(tr('Account created. You can log in now.'));
      navigate('/login');
    } catch (err) {
      toast(err instanceof ApiError ? tr(err.message) : tr('Something went wrong'), true);
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthFrame title={tr('Create your account')} subtitle={tr('Book doctors, keep your record, find medicines')} footer={<>{tr('Already have an account?')} <Link to="/login" className="font-semibold text-amber hover:underline">{tr('Log in')}</Link></>}>
      <form onSubmit={submit} noValidate className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2"><Field label={tr('Full name')} error={show('name')}><input className="input" value={f.name} onChange={set('name')} /></Field></div>
        <Field label={tr('Email')} error={show('email')}><input type="email" className="input" value={f.email} onChange={set('email')} /></Field>
        <Field label={tr('Mobile number')} error={show('phone')}><input className="input" placeholder="01012345678" value={f.phone} onChange={set('phone')} /></Field>
        <Field label={tr('National ID')} error={show('national_id')}><input className="input" maxLength={14} value={f.national_id} onChange={set('national_id')} /></Field>
        <Field label={tr('Birth date')} error={show('birth_date')}><input type="date" className="input" value={f.birth_date} onChange={set('birth_date')} /></Field>
        <Field label={tr('Gender')}><select className="input" value={f.gender} onChange={set('gender')}><option value="male">{tr('Male')}</option><option value="female">{tr('Female')}</option></select></Field>
        <div className="sm:col-span-2"><AreaPicker onChange={(_, a) => setF((x) => ({ ...x, area_id: a ?? '' }))} error={show('area_id')} /></div>
        <Field label={tr('Password')} error={show('password')} hint={tr('Upper and lower case, a number and a symbol')}><input type="password" className="input" value={f.password} onChange={set('password')} /></Field>
        <Field label={tr('Confirm password')} error={show('confirm')}><input type="password" className="input" value={f.confirm} onChange={set('confirm')} /></Field>
        <div className="sm:col-span-2"><Button type="submit" busy={busy} className="w-full">{tr('Create account')}</Button></div>
      </form>
    </AuthFrame>
  );
}
