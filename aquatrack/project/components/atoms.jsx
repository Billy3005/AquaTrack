// Shared UI atoms used across screens

const COLORS = {
  primary: '#0EA5E9',
  glow: '#38BDF8',
  deep: '#0284C7',
  heroDeep: '#0C4A80',
  heroDeeper: '#082F5C',
  nightBase: '#0B1120',
  nightSurface: '#0F1A2E',
  nightCard: '#1E293B',
  nightCardSoft: '#172033',
  border: 'rgba(56,189,248,0.15)',
  borderActive: '#38BDF8',
  green: '#059669',
  purple: '#818CF8',
  purpleDeep: '#4F46E5',
  amber: '#F59E0B',
  textPrimary: '#F1F5F9',
  textSecondary: '#94A3B8',
  textMuted: '#64748B',
  textBright: '#BAE6FD',
};

const FONT = '"SF Pro Display", -apple-system, "SF Pro", "Helvetica Neue", system-ui, sans-serif';
const FONT_TEXT = '"SF Pro Text", -apple-system, "Helvetica Neue", system-ui, sans-serif';
const FONT_ROUND = '"SF Pro Rounded", "SF Pro Text", -apple-system, system-ui, sans-serif';

// Tiny inline icons (24x24 stroke icons)
const I = {
  drop: (c = 'currentColor', s = 20) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3 C12 3 5 11 5 16 C5 19.866 8.134 23 12 23 C15.866 23 19 19.866 19 16 C19 11 12 3 12 3 Z" fill={c} fillOpacity="0.15"/>
    </svg>
  ),
  flame: (c = '#F97316', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 2 C12 6 8 7 8 12 C8 16 9.5 19 12 19 C14.5 19 16 16 16 12 C16 9 14 8 14 5 C14 4 13 3 12 2 Z" fill={c}/>
      <path d="M12 9 C12 11 10 12 10 14 C10 16 11 17 12 17 C13 17 14 16 14 14 C14 12 12 11 12 9 Z" fill="#FBBF24"/>
    </svg>
  ),
  bolt: (c = 'currentColor', s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M13 2 L4 14 L11 14 L11 22 L20 10 L13 10 Z"/>
    </svg>
  ),
  spark: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M12 2 L13.5 9 L20 11 L13.5 13 L12 20 L10.5 13 L4 11 L10.5 9 Z"/>
    </svg>
  ),
  plus: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round">
      <path d="M12 5 L12 19 M5 12 L19 12"/>
    </svg>
  ),
  thermo: (c = '#FBBF24', s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round">
      <path d="M14 14 V5 a2 2 0 0 0-4 0 V14 a3 3 0 1 0 4 0 z"/>
      <circle cx="12" cy="17" r="1.2" fill={c}/>
    </svg>
  ),
  chevR: (c = 'currentColor', s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 6 L15 12 L9 18"/>
    </svg>
  ),
  brain: (c = 'currentColor', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <path d="M9 4 a3 3 0 0 0-3 3 a3 3 0 0 0-2 5 a3 3 0 0 0 2 5 a3 3 0 0 0 3 3 V4 z" fill={c} fillOpacity="0.15"/>
      <path d="M15 4 a3 3 0 0 1 3 3 a3 3 0 0 1 2 5 a3 3 0 0 1-2 5 a3 3 0 0 1-3 3 V4 z" fill={c} fillOpacity="0.15"/>
    </svg>
  ),
  heart: (c = 'currentColor', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M12 21 C 12 21 4 14 4 9 C 4 6 6 4 8.5 4 C 10 4 11.5 5 12 6 C 12.5 5 14 4 15.5 4 C 18 4 20 6 20 9 C 20 14 12 21 12 21 Z"/>
    </svg>
  ),
  kidney: (c = 'currentColor', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M8 4 C5 4 3 7 3 12 C3 17 5 20 8 20 C 10 20 11 18 11 16 C11 13 9 12 9 10 C9 8 11 7 11 6 C11 5 10 4 8 4 Z"/>
    </svg>
  ),
  send: (c = 'currentColor', s = 20) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M3 11 L21 3 L13 21 L11 13 Z"/>
    </svg>
  ),
  wave: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round">
      <path d="M2 12 Q5 8 8 12 T14 12 T20 12 T26 12"/>
      <path d="M2 16 Q5 12 8 16 T14 16 T20 16 T26 16"/>
    </svg>
  ),
  trophy: (c = '#F59E0B', s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M6 4 H18 V8 a4 4 0 0 1-4 4 H10 a4 4 0 0 1-4-4 V4 z"/>
      <path d="M3 5 H6 V9 a3 3 0 0 1-3 0 V5 z M18 5 H21 V9 a3 3 0 0 1-3 0 V5 z" fill={c} fillOpacity="0.6"/>
      <path d="M9 13 H15 V16 H9 z M8 17 H16 V19 H8 z" />
    </svg>
  ),
};

