import { tr } from './i18n/i18n';

/** Same rules as the server, so the form says what's wrong before sending. Each returns '' when fine. */
export const v = {
  required: (s: string, field = 'This field') => (s.trim() ? '' : tr('{field} is required', { field: tr(field) })),
  email: (s: string) => (!s.trim() ? tr('Email is required') : /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(s.trim()) ? '' : tr('Enter a valid email')),
  password: (s: string) =>
    !s ? tr('Password is required') : s.length < 8 ? tr('At least 8 characters') : /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[_#$^+=!*()@%&]).{8,}$/.test(s) ? '' : tr('Use upper and lower case letters, a number and a symbol'),
  phone: (s: string) => (!s.trim() ? tr('Phone is required') : /^(?:\+20|0)?1[0125]\d{8}$/.test(s.trim()) ? '' : tr('Use an Egyptian mobile number, like 01012345678')),
  nationalId: (s: string) => (!s.trim() ? tr('National ID is required') : /^[23]\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{7}$/.test(s.trim()) ? '' : tr('National ID must be 14 valid digits')),
  name: (s: string) => (s.trim().length < 3 ? tr('Enter your full name') : ''),
};
