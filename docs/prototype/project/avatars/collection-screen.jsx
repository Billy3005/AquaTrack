// collection-screen.jsx — in-app "Bộ sưu tập avatar" screen + detail sheet
// Self-contained, mirrors AquaTrack's dark chrome.

const COLL_STATE = {
  giot_nuoc: 'equipped', suong_mai: 'owned', suoi_non: 'owned', dong_chay: 'owned',
};
function collState(id) { return COLL_STATE[id] || 'locked'; }

function CollHeader({ owned, total }) {
  return (
    <div style={{ background: 'linear-gradient(180deg, #15234A 0%, #0B1120 100%)', padding: '54px 18px 16px', position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
      <div style={{ position: 'absolute', top: -50, right: -30, width: 220, height: 220, borderRadius: '50%', background: 'radial-gradient(circle, rgba(129,140,248,0.22), transparent 60%)', pointerEvents: 'none' }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative' }}>
        <button style={{ width: 36, height: 36, borderRadius: 999, background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6 L9 12 L15 18" /></svg>
        </button>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 11, color: '#C4B5FD', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: AV.fontText }}>Tủ avatar</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound }}>Bộ sưu tập</div>
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '5px 10px 5px 7px', background: 'linear-gradient(135deg, rgba(251,191,36,0.18), rgba(245,158,11,0.06))', border: '1px solid rgba(251,191,36,0.45)', borderRadius: 999, fontFamily: AV.fontRound, fontSize: 12, fontWeight: 700, color: '#FDE68A' }}>
          {AvI.coin(15)}<span>1.240</span>
        </div>
      </div>

      {/* equipped hero */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 16, position: 'relative' }}>
        <AvatarBubble spec={AQUA_AVATARS[0]} size={88} animate />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 21, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em' }}>{AQUA_AVATARS[0].name}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
            <RarityTag tier="common" />
            <span style={{ fontSize: 11.5, color: '#7DD3FC', fontFamily: AV.fontRound, fontWeight: 700 }}>Đang dùng</span>
          </div>
          <div style={{ marginTop: 9, height: 7, borderRadius: 4, background: 'rgba(255,255,255,0.08)', overflow: 'hidden' }}>
            <div style={{ width: `${(owned / total) * 100}%`, height: '100%', borderRadius: 4, background: 'linear-gradient(90deg,#818CF8,#38BDF8)' }} />
          </div>
          <div style={{ fontSize: 10.5, color: AV.sub, marginTop: 5, fontFamily: AV.fontText }}>Đã mở <b style={{ color: '#fff' }}>{owned}</b> / {total} hình hài</div>
        </div>
      </div>
    </div>
  );
}

// small grid tile
function AvatarTile({ spec, onTap }) {
  const state = collState(spec.id);
  const locked = state === 'locked';
  const equipped = state === 'equipped';
  const t = tierMeta(spec.tier);
  return (
    <button onClick={onTap} style={{
      background: equipped ? `linear-gradient(180deg,${t.color}1F,${AV.surface})` : locked ? 'rgba(255,255,255,0.03)' : AV.surface,
      border: equipped ? `1.5px solid ${t.color}` : `1px solid ${locked ? 'rgba(255,255,255,0.06)' : t.color + '2E'}`,
      borderRadius: 16, padding: '10px 8px 11px', cursor: 'pointer', position: 'relative', overflow: 'hidden',
      boxShadow: equipped ? `0 0 0 3px ${t.color}1A` : 'none', textAlign: 'center',
    }}>
      <div style={{ position: 'absolute', top: 7, left: 7 }}><RarityTag tier={spec.tier} style={{ fontSize: 7.5, padding: '1px 5px' }} /></div>
      {locked && <div style={{ position: 'absolute', top: 8, right: 8 }}>{AvI.lock('#475569', 13)}</div>}
      {equipped && <div style={{ position: 'absolute', top: 8, right: 8 }}>{AvI.check('#7DD3FC', 14)}</div>}
      <div style={{ height: 78, display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: 8 }}>
        <AquaAvatar spec={spec} size={80} silhouette={locked} animate={false} />
      </div>
      <div style={{ fontSize: 12.5, fontWeight: 700, color: locked ? AV.sub : '#fff', fontFamily: AV.fontRound, marginTop: 4 }}>{spec.name}</div>
      <div style={{ marginTop: 6, display: 'flex', justifyContent: 'center', minHeight: 20 }}>
        {locked
          ? <UnlockChip unlock={spec.unlock} compact />
          : equipped
            ? <span style={{ fontSize: 10, color: t.color, fontFamily: AV.fontRound, fontWeight: 700 }}>Đang dùng</span>
            : <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 10, color: '#86EFAC', fontFamily: AV.fontRound, fontWeight: 700 }}>{AvI.check('#86EFAC', 10)} Đã mở</span>}
      </div>
    </button>
  );
}

