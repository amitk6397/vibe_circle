import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useUsers } from '../viewmodels/useUsers';

const STATUS_OPTIONS = ['', 'active', 'restricted', 'suspended', 'banned', 'deleted'];
const ROLE_OPTIONS = ['', 'user', 'moderator', 'admin'];

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

export default function UsersView({ onViewUser }) {
  const { users, loading, error, filters, applyFilters, fetchUsers, updateUser, deleteUser } = useUsers();
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [role, setRole] = useState('');
  const [actionModal, setActionModal] = useState(null); // { user, type }
  const [confirmText, setConfirmText] = useState('');

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const handleSearch = () => applyFilters({ search, status, role });

  const handleKeyDown = (e) => { if (e.key === 'Enter') handleSearch(); };

  const handleAction = async () => {
    if (!actionModal) return;
    const { user: u, type } = actionModal;
    if (type === 'delete') {
      await deleteUser(u.id);
    } else {
      await updateUser(u.id, { status: type });
    }
    setActionModal(null);
    setConfirmText('');
  };

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('en-IN') : '—';

  const columns = [
    {
      key: 'name', label: 'User', width: '200px',
      render: (row) => (
        <div className="flex gap-8" style={{ alignItems: 'center' }}>
          {row.avatarUrl ? (
            <img src={getAbsoluteUrl(row.avatarUrl)} alt="" style={{ width: 32, height: 32, borderRadius: '50%', objectFit: 'cover' }} />
          ) : (
            <div className="avatar" style={{ fontSize: '0.75rem' }}>{row.name?.[0]?.toUpperCase()}</div>
          )}
          <div>
            <div style={{ fontWeight: 600 }}>{row.name}</div>
            <div className="text-muted">@{row.username || '—'}</div>
          </div>
        </div>
      ),
    },
    { key: 'email', label: 'Email', render: (row) => <span className="text-sm">{row.email}</span> },
    { key: 'role', label: 'Role', width: '100px', render: (row) => <Badge value={row.role} /> },
    { key: 'status', label: 'Status', width: '110px', render: (row) => <Badge value={row.status} /> },
    { key: 'isVerified', label: 'Verified', width: '80px', render: (row) => <Badge value={String(row.isVerified)} /> },
    { key: 'city', label: 'City', render: (row) => row.city || '—' },
    { key: 'createdAt', label: 'Joined', width: '100px', render: (row) => formatDate(row.createdAt) },
    {
      key: 'actions', label: 'Actions', width: '200px',
      render: (row) => (
        <div className="flex gap-8">
          <button className="btn btn--ghost btn--sm" onClick={() => onViewUser && onViewUser(row.id)}>
            👁 View
          </button>
          {row.status === 'active' ? (
            <button className="btn btn--warning btn--sm" onClick={() => setActionModal({ user: row, type: 'suspended' })}>
              🚫 Suspend
            </button>
          ) : row.status !== 'deleted' ? (
            <button className="btn btn--success btn--sm" onClick={() => setActionModal({ user: row, type: 'active' })}>
              ✅ Activate
            </button>
          ) : null}
        </div>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>User Management</h2>
        <span className="text-muted">{users.length} users loaded</span>
      </div>

      {error && <div className="alert alert--error">⚠️ {error}</div>}

      <div className="toolbar">
        <input
          className="toolbar__search"
          placeholder="Search name, email, username…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={handleKeyDown}
        />
        <select className="form-select" style={{ width: 130 }} value={status} onChange={(e) => setStatus(e.target.value)}>
          {STATUS_OPTIONS.map(o => <option key={o} value={o}>{o || 'All Status'}</option>)}
        </select>
        <select className="form-select" style={{ width: 120 }} value={role} onChange={(e) => setRole(e.target.value)}>
          {ROLE_OPTIONS.map(o => <option key={o} value={o}>{o || 'All Roles'}</option>)}
        </select>
        <button className="btn btn--primary btn--sm" onClick={handleSearch}>🔍 Search</button>
        <button className="btn btn--ghost btn--sm" onClick={() => { setSearch(''); setStatus(''); setRole(''); applyFilters({}); }}>
          ✕ Clear
        </button>
      </div>

      <DataTable columns={columns} rows={users} loading={loading} emptyMsg="No users found. Try adjusting filters." />

      {actionModal && (
        <Modal
          title={`Confirm: ${actionModal.type} user`}
          onClose={() => { setActionModal(null); setConfirmText(''); }}
          size="sm"
        >
          <p style={{ color: 'var(--text-secondary)', marginBottom: 16 }}>
            Are you sure you want to set <strong>{actionModal.user.name}</strong>&apos;s status to{' '}
            <Badge value={actionModal.type} />?
          </p>
          <p className="text-muted mb-8">Type <strong>CONFIRM</strong> to proceed:</p>
          <input
            className="form-input mb-16"
            placeholder="CONFIRM"
            value={confirmText}
            onChange={(e) => setConfirmText(e.target.value)}
          />
          <div className="form-actions" style={{ marginTop: 0, paddingTop: 0, border: 'none' }}>
            <button className="btn btn--ghost" onClick={() => { setActionModal(null); setConfirmText(''); }}>Cancel</button>
            <button
              className={`btn ${actionModal.type === 'active' ? 'btn--success' : 'btn--danger'}`}
              disabled={confirmText !== 'CONFIRM'}
              onClick={handleAction}
            >
              Confirm
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
