import { useState, useEffect } from 'react';
import Spinner from '../components/Spinner';
import { useContent } from '../viewmodels/useContent';

// ─── Field definitions grouped by section ───────────────────────────────────

const SECTIONS = [
  {
    title: '💰 Coin Rates (Calls & Chat)',
    fields: [
      { key: 'chatCoinsPerMinute',    label: 'Chat Coins / Minute',    type: 'number', unit: 'coins' },
      { key: 'audioCoinsPerMinute',   label: 'Audio Coins / Minute',   type: 'number', unit: 'coins' },
      { key: 'videoCoinsPerMinute',   label: 'Video Coins / Minute',   type: 'number', unit: 'coins' },
      { key: 'chatCoinsPerMessage',   label: 'Chat Coins / Message',   type: 'number', unit: 'coins' },
      { key: 'chatMessageDeductionInterval', label: 'Chat Deduction Interval', type: 'number', unit: 'msgs' },
    ],
  },
  {
    title: '🔒 Private Content Pricing',
    fields: [
      { key: 'privatePostCoinPrice',   label: 'Private Post Price (Default)',      type: 'number', unit: 'coins' },
      { key: 'privateCommunityCoins',  label: 'Private Community Price (Default)', type: 'number', unit: 'coins' },
      { key: 'postPriceMinCoins',      label: 'Minimum Post Price',                type: 'number', unit: 'coins' },
      { key: 'postPriceMaxCoins',      label: 'Maximum Post Price',                type: 'number', unit: 'coins' },
      { key: 'communityPriceMinCoins', label: 'Min VIP Community Price',           type: 'number', unit: 'coins' },
      { key: 'communityPriceMaxCoins', label: 'Max VIP Community Price',           type: 'number', unit: 'coins' },
      { key: 'communitySubscriptionDays', label: 'Community Subscription Duration', type: 'number', unit: 'days' },
    ],
  },
  {
    title: '💬 Conversation Limits',
    fields: [
      { key: 'freeConversationsPerWeek',   label: 'Free Conversations / Week',   type: 'number', unit: 'convs' },
      { key: 'freeMessagesPerConversation',label: 'Free Messages / Conversation',type: 'number', unit: 'msgs' },
      { key: 'messageRequestsPerDay',      label: 'Message Requests / Day',      type: 'number', unit: 'reqs' },
      { key: 'messageRequestExpiryHours',  label: 'Message Request Expiry',      type: 'number', unit: 'hrs' },
    ],
  },
  {
    title: '📞 Call Settings',
    fields: [
      { key: 'callGracePeriodSeconds', label: 'Call Grace Period',     type: 'number', unit: 'secs' },
      { key: 'callRingTimeoutSeconds', label: 'Call Ring Timeout',     type: 'number', unit: 'secs' },
      { key: 'callJoinTimeoutSeconds', label: 'Call Join Timeout',     type: 'number', unit: 'secs' },
    ],
  },
  {
    title: '🏦 Platform Financials',
    fields: [
      { key: 'platformCommissionPercent', label: 'Platform Commission', type: 'number', unit: '%' },
      { key: 'creatorSettlementDays',     label: 'Creator Settlement',  type: 'number', unit: 'days' },
    ],
  },
  {
    title: '🎁 Rewards & Referrals',
    fields: [
      { key: 'dailyLoginRewardSchedule', label: 'Daily Rewards Schedule (Day 1–7)', type: 'text', unit: 'comma-sep' },
      { key: 'referralInviterCoins',     label: 'Referral Reward (Inviter)',        type: 'number', unit: 'coins' },
      { key: 'referralInviteeCoins',     label: 'Referral Bonus (Invitee)',         type: 'number', unit: 'coins' },
    ],
  },
  {
    title: '🚀 Post Boosting & Bounty',
    fields: [
      { key: 'postBoostCoins',  label: 'Post Boosting Cost',     type: 'number', unit: 'coins' },
      { key: 'postBoostHours',  label: 'Post Boosting Duration', type: 'number', unit: 'hours' },
      { key: 'bountyMinCoins',  label: 'Minimum Bounty Coins',  type: 'number', unit: 'coins' },
    ],
  },
];

// List fields that need special serialization (comma-separated ↔ list)
const LIST_FIELDS = new Set([
  'callDurationOptions',
  'paidChatDurationOptions',
  'restrictedWords',
  'dailyLoginRewardSchedule',
]);

