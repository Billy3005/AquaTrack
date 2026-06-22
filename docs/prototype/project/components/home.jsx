// HomeScreen — "Living Drop" — primary screen of AquaTrack
// state: 'normal' | 'dehydrated' | 'goal' | 'night'

function HomeScreen({ state = 'normal', current, goal, onLog, onNavigate, hot = false }) {
  const pct = Math.round(current / goal * 100);
  const isGoal = pct >= 80;
  const isLow = pct < 31;
  const isNight = state === 'night';

  // Hero background varies by state
  let heroBg;
  if (state === 'goal') {
    heroBg = 'linear-gradient(180deg, #0C4A80 0%, #1E6FA8 60%, #0EA5E9 120%)';
  } else if (state === 'dehydrated') {
    heroBg = 'linear-gradient(180deg, #061830 0%, #0A2545 100%)';
  } else if (hot) {
    heroBg = 'linear-gradient(180deg, #1A0A00 0%, #0C2A48 100%)';
  } else if (state === 'night') {
    heroBg = 'linear-gradient(180deg, #050B18 0%, #0B1933 100%)';
  } else {
    heroBg = 'linear-gradient(180deg, #0A3460 0%, #0C4A80 100%)';
  }

  const [activeChip, setActiveChip] = React.useState(250);
  const [holding, setHolding] = React.useState(null);
  const [xpPop, setXpPop] = React.useState(null);

  function handleLog(amt) {
    setActiveChip(amt);
    if (onLog) onLog(amt);
    setXpPop({ amt: 20, id: Date.now() });
    setTimeout(() => setXpPop(null), 900);
  }

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
      position: 'relative', overflow: 'hidden'
    }}>
      {/* Hero section */}
      <div style={{
        position: 'relative',
        background: heroBg,
        padding: '60px 20px 32px',
        flexShrink: 0
      }}>
        {/* top context row */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginBottom: 8, fontFamily: FONT_TEXT
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'rgba(186,230,253,0.85)' }}>
            {hot ? I.thermo('#FBBF24', 14) : I.drop('#7DD3FC', 14)}
            <span>{hot ? 'HCMC · 34°C' : isNight ? 'Đêm · 22°C' : 'HCMC · 28°C'}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <CoinBadge amount={1240} compact suffix="home" onClick={() => onNavigate && onNavigate('shop')} />
            <StreakBadge days={12} compact />
          </div>
        </div>

        {/* Greeting */}
        <div style={{ marginBottom: 20 }}>
          <div style={{
            fontSize: 13, color: 'rgba(186,230,253,0.7)', letterSpacing: '0.04em',
            textTransform: 'uppercase', fontWeight: 500, fontFamily: FONT_TEXT
          }}>
            {isNight ? 'Tối muộn · 22:14' : 'Chào buổi sáng'}
          </div>
          <div style={{
            fontSize: 22, fontWeight: 600, color: 'white', marginTop: 2,
            letterSpacing: '-0.02em'
          }}>
            {isLow ? 'Cơ thể bạn đang khát' :
            isGoal ? 'Tuyệt vời, gần đủ rồi!' :
            isNight ? 'Một ngụm trước khi ngủ?' : 'Hãy cùng giữ nhịp uống nước'}
          </div>
        </div>

        {/* Living drop */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
          <LivingDrop
            percent={pct}
            size={200}
            label={`${pct}%`}
            sublabel={`${current.toLocaleString()} / ${goal.toLocaleString()} ml`}
            glow={isGoal} />
          
          {/* XP popup */}
          {xpPop &&
          <div key={xpPop.id} style={{
            position: 'absolute', top: 180, left: '50%',
            transform: 'translateX(-50%)',
            fontFamily: FONT_ROUND, fontSize: 20, fontWeight: 700,
            color: '#FDE68A',
            textShadow: '0 2px 12px rgba(251,191,36,0.6)',
            animation: 'aq-xp 900ms ease-out forwards',
            pointerEvents: 'none'
          }}>+{xpPop.amt} XP</div>
          }
        </div>

        {/* XP bar pinned in hero */}
        <div style={{
          background: 'rgba(8,30,56,0.5)',
          backdropFilter: 'blur(12px)',
          border: '1px solid rgba(56,189,248,0.18)',
          borderRadius: 14,
          padding: '12px 14px'
        }}>
          <XPBar xp={1240} xpMax={2000} level={7} levelName="Chiến binh Nước" />
        </div>
      </div>

      {/* Content section (scrolls) */}
      <div style={{
        flex: 1, padding: '20px 20px 28px', overflow: 'auto',
        background: COLORS.nightBase
      }}>
        {/* Quick tap row */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginBottom: 10, fontFamily: FONT_TEXT
        }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, letterSpacing: '-0.01em' }}>
            Ghi nhanh
          </div>
          <div style={{ fontSize: 11, color: COLORS.textMuted }}>Giữ để nạp liên tục</div>
        </div>
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          <QuickChip amount={100} active={activeChip === 100} onClick={() => handleLog(100)} />
          <QuickChip amount={250} active={activeChip === 250} onClick={() => handleLog(250)} />
          <QuickChip amount={500} active={activeChip === 500} onClick={() => handleLog(500)} />
          <QuickChip custom onClick={() => onNavigate && onNavigate('log')} />
        </div>

        {/* Context-aware AI tip card */}
        <div onClick={() => onNavigate && onNavigate('coach')} style={{
          background: 'linear-gradient(135deg, rgba(56,189,248,0.14), rgba(129,140,248,0.10))',
          border: '1px solid rgba(56,189,248,0.25)',
          borderRadius: 16,
          padding: '14px 14px',
          marginBottom: 18,
          display: 'flex', gap: 12, alignItems: 'flex-start',
          cursor: 'pointer'
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 999,
            background: 'radial-gradient(circle at 30% 30%, #7DD3FC, #0EA5E9)',
            flexShrink: 0,
            boxShadow: '0 0 18px rgba(56,189,248,0.5)',
            display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
            <div style={{ width: 8, height: 8, borderRadius: 999, background: 'white' }} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontSize: 11, color: COLORS.textBright, fontWeight: 600,
              letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 2,
              fontFamily: FONT_TEXT
            }}>Aqua AI</div>
            <div style={{ fontSize: 13.5, color: COLORS.textPrimary, lineHeight: 1.4, fontFamily: FONT_TEXT }}>
              {hot ? 'Trời HCMC đang 34°C — uống thêm +300ml so với bình thường nhé.' :
              isLow ? 'Đã 14h mà mới đạt 28%. Uống 300ml ngay để theo kịp nhé!' :
              isGoal ? 'Bạn đang trên đà streak 13 ngày — chỉ còn 380ml nữa thôi!' :
              'Cà phê bạn vừa log có tính lợi tiểu — cần thêm +250ml để bù lại.'}
            </div>
          </div>
          <div style={{ alignSelf: 'center' }}>{I.chevR(COLORS.textMuted, 16)}</div>
        </div>

        {/* Today's log */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
          marginBottom: 10
        }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, fontFamily: FONT_TEXT }}>
            Hôm nay
          </div>
          <div style={{ fontSize: 11, color: COLORS.textMuted }}>5 lần · {current}ml</div>
        </div>
        <div style={{
          background: COLORS.nightSurface,
          border: `1px solid ${COLORS.border}`,
          borderRadius: 14,
          overflow: 'hidden'
        }}>
          {[
          { type: 'water', amt: 250, time: '13:20', label: 'Nước lọc' },
          { type: 'coffee', amt: 180, time: '10:45', label: 'Cà phê đá' },
          { type: 'tea', amt: 200, time: '09:10', label: 'Trà sen' }].
          map((row, i, arr) =>
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '12px 14px',
            borderBottom: i < arr.length - 1 ? `1px solid rgba(255,255,255,0.04)` : 'none'
          }}>
              <DrinkIcon type={row.type} size={22} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, color: COLORS.textPrimary, fontWeight: 500, fontFamily: FONT_TEXT }}>
                  {row.label}
                </div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1 }}>
                  {row.time}
                </div>
              </div>
              <div style={{
              fontFamily: FONT_ROUND, fontSize: 14, fontWeight: 600,
              color: COLORS.textPrimary,
              fontFeatureSettings: '"tnum"'
            }}>
                {row.amt}<span style={{ fontSize: 10, color: COLORS.textMuted, fontWeight: 500 }}> ml</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Floating Smart Scan FAB */}
      <button onClick={() => onNavigate && onNavigate('camera')} style={{
        position: 'absolute', right: 18, bottom: 96, zIndex: 10,
        width: 56, height: 56, borderRadius: 999,
        background: 'linear-gradient(135deg, #38BDF8, #0EA5E9)',
        border: '1px solid rgba(255,255,255,0.2)',
        boxShadow: '0 8px 24px rgba(14,165,233,0.5), inset 0 1px 0 rgba(255,255,255,0.3)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: 'pointer'
      }}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M4 8 V6 a2 2 0 0 1 2-2 H8 M16 4 H18 a2 2 0 0 1 2 2 V8 M20 16 V18 a2 2 0 0 1-2 2 H16 M8 20 H6 a2 2 0 0 1-2-2 V16" />
          <circle cx="12" cy="12" r="3.5" />
        </svg>
      </button>

      {/* Bottom tab bar */}
      <BottomTabBar active="home" onNavigate={onNavigate} />

      <style>{`
        @keyframes aq-pulse {
          0%, 100% { opacity: 0.5; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.05); }
        }
        @keyframes aq-xp {
          0% { transform: translate(-50%, 0); opacity: 0; }
          20% { opacity: 1; }
          100% { transform: translate(-50%, -60px); opacity: 0; }
        }
      `}</style>
    </div>);

}

