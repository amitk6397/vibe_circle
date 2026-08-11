import { useEffect, useState } from 'react';
import Spinner from '../components/Spinner';
import { referralService } from '../services/referralService';

const getAbsoluteUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) {
    return path;
  }
  const apiBase = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api/v1';
  const hostBase = apiBase.split('/api/')[0];
  return `${hostBase}${path.startsWith('/') ? '' : '/'}${path}`;
};

function StatPill({ icon, label, value, accent, gradient }) {
  return (
    <div style={{
      background: 'var(--bg-card)',
      border: `1px solid ${accent}33`,
      borderRadius: 18,
      padding: '20px 22px',
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      position: 'relative',
      overflow: 'hidden',
      boxShadow: `0 4px 24px ${accent}15`,
      transition: 'all 0.2s ease',
      cursor: 'default',
    }}
    onMouseEnter={e => { e.currentTarget.style.transform='translateY(-3px)'; e.currentTarget.style.boxShadow=`0 8px 32px ${accent}30`; }}
    onMouseLeave={e => { e.currentTarget.style.transform='translateY(0)'; e.currentTarget.style.boxShadow=`0 4px 24px ${accent}15`; }}
    >
      <div style={{ position:'absolute', top:0, left:0, right:0, height:3, background: gradient || accent, borderRadius:'18px 18px 0 0' }} />
      <div style={{ width:50, height:50, background:`${accent}15`, border:`1px solid ${accent}30`, borderRadius:14, display:'flex', alignItems:'center', justifyContent:'center', fontSize:22, flexShrink:0 }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize:'2rem', fontWeight:900, lineHeight:1, letterSpacing:'-0.02em', color: accent }}>{value}</div>
        <div style={{ fontSize:12, color:'var(--text-secondary)', marginTop:4, fontWeight:500 }}>{label}</div>
      </div>
    </div>
  );
}

