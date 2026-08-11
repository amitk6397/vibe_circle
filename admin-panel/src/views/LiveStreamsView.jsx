import { useEffect, useState } from 'react';
import Badge from '../components/Badge';
import Spinner from '../components/Spinner';
import { livestreamService } from '../services/livestreamService';

function formatDuration(startedAt, endedAt) {
  const start = new Date(startedAt).getTime();
  const end = endedAt ? new Date(endedAt).getTime() : Date.now();
  const secs = Math.floor((end - start) / 1000);
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

function ProStatCard({ icon, label, value, accent, gradient }) {
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
      boxShadow: `0 4px 24px ${accent}1a`,
      transition: 'all 0.2s ease',
    }}
    onMouseEnter={e => { e.currentTarget.style.transform='translateY(-3px)'; e.currentTarget.style.boxShadow=`0 8px 32px ${accent}33`; }}
    onMouseLeave={e => { e.currentTarget.style.transform='translateY(0)'; e.currentTarget.style.boxShadow=`0 4px 24px ${accent}1a`; }}
    >
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 3,
        background: gradient || accent,
        borderRadius: '18px 18px 0 0',
      }} />
      <div style={{
        width: 50, height: 50,
        background: `${accent}15`,
        border: `1px solid ${accent}30`,
        borderRadius: 14,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 22, flexShrink: 0,
      }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: '2rem', fontWeight: 900, lineHeight: 1, letterSpacing: '-0.02em', color: accent }}>{value}</div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 4, fontWeight: 500 }}>{label}</div>
      </div>
    </div>
  );
}

