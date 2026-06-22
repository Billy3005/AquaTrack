// avatar-engine.jsx — parametric water-spirit avatar renderer
// AquaAvatar({ spec, size, silhouette, animate }) draws one evolving
// water creature in a 120×120 field from the app's drop-path DNA.

(function injectAvatarCSS() {
  if (typeof document === 'undefined' || document.getElementById('aqua-av-css')) return;
  const s = document.createElement('style');
  s.id = 'aqua-av-css';
  s.textContent = `
    @keyframes aqav-bob { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-3.5%)} }
    @keyframes aqav-spin { to { transform: rotate(360deg) } }
    @keyframes aqav-twinkle { 0%,100%{opacity:.25;transform:scale(.7)} 50%{opacity:1;transform:scale(1)} }
    @keyframes aqav-wisp { 0%,100%{opacity:.4;transform:translateY(0)} 50%{opacity:.85;transform:translateY(-6%)} }
    @keyframes aqav-glowpulse { 0%,100%{opacity:.55;transform:scale(1)} 50%{opacity:.9;transform:scale(1.06)} }
    @media (prefers-reduced-motion: reduce){
      .aqav-anim,.aqav-anim *{animation:none !important}
    }
  `;
  document.head.appendChild(s);
})();

const DROP_PATH = 'M60,30 C60,30 30,68 30,87 C30,102 43,113 60,113 C77,113 90,102 90,87 C90,68 60,30 60,30 Z';
const FACE_DARK = '#0A1B33';

// ── EYES ────────────────────────────────────────────────────
function Eyes({ style, accent }) {
  const L = 50, R = 70, Y = 81;
  const hl = (cx, cy) => <circle cx={cx} cy={cy} r="1.7" fill="#fff" opacity="0.95" />;
  if (style === 'happy') {
    return (
      <g fill="none" stroke={FACE_DARK} strokeWidth="2.6" strokeLinecap="round">
        <path d={`M${L - 4.5},${Y - 1} Q${L},${Y + 4.5} ${L + 4.5},${Y - 1}`} />
        <path d={`M${R - 4.5},${Y - 1} Q${R},${Y + 4.5} ${R + 4.5},${Y - 1}`} />
      </g>
    );
  }
  if (style === 'cool') {
    return (
      <g>
        <ellipse cx={L} cy={Y} rx="3.7" ry="2.7" fill={FACE_DARK} />
        <ellipse cx={R} cy={Y} rx="3.7" ry="2.7" fill={FACE_DARK} />
        <path d={`M${L - 4.5},${Y - 3.2} h9 M${R - 4.5},${Y - 3.2} h9`} stroke="#fff" strokeOpacity="0.18" strokeWidth="2" strokeLinecap="round" />
        {hl(L + 1.3, Y - 1)}{hl(R + 1.3, Y - 1)}
      </g>
    );
  }
  if (style === 'wise') {
    return (
      <g>
        <ellipse cx={L} cy={Y} rx="3.3" ry="4.2" fill={FACE_DARK} />
        <ellipse cx={R} cy={Y} rx="3.3" ry="4.2" fill={FACE_DARK} />
        <circle cx={L} cy={Y} r="2" fill={accent} opacity="0.9" />
        <circle cx={R} cy={Y} r="2" fill={accent} opacity="0.9" />
        {hl(L + 0.8, Y - 1.6)}{hl(R + 0.8, Y - 1.6)}
      </g>
    );
  }
  if (style === 'fierce') {
    return (
      <g>
        <path d={`M${L - 5},${Y - 2.5} L${L + 4},${Y - 0.5} L${L + 4},${Y + 3} L${L - 4},${Y + 3} Z`} fill={FACE_DARK} />
        <path d={`M${R + 5},${Y - 2.5} L${R - 4},${Y - 0.5} L${R - 4},${Y + 3} L${R + 4},${Y + 3} Z`} fill={FACE_DARK} />
        <circle cx={L} cy={Y + 0.6} r="1.5" fill={accent} />
        <circle cx={R} cy={Y + 0.6} r="1.5" fill={accent} />
        <path d={`M${L - 5},${Y - 5} L${L + 4.5},${Y - 2.8} M${R + 5},${Y - 5} L${R - 4.5},${Y - 2.8}`}
          stroke={FACE_DARK} strokeWidth="2" strokeLinecap="round" />
      </g>
    );
  }
  if (style === 'regal') {
    return (
      <g>
        <path d={`M${L - 4.3},${Y + 1} Q${L - 3},${Y - 4} ${L + 3.2},${Y - 2.6} Q${L + 5},${Y + 1} ${L + 3},${Y + 3} Q${L - 2},${Y + 3.6} ${L - 4.3},${Y + 1} Z`} fill={FACE_DARK} />
        <path d={`M${R + 4.3},${Y + 1} Q${R + 3},${Y - 4} ${R - 3.2},${Y - 2.6} Q${R - 5},${Y + 1} ${R - 3},${Y + 3} Q${R + 2},${Y + 3.6} ${R + 4.3},${Y + 1} Z`} fill={FACE_DARK} />
        {hl(L + 1.4, Y - 1.2)}{hl(R - 1.4, Y - 1.2)}
      </g>
    );
  }
  // cute (default) — big round eyes
  return (
    <g>
      <ellipse cx={L} cy={Y} rx="4.1" ry="5" fill={FACE_DARK} />
      <ellipse cx={R} cy={Y} rx="4.1" ry="5" fill={FACE_DARK} />
      {hl(L + 1.4, Y - 1.7)}{hl(R + 1.4, Y - 1.7)}
      <circle cx={L - 1.4} cy={Y + 2} r="0.9" fill="#fff" opacity="0.7" />
      <circle cx={R - 1.4} cy={Y + 2} r="0.9" fill="#fff" opacity="0.7" />
    </g>
  );
}

