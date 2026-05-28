'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import AdminNav from '../components/AdminNav';

type Ticket = {
  id: string;
  title: string;
  status: string;
  priority: string;
  updated_at?: string;
};

type Stats = {
  open: number;
  in_progress: number;
  closed_today: number;
  no_response: number;
};

const STATUS_LABELS: Record<string, string> = {
  SUBMITTED: 'Enviado',
  IN_REVIEW: 'En revisión',
  NEEDS_INFO: 'Necesita info',
  RESOLVED: 'Resuelto',
  CLOSED: 'Cerrado',
};

function formatDate(iso?: string): string {
  if (!iso) return '—';
  try {
    return new Intl.DateTimeFormat('es-MX', {
      day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

export default function TicketsPage() {
  const router = useRouter();
  const [stats, setStats] = useState<Stats | null>(null);
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [statsRes, ticketsRes] = await Promise.all([
          fetch('/api/support/tickets/stats'),
          fetch('/api/support/tickets'),
        ]);
        if (!statsRes.ok || !ticketsRes.ok) throw new Error('Error');
        const [statsData, ticketsData] = await Promise.all([
          statsRes.json(),
          ticketsRes.json(),
        ]);
        setStats(statsData);
        setTickets(ticketsData.tickets ?? []);
      } catch {
        setError('No se pudieron cargar los tickets.');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return (
    <main className="page">
      <section className="card">
        <div className="card-header">
          <div>
            <h1 className="card-title">Panel de Tickets</h1>
            <p className="card-subtitle">Seguimiento y respuesta de soporte.</p>
          </div>
          <AdminNav current="tickets" />
        </div>

        {error && (
          <div style={{ color: 'var(--status-needs)', fontSize: 13, marginBottom: 16 }}>⚠️ {error}</div>
        )}

        {/* Stats */}
        {stats && (
          <div className="grid two section">
            {[
              { label: 'Abiertos', value: stats.open, color: 'var(--status-submitted)' },
              { label: 'En progreso', value: stats.in_progress, color: 'var(--status-review)' },
              { label: 'Cerrados hoy', value: stats.closed_today, color: 'var(--status-resolved)' },
              { label: 'Sin respuesta', value: stats.no_response, color: 'var(--status-needs)' },
            ].map(({ label, value, color }) => (
              <div key={label} className="card" style={{ padding: '16px 20px' }}>
                <p className="card-subtitle" style={{ margin: 0 }}>{label}</p>
                <p style={{ fontSize: 32, fontWeight: 700, margin: '4px 0 0', color }}>{value}</p>
              </div>
            ))}
          </div>
        )}

        {/* Table */}
        {loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 8 }}>
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="skeleton" style={{ height: 44 }} />
            ))}
          </div>
        ) : (
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Título</th>
                <th>Status</th>
                <th>Prioridad</th>
                <th>Actualizado</th>
              </tr>
            </thead>
            <tbody>
              {tickets.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', color: 'var(--muted)', padding: '32px 0' }}>
                    Sin tickets registrados.
                  </td>
                </tr>
              ) : (
                tickets.map((ticket) => (
                  <tr key={ticket.id} onClick={() => router.push(`/admin/tickets/${ticket.id}`)}>
                    <td style={{ color: 'var(--muted)', fontSize: 12 }}>#{ticket.id.slice(0, 8)}</td>
                    <td style={{ fontWeight: 500 }}>{ticket.title}</td>
                    <td>
                      <span className={`badge status-${ticket.status}`}>
                        {STATUS_LABELS[ticket.status] ?? ticket.status}
                      </span>
                    </td>
                    <td>
                      <span className={`badge priority-${ticket.priority}`}>
                        {ticket.priority}
                      </span>
                    </td>
                    <td style={{ color: 'var(--muted)', fontSize: 13 }}>{formatDate(ticket.updated_at)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </section>
    </main>
  );
}
