import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';

import { chat } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import type { ChatMessage } from '../../core/api/types';
import { Avatar, Button, ErrorBox, useToast } from '../../core/ui';
import { fmtDate, fmtTime, sameDay } from '../../core/time';
import { Icon } from '../../core/ui/icons';
import { tr } from '../../core/i18n/i18n';

export function ConversationPage() {
  const { id = '' } = useParams();
  const qc = useQueryClient();
  const toast = useToast();
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const bottom = useRef<HTMLDivElement>(null);

  const convs = useQuery({ queryKey: ['chat', 'conversations'], queryFn: chat.conversations });
  const conv = convs.data?.find((c) => c.id === id);
  const msgs = useQuery({ queryKey: ['chat', id, 'messages'], queryFn: () => chat.messages(id), refetchInterval: 5000 });

  useEffect(() => { bottom.current?.scrollIntoView({ behavior: 'smooth' }); qc.invalidateQueries({ queryKey: ['chat', 'unread'] }); }, [msgs.data?.length, qc]);

  async function send(e: FormEvent) {
    e.preventDefault();
    const t = text.trim();
    if (!t) return;
    setBusy(true);
    try {
      const m = await chat.send(id, t);
      setText('');
      qc.setQueryData<ChatMessage[]>(['chat', id, 'messages'], (old) => [...(old ?? []), m]);
      qc.invalidateQueries({ queryKey: ['chat', 'conversations'] });
    } catch (err) { toast(err instanceof ApiError ? tr(err.message) : tr('Could not send'), true); } finally { setBusy(false); }
  }

  return (
    <div className="mx-auto flex h-[calc(100dvh-5rem)] max-w-3xl flex-col md:h-[calc(100dvh-3rem)]">
      <header className="flex items-center gap-3 border-b border-line bg-surface px-4 py-3 md:rounded-t-3xl">
        <Link to="/messages" aria-label={tr('Back to inbox')} className="rounded-full p-2 hover:bg-surface-2"><Icon name="chevron" size={20} className="rotate-180" /></Link>
        {conv && <><Avatar name={conv.other.name} url={conv.other.image_url} size={36} /><div className="min-w-0"><p className="truncate font-bold">{conv.other_role === 'Doctor' ? tr('Dr. {name}', { name: conv.other.name }) : conv.other.name}</p><p className="text-xs text-muted">{conv.subject || tr(conv.other_role)}</p></div></>}
      </header>
      <div className="flex-1 space-y-1 overflow-y-auto bg-paper px-4 py-4">
        {msgs.isError && <ErrorBox message={(msgs.error as Error).message} onRetry={() => msgs.refetch()} />}
        {msgs.data?.map((m, i) => {
          const prev = msgs.data![i - 1];
          const showDay = !prev || !sameDay(new Date(prev.sent_at), new Date(m.sent_at));
          return (
            <div key={m.id}>
              {showDay && <p className="my-3 text-center text-xs font-semibold text-muted">{fmtDate(m.sent_at, { weekday: 'short', month: 'short', day: 'numeric' })}</p>}
              <div className={`rise flex ${m.mine ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[78%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${m.mine ? 'hero rounded-ee-md text-white' : 'rounded-es-md bg-surface text-ink shadow-card'}`}>
                  <p className="whitespace-pre-wrap">{m.text}</p>
                  <p className={`mt-1 text-end text-[11px] ${m.mine ? 'text-white/70' : 'text-muted'}`}>{fmtTime(m.sent_at)}{m.mine && <span className={m.read_at ? 'text-amber' : ''}> {m.read_at ? '✓✓' : '✓'}</span>}</p>
                </div>
              </div>
            </div>
          );
        })}
        <div ref={bottom} />
      </div>
      <form onSubmit={send} className="flex gap-2 border-t border-line bg-surface p-3 md:rounded-b-3xl">
        <input className="input" placeholder={tr('Write a message')} value={text} onChange={(e) => setText(e.target.value)} aria-label={tr('Message')} />
        <Button type="submit" busy={busy} disabled={!text.trim()}>{tr('Send')}</Button>
      </form>
    </div>
  );
}