function Mouth({ style }) {
  const Y = 92;
  if (style === 'open') {
    return <path d={`M55.5,${Y} Q60,${Y + 1.4} 64.5,${Y} Q63,${Y + 7} 60,${Y + 7} Q57,${Y + 7} 55.5,${Y} Z`} fill="#13314F" />;
  }
  if (style === 'smirk') {
    return <path d={`M54,${Y + 1.5} Q60,${Y + 4} 67,${Y - 1}`} fill="none" stroke={FACE_DARK} strokeWidth="2" strokeLinecap="round" />;
  }
  if (style === 'calm') {
    return <path d={`M55.5,${Y + 1} Q60,${Y + 3.2} 64.5,${Y + 1}`} fill="none" stroke={FACE_DARK} strokeWidth="1.9" strokeLinecap="round" />;
  }
  // smile
  return <path d={`M54,${Y} Q60,${Y + 6} 66,${Y}`} fill="none" stroke={FACE_DARK} strokeWidth="2.1" strokeLinecap="round" />;
}

// ── FEATURES (geometric primitives) ─────────────────────────
function backFeatures(s, uid) {
  const f = s.features || [];
  const a = s.accent, b = s.body;
  const out = [];
  if (f.includes('fins')) {
    out.push(
      <g key="fins" fill={b[1]} opacity="0.9">
        <path d="M31,78 Q18,74 14,82 Q22,84 31,88 Z" />
        <path d="M89,78 Q102,74 106,82 Q98,84 89,88 Z" />
      </g>
    );
  }
  if (f.includes('wings')) {
    out.push(
      <g key="wings">
        <path d="M33,72 Q8,60 4,86 Q16,80 24,86 Q14,82 33,84 Z" fill={s.accent} opacity="0.55" />
        <path d="M87,72 Q112,60 116,86 Q104,80 96,86 Q106,82 87,84 Z" fill={s.accent} opacity="0.55" />
        <path d="M33,74 Q14,66 9,84 Q19,79 27,84 Z" fill="#fff" opacity="0.25" />
        <path d="M87,74 Q106,66 111,84 Q101,79 93,84 Z" fill="#fff" opacity="0.25" />
      </g>
    );
  }
  if (f.includes('horns')) {
    out.push(
      <g key="horns" fill={s.accent}>
        <path d="M44,40 Q34,24 30,12 Q42,20 48,36 Z" />
        <path d="M76,40 Q86,24 90,12 Q78,20 72,36 Z" />
        <path d="M44,40 Q37,28 33,18 Q40,24 47,37 Z" fill="#fff" opacity="0.3" />
      </g>
    );
  }
  if (f.includes('halo')) {
    out.push(
      <g key="halo" className="aqav-anim">
        <ellipse cx="60" cy="26" rx="26" ry="8" fill="none" stroke={s.aura || a} strokeWidth="3"
          opacity="0.85" style={{ filter: `drop-shadow(0 0 6px ${s.aura || a})` }} />
        <ellipse cx="60" cy="26" rx="26" ry="8" fill="none" stroke="#fff" strokeWidth="1" opacity="0.6" />
      </g>
    );
  }
  if (f.includes('speed')) {
    out.push(
      <g key="speed" stroke={s.rim} strokeWidth="2.4" strokeLinecap="round" opacity="0.55">
        <path d="M14,72 h12" /><path d="M10,82 h16" /><path d="M16,92 h10" />
      </g>
    );
  }
  if (f.includes('ribbon')) {
    out.push(
      <path key="ribbonb" d="M26,86 Q40,76 60,82 Q80,88 96,80" fill="none"
        stroke={s.accent} strokeWidth="5" strokeLinecap="round" opacity="0.55" />
    );
  }
  if (f.includes('wisps')) {
    out.push(
      <g key="wisps" className="aqav-anim" fill={s.aura || a} opacity="0.6">
        <path d="M26,64 q-6,-6 -2,-12 q6,4 2,12 Z" style={{ animation: 'aqav-wisp 3s ease-in-out infinite' }} />
        <path d="M94,64 q6,-6 2,-12 q-6,4 -2,12 Z" style={{ animation: 'aqav-wisp 3.4s ease-in-out infinite .4s' }} />
      </g>
    );
  }
  return out;
}

