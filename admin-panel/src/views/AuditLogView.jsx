import { useEffect } from 'react';
import DataTable from '../components/DataTable';
import { useReports } from '../viewmodels/useReports';

export default function AuditLogView() {
  const { auditLogs, fetchAuditLogs, loading } = useReports();

  useEffect(() => { fetchAuditLogs(); }, [fetchAuditLogs]);

  const columns = [
    { key: 'actor_id', label: 'Admin', width: '120px', render: (row) => <span className="text-sm">{row.actor_id?.slice(0,8)}…</span> },
    { key: 'action', label: 'Action', render: (row) => <span style={{ fontWeight: 600, color: 'var(--accent-light)' }}>{row.action}</span> },
    { key: 'target_type', label: 'Target Type', width: '110px' },
    { key: 'target_id', label: 'Target ID', width: '120px', render: (row) => <span className="text-muted text-sm">{row.target_id?.slice(0,12)}…</span> },
    {
      key: 'metadata_json', label: 'Details', render: (row) =>
        row.metadata_json && Object.keys(row.metadata_json).length > 0
          ? <span className="text-muted text-sm">{JSON.stringify(row.metadata_json).slice(0, 60)}</span>
          : <span className="text-muted">—</span>,
    },
    { key: 'created_at', label: 'Time', width: '150px', render: (row) => new Date(row.created_at).toLocaleString('en-IN') },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Audit Log</h2>
        <button className="btn btn--ghost btn--sm" onClick={fetchAuditLogs}>🔄 Refresh</button>
      </div>
      <div className="alert alert--info">Showing last 200 admin actions in reverse chronological order.</div>
      <DataTable columns={columns} rows={auditLogs} loading={loading} emptyMsg="No audit logs found." />
    </div>
  );
}
