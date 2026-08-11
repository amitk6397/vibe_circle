import { useEffect, useState } from 'react';
import { commerceService } from '../services/commerceService';
import StatCard from '../components/StatCard';

const PERIODS = [
  { label: '7 Days', value: '7d' },
  { label: '30 Days', value: '30d' },
  { label: '90 Days', value: '90d' },
  { label: 'All Time', value: 'all' },
];

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

function AnimatedCounter({ value, prefix = '', suffix = '', decimals = 0 }) {
  const [display, setDisplay] = useState(0);
  useEffect(() => {
    const end = Number(value) || 0;
    if (end === 0) { setDisplay(0); return; }
    let start = 0;
    const duration = 1200;
    const step = end / (duration / 16);
    const timer = setInterval(() => {
      start = Math.min(start + step, end);
      setDisplay(start);
      if (start >= end) clearInterval(timer);
    }, 16);
    return () => clearInterval(timer);
  }, [value]);
  return <span>{prefix}{decimals > 0 ? display.toFixed(decimals) : Math.floor(display).toLocaleString()}{suffix}</span>;
}

export default function RevenueView() {
  const [period, setPeriod] = useState('30d');
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [hoveredBar, setHoveredBar] = useState(null);

  useEffect(() => {
    setLoading(true);
    setError('');
    commerceService.revenueSummary(period)
      .then(res => setData(res.data))
      .catch(err => setError(err.response?.data?.detail || 'Failed to load revenue data'))
      .finally(() => setLoading(false));
  }, [period]);

  const maxChart = data
    ? Math.max(1, ...data.chart.map(d => Math.max(d.coinRevenue || 0, d.commission || 0)))
    : 1;

  const adminTotalEarnings = data
    ? (data.coinPurchaseRevenue || 0) + (data.commissionEarned || 0)
    : 0;

  const coinRevenueRupees = data ? (data.coinPurchaseRevenue || 0) : 0;
  const commissionCoins = data ? (data.commissionEarned || 0) : 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '28px' }}>
      {/* ── Header ── */}
      <div className="rev-header">
        <div>
          <h1 className="view-title" style={{ fontSize: '1.75rem', letterSpacing: '-0.03em', marginBottom: 4 }}>
            💰 Revenue Dashboard
          </h1>
          <p className="view-subtitle">Platform earnings — real-time coin packs &amp; session commissions</p>
        </div>
        <div className="tabs" style={{ marginBottom: 0 }}>
          {PERIODS.map(p => (
            <button
              key={p.value}
              onClick={() => setPeriod(p.value)}
              className={`tab-btn${period === p.value ? ' active' : ''}`}
            >{p.label}</button>
          ))}
        </div>
      </div>

      {loading && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', padding: '70px', justifyContent: 'center', color: 'var(--text-secondary)' }}>
          <div className="spinner spinner--md" />
          <span>Loading revenue data…</span>
        </div>
      )}

      {error && <div className="alert alert--error">⚠️ {error}</div>}

      {data && !loading && (
        <>
          {/* ══ ADMIN EARNINGS HERO CARD ══ */}
          <div style={{
            background: 'linear-gradient(135deg, #1a1040 0%, #0d1f3c 40%, #071628 100%)',
            border: '1px solid rgba(108,93,211,0.45)',
            borderRadius: 24,
            padding: '32px 36px',
            position: 'relative',
            overflow: 'hidden',
            boxShadow: '0 8px 48px rgba(108,93,211,0.25), 0 0 0 1px rgba(255,255,255,0.04) inset',
          }}>
            {/* Decorative glow blobs */}
            <div style={{ position:'absolute', top:-60, right:-60, width:220, height:220, borderRadius:'50%', background:'radial-gradient(circle, rgba(108,93,211,0.25) 0%, transparent 70%)', pointerEvents:'none' }} />
            <div style={{ position:'absolute', bottom:-40, left:-40, width:160, height:160, borderRadius:'50%', background:'radial-gradient(circle, rgba(0,212,255,0.15) 0%, transparent 70%)', pointerEvents:'none' }} />

            <div style={{ position:'relative', zIndex:1 }}>
              <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:6 }}>
                <span style={{ fontSize:13, fontWeight:700, letterSpacing:'0.1em', textTransform:'uppercase', color:'rgba(168,130,255,0.8)' }}>
                  🏦 Admin / Platform Total Earnings
                </span>
                <span style={{ fontSize:11, background:'rgba(34,197,94,0.15)', color:'#22c55e', border:'1px solid rgba(34,197,94,0.3)', borderRadius:100, padding:'2px 10px', fontWeight:700 }}>
                  LIVE
                </span>
              </div>

              <div style={{ display:'flex', alignItems:'flex-end', gap:14, flexWrap:'wrap' }}>
                <div>
                  <div style={{ fontSize:'3.2rem', fontWeight:900, lineHeight:1, letterSpacing:'-0.04em', background:'linear-gradient(135deg, #fff 40%, #a78bfa 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>
                    ₹<AnimatedCounter value={coinRevenueRupees} decimals={2} />
                  </div>
                  <div style={{ fontSize:13, color:'rgba(255,255,255,0.45)', marginTop:4, fontWeight:500 }}>
                    From coin pack sales (100% platform)
                  </div>
                </div>
                <div style={{ width:1, height:64, background:'rgba(255,255,255,0.1)', alignSelf:'center' }} />
                <div>
                  <div style={{ fontSize:'2.4rem', fontWeight:900, lineHeight:1, letterSpacing:'-0.03em', background:'linear-gradient(135deg, #f59e0b 0%, #fcd34d 100%)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>
                    🪙 <AnimatedCounter value={commissionCoins} />
                  </div>
                  <div style={{ fontSize:13, color:'rgba(255,255,255,0.45)', marginTop:4, fontWeight:500 }}>
                    Commission coins ({data.commissionPercent}% of sessions)
                  </div>
                </div>
              </div>

              {/* Breakdown chips */}
              <div style={{ display:'flex', gap:12, marginTop:22, flexWrap:'wrap' }}>
                {[
                  { label:'Coin Packs Sold', value: data.coinPackagesSold, icon:'📦', color:'#6c5dd3' },
                  { label:'Paid Sessions', value: data.paidSessionCount, icon:'⚡', color:'#00d4ff' },
                  { label:'Commission Rate', value: `${data.commissionPercent}%`, icon:'🔒', color:'#22c55e' },
                  { label:'Creator Share', value: `${100 - data.commissionPercent}%`, icon:'🧑‍🎨', color:'#f59e0b' },
                ].map(chip => (
                  <div key={chip.label} style={{
                    display:'flex', alignItems:'center', gap:8,
                    background:'rgba(255,255,255,0.05)',
                    border:'1px solid rgba(255,255,255,0.1)',
                    borderRadius:12, padding:'8px 14px',
                  }}>
                    <span style={{ fontSize:16 }}>{chip.icon}</span>
                    <div>
                      <div style={{ fontSize:11, color:'rgba(255,255,255,0.45)', fontWeight:600, textTransform:'uppercase', letterSpacing:'0.06em' }}>{chip.label}</div>
                      <div style={{ fontSize:15, fontWeight:800, color: chip.color }}>{chip.value}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* ── Stat Cards ── */}
          <div className="stats-grid">
            <StatCard icon="💰" label="Total Revenue" value={`₹${Number(data.totalRevenue || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} sub="Total platform earnings" color="purple" />
            <StatCard icon="🪙" label="Coin Pack Revenue" value={`₹${Number(data.coinPurchaseRevenue || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`} sub={`${data.coinPackagesSold} packs sold`} color="orange" />
            <StatCard icon="⚡" label="Commission Earned" value={`${data.commissionEarned || 0} coins`} sub={`${data.commissionPercent}% from ${data.paidSessionCount} sessions`} color="green" />
          </div>

          {/* ── How Platform Earns ── */}
          <div style={{
            background: 'linear-gradient(135deg, rgba(108,93,211,0.08), rgba(34,197,94,0.05))',
            border: '1px solid rgba(108,93,211,0.2)',
            borderRadius: 20,
            padding: '24px 28px',
          }}>
            <h3 style={{ margin:'0 0 18px', fontSize:16, fontWeight:800, display:'flex', alignItems:'center', gap:8 }}>
              <span style={{ background:'linear-gradient(135deg,#f59e0b,#fcd34d)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>💡</span>
              How Platform Revenue Works
            </h3>
            <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(300px, 1fr))', gap:14 }}>
              {[
                {
                  icon:'🪙',
                  title: 'Coin Packs → 100% Platform',
                  desc: `Users buy coin packages to spend on creators. 100% of pack purchase revenue goes to the platform.`,
                  accent: '#6c5dd3',
                },
                {
                  icon:'⚡',
                  title: `Session Commission → ${data.commissionPercent}% Platform`,
                  desc: `When coins are spent on paid chats/calls, the platform keeps ${data.commissionPercent}%. The creator receives ${100 - data.commissionPercent}% (withdrawable).`,
                  accent: '#22c55e',
                },
              ].map(item => (
                <div key={item.title} style={{
                  display:'flex', gap:14, alignItems:'flex-start',
                  background:'var(--bg-elevated)',
                  border:`1px solid rgba(${item.accent === '#6c5dd3' ? '108,93,211' : '34,197,94'},0.2)`,
                  borderRadius:14, padding:'16px 18px',
                  transition:'transform 0.2s ease, box-shadow 0.2s ease',
                }}>
                  <div style={{ fontSize:28, flexShrink:0, background:`rgba(${item.accent === '#6c5dd3' ? '108,93,211' : '34,197,94'},0.12)`, borderRadius:10, width:48, height:48, display:'flex', alignItems:'center', justifyContent:'center' }}>
                    {item.icon}
                  </div>
                  <div>
                    <strong style={{ fontSize:13, color:'var(--text-primary)', display:'block', marginBottom:5, fontWeight:700 }}>{item.title}</strong>
                    <p style={{ fontSize:12.5, color:'var(--text-secondary)', margin:0, lineHeight:1.6 }}>{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* ── Revenue Trend Chart ── */}
          <div style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 20,
            padding: '24px 26px',
            boxShadow: 'var(--shadow-card)',
          }}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:24, flexWrap:'wrap', gap:12 }}>
              <h3 style={{ margin:0, fontSize:16, fontWeight:800, color:'var(--text-primary)' }}>📈 Revenue Trend</h3>
              <div style={{ display:'flex', alignItems:'center', gap:16, fontSize:12, color:'var(--text-secondary)', fontWeight:600 }}>
                {[['#F59E0B', 'Coin Revenue (₹)'], ['#10B981', 'Commission (coins)']].map(([color, name]) => (
                  <span key={name} style={{ display:'flex', alignItems:'center', gap:6 }}>
                    <span style={{ width:10, height:10, borderRadius:'50%', background:color, display:'inline-block', boxShadow:`0 0 6px ${color}` }} />
                    {name}
                  </span>
                ))}
              </div>
            </div>
            <div style={{ overflowX:'auto' }}>
              {data.chart.every(d => !d.coinRevenue && !d.commission) ? (
                <div style={{ textAlign:'center', color:'var(--text-muted)', padding:'50px', fontSize:15 }}>
                  📊 No revenue data for this period yet
                </div>
              ) : (
                <div style={{ display:'flex', alignItems:'flex-end', gap:5, minHeight:180, padding:'0 4px 32px', minWidth:`${data.chart.length * 42}px` }}>
                  {data.chart
                    .filter((_, i, arr) => arr.length <= 20 || i % Math.ceil(arr.length / 20) === 0)
                    .map((item, idx) => {
                      const isHovered = hoveredBar === idx;
                      return (
                        <div
                          key={item.date}
                          style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:5, flex:1, minWidth:32, cursor:'pointer', position:'relative' }}
                          onMouseEnter={() => setHoveredBar(idx)}
                          onMouseLeave={() => setHoveredBar(null)}
                        >
                          {isHovered && (
                            <div style={{
                              position:'absolute', bottom:'calc(100% + 8px)',
                              background:'rgba(15,15,26,0.95)', border:'1px solid rgba(108,93,211,0.4)',
                              borderRadius:10, padding:'8px 12px', fontSize:11, whiteSpace:'nowrap', zIndex:10,
                              pointerEvents:'none',
                            }}>
                              <div style={{ color:'#F59E0B', fontWeight:700 }}>₹{item.coinRevenue || 0} coins</div>
                              <div style={{ color:'#10B981', fontWeight:700 }}>{item.commission || 0} commission</div>
                            </div>
                          )}
                          <div style={{ display:'flex', alignItems:'flex-end', gap:3, height:140 }}>
                            {[
                              { val: item.coinRevenue || 0, color:'#F59E0B', glow:'rgba(245,158,11,0.5)' },
                              { val: item.commission || 0, color:'#10B981', glow:'rgba(16,185,129,0.5)' },
                            ].map(({ val, color, glow }) => (
                              <div
                                key={color}
                                style={{
                                  width:10, borderRadius:'4px 4px 0 0',
                                  background:color,
                                  height:`${Math.max(4, (val / maxChart) * 130)}px`,
                                  transition:'height 0.5s cubic-bezier(0.4,0,0.2,1), box-shadow 0.2s',
                                  boxShadow: isHovered ? `0 0 12px ${glow}` : 'none',
                                  opacity: isHovered ? 1 : 0.75,
                                }}
                              />
                            ))}
                          </div>
                          <span style={{ fontSize:9, color:'var(--text-muted)', fontWeight:700, textAlign:'center', whiteSpace:'nowrap' }}>
                            {new Date(item.date + 'T00:00:00').toLocaleDateString('en-IN', { day:'numeric', month:'short' })}
                          </span>
                        </div>
                      );
                    })}
                </div>
              )}
            </div>
          </div>

          {/* ── Top Creators ── */}
          {data.topCreators && data.topCreators.length > 0 && (
            <div style={{
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 20,
              padding: '24px 26px',
              boxShadow: 'var(--shadow-card)',
            }}>
              <h3 style={{ margin:'0 0 20px', fontSize:16, fontWeight:800, display:'flex', alignItems:'center', gap:8 }}>
                🏆 Top Creators by Earnings
              </h3>
              <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
                {data.topCreators.map((creator, idx) => {
                  const commission = Math.round(creator.totalEarned * data.commissionPercent / (100 - data.commissionPercent || 1));
                  const rankColors = ['linear-gradient(135deg,#FFD700,#FFA500)', 'linear-gradient(135deg,#C0C0C0,#A9A9A9)', 'linear-gradient(135deg,#CD7F32,#A0522D)'];
                  const rankColor = rankColors[idx] || 'var(--bg-elevated)';
                  const rankText = idx < 3 ? ['#000','#000','#fff'][idx] : 'var(--text-muted)';
                  return (
                    <div key={creator.userId} style={{
                      display:'flex', alignItems:'center', gap:16,
                      background:'var(--bg-elevated)',
                      border:'1px solid var(--border)',
                      borderRadius:14, padding:'14px 18px',
                      transition:'all 0.2s ease',
                    }}
                    onMouseEnter={e => { e.currentTarget.style.borderColor='rgba(108,93,211,0.4)'; e.currentTarget.style.transform='translateX(4px)'; }}
                    onMouseLeave={e => { e.currentTarget.style.borderColor='var(--border)'; e.currentTarget.style.transform='translateX(0)'; }}
                    >
                      {/* Rank */}
                      <div style={{
                        width:32, height:32, borderRadius:10,
                        background: idx < 3 ? rankColor : 'var(--bg-card)',
                        display:'flex', alignItems:'center', justifyContent:'center',
                        fontWeight:900, fontSize:13, color: rankText, flexShrink:0,
                      }}>
                        {idx < 3 ? ['🥇','🥈','🥉'][idx] : idx+1}
                      </div>

                      {/* Avatar + Name */}
                      <div style={{ display:'flex', alignItems:'center', gap:10, flex:1, minWidth:0 }}>
                        {creator.avatarUrl ? (
                          <img src={getAbsoluteUrl(creator.avatarUrl)} alt="" style={{ width:40, height:40, borderRadius:12, objectFit:'cover', border:'2px solid var(--border)' }} />
                        ) : (
                          <div style={{ width:40, height:40, borderRadius:12, background:'linear-gradient(135deg,#7C3AED,#A855F7)', color:'#fff', fontWeight:800, fontSize:15, display:'flex', alignItems:'center', justifyContent:'center', border:'2px solid rgba(168,85,247,0.3)' }}>
                            {creator.name[0]?.toUpperCase()}
                          </div>
                        )}
                        <div>
                          <div style={{ fontWeight:700, fontSize:14 }}>{creator.name}</div>
                          <div style={{ fontSize:12, color:'var(--text-muted)' }}>Creator</div>
                        </div>
                      </div>

                      {/* Total Earned */}
                      <div style={{ textAlign:'right', minWidth:120 }}>
                        <div style={{ fontSize:13, color:'var(--text-muted)', marginBottom:3 }}>Total Earned</div>
                        <div style={{ fontWeight:800, fontSize:16, color:'var(--text-primary)' }}>🪙 {creator.totalEarned.toLocaleString()}</div>
                      </div>

                      {/* Platform Commission */}
                      <div style={{ textAlign:'right', minWidth:130 }}>
                        <div style={{ fontSize:13, color:'var(--text-muted)', marginBottom:3 }}>Platform Got</div>
                        <span style={{
                          background:'rgba(34,197,94,0.1)', color:'#22c55e',
                          border:'1px solid rgba(34,197,94,0.25)',
                          fontWeight:800, fontSize:14, padding:'4px 12px', borderRadius:10,
                          display:'inline-block',
                        }}>
                          🪙 {commission}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {!data.topCreators?.length && (
            <div style={{
              background: 'var(--bg-card)', border: '1px solid var(--border)',
              borderRadius: 20, padding: '48px', textAlign:'center',
              color:'var(--text-secondary)',
            }}>
              <div style={{ fontSize:40, marginBottom:12 }}>🎬</div>
              No paid sessions recorded yet. Creators earn once users start paid chats/calls.
            </div>
          )}
        </>
      )}
    </div>
  );
}
