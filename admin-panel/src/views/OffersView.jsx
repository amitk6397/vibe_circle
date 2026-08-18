import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCommerce } from '../viewmodels/useCommerce';

const EMPTY_OFFER = {
  title: '',
  description: '',
  offer_type: 'discount',
  discount_percentage: 0,
  bonus_coins_percentage: 0,
  package_id: '',
  banner_url: '',
  active: true,
  starts_at: '',
  expires_at: ''
};

const toDatetimeLocal = (isoStr) => {
  if (!isoStr) return '';
  return isoStr.slice(0, 16);
};

export default function OffersView() {
  const { offers, packages, loading, error, createOffer, updateOffer, deleteOffer } = useCommerce();
  const [modal, setModal] = useState(null); // { mode: 'create' | 'edit', id?: string }
  const [form, setForm] = useState(EMPTY_OFFER);
  const [saving, setSaving] = useState(false);

  const openCreate = () => {
    setForm(EMPTY_OFFER);
    setModal({ mode: 'create' });
  };

  const openEdit = (offer) => {
    setForm({
      title: offer.title || '',
      description: offer.description || '',
      offer_type: offer.offerType || offer.offer_type || 'discount',
      discount_percentage: offer.discountPercentage || offer.discount_percentage || 0,
      bonus_coins_percentage: offer.bonusCoinsPercentage || offer.bonus_coins_percentage || 0,
      package_id: offer.packageId || offer.package_id || '',
      banner_url: offer.bannerUrl || offer.banner_url || '',
      active: offer.active ?? true,
      starts_at: toDatetimeLocal(offer.startsAt || offer.starts_at),
      expires_at: toDatetimeLocal(offer.expiresAt || offer.expires_at)
    });
    setModal({ mode: 'edit', id: offer.id });
  };

  const handleSave = async () => {
    setSaving(true);
    // Convert empty string dates to null
    const payload = {
      ...form,
      package_id: form.package_id || null,
      banner_url: form.banner_url || null,
      starts_at: form.starts_at ? new Date(form.starts_at).toISOString() : null,
      expires_at: form.expires_at ? new Date(form.expires_at).toISOString() : null,
    };
    
    const ok = modal.mode === 'create' 
      ? await createOffer(payload) 
      : await updateOffer(modal.id, payload);
      
    if (ok) setModal(null);
    setSaving(false);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this special offer?')) {
      await deleteOffer(id);
    }
  };

  const getPackageName = (pkgId) => {
    if (!pkgId) return 'All Packages';
    const pkg = packages.find(p => p.id === pkgId);
    return pkg ? pkg.name : 'Unknown Package';
  };

  const formatDate = (isoStr) => {
    if (!isoStr) return '—';
    return new Date(isoStr).toLocaleString('en-IN', {
      dateStyle: 'medium',
      timeStyle: 'short'
    });
  };

  const columns = [
    { key: 'title', label: 'Offer Info', render: (row) => (
      <div>
        <div style={{ fontWeight: 600 }}>{row.title}</div>
        <div className="text-muted" style={{ fontSize: '0.8rem' }}>Type: {row.offerType || row.offer_type}</div>
      </div>
    )},
    { key: 'description', label: 'Description', render: (row) => <span style={{ fontSize: '0.9rem' }}>{row.description}</span> },
    { key: 'details', label: 'Promotion Details', render: (row) => {
      const type = row.offerType || row.offer_type;
      if (type === 'discount') return <strong style={{ color: 'var(--green)' }}>{row.discountPercentage || row.discount_percentage}% Discount</strong>;
      if (type === 'bonus') return <strong style={{ color: 'var(--yellow)' }}>+{row.bonusCoinsPercentage || row.bonus_coins_percentage}% Bonus Coins</strong>;
      return <span className="text-muted">Promo Banner</span>;
    }},
    { key: 'package_id', label: 'Target', render: (row) => <span>{getPackageName(row.packageId || row.package_id)}</span> },
    { key: 'validity', label: 'Validity Period', render: (row) => (
      <div style={{ fontSize: '0.8rem' }}>
        <div>From: {formatDate(row.startsAt || row.starts_at)}</div>
        <div>Until: {formatDate(row.expiresAt || row.expires_at)}</div>
      </div>
    )},
    { key: 'active', label: 'Status', width: '80px', render: (row) => <Badge value={String(row.active)} /> },
    {
      key: 'actions', label: 'Actions', width: '120px',
      render: (row) => (
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="btn btn--ghost btn--sm" onClick={() => openEdit(row)}>✏️ Edit</button>
          <button className="btn btn--danger btn--sm" onClick={() => handleDelete(row.id)} style={{ minWidth: 32 }}>🗑</button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Special Offers & Promos</h2>
        <button className="btn btn--primary" onClick={openCreate}>+ New Offer</button>
      </div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      
      <DataTable columns={columns} rows={offers} loading={loading} emptyMsg="No special offers found." />

      {modal && (
        <Modal title={modal.mode === 'create' ? 'Create Special Offer' : 'Edit Offer'} onClose={() => setModal(null)} size="sm">
          <div className="form-group">
            <label className="form-label">Offer Title</label>
            <input className="form-input" value={form.title} onChange={(e) => setForm(p => ({ ...p, title: e.target.value }))} placeholder="e.g. Festival Special Discount" />
          </div>
          
          <div className="form-group">
            <label className="form-label">Description / Subtitle</label>
            <textarea 
              className="form-input" 
              style={{ minHeight: 60, fontFamily: 'inherit' }}
              value={form.description} 
              onChange={(e) => setForm(p => ({ ...p, description: e.target.value }))} 
              placeholder="Describe the offer details to the user..."
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Offer Type</label>
              <select className="form-select" value={form.offer_type} onChange={(e) => setForm(p => ({ ...p, offer_type: e.target.value }))}>
                <option value="discount">Percentage Discount</option>
                <option value="bonus">Bonus Coins</option>
                <option value="banner">Generic Banner</option>
              </select>
            </div>
            
            <div className="form-group">
              <label className="form-label">Applies To Package</label>
              <select className="form-select" value={form.package_id} onChange={(e) => setForm(p => ({ ...p, package_id: e.target.value }))}>
                <option value="">All Packages (Generic)</option>
                {packages.map(p => (
                  <option key={p.id} value={p.id}>{p.name} (🪙 {p.purchased_coins})</option>
                ))}
              </select>
            </div>
          </div>

          {form.offer_type === 'discount' && (
            <div className="form-group">
              <label className="form-label">Discount Percentage</label>
              <input className="form-input" type="number" min="0" max="100" value={form.discount_percentage} onChange={(e) => setForm(p => ({ ...p, discount_percentage: +e.target.value }))} />
            </div>
          )}

          {form.offer_type === 'bonus' && (
            <div className="form-group">
              <label className="form-label">Bonus Coins Percentage</label>
              <input className="form-input" type="number" min="0" value={form.bonus_coins_percentage} onChange={(e) => setForm(p => ({ ...p, bonus_coins_percentage: +e.target.value }))} />
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Banner Image URL (Optional)</label>
            <input className="form-input" value={form.banner_url} onChange={(e) => setForm(p => ({ ...p, banner_url: e.target.value }))} placeholder="https://example.com/banner.png" />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Starts At</label>
              <input className="form-input" type="datetime-local" value={form.starts_at} onChange={(e) => setForm(p => ({ ...p, starts_at: e.target.value }))} />
            </div>
            <div className="form-group">
              <label className="form-label">Expires At</label>
              <input className="form-input" type="datetime-local" value={form.expires_at} onChange={(e) => setForm(p => ({ ...p, expires_at: e.target.value }))} />
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
            <input type="checkbox" id="offer_active" checked={form.active} onChange={(e) => setForm(p => ({ ...p, active: e.target.checked }))} />
            <label htmlFor="offer_active" className="form-label" style={{ marginBottom: 0 }}>Active / Live</label>
          </div>

          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setModal(null)}>Cancel</button>
            <button className="btn btn--primary" onClick={handleSave} disabled={saving || !form.title || !form.description}>
              {saving ? 'Saving…' : 'Save Offer'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
