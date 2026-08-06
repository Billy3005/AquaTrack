// Chi tiết người dùng — the page a support agent opens when someone complains.
// Four tabs, all backed by real rows: hydration, gamification state, and the
// audit trail for this specific account.

import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { A } from '../icons';
import { AD, AF, NUM } from '../theme';
import { api } from '../lib/api';
import { useApi } from '../lib/useApi';
import { LIQUID_LABELS, SOURCE_LABELS, vi, viDate, viDateTime } from '../lib/format';
import { useAuth } from '../lib/auth';
import { useActions } from '../App';
import { ACard, ACardHead, ABtn, AAvatar, AEmpty, AError, APill, ASpinner, AStatusPill } from '../components/ui';
import { ABars } from '../components/charts';
import type { UserDetail as UserDetailData } from '../types';

type Tab = 'overview' | 'history' | 'gamify' | 'audit';

export function UserDetailScreen() {
  const { userId = '' } = useParams();
  const navigate = useNavigate();
  const { can } = useAuth();
  const { act, version } = useActions();
  const [tab, setTab] = useState<Tab>('overview');

  const { data: u, loading, error, reload } = useApi(() => api.user(userId), [userId, version]);

  if (loading && !u) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, padding: 80, color: AD.ink3, fontSize: 13 }}>
        <ASpinner /> Đang tải hồ sơ…
      </div>
    );
  }
  if (error || !u) {
    return (
      <ACard>
        <AError onRetry={reload} message={error ?? undefined} />
        <div style={{ textAlign: 'center', paddingBottom: 12 }}>
          <ABtn onClick={() => navigate('/users')}>Quay lại danh sách</ABtn>
        </div>
      </ACard>
    );
  }

  const target = { id: u.id, name: u.name };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5, color: AD.ink3 }}>
        <Link to="/users" style={{ color: AD.ink3, textDecoration: 'none', fontFamily: AF }}>
          Người dùng
        </Link>
        {A.chevR(AD.ink4, 12)}
        <span style={{ color: AD.ink2, fontWeight: 600 }}>{u.name}</span>
      </div>

      {/* profile header */}
      <ACard pad={22}>
        <div style={{ display: 'flex', gap: 18, alignItems: 'flex-start' }}>
          <AAvatar name={u.name} size={64} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
              <div style={{ fontSize: 19, fontWeight: 750, color: AD.ink, letterSpacing: '-0.02em' }}>{u.name}</div>
              <AStatusPill status={u.status} />
              {u.role !== 'user' && <APill tone="purple">{u.role.replace('_', ' ')}</APill>}
              {!u.isVerified && <APill tone="amber">Chưa xác minh email</APill>}
              <APill tone="slate">{u.authProvider === 'google' ? 'Đăng nhập Google' : 'Đăng nhập mật khẩu'}</APill>
            </div>
            <div style={{ fontSize: 13, color: AD.ink3, marginTop: 5, ...NUM }}>
              {u.email} · {u.id} · Tham gia {viDate(u.joinedAt)} · Hoạt động cuối {u.lastActiveLabel}
            </div>
            <div style={{ display: 'flex', gap: 22, marginTop: 16, flexWrap: 'wrap' }}>
              {(
                [
                  ['Level', String(u.level), u.rank],
                  ['XP tích luỹ', vi(u.xp), `còn ${vi(u.xpToNextLevel)} XP đến Lv ${u.level + 1}`],
                  ['Streak', `${u.streak} ngày`, `dài nhất: ${u.longestStreak}`],
                  ['Xu', vi(u.coins), `${vi(u.totalLogs)} lượt ghi nước`],
                  ['TB 7 ngày', `${vi(u.avgMl)} ml`, `${u.goalPercent}% mục tiêu ${vi(u.goalMl)} ml`],
                ] as const
              ).map(([label, value, sub]) => (
                <div key={label}>
                  <div style={{ fontSize: 11, color: AD.ink3, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{label}</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: AD.ink, marginTop: 4, ...NUM }}>{value}</div>
                  <div style={{ fontSize: 11, color: AD.ink4, marginTop: 2 }}>{sub}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: 190, flexShrink: 0 }}>
            <ABtn
              kind="primary"
              full
              icon={A.coin('#fff')}
              disabled={!can('user.grant')}
              title={can('user.grant') ? undefined : 'Vai trò của bạn không được phép tặng xu / XP'}
              onClick={() => act('grant', target)}
            >
              Tặng xu / XP
            </ABtn>
            <ABtn
              full
              icon={A.lock(AD.ink3)}
              disabled={!can('user.password_reset')}
              title={
                can('user.password_reset')
                  ? 'Sinh mã 6 số để đọc cho người dùng qua kênh hỗ trợ'
                  : 'Vai trò của bạn không được phép cấp mã đặt lại mật khẩu'
              }
              onClick={() => act('passwordReset', target)}
            >
              Cấp mã đặt lại mật khẩu
            </ABtn>
            <div style={{ display: 'flex', gap: 8 }}>
              <ABtn
                kind="danger"
                full
                icon={A.reset(AD.red)}
                disabled={!can('user.reset')}
                title={can('user.reset') ? undefined : 'Chỉ super admin mới được reset dữ liệu'}
                onClick={() => act('reset', target)}
              >
                Reset
              </ABtn>
              <ABtn
                kind="danger"
                full
                icon={u.status === 'locked' ? A.unlock(AD.red) : A.lock(AD.red)}
                disabled={!can('user.lock')}
                title={can('user.lock') ? undefined : 'Vai trò của bạn không được phép khoá tài khoản'}
                onClick={() => act(u.status === 'locked' ? 'unlock' : 'lock', target)}
              >
                {u.status === 'locked' ? 'Mở khoá' : 'Khoá'}
              </ABtn>
            </div>
          </div>
        </div>
      </ACard>

      {/* tabs */}
      <div style={{ display: 'flex', gap: 4, borderBottom: `1px solid ${AD.border}` }}>
        {(
          [
            ['overview', 'Tổng quan'],
            ['history', `Lịch sử uống nước (${u.recentLogs.length})`],
            ['gamify', 'Gamification'],
            ['audit', `Nhật ký thao tác (${u.audit.length})`],
          ] as const
        ).map(([key, label]) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            style={{
              padding: '10px 15px',
              border: 'none',
              background: 'transparent',
              cursor: 'pointer',
              fontFamily: AF,
              fontSize: 13,
              fontWeight: 650,
              color: tab === key ? AD.accentDeep : AD.ink3,
              borderBottom: `2px solid ${tab === key ? AD.accent : 'transparent'}`,
              marginBottom: -1,
            }}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <OverviewTab u={u} />}
      {tab === 'history' && <HistoryTab u={u} />}
      {tab === 'gamify' && <GamifyTab u={u} />}
      {tab === 'audit' && <AuditTab u={u} />}
    </div>
  );
}

