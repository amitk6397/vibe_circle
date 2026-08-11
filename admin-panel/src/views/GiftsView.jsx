import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useContent } from '../viewmodels/useContent';
import api from '../services/api';

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

const EMPTY = { name: '', icon: '🎁', coin_price: 20, creator_earning_value: 16, animation_url: '', active: true };

export default function GiftsView() {
  const { gifts, loading, error, createGift, updateGift, deleteGift } = useContent();
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [iconFile, setIconFile] = useState(null);
  const [saving, setSaving] = useState(false);
  const [deleteModal, setDeleteModal] = useState(null);

  const openCreate = () => { setIconFile(null); setForm(EMPTY); setModal({ mode: 'create' }); };
  const openEdit = (g) => { setIconFile(null); setForm({ ...g, animation_url: g.animation_url || '' }); setModal({ mode: 'edit', id: g.id }); };

  const handleSave = async () => {
    setSaving(true);
    try {
      let finalForm = { ...form };
      if (iconFile) {
        const formData = new FormData();
        formData.append('file', iconFile);
        const uploadRes = await api.post('/uploads', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
        finalForm.icon = uploadRes.data.url;
      }
      const ok = modal.mode === 'create' ? await createGift(finalForm) : await updateGift(modal.id, finalForm);
      if (ok) setModal(null);
    } catch (e) {
      console.error('Failed to save gift:', e);
      alert('Save failed: ' + (e.message || 'unknown error'));
    } finally {
      setSaving(false);
    }
  };

  const columns = [
    {
      key: 'icon', label: 'Icon', width: '70px',
      render: (row) => {
        const isImg = row.icon && (row.icon.startsWith('/') || row.icon.startsWith('http'));
        return isImg ? (
          <img src={getAbsoluteUrl(row.icon)} alt="" style={{ width: 28, height: 28, objectFit: 'contain' }} />
        ) : (
          <span style={{ fontSize: '1.6rem' }}>{row.icon}</span>
        );
      }
    },
    { key: 'name', label: 'Gift Name', render: (row) => <span style={{ fontWeight: 600 }}>{row.name}</span> },
    { key: 'coin_price', label: 'Price', width: '110px', render: (row) => <span style={{ color: 'var(--yellow)', fontWeight: 700 }}>🪙 {row.coin_price}</span> },
    { key: 'creator_earning_value', label: 'Creator Earning', width: '150px', render: (row) => <span style={{ color: 'var(--green)' }}>🪙 {row.creator_earning_value}</span> },
    { key: 'active', label: 'Status', width: '90px', render: (row) => <Badge value={String(row.active)} /> },
    {
      key: 'actions', label: 'Actions', width: '150px',
      render: (row) => (
        <div className="flex gap-8">
          <button className="btn btn--ghost btn--sm" onClick={() => openEdit(row)}>✏️ Edit</button>
          <button className="btn btn--danger btn--sm" onClick={() => setDeleteModal(row)}>🗑</button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Virtual Gifts</h2>
        <button className="btn btn--primary" onClick={openCreate}>+ New Gift</button>
      </div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      <DataTable columns={columns} rows={gifts} loading={loading} emptyMsg="No gifts found." />

      {modal && (
        <Modal title={modal.mode === 'create' ? 'Create Virtual Gift' : 'Edit Virtual Gift'} onClose={() => setModal(null)} size="md">
          <div className="form-row">
            <div className="form-group"><label className="form-label">Name</label><input className="form-input" value={form.name} onChange={(e) => setForm(p => ({ ...p, name: e.target.value }))} placeholder="Appreciation" /></div>
            <div className="form-group">
              <label className="form-label">Icon (Emoji or Image File)</label>
              <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                <input className="form-input" style={{ width: 60, textAlign: 'center' }} value={form.icon} onChange={(e) => setForm(p => ({ ...p, icon: e.target.value }))} placeholder="❤️" />
                <input type="file" accept="image/*" style={{ fontSize: '0.8rem' }} onChange={(e) => {
                  const file = e.target.files[0];
                  if (file) setIconFile(file);
                }} />
              </div>
            </div>
          </div>
          <div className="form-row">
            <div className="form-group"><label className="form-label">Price (coins)</label><input className="form-input" type="number" value={form.coin_price} onChange={(e) => setForm(p => ({ ...p, coin_price: +e.target.value }))} /></div>
            <div className="form-group"><label className="form-label">Creator Earning Share (coins)</label><input className="form-input" type="number" value={form.creator_earning_value} onChange={(e) => setForm(p => ({ ...p, creator_earning_value: +e.target.value }))} /></div>
          </div>
          <div className="form-group"><label className="form-label">Animation URL (Optional)</label><input className="form-input" value={form.animation_url} onChange={(e) => setForm(p => ({ ...p, animation_url: e.target.value }))} placeholder="https://example.com/heart.json" /></div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8, marginTop: 8 }}>
            <input type="checkbox" id="gift_active" checked={form.active} onChange={(e) => setForm(p => ({ ...p, active: e.target.checked }))} />
            <label htmlFor="gift_active" className="form-label" style={{ marginBottom: 0 }}>Active (available for tipping)</label>
          </div>
          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
            <button className="btn btn--primary" onClick={handleSave} disabled={saving || !form.name || !form.icon}>
              {saving ? 'Saving…' : 'Save Gift'}
            </button>
          </div>
        </Modal>
      )}

      {deleteModal && (
        <Modal title="Deactivate Gift" onClose={() => setDeleteModal(null)} size="sm">
          <p style={{ color: 'var(--text-secondary)', marginBottom: 20 }}>
            Are you sure you want to deactivate the gift &ldquo;<strong>{deleteModal.name}</strong>&rdquo;? It will no longer be visible for users to tip.
          </p>
          <div className="form-actions" style={{ marginTop: 0, paddingTop: 0, border: 'none' }}>
            <button className="btn btn--ghost" onClick={() => setDeleteModal(null)}>Cancel</button>
            <button className="btn btn--danger" onClick={async () => { await deleteGift(deleteModal.id); setDeleteModal(null); }}>Deactivate</button>
          </div>
        </Modal>
      )}
    </div>
  );
}
