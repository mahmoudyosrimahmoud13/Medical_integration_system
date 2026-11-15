import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import './index.css';
import { App } from './app/App';
import { ToastProvider } from './core/ui';
import { initTheme } from './core/theme/theme';
import { initLang, useLang } from './core/i18n/i18n';

initTheme();
initLang();

/** Re-draws every screen when the language changes, so all text switches at once. */
function Localised() {
  const lang = useLang((s) => s.lang);
  return <App key={lang} />;
}

export const queryClient = new QueryClient({ defaultOptions: { queries: { retry: 1, staleTime: 10_000, refetchOnWindowFocus: false } } });

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <Localised />
        </BrowserRouter>
      </ToastProvider>
    </QueryClientProvider>
  </React.StrictMode>,
);