function camelToSnake(str) {
  return str.replace(/[A-Z]/g, c => `_${c.toLowerCase()}`);
}

function serializeListField(key, value) {
  if (key === 'restrictedWords') {
    return value.split(',').map(x => x.trim()).filter(Boolean);
  }
  return value.split(',').map(x => parseInt(x.trim(), 10)).filter(x => !isNaN(x));
}

// ─── Component ───────────────────────────────────────────────────────────────

export default function SettingsView() {
  const { settings, saveSettings } = useContent();
  const [form, setForm] = useState(null);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (settings && !form) {
      const initial = { ...settings };
      // Convert list fields to comma-separated strings for editing
      LIST_FIELDS.forEach(key => {
        if (Array.isArray(initial[key])) {
          initial[key] = initial[key].join(', ');
        }
      });
      setForm(initial);
    }
  }, [settings, form]);

  const handleSave = async () => {
    setSaving(true); setSuccess(false); setError(null);
    const payload = {};

    // Process all editable fields
    if (form) {
      Object.keys(form).forEach(key => {
        const val = form[key];
        if (val === undefined || val === null) return;
        if (LIST_FIELDS.has(key)) {
          const parsed = serializeListField(key, String(val));
          if (parsed.length > 0) payload[camelToSnake(key)] = parsed;
        } else if (typeof val === 'boolean') {
          payload[camelToSnake(key)] = val;
        } else if (typeof val === 'number' || (typeof val === 'string' && val !== '')) {
          payload[camelToSnake(key)] = isNaN(Number(val)) ? val : Number(val);
        }
      });
    }

    const ok = await saveSettings(payload);
    if (ok) { setSuccess(true); setTimeout(() => setSuccess(false), 3000); }
    else setError('Failed to save settings. Please try again.');
    setSaving(false);
  };

  const setField = (key, value) =>
    setForm(p => ({ ...p, [key]: value }));

  if (!form) return <Spinner text="Loading settings…" />;

  return (
    <div>
      <div className="page-header">
        <h2>Platform Settings</h2>
        <button className="btn btn--primary" onClick={handleSave} disabled={saving}>
          {saving ? 'Saving…' : '💾 Save Changes'}
        </button>
      </div>

      {success && <div className="alert alert--success">✅ Settings saved successfully!</div>}
      {error   && <div className="alert alert--error">⚠️ {error}</div>}

      {/* ── Regular grid sections ─────────────────────────────────────── */}
      {SECTIONS.map(section => (
        <div key={section.title} style={{ marginBottom: 24 }}>
          <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: 10, letterSpacing: '0.03em' }}>
            {section.title}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {section.fields.map(({ key, label, type, unit }) => (
              <div className="card" key={key} style={{ padding: '14px 18px' }}>
                <label className="form-label" htmlFor={key}>{label}</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input
                    id={key}
                    type={type}
                    className="form-input"
                    style={{ flex: 1 }}
                    value={form[key] ?? ''}
                    onChange={e => setField(key, type === 'number' ? +e.target.value : e.target.value)}
                    min={0}
                  />
                  {unit && <span style={{ color: 'var(--text-muted)', fontSize: '0.78rem', whiteSpace: 'nowrap' }}>{unit}</span>}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}

      {/* ── List fields (full width) ──────────────────────────────────── */}
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: 10, letterSpacing: '0.03em' }}>
          ⏱️ Duration Options & Safety
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {/* Call Duration Options */}
          <div className="card" style={{ padding: '14px 18px' }}>
            <label className="form-label" htmlFor="callDurationOptions">
              Call Duration Options
              <span style={{ fontWeight: 400, color: 'var(--text-muted)', fontSize: '0.75rem', marginLeft: 6 }}>(minutes, comma-separated)</span>
            </label>
            <input
              id="callDurationOptions"
              type="text"
              className="form-input"
              value={form.callDurationOptions ?? ''}
              onChange={e => setField('callDurationOptions', e.target.value)}
              placeholder="5, 10, 15, 30"
            />
          </div>

          {/* Paid Chat Duration Options */}
          <div className="card" style={{ padding: '14px 18px' }}>
            <label className="form-label" htmlFor="paidChatDurationOptions">
              Paid Chat Duration Options
              <span style={{ fontWeight: 400, color: 'var(--text-muted)', fontSize: '0.75rem', marginLeft: 6 }}>(minutes, comma-separated)</span>
            </label>
            <input
              id="paidChatDurationOptions"
              type="text"
              className="form-input"
              value={form.paidChatDurationOptions ?? ''}
              onChange={e => setField('paidChatDurationOptions', e.target.value)}
              placeholder="5, 10, 15, 30"
            />
          </div>
        </div>

        {/* Restricted Words - full width */}
        <div className="card" style={{ padding: '14px 18px', marginTop: 12 }}>
          <label className="form-label" htmlFor="restrictedWords">
            🚫 Restricted Words / Phrases
            <span style={{ fontWeight: 400, color: 'var(--text-muted)', fontSize: '0.75rem', marginLeft: 6 }}>(comma-separated)</span>
          </label>
          <textarea
            id="restrictedWords"
            className="form-input"
            style={{ minHeight: 80, resize: 'vertical', fontFamily: 'monospace', fontSize: '0.82rem' }}
            value={form.restrictedWords ?? ''}
            onChange={e => setField('restrictedWords', e.target.value)}
            placeholder="kill yourself, child sexual, rape threat"
          />
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 4 }}>
            {String(form.restrictedWords || '').split(',').filter(w => w.trim()).length} terms configured
          </div>
        </div>
      </div>

      {/* ── Toggles ──────────────────────────────────────────────────── */}
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: 10, letterSpacing: '0.03em' }}>
          🔧 Feature Toggles
        </div>
        <div className="card" style={{ padding: '18px 20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontWeight: 600, fontSize: '0.9rem', marginBottom: 2 }}>Dummy Payments Mode</div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                When enabled, all payments succeed without real processing. Disable in production.
              </div>
            </div>
            <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', flexShrink: 0 }}>
              <div
                onClick={() => setField('dummyPaymentsEnabled', !form.dummyPaymentsEnabled)}
                style={{
                  width: 48,
                  height: 26,
                  borderRadius: 13,
                  background: form.dummyPaymentsEnabled ? 'var(--accent)' : 'var(--border)',
                  position: 'relative',
                  cursor: 'pointer',
                  transition: 'background 0.2s',
                }}
              >
                <div style={{
                  position: 'absolute',
                  top: 3,
                  left: form.dummyPaymentsEnabled ? 24 : 3,
                  width: 20,
                  height: 20,
                  borderRadius: '50%',
                  background: '#fff',
                  transition: 'left 0.2s',
                  boxShadow: '0 1px 4px rgba(0,0,0,0.3)',
                }} />
              </div>
              <span style={{ fontSize: '0.88rem', fontWeight: 600, color: form.dummyPaymentsEnabled ? 'var(--green)' : 'var(--text-muted)' }}>
                {form.dummyPaymentsEnabled ? '✅ Enabled' : '❌ Disabled'}
              </span>
            </label>
          </div>
        </div>
      </div>

      {/* ── Read-only info ────────────────────────────────────────────── */}
      <div className="card" style={{ marginTop: 8 }}>
        <div className="card__title">ℹ️ Current Configuration Summary</div>
        <div className="info-grid">
          <div className="info-item">
            <span className="info-item__label">Call Durations</span>
            <span className="info-item__value">{String(form.callDurationOptions || '')} min</span>
          </div>
          <div className="info-item">
            <span className="info-item__label">Paid Chat Durations</span>
            <span className="info-item__value">{String(form.paidChatDurationOptions || '')} min</span>
          </div>
          <div className="info-item">
            <span className="info-item__label">Grace Period</span>
            <span className="info-item__value">{form.callGracePeriodSeconds ?? '—'}s</span>
          </div>
          <div className="info-item">
            <span className="info-item__label">Restricted Words</span>
            <span className="info-item__value">
              {String(form.restrictedWords || '').split(',').filter(w => w.trim()).length} terms
            </span>
          </div>
          <div className="info-item">
            <span className="info-item__label">Dummy Payments</span>
            <span className="info-item__value">{form.dummyPaymentsEnabled ? '✅ Enabled' : '❌ Disabled'}</span>
          </div>
          <div className="info-item">
            <span className="info-item__label">Msg Request Expiry</span>
            <span className="info-item__value">{form.messageRequestExpiryHours ?? '—'}h</span>
          </div>
        </div>
      </div>
    </div>
  );
}