function BottomTabBar({ active, onNavigate }) {
  const tabs = [
  { id: 'home', label: 'Nước', svg: (c) => I.drop(c, 22) },
  { id: 'coach', label: 'Chat', svg: (c) =>
    <svg width="22" height="22" viewBox="0 0 24 24" fill={c}>
        <path d="M4 6 a3 3 0 0 1 3-3 H17 a3 3 0 0 1 3 3 V14 a3 3 0 0 1-3 3 H10 L5 21 V17 a3 3 0 0 1-1-2 V6 z" />
        <circle cx="9" cy="10" r="1.2" fill={COLORS.nightBase} />
        <circle cx="13" cy="10" r="1.2" fill={COLORS.nightBase} />
      </svg>
  },
  { id: 'missions', label: 'Nhiệm vụ', svg: (c) =>
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="9" />
        <circle cx="12" cy="12" r="5" />
        <circle cx="12" cy="12" r="1.6" fill={c} stroke="none" />
      </svg>
  },
  { id: 'stats', label: 'Thống kê', svg: (c) =>
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 13 Q6 9 9 13 T15 13 T21 13" />
        <path d="M3 17 Q6 13 9 17 T15 17 T21 17" opacity="0.5" />
      </svg>
  },
  { id: 'friends', label: 'Bạn bè', svg: (c) =>
    <svg width="22" height="22" viewBox="0 0 24 24" fill={c}>
        <circle cx="9" cy="8" r="3.5" />
        <circle cx="17" cy="9" r="2.8" />
        <path d="M2 20 a7 7 0 0 1 14 0 z" />
        <path d="M14 20 a5 5 0 0 1 8 0 H14 z" />
      </svg>
  },
  { id: 'level', label: 'Cấp độ', svg: (c) => I.trophy(c, 22) },
  { id: 'profile', label: 'Hồ sơ', svg: (c) =>
    <svg width="22" height="22" viewBox="0 0 24 24" fill={c}>
        <circle cx="12" cy="8" r="4" />
        <path d="M4 21 a8 8 0 0 1 16 0 z" />
      </svg>
  }];

  return (
    <div style={{
      flexShrink: 0,
      background: 'rgba(11,17,32,0.85)',
      backdropFilter: 'blur(20px)',
      borderTop: '1px solid rgba(56,189,248,0.12)',
      padding: '10px 8px 32px',
      display: 'flex', justifyContent: 'space-around'
    }}>
      {tabs.map((t) => {
        const a = t.id === active;
        const c = a ? COLORS.glow : '#475569';
        return (
          <button key={t.id} onClick={() => onNavigate && onNavigate(t.id)} style={{
            background: 'none', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '4px 8px'
          }}>
            {t.svg(c)}
            <div style={{
              fontSize: 9.5, color: c, fontFamily: FONT_ROUND, fontWeight: 600,
              letterSpacing: '0.04em'
            }}>{t.label}</div>
          </button>);

      })}
    </div>);

}

window.HomeScreen = HomeScreen;
window.BottomTabBar = BottomTabBar;