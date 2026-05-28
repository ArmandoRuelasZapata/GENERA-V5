'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await fetch('/api/auth/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.message || 'Credenciales inválidas');
        setLoading(false);
        return;
      }
      router.push('/admin/home');
    } catch (e) {
      setError('No se pudo iniciar sesión');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page">
      <section className="card">
        <div className="card-header">
          <div>
            <h1 className="card-title">CMS Tickets</h1>
            <p className="card-subtitle">Acceso administrativo para contenido y soporte.</p>
          </div>
        </div>
        <form className="form" onSubmit={onSubmit}>
          <label>
            Email
            <input
              className="input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@theoriginallab.com"
              required
            />
          </label>
          <label>
            Contraseña
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </label>
          {error ? <div className="badge">{error}</div> : null}
          <button className="button" type="submit" disabled={loading}>
            {loading ? 'Ingresando...' : 'Ingresar'}
          </button>
        </form>
      </section>
    </main>
  );
}