// XP Bar
function XPBar({ xp, xpMax, level, levelName, accent = COLORS.purple, trackBg = '#312E81', height = 8 }) {
  const pct = Math.min(100, (xp / xpMax) * 100);
  return (
    <div>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
        marginBottom: 6, fontFamily: FONT_TEXT,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 11, fontWeight: 600, color: accent, fontFamily: FONT_ROUND, letterSpacing: '0.04em' }}>
            LV {level}
          </span>
          <span style={{ fontSize: 11, color: COLORS.textSecondary }}>· {levelName}</span>
        </div>
        <div style={{ fontSize: 10, color: COLORS.textMuted, fontFeatureSettings: '"tnum"' }}>
          {xp} / {xpMax} XP
        </div>
      </div>
      <div style={{
        height, background: trackBg, borderRadius: height / 2, overflow: 'hidden', position: 'relative',
      }}>
        <div style={{
          height: '100%', width: `${pct}%`,
          background: `linear-gradient(90deg, ${accent}, #A5B4FC)`,
          borderRadius: height / 2,
          boxShadow: `0 0 12px ${accent}88`,
          transition: 'width 0.6s ease-out',
        }} />
      </div>
    </div>
  );
}

// Streak Badge
function StreakBadge({ days = 12, compact = false }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: compact ? '4px 10px' : '6px 12px',
      background: 'rgba(249,115,22,0.15)',
      border: '1px solid rgba(249,115,22,0.35)',
      borderRadius: 999,
      fontFamily: FONT_ROUND, fontSize: compact ? 11 : 12, fontWeight: 600,
      color: '#FED7AA',
    }}>
      {I.flame('#F97316', compact ? 12 : 14)}
      <span>Streak {days} ngày</span>
    </div>
  );
}

// Quick tap chip
function QuickChip({ amount, active, onClick, custom = false }) {
  return (
    <button onClick={onClick} style={{
      flex: 1,
      height: 56,
      borderRadius: 10,
      border: active ? `1.5px solid ${COLORS.borderActive}` : '1px solid rgba(56,189,248,0.18)',
      background: active ? '#0C3F6A' : 'rgba(15,26,46,0.6)',
      color: active ? '#E0F2FE' : COLORS.textPrimary,
      fontFamily: FONT_ROUND, fontWeight: 600,
      fontSize: 14, letterSpacing: '-0.01em',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      gap: 4,
      cursor: 'pointer',
      transition: 'all 0.18s ease',
      boxShadow: active ? `0 0 0 4px rgba(56,189,248,0.12), inset 0 1px 0 rgba(255,255,255,0.05)` : 'inset 0 1px 0 rgba(255,255,255,0.04)',
    }}>
      {custom ? (
        <>{I.plus('#94A3B8', 14)}<span style={{ fontSize: 12 }}>Khác</span></>
      ) : (
        <>
          <span style={{ fontSize: 16, fontWeight: 700 }}>{amount}</span>
          <span style={{ fontSize: 10, color: COLORS.textMuted, marginTop: 2 }}>ml</span>
        </>
      )}
    </button>
  );
}

// Drink type icon (small SVG)
function DrinkIcon({ type, size = 22 }) {
  const m = {
    water: { c: '#38BDF8', glyph: '💧' },
    tea: { c: '#A3E635', glyph: '🍵' },
    coffee: { c: '#A78BFA', glyph: '☕' },
    juice: { c: '#FB923C', glyph: '🧃' },
    smoothie: { c: '#F472B6', glyph: '🥤' },
  };
  const conf = m[type] || m.water;
  return (
    <div style={{
      width: size + 12, height: size + 12, borderRadius: 999,
      background: `${conf.c}22`,
      border: `1px solid ${conf.c}44`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {type === 'water' && (
        <svg width={size - 4} height={size - 4} viewBox="0 0 24 24" fill={conf.c}>
          <path d="M12 3 C12 3 5 11 5 16 C5 19.866 8.134 23 12 23 C15.866 23 19 19.866 19 16 C19 11 12 3 12 3 Z"/>
        </svg>
      )}
      {type === 'tea' && (
        <svg width={size - 4} height={size - 4} viewBox="0 0 24 24" fill={conf.c}>
          <path d="M4 8 H18 V14 a6 6 0 0 1-12 0 V8 z" />
          <path d="M18 9 a3 3 0 0 1 0 6" stroke={conf.c} strokeWidth="2" fill="none"/>
          <path d="M9 3 Q11 5 9 7 M13 3 Q15 5 13 7" stroke={conf.c} strokeWidth="1.5" fill="none" opacity="0.6"/>
        </svg>
      )}
      {type === 'coffee' && (
        <svg width={size - 4} height={size - 4} viewBox="0 0 24 24" fill={conf.c}>
          <path d="M4 9 H18 V15 a5 5 0 0 1-10 0 H6 a2 2 0 0 1-2-2 V9 z"/>
          <path d="M18 10 a2.5 2.5 0 0 1 0 5"  stroke={conf.c} strokeWidth="1.6" fill="none"/>
        </svg>
      )}
      {type === 'juice' && (
        <svg width={size - 4} height={size - 4} viewBox="0 0 24 24" fill={conf.c}>
          <path d="M7 5 H17 L16 21 H8 z M9 3 H15 V5 H9 z"/>
        </svg>
      )}
      {type === 'smoothie' && (
        <svg width={size - 4} height={size - 4} viewBox="0 0 24 24" fill={conf.c}>
          <path d="M7 7 H17 L15 21 H9 z M11 3 Q13 5 11 7"  stroke={conf.c} strokeWidth="1.5" fill="none"/>
        </svg>
      )}
    </div>
  );
}

window.COLORS = COLORS;
window.FONT = FONT;
window.FONT_TEXT = FONT_TEXT;
window.FONT_ROUND = FONT_ROUND;
window.I = I;
window.XPBar = XPBar;
window.StreakBadge = StreakBadge;
window.QuickChip = QuickChip;
window.DrinkIcon = DrinkIcon;