export default function LiveStreamsView() {
  const [streams, setStreams] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [endingId, setEndingId] = useState(null);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await livestreamService.listAll();
      setStreams(Array.isArray(data) ? data : []);
    } catch (e) {
      setError(e?.response?.data?.detail || e.message || 'Failed to load streams.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleForceEnd = async (streamId) => {
    if (!window.confirm('Force-end this stream? The host will be disconnected.')) return;
    setEndingId(streamId);
    try {
      await livestreamService.forceEnd(streamId);
      setStreams((prev) =>
        prev.map((s) => s.id === streamId ? { ...s, status: 'ended', force_ended: true } : s)
      );
    } catch (e) {
      alert('Failed to end stream: ' + (e?.response?.data?.detail || e.message));
    } finally {
      setEndingId(null);
    }
  };

  const filtered = streams.filter((s) => {
    const matchFilter = filter === 'all' || s.status === filter;
    const matchSearch = !search ||
      s.title?.toLowerCase().includes(search.toLowerCase()) ||
      s.host_name?.toLowerCase().includes(search.toLowerCase());
    return matchFilter && matchSearch;
  });

  const liveCount = streams.filter((s) => s.status === 'live').length;
  const totalViewers = streams.filter((s) => s.status === 'live').reduce((sum, s) => sum + (s.current_viewers || 0), 0);
  const totalGifts = streams.reduce((sum, s) => sum + (s.total_gifts_received || 0), 0);

  return (
    <div className="view-container">
      {/* ── Header ── */}
      <div className="view-header" style={{ marginBottom: 28 }}>
        <div>
          <h1 className="view-title" style={{ fontSize:'1.75rem', letterSpacing:'-0.03em', display:'flex', alignItems:'center', gap:10 }}>
            <span style={{ background:'linear-gradient(135deg,#ef4444,#f97316)', WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent' }}>📡</span>
            Live Streams
          </h1>
          <p className="view-subtitle">Monitor and manage all live stream sessions in real-time</p>
        </div>
        <button
          className="btn btn--primary"
          onClick={load}
          style={{ display:'flex', alignItems:'center', gap:8, padding:'10px 20px' }}
        >
          <span style={{ animation: loading ? 'spin 0.8s linear infinite' : 'none', display:'inline-block' }}>🔄</span>
          Refresh
        </button>
      </div>

      {/* ── Stats Row ── */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(200px, 1fr))', gap:16, marginBottom:28 }}>
        <ProStatCard
          icon="🔴"
          label="Active Streams"
          value={liveCount}
          accent="#EF4444"
          gradient="linear-gradient(90deg, #ef4444, #f97316)"
        />
        <ProStatCard
          icon="👁️"
          label="Live Viewers"
          value={totalViewers}
          accent="#3B82F6"
          gradient="linear-gradient(90deg, #3b82f6, #00d4ff)"
        />
        <ProStatCard
          icon="🎁"
          label="Total Gifts Today"
          value={totalGifts}
          accent="#F59E0B"
          gradient="linear-gradient(90deg, #f59e0b, #fcd34d)"
        />
        <ProStatCard
          icon="📊"
          label="Total Streams"
          value={streams.length}
          accent="#7C3AED"
          gradient="linear-gradient(90deg, #7c3aed, #a855f7)"
        />
      </div>

      {/* ── Filter Bar ── */}
      <div style={{
        display:'flex', gap:12, alignItems:'center', marginBottom:20,
        background:'var(--bg-card)', border:'1px solid var(--border)',
        borderRadius:16, padding:'12px 16px',
      }}>
        <div style={{ position:'relative', flex:1 }}>
          <span style={{ position:'absolute', left:12, top:'50%', transform:'translateY(-50%)', fontSize:14, color:'var(--text-muted)' }}>🔍</span>
          <input
            className="toolbar__search"
            placeholder="Search by title or host…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ width:'100%', paddingLeft:36, maxWidth:'100%' }}
          />
        </div>
        <div style={{ display:'flex', gap:4, background:'var(--bg-elevated)', borderRadius:10, padding:4 }}>
          {['all', 'live', 'ended'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding:'6px 16px', borderRadius:8, fontSize:13, fontWeight:600,
                border:'none', cursor:'pointer', transition:'all 0.2s',
                background: filter === f ? 'linear-gradient(135deg, var(--accent), #7c6be0)' : 'transparent',
                color: filter === f ? '#fff' : 'var(--text-secondary)',
                boxShadow: filter === f ? '0 2px 10px rgba(108,93,211,0.35)' : 'none',
              }}
            >
              {f === 'live' && <span style={{ display:'inline-block', width:7, height:7, borderRadius:'50%', background:'#22c55e', marginRight:5, boxShadow:'0 0 6px #22c55e', animation:'liveRing 2s infinite' }} />}
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {error && <div className="alert alert--error" style={{ marginBottom:16 }}>⚠️ {error}</div>}

      {loading ? (
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'80px', gap:16 }}>
          <div className="spinner spinner--lg" />
          <p style={{ color:'var(--text-muted)', fontSize:14 }}>Loading streams…</p>
        </div>
      ) : filtered.length === 0 ? (
        <div style={{
          textAlign:'center', padding:'80px 40px',
          background:'var(--bg-card)', border:'1px solid var(--border)',
          borderRadius:20,
        }}>
          <div style={{ fontSize:56, marginBottom:16 }}>📡</div>
          <div style={{ fontSize:18, fontWeight:700, color:'var(--text-primary)', marginBottom:8 }}>No streams found</div>
          <div style={{ color:'var(--text-muted)', fontSize:14 }}>
            {filter === 'live' ? 'No streams are currently live.' : 'No streams match your filters.'}
          </div>
        </div>
      ) : (
        <div style={{
          background:'var(--bg-card)', border:'1px solid var(--border)',
          borderRadius:20, overflow:'hidden',
          boxShadow:'var(--shadow-card)',
        }}>
          <div style={{ overflowX:'auto' }}>
            <table className="data-table" style={{ minWidth:900 }}>
              <thead>
                <tr>
                  <th>Host</th>
                  <th>Title</th>
                  <th>Category</th>
                  <th>Status</th>
                  <th>Viewers</th>
                  <th>Peak</th>
                  <th>Gifts 🎁</th>
                  <th>Duration</th>
                  <th>Started</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((s) => (
                  <tr key={s.id}>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                        <div style={{
                          width:36, height:36, borderRadius:'50%',
                          background:'linear-gradient(135deg, #5B5CE2, #7C3AED)',
                          display:'flex', alignItems:'center', justifyContent:'center',
                          color:'#fff', fontWeight:800, fontSize:14,
                          boxShadow:'0 2px 8px rgba(92,92,226,0.4)',
                          flexShrink:0,
                        }}>
                          {(s.host_name || '?')[0].toUpperCase()}
                        </div>
                        <span style={{ fontWeight:600, fontSize:14 }}>{s.host_name || '—'}</span>
                      </div>
                    </td>
                    <td style={{ maxWidth:200, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap', fontWeight:500 }}>
                      {s.title}
                    </td>
                    <td>
                      <span style={{ background:'rgba(59,130,246,0.12)', color:'#3b82f6', border:'1px solid rgba(59,130,246,0.25)', padding:'3px 10px', borderRadius:100, fontSize:12, fontWeight:600 }}>
                        {s.category}
                      </span>
                    </td>
                    <td>
                      {s.status === 'live' ? (
                        <span style={{
                          display:'inline-flex', alignItems:'center', gap:6,
                          background:'rgba(34,197,94,0.12)', color:'#22c55e',
                          border:'1px solid rgba(34,197,94,0.3)',
                          padding:'4px 10px', borderRadius:100, fontSize:12, fontWeight:700,
                        }}>
                          <span style={{ width:7, height:7, borderRadius:'50%', background:'#22c55e', display:'inline-block', animation:'liveRing 2s infinite', boxShadow:'0 0 6px #22c55e' }} />
                          LIVE
                        </span>
                      ) : (
                        <span style={{
                          background: s.force_ended ? 'var(--red-dim)' : 'rgba(144,144,176,0.08)',
                          color: s.force_ended ? 'var(--red)' : 'var(--text-secondary)',
                          border: `1px solid ${s.force_ended ? 'rgba(239,68,68,0.25)' : 'var(--border)'}`,
                          padding:'4px 10px', borderRadius:100, fontSize:12, fontWeight:600,
                        }}>
                          {s.force_ended ? '⛔ Force Ended' : '✓ Ended'}
                        </span>
                      )}
                    </td>
                    <td style={{ fontWeight:700, color:'#3b82f6' }}>{s.current_viewers ?? 0}</td>
                    <td style={{ fontWeight:600, color:'var(--text-secondary)' }}>{s.peak_viewers ?? 0}</td>
                    <td>
                      <span style={{ fontWeight:800, color:'#F59E0B', display:'flex', alignItems:'center', gap:4 }}>
                        🎁 {s.total_gifts_received ?? 0}
                      </span>
                    </td>
                    <td style={{ color:'var(--text-muted)', fontSize:13, fontFamily:'monospace' }}>
                      {formatDuration(s.started_at, s.ended_at)}
                    </td>
                    <td style={{ color:'var(--text-muted)', fontSize:12 }}>
                      {new Date(s.started_at).toLocaleString('en-IN', { dateStyle:'short', timeStyle:'short' })}
                    </td>
                    <td>
                      {s.status === 'live' ? (
                        <button
                          className="btn btn--danger btn--sm"
                          onClick={() => handleForceEnd(s.id)}
                          disabled={endingId === s.id}
                          style={{ whiteSpace:'nowrap' }}
                        >
                          {endingId === s.id ? '⏳' : '⛔'} Force End
                        </button>
                      ) : (
                        <span style={{ color:'var(--text-muted)', fontSize:12 }}>—</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div style={{ padding:'12px 20px', borderTop:'1px solid var(--border)', color:'var(--text-muted)', fontSize:12 }}>
            Showing {filtered.length} of {streams.length} streams
          </div>
        </div>
      )}
    </div>
  );
}
