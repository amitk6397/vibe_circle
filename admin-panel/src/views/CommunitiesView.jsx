import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCommunities } from '../viewmodels/useCommunities';

export default function CommunitiesView() {
  const { communities, loading, error, fetchCommunities, updateCommunity, deleteCommunity } = useCommunities();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [actionModal, setActionModal] = useState(null);

  useEffect(() => { fetchCommunities(); }, [fetchCommunities]);

  const handleSearch = () => fetchCommunities({ search, status: statusFilter });

  const columns = [
    { key: 'name', label: 'Community', width: '200px', render: (row) => (
      <div><div style={{ fontWeight: 600 }}>{row.name}</div><div className="text-muted">{row.category}</div></div>
    )},
    { key: 'privacy', label: 'Privacy/Price', width: '130px', render: (row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <Badge value={row.privacy} label={row.privacy} />
        {row.premiumPrice > 0 && <span style={{ color: 'var(--yellow)', fontWeight: 600, fontSize: '0.82rem' }}>🪙 {row.premiumPrice}</span>}
      </div>
    )},
    { key: 'status', label: 'Status', width: '100px', render: (row) => <Badge value={row.status} /> },
    { key: 'memberCount', label: 'Members', width: '90px', render: (row) => row.memberCount?.toLocaleString() },
    { key: 'ownerName', label: 'Owner' },
    { key: 'createdAt', label: 'Created', width: '100px', render: (row) => new Date(row.createdAt).toLocaleDateString('en-IN') },
    {
      key: 'actions', label: 'Actions', width: '180px',
      render: (row) => (
        <div className="flex gap-8">
          {row.status !== 'suspended' ? (
            <button className="btn btn--warning btn--sm" onClick={() => setActionModal({ item: row, type: 'suspend' })}>🚫 Suspend</button>
          ) : (
            <button className="btn btn--success btn--sm" onClick={() => setActionModal({ item: row, type: 'activate' })}>✅ Activate</button>
          )}
          <button className="btn btn--danger btn--sm" onClick={() => setActionModal({ item: row, type: 'delete' })}>🗑</button>
        </div>
      ),
    },
  ];

  const handleConfirm = async () => {
    if (!actionModal) return;
    const { item, type } = actionModal;
    if (type === 'delete') await deleteCommunity(item.id);
    else await updateCommunity(item.id, { status: type === 'suspend' ? 'suspended' : 'active' });
    setActionModal(null);
  };

  return (
    <div>
      <div className="page-header"><h2>Communities</h2></div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      <div className="toolbar">
        <input className="toolbar__search" placeholder="Search communities…" value={search} onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleSearch()} />
        <select className="form-select" style={{ width: 130 }} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          {['', 'active', 'suspended'].map(o => <option key={o} value={o}>{o || 'All Status'}</option>)}
        </select>
        <button className="btn btn--primary btn--sm" onClick={handleSearch}>🔍 Search</button>
        <button className="btn btn--ghost btn--sm" onClick={() => { setSearch(''); setStatusFilter(''); fetchCommunities({}); }}>✕ Clear</button>
      </div>
      <DataTable columns={columns} rows={communities} loading={loading} emptyMsg="No communities found." />

      {actionModal && (
        <Modal title={`Confirm: ${actionModal.type} community`} onClose={() => setActionModal(null)} size="sm">
          <p style={{ color: 'var(--text-secondary)', marginBottom: 20 }}>
            Are you sure you want to <strong>{actionModal.type}</strong> the community &ldquo;<strong>{actionModal.item.name}</strong>&rdquo;?
          </p>
          <div className="form-actions" style={{ marginTop: 0, paddingTop: 0, border: 'none' }}>
            <button className="btn btn--ghost" onClick={() => setActionModal(null)}>Cancel</button>
            <button className={`btn ${actionModal.type === 'delete' || actionModal.type === 'suspend' ? 'btn--danger' : 'btn--success'}`} onClick={handleConfirm}>
              Confirm
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
