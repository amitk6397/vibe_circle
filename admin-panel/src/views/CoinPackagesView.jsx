import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCommerce } from '../viewmodels/useCommerce';

const EMPTY_PKG = { name: '', purchased_coins: 0, bonus_coins: 0, price_minor: 0, currency: 'INR', active: true, discount_percentage: 0, badge: '', is_popular: false, description: '' };

export default function CoinPackagesView() {
  const { packages, loading, error, createPackage, updatePackage } = useCommerce();
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(EMPTY_PKG);
  const [saving, setSaving] = useState(false);

  const openCreate = () => { setForm(EMPTY_PKG); setModal({ mode: 'create' }); };
  const openEdit = (pkg) => {
    setForm({
      name: pkg.name || '',
      purchased_coins: pkg.purchased_coins || 0,
      bonus_coins: pkg.bonus_coins || 0,
      price_minor: pkg.price_minor || 0,
      currency: pkg.currency || 'INR',
      active: pkg.active ?? true,
      discount_percentage: pkg.discount_percentage || 0,
      badge: pkg.badge || '',
      is_popular: pkg.is_popular ?? false,
      description: pkg.description || '',
    });
    setModal({ mode: 'edit', id: pkg.id });
  };

  const handleSave = async () => {
    setSaving(true);
    const ok = modal.mode === 'create' ? await createPackage(form) : await updatePackage(modal.id, form);
    if (ok) setModal(null);
    setSaving(false);
  };

  const columns = [
    { key: 'name', label: 'Package', render: (row) => <span style={{ fontWeight: 600 }}>{row.name}</span> },
    { key: 'purchased_coins', label: 'Coins', width: '100px', render: (row) => <span style={{ color: 'var(--yellow)', fontWeight: 700 }}>🪙 {row.purchased_coins}</span> },
    { key: 'bonus_coins', label: 'Bonus', width: '90px', render: (row) => row.bonus_coins ? <span style={{ color: 'var(--green)' }}>+{row.bonus_coins}</span> : <span className="text-muted">—</span> },
    { key: 'discount_percentage', label: 'Discount', width: '90px', render: (row) => row.discount_percentage ? <span style={{ color: 'var(--green)', fontWeight: 600 }}>{row.discount_percentage}% OFF</span> : <span className="text-muted">—</span> },
    { key: 'badge', label: 'Badge', width: '100px', render: (row) => row.badge ? <span className="badge badge--purple">{row.badge}</span> : <span className="text-muted">—</span> },
    { key: 'is_popular', label: 'Popular', width: '80px', render: (row) => row.is_popular ? '⭐ Yes' : 'No' },
    { key: 'price_minor', label: 'Price', width: '90px', render: (row) => <span style={{ fontWeight: 700, color: 'var(--cyan)' }}>₹{(row.price_minor / 100).toFixed(0)}</span> },
    { key: 'active', label: 'Active', width: '80px', render: (row) => <Badge value={String(row.active)} /> },
    {
      key: 'actions', label: 'Actions', width: '100px',
      render: (row) => <button className="btn btn--ghost btn--sm" onClick={() => openEdit(row)}>✏️ Edit</button>,
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Coin Packages</h2>
        <button className="btn btn--primary" onClick={openCreate}>+ New Package</button>
      </div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      <DataTable columns={columns} rows={packages} loading={loading} emptyMsg="No coin packages found." />

      {modal && (
        <Modal title={modal.mode === 'create' ? 'Create Coin Package' : 'Edit Package'} onClose={() => setModal(null)} size="sm">
          <div className="form-group"><label className="form-label">Package Name</label><input className="form-input" value={form.name} onChange={(e) => setForm(p => ({ ...p, name: e.target.value }))} /></div>
          <div className="form-row">
            <div className="form-group"><label className="form-label">Purchased Coins</label><input className="form-input" type="number" value={form.purchased_coins} onChange={(e) => setForm(p => ({ ...p, purchased_coins: +e.target.value }))} /></div>
            <div className="form-group"><label className="form-label">Bonus Coins</label><input className="form-input" type="number" value={form.bonus_coins} onChange={(e) => setForm(p => ({ ...p, bonus_coins: +e.target.value }))} /></div>
          </div>
          <div className="form-row">
            <div className="form-group"><label className="form-label">Price (paise)</label><input className="form-input" type="number" value={form.price_minor} onChange={(e) => setForm(p => ({ ...p, price_minor: +e.target.value }))} /></div>
            <div className="form-group"><label className="form-label">Currency</label><input className="form-input" value={form.currency} onChange={(e) => setForm(p => ({ ...p, currency: e.target.value }))} /></div>
          </div>
          <div className="form-row">
            <div className="form-group"><label className="form-label">Discount Percentage</label><input className="form-input" type="number" value={form.discount_percentage} onChange={(e) => setForm(p => ({ ...p, discount_percentage: +e.target.value }))} /></div>
            <div className="form-group"><label className="form-label">Badge Label (e.g. Best Value)</label><input className="form-input" value={form.badge} onChange={(e) => setForm(p => ({ ...p, badge: e.target.value }))} /></div>
          </div>
          <div className="form-group"><label className="form-label">Description</label><input className="form-input" value={form.description} onChange={(e) => setForm(p => ({ ...p, description: e.target.value }))} /></div>
          <div style={{ display: 'flex', gap: 20, marginBottom: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <input type="checkbox" id="pkg_active" checked={form.active} onChange={(e) => setForm(p => ({ ...p, active: e.target.checked }))} />
              <label htmlFor="pkg_active" className="form-label" style={{ marginBottom: 0 }}>Active</label>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <input type="checkbox" id="pkg_popular" checked={form.is_popular} onChange={(e) => setForm(p => ({ ...p, is_popular: e.target.checked }))} />
              <label htmlFor="pkg_popular" className="form-label" style={{ marginBottom: 0 }}>Is Popular (⭐)</label>
            </div>
          </div>
          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
            <button className="btn btn--primary" onClick={handleSave} disabled={saving || !form.name}>
              {saving ? 'Saving…' : 'Save Package'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
