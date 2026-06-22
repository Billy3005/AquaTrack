// gallery.jsx — design-canvas composition + mount
const stateOf = (s) => (s.equipped ? 'equipped' : s.owned ? 'owned' : 'locked');
const byTier = (k) => AQUA_AVATARS.filter((a) => a.tier === k);

function DarkBoard({ children, pad = 28, style = {} }) {
  return <div style={{ width: '100%', height: '100%', background: AV.base, color: AV.text, fontFamily: AV.font, padding: pad, boxSizing: 'border-box', overflow: 'hidden', ...style }}>{children}</div>;
}

function BoardTitle({ kicker, title, note }) {
  return (
    <div style={{ marginBottom: 18 }}>
      {kicker && <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '0.16em', textTransform: 'uppercase', color: '#7DD3FC', fontFamily: AV.fontRound }}>{kicker}</div>}
      <div style={{ fontSize: 22, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em', marginTop: 3 }}>{title}</div>
      {note && <div style={{ fontSize: 12.5, color: AV.sub, marginTop: 5, fontFamily: AV.fontText, lineHeight: 1.5, maxWidth: 520, textWrap: 'pretty' }}>{note}</div>}
    </div>
  );
}

// ── BRIEF ───────────────────────────────────────────────────
function BriefBoard() {
  const rows = [
    ['Ý tưởng', 'Một “Linh hồn Nước” duy nhất tiến hoá qua 12 hình hài, trải 4 bậc hiếm — từ giọt sương bé bỏng đến đế vương đại dương.'],
    ['Hình ảnh', 'Tái dùng đúng hình giọt nước & bảng màu xanh của AquaTrack. Gương mặt dễ thương ở bậc thấp, uy nghi dần ở bậc cao. Phụ kiện mọc thêm theo bậc: lá → sóng → ngọc/hào quang → vương miện, sừng rồng, hào quang xoáy.'],
    ['Mở khoá', 'Bậc Thường mở bằng lên cấp; Hiếm bằng cấp hoặc xu; Sử thi mua bằng xu; Huyền thoại là cao cấp — xu lớn, chuỗi ngày, hoặc thành tựu.'],
    ['Độ hiếm', 'Càng hiếm càng rực rỡ: viền khung đổi màu, thêm hào quang phát sáng và hạt lấp lánh xoay quanh.'],
  ];
  return (
    <DarkBoard>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16 }}>
        <AvatarBubble spec={AQUA_AVATARS[11]} size={64} />
        <div>
          <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '0.16em', textTransform: 'uppercase', color: '#7DD3FC', fontFamily: AV.fontRound }}>AquaTrack · Bộ sưu tập avatar</div>
          <div style={{ fontSize: 25, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound, letterSpacing: '-0.01em' }}>Linh hồn Nước · 12 hình hài tiến hoá</div>
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
        {rows.map(([h, b]) => (
          <div key={h} style={{ background: AV.surface, border: `1px solid ${AV.border}`, borderRadius: 14, padding: '13px 15px' }}>
            <div style={{ fontSize: 12, fontWeight: 800, color: '#A5B4FC', fontFamily: AV.fontRound, letterSpacing: '0.04em', marginBottom: 5 }}>{h}</div>
            <div style={{ fontSize: 12.5, color: AV.sub, lineHeight: 1.55, fontFamily: AV.fontText, textWrap: 'pretty' }}>{b}</div>
          </div>
        ))}
      </div>
      {/* tier legend */}
      <div style={{ display: 'flex', gap: 10 }}>
        {['common', 'rare', 'epic', 'legendary'].map((k) => {
          const t = tierMeta(k);
          return (
            <div key={k} style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 10, background: AV.surface, border: `1px solid ${t.color}33`, borderRadius: 12, padding: '10px 12px' }}>
              <div style={{ width: 22, height: 22, borderRadius: '50%', background: `conic-gradient(from 210deg, ${t.ring.join(', ')})`, flexShrink: 0 }} />
              <div>
                <div style={{ fontSize: 12.5, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound }}>{t.name}</div>
                <div style={{ fontSize: 10, color: AV.muted, fontFamily: AV.fontRound, letterSpacing: '0.06em' }}>{byTier(k).length} hình hài</div>
              </div>
            </div>
          );
        })}
      </div>
    </DarkBoard>
  );
}

