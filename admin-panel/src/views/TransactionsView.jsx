import { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import Badge from '../components/Badge';
import { useCommerce } from '../viewmodels/useCommerce';

const TYPE_OPTIONS = ['', 'coin_purchase', 'coin_spend', 'chat_unlock', 'call_charge', 'creator_settlement'];

export default function TransactionsView() {
  const { transactions, loading, error, fetchTransactions } = useCommerce();
  const [searchEmail, setSearchEmail] = useState('');
  const [txType, setTxType] = useState('');

  useEffect(() => {
    fetchTransactions();
  }, [fetchTransactions]);

  const handleSearch = () => {
    const params = {};
    if (searchEmail.trim()) params.user_id = searchEmail.trim(); // Wait, email is searched as user_id in endpoint if they search. Wait, backend's list_transactions takes user_id, which we query on. Since email is more human-readable, we can search by user_id if needed, but let's query with search parameters.
    if (txType) params.transaction_type = txType;
    fetchTransactions(params);
  };

  const formatAmount = (row) => {
    if (row.transactionType === 'coin_purchase') {
      return (
        <span style={{ fontWeight: 700, color: 'var(--green)' }}>
          +₹{(row.amount / 100).toFixed(2)}
        </span>
      );
    }
    return (
      <span style={{ fontWeight: 600, color: 'var(--orange)' }}>
        {row.amount > 0 ? `-${row.amount}` : row.amount} Coins
      </span>
    );
  };

  const columns = [
    {
      key: 'userName', label: 'User', width: '220px',
      render: (row) => (
        <div>
          <div style={{ fontWeight: 600 }}>{row.userName}</div>
          <div className="text-muted text-sm">{row.userEmail || '—'}</div>
        </div>
      ),
    },
    {
      key: 'transactionType', label: 'Type', width: '150px',
      render: (row) => <Badge value={row.transactionType} label={row.transactionType?.replace('_', ' ')} />,
    },
    {
      key: 'amount', label: 'Amount', width: '120px',
      render: (row) => formatAmount(row),
    },
    {
      key: 'paymentMethod', label: 'Method / Details',
      render: (row) => (
        <div>
          <div className="text-sm">{row.paymentMethod || 'Wallet Balance'}</div>
          {row.referenceType && (
            <div className="text-muted" style={{ fontSize: '0.75rem' }}>
              Ref: {row.referenceType} ({row.referenceId?.slice(0, 8)}…)
            </div>
          )}
        </div>
      ),
    },
    {
      key: 'status', label: 'Status', width: '110px',
      render: (row) => <Badge value={row.status} />,
    },
    {
      key: 'createdAt', label: 'Date', width: '160px',
      render: (row) => new Date(row.createdAt).toLocaleString('en-IN'),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2>Transactions</h2>
        <span className="text-muted">{transactions.length} records loaded</span>
      </div>

      {error && <div className="alert alert--error">⚠️ {error}</div>}

      <div className="toolbar">
        <input
          className="toolbar__search"
          placeholder="Filter by user email or ID…"
          value={searchEmail}
          onChange={(e) => setSearchEmail(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
        />
        <select
          className="form-select"
          style={{ width: 180 }}
          value={txType}
          onChange={(e) => setTxType(e.target.value)}
        >
          {TYPE_OPTIONS.map(o => (
            <option key={o} value={o}>
              {o ? o.replace('_', ' ').toUpperCase() : 'All Types'}
            </option>
          ))}
        </select>
        <button className="btn btn--primary btn--sm" onClick={handleSearch}>Filter</button>
        <button
          className="btn btn--ghost btn--sm"
          onClick={() => {
            setSearchEmail('');
            setTxType('');
            fetchTransactions();
          }}
        >
          ✕ Clear
        </button>
      </div>

      <DataTable
        columns={columns}
        rows={transactions}
        loading={loading}
        emptyMsg="No transaction history found."
      />
    </div>
  );
}
