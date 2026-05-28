'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams } from 'next/navigation';
import AdminNav from '../../components/AdminNav';

type Item = {
  id: number;
  section_id: number;
  title: string | null;
  subtitle: string | null;
  description: string | null;
  image_url: string | null;
  mobile_image_url: string | null;
  thumbnail_url: string | null;
  cta_label: string | null;
  cta_url: string | null;
  badge: string | null;
  display_type: string | null;
  extra: Record<string, unknown> | null;
  is_active: boolean;
  sort_order: number;
  visible_from: string | null;
  visible_until: string | null;
};

export default function SectionItemsPage() {
  const params = useParams<{ sectionKey: string }>();
  const sectionKey = params.sectionKey;
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [sectionId, setSectionId] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [showInactive, setShowInactive] = useState(false);
  const [form, setForm] = useState<Item>({
    id: 0,
    section_id: 0,
    title: '',
    subtitle: '',
    description: '',
    image_url: '',
    mobile_image_url: '',
    thumbnail_url: '',
    cta_label: '',
    cta_url: '',
    badge: '',
    display_type: 'item',
    extra: {},
    is_active: true,
    sort_order: 0,
    visible_from: null,
    visible_until: null,
  });

  const fetchItems = useCallback(async () => {
    setError('');
    try {
      const res = await fetch(`/api/cms/home/items?section_key=${sectionKey}`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Error');
      const list = data.data || [];
      setItems(list);
      if (list.length > 0) setSectionId(list[0].section_id);
    } catch {
      setError('No se pudieron cargar los items');
    } finally {
      setLoading(false);
    }
  }, [sectionKey]);

  useEffect(() => {
    if (sectionKey) fetchItems();
  }, [sectionKey, fetchItems]);

  useEffect(() => {
    const loadSections = async () => {
      try {
        const res = await fetch('/api/cms/home/sections');
        const data = await res.json();
        if (!res.ok) throw new Error('Error');
        const match = (data.data || []).find(
          (s: { section_key: string; id: number }) => s.section_key === sectionKey
        );
        if (match) setSectionId(match.id);
      } catch {
        // ignore — sectionId will be set from items list
      }
    };
    if (!sectionId && sectionKey) loadSections();
  }, [sectionId, sectionKey]);

  const resetForm = () => {
    setEditingId(null);
    setForm((prev) => ({
      ...prev,
      id: 0,
      section_id: sectionId || 0,
      title: '',
      subtitle: '',
      description: '',
      image_url: '',
      mobile_image_url: '',
      thumbnail_url: '',
      cta_label: '',
      cta_url: '',
      badge: '',
      display_type: 'item',
      extra: {},
      is_active: true,
      sort_order: 0,
      visible_from: null,
      visible_until: null,
    }));
  };

  const startEdit = (item: Item) => {
    setEditingId(item.id);
    setForm({
      ...item,
      extra: item.extra || {},
    });
  };

  const buildPayload = (payload: Item) => ({
    section_id: payload.section_id,
    title: payload.title,
    subtitle: payload.subtitle,
    description: payload.description,
    image_url: payload.image_url,
    mobile_image_url: payload.mobile_image_url,
    thumbnail_url: payload.thumbnail_url,
    cta_label: payload.cta_label,
    cta_url: payload.cta_url,
    badge: payload.badge,
    display_type: payload.display_type || 'item',
    extra: payload.extra || {},
    is_active: payload.is_active,
    sort_order: payload.sort_order || 0,
    visible_from: payload.visible_from || null,
    visible_until: payload.visible_until || null,
  });

  const saveItem = async () => {
    if (!sectionId) {
      setError('No se pudo resolver la sección.');
      return;
    }
    setSaving(true);
    try {
      const payload = { ...form, section_id: sectionId };
      const res = await fetch(
        editingId ? `/api/cms/home/items/${editingId}` : '/api/cms/home/items',
        {
          method: editingId ? 'PUT' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(buildPayload(payload)),
        }
      );
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Error');
      await fetchItems();
      resetForm();
    } catch (e) {
      setError('No se pudo guardar el item');
    } finally {
      setSaving(false);
    }
  };

  // Removed separate `refresh` — use `fetchItems` directly everywhere.

  const toggleActive = async (item: Item) => {
    const res = await fetch(`/api/cms/home/items/${item.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(buildPayload({ ...item, is_active: !item.is_active })),
    });
    if (res.ok) fetchItems();
  };

  const removeItem = async (itemId: number) => {
    const res = await fetch(`/api/cms/home/items/${itemId}`, { method: 'DELETE' });
    if (res.ok) fetchItems();
  };

  const saveOrder = async () => {
    const payload = items.map((item) => ({ id: item.id, sort_order: item.sort_order || 0 }));
    const res = await fetch('/api/cms/home/items/reorder', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (res.ok) fetchItems();
  };

  const uploadImage = async (file?: File | null) => {
    if (!file) return;
    const formData = new FormData();
    formData.append('file', file);
    const res = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });
    const data = await res.json();
    if (res.ok && data?.url) {
      setForm((prev) => ({ ...prev, image_url: data.url }));
    }
  };

  const orderedItems = useMemo(
    () => [...items]
      .filter((item) => showInactive || item.is_active)
      .sort((a, b) => {
        if (a.is_active !== b.is_active) return a.is_active ? -1 : 1;
        return (a.sort_order || 0) - (b.sort_order || 0);
      }),
    [items, showInactive]
  );

  return (
    <main className="page">
      <section className="card">
        <div className="card-header">
          <div>
            <h1 className="card-title">Sección: {sectionKey}</h1>
            <p className="card-subtitle">Lista de items activos e históricos.</p>
          </div>
          <AdminNav current="home" />
        </div>
        {error ? <div className="badge">{error}</div> : null}
        <div className="section">
          <h3>{editingId ? 'Editar item' : 'Crear item'}</h3>
          <div className="form">
            <input
              className="input"
              placeholder="Título"
              value={form.title ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
            />
            <input
              className="input"
              placeholder="CTA URL"
              value={form.cta_url ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, cta_url: e.target.value }))}
            />
            <input
              className="input"
              placeholder="Etiqueta CTA"
              value={form.cta_label ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, cta_label: e.target.value }))}
            />
            <div className="grid two">
              <select
                className="input"
                value={form.display_type ?? 'item'}
                onChange={(e) => setForm((prev) => ({ ...prev, display_type: e.target.value }))}
              >
                <option value="item">item</option>
                <option value="banner">banner</option>
              </select>
              <input
                className="input"
                type="number"
                placeholder="Orden"
                value={form.sort_order ?? 0}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, sort_order: Number(e.target.value) }))
                }
              />
            </div>
            <div className="grid two">
              <input
                className="input"
                type="datetime-local"
                value={form.visible_from ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, visible_from: e.target.value }))}
              />
              <input
                className="input"
                type="datetime-local"
                value={form.visible_until ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, visible_until: e.target.value }))}
              />
            </div>
            <div className="grid two">
              <label className="input" style={{ cursor: 'pointer' }}>
                Subir imagen
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => uploadImage(e.target.files?.[0])}
                  style={{ display: 'none' }}
                />
              </label>
              <input
                className="input"
                placeholder="Image URL"
                value={form.image_url ?? ''}
                onChange={(e) => setForm((prev) => ({ ...prev, image_url: e.target.value }))}
              />
            </div>
            <label>
              <input
                type="checkbox"
                checked={form.is_active}
                onChange={(e) => setForm((prev) => ({ ...prev, is_active: e.target.checked }))}
              />{' '}
              Activo
            </label>
            <div style={{ display: 'flex', gap: 12 }}>
              <button className="button" type="button" onClick={saveItem} disabled={saving}>
                {saving ? 'Guardando...' : editingId ? 'Actualizar' : 'Crear'}
              </button>
              <button className="button secondary" type="button" onClick={resetForm}>
                Limpiar
              </button>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
          <label style={{ cursor: 'pointer', display: 'flex', gap: 8, alignItems: 'center' }}>
            <input 
              type="checkbox" 
              checked={showInactive} 
              onChange={(e) => setShowInactive(e.target.checked)} 
            />
            Mostrar inactivos ({items.filter(i => !i.is_active).length})
          </label>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Orden</th>
              <th>Imagen</th>
              <th>Título</th>
              <th>CTA</th>
              <th>Visible</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {orderedItems.map((item) => (
              <tr key={item.id}>
                <td>
                  <input
                    className="input"
                    type="number"
                    value={item.sort_order ?? 0}
                    onChange={(e) => {
                      const next = Number(e.target.value);
                      setItems((prev) =>
                        prev.map((p) => (p.id === item.id ? { ...p, sort_order: next } : p))
                      );
                    }}
                    style={{ width: 80 }}
                  />
                </td>
                <td>
                  {item.image_url ? (
                    <img
                      src={item.image_url}
                      alt=""
                      width={60}
                      height={40}
                      style={{
                        borderRadius: 8,
                        objectFit: 'cover',
                        display: 'block',
                        background: '#222',
                      }}
                      onError={(e) => {
                        const t = e.currentTarget;
                        t.style.display = 'none';
                        const next = t.nextSibling as HTMLElement | null;
                        if (next) next.style.display = 'flex';
                      }}
                    />
                  ) : null}
                  <div
                    style={{
                      display: item.image_url ? 'none' : 'flex',
                      width: 60,
                      height: 40,
                      borderRadius: 8,
                      background: '#2a2a2a',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 20,
                      color: '#666',
                    }}
                  >
                    Sin imagen
                  </div>
                </td>
                <td>{item.title || 'Sin título'}</td>
                <td>{item.cta_url || '—'}</td>
                <td>
                  {item.visible_from || 'Siempre'}
                  {item.visible_until ? ` → ${item.visible_until}` : ''}
                </td>
                <td>{item.is_active ? 'Activo' : 'Inactivo'}</td>
                <td style={{ display: 'flex', gap: 8 }}>
                  <button className="button secondary" type="button" onClick={() => startEdit(item)}>
                    Editar
                  </button>
                  <button className="button secondary" type="button" onClick={() => toggleActive(item)}>
                    {item.is_active ? 'Desactivar' : 'Activar'}
                  </button>
                  <button className="button secondary" type="button" onClick={() => removeItem(item.id)}>
                    Eliminar
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div style={{ marginTop: 16 }}>
          <button className="button" type="button" onClick={saveOrder}>
            Guardar orden
          </button>
        </div>
      </section>
    </main>
  );
}
