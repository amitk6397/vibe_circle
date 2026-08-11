import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import Modal from '../components/Modal';
import { useCreators } from '../viewmodels/useCreators';

const TRANSITIONS = {
  pending:      ['under_review', 'rejected'],
  under_review: ['approved', 'rejected'],
  approved:     ['processing', 'rejected'],
  processing:   ['paid', 'failed'],
};

export default function WithdrawalsView() {
  const { withdrawals, loading, error, fetchWithdrawals, reviewWithdrawal } = useCreators();
  const [statusFilter, setStatusFilter] = useState('pending');
  const [actionModal, setActionModal] = useState(null);
  const [reason, setReason] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('');

  useEffect(() => { fetchWithdrawals(); }, [fetchWithdrawals]);

  const filtered = statusFilter ? withdrawals.filter(w => w.status === statusFilter) : withdrawals;

  const handleConfirm = async () => {
    if (!actionModal || !selectedStatus) return;
    const ok = await reviewWithdrawal(actionModal.id, selectedStatus, reason);
    if (ok) { setActionModal(null); setReason(''); setSelectedStatus(''); }
  };

  const columns = [
    { key: 'creatorName', label: 'Creator', render: (row) => (
      <div><div style={{ fontWeight: 600 }}>{row.creatorName}</div><div className="text-muted text-sm">{row.creatorEmail}</div></div>
    )},
    { key: 'amount', label: 'Amount', width: '120px', render: (row) => <span style={{ fontWeight: 700, color: 'var(--green)' }}>₹{(row.amount / 100).toFixed(2)}</span> },
    { key: 'payoutAccountReference', label: 'Payout Ref', render: (row) => <span className="text-sm text-muted">{row.payoutAccountReference}</span> },
    { key: 'status', label: 'Status', width: '120px', render: (row) => <Badge value={row.status} /> },
    { key: 'createdAt', label: 'Requested', width: '100px', render: (row) => new Date(row.createdAt).toLocaleDateString('en-IN') },
    {
      key: 'actions', label: 'Actions', width: '120px',
      render: (row) => TRANSITIONS[row.status]?.length > 0 ? (
        <button className="btn btn--primary btn--sm" onClick={() => { setActionModal(row); setSelectedStatus(TRANSITIONS[row.status][0]); }}>
          📝 Update
        </button>
      ) : null,
    },
  ];

  return (
    <div>
      <div className="page-header"><h2>Withdrawals</h2></div>
      {error && <div className="alert alert--error">⚠️ {error}</div>}

      <div className="tabs">
        {['', 'pending', 'under_review', 'approved', 'processing', 'paid', 'failed', 'rejected'].map(s => (
          <button key={s} className={`tab-btn${statusFilter === s ? ' active' : ''}`} onClick={() => setStatusFilter(s)}>
            {s || 'All'}
          </button>
        ))}
      </div>

      <DataTable columns={columns} rows={filtered} loading={loading} emptyMsg="No withdrawal requests found." />

      {actionModal && (
        <Modal title="Process Withdrawal" onClose={() => { setActionModal(null); setReason(''); }} size="md">
          <div className="info-grid mb-16">
            <div className="info-item"><span className="info-item__label">Creator</span><span className="info-item__value">{actionModal.creatorName}</span></div>
            <div className="info-item"><span className="info-item__label">Amount</span><span className="info-item__value" style={{ color: 'var(--green)', fontWeight: 700 }}>₹{(actionModal.amount / 100).toFixed(2)}</span></div>
            <div className="info-item"><span className="info-item__label">Current Status</span><span className="info-item__value"><Badge value={actionModal.status} /></span></div>
            <div className="info-item"><span className="info-item__label">Payout Ref</span><span className="info-item__value text-sm">{actionModal.payoutAccountReference}</span></div>
          </div>
          <div className="form-group">
            <label className="form-label">New Status</label>
            <select className="form-select" value={selectedStatus} onChange={(e) => setSelectedStatus(e.target.value)}>
              {(TRANSITIONS[actionModal.status] || []).map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          <div className="form-group">
            <label className="form-label">Reason / Notes (optional)</label>
            <input className="form-input" placeholder="Add a note for the creator…" value={reason} onChange={(e) => setReason(e.target.value)} />
          </div>
          <div className="form-actions">
            <button className="btn btn--ghost" onClick={() => { setActionModal(null); setReason(''); }}>Cancel</button>
            <button className="btn btn--primary" onClick={handleConfirm} disabled={!selectedStatus}>Confirm</button>
          </div>
        </Modal>
      )}
    </div>
  );
}
