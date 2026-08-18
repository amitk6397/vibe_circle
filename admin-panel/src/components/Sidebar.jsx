import { useState } from 'react';
import {
  LayoutDashboard,
  Users,
  Compass,
  Flag,
  HandCoins,
  Coins,
  Tag,
  CreditCard,
  TrendingUp,
  Radio,
  Target,
  FileText,
  Gift,
  Settings,
  ShieldCheck,
  LogOut
} from 'lucide-react';

const NAV_ITEMS = [
  { id: 'dashboard',    label: 'Dashboard',          icon: 'dashboard' },
  { id: 'users',        label: 'Users',               icon: 'users' },
  { id: 'communities',  label: 'Communities',         icon: 'communities' },
  { id: 'reports',      label: 'Reports',             icon: 'reports' },
  { id: 'withdrawals',  label: 'Withdrawals',         icon: 'withdrawals' },
  { id: 'packages',     label: 'Coin Packages',       icon: 'packages' },
  { id: 'offers',       label: 'Special Offers',      icon: 'offers' },
  { id: 'transactions', label: 'Transactions',        icon: 'transactions' },
  { id: 'revenue',      label: 'Revenue Dashboard',   icon: 'revenue' },
  { id: 'livestreams',  label: 'Live Streams',        icon: 'livestreams' },
  { id: 'referral',     label: 'Referral Program',    icon: 'referral' },
  { id: 'articles',     label: 'Support Articles',    icon: 'articles' },
  { id: 'gifts',        label: 'Virtual Gifts',       icon: 'gifts' },
  { id: 'settings',     label: 'Platform Settings',   icon: 'settings' },
  { id: 'audit',        label: 'Audit Log',           icon: 'audit' },
];

const ICON_MAP = {
  dashboard:    LayoutDashboard,
  users:        Users,
  communities:  Compass,
  reports:      Flag,
  withdrawals:  HandCoins,
  packages:     Coins,
  offers:       Tag,
  transactions: CreditCard,
  revenue:      TrendingUp,
  livestreams:  Radio,
  referral:     Target,
  articles:     FileText,
  gifts:        Gift,
  settings:     Settings,
  audit:        ShieldCheck,
};

export default function Sidebar({ activePage, onNavigate, user, onLogout }) {
  const [isCollapsed, setIsCollapsed] = useState(false);

  return (
    <aside className={`sidebar${isCollapsed ? ' sidebar--collapsed' : ''}`}>
      <div className="sidebar__brand" style={isCollapsed ? { justifyContent: 'center', padding: '16px 0' } : {}}>
        <div className="sidebar__logo">
          <div className="sidebar__logo-icon">V</div>
          {!isCollapsed && (
            <div className="sidebar__logo-text">
              <strong>VibeCam</strong>
              <em>Admin Portal</em>
            </div>
          )}
        </div>
        <button
          className="sidebar__collapse-btn"
          onClick={() => setIsCollapsed(!isCollapsed)}
          title={isCollapsed ? "Expand Sidebar" : "Collapse Sidebar"}
        >
          ◀
        </button>
      </div>

      <nav className="sidebar__nav">
        {NAV_ITEMS.map(item => {
          const IconComponent = ICON_MAP[item.icon] || LayoutDashboard;
          return (
            <button
              key={item.id}
              className={`sidebar__nav-item${activePage === item.id ? ' active' : ''}`}
              onClick={() => onNavigate(item.id)}
              title={item.label}
              style={isCollapsed ? { justifyContent: 'center', padding: '12px 0' } : {}}
            >
              <IconComponent size={18} className="sidebar__nav-icon" />
              {!isCollapsed && <span className="sidebar__nav-label" style={{ marginLeft: 8 }}>{item.label}</span>}
            </button>
          );
        })}
      </nav>

      <div className="sidebar__footer" style={isCollapsed ? { padding: '14px 0', alignItems: 'center' } : { padding: '14px 16px' }}>
        {!isCollapsed && user && (
          <div className="sidebar__user" style={{ marginBottom: 12 }}>
            <div className="sidebar__user-avatar">
              {user.username?.slice(0, 2).toUpperCase() || 'AD'}
            </div>
            <div className="sidebar__user-info">
              <span className="sidebar__user-name">{user.username || 'Admin'}</span>
              <span className="sidebar__user-role">{user.role || 'Super Admin'}</span>
            </div>
          </div>
        )}
        
        <button
          className="sidebar__logout"
          onClick={onLogout}
          title="Logout"
          style={isCollapsed ? { justifyContent: 'center', width: '100%', padding: '10px 0' } : {}}
        >
          <LogOut size={18} className="sidebar__nav-icon" />
          {!isCollapsed && <span style={{ marginLeft: 8 }}>Logout</span>}
        </button>
      </div>
    </aside>
  );
}
