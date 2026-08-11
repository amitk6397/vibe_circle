import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useReports } from '../viewmodels/useReports';

const REVIEW_OPTIONS = [
  { action: 'dismiss', status: 'dismissed', label: '✕ Dismiss', cls: 'btn--ghost' },
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

  const columns = [
    { key: 'reporter_id', label: 'Reporter', width: '120px', render: (row) => <span className="text-sm">{row.reporter_id?.slice(0,8)}…</span> },
    { key: 'target_type', label: 'Type', width: '90px', render: (row) => <Badge value={row.target_type} label={row.target_type} /> },
    { key: 'reason', label: 'Reason' },
    { key: 'details', label: 'Details', render: (row) => <span className="text-muted text-sm">{row.details?.slice(0, 60) || '—'}</span> },
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
          <div className="info-grid mb-16">
            <div className="info-item"><span className="info-item__label">Target Type</span><span className="info-item__value">{reviewModal.target_type}</span></div>
            <div className="info-item"><span className="info-item__label">Target ID</span><span className="info-item__value">{reviewModal.target_id?.slice(0,12)}…</span></div>
            <div className="info-item"><span className="info-item__label">Reason</span><span className="info-item__value">{reviewModal.reason}</span></div>
            <div className="info-item"><span className="info-item__label">Current Status</span><span className="info-item__value"><Badge value={reviewModal.status} /></span></div>
          </div>
          {reviewModal.details && (
            <div className="card mb-16" style={{ padding: 12, marginBottom: 16 }}>
              <p className="text-muted text-sm">{reviewModal.details}</p>
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
