import { useEffect, useState, useCallback } from 'react';
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import StatCard from '../components/StatCard';
import Spinner from '../components/Spinner';
import { useDashboard } from '../viewmodels/useDashboard';
import api from '../services/api';

// Custom tooltip for charts
const ChartTooltip = ({ active, payload, label, prefix = '' }) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{
      background: 'rgba(15,15,26,0.95)', border: '1px solid rgba(108,93,211,0.4)',
      borderRadius: 10, padding: '10px 14px', fontSize: '0.8rem',
    }}>
      <p style={{ color: '#9090b0', marginBottom: 4 }}>{label}</p>
      {payload.map((p, i) => (
        <p key={i} style={{ color: p.color, fontWeight: 700 }}>{p.name}: {prefix}{p.value?.toLocaleString()}</p>
      ))}
    </div>
  );
};

// Animated count-up number
function AnimatedNumber({ value, prefix = '', suffix = '' }) {
  const [display, setDisplay] = useState(0);
  useEffect(() => {
    if (!value) return;
    let start = 0;
    const end = Number(value);
    if (start === end) return;
    const duration = 1000;
    const step = Math.max(1, Math.floor(end / (duration / 16)));
    const timer = setInterval(() => {
      start = Math.min(start + step, end);
      setDisplay(start);
      if (start >= end) clearInterval(timer);
    }, 16);
    return () => clearInterval(timer);
  }, [value]);
  return <span>{prefix}{display.toLocaleString()}{suffix}</span>;
}

const PIE_COLORS = ['#6c5dd3', '#00d4ff', '#22c55e', '#eab308', '#ef4444'];

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

