// celebration.jsx — "unlock a new avatar" reward moment (in-app, iPhone content)
function UnlockCelebration({ spec }) {
  const t = tierMeta(spec.tier);
  const rays = Array.from({ length: 12 });
  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden', fontFamily: AV.font,
      background: `radial-gradient(ellipse at 50% 38%, ${t.color}22 0%, #0A1326 55%, #050A18 100%)`,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 26px' }}>

      {/* rotating rays */}
      <div style={{ position: 'absolute', top: '32%', left: '50%', width: 460, height: 460, transform: 'translate(-50%,-50%)', animation: 'aqav-spin 22s linear infinite', opacity: 0.5 }}>
        {rays.map((_, i) => (
          <div key={i} style={{ position: 'absolute', top: '50%', left: '50%', width: 4, height: 230, transformOrigin: 'top center',
            transform: `translate(-50%,0) rotate(${i * 30}deg)`,
            background: `linear-gradient(${t.color}, transparent)`, opacity: i % 2 ? 0.5 : 0.85 }} />
        ))}
      </div>

      {/* confetti */}
      {[['8%', '20%', '#FBBF24'], ['86%', '24%', t.color], ['16%', '64%', '#38BDF8'], ['82%', '60%', '#F472B6'], ['50%', '12%', '#A78BFA'], ['30%', '78%', t.color], ['70%', '80%', '#FDE68A']].map(([l, top, c], i) => (
        <span key={i} style={{ position: 'absolute', left: l, top, width: 8, height: 8, borderRadius: i % 2 ? 2 : 8, background: c,
          animation: `aqav-twinkle ${1.8 + i * 0.25}s ease-in-out infinite ${i * 0.3}s`, opacity: 0.9 }} />
      ))}

      {/* banner */}
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', marginBottom: 6 }}>
        <div style={{ fontSize: 12, fontWeight: 800, letterSpacing: '0.28em', color: t.color, fontFamily: AV.fontRound, textTransform: 'uppercase' }}>Hình hài mới</div>
        <div style={{ fontSize: 30, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '0.01em', marginTop: 2, textShadow: `0 2px 24px ${t.color}88` }}>ĐÃ MỞ KHOÁ!</div>
      </div>

      {/* avatar */}
      <div style={{ position: 'relative', zIndex: 2, margin: '12px 0 4px' }}>
        <AvatarBubble spec={spec} size={208} animate />
      </div>

      {/* name plate */}
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', marginTop: 8 }}>
        <div style={{ fontSize: 28, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em' }}>{spec.name}</div>
        <div style={{ display: 'flex', gap: 9, alignItems: 'center', justifyContent: 'center', marginTop: 6 }}>
          <RarityTag tier={spec.tier} style={{ fontSize: 10, padding: '3px 9px' }} />
          <span style={{ fontSize: 13, color: AV.sub, fontStyle: 'italic', fontFamily: AV.fontText }}>{spec.meaning}</span>
        </div>
        <p style={{ fontSize: 13, color: AV.bright, opacity: 0.85, margin: '11px auto 0', maxWidth: 280, lineHeight: 1.5, fontFamily: AV.fontText, textWrap: 'pretty' }}>{spec.desc}</p>
      </div>

      {/* actions */}
      <div style={{ position: 'relative', zIndex: 2, width: '100%', marginTop: 24, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <button style={{ width: '100%', padding: '15px 0', borderRadius: 15, border: 'none',
          background: `linear-gradient(135deg, ${t.ring[0]}, ${t.ring[1]})`, color: spec.tier === 'legendary' ? '#451A03' : '#fff',
          fontFamily: AV.fontRound, fontWeight: 800, fontSize: 16, cursor: 'pointer',
          boxShadow: `0 10px 28px ${t.glow}` }}>Trang bị ngay</button>
        <button style={{ width: '100%', padding: '12px 0', borderRadius: 15, border: '1px solid rgba(255,255,255,0.12)',
          background: 'transparent', color: AV.sub, fontFamily: AV.fontRound, fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>Để sau</button>
      </div>
    </div>
  );
}
window.UnlockCelebration = UnlockCelebration;