function OverviewTab({ u }: { u: UserDetailData }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16 }}>
      <ACard>
        <ACardHead
          title="Lượng nước 7 ngày gần nhất"
          sub={`Mục tiêu ${vi(u.goalMl)} ml/ngày`}
          right={<APill tone={u.goalPercent >= 100 ? 'green' : u.goalPercent >= 70 ? 'sky' : 'amber'}>{u.goalPercent}% mục tiêu</APill>}
        />
        <ABars
          data={u.weekly.map((d) => ({ label: d.label, value: d.ml }))}
          height={150}
          valueFmt={(v) => `${vi(v)} ml`}
        />
      </ACard>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <ACard>
          <ACardHead title="Tiến độ level" />
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8, ...NUM }}>
            <span style={{ fontSize: 12.5, color: AD.ink2, fontWeight: 600 }}>
              Lv {u.level} → {u.level + 1}
            </span>
            <span style={{ fontSize: 12, color: AD.ink3 }}>
              {vi(u.xpIntoLevel)} / {vi(u.xpForNextLevel)} XP
            </span>
          </div>
          <div style={{ height: 9, background: '#EDF3F9', borderRadius: 5, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${Math.min(100, u.levelProgress)}%`, background: `linear-gradient(90deg,${AD.accent},#38BDF8)`, borderRadius: 5 }} />
          </div>
          <div style={{ fontSize: 11.5, color: AD.ink3, marginTop: 10 }}>
            Danh hiệu hiện tại: <b style={{ color: AD.ink2 }}>{u.rank}</b>
          </div>
        </ACard>

        <ACard>
          <ACardHead title="Cờ theo dõi" sub="Chỉ hiển thị điều rút ra được từ dữ liệu thật" />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {u.flags.map((f, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9, fontSize: 12.5, color: AD.ink2 }}>
                <APill tone={f.tone} dot>
                  {f.label}
                </APill>
                {f.text}
              </div>
            ))}
          </div>
        </ACard>
      </div>
    </div>
  );
}

