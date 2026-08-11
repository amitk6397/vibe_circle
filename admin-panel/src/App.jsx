import { useState } from 'react';
import { useAuth } from './viewmodels/useAuth';

import Sidebar from './components/Sidebar';
import Header from './components/Header';

import AuthView from './views/AuthView';
import DashboardView from './views/DashboardView';
import UsersView from './views/UsersView';
import CommunitiesView from './views/CommunitiesView';
import ReportsView from './views/ReportsView';
import WithdrawalsView from './views/WithdrawalsView';
import CommercePlansView from './views/CommercePlansView';
import CoinPackagesView from './views/CoinPackagesView';
import SupportArticlesView from './views/SupportArticlesView';
import SettingsView from './views/SettingsView';
import AuditLogView from './views/AuditLogView';
import TransactionsView from './views/TransactionsView';
import RevenueView from './views/RevenueView';
import GiftsView from './views/GiftsView';
import LiveStreamsView from './views/LiveStreamsView';
import ReferralView from './views/ReferralView';

import './index.css';

function renderPage(page, navigate) {
  switch (page) {
    case 'dashboard':    return <DashboardView onNavigate={navigate} />;
    case 'users':        return <UsersView />;
    case 'communities':  return <CommunitiesView />;
    case 'reports':      return <ReportsView />;
    case 'withdrawals':  return <WithdrawalsView />;
    case 'plans':        return <CoinPackagesView />;
    case 'packages':     return <CoinPackagesView />;
    case 'articles':     return <SupportArticlesView />;
    case 'gifts':        return <GiftsView />;
    case 'livestreams':  return <LiveStreamsView />;
    case 'referral':     return <ReferralView />;
    case 'settings':     return <SettingsView />;
    case 'audit':        return <AuditLogView />;
    case 'transactions': return <TransactionsView />;
    case 'revenue':      return <RevenueView />;

    default:             return <DashboardView onNavigate={navigate} />;
  }
}

export default function App() {
  const {
    user,
    loading,
    error,
    login,
    logout,
    register,
    forgotPassword,
    resetPassword,
    isLoggedIn,
  } = useAuth();
  const [page, setPage] = useState('dashboard');

  if (!isLoggedIn) {
    return (
      <AuthView
        onLogin={login}
        onRegister={register}
        onForgotPassword={forgotPassword}
        onResetPassword={resetPassword}
        loading={loading}
        error={error}
      />
    );
  }

  return (
    <div className="app-shell">
      <Sidebar
        activePage={page}
        onNavigate={setPage}
        user={user}
        onLogout={logout}
      />
      <div className="app-main">
        <Header page={page} />
        <main className="page-content">
          {renderPage(page, setPage)}
        </main>
      </div>
    </div>
  );
}