export default function DashboardView({ onNavigate }) {
  const { stats, loading, error, refresh } = useDashboard();
  const [chartData, setChartData] = useState([]);
  const [recentUsers, setRecentUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);

  useEffect(() => {
    if (stats?.dailyStats) {
      setChartData(stats.dailyStats);
    }
  }, [stats]);

  const fetchRecentUsers = useCallback(async () => {
    setLoadingUsers(true);
    try {
      const res = await api.get('/admin/users', { params: { limit: 5 } });
      setRecentUsers(res.data || []);
    } catch (_) { /* silent */ }
    setLoadingUsers(false);
  }, []);

  useEffect(() => {
    fetchRecentUsers();
    const interval = setInterval(refresh, 60_000);
    return () => clearInterval(interval);
  }, [refresh, fetchRecentUsers]);

  if (loading && !stats) return <div className="full-center"><Spinner size="lg" text="Loading dashboard…" /></div>;

  const pieData = stats ? [
    { name: 'Active', value: stats.activeUsers || 0 },
    { name: 'Suspended', value: Math.max(0, (stats.totalUsers || 0) - (stats.activeUsers || 0)) },
    { name: 'Online Now', value: stats.onlineUsers || 0 },
  ] : [];

  return (
    <div className="dashboard">
      {error && <div className="alert alert--error">⚠️ {error}</div>}

      {/* ─── Admin Earnings Hero ─────────────────────────── */}
      <div style={{
        background: 'linear-gradient(135deg, #1a1040 0%, #0d1f3c 40%, #071628 100%)',
        border: '1px solid rgba(108,93,211,0.4)',
        borderRadius: 22,
        padding: '28px 32px',
        marginBottom: 28,
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 8px 48px rgba(108,93,211,0.2), 0 0 0 1px rgba(255,255,255,0.03) inset',
      }}>
        <div style={{ position:'absolute', top:-80, right:-80, width:250, height:250, borderRadius:'50%', background:'radial-gradient(circle, rgba(108,93,211,0.2) 0%, transparent 70%)', pointerEvents:'none' }} />
        <div style={{ position:'absolute', bottom:-60, left:-60, width:200, height:200, borderRadius:'50%', background:'radial-gradient(circle, rgba(0,212,255,0.12) 0%, transparent 70%)', pointerEvents:'none' }} />
        <div style={{ position:'relative', zIndex:1 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:8 }}>
            <span style={{ fontSize:13, fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase', color:'rgba(168,130,255,0.8)' }}>🏦 Admin Earnings At a Glance</span>
            <span style={{ fontSize:11, background:'rgba(34,197,94,0.15)', color:'#22c55e', border:'1px solid rgba(34,197,94,0.3)', borderRadius:100, padding:'2px 10px', fontWeight:700 }}>LIVE</span>
          </div>
          <div style={{ display:'flex', gap:32, flexWrap:'wrap', alignItems:'flex-end' }}>
            <div>
              <div style={{ fontSize:'2.8rem', fontWeight:900, lineHeight:1, letterSpacing:'-0.04em', background:'linear-gradient(135deg,#fff 40%,#a78bfa 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>
                ₹<AnimatedNumber value={Math.floor((stats?.totalRevenue || 0) / 100)} />
              </div>
              <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginTop:5, fontWeight:500 }}>Total Revenue (Coin Pack Sales)</div>
            </div>
            <div style={{ width:1, height:60, background:'rgba(255,255,255,0.1)', alignSelf:'center' }} />
            <div>
              <div style={{ fontSize:'2rem', fontWeight:900, lineHeight:1, letterSpacing:'-0.03em', color:'#f59e0b' }}>
                🪙 <AnimatedNumber value={stats?.totalCoinsSold} />
              </div>
              <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginTop:5, fontWeight:500 }}>Total Coins Sold</div>
            </div>
            <div style={{ width:1, height:60, background:'rgba(255,255,255,0.1)', alignSelf:'center' }} />
            <div>
              <div style={{ fontSize:'1.6rem', fontWeight:800, lineHeight:1, color:'#00d4ff' }}>
                <AnimatedNumber value={stats?.pendingWithdrawals} /> <span style={{ fontSize:14, opacity:0.6 }}>pending</span>
              </div>
              <div style={{ fontSize:12, color:'rgba(255,255,255,0.4)', marginTop:5, fontWeight:500 }}>Payouts Awaiting Approval</div>
            </div>
          </div>
          <div style={{ display:'flex', gap:10, marginTop:20, flexWrap:'wrap' }}>
            {[
              { label:'Open Reports', value: stats?.openReports || 0, icon:'🚩', color:'#ef4444', page:'reports' },
              { label:'Active Users', value: stats?.activeUsers || 0, icon:'✅', color:'#22c55e', page:'users' },
              { label:'Communities', value: stats?.totalCommunities || 0, icon:'🏘️', color:'#6c5dd3', page:'communities' },
            ].map(chip => (
              <button key={chip.page} onClick={() => onNavigate(chip.page)} style={{
                display:'flex', alignItems:'center', gap:8,
                background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.1)',
                borderRadius:10, padding:'7px 14px', cursor:'pointer',
                transition:'all 0.2s', color:'inherit',
              }}
              onMouseEnter={e => { e.currentTarget.style.background='rgba(255,255,255,0.1)'; }}
              onMouseLeave={e => { e.currentTarget.style.background='rgba(255,255,255,0.05)'; }}
              >
                <span style={{ fontSize:15 }}>{chip.icon}</span>
                <div>
                  <div style={{ fontSize:11, color:'rgba(255,255,255,0.4)', fontWeight:600, textTransform:'uppercase', letterSpacing:'0.06em' }}>{chip.label}</div>
                  <div style={{ fontSize:14, fontWeight:800, color: chip.color }}>{chip.value}</div>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ─── Stat Cards ────────────────────────────────── */}
      <div className="stats-grid" style={{ marginBottom: 28 }}>
        <StatCard icon="👥" label="Total Users" value={<AnimatedNumber value={stats?.totalUsers} />} color="purple" onClick={() => onNavigate('users')} />
        <StatCard icon="✅" label="Active Users" value={<AnimatedNumber value={stats?.activeUsers} />} color="green" />
        <StatCard icon="🟢" label="Online Now" value={<AnimatedNumber value={stats?.onlineUsers} />} color="cyan" />
        <StatCard icon="🆕" label="New Today" value={<AnimatedNumber value={stats?.newUsersToday} />} color="blue" />
        <StatCard icon="🏘️" label="Communities" value={<AnimatedNumber value={stats?.totalCommunities} />} color="purple" onClick={() => onNavigate('communities')} />
        <StatCard icon="🚩" label="Open Reports" value={<AnimatedNumber value={stats?.openReports} />} color="red" onClick={() => onNavigate('reports')} />
        <StatCard icon="💸" label="Pending Payouts" value={<AnimatedNumber value={stats?.pendingWithdrawals} />} color="orange" onClick={() => onNavigate('withdrawals')} />
        <StatCard icon="🪙" label="Total Coins Sold" value={<AnimatedNumber value={stats?.totalCoinsSold} />} color="blue" />
        <StatCard icon="💰" label="Total Revenue" value={<AnimatedNumber value={Math.floor((stats?.totalRevenue || 0) / 100)} prefix="₹" />} color="green" onClick={() => onNavigate('revenue')} />
      </div>

      {/* ─── Charts Row 1 ──────────────────────────────── */}
      <div className="charts-row" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>

        {/* Area Chart — User Activity */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div className="chart-card__title">📈 User Activity (7 Days)</div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradUsers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#6c5dd3" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#6c5dd3" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: '#9090b0', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#9090b0', fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<ChartTooltip />} />
              <Area type="monotone" dataKey="users" name="Active Users" stroke="#6c5dd3" strokeWidth={2.5} fill="url(#gradUsers)" dot={{ fill: '#6c5dd3', r: 4 }} activeDot={{ r: 6, fill: '#8b7de8' }} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Bar Chart — Revenue */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div className="chart-card__title">💰 Revenue (7 Days)</div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="gradRev" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#22c55e" stopOpacity={0.9} />
                  <stop offset="95%" stopColor="#22c55e" stopOpacity={0.3} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: '#9090b0', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: '#9090b0', fontSize: 11 }} axisLine={false} tickLine={false} />
              <Tooltip content={<ChartTooltip prefix="₹" />} />
              <Bar dataKey="revenue" name="Revenue (₹)" fill="url(#gradRev)" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* ─── Charts Row 2 ──────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 20, marginBottom: 20 }}>
        {/* Pie Chart — User Distribution */}
        <div className="chart-card">
          <div className="chart-card__header">
            <div className="chart-card__title">👥 User Status</div>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" innerRadius={55} outerRadius={80} paddingAngle={4} dataKey="value" startAngle={90} endAngle={-270}>
                {pieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i]} />)}
              </Pie>
              <Tooltip content={<ChartTooltip />} />
              <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: '0.75rem', color: '#9090b0' }} wrapperClassName="pie-legend" />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Recent Audits */}
        <div className="chart-card flex-1">
          <div className="chart-card__header">
            <div className="chart-card__title">📋 Recent Platform Audits</div>
            <button className="btn btn--ghost btn--sm" onClick={() => onNavigate('audit')}>View Log →</button>
          </div>
          <div className="dashboard-audits-list">
            {(stats?.recentAudits || []).map((audit) => (
              <div key={audit.id} className="dashboard-audit-item">
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10, marginBottom: 3 }}>
                  <span className="audit-action">{audit.action.toUpperCase()}</span>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                    {audit.createdAt ? new Date(audit.createdAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : ''}
                  </span>
                </div>
                <p className="audit-desc">{audit.description}</p>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                  <span>Actor: {audit.actorEmail}</span>
                  <span>Target: {audit.targetType}</span>
                </div>
              </div>
            ))}
            {(!stats?.recentAudits || stats.recentAudits.length === 0) && (
              <p className="text-muted" style={{ textAlign: 'center', padding: '20px' }}>No recent audits</p>
            )}
          </div>
        </div>
      </div>

      {/* Bottom Grid: Recent Users */}
      <div className="stats-charts-row" style={{ marginBottom: 20 }}>
        {/* Recent Users */}
        <div className="chart-card" style={{ flex: 1 }}>
          <div className="chart-card__header">
            <div className="chart-card__title">🆕 Recently Joined Users</div>
            <button className="btn btn--ghost btn--sm" onClick={() => onNavigate('users')}>View All →</button>
          </div>
          {loadingUsers ? <Spinner size="sm" /> : (
            <div className="recent-users-list">
              {recentUsers.map(u => (
                <div key={u.id} className="recent-user-item">
                  {u.avatarUrl ? (
                    <img src={getAbsoluteUrl(u.avatarUrl)} alt="" style={{ width: 32, height: 32, borderRadius: '50%', objectFit: 'cover' }} />
                  ) : (
                    <div className="avatar" style={{ fontSize: '0.7rem', width: 32, height: 32 }}>{u.name?.[0]?.toUpperCase()}</div>
                  )}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: '0.875rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.name}</div>
                    <div className="text-muted" style={{ fontSize: '0.75rem' }}>{u.email}</div>
                  </div>
                  <div style={{ textAlign: 'right', flexShrink: 0 }}>
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                      {u.createdAt ? new Date(u.createdAt).toLocaleDateString('en-IN') : ''}
                    </div>
                    <span className={`badge badge--${u.status === 'active' ? 'green' : 'red'}`} style={{ fontSize: '0.65rem', padding: '2px 7px' }}>{u.status}</span>
                  </div>
                </div>
              ))}
              {recentUsers.length === 0 && <p className="text-muted" style={{ textAlign: 'center', padding: '20px' }}>No users found</p>}
            </div>
          )}
        </div>
      </div>

      {/* ─── Quick Actions & Platform Health ──────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div className="chart-card">
          <div className="chart-card__header">
            <div className="chart-card__title">⚡ Quick Actions</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { icon: '🚩', label: `Review ${stats?.openReports || 0} Open Reports`, page: 'reports', cls: stats?.openReports > 0 ? 'btn--danger' : 'btn--ghost' },
              { icon: '💸', label: `Process ${stats?.pendingWithdrawals || 0} Withdrawals`, page: 'withdrawals', cls: stats?.pendingWithdrawals > 0 ? 'btn--warning' : 'btn--ghost' },
              { icon: '👤', label: 'Manage Users', page: 'users', cls: 'btn--ghost' },
              { icon: '💎', label: 'Subscription Plans', page: 'plans', cls: 'btn--ghost' },
              { icon: '📋', label: 'View Audit Log', page: 'audit', cls: 'btn--ghost' },
            ].map(action => (
              <button key={action.page} className={`btn ${action.cls}`} style={{ justifyContent: 'flex-start', fontSize: '0.85rem' }} onClick={() => onNavigate(action.page)}>
                {action.icon} {action.label}
              </button>
            ))}
          </div>
        </div>

        <div className="chart-card">
          <div className="chart-card__header">
            <div className="chart-card__title">📊 Platform Health</div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {[
              { label: 'User Activation Rate', value: stats ? Math.round((stats.activeUsers / Math.max(stats.totalUsers, 1)) * 100) : 0, color: 'var(--green)' },
              { label: 'Online Presence', value: stats ? Math.round((stats.onlineUsers / Math.max(stats.activeUsers, 1)) * 100) : 0, color: 'var(--cyan)' },
              { label: 'Report Resolution', value: stats ? Math.max(0, 100 - Math.round((stats.openReports / Math.max(stats.totalUsers / 10, 1)) * 100)) : 100, color: 'var(--accent)' },
            ].map(item => (
              <div key={item.label}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span className="text-muted" style={{ fontSize: '0.8rem' }}>{item.label}</span>
                  <span style={{ fontWeight: 700, color: item.color, fontSize: '0.8rem' }}>{item.value}%</span>
                </div>
                <div className="progress-track">
                  <div className="progress-fill" style={{ width: `${Math.min(item.value, 100)}%`, background: item.color }} />
                </div>
              </div>
            ))}
            <div className="info-grid" style={{ marginTop: 8 }}>
              <div className="info-item"><span className="info-item__label">Communities</span><span className="info-item__value">{stats?.totalCommunities?.toLocaleString() || '—'}</span></div>
              <div className="info-item"><span className="info-item__label">Coins Sold</span><span className="info-item__value">{stats?.totalCoinsSold?.toLocaleString() || '—'}</span></div>
              <div className="info-item"><span className="info-item__label">Revenue</span><span className="info-item__value">₹{Math.floor((stats?.totalRevenue || 0) / 100).toLocaleString()}</span></div>
              <div className="info-item"><span className="info-item__label">Pending Payouts</span><span className="info-item__value">{stats?.pendingWithdrawals || 0}</span></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
