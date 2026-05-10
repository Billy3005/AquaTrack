// CameraScreen — Smart Scan: AI detects drink type & ml from camera feed
function CameraScreen({ onNavigate, onLog }) {
  // States: scanning → detected → fallback (manual)
  const [phase, setPhase] = React.useState('scanning'); // 'scanning' | 'detected' | 'fallback'
  const [detected, setDetected] = React.useState({
    type: 'coffee',
    name: 'Cà phê đá',
    ml: 200,
    hydrationScore: 60,
    confidence: 92,
  });

  // Simulate scan completion after 2.4s
  React.useEffect(() => {
    if (phase !== 'scanning') return;
    const t = setTimeout(() => setPhase('detected'), 2400);
    return () => clearTimeout(t);
  }, [phase]);

  function rescan() {
    setPhase('scanning');
  }

  return (
    <div style={{
      width: '100%', height: '100%',
      background: '#000', color: 'white',
      fontFamily: FONT, position: 'relative', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Simulated camera feed — moody dark backdrop with subtle gradient + grain */}
      <div style={{
        position: 'absolute', inset: 0, zIndex: 0,
        background: 'radial-gradient(ellipse at 50% 40%, #1F2937 0%, #050810 70%, #000 100%)',
      }}>
        {/* Mock subject — glass of coffee on table */}
        <svg width="100%" height="100%" viewBox="0 0 390 844" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
          {/* table line */}
          <rect x="0" y="560" width="390" height="284" fill="url(#tableGrad)"/>
          <defs>
            <linearGradient id="tableGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#1F2937"/>
              <stop offset="100%" stopColor="#030712"/>
            </linearGradient>
            <linearGradient id="glassGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#1E293B" stopOpacity="0.4"/>
              <stop offset="100%" stopColor="#0F172A" stopOpacity="0.7"/>
            </linearGradient>
          </defs>
          {/* glass */}
          <ellipse cx="195" cy="558" rx="78" ry="14" fill="rgba(0,0,0,0.5)"/>
          <path d="M132,395 L258,395 L248,560 L142,560 Z" fill="url(#glassGrad)" stroke="rgba(255,255,255,0.08)" strokeWidth="1"/>
          {/* coffee */}
          <path d="M138,418 L252,418 L246,555 L144,555 Z" fill="#3F2A1A" opacity="0.85"/>
          <ellipse cx="195" cy="418" rx="57" ry="8" fill="#5B3A20"/>
          {/* highlight */}
          <path d="M148,420 Q150,490 156,550" stroke="rgba(255,255,255,0.06)" strokeWidth="2" fill="none"/>
        </svg>
        {/* grain overlay */}
        <div style={{
          position: 'absolute', inset: 0,
          backgroundImage: 'radial-gradient(circle at 20% 30%, rgba(255,255,255,0.02) 1px, transparent 1px), radial-gradient(circle at 70% 60%, rgba(255,255,255,0.015) 1px, transparent 1px)',
          backgroundSize: '4px 4px, 6px 6px',
          mixBlendMode: 'overlay',
        }} />
      </div>

      {/* Top bar */}
      <div style={{
        position: 'relative', zIndex: 5,
        padding: '54px 16px 12px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <button onClick={() => onNavigate && onNavigate('home')} style={{
          width: 38, height: 38, borderRadius: 999,
          background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255,255,255,0.1)', color: 'white',
          fontSize: 18, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>×</button>
        <div style={{
          background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(10px)',
          border: '1px solid rgba(56,189,248,0.3)',
          borderRadius: 999, padding: '6px 12px',
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 600, fontFamily: FONT_TEXT,
          color: '#BAE6FD', letterSpacing: '0.04em',
        }}>
          {I.spark('#38BDF8', 12)}
          <span>Smart Scan · AI</span>
        </div>
        <button onClick={() => setPhase(phase === 'fallback' ? 'scanning' : 'fallback')} style={{
          width: 38, height: 38, borderRadius: 999,
          background: phase === 'fallback' ? 'rgba(56,189,248,0.25)' : 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255,255,255,0.1)', color: 'white',
          cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="7"/><path d="M21 21 L17 17"/>
          </svg>
        </button>
      </div>

      {/* Scan frame area */}
      {phase !== 'fallback' && (
        <div style={{
          position: 'relative', zIndex: 4,
          flex: 1,
          display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          padding: '20px 16px',
        }}>
          {/* Oval scan frame */}
          <div style={{
            position: 'relative',
            width: 260, height: 340,
          }}>
            {/* corner brackets / oval */}
            <svg width="260" height="340" viewBox="0 0 260 340" style={{ position: 'absolute', inset: 0 }}>
              <defs>
                <linearGradient id="scanRing" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#38BDF8"/>
                  <stop offset="100%" stopColor="#0EA5E9"/>
                </linearGradient>
                <radialGradient id="scanInner">
                  <stop offset="60%" stopColor="rgba(56,189,248,0)"/>
                  <stop offset="100%" stopColor="rgba(56,189,248,0.18)"/>
                </radialGradient>
              </defs>
              {/* outer dim mask is achieved via the page bg; here we draw the ring */}
              <ellipse cx="130" cy="170" rx="120" ry="160" fill="url(#scanInner)" stroke="url(#scanRing)" strokeWidth="2" strokeDasharray="6 5" opacity={phase === 'scanning' ? 1 : 0.5}>
                {phase === 'scanning' && (
                  <animate attributeName="stroke-dashoffset" values="0;-44" dur="1.4s" repeatCount="indefinite"/>
                )}
              </ellipse>
              {/* corner ticks */}
              {[
                [10, 30], [250, 30], [10, 310], [250, 310],
              ].map(([x, y], i) => (
                <g key={i} stroke="#38BDF8" strokeWidth="2.5" strokeLinecap="round" fill="none">
                  <path d={`M${x},${y} ${x < 130 ? `l 18 0 M${x},${y} l 0 ${y < 170 ? 18 : -18}` : `l -18 0 M${x},${y} l 0 ${y < 170 ? 18 : -18}`}`}/>
                </g>
              ))}
            </svg>

            {/* scanning line + drop indicator */}
            {phase === 'scanning' && (
              <>
                <div style={{
                  position: 'absolute', left: 20, right: 20,
                  height: 2,
                  background: 'linear-gradient(90deg, transparent, #38BDF8, transparent)',
                  boxShadow: '0 0 16px rgba(56,189,248,0.8)',
                  animation: 'scan-sweep 2s ease-in-out infinite',
                }} />
                <div style={{
                  position: 'absolute', left: '50%', top: '50%',
                  transform: 'translate(-50%, -50%)',
                  animation: 'scan-pulse 1.4s ease-in-out infinite',
                }}>
                  <LivingDrop percent={70} size={70} glow={false} />
                </div>
              </>
            )}

            {/* Detected check overlay */}
            {phase === 'detected' && (
              <div style={{
                position: 'absolute', left: '50%', top: '50%',
                transform: 'translate(-50%, -50%)',
                width: 56, height: 56, borderRadius: 999,
                background: '#10B981',
                boxShadow: '0 0 24px rgba(16,185,129,0.6)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                animation: 'pop-in 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)',
              }}>
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M5 12 L10 17 L19 7"/>
                </svg>
              </div>
            )}
          </div>

          {/* Status caption */}
          <div style={{
            marginTop: 28,
            background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(12px)',
            border: '1px solid rgba(56,189,248,0.2)',
            borderRadius: 999, padding: '8px 16px',
            fontSize: 13, fontFamily: FONT_TEXT, fontWeight: 500,
            color: phase === 'detected' ? '#86EFAC' : '#BAE6FD',
            display: 'flex', alignItems: 'center', gap: 8,
          }}>
            {phase === 'scanning' ? (
              <>
                <span style={{ width: 6, height: 6, borderRadius: 999, background: '#38BDF8', display: 'inline-block', animation: 'blink 1s infinite' }} />
                Đang quét... giữ camera ổn định
              </>
            ) : (
              <>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="#10B981"><path d="M5 12 L10 17 L19 7" stroke="#10B981" strokeWidth="3" fill="none" strokeLinecap="round"/></svg>
                Đã nhận diện · {detected.confidence}% chắc chắn
              </>
            )}
          </div>
        </div>
      )}

      {/* Fallback search */}
      {phase === 'fallback' && (
        <div style={{
          position: 'relative', zIndex: 4, flex: 1,
          padding: '40px 20px',
        }}>
          <div style={{
            background: 'rgba(15,26,46,0.95)', backdropFilter: 'blur(12px)',
            borderRadius: 16, padding: 16,
            border: '1px solid rgba(56,189,248,0.2)',
          }}>
            <div style={{ fontSize: 12, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 10, fontFamily: FONT_TEXT }}>
              Tìm thủ công
            </div>
            <div style={{
              background: COLORS.nightCard, borderRadius: 12, padding: '10px 14px',
              display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12,
              border: '1px solid rgba(255,255,255,0.06)',
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={COLORS.textMuted} strokeWidth="2" strokeLinecap="round">
                <circle cx="11" cy="11" r="7"/><path d="M21 21 L17 17"/>
              </svg>
              <input placeholder="Nhập tên thức uống..." style={{
                flex: 1, background: 'transparent', border: 'none', outline: 'none',
                color: 'white', fontSize: 14, fontFamily: FONT_TEXT,
              }} />
            </div>
            <div style={{ fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 600 }}>
              Phổ biến
            </div>
            {[
              { type: 'water', name: 'Nước lọc', ml: 250, score: 100 },
              { type: 'tea', name: 'Trà sen', ml: 200, score: 90 },
              { type: 'coffee', name: 'Cà phê đá', ml: 200, score: 60 },
              { type: 'juice', name: 'Nước cam', ml: 220, score: 75 },
            ].map((d, i) => (
              <div key={i} onClick={() => { setDetected({ ...detected, type: d.type, name: d.name, ml: d.ml, hydrationScore: d.score }); setPhase('detected'); }} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '10px 6px',
                borderTop: i ? '1px solid rgba(255,255,255,0.04)' : 'none',
                cursor: 'pointer',
              }}>
                <DrinkIcon type={d.type} size={20} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 500, color: 'white', fontFamily: FONT_TEXT }}>{d.name}</div>
                  <div style={{ fontSize: 11, color: COLORS.textMuted }}>{d.ml}ml · {d.score}% hydration</div>
                </div>
                {I.chevR(COLORS.textMuted, 14)}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Bottom sheet — detection result */}
      {phase === 'detected' && (
        <div style={{
          position: 'relative', zIndex: 6,
          background: 'rgba(11,17,32,0.96)', backdropFilter: 'blur(20px)',
          borderTopLeftRadius: 24, borderTopRightRadius: 24,
          border: '1px solid rgba(56,189,248,0.18)',
          borderBottom: 'none',
          padding: '14px 18px 36px',
          animation: 'sheet-up 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        }}>
          {/* drag handle */}
          <div style={{
            width: 40, height: 4, borderRadius: 999, background: 'rgba(255,255,255,0.2)',
            margin: '0 auto 14px',
          }} />

          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
            <DrinkIcon type={detected.type} size={32} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 17, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT, letterSpacing: '-0.01em' }}>
                {detected.name}
              </div>
              <div style={{ fontSize: 11, color: COLORS.textBright, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
                {I.spark('#38BDF8', 11)} AI · {detected.confidence}% chắc chắn
              </div>
            </div>
            <button onClick={rescan} style={{
              background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: 999, padding: '6px 12px', color: COLORS.textPrimary,
              fontFamily: FONT_TEXT, fontSize: 11.5, cursor: 'pointer',
            }}>Quét lại</button>
          </div>

          {/* Stats grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
            <div style={{
              background: COLORS.nightCard, borderRadius: 12, padding: '12px 14px',
              border: '1px solid rgba(255,255,255,0.04)',
            }}>
              <div style={{ fontSize: 10, color: COLORS.textMuted, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT, marginBottom: 4 }}>
                Lượng ước tính
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em', lineHeight: 1 }}>
                  {detected.ml}
                </div>
                <div style={{ fontSize: 12, color: COLORS.textSecondary }}>ml</div>
              </div>
            </div>
            <div style={{
              background: COLORS.nightCard, borderRadius: 12, padding: '12px 14px',
              border: '1px solid rgba(255,255,255,0.04)',
              position: 'relative', overflow: 'hidden',
            }}>
              <div style={{ fontSize: 10, color: COLORS.textMuted, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT, marginBottom: 4 }}>
                Hydration value
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                <div style={{
                  fontSize: 24, fontWeight: 700,
                  color: detected.hydrationScore >= 90 ? '#86EFAC' : detected.hydrationScore >= 70 ? '#7DD3FC' : '#FCD34D',
                  fontFamily: FONT_ROUND, letterSpacing: '-0.02em', lineHeight: 1,
                }}>
                  {detected.hydrationScore}<span style={{ fontSize: 14, fontWeight: 500, opacity: 0.7 }}>%</span>
                </div>
              </div>
              <div style={{
                marginTop: 8, height: 4, background: 'rgba(255,255,255,0.06)',
                borderRadius: 999, overflow: 'hidden',
              }}>
                <div style={{
                  height: '100%', width: `${detected.hydrationScore}%`,
                  background: detected.hydrationScore >= 90 ? '#10B981' : detected.hydrationScore >= 70 ? '#38BDF8' : '#F59E0B',
                  borderRadius: 999,
                }} />
              </div>
            </div>
          </div>

          {/* Effective contribution callout */}
          {detected.hydrationScore < 90 && (
            <div style={{
              background: 'linear-gradient(135deg, rgba(245,158,11,0.12), rgba(245,158,11,0.04))',
              border: '1px solid rgba(245,158,11,0.3)',
              borderRadius: 12, padding: '10px 12px',
              marginBottom: 14,
              fontSize: 12, color: '#FED7AA', fontFamily: FONT_TEXT, lineHeight: 1.4,
              display: 'flex', gap: 8,
            }}>
              <div style={{ flexShrink: 0 }}>{I.thermo('#F59E0B', 14)}</div>
              <div>
                Đóng góp thực tế: <b style={{ color: '#FED7AA' }}>+{Math.round(detected.ml * detected.hydrationScore / 100)}ml</b> sau khi trừ tác động lợi tiểu của cà phê
              </div>
            </div>
          )}

          {/* Edit + confirm */}
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => onNavigate && onNavigate('log')} style={{
              padding: '14px 18px', borderRadius: 12,
              background: 'rgba(255,255,255,0.06)',
              border: '1px solid rgba(255,255,255,0.1)',
              color: COLORS.textPrimary,
              fontFamily: FONT_TEXT, fontSize: 13.5, fontWeight: 600,
              cursor: 'pointer',
            }}>Sửa lượng</button>
            <button onClick={() => { onLog && onLog(detected.ml); onNavigate && onNavigate('home'); }} style={{
              flex: 1, padding: '14px', borderRadius: 12,
              background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
              border: 'none', color: 'white',
              fontFamily: FONT_TEXT, fontSize: 14, fontWeight: 600,
              cursor: 'pointer',
              boxShadow: '0 6px 16px rgba(14,165,233,0.4)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}>
              <span>Log thức uống này</span>
              <span style={{
                background: 'rgba(255,255,255,0.2)', borderRadius: 999,
                padding: '2px 8px', fontSize: 11, fontFamily: FONT_ROUND, fontWeight: 700,
              }}>+20 XP</span>
            </button>
          </div>
        </div>
      )}

      <style>{`
        @keyframes scan-sweep {
          0% { top: 12%; }
          50% { top: 85%; }
          100% { top: 12%; }
        }
        @keyframes scan-pulse {
          0%, 100% { transform: translate(-50%, -50%) scale(1); opacity: 0.7; }
          50% { transform: translate(-50%, -50%) scale(1.12); opacity: 1; }
        }
        @keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        @keyframes pop-in {
          0% { transform: translate(-50%, -50%) scale(0.3); opacity: 0; }
          100% { transform: translate(-50%, -50%) scale(1); opacity: 1; }
        }
        @keyframes sheet-up {
          0% { transform: translateY(100%); }
          100% { transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}

window.CameraScreen = CameraScreen;