function frontFeatures(s, uid) {
  const f = s.features || [];
  const out = [];
  if (f.includes('leaf')) {
    out.push(
      <g key="leaf">
        <path d="M60,32 Q58,18 50,12 Q54,24 58,32 Z" fill="#34D399" />
        <path d="M60,32 Q63,20 72,16 Q66,26 62,33 Z" fill="#10B981" />
        <path d="M50,12 Q55,22 59,31" stroke="#A7F3D0" strokeWidth="0.8" fill="none" opacity="0.7" />
      </g>
    );
  }
  if (f.includes('quiff')) {
    out.push(
      <path key="quiff" d="M60,30 Q50,18 60,12 Q66,18 72,16 Q70,26 62,34 Z" fill={s.rim} />
    );
  }
  if (f.includes('wavecrest')) {
    out.push(
      <g key="wave" fill={s.rim}>
        <path d="M48,34 Q46,20 56,16 Q54,24 58,32 Z" />
        <path d="M58,32 Q58,16 70,14 Q66,22 66,30 Z" />
        <path d="M64,31 Q68,20 78,20 Q72,27 70,33 Z" />
      </g>
    );
  }
  if (f.includes('whiskers')) {
    out.push(
      <g key="whisk" className="aqav-anim" stroke={s.accent} strokeWidth="1.8" strokeLinecap="round" fill="none" opacity="0.9">
        <path d="M34,86 Q18,84 10,90" style={{ animation: 'aqav-wisp 3.2s ease-in-out infinite' }} />
        <path d="M86,86 Q102,84 110,90" style={{ animation: 'aqav-wisp 3.2s ease-in-out infinite .3s' }} />
      </g>
    );
  }
  if (f.includes('fangs')) {
    out.push(
      <g key="fangs" fill="#fff">
        <path d="M56.5,95 l1.2,4 l1.2,-4 Z" />
        <path d="M61.1,95 l1.2,4 l1.2,-4 Z" />
      </g>
    );
  }
  if (f.includes('gem')) {
    out.push(
      <g key="gem" className="aqav-anim">
        <path d="M60,56 l4.5,4 l-4.5,5.5 l-4.5,-5.5 Z" fill={s.accent}
          style={{ filter: `drop-shadow(0 0 4px ${s.accent})` }} />
        <path d="M60,56 l4.5,4 l-4.5,2 l-4.5,-2 Z" fill="#fff" opacity="0.7" />
      </g>
    );
  }
  if (f.includes('crown')) {
    out.push(<Crown key="crown" grand={false} accent={s.accent} />);
  }
  if (f.includes('crown_grand')) {
    out.push(<Crown key="crowng" grand={true} accent={s.accent} />);
  }
  if (f.includes('dew')) {
    out.push(
      <g key="dew" className="aqav-anim" fill={s.rim}>
        <circle cx="30" cy="48" r="2.4" opacity="0.85" style={{ animation: 'aqav-twinkle 2.6s ease-in-out infinite' }} />
        <circle cx="92" cy="56" r="2" opacity="0.8" style={{ animation: 'aqav-twinkle 2.6s ease-in-out infinite .8s' }} />
        <circle cx="86" cy="38" r="1.5" opacity="0.7" style={{ animation: 'aqav-twinkle 2.6s ease-in-out infinite 1.4s' }} />
      </g>
    );
  }
  return out;
}

