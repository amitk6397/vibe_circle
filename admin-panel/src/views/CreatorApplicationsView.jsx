import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCreators } from '../viewmodels/useCreators';

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

export default function CreatorApplicationsView() {
  const { applications, loading, error, fetchApplications, reviewApplication } = useCreators();
  const [statusFilter, setStatusFilter] = useState('submitted');
  const [reviewModal, setReviewModal] = useState(null);
  const [note, setNote] = useState('');

  useEffect(() => { fetchApplications(statusFilter || undefined); }, [fetchApplications, statusFilter]);

  const handleReview = async (action) => {
    if (!reviewModal) return;
    const ok = await reviewApplication(reviewModal.id, action, note);
    if (ok) { setReviewModal(null); setNote(''); }
  };

  const columns = [
    {
      key: 'userName', label: 'Applicant', render: (row) => (
        <div className="flex gap-8" style={{ alignItems: 'center' }}>
          {row.avatarUrl ? (
            <img src={getAbsoluteUrl(row.avatarUrl)} alt="" style={{ width: 32, height: 32, borderRadius: '50%', objectFit: 'cover' }} />
          ) : (
            <div className="avatar" style={{ fontSize: '0.75rem' }}>{row.userName?.[0]?.toUpperCase()}</div>
          )}
          <div><div style={{ fontWeight: 600 }}>{row.userName}</div><div className="text-muted text-sm">{row.userEmail}</div></div>
        </div>
      ),
    },
    { key: 'languages', label: 'Languages', render: (row) => row.languages?.join(', ') || '—' },
    { key: 'topics', label: 'Topics', render: (row) => row.topics?.slice(0, 2).join(', ') || '—' },
    { key: 'status', label: 'Status', width: '100px', render: (row) => <Badge value={row.status} /> },
    { key: 'submittedAt', label: 'Submitted', width: '100px', render: (row) => new Date(row.submittedAt).toLocaleDateString('en-IN') },
    {
      key: 'actions', label: 'Actions', width: '120px',
      render: (row) => row.status === 'submitted' ? (
        <button className="btn btn--primary btn--sm" onClick={() => { setReviewModal(row); setNote(''); }}>📋 Review</button>
      ) : null,
    },
  ];

  return (
    <div>
      <div className="page-header"><h2>Creator Applications</h2></div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}

      <div className="tabs">
        {['', 'draft', 'submitted', 'approved', 'rejected'].map(s => (
          <button key={s} className={`tab-btn${statusFilter === s ? ' active' : ''}`} onClick={() => setStatusFilter(s)}>
            {s || 'All'}
          </button>
        ))}
      </div>

      <DataTable columns={columns} rows={applications} loading={loading} emptyMsg="No applications in this category." />

      {reviewModal && (
        <Modal title="Review Creator Application" onClose={() => setReviewModal(null)} size="lg">
          <div className="info-grid mb-16">
            <div className="info-item"><span className="info-item__label">Name</span><span className="info-item__value">{reviewModal.userName}</span></div>
            <div className="info-item"><span className="info-item__label">Email</span><span className="info-item__value">{reviewModal.userEmail}</span></div>
            <div className="info-item"><span className="info-item__label">Languages</span><span className="info-item__value">{reviewModal.languages?.join(', ')}</span></div>
            <div className="info-item"><span className="info-item__label">Topics</span><span className="info-item__value">{reviewModal.topics?.join(', ')}</span></div>
            <div className="info-item"><span className="info-item__label">Chat</span><span className="info-item__value"><Badge value={String(reviewModal.chatAvailable)} /></span></div>
            <div className="info-item"><span className="info-item__label">Audio</span><span className="info-item__value"><Badge value={String(reviewModal.audioAvailable)} /></span></div>
            <div className="info-item"><span className="info-item__label">Video</span><span className="info-item__value"><Badge value={String(reviewModal.videoAvailable)} /></span></div>
          </div>

          {reviewModal.introduction && (
            <div className="form-group">
              <label className="form-label">Introduction</label>
              <div className="card" style={{ padding: 12 }}><p className="text-sm">{reviewModal.introduction}</p></div>
            </div>
          )}
          {reviewModal.experience && (
            <div className="form-group">
              <label className="form-label">Experience</label>
              <div className="card" style={{ padding: 12 }}><p className="text-sm">{reviewModal.experience}</p></div>
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Review Note (optional)</label>
            <input className="form-input" placeholder="Add a note to the applicant…" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>

          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => setReviewModal(null)}>Cancel</button>
            <button className="btn btn--danger" onClick={() => handleReview('reject')}>❌ Reject</button>
            <button className="btn btn--success" onClick={() => handleReview('approve')}>✅ Approve</button>
          </div>
        </Modal>
      )}
    </div>
  );
}
