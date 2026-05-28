'use client';

import { useEffect, useState } from 'react';
import AdminNav from '../components/AdminNav';

type Section = {
  id: number;
  section_key: string;
  display_name: string;
  description: string | null;
  is_active: boolean;
  sort_order: number;
  active_items: number;
};

export default function AdminHomePage() {
  const [sections, setSections] = useState<Section[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch('/api/cms/home/sections');
        const data = await res.json();
        if (!res.ok) throw new Error(data?.message || 'Error');
        setSections(data.data || []);
      } catch (e) {
        setError('No se pudieron cargar las secciones');
      }
    };
    load();
  }, []);

  return (
    <main className="page">
      <section className="card">
        <div className="card-header">
          <div>
            <h1 className="card-title">Contenido Home</h1>
            <p className="card-subtitle">Administra carruseles, destacados, casos de éxito y anuncios.</p>
          </div>
          <AdminNav current="home" />
        </div>
        {error ? <div className="badge">{error}</div> : null}
        <div className="section">
          <table className="table">
            <thead>
              <tr>
                <th>Sección</th>
                <th>Clave</th>
                <th>Items activos</th>
                <th>Orden</th>
                <th>Estado</th>
              </tr>
            </thead>
            <tbody>
              {sections.map((section) => (
                <tr key={section.id}>
                  <td>
                    <a href={`/admin/home/${section.section_key}`}>{section.display_name}</a>
                  </td>
                  <td>{section.section_key}</td>
                  <td>{section.active_items}</td>
                  <td>{section.sort_order}</td>
                  <td>{section.is_active ? 'Activa' : 'Inactiva'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </main>
  );
}
