// StatsScreen — wave chart + AI insights
function StatsScreen({ onNavigate }) {
  const [period, setPeriod] = React.useState('week');

  // Daily fills for the week (% of goal)
  const week = [
    { d: 'T2', pct: 102 }, { d: 'T3', pct: 88 },
    { d: 'T4', pct: 100 }, { d: 'T5', pct: 92 },
    { d: 'T6', pct: 67 }, { d: 'T7', pct: 80 }, { d: 'CN', pct: 78 },
  ];

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{ padding: '54px 20px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              Lịch sử hydration
            </div>
            <div style={{ fontSize: 26, fontWeight: 600, color: 'white', letterSpacing: '-0.02em', marginTop: 2 }}>
              Tuần này
            </div>
          </div>
          {/* Period toggle */}
          <div style={{
            display: 'flex', background: COLORS.nightCard, borderRadius: 999,
            padding: 3, fontFamily: FONT_TEXT, fontSize: 11.5, fontWeight: 600,
          }}>
            {['week', 'month'].map((p) => (
              <button key={p} onClick={() => setPeriod(p)} style={{
                background: period === p ? COLORS.glow : 'transparent',
                color: period === p ? '#082F49' : COLORS.textSecondary,
                border: 'none', borderRadius: 999, padding: '5px 14px',
                cursor: 'pointer', fontFamily: 'inherit', fontWeight: 600, fontSize: 11.5,
              }}>{p === 'week' ? 'Tuần' : 'Tháng'}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 20px' }}>
        {/* Wave chart */}
        <div style={{
          background: 'linear-gradient(180deg, #0C2A4A, #0B1933)',
          border: '1px solid rgba(56,189,248,0.18)',
          borderRadius: 18,
          padding: 16,
          marginBottom: 16,
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8,
          }}>
            <div>
              <div style={{ fontSize: 28, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em' }}>
                14.7L
              </div>
              <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT }}>tổng tuần · +1.2L vs tuần trước</div>
            </div>
            <div style={{
              fontSize: 11, color: '#86EFAC', fontFamily: FONT_ROUND, fontWeight: 600,
              background: 'rgba(16,185,129,0.15)', padding: '4px 10px', borderRadius: 999,
              border: '1px solid rgba(16,185,129,0.3)',
            }}>+8.9%</div>
          </div>

          <WaveChart days={week} />

          {/* Day labels */}
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
            marginTop: 6, fontSize: 10.5, color: COLORS.textSecondary,
            fontFamily: FONT_TEXT, textAlign: 'center', fontWeight: 500,
          }}>
            {week.map((d, i) => (
              <div key={i} style={{
                color: d.pct >= 100 ? '#86EFAC' : d.pct < 80 ? '#FCA5A5' : COLORS.textSecondary,
              }}>
                <div style={{ fontSize: 10, opacity: 0.7 }}>{d.d}</div>
                <div style={{ fontSize: 11, fontWeight: 600, fontFamily: FONT_ROUND, marginTop: 2 }}>{d.pct}%</div>
              </div>
            ))}
          </div>
        </div>

        {/* Metric row */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 18 }}>
          <Metric value="84%" label="goal met" accent="#38BDF8" />
          <Metric value="12" label="day streak" accent="#F97316" suffix="🔥" />
          <Metric value="14.7L" label="this week" accent="#A78BFA" />
        </div>

        {/* AI Insights */}
        <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, marginBottom: 10, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 6 }}>
          {I.spark('#38BDF8', 14)} AI Insights
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Insight
            color="#38BDF8"
            tag="hydration"
            title="Buổi chiều là điểm yếu của bạn"
            body="Bạn thường uống ít nhất vào khoảng 14–17h. Đặt nhắc nhở vào 15h sẽ giúp tăng 18% goal."
          />
          <Insight
            color="#818CF8"
            tag="pattern"
            title="Thứ Hai & Thứ Tư đạt 100%"
            body="Thứ Sáu chỉ đạt 67% — có thể do lịch họp dày. Đặt mục tiêu thấp hơn ngày bận?"
          />
          <Insight
            color="#F59E0B"
            tag="weather"
            title="Hôm nay nóng — goal đã tăng"
            body="Nhiệt độ 34°C đã tự động tăng goal lên 2,800ml. Bạn đã uống được 1,450ml."
          />
        </div>
      </div>

      <BottomTabBar active="stats" onNavigate={onNavigate} />
    </div>
  );
}

