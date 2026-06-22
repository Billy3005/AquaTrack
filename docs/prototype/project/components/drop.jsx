// LivingDrop — animated water drop SVG that fills based on hydration %
// Uses clipPath + animated wave path for the water surface

function LivingDrop({ percent = 50, size = 220, label, sublabel, glow = true }) {
  const pct = Math.max(0, Math.min(100, percent));
  const id = React.useId().replace(/:/g, '');

  // Color states
  let fill = '#0EA5E9';
  let secondary = '#38BDF8';
  if (pct < 31) { fill = '#1E3A5F'; secondary = '#2C4F7A'; }
  else if (pct >= 70) { fill = '#38BDF8'; secondary = '#7DD3FC'; }

  const waveY = 100 - pct; // 0% = top of drop empty (waveY=100), 100% = full (waveY=0)
  const dropPath = `M50,5 C50,5 12,55 12,76 C12,96 30,108 50,108 C70,108 88,96 88,76 C88,55 50,5 50,5 Z`;

  // Animated wave (using SMIL <animate>)
  return (
    <div style={{
      position: 'relative', width: size, height: size * 1.13,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {glow && pct >= 70 && (
        <div style={{
          position: 'absolute', inset: -20, borderRadius: '50%',
          background: `radial-gradient(circle, ${secondary}55 0%, transparent 60%)`,
          animation: 'aq-pulse 2.5s ease-in-out infinite',
        }} />
      )}
      <svg width={size} height={size * 1.13} viewBox="0 0 100 113" style={{ position: 'relative', zIndex: 1 }}>
        <defs>
          <clipPath id={`drop-${id}`}>
            <path d={dropPath} />
          </clipPath>
          <linearGradient id={`fill-${id}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={secondary} />
            <stop offset="100%" stopColor={fill} />
          </linearGradient>
          <linearGradient id={`stroke-${id}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgba(255,255,255,0.4)" />
            <stop offset="100%" stopColor="rgba(255,255,255,0.1)" />
          </linearGradient>
        </defs>

        {/* drop outline / vessel */}
        <path d={dropPath} fill="rgba(8,30,56,0.5)" stroke={`url(#stroke-${id})`} strokeWidth="1.2" />

        {/* clipped water content */}
        <g clipPath={`url(#drop-${id})`}>
          {/* base fill */}
          <rect x="0" y={waveY} width="100" height={113 - waveY} fill={`url(#fill-${id})`}>
            <animate attributeName="y" values={`${waveY};${waveY - 1.5};${waveY}`} dur="3.5s" repeatCount="indefinite" />
          </rect>
          {/* wavy surface */}
          <path
            d={`M-20,${waveY} Q10,${waveY - 3} 40,${waveY} T100,${waveY} T160,${waveY} L160,113 L-20,113 Z`}
            fill={secondary}
            opacity="0.55"
          >
            <animate attributeName="d"
              dur="4s" repeatCount="indefinite"
              values={`
                M-20,${waveY} Q10,${waveY - 3} 40,${waveY} T100,${waveY} T160,${waveY} L160,113 L-20,113 Z;
                M-20,${waveY} Q10,${waveY + 3} 40,${waveY} T100,${waveY} T160,${waveY} L160,113 L-20,113 Z;
                M-20,${waveY} Q10,${waveY - 3} 40,${waveY} T100,${waveY} T160,${waveY} L160,113 L-20,113 Z
              `}
            />
          </path>
          {/* second wave */}
          <path
            d={`M-20,${waveY + 2} Q20,${waveY - 1} 50,${waveY + 2} T120,${waveY + 2} T180,${waveY + 2} L180,113 L-20,113 Z`}
            fill={secondary}
            opacity="0.35"
          >
            <animate attributeName="d"
              dur="3.2s" repeatCount="indefinite"
              values={`
                M-20,${waveY + 2} Q20,${waveY + 5} 50,${waveY + 2} T120,${waveY + 2} T180,${waveY + 2} L180,113 L-20,113 Z;
                M-20,${waveY + 2} Q20,${waveY - 1} 50,${waveY + 2} T120,${waveY + 2} T180,${waveY + 2} L180,113 L-20,113 Z;
                M-20,${waveY + 2} Q20,${waveY + 5} 50,${waveY + 2} T120,${waveY + 2} T180,${waveY + 2} L180,113 L-20,113 Z
              `}
            />
          </path>
          {/* highlight bubble */}
          {pct > 35 && (
            <circle cx="38" cy={Math.max(waveY + 12, 30)} r="2.3" fill="white" opacity="0.5" />
          )}
          {pct > 50 && (
            <circle cx="62" cy={Math.max(waveY + 22, 40)} r="1.4" fill="white" opacity="0.4" />
          )}
        </g>

        {/* gloss highlight on drop shell */}
        <path d="M30,30 Q26,55 38,72" stroke="rgba(255,255,255,0.35)" strokeWidth="2" strokeLinecap="round" fill="none" />

        {/* crack overlay if low */}
        {pct < 31 && (
          <g opacity="0.45" stroke="#1E293B" strokeWidth="0.6" fill="none">
            <path d="M55,30 L52,45 L58,55 L54,70" />
            <path d="M40,40 L45,52 L41,62" />
            <path d="M65,55 L70,68" />
          </g>
        )}
      </svg>

      {/* center text */}
      <div style={{
        position: 'absolute', inset: 0, zIndex: 2,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        pointerEvents: 'none',
      }}>
        {label !== undefined && (
          <div style={{
            fontSize: size * 0.22, fontWeight: 600,
            color: 'white',
            letterSpacing: '-0.03em',
            fontFeatureSettings: '"tnum"',
            lineHeight: 1,
            textShadow: '0 2px 8px rgba(0,0,0,0.3)',
          }}>{label}</div>
        )}
        {sublabel && (
          <div style={{
            fontSize: size * 0.06, fontWeight: 500,
            color: 'rgba(255,255,255,0.85)',
            marginTop: 6, letterSpacing: '0.02em',
            textShadow: '0 1px 4px rgba(0,0,0,0.3)',
          }}>{sublabel}</div>
        )}
      </div>
    </div>
  );
}

window.LivingDrop = LivingDrop;
