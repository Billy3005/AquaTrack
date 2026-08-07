// Console shell: sidebar, topbar, routing, and the shared action dialog.
//
// The action dialog lives here rather than inside each screen because the same
// four actions are reachable from the user table, the user detail page, and
// (later) bulk selection — they must behave identically from all three.

import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { NavLink, Navigate, Route, Routes, useNavigate } from 'react-router-dom';
import { A } from './icons';
import { AD, AF, NUM } from './theme';
import { useAuth } from './lib/auth';
import { AAvatar, ABtn, APill, AToast, ASpinner, type ToastState } from './components/ui';
import { ActionModal, type ActionKind, type ActionTarget } from './components/ActionModal';
import { LoginScreen } from './pages/Login';
import { DashboardScreen } from './pages/Dashboard';
import { UsersScreen } from './pages/Users';
import { UserDetailScreen } from './pages/UserDetail';
import { AuditScreen } from './pages/Audit';
import { ComingSoonScreen, COMING_SOON } from './pages/ComingSoon';

interface ActionsValue {
  act: (kind: ActionKind, target: ActionTarget) => void;
  toast: (text: string, tone?: 'success' | 'error') => void;
  /** Bumped after every successful action so screens can refetch. */
  version: number;
}

const ActionsContext = createContext<ActionsValue | null>(null);

export function useActions(): ActionsValue {
  const ctx = useContext(ActionsContext);
  if (!ctx) throw new Error('useActions must be used inside the console shell');
  return ctx;
}

const NAV = [
  { key: 'dash', to: '/', label: 'Tổng quan', icon: A.grid, end: true },
  { key: 'users', to: '/users', label: 'Người dùng', icon: A.users },
  { key: 'gamify', to: '/gamification', label: 'Gamification', icon: A.trophy, soon: true },
  { key: 'content', to: '/content', label: 'Thử thách & nội dung', icon: A.doc, soon: true },
  { key: 'reports', to: '/reports', label: 'Báo cáo', icon: A.flag, soon: true },
  { key: 'notify', to: '/notifications', label: 'Thông báo đẩy', icon: A.bell, soon: true },
  { key: 'audit', to: '/audit', label: 'Nhật ký thao tác', icon: A.history },
  { key: 'settings', to: '/settings', label: 'Cài đặt & phân quyền', icon: A.gear, soon: true },
];

export function App() {
  const { profile, loading } = useAuth();

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: AD.bg, gap: 12, fontFamily: AF, color: AD.ink3 }}>
        <ASpinner /> Đang khôi phục phiên đăng nhập…
      </div>
    );
  }

  if (!profile) return <LoginScreen />;

  return <Console />;
}

