// avatar-cards.jsx — gallery cards, unlock chips, state variants, celebration
const AV = {
  base: '#0B1120', surface: '#0F1A2E', card: '#16223A', cardSoft: '#13203A',
  border: 'rgba(56,189,248,0.15)', text: '#F1F5F9', sub: '#94A3B8', muted: '#64748B',
  bright: '#BAE6FD',
  font: '"SF Pro Display", -apple-system, "Helvetica Neue", system-ui, sans-serif',
  fontText: '"SF Pro Text", -apple-system, system-ui, sans-serif',
  fontRound: '"SF Pro Rounded", "SF Pro Text", system-ui, sans-serif',
};

// ── tiny icons ──────────────────────────────────────────────
const AvI = {
  coin: (s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24">
      <defs><radialGradient id="avc-coin" cx="35%" cy="30%" r="75%">
        <stop offset="0%" stopColor="#FEF3C7" /><stop offset="55%" stopColor="#FBBF24" /><stop offset="100%" stopColor="#B45309" />
      </radialGradient></defs>
      <circle cx="12" cy="12" r="10" fill="url(#avc-coin)" stroke="#78350F" strokeWidth="0.6" />
      <path d="M12 7.5 C10.3 7.5 9 8.7 9 10.3 C9 11.7 10 12.4 11.5 12.8 C13 13.2 13.6 13.5 13.6 14.2 C13.6 14.9 12.9 15.3 12 15.3 C10.9 15.3 10.1 14.8 9.7 14.1" fill="none" stroke="#78350F" strokeWidth="1.3" strokeLinecap="round" />
      <path d="M12 6.5 V8 M12 15 V16.5" stroke="#78350F" strokeWidth="1.3" strokeLinecap="round" />
    </svg>
  ),
  level: (c = '#A5B4FC', s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 14 L12 7 L19 14" /><path d="M5 19 L12 12 L19 19" opacity="0.55" />
    </svg>
  ),
  flame: (c = '#F97316', s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M12 2 C12 6 8 7 8 12 C8 16 9.5 19 12 19 C14.5 19 16 16 16 12 C16 9 14 8 14 5 C14 4 13 3 12 2 Z" />
    </svg>
  ),
  mission: (c = '#C4B5FD', s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r="1" fill={c} stroke="none" />
    </svg>
  ),
  lock: (c = '#64748B', s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11 V8 a4 4 0 0 1 8 0 V11" />
    </svg>
  ),
  check: (c = '#7DD3FC', s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12 L9 17 L20 6" /></svg>
  ),
};

function tierMeta(key) { return (window.AQUA_TIERS && window.AQUA_TIERS[key]) || {}; }

// rarity pill
function RarityTag({ tier, style = {} }) {
  const t = tierMeta(tier);
  return (
    <span style={{
      fontSize: 9, fontWeight: 800, letterSpacing: '0.12em', fontFamily: AV.fontRound,
      color: t.color, background: `${t.color}1F`, border: `1px solid ${t.color}40`,
      padding: '2px 7px', borderRadius: 5, textTransform: 'uppercase', ...style,
    }}>{t.short}</span>
  );
}

// unlock requirement chip
function UnlockChip({ unlock, compact }) {
  const u = unlock;
  let icon, color, bg;
  if (u.type === 'level') { icon = AvI.level('#A5B4FC', 12); color = '#A5B4FC'; bg = 'rgba(129,140,248,0.14)'; }
  else if (u.type === 'coin') { icon = AvI.coin(13); color = '#FDE68A'; bg = 'rgba(251,191,36,0.14)'; }
  else if (u.type === 'streak') { icon = AvI.flame('#FB923C', 12); color = '#FED7AA'; bg = 'rgba(249,115,22,0.16)'; }
  else { icon = AvI.mission('#C4B5FD', 12); color = '#DDD6FE'; bg = 'rgba(167,139,250,0.16)'; }
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: compact ? '3px 8px' : '4px 10px', borderRadius: 999,
      background: bg, border: `1px solid ${color}33`, color,
      fontFamily: AV.fontRound, fontWeight: 700, fontSize: compact ? 10.5 : 11.5,
      letterSpacing: '0.01em', whiteSpace: 'nowrap',
    }}>{icon}{u.label}</span>
  );
}

// ── full gallery card ───────────────────────────────────────
function AvatarCard({ spec, state = 'locked', width = 198 }) {
  const t = tierMeta(spec.tier);
  const locked = state === 'locked';
  const equipped = state === 'equipped';
  return (
    <div style={{
      width, borderRadius: 18, padding: 14,
      background: equipped
        ? `linear-gradient(180deg, ${t.color}1A, ${AV.surface})`
        : locked ? AV.cardSoft : `linear-gradient(180deg, ${t.color}12, ${AV.surface})`,
      border: equipped ? `1.5px solid ${t.color}` : `1px solid ${locked ? 'rgba(255,255,255,0.06)' : t.color + '33'}`,
      boxShadow: equipped ? `0 0 0 4px ${t.color}1F, 0 10px 30px rgba(0,0,0,0.4)` : '0 6px 20px rgba(0,0,0,0.3)',
      position: 'relative', overflow: 'hidden', boxSizing: 'border-box',
    }}>
      {/* corner rarity glow */}
      {!locked && <div style={{ position: 'absolute', top: -30, right: -30, width: 110, height: 110, borderRadius: '50%', background: `radial-gradient(circle, ${t.color}26, transparent 65%)`, pointerEvents: 'none' }} />}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
        <RarityTag tier={spec.tier} />
        {equipped && (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 9.5, fontWeight: 800, letterSpacing: '0.06em', color: '#7DD3FC', background: 'rgba(56,189,248,0.18)', border: '1px solid rgba(56,189,248,0.4)', padding: '2px 7px', borderRadius: 5, fontFamily: AV.fontRound }}>{AvI.check('#7DD3FC', 10)} ĐANG DÙNG</span>
        )}
        {locked && AvI.lock('#475569', 15)}
      </div>

      {/* avatar */}
      <div style={{ height: 116, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '6px 0 8px', position: 'relative' }}>
        <AquaAvatar spec={spec} size={118} silhouette={locked} />
      </div>

      {/* name */}
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 16.5, fontWeight: 700, color: locked ? AV.sub : '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em', whiteSpace: 'nowrap', lineHeight: 1.15 }}>{spec.name}</div>
        <div style={{ fontSize: 10.5, color: AV.muted, fontFamily: AV.fontText, marginTop: 2, fontStyle: 'italic', letterSpacing: '0.02em', whiteSpace: 'nowrap' }}>{spec.meaning}</div>
      </div>

      {/* unlock / status */}
      <div style={{ display: 'flex', justifyContent: 'center', marginTop: 10 }}>
        {equipped
          ? <span style={{ fontSize: 11, color: t.color, fontFamily: AV.fontRound, fontWeight: 700, whiteSpace: 'nowrap' }}>Đang trang bị</span>
          : state === 'owned'
            ? <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 11, color: '#86EFAC', fontFamily: AV.fontRound, fontWeight: 700, whiteSpace: 'nowrap' }}>{AvI.check('#86EFAC', 12)} Đã sở hữu</span>
            : <UnlockChip unlock={spec.unlock} />}
      </div>
    </div>
  );
}

window.AV = AV;
window.AvI = AvI;
window.RarityTag = RarityTag;
window.UnlockChip = UnlockChip;
window.AvatarCard = AvatarCard;
window.tierMeta = tierMeta;