function HistoryTab({ u }: { u: UserDetailData }) {
  if (!u.recentLogs.length) {
    return (
      <ACard>
        <AEmpty title="Chưa có lượt ghi nước nào" sub="Người dùng này chưa từng ghi nhận uống nước, hoặc dữ liệu đã bị reset." />
      </ACard>
    );
  }
  return (
    <ACard pad={0}>
      <div style={{ padding: '18px 22px 14px' }}>
        <ACardHead title="Lịch sử ghi nước" sub={`${u.recentLogs.length} lượt gần nhất · tổng ${vi(u.totalVolumeMl)} ml từ trước tới nay`} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 0.8fr 0.8fr 1fr', gap: 14, padding: '10px 22px', background: AD.panelAlt, borderTop: `1px solid ${AD.border}` }}>
        {['Thời điểm', 'Thể tích', 'Hiệu dụng', 'Loại · nguồn'].map((h) => (
          <div key={h} style={{ fontSize: 11, fontWeight: 700, color: AD.ink3, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            {h}
          </div>
        ))}
      </div>
      {u.recentLogs.map((log) => (
        <div key={log.id} style={{ display: 'grid', gridTemplateColumns: '1.4fr 0.8fr 0.8fr 1fr', gap: 14, padding: '13px 22px', borderTop: `1px solid ${AD.border}`, alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9, fontSize: 13, color: AD.ink2, ...NUM }}>
            {A.clock(AD.ink4)}
            {viDateTime(log.loggedAt)}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 13.5, fontWeight: 700, color: AD.ink, ...NUM }}>
            {A.drop(AD.accent, 14)}
            {vi(log.volumeMl)} ml
          </div>
          <div style={{ fontSize: 13, color: AD.ink3, ...NUM }}>{vi(log.effectiveMl)} ml</div>
          <div style={{ fontSize: 12.5, color: AD.ink3 }}>
            {LIQUID_LABELS[log.liquidType] ?? log.liquidType} · {SOURCE_LABELS[log.source] ?? log.source}
          </div>
        </div>
      ))}
    </ACard>
  );
}

function GamifyTab({ u }: { u: UserDetailData }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
      <ACard>
        <ACardHead title="Thành tích & hoạt động" sub="Số liệu lấy trực tiếp từ bảng achievements và scan_history" />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {(
            [
              ['Huy hiệu đã đạt', vi(u.achievementsCount), A.trophy(AD.amber, 16)],
              ['Lượt Smart Scan', vi(u.scansCount), A.drop(AD.accent, 15)],
              ['Tổng lượt ghi nước', vi(u.totalLogs), A.clock(AD.ink3, 15)],
              ['Tổng thể tích', `${vi(u.totalVolumeMl)} ml`, A.drop(AD.green, 15)],
            ] as const
          ).map(([label, value, icon]) => (
            <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '12px 14px', border: `1px solid ${AD.border}`, borderRadius: 11 }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: AD.panelAlt, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
              <div style={{ flex: 1, fontSize: 13, color: AD.ink2, fontWeight: 600 }}>{label}</div>
              <div style={{ fontSize: 15, fontWeight: 750, color: AD.ink, ...NUM }}>{value}</div>
            </div>
          ))}
        </div>
      </ACard>

      <ACard>
        <ACardHead title="Ví & streak" />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {(
            [
              ['Số xu hiện có', vi(u.coins)],
              ['Streak hiện tại', `${u.streak} ngày`],
              ['Streak dài nhất', `${u.longestStreak} ngày`],
              ['Múi giờ', u.timezone],
              ['Đăng nhập lần cuối', viDateTime(u.lastLoginAt)],
            ] as const
          ).map(([label, value]) => (
            <div key={label} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 13, paddingBottom: 10, borderBottom: `1px solid ${AD.border}` }}>
              <span style={{ color: AD.ink3 }}>{label}</span>
              <span style={{ color: AD.ink, fontWeight: 650, ...NUM }}>{value}</span>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 14, padding: '11px 13px', background: AD.accentTint, borderRadius: 10, fontSize: 12, color: AD.accentDeep, lineHeight: 1.5 }}>
          Danh sách huy hiệu chi tiết và cấu hình level sẽ nằm ở mục Gamification — hiện chưa triển khai.
        </div>
      </ACard>
    </div>
  );
}

function AuditTab({ u }: { u: UserDetailData }) {
  if (!u.audit.length) {
    return (
      <ACard>
        <AEmpty
          icon={A.history(AD.accent, 24)}
          title="Chưa có thao tác nào trên tài khoản này"
          sub="Mọi lần khoá, mở khoá, reset hoặc tặng thưởng sẽ xuất hiện ở đây kèm người thực hiện và lý do."
        />
      </ACard>
    );
  }
  return (
    <ACard pad={0}>
      <div style={{ padding: '18px 22px 14px' }}>
        <ACardHead title="Nhật ký thao tác trên tài khoản này" sub="Bản ghi chỉ thêm mới, không sửa và không xoá" />
      </div>
      {u.audit.map((entry) => (
        <div key={entry.id} style={{ display: 'flex', gap: 12, padding: '14px 22px', borderTop: `1px solid ${AD.border}`, alignItems: 'center' }}>
          <AAvatar name={entry.actorName} size={30} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, color: AD.ink }}>
              <b style={{ fontWeight: 650 }}>{entry.actorName}</b> <span style={{ color: AD.ink3, fontSize: 11.5 }}>· {entry.actorRoleLabel}</span>
            </div>
            <div style={{ fontSize: 11.5, color: AD.ink3, marginTop: 3 }}>{entry.reason}</div>
          </div>
          <APill tone={entry.tone}>{entry.actionLabel}</APill>
          <div style={{ fontSize: 11.5, color: AD.ink4, width: 110, textAlign: 'right', ...NUM }}>{viDateTime(entry.createdAt)}</div>
        </div>
      ))}
    </ACard>
  );
}