// ── tier column ─────────────────────────────────────────────
function TierColumn({ tierKey }) {
  const t = tierMeta(tierKey);
  const list = byTier(tierKey);
  return (
    <DarkBoard pad={22}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 16 }}>
        <span style={{ width: 10, height: 10, borderRadius: 3, background: t.color, transform: 'rotate(45deg)', boxShadow: `0 0 12px ${t.color}` }} />
        <span style={{ fontSize: 16, fontWeight: 800, color: '#fff', fontFamily: AV.fontRound }}>{t.name}</span>
        <RarityTag tier={tierKey} />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {list.map((s) => <AvatarCard key={s.id} spec={s} state={stateOf(s)} width={200} />)}
      </div>
    </DarkBoard>
  );
}

// ── EVOLUTION CHAIN ─────────────────────────────────────────
function EvolutionChain() {
  return (
    <DarkBoard pad={30}>
      <BoardTitle kicker="Tiến hoá" title="Từ giọt sương đến đế vương" note="Đọc trái → phải. Thân đậm dần, mắt trưởng thành dần, phụ kiện mọc thêm; nền sáng dần theo độ hiếm." />
      <div style={{ position: 'relative', display: 'flex', alignItems: 'flex-end', gap: 6, paddingTop: 10 }}>
        {/* progress line */}
        <div style={{ position: 'absolute', left: 40, right: 40, top: 64, height: 3, borderRadius: 2, background: 'linear-gradient(90deg, #64748B, #38BDF8, #A78BFA, #FBBF24)', opacity: 0.5 }} />
        {AQUA_AVATARS.map((s, i) => {
          const t = tierMeta(s.tier);
          const size = 64 + i * 4; // grows along the chain
          return (
            <div key={s.id} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative' }}>
              <div style={{ height: 116, display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}>
                <AvatarBubble spec={s} size={size} ring={false} animate={false} />
              </div>
              <span style={{ width: 9, height: 9, borderRadius: '50%', background: t.color, border: '2px solid #0B1120', boxShadow: `0 0 8px ${t.color}`, marginTop: 4, zIndex: 1 }} />
              <div style={{ fontSize: 11, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound, marginTop: 7, textAlign: 'center', lineHeight: 1.1 }}>{s.name}</div>
              <div style={{ fontSize: 9, color: AV.muted, fontFamily: AV.fontRound, marginTop: 2 }}>{s.unlock.type === 'level' ? s.unlock.label : s.unlock.type === 'coin' ? s.unlock.label : s.unlock.type === 'streak' ? '100 ngày' : 'Nhiệm vụ'}</div>
            </div>
          );
        })}
      </div>
    </DarkBoard>
  );
}

// ── STATES ──────────────────────────────────────────────────
function StatesBoard() {
  const s = AQUA_AVATARS.find((a) => a.id === 'hai_vuong');
  const items = [['locked', 'Chưa mở · hiện bóng bí ẩn + điều kiện'], ['owned', 'Đã sở hữu · sẵn sàng trang bị'], ['equipped', 'Đang dùng · viền sáng nổi bật']];
  return (
    <DarkBoard pad={26}>
      <BoardTitle kicker="Trạng thái" title="Khoá · Mở · Đang dùng" note="Mỗi avatar có 3 trạng thái rõ ràng để người chơi luôn biết mình đang ở đâu." />
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        {items.map(([st, cap]) => (
          <div key={st} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
            <AvatarCard spec={s} state={st} width={196} />
            <div style={{ fontSize: 11.5, color: AV.sub, fontFamily: AV.fontText, textAlign: 'center', maxWidth: 196, lineHeight: 1.4 }}>{cap}</div>
          </div>
        ))}
      </div>
    </DarkBoard>
  );
}

// ── DISPLAY (bubbles + sizes) ───────────────────────────────
function DisplayBoard() {
  const sizes = [[32, 'Tab'], [44, 'Danh sách'], [56, 'Bình luận'], [76, 'Hồ sơ'], [120, 'Tủ đồ']];
  const heroes = ['giot_nuoc', 'thuy_linh', 'hai_vuong', 'thuy_de'].map((id) => AQUA_AVATARS.find((a) => a.id === id));
  return (
    <DarkBoard pad={26}>
      <BoardTitle kicker="Hiển thị" title="Bong bóng hồ sơ & cỡ hiển thị" note="Khung viền đổi màu theo bậc hiếm. Avatar đọc tốt từ icon tab 32px đến tủ đồ 120px." />
      {/* profile header mock */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 22 }}>
        {heroes.map((s) => {
          const t = tierMeta(s.tier);
          return (
            <div key={s.id} style={{ display: 'flex', alignItems: 'center', gap: 14, background: 'linear-gradient(180deg,#0C2A4A,#0B1120)', border: `1px solid ${AV.border}`, borderRadius: 16, padding: '12px 16px' }}>
              <div style={{ position: 'relative' }}>
                <AvatarBubble spec={s} size={68} />
                <div style={{ position: 'absolute', bottom: -4, right: -4, background: '#4F46E5', color: '#E0E7FF', fontFamily: AV.fontRound, fontSize: 10, fontWeight: 700, padding: '2px 7px', borderRadius: 7, border: '2px solid #0B1120' }}>LV 7</div>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 17, fontWeight: 700, color: '#fff', fontFamily: AV.fontRound }}>Minh Nguyễn</div>
                <div style={{ fontSize: 12, color: t.color, fontFamily: AV.fontRound, fontWeight: 600, marginTop: 2 }}>{s.name} · <span style={{ color: AV.sub }}>{tierMeta(s.tier).name}</span></div>
              </div>
              <RarityTag tier={s.tier} />
            </div>
          );
        })}
      </div>
      {/* size ramp */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 22, justifyContent: 'center', background: AV.surface, borderRadius: 16, padding: '20px 16px', border: `1px solid ${AV.border}` }}>
        {sizes.map(([sz, lbl]) => (
          <div key={sz} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <AvatarBubble spec={AQUA_AVATARS.find((a) => a.id === 'hai_lam')} size={sz} animate={false} />
            <div style={{ fontSize: 10.5, color: AV.muted, fontFamily: AV.fontRound }}>{sz}px · {lbl}</div>
          </div>
        ))}
      </div>
    </DarkBoard>
  );
}

