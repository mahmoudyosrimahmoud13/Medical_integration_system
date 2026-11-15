import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { http, HttpResponse } from 'msw';

import { LoginPage } from './LoginPage';
import { API, server } from '../../test/server';

function renderLogin() {
  render(
    <MemoryRouter initialEntries={['/login']} future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/doctor" element={<p>Doctor workspace</p>} />
        <Route path="/home" element={<p>Patient home</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

describe('LoginPage', () => {
  it('asks for both fields before calling the server', async () => {
    renderLogin();
    await userEvent.click(screen.getByRole('button', { name: /log in/i }));
    expect(screen.getByText('Email or username is required')).toBeInTheDocument();
    expect(screen.getByText('Password is required')).toBeInTheDocument();
  });

  it('shows the server message when the password is wrong', async () => {
    server.use(http.post(`${API}/auth/login`, () => HttpResponse.json({ detail: 'Email Or Password Incorrect' }, { status: 401 })));
    renderLogin();
    await userEvent.type(screen.getByLabelText('Email or username'), 'doctor@healthhub.local');
    await userEvent.type(screen.getByLabelText('Password'), 'wrong');
    await userEvent.click(screen.getByRole('button', { name: /log in/i }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Email Or Password Incorrect');
  });

  it('takes a doctor straight to the doctor workspace', async () => {
    server.use(
      http.post(`${API}/auth/login`, () =>
        HttpResponse.json({ access_token: 't', token_type: 'bearer', user: { id: '1', name: 'Ahmed Hassan', email: 'doctor@healthhub.local', roles: ['Patient', 'Doctor'] } }),
      ),
    );
    renderLogin();
    await userEvent.type(screen.getByLabelText('Email or username'), 'doctor@healthhub.local');
    await userEvent.type(screen.getByLabelText('Password'), 'Doctor@12345');
    await userEvent.click(screen.getByRole('button', { name: /log in/i }));
    expect(await screen.findByText('Doctor workspace')).toBeInTheDocument();
  });
});
