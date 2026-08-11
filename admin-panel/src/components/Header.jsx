const PAGE_TITLES = {
  dashboard:    { title: 'Dashboard', icon: '📊' },
  users:        { title: 'User Management', icon: '👥' },
  communities:  { title: 'Communities', icon: '🏘️' },
  reports:      { title: 'Reports & Moderation', icon: '🚩' },
  withdrawals:  { title: 'Withdrawals', icon: '💸' },
  plans:        { title: 'Subscription Plans', icon: '💎' },
  packages:     { title: 'Coin Packages', icon: '🪙' },
  transactions: { title: 'Transactions', icon: '💳' },
  articles:     { title: 'Support Articles', icon: '📄' },
  settings:     { title: 'Platform Settings', icon: '⚙️' },
  audit:        { title: 'Audit Log', icon: '📋' },
};

export default function Header({ page, onRefresh }) {
  const now = new Date();
  const formatted = now.toLocaleDateString('en-IN', {
    weekday: 'short', year: 'numeric', month: 'short', day: 'numeric',
  });
  const info = PAGE_TITLES[page] || { title: 'Admin Panel', icon: '🔐' };

  return (
    <header className="header">
      <div className="header__left">
        <h1 className="header__title">
          <span style={{ marginRight: 8 }}>{info.icon}</span>
          {info.title}
        </h1>
        <span className="header__date">{formatted}</span>
      </div>
      <div className="header__right">
        {onRefresh && (
          <button className="btn btn--ghost btn--sm" onClick={onRefresh}>
            🔄 Refresh
          </button>
        )}
        <div className="header__indicator">
          <span className="header__indicator-dot" />
          <span>Live</span>
        </div>
      </div>
    </header>
  );
}