function Phone({ children }) {
  return <IOSDevice width={390} height={844} dark>{children}</IOSDevice>;
}

function Root() {
  const detailSpec = AQUA_AVATARS.find((a) => a.id === 'thuy_linh');
  const celebSpec = AQUA_AVATARS.find((a) => a.id === 'long_thuy');
  return (
    <DesignCanvas>
      <DCSection id="brief" title="Định hướng" subtitle="Khái niệm & quy tắc của bộ avatar">
        <DCArtboard id="brief" label="Bản tóm tắt" width={760} height={430} style={{ background: AV.base, borderRadius: 20 }}><BriefBoard /></DCArtboard>
      </DCSection>

      <DCSection id="collection" title="Bộ sưu tập theo bậc" subtitle="12 hình hài · 4 bậc hiếm · trạng thái thật">
        <DCArtboard id="c1" label="Thường" width={248} height={1120} style={{ background: AV.base, borderRadius: 20 }}><TierColumn tierKey="common" /></DCArtboard>
        <DCArtboard id="c2" label="Hiếm" width={248} height={1120} style={{ background: AV.base, borderRadius: 20 }}><TierColumn tierKey="rare" /></DCArtboard>
        <DCArtboard id="c3" label="Sử thi" width={248} height={1120} style={{ background: AV.base, borderRadius: 20 }}><TierColumn tierKey="epic" /></DCArtboard>
        <DCArtboard id="c4" label="Huyền thoại" width={248} height={1120} style={{ background: AV.base, borderRadius: 20 }}><TierColumn tierKey="legendary" /></DCArtboard>
      </DCSection>

      <DCSection id="evo" title="Chuỗi tiến hoá" subtitle="Cơ bản → nâng cao">
        <DCArtboard id="chain" label="12 hình hài" width={1280} height={300} style={{ background: AV.base, borderRadius: 20 }}><EvolutionChain /></DCArtboard>
      </DCSection>

      <DCSection id="states" title="Trạng thái & hiển thị" subtitle="Khoá / mở / đang dùng · bong bóng hồ sơ">
        <DCArtboard id="st" label="3 trạng thái" width={680} height={420} style={{ background: AV.base, borderRadius: 20 }}><StatesBoard /></DCArtboard>
        <DCArtboard id="disp" label="Hồ sơ & cỡ" width={560} height={560} style={{ background: AV.base, borderRadius: 20 }}><DisplayBoard /></DCArtboard>
      </DCSection>

      <DCSection id="inapp" title="Trải nghiệm trong app" subtitle="Màn hình tủ đồ · chi tiết · mở khoá">
        <DCArtboard id="screen" label="Tủ avatar" width={390} height={844}><Phone><CollectionScreen /></Phone></DCArtboard>
        <DCArtboard id="detail" label="Chi tiết (bottom sheet)" width={390} height={844}><Phone><AvatarDetailSheet spec={detailSpec} /></Phone></DCArtboard>
        <DCArtboard id="celebrate" label="Khoảnh khắc mở khoá" width={390} height={844}><Phone><UnlockCelebration spec={celebSpec} /></Phone></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

Object.assign(window, { BriefBoard, TierColumn, EvolutionChain, StatesBoard, DisplayBoard, Root });

if (!window.__AQUA_NO_AUTOMOUNT) {
  ReactDOM.createRoot(document.getElementById('root')).render(<Root />);
}
