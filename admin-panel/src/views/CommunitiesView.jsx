import { useEffect, useState } from 'react';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import Spinner from '../components/Spinner';
import { useCommunities } from '../viewmodels/useCommunities';

export default function CommunitiesView() {
  const { communities, loading, error, filters, applyFilters, updateCommunity, deleteCommunity, fetchCommunityMembers } = useCommunities();
  const [search, setSearch] = useState(filters.search || '');
  const [status, setStatus] = useState(filters.status || '');
  const [actionModal, setActionModal] = useState(null);
  const [membersModal, setMembersModal] = useState(null);
  const [membersLoading, setMembersLoading] = useState(false);

  // Sync state if filters change (e.g. on clear)
  useEffect(() => {
    setSearch(filters.search || '');
    setStatus(filters.status || '');
  }, [filters]);

  const handleSearch = () => applyFilters({ search, status });

  const handleStatusChange = (newStatus) => {
    setStatus(newStatus);
    applyFilters({ search, status: newStatus });
  };

  const handleConfirm = async () => {
    if (!actionModal) return;
    const { item, type } = actionModal;
    if (type === 'delete') await deleteCommunity(item.id);
    else await updateCommunity(item.id, { status: type === 'suspend' ? 'suspended' : 'active' });
    setActionModal(null);
  };

  const handleViewMembers = async (c) => {
    setMembersLoading(true);
    setMembersModal({ name: c.name, list: [] });
    const list = await fetchCommunityMembers(c.id);
    setMembersModal({ name: c.name, list });
    setMembersLoading(false);
  };

  const renderAvatar = (url, name) => {
    if (url) {
      return <img src={url} style={{ width: 28, height: 28, borderRadius: '50%', objectFit: 'cover', border: '1px solid var(--border)' }} alt="" />;
    }
    const initials = name?.slice(0, 2).toUpperCase() || '?';
    return (
      <div style={{
        width: 28,
        height: 28,
        borderRadius: '50%',
        background: 'linear-gradient(135deg, var(--accent), var(--purple))',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '0.75rem',
        fontWeight: 'bold',
        border: '1px solid var(--border)'
      }}>
        {initials}
      </div>
    );
  };

  return (
    <div>
      <div className="page-header"><h2>Communities</h2></div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}
      
      <div className="toolbar">
        <input className="toolbar__search" placeholder="Search communities…" value={search} onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleSearch()} />
        <select className="form-select" style={{ width: 130 }} value={status} onChange={(e) => handleStatusChange(e.target.value)}>
          {['', 'active', 'suspended', 'deleted'].map(o => <option key={o} value={o}>{o || 'All Status'}</option>)}
        </select>
        <button className="btn btn--primary btn--sm" onClick={handleSearch}>🔍 Search</button>
        <button className="btn btn--ghost btn--sm" onClick={() => applyFilters({ search: '', status: '' })}>✕ Clear</button>
      </div>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '40px 0' }}><Spinner /></div>
      ) : communities.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>No communities found.</div>
      ) : (
        <div className="community-grid">
          {communities.map(c => (
            <div key={c.id} className="community-card">
              <div 
                className="community-card__banner"
                style={{ 
                  backgroundImage: c.coverUrl ? `url(${c.coverUrl})` : 'none'
                }}
              >
                {c.logoUrl ? (
                  <img className="community-card__logo" src={c.logoUrl} alt="" />
                ) : (
                  <div className="community-card__logo" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.5rem', background: 'var(--bg-elevated)', color: 'white' }}>
                    🏘️
                  </div>
                )}
              </div>
              <div className="community-card__body">
                <div className="community-card__meta">
                  <Badge value={c.category} label={c.category} />
                  <Badge value={c.privacy} label={c.privacy} />
                  {c.premiumPrice > 0 && (
                    <span style={{ color: 'var(--yellow)', fontWeight: 600, fontSize: '0.82rem', display: 'flex', alignItems: 'center', gap: 2 }}>
                      🪙 {c.premiumPrice}
                    </span>
                  )}
                </div>
                <h3 className="community-card__title" title={c.name}>{c.name}</h3>
                <p className="community-card__description" title={c.description}>
                  {c.description || 'No description provided.'}
                </p>
                
                <div className="community-card__details">
                  <div className="community-card__detail-item">
                    <span>👥</span>
                    <strong>{c.memberCount?.toLocaleString() || 0} members</strong>
                  </div>
                  <div className="community-card__detail-item">
                    <span>👤</span>
                    <span>Owner: <strong>{c.ownerName || 'Unknown'}</strong></span>
                  </div>
                </div>

                <div className="community-card__actions">
                  <button className="btn btn--ghost btn--sm" onClick={() => handleViewMembers(c)} style={{ flex: 1, border: '1px solid var(--border)' }}>
                    👥 Members
                  </button>
                  {c.status === 'deleted' ? (
                    <button className="btn btn--success btn--sm" onClick={() => setActionModal({ item: c, type: 'activate' })} style={{ flex: 1 }}>
                      ✅ Restore
                    </button>
                  ) : (
                    <>
                      {c.status !== 'suspended' ? (
                        <button className="btn btn--warning btn--sm" onClick={() => setActionModal({ item: c, type: 'suspend' })}>
                          🚫 Suspend
                        </button>
                      ) : (
                        <button className="btn btn--success btn--sm" onClick={() => setActionModal({ item: c, type: 'activate' })}>
                          ✅ Activate
                        </button>
                      )}
                      <button className="btn btn--danger btn--sm" onClick={() => setActionModal({ item: c, type: 'delete' })} style={{ minWidth: 40 }}>
                        🗑
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

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

      {membersModal && (
        <Modal title={`Community Members — ${membersModal.name}`} onClose={() => setMembersModal(null)} size="md">
          {membersLoading ? (
            <div style={{ display: 'flex', justifyContent: 'center', padding: '40px 0' }}><Spinner /></div>
          ) : membersModal.list.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '20px 0', color: 'var(--text-secondary)' }}>No members in this community.</div>
          ) : (
            <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
              <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border)', textAlign: 'left' }}>
                    <th style={{ padding: '10px 12px', fontSize: '0.78rem', color: 'var(--text-secondary)' }}>User</th>
                    <th style={{ padding: '10px 12px', fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Role</th>
                    <th style={{ padding: '10px 12px', fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Joined Date</th>
                  </tr>
                </thead>
                <tbody>
                  {membersModal.list.map(member => (
                    <tr key={member.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '10px 12px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          {renderAvatar(member.avatarUrl, member.username || member.name)}
                          <div>
                            <div style={{ fontWeight: 600, fontSize: '0.85rem', color: 'var(--text-primary)' }}>{member.name}</div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>@{member.username}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '10px 12px' }}>
                        <Badge value={member.role} label={member.role} />
                      </td>
                      <td style={{ padding: '10px 12px', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                        {new Date(member.joinedAt).toLocaleDateString('en-IN')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 20 }}>
            <button className="btn btn--primary" onClick={() => setMembersModal(null)}>Close</button>
          </div>
        </Modal>
      )}
    </div>
  );
}
