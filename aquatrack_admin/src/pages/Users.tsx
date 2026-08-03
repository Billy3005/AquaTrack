// Người dùng — the console's main working surface.
//
// Search / status / level filters and pagination all run server-side, so the
// table behaves the same at 40 users and at 40,000. Row actions are gated by
// the caller's capabilities: a control the API would refuse is disabled and
// explains itself on hover, rather than failing after the fact.

import { useEffect, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { A } from '../icons';
import { AD, NUM } from '../theme';
import { api } from '../lib/api';
import { useApi, useDebounced } from '../lib/useApi';
import { vi } from '../lib/format';
import { useAuth } from '../lib/auth';
import { useActions } from '../App';
import {
  ACard,
  ABtn,
  AAvatar,
  AEmpty,
  AError,
  AField,
  AMenuItem,
  APager,
  ASelect,
  ASkeletonRows,
  ASpinner,
  AStatusPill,
} from '../components/ui';
import type { UserRow } from '../types';

const COLS = '2.3fr 0.9fr 0.8fr 1fr 0.9fr 1fr 34px';
const PAGE_SIZE = 10;

type StatusFilter = 'all' | 'active' | 'inactive' | 'locked';
type LevelFilter = 'all' | 'low' | 'mid' | 'high';

export function UsersScreen() {
  const navigate = useNavigate();
  const { can } = useAuth();
  const { act, toast, version } = useActions();
  const [params, setParams] = useSearchParams();

  // The topbar quick-search navigates here with ?q=..., so the URL is the
  // source of truth for the query and the screen stays linkable.
  const [q, setQ] = useState(params.get('q') ?? '');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [level, setLevel] = useState<LevelFilter>('all');
  const [page, setPage] = useState(1);
  const [menu, setMenu] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const debouncedQ = useDebounced(q);

  useEffect(() => {
    const fromUrl = params.get('q') ?? '';
    if (fromUrl !== q) setQ(fromUrl);
    // Only react to URL changes coming from outside this screen.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params]);

  useEffect(() => {
    setPage(1);
  }, [debouncedQ, status, level]);

  const { data, loading, stale, error, reload } = useApi(
    () => api.users({ q: debouncedQ, status, level, page, page_size: PAGE_SIZE }),
    [debouncedQ, status, level, page, version],
  );

  // While a new filter is loading the visible rows still belong to the old one.
  // Close any open row menu and block actions until the replacement lands.
  useEffect(() => {
    if (stale) setMenu(null);
  }, [stale]);

  // Close the row menu on any outside click.
  const rootRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!menu) return;
    const close = () => setMenu(null);
    window.addEventListener('click', close);
    return () => window.removeEventListener('click', close);
  }, [menu]);

  const summary = data?.summary;

  const exportCsv = async () => {
    setExporting(true);
    try {
      await api.exportUsers();
      toast('Đã tải file CSV · ghi vào nhật ký thao tác');
    } catch (err) {
      toast(err instanceof Error ? err.message : 'Xuất CSV thất bại', 'error');
    } finally {
      setExporting(false);
    }
  };

  return (
    <div ref={rootRef} style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 750, color: AD.ink, letterSpacing: '-0.025em' }}>Người dùng</h1>
          <div style={{ fontSize: 13, color: AD.ink3, marginTop: 4, ...NUM }}>
            {summary
              ? `${vi(summary.totalUsers)} tài khoản · ${vi(summary.activeToday)} hoạt động hôm nay · ${vi(summary.lockedUsers)} bị khoá`
              : 'Đang tải…'}
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <ABtn
            icon={A.down(AD.ink2)}
            onClick={exportCsv}
            disabled={!can('data.export') || exporting}
            title={can('data.export') ? undefined : 'Vai trò của bạn không được phép xuất dữ liệu'}
          >
            {exporting ? 'Đang xuất…' : 'Xuất CSV'}
          </ABtn>
        </div>
      </div>

      <ACard pad={0}>
        {/* filter bar */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 22px', flexWrap: 'wrap' }}>
          <AField
            icon={A.search(AD.ink3)}
            placeholder="Tìm theo tên, email hoặc ID…"
            value={q}
            onChange={(v) => {
              setQ(v);
              if (params.get('q')) setParams({}, { replace: true });
            }}
            width={280}
          />
          <ASelect<StatusFilter>
            value={status}
            onChange={setStatus}
            width={160}
            options={[
              { value: 'all', label: 'Mọi trạng thái' },
              { value: 'active', label: 'Đang hoạt động' },
              { value: 'inactive', label: 'Không hoạt động' },
              { value: 'locked', label: 'Đã khoá' },
            ]}
          />
          <ASelect<LevelFilter>
            value={level}
            onChange={setLevel}
            width={140}
            options={[
              { value: 'all', label: 'Mọi level' },
              { value: 'low', label: 'Lv 1–4' },
              { value: 'mid', label: 'Lv 5–8' },
              { value: 'high', label: 'Lv 9+' },
            ]}
          />
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5, color: AD.ink3, ...NUM }}>
            {stale && <ASpinner size={13} />}
            {stale ? 'Đang lọc lại…' : data ? `${vi(data.total)} kết quả` : '—'}
          </div>
        </div>

        {/* header */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: COLS,
            gap: 14,
            padding: '10px 22px',
            background: AD.panelAlt,
            borderTop: `1px solid ${AD.border}`,
            borderBottom: `1px solid ${AD.border}`,
          }}
        >
          {['Người dùng', 'Level', 'Streak', 'TB/ngày (7 ngày)', 'Trạng thái', 'Hoạt động cuối', ''].map((h, i) => (
            <div key={i} style={{ fontSize: 11, fontWeight: 700, color: AD.ink3, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              {h}
            </div>
          ))}
        </div>

        {loading && !data && <ASkeletonRows rows={PAGE_SIZE} cols={COLS} />}
        {error && <AError onRetry={reload} message={error} />}
        {data && data.items.length === 0 && (
          <AEmpty
            icon={A.search(AD.accent, 24)}
            title="Không tìm thấy người dùng nào"
            sub="Thử bỏ bớt bộ lọc hoặc kiểm tra lại từ khoá tìm kiếm."
            action={
              <ABtn
                kind="soft"
                onClick={() => {
                  setQ('');
                  setStatus('all');
                  setLevel('all');
                }}
              >
                Xoá bộ lọc
              </ABtn>
            }
          />
        )}

        <div style={{ opacity: stale ? 0.45 : 1, transition: 'opacity .15s', pointerEvents: stale ? 'none' : 'auto' }}>
          {data?.items.map((u) => (
            <UserRowView
              key={u.id}
              user={u}
              open={menu === u.id}
              onToggleMenu={() => setMenu(menu === u.id ? null : u.id)}
              onOpen={() => navigate(`/users/${u.id}`)}
              onAct={act}
              can={can}
            />
          ))}
        </div>

        {data && data.items.length > 0 && (
          <APager page={data.page} pages={data.pages} total={data.total} pageSize={data.pageSize} onPage={setPage} />
        )}
      </ACard>
    </div>
  );
}

