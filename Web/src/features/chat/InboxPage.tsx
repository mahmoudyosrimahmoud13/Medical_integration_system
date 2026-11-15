import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { chat } from '../../core/api/endpoints';
import { ApiError } from '../../core/api/client';
import { Avatar, Button, Card, Empty, ErrorBox, Modal, PageHeader, Section, SkeletonList, useToast } from '../../core/ui';
import { fmtDate, fmtTime, sameDay } from '../../core/time';

export function InboxPage() {
  const q = useQuery({ queryKey: ['chat', 'conversations'], queryFn: chat.conversations, refetchInterval: 10_000 });
  const [compose, setCompose] = useState(false);
  const navigate = useNavigate();
  return (
    <>
      <PageHeader eyebrow="Messages" title="Inbox" right={<Button variant="amber" onClick={() => setCompose(true)}>New message</Button>} />
      <div className="mx-auto mt-6 max-w-3xl px-4 md:px-0">
        {q.isLoading ? <SkeletonList /> : q.isError ? <ErrorBox message={(q.error as Error).message} onRetry={() => q.refetch()} /> : q.data!.length === 0 ? (
          <Empty title="No messages yet" text="Write to your doctor, a pharmacy or a hospital." action={<Button onClick={() => setCompose(true)}>New message</Button>} />
        ) : (
          <div className="space-y-2">
            {q.data!.map((c, i) => {
              const when = new Date(c.last_message_at);
              return (
                <Card key={c.id} index={i} onClick={() => navigate(`/messages/${c.id}`)} className={`flex items-center gap-3 p-4 ${c.unread ? 'border-indigo/30 bg-indigo-100/40' : ''}`}>
                  <Avatar name={c.other.name} url={c.other.image_url} size={48} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-baseline justify-between gap-2"><p className="truncate font-bold">{c.other_role === 'Doctor' ? 'Dr. ' : ''}{c.other.name}</p><span className="shrink-0 text-xs text-muted">{sameDay(when, new Date()) ? fmtTime(when) : fmtDate(when, { month: 'short', day: 'numeric' })}</span></div>
                    <p className="text-xs font-semibold text-indigo">{c.other_role}{c.subject ? ` · ${c.subject}` : ''}</p>
                    {c.last_message && <p className={`truncate text-sm ${c.unread ? 'font-semibold' : 'text-muted'}`}>{c.last_message.mine ? 'You: ' : ''}{c.last_message.text}</p>}
                  </div>
                  {c.unread > 0 && <span className="pop badge bg-indigo text-white">{c.unread}</span>}
                </Card>
              );
            })}
          </div>
        )}
      </div>
      <ComposeModal open={compose} onClose={() => setCompose(false)} />
    </>
  );
}

function ComposeModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const q = useQuery({ queryKey: ['chat', 'contacts'], queryFn: chat.contacts, enabled: open });
  const navigate = useNavigate();
  const toast = useToast();
  const groups = new Map<string, NonNullable<typeof q.data>>();
  for (const c of q.data ?? []) groups.set(c.role, [...(groups.get(c.role) ?? []), c]);
  async function start(userId: string) {
    try { const c = await chat.start(userId); onClose(); navigate(`/messages/${c.id}`); } catch (e) { toast(e instanceof ApiError ? e.message : 'Could not start', true); }
  }
  return (
    <Modal open={open} onClose={onClose} title="New message">
      {q.isLoading && <SkeletonList count={3} />}
      {q.data?.length === 0 && <p className="text-sm text-muted">No one to write to yet. Book a doctor or open a pharmacy page to start a conversation.</p>}
      {[...groups.entries()].map(([role, list]) => (
        <Section key={role} title={`${role}s`}>
          <div className="space-y-2">
            {list.map((c, i) => (
              <Card key={c.user_id} index={i} onClick={() => start(c.user_id)} className="flex items-center gap-3 p-3">
                <Avatar name={c.name} url={c.image_url} size={40} />
                <span className="min-w-0 flex-1"><span className="block font-semibold">{role === 'Doctor' ? 'Dr. ' : ''}{c.name}</span><span className="block text-xs text-muted">{c.context}</span></span>
                <span aria-hidden>›</span>
              </Card>
            ))}
          </div>
        </Section>
      ))}
    </Modal>
  );
}