function CollectionScreen({ onTap }) {
  const total = AQUA_AVATARS.length;
  const owned = AQUA_AVATARS.filter((a) => collState(a.id) !== 'locked').length;
  const tierOrder = ['common', 'rare', 'epic', 'legendary'];
  return (
    <div style={{ width: '100%', height: '100%', background: AV.base, color: AV.text, fontFamily: AV.font, display: 'flex', flexDirection: 'column' }}>
      <CollHeader owned={owned} total={total} />
      {/* segmented */}
      <div style={{ display: 'flex', gap: 8, padding: '12px 16px 6px', flexShrink: 0 }}>
        {[['Avatar', true], ['Theme', false], ['Khung', false]].map(([l, a]) => (
          <div key={l} style={{ padding: '6px 14px', borderRadius: 999, fontSize: 12.5, fontWeight: 700, fontFamily: AV.fontRound,
            background: a ? 'rgba(129,140,248,0.18)' : 'rgba(255,255,255,0.04)', border: a ? '1px solid rgba(129,140,248,0.45)' : '1px solid rgba(255,255,255,0.06)', color: a ? '#C4B5FD' : AV.sub }}>{l}</div>
        ))}
      </div>
      <div style={{ flex: 1, overflow: 'auto', padding: '8px 16px 16px' }}>
        {tierOrder.map((tk) => {
          const list = AQUA_AVATARS.filter((a) => a.tier === tk);
          const t = tierMeta(tk);
          const got = list.filter((a) => collState(a.id) !== 'locked').length;
          return (
            <div key={tk} style={{ marginTop: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <span style={{ width: 7, height: 7, borderRadius: 2, background: t.color, transform: 'rotate(45deg)' }} />
                <span style={{ fontSize: 12.5, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '0.02em' }}>{t.name}</span>
                <span style={{ fontSize: 10.5, color: AV.muted, fontFamily: AV.fontRound }}>{got}/{list.length}</span>
                <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.06)' }} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 9 }}>
                {list.map((a) => <AvatarTile key={a.id} spec={a} onTap={() => onTap && onTap(a)} />)}
              </div>
            </div>
          );
        })}
        <div style={{ height: 8 }} />
      </div>
      <CollBottomBar />
    </div>
  );
}

function CollBottomBar() {
  const tabs = [
    ['Nước', (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><path d="M12 3 C12 3 5 11 5 16 C5 19.866 8.134 23 12 23 C15.866 23 19 19.866 19 16 C19 11 12 3 12 3 Z" /></svg>],
    ['Nhiệm vụ', (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9"><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="5" /><circle cx="12" cy="12" r="1.6" fill={c} stroke="none" /></svg>],
    ['Thống kê', (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round"><path d="M3 13 Q6 9 9 13 T15 13 T21 13" /></svg>],
    ['Hồ sơ', (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><circle cx="12" cy="8" r="4" /><path d="M4 21 a8 8 0 0 1 16 0 z" /></svg>, true],
  ];
  return (
    <div style={{ flexShrink: 0, background: 'rgba(11,17,32,0.9)', backdropFilter: 'blur(20px)', borderTop: '1px solid rgba(56,189,248,0.12)', padding: '10px 8px 30px', display: 'flex', justifyContent: 'space-around' }}>
      {tabs.map(([l, svg, active]) => {
        const c = active ? '#38BDF8' : '#475569';
        return <div key={l} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>{svg(c)}<div style={{ fontSize: 9.5, color: c, fontFamily: AV.fontRound, fontWeight: 600 }}>{l}</div></div>;
      })}
    </div>
  );
}

// ── detail bottom sheet ─────────────────────────────────────
function AvatarDetailSheet({ spec }) {
  const state = collState(spec.id);
  const locked = state === 'locked';
  const equipped = state === 'equipped';
  const t = tierMeta(spec.tier);
  const u = spec.unlock;
  let action;
  if (equipped) action = { label: 'Đang trang bị', disabled: true, kind: 'dim' };
  else if (state === 'owned') action = { label: 'Trang bị', kind: 'blue' };
  else if (u.type === 'coin') action = { label: `Mua · ${u.label}`, kind: 'gold', icon: AvI.coin(15) };
  else if (u.type === 'level') action = { label: `Cần đạt ${u.label}`, disabled: true, kind: 'lock' };
  else if (u.type === 'streak') action = { label: u.label, disabled: true, kind: 'lock' };
  else action = { label: 'Hoàn thành nhiệm vụ', disabled: true, kind: 'lock' };

  const btnStyle = {
    blue: { background: 'linear-gradient(135deg,#0EA5E9,#0284C7)', color: '#fff', shadow: '0 6px 18px rgba(14,165,233,0.4)' },
    gold: { background: 'linear-gradient(135deg,#FBBF24,#F59E0B)', color: '#451A03', shadow: '0 6px 18px rgba(245,158,11,0.4)' },
    dim: { background: 'rgba(56,189,248,0.12)', color: '#7DD3FC', shadow: 'none' },
    lock: { background: 'rgba(255,255,255,0.05)', color: AV.sub, shadow: 'none' },
  }[action.kind];

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', fontFamily: AV.font, background: 'rgba(5,9,20,0.65)', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <div style={{ background: 'linear-gradient(180deg,#10203C,#0B1120)', borderRadius: '28px 28px 0 0', border: `1px solid ${t.color}33`, borderBottom: 'none', padding: '14px 22px 34px', position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: -40, left: '50%', transform: 'translateX(-50%)', width: 280, height: 200, background: `radial-gradient(circle, ${t.color}30, transparent 65%)`, pointerEvents: 'none' }} />
        <div style={{ width: 40, height: 5, borderRadius: 3, background: 'rgba(255,255,255,0.18)', margin: '0 auto 14px' }} />
        <div style={{ display: 'flex', justifyContent: 'center', position: 'relative' }}>
          <AvatarBubble spec={spec} size={156} animate />
        </div>
        <div style={{ textAlign: 'center', marginTop: 12, position: 'relative' }}>
          <div style={{ fontSize: 25, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em' }}>{spec.name}</div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', justifyContent: 'center', marginTop: 6 }}>
            <RarityTag tier={spec.tier} />
            <span style={{ fontSize: 12, color: AV.muted, fontStyle: 'italic', fontFamily: AV.fontText }}>{spec.meaning}</span>
          </div>
          <p style={{ fontSize: 13, color: AV.sub, lineHeight: 1.5, margin: '12px auto 0', maxWidth: 290, fontFamily: AV.fontText, textWrap: 'pretty' }}>{spec.desc}</p>
        </div>
        {/* unlock note */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginTop: 14, padding: '9px 12px', background: 'rgba(255,255,255,0.04)', borderRadius: 12, border: '1px solid rgba(255,255,255,0.06)' }}>
          <UnlockChip unlock={u} />
          {u.sub && <span style={{ fontSize: 11.5, color: AV.muted, fontFamily: AV.fontText }}>· {u.sub}</span>}
        </div>
        <button disabled={action.disabled} style={{
          width: '100%', marginTop: 14, padding: '14px 0', borderRadius: 14, border: 'none',
          background: btnStyle.background, color: btnStyle.color, boxShadow: btnStyle.shadow,
          fontFamily: AV.fontRound, fontWeight: 800, fontSize: 15, letterSpacing: '0.01em',
          cursor: action.disabled ? 'default' : 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 7,
        }}>{action.icon}{action.label}</button>
      </div>
    </div>
  );
}

window.CollectionScreen = CollectionScreen;
window.AvatarDetailSheet = AvatarDetailSheet;
