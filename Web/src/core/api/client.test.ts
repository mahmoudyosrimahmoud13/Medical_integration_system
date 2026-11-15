import { describe, expect, it } from 'vitest';
import { http, HttpResponse } from 'msw';

import { api, ApiError, messageFromBody, query } from './client';
import { API, server } from '../../test/server';
import { useAuthStore } from '../auth/store';
import type { User } from './types';

const user = { id: '1', name: 'Sara Ali', email: 's@x.co', roles: ['Patient'] } as unknown as User;

describe('messageFromBody', () => {
  it('reads plain FastAPI errors', () => {
    expect(messageFromBody({ detail: 'Slot taken' }, 'x')).toBe('Slot taken');
  });
  it('reads validation errors with the field name', () => {
    expect(messageFromBody({ detail: [{ loc: ['body', 'phone_number'], msg: 'Value error, bad phone' }] }, 'x')).toBe('phone number: bad phone');
  });
  it('falls back when the body is unknown', () => {
    expect(messageFromBody('oops', 'fallback')).toBe('fallback');
  });
});

describe('query', () => {
  it('skips empty values', () => {
    expect(query({ q: 'pan', area: '', page: 2, x: undefined })).toBe('?q=pan&page=2');
    expect(query({})).toBe('');
  });
});

describe('api', () => {
  it('sends the saved token', async () => {
    useAuthStore.getState().login('tok-123', user);
    server.use(http.get(`${API}/me`, ({ request }) => HttpResponse.json({ auth: request.headers.get('authorization') })));
    await expect(api.get<{ auth: string }>('/me')).resolves.toEqual({ auth: 'Bearer tok-123' });
  });
  it('turns server errors into ApiError with the server message', async () => {
    server.use(http.post(`${API}/things`, () => HttpResponse.json({ detail: 'Already booked' }, { status: 409 })));
    const err = (await api.post("/things", {}).catch((e: unknown) => e)) as ApiError;
    expect(err).toBeInstanceOf(ApiError);
    expect(err.message).toBe('Already booked');
    expect(err.status).toBe(409);
  });
  it('logs out when the token is rejected', async () => {
    useAuthStore.getState().login('expired', user);
    server.use(http.get(`${API}/me`, () => new HttpResponse(null, { status: 401 })));
    await expect(api.get('/me')).rejects.toMatchObject({ isUnauthorized: true });
    expect(useAuthStore.getState().token).toBeNull();
  });
});