function WaveChart({ days }) {
  // 7 points across the chart, value scaled to height
  const W = 320, H = 120, P = 8;
  const xs = days.map((_, i) => P + i * ((W - 2 * P) / (days.length - 1)));
  const ys = days.map((d) => {
    const v = Math.min(120, d.pct);
    return H - 8 - (v / 120) * (H - 18);
  });

  // smooth path
  const path = xs.reduce((acc, x, i) => {
    if (i === 0) return `M${x},${ys[i]}`;
    const px = xs[i - 1], py = ys[i - 1];
    const cx1 = px + (x - px) / 2, cx2 = px + (x - px) / 2;
    return acc + ` C${cx1},${py} ${cx2},${ys[i]} ${x},${ys[i]}`;
  }, '');
  const fillPath = path + ` L${xs[xs.length - 1]},${H} L${xs[0]},${H} Z`;

  const goalY = H - 8 - (100 / 120) * (H - 18);

  return (
    <svg width="100%" height={H} viewBox={`0 0 ${W} ${H}`} style={{ display: 'block' }}>
      <defs>
        <linearGradient id="waveFill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#0EA5E9" stopOpacity="0.5"/>
          <stop offset="100%" stopColor="#0C3A5E" stopOpacity="0.1"/>
        </linearGradient>
      </defs>

      {/* Goal dashed line */}
      <line x1={P} y1={goalY} x2={W - P} y2={goalY} stroke="rgba(56,189,248,0.45)" strokeWidth="1" strokeDasharray="4 4"/>
      <text x={W - P} y={goalY - 4} textAnchor="end" fontSize="9" fill="rgba(56,189,248,0.7)" fontFamily="-apple-system">Goal 100%</text>

      {/* fill */}
      <path d={fillPath} fill="url(#waveFill)" />
      {/* stroke */}
      <path d={path} fill="none" stroke="#38BDF8" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>

      {/* points */}
      {xs.map((x, i) => {
        const ok = days[i].pct >= 100;
        return (
          <g key={i}>
            <circle cx={x} cy={ys[i]} r="5" fill={ok ? '#38BDF8' : '#F87171'} opacity="0.25"/>
            <circle cx={x} cy={ys[i]} r="2.8" fill={ok ? '#38BDF8' : '#F87171'} stroke={COLORS.nightBase} strokeWidth="1.2"/>
          </g>
        );
      })}
    </svg>
  );
}

function Metric({ value, label, accent, suffix }) {
  return (
    <div style={{
      background: COLORS.nightCard,
      borderRadius: 12, padding: '12px 10px',
      textAlign: 'center',
    }}>
      <div style={{
        fontSize: 19, fontWeight: 700, color: 'white',
        fontFamily: FONT_ROUND, letterSpacing: '-0.02em',
      }}>{value}{suffix && <span style={{ marginLeft: 4 }}>{suffix}</span>}</div>
      <div style={{ fontSize: 10, color: COLORS.textSecondary, marginTop: 2, fontFamily: FONT_TEXT, letterSpacing: '0.04em' }}>{label}</div>
    </div>
  );
}

function Insight({ color, tag, title, body }) {
  return (
    <div style={{
      background: COLORS.nightSurface,
      borderRadius: 14, padding: '12px 14px',
      borderLeft: `2px solid ${color}`,
      border: `1px solid ${color}22`,
      borderLeftWidth: 3,
    }}>
      <div style={{
        fontSize: 9.5, color, fontFamily: FONT_TEXT, fontWeight: 600,
        letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 4,
      }}>{tag}</div>
      <div style={{ fontSize: 13.5, fontWeight: 600, color: COLORS.textPrimary, marginBottom: 4, fontFamily: FONT_TEXT, letterSpacing: '-0.01em' }}>{title}</div>
      <div style={{ fontSize: 12, color: COLORS.textSecondary, lineHeight: 1.4, fontFamily: FONT_TEXT }}>{body}</div>
    </div>
  );
}

window.StatsScreen = StatsScreen;
