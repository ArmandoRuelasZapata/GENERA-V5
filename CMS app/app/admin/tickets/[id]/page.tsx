'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import AdminNav from '../../components/AdminNav';

type Message = {
  id: string;
  sender_type: 'USER' | 'SUPPORT' | string;
  content: string;
  type?: string;
  attachments?: string[] | any[];
  created_at: string;
};

type Ticket = {
  id: string;
  title: string;
  status: string;
  priority?: string;
  user_name?: string;
  user_email?: string;
};

const STATUS_OPTIONS = ['SUBMITTED', 'IN_REVIEW', 'NEEDS_INFO', 'RESOLVED', 'CLOSED'];

const STATUS_LABELS: Record<string, string> = {
  SUBMITTED: 'Enviado',
  IN_REVIEW: 'En revisión',
  NEEDS_INFO: 'Necesita info',
  RESOLVED: 'Resuelto',
  CLOSED: 'Cerrado',
};

function formatDate(iso: string): string {
  try {
    const date = new Date(iso);
    const now = new Date();
    const diff = (now.getTime() - date.getTime()) / 1000;
    if (diff < 60) return 'Ahora';
    if (diff < 3600) return `Hace ${Math.floor(diff / 60)} min`;
    if (diff < 86400) return `Hace ${Math.floor(diff / 3600)} h`;
    return new Intl.DateTimeFormat('es-MX', {
      day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    }).format(date);
  } catch {
    return iso;
  }
}

export default function TicketDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const id = params.id;

  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [content, setContent] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [autoScrollAllowed, setAutoScrollAllowed] = useState(true);

  const bottomRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const load = useCallback(async (isPolling = false) => {
    try {
      const [ticketRes, msgRes] = await Promise.all([
        fetch(`/api/tickets/${id}`),
        fetch(`/api/tickets/${id}/messages`),
      ]);
      if (!ticketRes.ok || !msgRes.ok) throw new Error('Error');
      const [ticketData, msgData] = await Promise.all([
        ticketRes.json(),
        msgRes.json(),
      ]);
      setTicket(ticketData);

      // Extract new messages
      const newMessages = Array.isArray(msgData) ? msgData : (msgData.messages ?? []);
      
      setMessages((prev) => {
        // If the number of messages increased, allow auto-scroll
        if (newMessages.length > prev.length) {
          setAutoScrollAllowed(true);
        }
        return newMessages;
      });
      setError('');
    } catch {
      if (!isPolling) setError('No se pudo cargar el ticket.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    if (id) {
      load();
      // Auto-refresh interval (poll every 5 seconds)
      const intervalId = setInterval(() => {
        load(true);
      }, 5000);
      return () => clearInterval(intervalId);
    }
  }, [id, load]);

  // Scroll to bottom on load and new messages
  useEffect(() => {
    if (autoScrollAllowed) {
      bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
      setAutoScrollAllowed(false); // Reset after scrolling
    }
  }, [messages, autoScrollAllowed]);

  const sendMessage = async () => {
    if (!content.trim() || sending) return;
    setSending(true);
    try {
      const res = await fetch(`/api/tickets/${id}/messages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: content.trim(), sender_type: 'SUPPORT', type: 'TEXT' }),
      });
      if (res.ok) {
        setContent('');
        await load();
      }
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      sendMessage();
    }
  };

  const updateStatus = async (status: string) => {
    const res = await fetch(`/api/tickets/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    if (res.ok) load();
  };

  return (
    <main className="page chat-page">
      <section className="card chat-card">
        {/* Header */}
        <div className="card-header chat-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
            <button
              onClick={() => router.push('/admin/tickets')}
              style={{
                background: 'rgba(255,255,255,0.08)',
                border: 'none',
                borderRadius: 10,
                padding: '6px 12px',
                color: 'var(--text)',
                cursor: 'pointer',
                fontSize: 14,
              }}
            >
              ← Volver
            </button>
            <div>
              <h1 className="card-title" style={{ fontSize: 'clamp(16px,2vw,22px)' }}>
                {ticket ? ticket.title : `Ticket #${id}`}
              </h1>
              {ticket?.user_email && (
                <p className="card-subtitle">{ticket.user_name ?? ticket.user_email}</p>
              )}
            </div>
            {ticket && (
              <span className={`badge status-${ticket.status}`}>
                {STATUS_LABELS[ticket.status] ?? ticket.status}
              </span>
            )}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--muted)' }}>
              Estado:
              <select
                className="status-select"
                value={ticket?.status ?? 'SUBMITTED'}
                onChange={(e) => updateStatus(e.target.value)}
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>{STATUS_LABELS[s] ?? s}</option>
                ))}
              </select>
            </label>
            <AdminNav current="tickets" />
          </div>
        </div>

        {/* Error */}
        {error && (
          <div style={{ padding: '10px 28px', color: 'var(--status-needs)', fontSize: 13 }}>
            ⚠️ {error}
          </div>
        )}

        {/* Messages */}
        <div className="chat-window">
          {loading ? (
            <>
              {[1, 2, 3].map((i) => (
                <div key={i} className="skeleton" style={{ height: 52, width: `${45 + i * 12}%`, alignSelf: i % 2 === 0 ? 'flex-end' : 'flex-start' }} />
              ))}
            </>
          ) : messages.length === 0 ? (
            <p style={{ color: 'var(--muted)', textAlign: 'center', marginTop: 40 }}>
              Sin mensajes aún.
            </p>
          ) : (
            messages.map((msg) => {
              const isSupport = msg.sender_type === 'SUPPORT';
              return (
                <div key={msg.id} className={`chat-bubble-wrap ${isSupport ? 'support' : 'user'}`}>
                  <div className={`chat-bubble ${isSupport ? 'support' : 'user'}`}>
                    {msg.type === 'IMAGE' || (msg.attachments && msg.attachments.length > 0) ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                        {msg.content && <p style={{ margin: 0 }}>{msg.content}</p>}
                        {/* the image could be in content if type=IMAGE, or in attachments */}
                        {msg.type === 'IMAGE' && msg.content?.startsWith('http') && (
                          <img src={msg.content} alt="Adjunto" style={{ maxWidth: '100%', borderRadius: 8 }} />
                        )}
                        {msg.attachments?.map((att, idx) => {
                          const url = typeof att === 'string' ? att : att?.url;
                          return url && typeof url === 'string' && url.startsWith('http') ? (
                            <img key={idx} src={url} alt="Adjunto" style={{ maxWidth: '100%', borderRadius: 8, marginTop: 4 }} />
                          ) : null;
                        })}
                      </div>
                    ) : (
                      <>{msg.content}</>
                    )}
                  </div>
                  <span className="chat-meta">
                    {isSupport ? 'Soporte' : 'Usuario'} · {formatDate(msg.created_at)}
                  </span>
                </div>
              );
            })
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input bar */}
        <div className="chat-input-bar">
          <textarea
            ref={textareaRef}
            placeholder="Escribe una respuesta… (Ctrl+Enter para enviar)"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            rows={1}
          />
          <button
            className="send-btn"
            onClick={sendMessage}
            disabled={!content.trim() || sending}
            title="Enviar (Ctrl+Enter)"
          >
            {sending ? '⏳' : '➤'}
          </button>
        </div>
      </section>
    </main>
  );
}
