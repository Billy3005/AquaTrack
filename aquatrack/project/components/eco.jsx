// EcosystemScreen — body as a hydration ecosystem map
function EcosystemScreen({ current, goal, onNavigate }) {
  const pct = Math.round((current / goal) * 100);
  const dehydrated = pct < 40;
  const fullyHydrated = pct >= 90;

  // Organ colors interpolate based on hydration
  const organColor = (lowC, highC) => {
    const t = Math.min(1, pct / 100);
    return mix(lowC, highC, t);
  };

  function mix(a, b, t) {
    const ax = parseInt(a.slice(1), 16); const bx = parseInt(b.slice(1), 16);
    const ar = (ax >> 16) & 255, ag = (ax >> 8) & 255, ab = ax & 255;
    const br = (bx >> 16) & 255, bg = (bx >> 8) & 255, bb = bx & 255;
    const r = Math.round(ar + (br - ar) * t);
    const g = Math.round(ag + (bg - ag) * t);
    const b2 = Math.round(ab + (bb - ab) * t);
    return `rgb(${r},${g},${b2})`;
  }

  const brain = organColor('#064E3B', '#10B981');
  const kidney = organColor('#0C3A5E', '#0EA5E9');
  const heart = organColor('#4A1B0C', '#EF4444');
  const skin = organColor('#1C1040', '#A78BFA');

  const mapBg = dehydrated
    ? 'radial-gradient(ellipse at center, #92400E, #451A03)'
    : fullyHydrated
    ? 'radial-gradient(ellipse at center, #075985, #0C2A4A)'
    : 'radial-gradient(ellipse at center, #0F2A4A, #0B1933)';

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{ padding: '54px 20px 12px' }}>
        <div style={{
          fontSize: 11, color: COLORS.textBright, fontWeight: 600,
          letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 4,
          fontFamily: FONT_TEXT,
        }}>Hệ sinh thái cơ thể</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <div style={{ fontSize: 26, fontWeight: 600, color: 'white', letterSpacing: '-0.02em' }}>
            {dehydrated ? 'Hệ sinh thái khô hạn' : fullyHydrated ? 'Hệ sinh thái nở rộ' : 'Đang phục hồi'}
          </div>
        </div>
        <div style={{ fontSize: 13, color: COLORS.textSecondary, marginTop: 4, fontFamily: FONT_TEXT }}>
          {dehydrated ? 'Các cơ quan đang cần nước. Bù 500ml ngay nhé.' :
            fullyHydrated ? 'Tuyệt vời — mọi cơ quan đều khỏe mạnh.' :
            'Tiếp tục uống đều để đánh thức từng cơ quan.'}
        </div>
      </div>

      {/* Body map */}
      <div style={{ padding: '0 16px', flex: 1, overflow: 'auto' }}>
        <div style={{
          background: mapBg,
          borderRadius: 20,
          border: '1px solid rgba(56,189,248,0.15)',
          padding: 20,
          height: 380,
          position: 'relative',
          overflow: 'hidden',
          marginBottom: 20,
        }}>
          {/* Environment badge */}
          <div style={{
            position: 'absolute', top: 14, left: 14,
            background: 'rgba(0,0,0,0.4)',
            backdropFilter: 'blur(10px)',
            border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: 999, padding: '5px 10px',
            display: 'flex', alignItems: 'center', gap: 5,
            fontSize: 10.5, fontFamily: FONT_TEXT, fontWeight: 500,
            color: '#FBBF24',
          }}>
            {I.thermo('#FBBF24', 12)} HCMC · 34°C
          </div>

          {/* Hydration % readout */}
          <div style={{
            position: 'absolute', top: 14, right: 14,
            textAlign: 'right',
          }}>
            <div style={{
              fontSize: 28, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND,
              letterSpacing: '-0.03em', lineHeight: 1,
            }}>{pct}<span style={{ fontSize: 14, color: 'rgba(255,255,255,0.6)' }}>%</span></div>
            <div style={{ fontSize: 9.5, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.06em', textTransform: 'uppercase', marginTop: 2 }}>
              hydration
            </div>
          </div>

          {/* Particle bubbles when hydrated */}
          {fullyHydrated && (
            <>
              {[...Array(8)].map((_, i) => (
                <div key={i} style={{
                  position: 'absolute',
                  left: `${10 + (i * 11) % 80}%`,
                  bottom: 10,
                  width: 4 + (i % 3) * 2, height: 4 + (i % 3) * 2,
                  borderRadius: 999,
                  background: 'rgba(125,211,252,0.5)',
                  animation: `aq-bubble ${4 + (i % 3)}s ease-in infinite`,
                  animationDelay: `${i * 0.4}s`,
                }} />
              ))}
            </>
          )}

          {/* Body silhouette + organ nodes (SVG) */}
          <svg viewBox="0 0 320 320" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
            <defs>
              <linearGradient id="silh" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="rgba(255,255,255,0.08)"/>
                <stop offset="100%" stopColor="rgba(255,255,255,0.02)"/>
              </linearGradient>
              <radialGradient id="nodeGlow">
                <stop offset="0%" stopColor="rgba(56,189,248,0.5)"/>
                <stop offset="100%" stopColor="transparent"/>
              </radialGradient>
            </defs>

            {/* dashed environment line */}
            <line x1="60" y1="55" x2="160" y2="100" stroke="rgba(251,191,36,0.4)" strokeWidth="1" strokeDasharray="3 3"/>

            {/* silhouette */}
            <g fill="url(#silh)" stroke="rgba(255,255,255,0.18)" strokeWidth="1">
              {/* head */}
              <circle cx="160" cy="100" r="26"/>
              {/* neck */}
              <rect x="153" y="120" width="14" height="14"/>
              {/* torso */}
              <path d="M125,140 Q120,135 130,134 L190,134 Q200,135 195,140 L210,210 Q200,232 160,232 Q120,232 110,210 z"/>
              {/* arms */}
              <path d="M125,142 L100,200 L96,260 L106,262 L114,205 L130,160" />
              <path d="M195,142 L220,200 L224,260 L214,262 L206,205 L190,160"/>
              {/* legs */}
              <path d="M138,232 L132,300 L144,302 L150,232" />
              <path d="M182,232 L188,300 L176,302 L170,232"/>
            </g>

            {/* crack overlay if dehydrated */}
            {dehydrated && (
              <g stroke="#7C2D12" strokeWidth="1" fill="none" opacity="0.6">
                <path d="M160,150 L162,180 L155,210 M158,160 L150,185"/>
                <path d="M155,260 L160,290"/>
              </g>
            )}

            {/* organ nodes */}
            {/* Brain */}
            <g>
              <line x1="160" y1="100" x2="80" y2="60" stroke={dehydrated ? '#EF4444' : 'rgba(255,255,255,0.2)'} strokeWidth="1" strokeDasharray={dehydrated ? '2 3' : '0'} />
              <circle cx="80" cy="60" r="22" fill={brain} stroke="rgba(255,255,255,0.3)" strokeWidth="1.2" />
              {fullyHydrated && <circle cx="80" cy="60" r="30" fill="url(#nodeGlow)"/>}
              <text x="80" y="64" textAnchor="middle" fontFamily="-apple-system" fontSize="10" fontWeight="600" fill="white">Não</text>
            </g>
            {/* Kidney */}
            <g>
              <line x1="170" y1="190" x2="245" y2="60" stroke={dehydrated ? '#EF4444' : 'rgba(255,255,255,0.2)'} strokeWidth="1" strokeDasharray={dehydrated ? '2 3' : '0'} />
              <circle cx="245" cy="60" r="22" fill={kidney} stroke="rgba(255,255,255,0.3)" strokeWidth="1.2" />
              {fullyHydrated && <circle cx="245" cy="60" r="30" fill="url(#nodeGlow)"/>}
              <text x="245" y="64" textAnchor="middle" fontFamily="-apple-system" fontSize="10" fontWeight="600" fill="white">Thận</text>
            </g>
            {/* Heart */}
            <g>
              <line x1="160" y1="170" x2="68" y2="180" stroke={dehydrated ? '#EF4444' : 'rgba(255,255,255,0.2)'} strokeWidth="1" strokeDasharray={dehydrated ? '2 3' : '0'} />
              <circle cx="68" cy="180" r="22" fill={heart} stroke="rgba(255,255,255,0.3)" strokeWidth="1.2" />
              <text x="68" y="184" textAnchor="middle" fontFamily="-apple-system" fontSize="10" fontWeight="600" fill="white">Tim</text>
            </g>
            {/* Skin */}
            <g>
              <line x1="180" y1="220" x2="255" y2="200" stroke={dehydrated ? '#EF4444' : 'rgba(255,255,255,0.2)'} strokeWidth="1" strokeDasharray={dehydrated ? '2 3' : '0'} />
              <circle cx="255" cy="200" r="22" fill={skin} stroke="rgba(255,255,255,0.3)" strokeWidth="1.2" />
              <text x="255" y="204" textAnchor="middle" fontFamily="-apple-system" fontSize="10" fontWeight="600" fill="white">Da</text>
            </g>
          </svg>

          {/* Caption */}
          <div style={{
            position: 'absolute', bottom: 14, left: 14, right: 14,
            fontSize: 11, color: 'rgba(255,255,255,0.6)',
            fontFamily: FONT_TEXT, fontStyle: 'italic',
            textAlign: 'center',
          }}>
            “Uống đủ nước → hệ sinh thái phát triển”
          </div>
        </div>

        {/* Organ stat cards */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 16 }}>
          <OrganCard name="Não" status={dehydrated ? 'Mệt mỏi' : fullyHydrated ? 'Tỉnh táo' : 'Ổn định'} pct={Math.min(100, pct + 8)} color={brain} icon={I.brain('white', 18)} />
          <OrganCard name="Thận" status={dehydrated ? 'Quá tải' : fullyHydrated ? 'Hoạt động tốt' : 'Bình thường'} pct={pct} color={kidney} icon={I.kidney('white', 18)} />
          <OrganCard name="Tim" status={dehydrated ? 'Đập nhanh' : fullyHydrated ? 'Khỏe mạnh' : 'Đều'} pct={Math.max(20, pct - 5)} color={heart} icon={I.heart('white', 18)} />
          <OrganCard name="Da" status={dehydrated ? 'Khô' : fullyHydrated ? 'Mịn' : 'Đang phục hồi'} pct={Math.max(10, pct - 12)} color={skin} icon={
            <svg width="18" height="18" viewBox="0 0 24 24" fill="white"><path d="M12 3 C8 3 5 6 5 10 V18 a2 2 0 0 0 2 2 H17 a2 2 0 0 0 2-2 V10 C19 6 16 3 12 3 z"/></svg>
          } />
        </div>

        <div style={{ height: 12 }} />
      </div>

      <BottomTabBar active="eco" onNavigate={onNavigate} />

      <style>{`
        @keyframes aq-bubble {
          0% { transform: translateY(0) scale(1); opacity: 0; }
          20% { opacity: 1; }
          100% { transform: translateY(-300px) scale(0.5); opacity: 0; }
        }
      `}</style>
    </div>
  );
}

function OrganCard({ name, status, pct, color, icon }) {
  return (
    <div style={{
      background: COLORS.nightSurface,
      border: '1px solid rgba(56,189,248,0.12)',
      borderRadius: 14,
      padding: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
        <div style={{
          width: 28, height: 28, borderRadius: 8, background: color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{icon}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, fontFamily: FONT_TEXT }}>{name}</div>
          <div style={{ fontSize: 10, color: COLORS.textMuted }}>{status}</div>
        </div>
      </div>
      <div style={{ height: 4, background: 'rgba(255,255,255,0.06)', borderRadius: 999, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 999 }} />
      </div>
    </div>
  );
}

window.EcosystemScreen = EcosystemScreen;
