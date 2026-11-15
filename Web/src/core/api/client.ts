/** The only place that talks to the server. Tests mock it with MSW at the network level. */

import { useAuthStore } from '../auth/store';

export class ApiError extends Error {
  constructor(message: string, public status: number) {
    super(message);
  }
  get isUnauthorized() { return this.status === 401; }
  get isNotFound() { return this.status === 404; }
}

const base = (import.meta.env.VITE_API_BASE_URL as string | undefined) || '';
export const apiV1 = `${base}/api/v1`;

/** FastAPI answers errors as {detail: "text"} or {detail: [{loc, msg}]} */
export function messageFromBody(body: unknown, fallback: string): string {
  if (body && typeof body === 'object' && 'detail' in body) {
    const d = (body as { detail: unknown }).detail;
    if (typeof d === 'string' && d) return d;
    if (Array.isArray(d) && d.length && d[0] && typeof d[0] === 'object' && 'msg' in d[0]) {
      const first = d[0] as { msg: string; loc?: unknown[] };
      const msg = String(first.msg).replace(/^Value error, /, '');
      const field = Array.isArray(first.loc) ? String(first.loc[first.loc.length - 1]) : '';
      return field && field !== 'body' ? `${field.replace(/_/g, ' ')}: ${msg}` : msg;
    }
  }
  return fallback;
}

async function request<T>(method: string, path: string, body?: unknown, form?: FormData): Promise<T> {
  const token = useAuthStore.getState().token;
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  let res: Response;
  try {
    res = await fetch(`${apiV1}${path}`, { method, headers, body: form ?? (body === undefined ? undefined : JSON.stringify(body)) });
  } catch {
    throw new ApiError("Can't reach the server. Check your connection.", 0);
  }
  if (res.status === 401 && token) useAuthStore.getState().logout();
  const text = await res.text();
  const data = text ? safeJson(text) : null;
  if (!res.ok) {
    const fallback = res.status === 401 ? 'Please log in again.' : res.status === 403 ? "You don't have access to this." : res.status === 404 ? 'Not found.' : 'Something went wrong. Please try again.';
    throw new ApiError(messageFromBody(data, fallback), res.status);
  }
  return data as T;
}

function safeJson(text: string): unknown {
  try { return JSON.parse(text); } catch { return text; }
}

export function query(params: Record<string, unknown>): string {
  const q = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) if (v !== undefined && v !== null && v !== '') q.set(k, String(v));
  const s = q.toString();
  return s ? `?${s}` : '';
}

export const api = {
  get: <T>(path: string, params?: Record<string, unknown>) => request<T>('GET', path + (params ? query(params) : '')),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, body),
  put: <T>(path: string, body?: unknown) => request<T>('PUT', path, body),
  delete: <T>(path: string) => request<T>('DELETE', path),
  upload: <T>(path: string, form: FormData, method: 'POST' | 'PUT' = 'POST') => request<T>(method, path, undefined, form),
};