function Crown({ grand, accent }) {
  const gold = '#FBBF24', goldHi = '#FDE68A', goldLo = '#B45309';
  if (grand) {
    return (
      <g>
        <path d="M40,38 L40,24 L48,32 L54,18 L60,30 L66,18 L72,32 L80,24 L80,38 Z" fill={gold} stroke={goldLo} strokeWidth="0.8" strokeLinejoin="round" />
        <rect x="40" y="37" width="40" height="6" rx="2" fill={gold} stroke={goldLo} strokeWidth="0.6" />
        <path d="M40,38 L40,24 L48,32 L54,18 L60,30 L66,18 L72,32 L80,24 L80,38 Z" fill={goldHi} opacity="0.35" />
        <circle cx="54" cy="22" r="1.6" fill="#EF4444" /><circle cx="60" cy="33" r="1.8" fill={accent} /><circle cx="66" cy="22" r="1.6" fill="#22D3EE" />
        <rect x="42" y="39" width="36" height="1.4" fill={goldHi} opacity="0.8" />
      </g>
    );
  }
  return (
    <g>
      <path d="M44,38 L44,26 L52,33 L60,22 L68,33 L76,26 L76,38 Z" fill={gold} stroke={goldLo} strokeWidth="0.8" strokeLinejoin="round" />
      <path d="M44,38 L44,26 L52,33 L60,22 L68,33 L76,26 L76,38 Z" fill={goldHi} opacity="0.35" />
      <circle cx="60" cy="27" r="1.8" fill={accent} />
      <circle cx="48" cy="28" r="1.1" fill="#fff" opacity="0.8" /><circle cx="72" cy="28" r="1.1" fill="#fff" opacity="0.8" />
    </g>
  );
}

