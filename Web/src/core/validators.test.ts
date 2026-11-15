import { describe, expect, it } from 'vitest';
import { v } from './validators';

describe('validators', () => {
  it('checks passwords like the server', () => {
    expect(v.password('short')).not.toBe('');
    expect(v.password('nouppercase1!')).not.toBe('');
    expect(v.password('Patient@12345')).toBe('');
  });
  it('accepts Egyptian mobile numbers only', () => {
    expect(v.phone('01012345678')).toBe('');
    expect(v.phone('+201112345678')).toBe('');
    expect(v.phone('0123')).not.toBe('');
  });
  it('checks the national ID shape', () => {
    expect(v.nationalId('29801011234567')).toBe('');
    expect(v.nationalId('19801011234567')).not.toBe('');
    expect(v.nationalId('2981301123456')).not.toBe('');
  });
  it('checks emails and names', () => {
    expect(v.email('a@b.co')).toBe('');
    expect(v.email('nope')).not.toBe('');
    expect(v.name('Al')).not.toBe('');
  });
});
