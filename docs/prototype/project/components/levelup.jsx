// LevelUpCelebration — the "lên cấp" reward moment.
// Full-bleed overlay shown inside the iPhone frame when the user reaches a new level.
// Auto-plays on mount; tap anywhere (backdrop) to replay the sequence.

function LevelUpCelebration({
  fromLevel = 7,
  toLevel = 8,
  rankName = 'Thuỷ thủ Đại dương',
  xpInto = 100,            // XP carried into the new level (the bar fills then settles here)
  rewards = [
    { icon: 'coin', label: '+120 xu' },
    { icon: 'theme', label: 'Mở khoá theme “Biển đêm”' },
    { icon: 'frame', label: 'Khung avatar mới' },
  ],
  onDone,
}) {
  const [runId, setRunId] = React.useState(0);
  const replay = () => setRunId((n) => n + 1);

  // teardrop confetti — water-themed
  const drops = React.useMemo(() => {
    const palette = ['#7DD3FC', '#38BDF8', '#0EA5E9', '#A5B4FC', '#FBBF24', '#BAE6FD'];
    return Array.from({ length: 22 }, (_, i) => ({
      left: 4 + Math.random() * 92,
      size: 7 + Math.random() * 12,
      color: palette[i % palette.length],
      delay: 0.15 + Math.random() * 1.6,
      dur: 2.4 + Math.random() * 1.8,
      drift: (Math.random() - 0.5) * 60,
      rot: (Math.random() - 0.5) * 120,
    }));
  }, [runId]);

  return (
    <div
      key={runId}
      onClick={replay}
      style={{
        width: '100%', height: '100%', position: 'relative', overflow: 'hidden',
        fontFamily: FONT, color: '#fff', cursor: 'pointer',
        background: 'radial-gradient(ellipse 70% 50% at 50% 34%, #15376B 0%, #0A1B3A 48%, #050B1C 100%)',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        padding: '0 28px',
      }}
    >
      {/* ===== sunburst rays ===== */}
      <div style={{
        position: 'absolute', top: '34%', left: '50%', width: 620, height: 620,
        transform: 'translate(-50%,-50%)',
        background: 'repeating-conic-gradient(from 0deg at 50% 50%, rgba(125,211,252,0.16) 0deg 5deg, transparent 5deg 17deg)',
        WebkitMaskImage: 'radial-gradient(circle, #000 0%, #000 30%, transparent 66%)',
        maskImage: 'radial-gradient(circle, #000 0%, #000 30%, transparent 66%)',
        animation: 'lu-spin 26s linear infinite',
        opacity: 0, animationName: 'lu-spin, lu-fade-in',
        animationDuration: '26s, 0.9s', animationTimingFunction: 'linear, ease-out',
        animationIterationCount: 'infinite, 1', animationFillMode: 'none, forwards',
      }} />

      {/* ===== expanding ripple rings ===== */}
      {[0, 0.45, 0.9].map((d, i) => (
        <div key={i} style={{
          position: 'absolute', top: '34%', left: '50%', width: 120, height: 120,
          marginLeft: -60, marginTop: -60, borderRadius: '50%',
          border: '2px solid rgba(125,211,252,0.5)',
          animation: `lu-ring 2.6s ease-out ${d}s infinite`,
        }} />
      ))}

      {/* ===== floating teardrop confetti ===== */}
      {drops.map((dp, i) => (
        <span key={i} style={{
          position: 'absolute', left: `${dp.left}%`, top: '64%',
          width: dp.size, height: dp.size * 1.25,
          background: dp.color,
          borderRadius: '50% 50% 50% 50% / 64% 64% 36% 36%',
          transform: 'rotate(180deg)',
          boxShadow: `0 0 8px ${dp.color}88`,
          opacity: 0,
          '--drift': `${dp.drift}px`, '--rot': `${dp.rot}deg`,
          animation: `lu-float ${dp.dur}s ease-out ${dp.delay}s forwards`,
        }} />
      ))}

      {/* ===== eyebrow ===== */}
      <div style={{
        position: 'relative', zIndex: 3, textAlign: 'center',
        opacity: 0, animation: 'lu-rise 0.6s ease-out 0.15s forwards',
      }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 7,
          fontSize: 12, fontWeight: 800, letterSpacing: '0.32em',
          color: '#7DD3FC', fontFamily: FONT_ROUND, textTransform: 'uppercase',
        }}>
          {I.spark('#7DD3FC', 14)} Lên cấp {I.spark('#7DD3FC', 14)}
        </div>
      </div>

      {/* ===== level badge ===== */}
      <div style={{
        position: 'relative', zIndex: 3, margin: '14px 0 6px',
        opacity: 0, animation: 'lu-pop 0.7s cubic-bezier(.2,1.5,.4,1) 0.35s forwards',
      }}>
        {/* glow halo */}
        <div style={{
          position: 'absolute', inset: -26, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.45), transparent 68%)',
          animation: 'lu-glow 2.4s ease-in-out infinite',
        }} />
        {/* rotating conic shine ring */}
        <div style={{
          position: 'absolute', inset: -8, borderRadius: 34,
          background: 'conic-gradient(from 0deg, transparent, rgba(165,180,252,0.7), transparent 40%, transparent, rgba(125,211,252,0.7), transparent 90%)',
          animation: 'lu-spin 6s linear infinite',
          filter: 'blur(1px)',
        }} />
        {/* badge body — rounded hexagon */}
        <div style={{
          position: 'relative', width: 148, height: 162,
          clipPath: 'polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%)',
          background: 'linear-gradient(160deg, #2563EB 0%, #1E40AF 55%, #0C2A6B 100%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 18px 50px rgba(37,99,235,0.55), inset 0 2px 0 rgba(255,255,255,0.25)',
        }}>
          <div style={{
            fontSize: 11, fontWeight: 800, letterSpacing: '0.22em',
            color: 'rgba(186,230,253,0.85)', fontFamily: FONT_ROUND, marginBottom: -4,
          }}>LV</div>
          <div style={{
            fontSize: 78, fontWeight: 800, lineHeight: 1, color: '#fff',
            fontFamily: FONT_ROUND, letterSpacing: '-0.04em',
            textShadow: '0 4px 18px rgba(0,0,0,0.4)',
            display: 'flex',
          }}>
            <span style={{ display: 'inline-block', animation: 'lu-num 0.55s cubic-bezier(.2,1.4,.4,1) 0.7s backwards' }}>{toLevel}</span>
          </div>
        </div>
      </div>

      {/* ===== headline ===== */}
      <div style={{
        position: 'relative', zIndex: 3, textAlign: 'center', marginTop: 4,
        opacity: 0, animation: 'lu-rise 0.6s ease-out 0.55s forwards',
      }}>
        <div style={{
          fontSize: 34, fontWeight: 800, color: '#fff', fontFamily: FONT_ROUND,
          letterSpacing: '-0.02em', textShadow: '0 2px 26px rgba(56,189,248,0.6)',
        }}>
          ĐÃ LÊN CẤP {toLevel}!
        </div>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 8, marginTop: 8,
          fontSize: 13, color: '#94A3B8', fontFamily: FONT_TEXT, fontWeight: 500,
        }}>
          <span style={{ color: '#64748B', textDecoration: 'line-through' }}>Lv {fromLevel}</span>
          {I.chevR('#7DD3FC', 13)}
          <span style={{
            color: '#FDE68A', fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.01em',
          }}>{rankName}</span>
        </div>
      </div>

      {/* ===== XP bar ===== */}
      <div style={{
        position: 'relative', zIndex: 3, width: '100%', maxWidth: 300, marginTop: 22,
        opacity: 0, animation: 'lu-rise 0.6s ease-out 0.8s forwards',
      }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
          marginBottom: 6, fontFamily: FONT_TEXT,
        }}>
          <span style={{ fontSize: 11, color: '#7DD3FC', fontWeight: 700, fontFamily: FONT_ROUND, letterSpacing: '0.04em' }}>
            Tiến độ Lv {toLevel}
          </span>
          <span style={{ fontSize: 10.5, color: '#64748B', fontFeatureSettings: '"tnum"' }}>{xpInto} / 2.000 XP</span>
        </div>
        <div style={{ height: 9, background: '#172A4A', borderRadius: 5, overflow: 'hidden', position: 'relative' }}>
          <div style={{
            position: 'absolute', inset: 0, width: '100%', borderRadius: 5,
            background: 'linear-gradient(90deg, #0EA5E9, #38BDF8, #A5B4FC)',
            transformOrigin: 'left center',
            animation: 'lu-xpsurge 1.5s cubic-bezier(.4,0,.1,1) 0.95s backwards',
          }} />
          <div style={{
            height: '100%', borderRadius: 5,
            background: 'linear-gradient(90deg, #0EA5E9, #38BDF8)',
            boxShadow: '0 0 12px rgba(56,189,248,0.8)',
            width: `${Math.min(100, (xpInto / 2000) * 100)}%`,
            animation: 'lu-xpfill 0.9s ease-out 2.4s backwards',
            position: 'relative', zIndex: 1,
          }} />
        </div>
      </div>

      {/* ===== reward chips ===== */}
      <div style={{
        position: 'relative', zIndex: 3, width: '100%', maxWidth: 320,
        display: 'flex', flexDirection: 'column', gap: 8, marginTop: 18,
      }}>
        {rewards.map((r, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 11,
            padding: '11px 14px', borderRadius: 13,
            background: 'linear-gradient(135deg, rgba(56,189,248,0.12), rgba(165,180,252,0.06))',
            border: '1px solid rgba(125,211,252,0.28)',
            opacity: 0,
            animation: `lu-chip 0.5s cubic-bezier(.2,1.3,.4,1) ${1.2 + i * 0.18}s forwards`,
          }}>
            <RewardGlyph kind={r.icon} />
            <span style={{ fontSize: 13.5, fontWeight: 600, color: '#E0F2FE', fontFamily: FONT_TEXT }}>{r.label}</span>
            <span style={{ marginLeft: 'auto', color: '#86EFAC', fontSize: 15, fontWeight: 800 }}>✓</span>
          </div>
        ))}
      </div>

      {/* ===== actions ===== */}
      <div style={{
        position: 'relative', zIndex: 3, width: '100%', maxWidth: 320,
        display: 'flex', gap: 10, marginTop: 22,
        opacity: 0, animation: 'lu-rise 0.6s ease-out 1.9s forwards',
      }}>
        <button onClick={(e) => { e.stopPropagation(); onDone ? onDone() : replay(); }} style={{
          flex: 1, padding: '15px 0', borderRadius: 15, border: 'none',
          background: 'linear-gradient(135deg, #38BDF8, #0EA5E9)', color: '#04243F',
          fontFamily: FONT_ROUND, fontWeight: 800, fontSize: 16, cursor: 'pointer',
          boxShadow: '0 12px 30px rgba(14,165,233,0.5)',
        }}>Tuyệt vời!</button>
        <button onClick={(e) => e.stopPropagation()} style={{
          width: 56, padding: '15px 0', borderRadius: 15,
          border: '1px solid rgba(255,255,255,0.14)', background: 'rgba(255,255,255,0.04)',
          color: '#BAE6FD', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }} aria-label="Chia sẻ">
          {I.send('#BAE6FD', 19)}
        </button>
      </div>

      {/* replay hint */}
      <div style={{
        position: 'absolute', bottom: 16, left: 0, right: 0, textAlign: 'center',
        fontSize: 10.5, color: 'rgba(148,163,184,0.5)', fontFamily: FONT_TEXT,
        opacity: 0, animation: 'lu-rise 0.6s ease-out 2.6s forwards',
      }}>Chạm để xem lại hiệu ứng</div>

      <style>{`
        @keyframes lu-fade-in { to { opacity: 0.55; } }
        @keyframes lu-spin { to { transform: translate(-50%,-50%) rotate(360deg); } }
        @keyframes lu-ring {
          0% { transform: scale(0.4); opacity: 0.9; }
          80% { opacity: 0; }
          100% { transform: scale(3.2); opacity: 0; }
        }
        @keyframes lu-float {
          0% { transform: translateY(0) translateX(0) rotate(180deg); opacity: 0; }
          12% { opacity: 0.95; }
          100% { transform: translateY(-440px) translateX(var(--drift)) rotate(calc(180deg + var(--rot))); opacity: 0; }
        }
        @keyframes lu-rise {
          0% { opacity: 0; transform: translateY(14px); }
          100% { opacity: 1; transform: translateY(0); }
        }
        @keyframes lu-pop {
          0% { opacity: 0; transform: scale(0.3) rotate(-8deg); }
          70% { opacity: 1; transform: scale(1.08) rotate(2deg); }
          100% { opacity: 1; transform: scale(1) rotate(0deg); }
        }
        @keyframes lu-num {
          0% { transform: translateY(28px) scale(0.4); opacity: 0; }
          100% { transform: translateY(0) scale(1); opacity: 1; }
        }
        @keyframes lu-glow { 0%,100% { opacity: 0.6; } 50% { opacity: 1; } }
        @keyframes lu-chip {
          0% { opacity: 0; transform: translateX(-16px) scale(0.96); }
          100% { opacity: 1; transform: translateX(0) scale(1); }
        }
        @keyframes lu-xpsurge {
          0% { transform: scaleX(0); opacity: 0.9; }
          70% { transform: scaleX(1); opacity: 0.5; }
          100% { transform: scaleX(1); opacity: 0; }
        }
        @keyframes lu-xpfill { 0% { width: 0; } }
        @media (prefers-reduced-motion: reduce) {
          [style*="lu-"] { animation: none !important; opacity: 1 !important; }
        }
      `}</style>
    </div>
  );
}

function RewardGlyph({ kind }) {
  const box = {
    width: 34, height: 34, borderRadius: 9, flexShrink: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
  if (kind === 'coin') {
    return <div style={{ ...box, background: 'rgba(251,191,36,0.16)', border: '1px solid rgba(251,191,36,0.4)' }}>{I.coin(20, 'lu')}</div>;
  }
  if (kind === 'theme') {
    return <div style={{ ...box, background: 'linear-gradient(135deg, #0C4A80, #082F5C)', border: '1px solid rgba(125,211,252,0.4)' }}>{I.drop('#7DD3FC', 18)}</div>;
  }
  // frame
  return (
    <div style={{ ...box, background: 'rgba(165,180,252,0.16)', border: '1px solid rgba(165,180,252,0.45)' }}>
      <div style={{ width: 16, height: 16, borderRadius: '50%', border: '2px solid #A5B4FC' }} />
    </div>
  );
}

window.LevelUpCelebration = LevelUpCelebration;
