import { afterEach, describe, expect, it } from 'vitest';
import { clock, place, tr, useLang } from './i18n';
import { ar } from './ar';

afterEach(() => useLang.getState().setLang('en'));

describe('i18n', () => {
  it('switches the page to right-to-left Arabic', () => {
    useLang.getState().setLang('ar');
    expect(document.documentElement.dir).toBe('rtl');
    expect(document.documentElement.lang).toBe('ar');
    expect(tr('Book a doctor')).toBe('احجز طبيبًا');
    useLang.getState().setLang('en');
    expect(document.documentElement.dir).toBe('ltr');
    expect(tr('Book a doctor')).toBe('Book a doctor');
  });
  it('fills placeholders and falls back to English for unknown text', () => {
    useLang.getState().setLang('ar');
    expect(tr('{n} EGP', { n: 400 })).toBe('400 ج.م');
    expect(tr('Some text nobody translated')).toBe('Some text nobody translated');
  });
  it('uses the Arabic place names from the database and ص / م for times', () => {
    useLang.getState().setLang('ar');
    expect(place({ key: 'Maadi', name_ar: 'المعادى' })).toBe('المعادى');
    expect(place('Maadi')).toBe('المعادى'); // remembered once seen
    expect(clock('01:00 PM')).toBe('01:00 م');
  });
  it('has an Arabic entry for every weekday and specialty the server sends', () => {
    for (const k of ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Cardiology', 'Paediatrics', 'Email Or Password Incorrect']) {
      expect(ar[k], k).toBeTruthy();
    }
  });
});
