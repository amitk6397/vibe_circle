import { useState } from 'react';

export default function AuthView({
  onLogin,
  onRegister,
  onForgotPassword,
  onResetPassword,
  loading,
  error,
}) {
  const [mode, setMode] = useState('login'); // 'login' | 'register' | 'forgot' | 'reset'

  // Login form state
  const [loginEmail, setLoginEmail] = useState('amitk15042003@gmail.com');
  const [loginPassword, setLoginPassword] = useState('Amit@7454');

  // Register form state
  const [regName, setRegName] = useState('');
  const [regAge, setRegAge] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regSuccessMsg, setRegSuccessMsg] = useState('');

  // Forgot password form state
  const [forgotEmail, setForgotEmail] = useState('');
  const [resetToken, setResetToken] = useState('');
  const [resetPassword, setResetPassword] = useState('');
  const [resetSuccessMsg, setResetSuccessMsg] = useState('');
  const [devTokenMsg, setDevTokenMsg] = useState('');

  const handleLoginSubmit = (e) => {
    e.preventDefault();
    onLogin(loginEmail, loginPassword);
  };

  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setRegSuccessMsg('');
    const res = await onRegister(regName, regAge, regEmail, regPassword);
    if (res.success) {
      setRegSuccessMsg(
        'Registration successful! By default, new accounts are created with the "User" role. Ask a database administrator to run "python scripts/make_admin.py" to promote your role to admin.'
      );
      setRegName('');
      setRegAge('');
      setRegEmail('');
      setRegPassword('');
    }
  };

  const handleForgotSubmit = async (e) => {
    e.preventDefault();
    setDevTokenMsg('');
    const res = await onForgotPassword(forgotEmail);
    if (res.success) {
      const devToken = res.data?.development_token;
      if (devToken) {
        setDevTokenMsg(`[Dev Mode] Recovery Token generated: ${devToken}`);
        setResetToken(devToken); // Autofill for convenience
        setTimeout(() => setMode('reset'), 1500);
      } else {
        setDevTokenMsg('Recovery link instructions sent if the account exists.');
      }
    }
  };

  const handleResetSubmit = async (e) => {
    e.preventDefault();
    setResetSuccessMsg('');
    const res = await onResetPassword(resetToken, resetPassword);
    if (res.success) {
      setResetSuccessMsg('Password has been reset successfully! You can now log in.');
      setResetToken('');
      setResetPassword('');
      setTimeout(() => {
        setMode('login');
        setResetSuccessMsg('');
      }, 2500);
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-brand">
          <div className="login-brand-icon">V</div>
          <div className="login-brand-text">
            <strong>VibeCam</strong>
            <em>Admin Console</em>
          </div>
        </div>

        {error && <div className="login-error">⚠️ {error}</div>}

        {/* ─── LOGIN MODE ─── */}
        {mode === 'login' && (
          <div className="auth-form-wrapper">
            <h1 className="login-title">Welcome back</h1>
            <p className="login-subtitle">Sign in with your admin credentials to continue.</p>

            <form onSubmit={handleLoginSubmit}>
              <div className="form-group">
                <label className="form-label" htmlFor="email">Email address</label>
                <input
                  id="email"
                  type="email"
                  className="form-input"
                  placeholder="admin@vibecam.app"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  className="form-input"
                  placeholder="••••••••"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
                <button
                  type="button"
                  className="text-sm"
                  style={{ color: 'var(--accent-light)', fontWeight: 500 }}
                  onClick={() => setMode('forgot')}
                >
                  Forgot password?
                </button>
              </div>

              <button
                type="submit"
                className="btn btn--primary btn--full"
                disabled={loading}
              >
                {loading ? 'Signing in…' : '🔐 Sign in to Admin Panel'}
              </button>
            </form>

            <p style={{ textAlign: 'center', marginTop: 24, fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
              Don&apos;t have an account?{' '}
              <button
                type="button"
                style={{ color: 'var(--accent-light)', fontWeight: 600 }}
                onClick={() => setMode('register')}
              >
                Register
              </button>
            </p>
          </div>
        )}

        {/* ─── REGISTER MODE ─── */}
        {mode === 'register' && (
          <div className="auth-form-wrapper">
            <h1 className="login-title">Create Admin Account</h1>
            <p className="login-subtitle">Register a new console profile.</p>

            {regSuccessMsg && <div className="alert alert--success">{regSuccessMsg}</div>}

            <form onSubmit={handleRegisterSubmit}>
              <div className="form-group">
                <label className="form-label">Full Name</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Amit Kumar"
                  value={regName}
                  onChange={(e) => setRegName(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Age</label>
                <input
                  type="number"
                  className="form-input"
                  placeholder="21"
                  min="18"
                  max="120"
                  value={regAge}
                  onChange={(e) => setRegAge(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Email address</label>
                <input
                  type="email"
                  className="form-input"
                  placeholder="name@vibecam.app"
                  value={regEmail}
                  onChange={(e) => setRegEmail(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Password</label>
                <input
                  type="password"
                  className="form-input"
                  placeholder="At least 8 chars (letters + numbers)"
                  value={regPassword}
                  onChange={(e) => setRegPassword(e.target.value)}
                  required
                />
              </div>

              <button
                type="submit"
                className="btn btn--primary btn--full"
                disabled={loading}
              >
                {loading ? 'Creating Account…' : '📝 Create Console Account'}
              </button>
            </form>

            <p style={{ textAlign: 'center', marginTop: 24, fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
              Already registered?{' '}
              <button
                type="button"
                style={{ color: 'var(--accent-light)', fontWeight: 600 }}
                onClick={() => setMode('login')}
              >
                Sign In
              </button>
            </p>
          </div>
        )}

        {/* ─── FORGOT PASSWORD MODE ─── */}
        {mode === 'forgot' && (
          <div className="auth-form-wrapper">
            <h1 className="login-title">Recover Password</h1>
            <p className="login-subtitle">Enter your email to reset credentials.</p>

            {devTokenMsg && <div className="alert alert--info" style={{ wordBreak: 'break-all' }}>{devTokenMsg}</div>}

            <form onSubmit={handleForgotSubmit}>
              <div className="form-group">
                <label className="form-label">Email address</label>
                <input
                  type="email"
                  className="form-input"
                  placeholder="amitk15042003@gmail.com"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  required
                />
              </div>

              <button
                type="submit"
                className="btn btn--primary btn--full"
                disabled={loading}
              >
                {loading ? 'Requesting token…' : '🔑 Get Recovery Token'}
              </button>
            </form>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 24, fontSize: '0.8rem' }}>
              <button
                type="button"
                style={{ color: 'var(--accent-light)', fontWeight: 600 }}
                onClick={() => setMode('login')}
              >
                Back to Sign In
              </button>

              <button
                type="button"
                style={{ color: 'var(--text-secondary)', fontWeight: 500 }}
                onClick={() => setMode('reset')}
              >
                Have reset token?
              </button>
            </div>
          </div>
        )}

        {/* ─── RESET PASSWORD MODE ─── */}
        {mode === 'reset' && (
          <div className="auth-form-wrapper">
            <h1 className="login-title">Reset Password</h1>
            <p className="login-subtitle">Enter token and new password.</p>

            {resetSuccessMsg && <div className="alert alert--success">{resetSuccessMsg}</div>}

            <form onSubmit={handleResetSubmit}>
              <div className="form-group">
                <label className="form-label">One-Time Reset Token</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Paste token here…"
                  value={resetToken}
                  onChange={(e) => setResetToken(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">New Password</label>
                <input
                  type="password"
                  className="form-input"
                  placeholder="At least 8 characters…"
                  value={resetPassword}
                  onChange={(e) => setResetPassword(e.target.value)}
                  required
                />
              </div>

              <button
                type="submit"
                className="btn btn--primary btn--full"
                disabled={loading}
              >
                {loading ? 'Saving new password…' : '💾 Save New Password'}
              </button>
            </form>

            <p style={{ textAlign: 'center', marginTop: 24, fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
              Or{' '}
              <button
                type="button"
                style={{ color: 'var(--accent-light)', fontWeight: 600 }}
                onClick={() => setMode('login')}
              >
                Back to Sign In
              </button>
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