export default function ReferralView() {
  const [stats, setStats] = useState(null);
  const [topReferrers, setTopReferrers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const [statsRes, topRes] = await Promise.all([
        referralService.stats(),
        referralService.topReferrers(),
      ]);
      setStats(statsRes.data);
      setTopReferrers(Array.isArray(topRes.data) ? topRes.data : []);
    } catch (e) {
      setError(e?.response?.data?.detail || e.message || 'Failed to load referral data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  return (
    <div className="view-container">
      {/* ── Header ── */}
      <div className="view-header" style={{ marginBottom: 28 }}>
        <div>
          <h1 className="view-title" style={{ fontSize:'1.75rem', letterSpacing:'-0.03em', display:'flex', alignItems:'center', gap:10 }}>
            <span style={{ background:'linear-gradient(135deg,#f59e0b,#fcd34d)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>🪙</span>
            Referral Program
          </h1>
          <p className="view-subtitle">Track referrals, coin awards, and top referrers</p>
        </div>
        <button
          className="btn btn--primary"
          onClick={load}
          style={{ display:'flex', alignItems:'center', gap:8, padding:'10px 20px' }}
        >
          🔄 Refresh
        </button>
      </div>

      {error && <div className="alert alert--error" style={{ marginBottom:18 }}>⚠️ {error}</div>}

      {loading ? (
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'80px', gap:16 }}>
          <div className="spinner spinner--lg" />
          <p style={{ color:'var(--text-muted)', fontSize:14 }}>Loading referral data…</p>
        </div>
      ) : (
        <>
          {/* ── Stat Cards ── */}
          <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(200px, 1fr))', gap:16, marginBottom:28 }}>
            <StatPill icon="👥" label="Users Referred" value={stats?.totalReferred ?? 0} accent="#5B5CE2" gradient="linear-gradient(90deg,#5b5ce2,#7c3aed)" />
            <StatPill icon="🔗" label="Active Referrers" value={stats?.totalReferrers ?? 0} accent="#7C3AED" gradient="linear-gradient(90deg,#7c3aed,#a855f7)" />
            <StatPill icon="🪙" label="Coins Awarded" value={stats?.totalCoinsAwarded ?? 0} accent="#F59E0B" gradient="linear-gradient(90deg,#f59e0b,#fcd34d)" />
            <StatPill icon="🎁" label="Reward Per Referral" value={`${stats?.rewardPerReferral ?? 50} 🪙`} accent="#10B981" gradient="linear-gradient(90deg,#10b981,#00d4ff)" />
          </div>

          {/* ── Config Banner ── */}
          <div style={{
            background: 'linear-gradient(135deg, rgba(92,92,226,0.1), rgba(124,58,237,0.1))',
            border: '1px solid rgba(92,92,226,0.25)',
            borderRadius: 18,
            padding: '20px 24px',
            marginBottom: 28,
            display: 'flex',
            alignItems: 'center',
            gap: 20,
            flexWrap: 'wrap',
          }}>
            <div style={{ fontSize:28 }}>💡</div>
            <div style={{ flex:1 }}>
              <h3 style={{ margin:'0 0 8px', fontSize:15, fontWeight:800 }}>Program Configuration</h3>
              <div style={{ display:'flex', gap:28, flexWrap:'wrap', alignItems:'center' }}>
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ color:'var(--text-muted)', fontSize:13 }}>Inviter earns:</span>
                  <span style={{
                    background:'rgba(245,158,11,0.12)', color:'#F59E0B',
                    border:'1px solid rgba(245,158,11,0.3)',
                    fontWeight:800, padding:'3px 12px', borderRadius:10, fontSize:14,
                  }}>
                    🪙 {stats?.rewardPerReferral} coins
                  </span>
                </div>
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ color:'var(--text-muted)', fontSize:13 }}>Invitee gets:</span>
                  <span style={{
                    background:'rgba(16,185,129,0.12)', color:'#10B981',
                    border:'1px solid rgba(16,185,129,0.3)',
                    fontWeight:800, padding:'3px 12px', borderRadius:10, fontSize:14,
                  }}>
                    🪙 {stats?.inviteeBonus} coins
                  </span>
                </div>
                <div style={{ fontSize:12, color:'var(--text-muted)', fontStyle:'italic' }}>
                  Configurable via: <code style={{ background:'var(--bg-elevated)', padding:'2px 8px', borderRadius:6, fontStyle:'normal', color:'var(--accent-light)' }}>REFERRAL_INVITER_COINS</code>,{' '}
                  <code style={{ background:'var(--bg-elevated)', padding:'2px 8px', borderRadius:6, fontStyle:'normal', color:'var(--accent-light)' }}>REFERRAL_INVITEE_COINS</code>
                </div>
              </div>
            </div>
          </div>

          {/* ── Top Referrers ── */}
          <div>
            <h2 style={{ fontSize:18, fontWeight:800, marginBottom:18, display:'flex', alignItems:'center', gap:10 }}>
              🏆 Top Referrers
            </h2>
            {topReferrers.length === 0 ? (
              <div style={{
                textAlign:'center', padding:'80px 40px',
                background:'var(--bg-card)', border:'1px solid var(--border)',
                borderRadius:20,
              }}>
                <div style={{ fontSize:56, marginBottom:16 }}>🪙</div>
                <div style={{ fontSize:18, fontWeight:700, color:'var(--text-primary)', marginBottom:8 }}>No referrals yet</div>
                <div style={{ color:'var(--text-muted)', fontSize:14 }}>Users will appear here once they start referring friends.</div>
              </div>
            ) : (
              <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
                {topReferrers.map((r, idx) => (
                  <div
                    key={r.id}
                    style={{
                      display:'flex', alignItems:'center', gap:16,
                      background:'var(--bg-card)', border:'1px solid var(--border)',
                      borderRadius:16, padding:'14px 18px',
                      transition:'all 0.2s ease',
                    }}
                    onMouseEnter={e => { e.currentTarget.style.borderColor='rgba(108,93,211,0.4)'; e.currentTarget.style.transform='translateX(4px)'; }}
                    onMouseLeave={e => { e.currentTarget.style.borderColor='var(--border)'; e.currentTarget.style.transform='translateX(0)'; }}
                  >
                    {/* Rank */}
                    <div style={{
                      width:36, height:36, borderRadius:10, flexShrink:0,
                      background: idx < 3 ? ['linear-gradient(135deg,#FFD700,#FFA500)', 'linear-gradient(135deg,#C0C0C0,#A9A9A9)', 'linear-gradient(135deg,#CD7F32,#A0522D)'][idx] : 'var(--bg-elevated)',
                      display:'flex', alignItems:'center', justifyContent:'center',
                      fontWeight:900, fontSize:18,
                      boxShadow: idx < 3 ? '0 2px 12px rgba(0,0,0,0.3)' : 'none',
                    }}>
                      {idx < 3 ? ['🥇','🥈','🥉'][idx] : <span style={{ color:'var(--text-secondary)', fontSize:14 }}>{idx+1}</span>}
                    </div>

                    {/* Avatar + Name */}
                    <div style={{ display:'flex', alignItems:'center', gap:12, flex:1, minWidth:0 }}>
                      {r.avatarUrl ? (
                        <img src={getAbsoluteUrl(r.avatarUrl)} alt="" style={{ width:42, height:42, borderRadius:12, objectFit:'cover', border:'2px solid var(--border)' }} />
                      ) : (
                        <div style={{ width:42, height:42, borderRadius:12, background:'linear-gradient(135deg,#7C3AED,#A855F7)', color:'#fff', fontWeight:800, fontSize:16, display:'flex', alignItems:'center', justifyContent:'center', border:'2px solid rgba(168,85,247,0.3)' }}>
                          {r.name[0]?.toUpperCase()}
                        </div>
                      )}
                      <div>
                        <div style={{ fontWeight:700, fontSize:14 }}>{r.name}</div>
                        <div style={{ fontSize:12, color:'var(--text-muted)' }}>{r.email}</div>
                      </div>
                    </div>

                    {/* Referral Code */}
                    <div style={{ textAlign:'center', minWidth:120 }}>
                      <div style={{ fontSize:11, color:'var(--text-muted)', marginBottom:4, textTransform:'uppercase', letterSpacing:'0.06em' }}>Ref Code</div>
                      <code style={{
                        background:'var(--bg-elevated)', padding:'4px 12px',
                        borderRadius:8, fontWeight:800, fontSize:12,
                        letterSpacing:2, color:'var(--accent-light)',
                        border:'1px solid rgba(108,93,211,0.2)',
                      }}>
                        {r.referralCode}
                      </code>
                    </div>

                    {/* Referrals Count */}
                    <div style={{ textAlign:'center', minWidth:80 }}>
                      <div style={{ fontSize:11, color:'var(--text-muted)', marginBottom:4, textTransform:'uppercase', letterSpacing:'0.06em' }}>Referrals</div>
                      <div style={{ fontWeight:800, fontSize:18, color:'#5B5CE2' }}>{r.referralCount}</div>
                    </div>

                    {/* Coins Earned */}
                    <div style={{ textAlign:'right', minWidth:100 }}>
                      <div style={{ fontSize:11, color:'var(--text-muted)', marginBottom:4, textTransform:'uppercase', letterSpacing:'0.06em' }}>Coins Earned</div>
                      <span style={{
                        background:'rgba(245,158,11,0.12)', color:'#F59E0B',
                        border:'1px solid rgba(245,158,11,0.25)',
                        fontWeight:800, fontSize:14, padding:'4px 12px', borderRadius:10,
                        display:'inline-block',
                      }}>
                        🪙 {r.coinsEarned}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
