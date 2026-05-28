'use client';

import { useRouter } from 'next/navigation';

type Props = {
  current?: 'home' | 'tickets';
};

export default function AdminNav({ current }: Props) {
  const router = useRouter();

  const onLogout = async () => {
    await fetch('/api/auth/admin/logout', { method: 'POST' });
    router.push('/login');
  };

  return (
    <div className="nav">
      <a href="/admin/home" aria-current={current === 'home' ? 'page' : undefined}>
        Home
      </a>
      <a href="/admin/tickets" aria-current={current === 'tickets' ? 'page' : undefined}>
        Tickets
      </a>
      <button className="button secondary" type="button" onClick={onLogout}>
        Cerrar sesión
      </button>
    </div>
  );
}