// ── MAIN ────────────────────────────────────────────────────
function AquaAvatar({ spec, size = 120, silhouette = false, animate = false, style = {} }) {
  const uid = React.useId().replace(/:/g, '');
  const s = silhouette
    ? { ...spec, body: ['#2C4566', '#0F1E36'], rim: '#3A5C84', accent: '#3A5C84', aura: null, features: [], blush: false }
    : spec;
  const tier = (window.AQUA_TIERS && window.AQUA_TIERS[spec.tier]) || {};

  return (
    <div className={animate ? 'aqav-anim' : ''} style={{ position: 'relative', width: size, height: size, ...style }}>
      {/* aura glow behind */}
      {!silhouette && s.aura && (
        <>
          <div style={{
            position: 'absolute', inset: '-14%', borderRadius: '50%',
            background: `radial-gradient(circle, ${s.aura}66 0%, transparent 62%)`,
            animation: animate ? 'aqav-glowpulse 3s ease-in-out infinite' : 'none',
          }} />
          {animate && (
            <div style={{
              position: 'absolute', inset: '-8%', borderRadius: '50%',
              background: `conic-gradient(from 0deg, transparent, ${s.aura}, transparent 55%)`,
              WebkitMaskImage: 'radial-gradient(closest-side, transparent 63%, #000 65%, #000 80%, transparent 82%)',
              maskImage: 'radial-gradient(closest-side, transparent 63%, #000 65%, #000 80%, transparent 82%)',
              animation: 'aqav-spin 9s linear infinite', opacity: 0.8,
            }} />
          )}
        </>
      )}
      <div style={{ position: 'relative', width: '100%', height: '100%',
        animation: animate ? 'aqav-bob 4s ease-in-out infinite' : 'none' }}>
        <svg viewBox="0 0 120 120" width="100%" height="100%" style={{ overflow: 'visible', display: 'block' }}>
          <defs>
            <linearGradient id={`body-${uid}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={s.body[0]} />
              <stop offset="100%" stopColor={s.body[1]} />
            </linearGradient>
            <radialGradient id={`sheen-${uid}`} cx="38%" cy="34%" r="55%">
              <stop offset="0%" stopColor="#fff" stopOpacity="0.5" />
              <stop offset="100%" stopColor="#fff" stopOpacity="0" />
            </radialGradient>
          </defs>

          {backFeatures(s, uid)}

          {/* body */}
          <path d={DROP_PATH} fill={`url(#body-${uid})`} stroke={s.rim} strokeWidth="1.4" />
          {/* depth shadow at bottom */}
          <path d="M30,87 C30,102 43,113 60,113 C77,113 90,102 90,87 C84,98 72,103 60,103 C48,103 36,98 30,87 Z"
            fill={s.body[1]} opacity={silhouette ? 0.4 : 0.55} />
          {/* top sheen */}
          <ellipse cx="50" cy="58" rx="20" ry="26" fill={`url(#sheen-${uid})`} />
          {/* gloss streak */}
          <path d="M45,46 Q38,60 46,74" stroke="#fff" strokeWidth="2.6" strokeLinecap="round" fill="none" opacity={silhouette ? 0.15 : 0.45} />

          {!silhouette && (
            <>
              {s.blush && (
                <g fill="#FB7185" opacity="0.4">
                  <ellipse cx="44" cy="89" rx="4" ry="2.4" />
                  <ellipse cx="76" cy="89" rx="4" ry="2.4" />
                </g>
              )}
              <Eyes style={s.eyes} accent={s.accent} />
              <Mouth style={s.mouth} />
              {frontFeatures(s, uid)}
            </>
          )}

          {silhouette && (
            <text x="60" y="92" textAnchor="middle" fontSize="22" fontWeight="800"
              fill={s.rim} opacity="0.7" fontFamily="system-ui">?</text>
          )}
        </svg>
      </div>

      {/* twinkle particles for high tiers */}
      {!silhouette && (s.features || []).includes('particles') && animate && (
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {[[10, 20], [90, 14], [16, 80], [88, 74], [50, 6]].map(([x, y], i) => (
            <svg key={i} viewBox="0 0 24 24" width="11" height="11" style={{
              position: 'absolute', left: `${x}%`, top: `${y}%`,
              fill: s.accent, animation: `aqav-twinkle ${2 + i * 0.3}s ease-in-out infinite ${i * 0.4}s`,
              filter: `drop-shadow(0 0 3px ${s.accent})`,
            }}>
              <path d="M12 2 L13.5 9 L20 11 L13.5 13 L12 20 L10.5 13 L4 11 L10.5 9 Z" />
            </svg>
          ))}
        </div>
      )}
    </div>
  );
}

// circular framed bubble (profile-style ring)
function AvatarBubble({ spec, size = 76, silhouette = false, ring = true, animate = false }) {
  const tier = (window.AQUA_TIERS && window.AQUA_TIERS[spec.tier]) || { ring: ['#64748B', '#94A3B8'], glow: 'rgba(148,163,184,0.3)' };
  const ringBg = silhouette ? 'rgba(255,255,255,0.1)' : `conic-gradient(from 210deg, ${tier.ring.join(', ')})`;
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%', padding: ring ? size * 0.045 : 0,
      background: ringBg,
      boxShadow: silhouette ? 'none' : `0 0 ${size * 0.28}px ${tier.glow}`,
      flexShrink: 0,
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: '50%',
        background: silhouette
          ? 'radial-gradient(circle at 50% 40%, #16243C, #0B1322)'
          : 'radial-gradient(circle at 50% 38%, #14365C, #081325)',
        border: '2px solid #0B1120', overflow: 'hidden',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <AquaAvatar spec={spec} size={size * 0.92} silhouette={silhouette} animate={animate} />
      </div>
    </div>
  );
}

window.AquaAvatar = AquaAvatar;
window.AvatarBubble = AvatarBubble;