function UserRowView({
  user,
  open,
  onToggleMenu,
  onOpen,
  onAct,
  can,
}: {
  user: UserRow;
  open: boolean;
  onToggleMenu: () => void;
  onOpen: () => void;
  onAct: ReturnType<typeof useActions>['act'];
  can: ReturnType<typeof useAuth>['can'];
}) {
  const target = { id: user.id, name: user.name };
  const pct = user.goalMl ? Math.min(100, (user.avgMl / user.goalMl) * 100) : 0;
  const barColor = user.avgMl >= user.goalMl ? AD.green : pct > 70 ? AD.accent : AD.amber;

  return (
    <div
      onClick={onOpen}
      style={{
        display: 'grid',
        gridTemplateColumns: COLS,
        gap: 14,
        padding: '13px 22px',
        borderBottom: `1px solid ${AD.border}`,
        alignItems: 'center',
        cursor: 'pointer',
        position: 'relative',
      }}
      onMouseEnter={(e) => (e.currentTarget.style.background = AD.panelAlt)}
      onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
        <AAvatar name={user.name} />
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 13.5, fontWeight: 650, color: AD.ink, display: 'flex', alignItems: 'center', gap: 7 }}>
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user.name}</span>
            {user.role !== 'user' && (
              <span
                style={{
                  fontSize: 9.5,
                  fontWeight: 750,
                  color: '#B45309',
                  background: 'linear-gradient(135deg,#FDE68A,#FCD34D)',
                  padding: '1.5px 5px',
                  borderRadius: 4,
                  letterSpacing: '0.04em',
                  textTransform: 'uppercase',
                }}
              >
                {user.role.replace('_', ' ')}
              </span>
            )}
          </div>
          <div style={{ fontSize: 11.5, color: AD.ink3, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {user.email}
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
        <span
          style={{
            width: 24,
            height: 24,
            borderRadius: 7,
            background: `linear-gradient(140deg,${AD.accent},${AD.accentDeep})`,
            color: '#fff',
            fontSize: 11,
            fontWeight: 750,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            ...NUM,
          }}
        >
          {user.level}
        </span>
        <span style={{ fontSize: 11.5, color: AD.ink3, ...NUM }}>{vi(user.xp)} XP</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 13, color: user.streak > 0 ? AD.ink : AD.ink4, fontWeight: 600, ...NUM }}>
        {user.streak > 0 && A.flame('#F59E0B', 13)}
        {user.streak} ngày
      </div>

      <div style={{ ...NUM }}>
        <div style={{ fontSize: 13, color: AD.ink, fontWeight: 600 }}>{vi(user.avgMl)} ml</div>
        <div style={{ height: 4, borderRadius: 2, background: '#EDF3F9', marginTop: 5, overflow: 'hidden' }}>
          <div style={{ height: '100%', width: `${pct}%`, background: barColor, borderRadius: 2 }} />
        </div>
      </div>

      <div>
        <AStatusPill status={user.status} />
      </div>

      <div style={{ fontSize: 12.5, color: AD.ink2, ...NUM }}>{user.lastActiveLabel}</div>

      <div
        onClick={(e) => {
          e.stopPropagation();
          onToggleMenu();
        }}
        style={{ display: 'flex', justifyContent: 'flex-end', position: 'relative' }}
      >
        <button style={{ border: 'none', background: 'transparent', cursor: 'pointer', padding: 4, borderRadius: 6, display: 'flex' }}>{A.dots(AD.ink3)}</button>
        {open && (
          <div
            style={{
              position: 'absolute',
              right: 0,
              top: 30,
              zIndex: 20,
              width: 224,
              background: '#fff',
              border: `1px solid ${AD.border}`,
              borderRadius: 11,
              boxShadow: AD.shadowUp,
              padding: 5,
              animation: 'ad-pop .16s ease-out',
            }}
          >
            <AMenuItem icon={A.users(AD.ink2, 15)} label="Xem hồ sơ chi tiết" onClick={onOpen} />
            <AMenuItem
              icon={A.coin(AD.ink2)}
              label="Tặng xu / XP thủ công"
              disabled={!can('user.grant')}
              onClick={() => onAct('grant', target)}
            />
            <div style={{ height: 1, background: AD.border, margin: '5px 0' }} />
            <AMenuItem
              icon={A.reset(AD.red)}
              label="Reset dữ liệu uống nước"
              danger
              disabled={!can('user.reset')}
              onClick={() => onAct('reset', target)}
            />
            <AMenuItem
              icon={user.status === 'locked' ? A.unlock(AD.red) : A.lock(AD.red)}
              label={user.status === 'locked' ? 'Mở khoá tài khoản' : 'Khoá tài khoản'}
              danger
              disabled={!can('user.lock')}
              onClick={() => onAct(user.status === 'locked' ? 'unlock' : 'lock', target)}
            />
          </div>
        )}
      </div>
    </div>
  );
}