function Console() {
  const { profile, signOut } = useAuth();
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);
  const [toastState, setToastState] = useState<ToastState>(null);
  const [modal, setModal] = useState<{ kind: ActionKind; target: ActionTarget } | null>(null);
  const [version, setVersion] = useState(0);
  const [search, setSearch] = useState('');

  const toast = useCallback((text: string, tone: 'success' | 'error' = 'success') => {
    setToastState({ text, tone });
    setTimeout(() => setToastState(null), 2800);
  }, []);

  const act = useCallback((kind: ActionKind, target: ActionTarget) => setModal({ kind, target }), []);

  const value = useMemo<ActionsValue>(() => ({ act, toast, version }), [act, toast, version]);

  const totalWidth = collapsed ? 76 : 248;

  return (
    <ActionsContext.Provider value={value}>
      <div style={{ display: 'flex', minHeight: '100vh', background: AD.bg, fontFamily: AF, color: AD.ink }}>
        {/* ── sidebar ── */}
        <aside
          style={{
            width: totalWidth,
            flexShrink: 0,
            background: `linear-gradient(180deg, ${AD.navy} 0%, ${AD.navy2} 100%)`,
            display: 'flex',
            flexDirection: 'column',
            position: 'sticky',
            top: 0,
            height: '100vh',
            transition: 'width .2s ease',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 11,
              padding: collapsed ? '22px 0' : '22px 20px',
              justifyContent: collapsed ? 'center' : 'flex-start',
            }}
          >
            <div
              style={{
                width: 34,
                height: 34,
                borderRadius: 10,
                background: 'linear-gradient(140deg,#38BDF8,#0284C7)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
                boxShadow: '0 4px 14px rgba(56,189,248,0.4)',
              }}
            >
              {A.drop('#fff', 18)}
            </div>
            {!collapsed && (
              <div>
                <div style={{ fontSize: 14.5, fontWeight: 750, color: '#fff', letterSpacing: '-0.01em' }}>Wafubi</div>
                <div style={{ fontSize: 10.5, color: '#6E93B4', fontWeight: 600, letterSpacing: '0.09em' }}>ADMIN CONSOLE</div>
              </div>
            )}
          </div>

          <nav style={{ display: 'flex', flexDirection: 'column', gap: 2, padding: '10px 12px', flex: 1 }}>
            {NAV.map((n) => (
              <NavLink key={n.key} to={n.to} end={n.end} style={{ textDecoration: 'none' }}>
                {({ isActive }) => (
                  <div
                    title={n.label}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 11,
                      padding: collapsed ? '11px 0' : '10px 12px',
                      justifyContent: collapsed ? 'center' : 'flex-start',
                      borderRadius: 10,
                      cursor: 'pointer',
                      fontFamily: AF,
                      fontSize: 13,
                      fontWeight: isActive ? 700 : 550,
                      background: isActive ? 'rgba(56,189,248,0.16)' : 'transparent',
                      color: isActive ? '#BAE6FD' : '#89A9C4',
                      position: 'relative',
                      transition: 'background .15s',
                    }}
                    onMouseEnter={(e) => {
                      if (!isActive) e.currentTarget.style.background = 'rgba(255,255,255,0.05)';
                    }}
                    onMouseLeave={(e) => {
                      if (!isActive) e.currentTarget.style.background = 'transparent';
                    }}
                  >
                    {isActive && <span style={{ position: 'absolute', left: -12, top: 9, bottom: 9, width: 3, borderRadius: '0 3px 3px 0', background: '#38BDF8' }} />}
                    {n.icon(isActive ? '#38BDF8' : '#7C9CB8', 18)}
                    {!collapsed && <span style={{ flex: 1 }}>{n.label}</span>}
                    {!collapsed && n.soon && (
                      <span
                        style={{
                          fontSize: 9.5,
                          fontWeight: 700,
                          padding: '2px 6px',
                          borderRadius: 999,
                          background: 'rgba(255,255,255,0.09)',
                          color: '#7C9CB8',
                          letterSpacing: '0.03em',
                        }}
                      >
                        SẮP CÓ
                      </span>
                    )}
                  </div>
                )}
              </NavLink>
            ))}
          </nav>

          {!collapsed && (
            <div style={{ margin: 12, padding: 14, borderRadius: 12, background: 'rgba(56,189,248,0.09)', border: '1px solid rgba(56,189,248,0.18)' }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: '#BAE6FD' }}>Đang xem dữ liệu thật</div>
              <div style={{ fontSize: 11, color: '#7C9CB8', marginTop: 5, lineHeight: 1.5 }}>
                Mọi số liệu được tính trực tiếp từ cơ sở dữ liệu, không có bộ nhớ đệm.
              </div>
            </div>
          )}

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              padding: collapsed ? '14px 0' : '14px 18px',
              borderTop: '1px solid rgba(255,255,255,0.07)',
              justifyContent: collapsed ? 'center' : 'flex-start',
            }}
          >
            <AAvatar name={profile!.name} size={30} hue={200} />
            {!collapsed && (
              <div style={{ minWidth: 0, flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 650, color: '#DCEBF7', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{profile!.name}</div>
                <div style={{ fontSize: 10.5, color: '#6E93B4' }}>{profile!.roleLabel}</div>
              </div>
            )}
          </div>
        </aside>

        {/* ── main ── */}
        <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
          <header
            style={{
              height: 60,
              flexShrink: 0,
              background: 'rgba(255,255,255,0.86)',
              backdropFilter: 'blur(10px)',
              borderBottom: `1px solid ${AD.border}`,
              display: 'flex',
              alignItems: 'center',
              gap: 14,
              padding: '0 28px',
              position: 'sticky',
              top: 0,
              zIndex: 30,
            }}
          >
            <button
              onClick={() => setCollapsed((c) => !c)}
              style={{ border: `1px solid ${AD.border}`, background: '#fff', borderRadius: 8, width: 32, height: 32, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            >
              {collapsed ? A.chevR(AD.ink2, 15) : A.chevL(AD.ink2, 15)}
            </button>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: 360, padding: '0 11px', height: 36, background: '#fff', border: `1px solid ${AD.borderStrong}`, borderRadius: 9 }}>
              {A.search(AD.ink3)}
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && search.trim()) {
                    navigate(`/users?q=${encodeURIComponent(search.trim())}`);
                    setSearch('');
                  }
                }}
                placeholder="Tìm nhanh người dùng theo tên, email hoặc ID…"
                style={{ flex: 1, minWidth: 0, border: 'none', outline: 'none', background: 'transparent', fontFamily: AF, fontSize: 13, color: AD.ink }}
              />
            </div>

            <div style={{ flex: 1 }} />
            <APill tone="green" dot>
              Dữ liệu thời gian thực
            </APill>
            <div style={{ width: 1, height: 24, background: AD.border }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
              <AAvatar name={profile!.name} size={30} hue={200} />
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 650 }}>{profile!.name}</div>
                <div style={{ fontSize: 10.5, color: AD.ink3, ...NUM }}>{profile!.roleLabel}</div>
              </div>
            </div>
            <ABtn size="sm" icon={A.logout(AD.ink2)} onClick={signOut}>
              Đăng xuất
            </ABtn>
          </header>

          <main style={{ flex: 1, padding: '26px 28px 44px' }}>
            <div style={{ maxWidth: 1240, margin: '0 auto' }}>
              <Routes>
                <Route path="/" element={<DashboardScreen />} />
                <Route path="/users" element={<UsersScreen />} />
                <Route path="/users/:userId" element={<UserDetailScreen />} />
                <Route path="/audit" element={<AuditScreen />} />
                {COMING_SOON.map((page) => (
                  <Route key={page.path} path={page.path} element={<ComingSoonScreen page={page} />} />
                ))}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </div>
          </main>
        </div>

        <ActionModal
          kind={modal?.kind ?? null}
          target={modal?.target ?? null}
          onClose={() => setModal(null)}
          onDone={(message, tone) => {
            toast(message, tone);
            setVersion((v) => v + 1);
          }}
        />
        <AToast toast={toastState} />
      </div>
    </ActionsContext.Provider>
  );
}
