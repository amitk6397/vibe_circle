import { useState } from 'react';

const NAV_ITEMS = [
  { id: 'dashboard',    label: 'Dashboard',          icon: '📊' },
  { id: 'users',        label: 'Users',               icon: '👥' },
  { id: 'communities',  label: 'Communities',         icon: '🏘️' },
  { id: 'reports',      label: 'Reports',             icon: '🚩' },
  { id: 'withdrawals',  label: 'Withdrawals',         icon: '💸' },
  { id: 'packages',     label: 'Coin Packages',       icon: '🪙' },
  { id: 'transactions', label: 'Transactions',        icon: '💳' },
  { id: 'revenue',      label: 'Revenue Dashboard',   icon: '📈' },
  { id: 'livestreams',  label: 'Live Streams',        icon: '📡' },
  { id: 'referral',     label: 'Referral Program',    icon: '🎯' },
  { id: 'articles',     label: 'Support Articles',    icon: '📄' },
  { id: 'gifts',        label: 'Virtual Gifts',       icon: '🎁' },
  { id: 'settings',     label: 'Platform Settings',   icon: '⚙️' },
  { id: 'audit',        label: 'Audit Log',           icon: '🗂️' },
];

export default function Sidebar({ activePage, onNavigate, user, onLogout }) {
  return (
    <aside className="sidebar sidebar--collapsed">
      <div className="sidebar__brand" style={{ justifyContent: 'center', padding: '16px 0' }}>
        <div className="sidebar__logo">
          <div className="sidebar__logo-icon">V</div>
        </div>
      </div>

      <nav className="sidebar__nav">
        {NAV_ITEMS.map(item => (
          <button
            key={item.id}
            className={`sidebar__nav-item${activePage === item.id ? ' active' : ''}`}
            onClick={() => onNavigate(item.id)}
            title={item.label}
            style={{ justifyContent: 'center', padding: '10px 0' }}
          >
            <span className="sidebar__nav-icon" style={{ fontSize: '1.25rem' }}>{item.icon}</span>
          </button>
        ))}
      </nav>

      <div className="sidebar__footer" style={{ padding: '14px 0', alignItems: 'center' }}>
        <button className="sidebar__logout" onClick={onLogout} title="Logout" style={{ justifyContent: 'center', width: '100%', padding: '10px 0' }}>
          <span style={{ fontSize: '1.25rem' }}>🚪</span>
        </button>
      </div>
    </aside>
  );
}
