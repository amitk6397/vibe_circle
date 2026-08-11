import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useContent } from '../viewmodels/useContent';

const EMPTY = { slug: '', title: '', icon: 'document-text-outline', body: '', position: 0, active: true };

export default function SupportArticlesView() {
  const { articles, loading, error, createArticle, updateArticle, deleteArticle } = useContent();
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);
  const [deleteModal, setDeleteModal] = useState(null);

  const openCreate = () => { setForm(EMPTY); setModal({ mode: 'create' }); };
  const openEdit = (a) => { setForm({ ...a }); setModal({ mode: 'edit', id: a.id }); };

  const handleSave = async () => {
    setSaving(true);
    const ok = modal.mode === 'create' ? await createArticle(form) : await updateArticle(modal.id, form);
    if (ok) setModal(null);
    setSaving(false);
  };

  const columns = [
    { key: 'position', label: '#', width: '50px' },
    { key: 'icon', label: 'Icon', width: '60px', render: (row) => <span style={{ fontSize: '1.2rem' }}>📄</span> },
    { key: 'title', label: 'Title', render: (row) => <span style={{ fontWeight: 600 }}>{row.title}</span> },
    { key: 'slug', label: 'Slug', render: (row) => <span className="text-muted text-sm">{row.slug}</span> },
    { key: 'active', label: 'Active', width: '80px', render: (row) => <Badge value={String(row.active)} /> },
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
        <h2>Support Articles</h2>
        <button className="btn btn--primary" onClick={openCreate}>+ New Article</button>
      </div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      <DataTable columns={columns} rows={articles} loading={loading} emptyMsg="No articles found." />

      {modal && (
        <Modal title={modal.mode === 'create' ? 'Create Support Article' : 'Edit Article'} onClose={() => setModal(null)} size="lg">
          <div className="form-row">
            <div className="form-group"><label className="form-label">Slug</label><input className="form-input" value={form.slug} onChange={(e) => setForm(p => ({ ...p, slug: e.target.value }))} placeholder="privacy-policy" /></div>
            <div className="form-group"><label className="form-label">Position</label><input className="form-input" type="number" value={form.position} onChange={(e) => setForm(p => ({ ...p, position: +e.target.value }))} /></div>
          </div>
          <div className="form-group"><label className="form-label">Title</label><input className="form-input" value={form.title} onChange={(e) => setForm(p => ({ ...p, title: e.target.value }))} /></div>
          <div className="form-group"><label className="form-label">Body / Content (Markdown supported)</label><textarea className="form-textarea" style={{ minHeight: 180 }} value={form.body} onChange={(e) => setForm(p => ({ ...p, body: e.target.value }))} /></div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <input type="checkbox" id="art_active" checked={form.active} onChange={(e) => setForm(p => ({ ...p, active: e.target.checked }))} />
            <label htmlFor="art_active" className="form-label" style={{ marginBottom: 0 }}>Active (visible in app)</label>
          </div>
          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
            <button className="btn btn--primary" onClick={handleSave} disabled={saving || !form.title || !form.slug}>
              {saving ? 'Saving…' : 'Save Article'}
            </button>
          </div>
        </Modal>
      )}

      {deleteModal && (
        <Modal title="Delete Article" onClose={() => setDeleteModal(null)} size="sm">
          <p style={{ color: 'var(--text-secondary)', marginBottom: 20 }}>
            Are you sure you want to delete &ldquo;<strong>{deleteModal.title}</strong>&rdquo;? This cannot be undone.
          </p>
          <div className="form-actions" style={{ marginTop: 0, paddingTop: 0, border: 'none' }}>
            <button className="btn btn--ghost" onClick={() => setDeleteModal(null)}>Cancel</button>
            <button className="btn btn--danger" onClick={async () => { await deleteArticle(deleteModal.id); setDeleteModal(null); }}>Delete</button>
          </div>
        </Modal>
      )}
    </div>
  );
}
