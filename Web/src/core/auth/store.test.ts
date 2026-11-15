import { describe, expect, it } from 'vitest';
import { useAuthStore } from './store';
import type { User } from '../api/types';

const make = (roles: string[]) => ({ id: '1', name: 'X', email: 'x@y.co', roles }) as unknown as User;

describe('auth store', () => {
  it('opens the newest role workspace on login, not the one saved from the last person', () => {
    useAuthStore.getState().login('a', make(['Patient']));
    expect(useAuthStore.getState().workspace).toBe('patient');
    useAuthStore.getState().login('b', make(['Patient', 'Doctor']));
    expect(useAuthStore.getState().workspace).toBe('doctor');
    useAuthStore.getState().login('c', make(['Patient', 'Pharmacy']));
    expect(useAuthStore.getState().workspace).toBe('pharmacy');
  });
  it('only switches to workspaces the user has', () => {
    useAuthStore.getState().login('a', make(['Patient', 'Doctor']));
    useAuthStore.getState().switchWorkspace('admin');
    expect(useAuthStore.getState().workspace).toBe('doctor');
    useAuthStore.getState().switchWorkspace('patient');
    expect(useAuthStore.getState().workspace).toBe('patient');
  });
  it('clears everything on logout', () => {
    useAuthStore.getState().login('a', make(['Patient']));
    useAuthStore.getState().logout();
    expect(useAuthStore.getState()).toMatchObject({ token: null, user: null, workspace: 'patient' });
  });
});
