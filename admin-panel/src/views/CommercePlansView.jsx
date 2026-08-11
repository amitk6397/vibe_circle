import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCommerce } from '../viewmodels/useCommerce';

const EMPTY_PLAN = { name: '', description: '', price_minor: 0, currency: 'INR', interval: 'month', features: [], highlighted: false, active: true, chat_allowance: null, audio_credits: 0, video_credits: 0 };

export default function CommercePlansView() {
  const { plans, loading, error, createPlan, updatePlan, deletePlan } = useCommerce();
  const [modal, setModal] = useState(null); // null | { mode: 'create'|'edit', data }
  const [form, setForm] = useState(EMPTY_PLAN);
  const [featuresText, setFeaturesText] = useState('');
  const [saving, setSaving] = useState(false);

  const openCreate = () => { setForm(EMPTY_PLAN); setFeaturesText(''); setModal({ mode: 'create' }); };
  const openEdit = (plan) => { setForm({ ...plan }); setFeaturesText((plan.features || []).join('\n')); setModal({ mode: 'edit', id: plan.id }); };

  const handleSave = async () => {
    setSaving(true);
    const payload = { ...form, features: featuresText.split('\n').map(s => s.trim()).filter(Boolean) };
    const ok = modal.mode === 'create' ? await createPlan(payload) : await updatePlan(modal.id, payload);
    if (ok) setModal(null);
    setSaving(false);
  };

  const columns = [
    { key: 'name', label: 'Plan', render: (row) => (
      <div>
        <div style={{ fontWeight: 700 }}>{row.name}</div>
        <div className="text-muted text-sm">{row.description?.slice(0, 50)}</div>
      </div>
    )},
    { key: 'price_minor', label: 'Price', width: '100px', render: (row) => <span style={{ fontWeight: 700, color: 'var(--cyan)' }}>₹{(row.price_minor / 100).toFixed(0)}/{row.interval}</span> },
    { key: 'highlighted', label: 'Featured', width: '80px', render: (row) => <Badge value={String(row.highlighted)} /> },
    { key: 'active', label: 'Active', width: '80px', render: (row) => <Badge value={String(row.active)} /> },
    { key: 'features', label: 'Features', render: (row) => <span className="text-muted text-sm">{row.features?.length || 0} features</span> },
    {
      key: 'actions', label: 'Actions', width: '150px',
      render: (row) => (
        <div className="flex gap-8">
          <button className="btn btn--ghost btn--sm" onClick={() => openEdit(row)}>✏️ Edit</button>
          <button className="btn btn--danger btn--sm" onClick={() => deletePlan(row.id)}>🗑</button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Subscription Plans</h2>
        <button className="btn btn--primary" onClick={openCreate}>+ New Plan</button>
      </div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      <DataTable columns={columns} rows={plans} loading={loading} emptyMsg="No plans found." />

      {modal && (
        <Modal title={modal.mode === 'create' ? 'Create Subscription Plan' : 'Edit Plan'} onClose={() => setModal(null)} size="md">
          <div className="form-row">
            <div className="form-group"><label className="form-label">Name</label><input className="form-input" value={form.name} onChange={(e) => setForm(p => ({ ...p, name: e.target.value }))} /></div>
            <div className="form-group"><label className="form-label">Price (paise)</label><input className="form-input" type="number" value={form.price_minor} onChange={(e) => setForm(p => ({ ...p, price_minor: +e.target.value }))} /></div>
          </div>
          <div className="form-row">
            <div className="form-group"><label className="form-label">Interval</label>
              <select className="form-select" value={form.interval} onChange={(e) => setForm(p => ({ ...p, interval: e.target.value }))}>
                {['month', 'year', 'week'].map(o => <option key={o}>{o}</option>)}
              </select>
            </div>
            <div className="form-group"><label className="form-label">Currency</label><input className="form-input" value={form.currency} onChange={(e) => setForm(p => ({ ...p, currency: e.target.value }))} /></div>
          </div>
          <div className="form-group"><label className="form-label">Description</label><input className="form-input" value={form.description} onChange={(e) => setForm(p => ({ ...p, description: e.target.value }))} /></div>
          <div className="form-group">
            <label className="form-label">Features (one per line)</label>
            <textarea className="form-textarea" style={{ minHeight: 80 }} value={featuresText} onChange={(e) => setFeaturesText(e.target.value)} placeholder="Unlimited calls&#10;Priority matching&#10;…" />
          </div>
          <div className="form-row">
            <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: 10, paddingTop: 20 }}>
              <input type="checkbox" id="highlighted" checked={form.highlighted} onChange={(e) => setForm(p => ({ ...p, highlighted: e.target.checked }))} />
              <label htmlFor="highlighted" className="form-label" style={{ marginBottom: 0 }}>Highlighted (featured)</label>
            </div>
            <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: 10, paddingTop: 20 }}>
              <input type="checkbox" id="active_plan" checked={form.active} onChange={(e) => setForm(p => ({ ...p, active: e.target.checked }))} />
              <label htmlFor="active_plan" className="form-label" style={{ marginBottom: 0 }}>Active</label>
            </div>
          </div>
          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
            <button className="btn btn--primary" onClick={handleSave} disabled={saving || !form.name}>
              {saving ? 'Saving…' : 'Save Plan'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
