// Tổng quan — every figure on this page is computed from intake_logs + users
// at request time. Nothing is mocked; where a number cannot be derived
// honestly (e.g. historical streak averages) the card shows no comparison.

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { A } from '../icons';
import { AD, NUM } from '../theme';
import { api } from '../lib/api';
import { useApi } from '../lib/useApi';
import { shortDay, vi, viDecimal } from '../lib/format';
import { ACard, ACardHead, ABtn, AAvatar, AEmpty, AError, APill, ASegment, ASpinner, AStat } from '../components/ui';
import { ABars, ADonut, AHeatmap, AHours, ALine, ASpark } from '../components/charts';

type Range = '7' | '30' | '90';

export function DashboardScreen() {
  const navigate = useNavigate();
  const [range, setRange] = useState<Range>('30');
  const { data, loading, error, reload } = useApi(() => api.overview(Number(range)), [range]);

  if (loading && !data) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, padding: 80, color: AD.ink3, fontSize: 13 }}>
        <ASpinner /> Đang tính toán số liệu…
      </div>
    );
  }
  if (error || !data) {
    return (
      <ACard>
        <AError onRetry={reload} message={error ?? undefined} />
      </ACard>
    );
  }

  const dau = data.dauSeries.map((p) => p.value);
  const dauPrev = data.dauSeriesPrev.map((p) => p.value);
  const labels = data.dauSeries.map((p) => shortDay(p.date));
  const peakHour = data.hourlyDistribution.indexOf(Math.max(...data.hourlyDistribution));
  const peakLevel = data.levelDistribution.reduce(
    (best, cur) => (cur.users > (best?.users ?? -1) ? cur : best),
    data.levelDistribution[0],
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 750, color: AD.ink, letterSpacing: '-0.025em' }}>Tổng quan</h1>
          <div style={{ fontSize: 13, color: AD.ink3, marginTop: 4, ...NUM }}>
            Cập nhật lúc{' '}
            {new Date(data.generatedAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} ·{' '}
            {new Date(data.generatedAt).toLocaleDateString('vi-VN')} · {vi(data.totalUsers)} tài khoản
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          {loading && <ASpinner size={15} />}
          <ASegment<Range>
            value={range}
            onChange={setRange}
            options={[
              { value: '7', label: '7 ngày' },
              { value: '30', label: '30 ngày' },
              { value: '90', label: '90 ngày' },
            ]}
          />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        <AStat
          label="Hoạt động hôm nay"
          value={vi(data.kpis.dau.value)}
          delta={data.kpis.dau.delta}
          deltaCaption={data.kpis.dau.deltaCaption}
          icon={A.users(AD.accent, 17)}
          spark={<ASpark data={dau.slice(-12)} />}
        />
        <AStat
          label="Hoàn thành mục tiêu"
          value={viDecimal(data.kpis.goalCompletionRate.value)}
          unit="%"
          delta={data.kpis.goalCompletionRate.delta}
          deltaCaption={data.kpis.goalCompletionRate.deltaCaption}
          tone="green"
          icon={A.drop(AD.green, 15)}
        />
        <AStat
          label="Streak trung bình"
          value={viDecimal(data.kpis.avgStreak.value)}
          unit="ngày"
          delta={data.kpis.avgStreak.delta}
          deltaCaption={data.kpis.avgStreak.deltaCaption}
          tone="amber"
          icon={A.flame(AD.amber, 15)}
        />
        <AStat
          label="Người dùng mới hôm nay"
          value={vi(data.kpis.newUsersToday.value)}
          delta={data.kpis.newUsersToday.delta}
          deltaCaption={data.kpis.newUsersToday.deltaCaption}
          tone="purple"
          icon={A.plus(AD.purple, 16)}
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16 }}>
        <ACard>
          <ACardHead
            title="Người dùng hoạt động theo ngày"
            sub={`Đường nét đứt là ${range} ngày liền trước`}
            right={
              <div style={{ display: 'flex', gap: 14, fontSize: 11.5, color: AD.ink3 }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ width: 14, height: 3, borderRadius: 2, background: AD.accent }} />
                  Kỳ này
                </span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ width: 14, height: 0, borderTop: `2px dashed ${AD.ink4}` }} />
                  Kỳ trước
                </span>
              </div>
            }
          />
          <ALine data={dau} compare={dauPrev} labels={labels} unit="người" />
        </ACard>

        <ACard>
          <ACardHead title="Tỉ lệ đạt mục tiêu" sub={`Trung bình ${range} ngày`} />
          <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 14px' }}>
            <ADonut
              pct={data.kpis.goalCompletionRate.value}
              sub={`≈ ${vi(data.goalBreakdown.avgUsersPerDay)} người/ngày có ghi nước`}
            />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 9, paddingTop: 14, borderTop: `1px solid ${AD.border}` }}>
            {(
              [
                ['Vượt mục tiêu (≥120%)', data.goalBreakdown.exceeded, AD.green],
                ['Đạt mục tiêu', data.goalBreakdown.met, AD.accent],
                ['Chưa đạt', data.goalBreakdown.missed, AD.ink4],
              ] as const
            ).map(([label, value, color]) => (
              <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 9, fontSize: 12.5 }}>
                <span style={{ width: 8, height: 8, borderRadius: 3, background: color }} />
                <span style={{ color: AD.ink2, flex: 1 }}>{label}</span>
                <span style={{ color: AD.ink, fontWeight: 700, ...NUM }}>{viDecimal(value)}%</span>
              </div>
            ))}
          </div>
        </ACard>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <ACard>
          <ACardHead
            title="Phân bổ level người dùng"
            sub={peakLevel ? `Đông nhất ở Lv ${peakLevel.level} — ${vi(peakLevel.users)} người` : 'Chưa có dữ liệu level'}
          />
          {data.levelDistribution.length ? (
            <ABars
              data={data.levelDistribution.map((d) => ({ label: String(d.level), value: d.users }))}
              highlight={peakLevel ? String(peakLevel.level) : undefined}
              labelFmt={(d) => `Lv${d.label}`}
              valueFmt={(v) => `${vi(v)} người`}
            />
          ) : (
            <AEmpty title="Chưa có người dùng nào" sub="Chạy scripts/seed_admin_demo.py để có dữ liệu mẫu." />
          )}
        </ACard>

        <ACard>
          <ACardHead
            title="Giờ uống nước phổ biến"
            sub="Tỉ lệ lượt ghi nước theo khung giờ"
            right={<APill tone="sky">{`Đỉnh ${peakHour}h`}</APill>}
          />
          <div style={{ paddingTop: 18 }}>
            <AHours data={data.hourlyDistribution} />
          </div>
        </ACard>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 380px', gap: 16 }}>
        <ACard>
          <ACardHead title="Giữ chân người dùng theo cohort" sub="% người dùng của tuần đăng ký còn ghi nước ở các tuần sau" />
          <AHeatmap cohorts={data.retentionCohorts} />
        </ACard>

        <ACard pad={0}>
          <div style={{ padding: '20px 20px 14px' }}>
            <ACardHead title="Nhật ký thao tác gần đây" sub="Mọi hành động nhạy cảm đều được ghi lại" />
          </div>
          <div style={{ maxHeight: 292, overflowY: 'auto' }}>
            {data.recentAudit.length === 0 && (
              <div style={{ padding: '34px 20px', textAlign: 'center', fontSize: 12.5, color: AD.ink4 }}>Chưa có thao tác nào được ghi lại</div>
            )}
            {data.recentAudit.map((entry) => (
              <div key={entry.id} style={{ display: 'flex', gap: 11, padding: '13px 20px', borderTop: `1px solid ${AD.border}` }}>
                <AAvatar name={entry.actorName} size={30} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, color: AD.ink, lineHeight: 1.45 }}>
                    <b style={{ fontWeight: 650 }}>{entry.actorName}</b> · <APill tone={entry.tone}>{entry.actionLabel}</APill>
                  </div>
                  <div style={{ fontSize: 11.5, color: AD.ink3, marginTop: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {entry.targetLabel}
                  </div>
                  <div style={{ fontSize: 11, color: AD.ink4, marginTop: 3, ...NUM }}>
                    {entry.createdAtLabel} · {entry.reason}
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div style={{ padding: '12px 20px', borderTop: `1px solid ${AD.border}` }}>
            <ABtn size="sm" full onClick={() => navigate('/audit')}>
              Xem toàn bộ nhật ký
            </ABtn>
          </div>
        </ACard>
      </div>
    </div>
  );
}
