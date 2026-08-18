import { useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useReports } from '../viewmodels/useReports';

const REVIEW_OPTIONS = [
  { action: 'none', status: 'dismissed', label: '✕ Dismiss', cls: 'btn--ghost' },
  { action: 'restrict', status: 'resolved', label: '⚠️ Restrict User', cls: 'btn--warning' },
  { action: 'suspend', status: 'resolved', label: '🚫 Suspend User', cls: 'btn--warning' },
  { action: 'ban', status: 'resolved', label: '🔴 Ban User', cls: 'btn--danger' },
  { action: 'remove_content', status: 'resolved', label: '🗑 Remove Content', cls: 'btn--danger' },
];

export default function ReportsView() {
  const { reports, loading, error, reviewReport } = useReports();
  const [reviewModal, setReviewModal] = useState(null);
  const [statusFilter, setStatusFilter] = useState('open');

  const filtered = statusFilter ? reports.filter(r => r.status === statusFilter) : reports;

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

  const columns = [
    {
      key: 'reporter', label: 'Reporter', width: '160px',
      render: (row) => row.reporter ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {renderAvatar(row.reporter.avatar_url, row.reporter.username || row.reporter.name)}
          <span style={{ fontWeight: 500, fontSize: '0.85rem' }}>@{row.reporter.username || 'user'}</span>
        </div>
      ) : <span className="text-muted text-sm">{row.reporter_id?.slice(0,8)}…</span>
    },
    { key: 'target_type', label: 'Type', width: '90px', render: (row) => <Badge value={row.target_type} label={row.target_type} /> },
    {
      key: 'target', label: 'Reported Target', width: '220px',
      render: (row) => row.target ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {row.target.type === 'user' ? (
            renderAvatar(row.target.avatar_url, row.target.display_name?.replace('@', ''))
          ) : row.target.logo_url ? (
            <img src={row.target.logo_url} style={{ width: 28, height: 28, borderRadius: '6px', objectFit: 'cover', border: '1px solid var(--border)' }} alt="" />
          ) : (
            <div style={{ width: 28, height: 28, borderRadius: '6px', background: 'var(--accent-dim)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.9rem' }}>
              {row.target_type === 'post' ? '📝' : row.target_type === 'comment' ? '💬' : '📁'}
            </div>
          )}
          <span style={{ fontWeight: 500, fontSize: '0.85rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 160 }} title={row.target.display_name}>
            {row.target.display_name}
          </span>
        </div>
      ) : <span className="text-muted text-sm">{row.target_id?.slice(0,8)}…</span>
    },
    { key: 'reason', label: 'Reason' },
    { key: 'status', label: 'Status', width: '100px', render: (row) => <Badge value={row.status} /> },
    { key: 'created_at', label: 'Reported', width: '100px', render: (row) => new Date(row.created_at).toLocaleDateString('en-IN') },
    {
      key: 'actions', label: 'Actions', width: '100px',
      render: (row) => row.status === 'open' || row.status === 'reviewing' ? (
        <button className="btn btn--primary btn--sm" onClick={() => setReviewModal(row)}>📋 Review</button>
      ) : null,
    },
  ];

  return (
    <div>
      <div className="page-header"><h2>Reports & Moderation</h2></div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}

      <div className="tabs">
        {['', 'open', 'reviewing', 'resolved', 'dismissed'].map(s => (
          <button key={s} className={`tab-btn${statusFilter === s ? ' active' : ''}`} onClick={() => setStatusFilter(s)}>
            {s || 'All'}
          </button>
        ))}
      </div>

      <DataTable columns={columns} rows={filtered} loading={loading} emptyMsg="No reports in this category." />

      {reviewModal && (
        <Modal title={`Review Report — ${reviewModal.target_type}`} onClose={() => setReviewModal(null)} size="md">
          
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
            {/* Reporter Card */}
            <div className="card" style={{ padding: 14, background: 'rgba(255,255,255,0.02)', border: '1px solid var(--border)' }}>
              <h4 style={{ marginBottom: 10, fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Reported By</h4>
              {reviewModal.reporter ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  {renderAvatar(reviewModal.reporter.avatar_url, reviewModal.reporter.username || reviewModal.reporter.name)}
                  <div style={{ minWidth: 0, flex: 1 }}>
                    <div style={{ fontWeight: 600, fontSize: '0.85rem', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                      {reviewModal.reporter.name}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                      @{reviewModal.reporter.username}
                    </div>
                  </div>
                </div>
              ) : (
                <span className="text-muted text-sm">ID: {reviewModal.reporter_id?.slice(0, 16)}…</span>
              )}
            </div>

            {/* Target Card */}
            <div className="card" style={{ padding: 14, background: 'rgba(255,255,255,0.02)', border: '1px solid var(--border)' }}>
              <h4 style={{ marginBottom: 10, fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Reported Target</h4>
              {reviewModal.target ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  {reviewModal.target.type === 'user' ? (
                    renderAvatar(reviewModal.target.avatar_url, reviewModal.target.display_name?.replace('@', ''))
                  ) : reviewModal.target.logo_url ? (
                    <img src={reviewModal.target.logo_url} style={{ width: 28, height: 28, borderRadius: '6px', objectFit: 'cover', border: '1px solid var(--border)' }} alt="" />
                  ) : (
                    <div style={{ width: 28, height: 28, borderRadius: '6px', background: 'var(--accent-dim)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.9rem' }}>
                      {reviewModal.target_type === 'post' ? '📝' : reviewModal.target_type === 'comment' ? '💬' : '📁'}
                    </div>
                  )}
                  <div style={{ minWidth: 0, flex: 1 }}>
                    <div style={{ fontWeight: 600, fontSize: '0.85rem', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                      {reviewModal.target.display_name}
                    </div>
                    <div style={{ fontSize: '0.72rem', color: 'var(--text-secondary)' }}>
                      ID: {reviewModal.target.id?.slice(0, 12)}…
                    </div>
                  </div>
                </div>
              ) : (
                <span className="text-muted text-sm">ID: {reviewModal.target_id?.slice(0, 16)}…</span>
              )}
            </div>
          </div>

          {/* Details Card */}
          <div className="card mb-16" style={{ padding: 14, background: 'rgba(255,255,255,0.01)', border: '1px solid var(--border)', marginBottom: 16 }}>
            <h4 style={{ marginBottom: 8, fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Report Details</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div>
                <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Reason: </span>
                <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)' }}>{reviewModal.reason}</span>
              </div>
              {reviewModal.details && (
                <div>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>Description: </span>
                  <p style={{ fontSize: '0.82rem', color: 'var(--text-primary)', marginTop: 4, background: 'var(--bg-elevated)', padding: 10, borderRadius: 6, border: '1px solid var(--border)' }}>
                    {reviewModal.details}
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Reported Content Details (Post body, Comment body, Media file etc.) */}
          {reviewModal.target && (reviewModal.target.details || reviewModal.target.media_url || reviewModal.target.cover_url) && (
            <div className="card mb-16" style={{ padding: 14, background: 'rgba(108,93,211,0.04)', border: '1px solid var(--border-accent)', marginBottom: 16 }}>
              <h4 style={{ marginBottom: 8, fontSize: '0.85rem', color: 'var(--accent-light)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Reported Content</h4>
              {reviewModal.target.details && (
                <p style={{ fontSize: '0.85rem', color: 'var(--text-primary)', marginBottom: 8, fontStyle: 'italic' }}>
                  &ldquo;{reviewModal.target.details}&rdquo;
                </p>
              )}
              {reviewModal.target.media_url && (
                <div style={{ marginTop: 10, textAlign: 'center' }}>
                  <img
                    src={reviewModal.target.media_url}
                    style={{ maxWidth: '100%', maxHeight: 220, borderRadius: 8, objectFit: 'contain', border: '1px solid var(--border)' }}
                    alt="Post attachment"
                    onError={(e) => { e.target.style.display = 'none'; }}
                  />
                </div>
              )}
              {reviewModal.target.cover_url && (
                <div style={{ marginTop: 10, textAlign: 'center' }}>
                  <img
                    src={reviewModal.target.cover_url}
                    style={{ maxWidth: '100%', maxHeight: 120, borderRadius: 8, objectFit: 'cover', border: '1px solid var(--border)' }}
                    alt="Community Cover"
                    onError={(e) => { e.target.style.display = 'none'; }}
                  />
                </div>
              )}
            </div>
          )}

          {/* Evidence Card */}
          {reviewModal.evidence_ids && reviewModal.evidence_ids.length > 0 && (
            <div className="card mb-16" style={{ padding: 14, background: 'rgba(255,255,255,0.02)', border: '1px solid var(--border)', marginBottom: 16 }}>
              <h4 style={{ marginBottom: 10, fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Evidence Files ({reviewModal.evidence_ids.length})</h4>
              <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 6 }}>
                {reviewModal.evidence_ids.map((url, index) => (
                  <a key={index} href={url} target="_blank" rel="noreferrer" style={{ flexShrink: 0 }}>
                    <img
                      src={url}
                      style={{ width: 90, height: 90, borderRadius: 8, objectFit: 'cover', border: '1px solid var(--border)', cursor: 'zoom-in' }}
                      alt={`Evidence ${index + 1}`}
                      onError={(e) => { e.target.src = 'https://via.placeholder.com/90?text=File'; }}
                    />
                  </a>
                ))}
              </div>
            </div>
          )}

          <p style={{ color: 'var(--text-secondary)', marginBottom: 12, fontSize: '0.85rem' }}>Choose an action:</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {REVIEW_OPTIONS.map(opt => (
              <button
                key={opt.action}
                className={`btn ${opt.cls}`}
                style={{ justifyContent: 'flex-start' }}
                onClick={async () => {
                  const ok = await reviewReport(reviewModal.id, opt.status, opt.action);
                  if (ok) setReviewModal(null);
                }}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </Modal>
      )}
    </div>
  );
}
