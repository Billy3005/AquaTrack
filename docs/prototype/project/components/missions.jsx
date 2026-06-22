// MissionsScreen — Daily & Weekly missions / quests
// Two tabs: Hằng ngày (daily) and Hằng tuần (weekly)
// Each mission card has: icon, title, sub, progress, reward (XP / unlock), claim button when done

function MissionsScreen({ onNavigate, initialTab = 'daily' }) {
  const [tab, setTab] = React.useState(initialTab);

  // Today's missions
  const daily = [
    {
      id: 'd1',
      icon: '🌅',
      glow: '#FBBF24',
      name: 'Khởi đầu tươi mới',
      sub: 'Uống 250ml trong 30 phút sau khi thức dậy',
      progress: 250, target: 250, unit: 'ml',
      reward: 15, kind: 'coin',
      done: true, claimed: true,
    },
    {
      id: 'd2',
      icon: '☀️',
      glow: '#38BDF8',
      name: 'Nửa ngày — nửa bình',
      sub: 'Đạt 50% mục tiêu trước 12:00',
      progress: 1250, target: 1250, unit: 'ml',
      reward: 25, kind: 'coin',
      done: true, claimed: false,
    },
    {
      id: 'd3',
      icon: '💧',
      glow: '#0EA5E9',
      name: 'Đều đặn cả ngày',
      sub: 'Log nước ít nhất 5 lần',
      progress: 3, target: 5, unit: 'lần',
      reward: 20, kind: 'coin',
    },
    {
      id: 'd4',
      icon: '🏃',
      glow: '#A78BFA',
      name: 'Bù nước sau vận động',
      sub: 'Uống 500ml trong 1h sau khi tập',
      progress: 0, target: 500, unit: 'ml',
      reward: 30, kind: 'coin',
      contextual: true,
    },
    {
      id: 'd5',
      icon: '🎯',
      glow: '#F472B6',
      name: 'Cán đích hôm nay',
      sub: 'Đạt 100% mục tiêu 2,500ml',
      progress: 1450, target: 2500, unit: 'ml',
      reward: 50, kind: 'coin',
    },
  ];

  // Weekly missions
  const weekly = [
    {
      id: 'w1',
      icon: '🔥',
      glow: '#F97316',
      name: 'Tuần lễ kiên trì',
      sub: 'Streak 7 ngày liên tiếp',
      progress: 5, target: 7, unit: 'ngày',
      reward: 'Avatar Frame · Ocean', kind: 'unlock',
      bonusXP: 150,
      bonusCoin: 250,
    },
    {
      id: 'w2',
      icon: '🌊',
      glow: '#38BDF8',
      name: 'Đại dương 14 lít',
      sub: 'Tổng 14,000ml trong tuần',
      progress: 9850, target: 14000, unit: 'ml',
      reward: 200, kind: 'coin',
    },
    {
      id: 'w3',
      icon: '⭐',
      glow: '#FBBF24',
      name: 'Hoàn thành 5/7',
      sub: 'Đạt mục tiêu ngày trong 5 ngày',
      progress: 4, target: 5, unit: 'ngày',
      reward: 'Theme Forest Rain', kind: 'unlock',
      bonusXP: 120,
      bonusCoin: 180,
    },
    {
      id: 'w4',
      icon: '🍵',
      glow: '#A3E635',
      name: 'Đa dạng hoá',
      sub: 'Thử log 4 loại đồ uống khác nhau',
      progress: 3, target: 4, unit: 'loại',
      reward: 80, kind: 'coin',
    },
    {
      id: 'w5',
      icon: '🤝',
      glow: '#C084FC',
      name: 'Cùng nhau hydrate',
      sub: 'Mời 1 bạn tham gia AquaTrack',
      progress: 0, target: 1, unit: 'bạn',
      reward: 120, kind: 'coin',
    },
  ];

  const dailyDone = daily.filter((m) => m.done).length;
  const dailyClaimableXP = daily.filter((m) => m.done && !m.claimed).reduce((s, m) => s + ((m.kind === 'xp' || m.kind === 'coin') ? m.reward : 0), 0);
  const weeklyDone = weekly.filter((m) => m.progress >= m.target).length;
  const weeklyTotalReward = weekly.reduce((s, m) => s + (m.kind === 'coin' ? m.reward : (m.bonusCoin || 0)), 0);
  const weekProgress = Math.round((weekly.reduce((s, m) => s + Math.min(1, m.progress / m.target), 0) / weekly.length) * 100);

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{ padding: '54px 20px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 11, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              {tab === 'daily' ? 'Thứ Hai · 11.05' : 'Tuần 19 · 11—17.05'}
            </div>
            <div style={{ fontSize: 26, fontWeight: 600, color: 'white', letterSpacing: '-0.02em', marginTop: 2 }}>
              Nhiệm vụ
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <CoinBadge amount={1240} compact suffix="miss" onClick={() => onNavigate && onNavigate('shop')} />
            <StreakBadge days={12} compact />
          </div>
        </div>
      </div>

      {/* Tab switcher */}
      <div style={{ padding: '8px 16px 12px' }}>
        <div style={{
          display: 'flex',
          background: COLORS.nightSurface,
          border: `1px solid ${COLORS.border}`,
          borderRadius: 12,
          padding: 4,
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute',
            top: 4, bottom: 4,
            left: tab === 'daily' ? 4 : '50%',
            width: 'calc(50% - 4px)',
            background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
            borderRadius: 9,
            boxShadow: '0 4px 12px rgba(14,165,233,0.35)',
            transition: 'left 0.28s cubic-bezier(0.4, 0, 0.2, 1)',
          }} />
          {[
            { id: 'daily', label: 'Hằng ngày', count: `${dailyDone}/${daily.length}` },
            { id: 'weekly', label: 'Hằng tuần', count: `${weeklyDone}/${weekly.length}` },
          ].map((t) => {
            const a = t.id === tab;
            return (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                flex: 1, position: 'relative',
                background: 'none', border: 'none', cursor: 'pointer',
                padding: '10px 0',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                fontFamily: FONT_ROUND, fontWeight: 600, fontSize: 13,
                color: a ? 'white' : COLORS.textSecondary,
                letterSpacing: '-0.01em',
                transition: 'color 0.2s',
              }}>
                <span>{t.label}</span>
                <span style={{
                  fontSize: 10, fontWeight: 700,
                  padding: '2px 7px', borderRadius: 999,
                  background: a ? 'rgba(255,255,255,0.22)' : 'rgba(148,163,184,0.15)',
                  color: a ? 'white' : COLORS.textSecondary,
                  fontFeatureSettings: '"tnum"',
                }}>{t.count}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Scrollable content */}
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 20px' }}>
        {tab === 'daily' ? (
          <DailyView missions={daily} dailyDone={dailyDone} claimable={dailyClaimableXP} />
        ) : (
          <WeeklyView missions={weekly} weekProgress={weekProgress} totalReward={weeklyTotalReward} weeklyDone={weeklyDone} />
        )}
      </div>

      <BottomTabBar active="missions" onNavigate={onNavigate} />

      <style>{`
        @keyframes aq-pulse-glow {
          0%, 100% { box-shadow: 0 0 0 0 rgba(56,189,248,0.5); }
          50% { box-shadow: 0 0 0 8px rgba(56,189,248,0); }
        }
        @keyframes aq-shimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }
      `}</style>
    </div>
  );
}

/* ─── DAILY VIEW ─────────────────────────────────────── */

function DailyView({ missions, dailyDone, claimable }) {
  const pct = Math.round((dailyDone / missions.length) * 100);
  return (
    <>
      {/* Summary ring card */}
      <div style={{
        background: 'linear-gradient(135deg, #0C2A4A 0%, #0B1933 100%)',
        border: `1px solid ${COLORS.border}`,
        borderRadius: 18,
        padding: 16,
        marginBottom: 14,
        display: 'flex', alignItems: 'center', gap: 16,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(circle at 90% 0%, rgba(56,189,248,0.18), transparent 60%)',
          pointerEvents: 'none',
        }} />
        <ProgressRing size={72} stroke={7} percent={pct} accent="#38BDF8" track="rgba(56,189,248,0.12)">
          <div style={{ fontSize: 18, fontWeight: 700, fontFamily: FONT_ROUND, color: 'white', letterSpacing: '-0.02em' }}>
            {dailyDone}<span style={{ fontSize: 11, color: COLORS.textSecondary, fontWeight: 500 }}>/{missions.length}</span>
          </div>
        </ProgressRing>
        <div style={{ flex: 1, position: 'relative' }}>
          <div style={{ fontSize: 11, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
            Tiến độ hôm nay
          </div>
          <div style={{ fontSize: 16, fontWeight: 600, color: 'white', marginTop: 2, letterSpacing: '-0.01em', textWrap: 'pretty' }}>
            Bạn đã làm rất tốt 👏
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
            <Pill color="#FDE68A" bg="rgba(245,158,11,0.15)" border="rgba(245,158,11,0.35)">
              {I.coin(11, 'pill')} <b>+40</b> đã nhận
            </Pill>
            {claimable > 0 && (
              <Pill color="#FDE68A" bg="rgba(251,191,36,0.18)" border="rgba(251,191,36,0.5)" pulse>
                {I.coin(12, 'pillc')} <b>+{claimable}</b> sẵn sàng nhận
              </Pill>
            )}
          </div>
        </div>
      </div>

      {/* Mission cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {missions.map((m) => (
          <MissionCard key={m.id} mission={m} />
        ))}
      </div>

      {/* Footer: refresh notice */}
      <div style={{
        marginTop: 14,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT,
      }}>
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <path d="M12 6 V12 L16 14" /><circle cx="12" cy="12" r="9" />
        </svg>
        Làm mới sau 11h 24p
      </div>
    </>
  );
}

/* ─── WEEKLY VIEW ────────────────────────────────────── */

function WeeklyView({ missions, weekProgress, totalReward, weeklyDone }) {
  // 7-day strip
  const days = [
    { d: 'T2', s: 'done', label: 100 },
    { d: 'T3', s: 'done', label: 100 },
    { d: 'T4', s: 'partial', label: 78 },
    { d: 'T5', s: 'done', label: 100 },
    { d: 'T6', s: 'today', label: 58 },
    { d: 'T7', s: 'future' },
    { d: 'CN', s: 'future' },
  ];

  return (
    <>
      {/* Chest / Weekly mega reward */}
      <div style={{
        background: 'linear-gradient(135deg, #1A1040 0%, #2D1B6B 60%, #0C2A4A 100%)',
        border: '1px solid rgba(165,180,252,0.4)',
        borderRadius: 18,
        padding: 16,
        marginBottom: 14,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(circle at 100% 0%, rgba(251,191,36,0.18), transparent 55%)',
          pointerEvents: 'none',
        }} />
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
          <div style={{ flex: 1, paddingRight: 12 }}>
            <div style={{ fontSize: 11, color: '#FCD34D', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              Kho báu cuối tuần
            </div>
            <div style={{ fontSize: 18, fontWeight: 700, color: 'white', marginTop: 2, fontFamily: FONT_ROUND, letterSpacing: '-0.02em', textWrap: 'pretty' }}>
              Hoàn thành cả tuần để mở khoá
            </div>
            <div style={{ fontSize: 12, color: '#C7D2FE', marginTop: 4, fontFamily: FONT_TEXT, lineHeight: 1.4 }}>
              {weeklyDone}/{missions.length} nhiệm vụ · còn 3 ngày
            </div>
          </div>
          <ChestIcon />
        </div>

        {/* Progress */}
        <div style={{ marginTop: 14, position: 'relative' }}>
          <div style={{
            height: 8, background: 'rgba(255,255,255,0.08)', borderRadius: 999, overflow: 'hidden',
          }}>
            <div style={{
              height: '100%', width: `${weekProgress}%`,
              background: 'linear-gradient(90deg, #FBBF24, #F59E0B, #A78BFA)',
              borderRadius: 999,
              boxShadow: '0 0 12px rgba(251,191,36,0.5)',
            }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 10.5, fontFamily: FONT_TEXT }}>
            <span style={{ color: '#FCD34D', fontWeight: 600 }}>{weekProgress}% hoàn thành</span>
            <span style={{ color: COLORS.textSecondary, fontFeatureSettings: '"tnum"' }}>+{totalReward.toLocaleString('vi-VN')} xu · 2 unlock</span>
          </div>
        </div>
      </div>

      {/* 7-day strip */}
      <div style={{
        background: COLORS.nightSurface,
        border: `1px solid ${COLORS.border}`,
        borderRadius: 14,
        padding: '12px 10px',
        marginBottom: 14,
      }}>
        <div style={{ fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Tuần này
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {days.map((d, i) => {
            const palette = {
              done: { bg: 'linear-gradient(180deg, #0EA5E9, #0284C7)', dot: '#FBBF24', text: 'white', sub: '#BAE6FD' },
              partial: { bg: 'rgba(14,165,233,0.18)', dot: 'transparent', text: '#BAE6FD', sub: '#7DD3FC' },
              today: { bg: 'rgba(56,189,248,0.10)', dot: 'transparent', text: 'white', sub: '#FBBF24', ring: true },
              future: { bg: 'rgba(255,255,255,0.03)', dot: 'transparent', text: COLORS.textMuted, sub: COLORS.textMuted },
            }[d.s];
            return (
              <div key={i} style={{
                flex: 1, aspectRatio: '0.78',
                background: palette.bg,
                border: palette.ring ? `1.5px dashed ${COLORS.glow}` : '1px solid rgba(255,255,255,0.05)',
                borderRadius: 10,
                padding: '6px 4px',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between',
                position: 'relative',
              }}>
                <div style={{ fontSize: 10, color: palette.text, fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.04em' }}>{d.d}</div>
                {d.s === 'done' && <span style={{ fontSize: 13 }}>✓</span>}
                {d.s !== 'done' && d.label !== undefined && (
                  <div style={{ fontSize: 9.5, color: palette.sub, fontFamily: FONT_TEXT, fontWeight: 600, fontFeatureSettings: '"tnum"' }}>{d.label}%</div>
                )}
                {d.s === 'future' && <div style={{ fontSize: 11, color: COLORS.textMuted }}>·</div>}
              </div>
            );
          })}
        </div>
      </div>

      {/* Weekly mission cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {missions.map((m) => (
          <MissionCard key={m.id} mission={m} weekly />
        ))}
      </div>
    </>
  );
}

/* ─── MISSION CARD ───────────────────────────────────── */

function MissionCard({ mission: m, weekly = false }) {
  const pct = Math.min(100, Math.round((m.progress / m.target) * 100));
  const done = m.progress >= m.target;
  const claimable = done && !m.claimed;

  // Format progress label — unit comes from each mission
  const fmt = (n) => (m.target >= 1000 ? n.toLocaleString() : n);
  const unit = m.unit || '';
  const progressLabel = `${fmt(m.progress)}/${fmt(m.target)}${unit ? ' ' + unit : ''}`;

  return (
    <div style={{
      background: m.claimed
        ? 'rgba(15,26,46,0.5)'
        : claimable
          ? 'linear-gradient(135deg, rgba(251,191,36,0.10), rgba(245,158,11,0.04))'
          : COLORS.nightSurface,
      border: m.claimed
        ? '1px dashed rgba(255,255,255,0.08)'
        : claimable
          ? '1px solid rgba(251,191,36,0.5)'
          : `1px solid ${COLORS.border}`,
      borderRadius: 14,
      padding: 12,
      display: 'flex', gap: 12,
      opacity: m.claimed ? 0.6 : 1,
      position: 'relative', overflow: 'hidden',
    }}>
      {claimable && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(110deg, transparent 30%, rgba(251,191,36,0.08) 50%, transparent 70%)',
          backgroundSize: '200% 100%',
          animation: 'aq-shimmer 3s linear infinite',
          pointerEvents: 'none',
        }} />
      )}

      {/* Icon */}
      <div style={{
        width: 46, height: 46, borderRadius: 12,
        background: `radial-gradient(circle at 30% 30%, ${m.glow}33, ${m.glow}11)`,
        border: `1px solid ${m.glow}44`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        fontSize: 22,
        filter: m.claimed ? 'grayscale(0.7)' : 'none',
      }}>{m.icon}</div>

      {/* Body */}
      <div style={{ flex: 1, minWidth: 0, position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{
                fontSize: 13.5, fontWeight: 600, color: m.claimed ? COLORS.textSecondary : COLORS.textPrimary,
                fontFamily: FONT_TEXT, letterSpacing: '-0.01em',
                textDecoration: m.claimed ? 'line-through' : 'none',
              }}>{m.name}</div>
              {m.contextual && (
                <span style={{
                  fontSize: 8.5, padding: '1px 5px', borderRadius: 4,
                  background: 'rgba(167,139,250,0.18)', color: '#C4B5FD',
                  fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.04em',
                }}>AI</span>
              )}
            </div>
            <div style={{ fontSize: 11.5, color: COLORS.textSecondary, marginTop: 2, fontFamily: FONT_TEXT, lineHeight: 1.35 }}>
              {m.sub}
            </div>
          </div>

          {/* Reward chip */}
          <RewardChip mission={m} />
        </div>

        {/* Progress */}
        <div style={{ marginTop: 9 }}>
          <div style={{
            height: 5, background: 'rgba(255,255,255,0.06)', borderRadius: 999, overflow: 'hidden', position: 'relative',
          }}>
            <div style={{
              height: '100%', width: `${pct}%`,
              background: m.claimed
                ? 'rgba(255,255,255,0.18)'
                : done
                  ? 'linear-gradient(90deg, #FBBF24, #F59E0B)'
                  : `linear-gradient(90deg, ${m.glow}, ${m.glow}AA)`,
              borderRadius: 999,
              boxShadow: done && !m.claimed ? '0 0 8px rgba(251,191,36,0.6)' : 'none',
              transition: 'width 0.4s ease',
            }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 6 }}>
            <span style={{ fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT, fontFeatureSettings: '"tnum"', fontWeight: 500 }}>
              {progressLabel}
            </span>
            {claimable ? (
              <button style={{
                background: 'linear-gradient(135deg, #FBBF24, #F59E0B)',
                color: '#451A03',
                border: 'none',
                padding: '4px 12px', borderRadius: 8,
                fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 11,
                letterSpacing: '0.02em',
                cursor: 'pointer',
                boxShadow: '0 2px 8px rgba(245,158,11,0.4)',
              }}>NHẬN</button>
            ) : m.claimed ? (
              <span style={{ fontSize: 10, color: '#A3E635', fontFamily: FONT_ROUND, fontWeight: 600, letterSpacing: '0.04em' }}>
                ✓ ĐÃ NHẬN
              </span>
            ) : (
              <span style={{ fontSize: 10.5, color: m.glow, fontFamily: FONT_ROUND, fontWeight: 600, fontFeatureSettings: '"tnum"' }}>
                {pct}%
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function RewardChip({ mission: m }) {
  if (m.kind === 'coin') {
    return (
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        padding: '3px 8px 3px 6px', borderRadius: 999,
        background: 'linear-gradient(135deg, rgba(251,191,36,0.18), rgba(245,158,11,0.06))',
        border: '1px solid rgba(251,191,36,0.45)',
        fontFamily: FONT_ROUND, fontSize: 11, fontWeight: 700,
        color: '#FDE68A',
        flexShrink: 0,
        fontFeatureSettings: '"tnum"',
      }}>
        {I.coin(11, 'rc' + m.id)} +{m.reward}
      </div>
    );
  }
  if (m.kind === 'xp') {
    return (
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        padding: '3px 8px 3px 6px', borderRadius: 999,
        background: 'rgba(129,140,248,0.15)',
        border: '1px solid rgba(129,140,248,0.35)',
        fontFamily: FONT_ROUND, fontSize: 11, fontWeight: 700,
        color: '#C7D2FE',
        flexShrink: 0,
        fontFeatureSettings: '"tnum"',
      }}>
        {I.bolt('#A5B4FC', 10)} +{m.reward}
      </div>
    );
  }
  // unlock
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 8px', borderRadius: 999,
      background: 'rgba(251,191,36,0.15)',
      border: '1px solid rgba(251,191,36,0.4)',
      fontFamily: FONT_ROUND, fontSize: 10, fontWeight: 700,
      color: '#FDE68A',
      flexShrink: 0,
      maxWidth: 130,
      letterSpacing: '0.01em',
    }}>
      🔓 {m.reward}
    </div>
  );
}

/* ─── ATOMS ──────────────────────────────────────────── */

function ProgressRing({ size = 72, stroke = 7, percent, accent, track, children }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c - (percent / 100) * c;
  return (
    <div style={{ width: size, height: size, position: 'relative', flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={accent} strokeWidth={stroke}
          strokeDasharray={c} strokeDashoffset={off} strokeLinecap="round"
          style={{ filter: `drop-shadow(0 0 4px ${accent}99)`, transition: 'stroke-dashoffset 0.6s ease' }} />
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexDirection: 'column',
      }}>{children}</div>
    </div>
  );
}

function Pill({ children, color, bg, border, pulse }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '4px 9px',
      borderRadius: 999,
      background: bg,
      border: `1px solid ${border}`,
      fontFamily: FONT_TEXT, fontSize: 11,
      color,
      animation: pulse ? 'aq-pulse-glow 1.8s ease-in-out infinite' : 'none',
    }}>{children}</span>
  );
}

function ChestIcon() {
  return (
    <div style={{
      width: 64, height: 64, flexShrink: 0,
      borderRadius: 14,
      background: 'radial-gradient(circle at 30% 30%, rgba(251,191,36,0.35), rgba(245,158,11,0.1))',
      border: '1px solid rgba(251,191,36,0.5)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 6px 20px rgba(245,158,11,0.25)',
      position: 'relative',
    }}>
      <svg width="38" height="38" viewBox="0 0 24 24" fill="none">
        <path d="M3 10 V20 a1 1 0 0 0 1 1 H20 a1 1 0 0 0 1-1 V10 z" fill="#92400E" stroke="#FBBF24" strokeWidth="1.4"/>
        <path d="M3 10 V8 a3 3 0 0 1 3-3 H18 a3 3 0 0 1 3 3 V10 z" fill="#B45309" stroke="#FBBF24" strokeWidth="1.4"/>
        <rect x="10" y="11" width="4" height="6" rx="0.5" fill="#FBBF24" stroke="#78350F" strokeWidth="0.6"/>
        <circle cx="12" cy="13.5" r="0.8" fill="#78350F"/>
      </svg>
      <span style={{ position: 'absolute', top: -4, right: -4, fontSize: 16 }}>✨</span>
    </div>
  );
}

window.MissionsScreen = MissionsScreen;
