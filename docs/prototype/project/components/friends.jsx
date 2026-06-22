// FriendsScreen — social hydration: leaderboard + remind/poke/challenge actions
function FriendsScreen({ onNavigate }) {
  const [tab, setTab] = React.useState('friends'); // 'friends' | 'requests'
  const [toast, setToast] = React.useState(null);

  const me = { name: 'Bạn', pct: 58, level: 7, streak: 12, avatar: '#38BDF8' };

  const [friends, setFriends] = React.useState([
    { id: 'a', name: 'Linh Phạm', handle: '@linhpham', level: 9, pct: 96, streak: 18, avatar: '#FBBF24', mood: 'glow', lastDrink: '2 phút trước', online: true, reminded: false },
    { id: 'b', name: 'Hoàng Lê', handle: '@hoangle', level: 6, pct: 18, streak: 4, avatar: '#F97316', mood: 'thirsty', lastDrink: '4 giờ trước', online: true, reminded: false },
    { id: 'c', name: 'Mai Trần', handle: '@maitran', level: 11, pct: 72, streak: 31, avatar: '#A78BFA', mood: 'good', lastDrink: '20 phút trước', online: false, reminded: false },
    { id: 'd', name: 'Đức Nguyễn', handle: '@ducn', level: 7, pct: 41, streak: 0, avatar: '#10B981', mood: 'low', lastDrink: '1 giờ trước', online: false, reminded: false },
    { id: 'e', name: 'Thảo Vũ', handle: '@thaovu', level: 5, pct: 64, streak: 7, avatar: '#EC4899', mood: 'good', lastDrink: '15 phút trước', online: true, reminded: true },
  ]);

  const [requests] = React.useState([
    { id: 'r1', name: 'Quỳnh Anh', handle: '@quynh', level: 8, mutual: 3, avatar: '#06B6D4' },
    { id: 'r2', name: 'Bảo Nguyễn', handle: '@baon', level: 4, mutual: 1, avatar: '#F472B6' },
  ]);

  function showToast(msg) {
    setToast(msg);
    setTimeout(() => setToast(null), 2000);
  }

  function nudge(f) {
    setFriends((arr) => arr.map((x) => x.id === f.id ? { ...x, reminded: true } : x));
    showToast(`Đã nhắc ${f.name.split(' ').slice(-1)[0]} uống nước 💧`);
  }

  function challenge(f) {
    showToast(`Đã gửi thách đấu cho ${f.name.split(' ').slice(-1)[0]} ⚔️`);
  }

  // Sort: thirsty first when "all" view, kept stable order for now
  const sortedFriends = friends.slice().sort((a, b) => {
    const pri = (m) => m === 'thirsty' ? 0 : m === 'low' ? 1 : m === 'good' ? 2 : 3;
    return pri(a.mood) - pri(b.mood);
  });

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, #0C2A4A 0%, #0B1120 100%)',
        padding: '54px 18px 14px',
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', top: -50, right: -30, width: 200, height: 200,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.16), transparent 60%)',
        }} />
        <div style={{ position: 'relative', display: 'flex', justifyContent: 'flex-end', marginBottom: 4 }}>
          <CoinBadge amount={1240} compact suffix="fr" onClick={() => onNavigate && onNavigate('shop')} />
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              Bạn bè
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, color: 'white', letterSpacing: '-0.02em', marginTop: 2 }}>
              Cùng giữ nhịp uống
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={{
              width: 36, height: 36, borderRadius: 999,
              background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round">
                <circle cx="11" cy="11" r="7"/><path d="M21 21 L17 17"/>
              </svg>
            </button>
            <button style={{
              width: 36, height: 36, borderRadius: 999,
              background: 'linear-gradient(135deg, #38BDF8, #0EA5E9)',
              border: '1px solid rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
              boxShadow: '0 4px 12px rgba(14,165,233,0.4)',
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.4" strokeLinecap="round">
                <path d="M12 5 V19 M5 12 H19"/>
              </svg>
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div style={{
          display: 'flex', gap: 4,
          background: 'rgba(0,0,0,0.3)', borderRadius: 10, padding: 3,
          border: '1px solid rgba(255,255,255,0.04)',
          width: 'fit-content',
        }}>
          {[
            { id: 'friends', lbl: `Bạn bè · ${friends.length}` },
            { id: 'requests', lbl: `Lời mời · ${requests.length}` },
          ].map((t) => (
            <button key={t.id} onClick={() => setTab(t.id)} style={{
              padding: '6px 14px', borderRadius: 8,
              background: tab === t.id ? 'rgba(56,189,248,0.18)' : 'transparent',
              border: tab === t.id ? '1px solid rgba(56,189,248,0.35)' : '1px solid transparent',
              color: tab === t.id ? '#BAE6FD' : COLORS.textSecondary,
              fontSize: 12, fontWeight: 600, fontFamily: FONT_TEXT,
              cursor: 'pointer',
            }}>{t.lbl}</button>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px 20px' }}>
        {tab === 'friends' && (
          <>
            {/* Interactive weekly ranking */}
            <InteractiveRanking
              friends={friends}
              me={me}
              onNudge={nudge}
              onChallenge={challenge}
            />

            {/* Filter chips */}
            <div style={{ display: 'flex', gap: 6, marginBottom: 12, overflowX: 'auto', paddingBottom: 4, scrollbarWidth: 'none' }}>
              {[
                { id: 'all', lbl: 'Tất cả', count: friends.length, active: true },
                { id: 'low', lbl: 'Đang khát', count: friends.filter((f) => f.mood === 'thirsty' || f.mood === 'low').length, color: '#F97316' },
                { id: 'on', lbl: 'Online', count: friends.filter((f) => f.online).length, color: '#10B981' },
                { id: 'streak', lbl: 'Đang streak', count: friends.filter((f) => f.streak > 5).length, color: '#A78BFA' },
              ].map((c) => (
                <div key={c.id} style={{
                  flexShrink: 0,
                  padding: '6px 12px', borderRadius: 999,
                  background: c.active ? 'rgba(56,189,248,0.16)' : 'rgba(255,255,255,0.04)',
                  border: c.active ? '1px solid rgba(56,189,248,0.35)' : '1px solid rgba(255,255,255,0.06)',
                  color: c.active ? '#BAE6FD' : COLORS.textSecondary,
                  fontSize: 12, fontFamily: FONT_TEXT, fontWeight: 500,
                  display: 'flex', alignItems: 'center', gap: 6,
                  cursor: 'pointer',
                }}>
                  {c.color && <span style={{ width: 5, height: 5, borderRadius: 999, background: c.color }} />}
                  {c.lbl}
                  <span style={{ opacity: 0.6, fontSize: 11 }}>{c.count}</span>
                </div>
              ))}
            </div>

            {/* Section header */}
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '4px 2px', marginBottom: 8,
            }}>
              <div style={{ fontSize: 12, color: COLORS.textMuted, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT }}>
                Bạn bè
              </div>
              <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT }}>
                Sắp theo: <span style={{ color: '#7DD3FC', fontWeight: 600 }}>cần nhắc</span>
              </div>
            </div>

            {/* Friend cards */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {sortedFriends.map((f) => (
                <FriendCard key={f.id} f={f} onNudge={() => nudge(f)} onChallenge={() => challenge(f)} />
              ))}
            </div>

            {/* Group challenge banner */}
            <div style={{
              marginTop: 16,
              background: 'linear-gradient(135deg, #1E1B4B, #0F172A)',
              border: '1px solid rgba(168,85,247,0.3)',
              borderRadius: 14, padding: '14px 14px',
              display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 12,
                background: 'linear-gradient(135deg, #A78BFA, #6366F1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                boxShadow: '0 4px 12px rgba(99,102,241,0.4)',
              }}>
                <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
                  <path d="M5 3 H19 V5 a3 3 0 0 1-3 3 H8 a3 3 0 0 1-3-3 z M9 8 V13 a3 3 0 0 0 3 3 a3 3 0 0 0 3-3 V8 M12 16 V20 M8 21 H16"/>
                </svg>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT }}>
                  Thách đấu nhóm
                </div>
                <div style={{ fontSize: 11, color: '#C4B5FD', marginTop: 2, fontFamily: FONT_TEXT, lineHeight: 1.4 }}>
                  Tạo cuộc đua 7 ngày · thưởng XP gấp đôi
                </div>
              </div>
              <div style={{
                background: 'rgba(168,85,247,0.18)',
                border: '1px solid rgba(168,85,247,0.4)',
                color: '#DDD6FE', padding: '6px 12px', borderRadius: 999,
                fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 600, cursor: 'pointer',
              }}>Tạo</div>
            </div>

            <div style={{ height: 8 }} />
          </>
        )}

        {tab === 'requests' && (
          <>
            <div style={{ fontSize: 12, color: COLORS.textMuted, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT, padding: '4px 2px', marginBottom: 8 }}>
              Lời mời mới
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {requests.map((r) => (
                <div key={r.id} style={{
                  background: COLORS.nightSurface,
                  border: '1px solid rgba(56,189,248,0.18)',
                  borderRadius: 14, padding: '12px 14px',
                  display: 'flex', alignItems: 'center', gap: 12,
                }}>
                  <Avatar color={r.avatar} level={r.level} size={44} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT }}>{r.name}</div>
                    <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1 }}>
                      {r.handle} · {r.mutual} bạn chung
                    </div>
                  </div>
                  <button style={{
                    padding: '7px 12px', borderRadius: 999,
                    background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
                    border: 'none', color: 'white',
                    fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 600,
                    cursor: 'pointer',
                  }}>Chấp nhận</button>
                  <button style={{
                    width: 32, height: 32, borderRadius: 999,
                    background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)',
                    color: COLORS.textMuted, fontSize: 16, cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>×</button>
                </div>
              ))}
            </div>

            {/* Suggested */}
            <div style={{ fontSize: 12, color: COLORS.textMuted, letterSpacing: '0.08em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT, padding: '20px 2px 8px' }}>
              Có thể bạn biết
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {[
                { name: 'Khánh Lê', handle: '@khanhle', level: 6, mutual: 5, avatar: '#0EA5E9' },
                { name: 'Trang Phạm', handle: '@trangp', level: 10, mutual: 2, avatar: '#FB7185' },
                { name: 'An Đỗ', handle: '@ando', level: 3, mutual: 8, avatar: '#34D399' },
              ].map((s, i) => (
                <div key={i} style={{
                  background: COLORS.nightCard,
                  border: '1px solid rgba(255,255,255,0.04)',
                  borderRadius: 12, padding: '10px 12px',
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <Avatar color={s.avatar} level={s.level} size={36} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 500, color: 'white', fontFamily: FONT_TEXT }}>{s.name}</div>
                    <div style={{ fontSize: 10.5, color: COLORS.textMuted, marginTop: 1 }}>
                      {s.mutual} bạn chung
                    </div>
                  </div>
                  <button style={{
                    padding: '6px 10px', borderRadius: 999,
                    background: 'rgba(56,189,248,0.12)',
                    border: '1px solid rgba(56,189,248,0.3)',
                    color: '#BAE6FD', fontSize: 11, fontFamily: FONT_TEXT, fontWeight: 600,
                    cursor: 'pointer',
                  }}>+ Kết bạn</button>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Toast */}
      {toast && (
        <div style={{
          position: 'absolute', left: '50%', bottom: 100,
          transform: 'translateX(-50%)',
          background: 'rgba(15,23,42,0.95)', backdropFilter: 'blur(12px)',
          border: '1px solid rgba(56,189,248,0.3)',
          borderRadius: 999, padding: '10px 18px',
          fontSize: 13, color: '#BAE6FD', fontFamily: FONT_TEXT, fontWeight: 500,
          boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
          animation: 'toast-up 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)',
          zIndex: 20,
          whiteSpace: 'nowrap',
        }}>
          {toast}
        </div>
      )}

      <BottomTabBar active="friends" onNavigate={onNavigate} />

      <style>{`
        @keyframes toast-up {
          0% { transform: translate(-50%, 16px); opacity: 0; }
          100% { transform: translate(-50%, 0); opacity: 1; }
        }
      `}</style>
    </div>
  );
}

function Avatar({ color, level, size = 44, online }) {
  return (
    <div style={{ position: 'relative', flexShrink: 0 }}>
      <div style={{
        width: size, height: size, borderRadius: 999,
        background: `radial-gradient(circle at 30% 30%, ${color}EE, ${color}88)`,
        border: `1.5px solid ${color}55`,
        boxShadow: `0 2px 8px ${color}33`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {I.drop('white', size * 0.45)}
      </div>
      {level != null && (
        <div style={{
          position: 'absolute', bottom: -2, right: -2,
          background: '#1E1B4B', color: '#C7D2FE',
          fontFamily: FONT_ROUND, fontSize: 9, fontWeight: 700,
          padding: '1px 5px', borderRadius: 6,
          border: '1.5px solid #0B1120',
          letterSpacing: '0.04em',
        }}>{level}</div>
      )}
      {online && (
        <div style={{
          position: 'absolute', top: 0, right: 0,
          width: 10, height: 10, borderRadius: 999,
          background: '#10B981',
          border: '2px solid #0B1120',
        }} />
      )}
    </div>
  );
}

function FriendCard({ f, onNudge, onChallenge }) {
  const moodColor = f.mood === 'thirsty' ? '#F97316'
    : f.mood === 'low' ? '#FBBF24'
    : f.mood === 'glow' ? '#FBBF24'
    : '#10B981';
  const moodLabel = f.mood === 'thirsty' ? 'Đang khát'
    : f.mood === 'low' ? 'Hơi thấp'
    : f.mood === 'glow' ? 'Đang glow ✨'
    : 'Đủ nước';

  return (
    <div style={{
      background: COLORS.nightSurface,
      border: f.mood === 'thirsty' ? '1px solid rgba(249,115,22,0.3)' : `1px solid ${COLORS.border}`,
      borderRadius: 14, padding: '12px 14px',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* hot border glow when thirsty */}
      {f.mood === 'thirsty' && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(circle at 0% 50%, rgba(249,115,22,0.08), transparent 60%)',
          pointerEvents: 'none',
        }} />
      )}

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative' }}>
        <Avatar color={f.avatar} level={f.level} size={48} online={f.online} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT, letterSpacing: '-0.01em' }}>
              {f.name}
            </div>
            {f.streak >= 7 && (
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 2,
                background: 'rgba(249,115,22,0.12)', border: '1px solid rgba(249,115,22,0.3)',
                color: '#FB923C', padding: '1px 6px', borderRadius: 6,
                fontSize: 10, fontFamily: FONT_ROUND, fontWeight: 700,
              }}>
                🔥 {f.streak}
              </div>
            )}
          </div>
          <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 2, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ color: moodColor, fontWeight: 600 }}>{moodLabel}</span>
            <span style={{ opacity: 0.4 }}>·</span>
            <span>{f.lastDrink}</span>
          </div>

          {/* hydration progress bar */}
          <div style={{
            marginTop: 8, display: 'flex', alignItems: 'center', gap: 8,
          }}>
            <div style={{
              flex: 1, height: 5, background: 'rgba(255,255,255,0.05)',
              borderRadius: 999, overflow: 'hidden', position: 'relative',
            }}>
              <div style={{
                height: '100%', width: `${f.pct}%`,
                background: f.mood === 'thirsty' ? 'linear-gradient(90deg, #F97316, #FB923C)'
                  : f.mood === 'low' ? 'linear-gradient(90deg, #F59E0B, #FBBF24)'
                  : f.mood === 'glow' ? 'linear-gradient(90deg, #FBBF24, #38BDF8)'
                  : 'linear-gradient(90deg, #0EA5E9, #38BDF8)',
                borderRadius: 999,
                boxShadow: f.mood === 'glow' ? '0 0 8px rgba(56,189,248,0.6)' : 'none',
              }} />
            </div>
            <div style={{ fontSize: 11, fontFamily: FONT_ROUND, fontWeight: 700, color: 'white', minWidth: 32, textAlign: 'right', letterSpacing: '-0.01em' }}>
              {f.pct}%
            </div>
          </div>
        </div>
      </div>

      {/* Action row */}
      <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
        <button onClick={onNudge} disabled={f.reminded} style={{
          flex: 1, padding: '8px 10px', borderRadius: 10,
          background: f.reminded
            ? 'rgba(16,185,129,0.10)'
            : f.mood === 'thirsty' || f.mood === 'low'
              ? 'linear-gradient(135deg, rgba(56,189,248,0.22), rgba(14,165,233,0.16))'
              : 'rgba(56,189,248,0.10)',
          border: f.reminded
            ? '1px solid rgba(16,185,129,0.3)'
            : '1px solid rgba(56,189,248,0.3)',
          color: f.reminded ? '#86EFAC' : '#BAE6FD',
          fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 600,
          cursor: f.reminded ? 'default' : 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
        }}>
          {f.reminded ? (
            <>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12 L10 17 L19 7"/>
              </svg>
              Đã nhắc
            </>
          ) : (
            <>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 22 a2 2 0 0 0 2-2 H10 a2 2 0 0 0 2 2 z M19 17 V11 a7 7 0 0 0-5-6.7 V4 a2 2 0 0 0-4 0 V4.3 A7 7 0 0 0 5 11 V17 L3 19 V20 H21 V19 z"/>
              </svg>
              Nhắc uống nước
            </>
          )}
        </button>
        <button onClick={onChallenge} style={{
          padding: '8px 12px', borderRadius: 10,
          background: 'rgba(168,85,247,0.10)',
          border: '1px solid rgba(168,85,247,0.3)',
          color: '#DDD6FE', fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 600,
          cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
        }}>
          ⚔️ Đua
        </button>
        <button style={{
          width: 36, padding: '8px 0', borderRadius: 10,
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.08)',
          color: COLORS.textSecondary, fontSize: 14,
          cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/>
          </svg>
        </button>
      </div>
    </div>
  );
}

/* ─── Interactive weekly ranking ──────────────────────
   Tap a podium member → expands inline detail with quick actions.
   Period toggle re-sorts. "Your rank" row pinned when outside top 3. */
function InteractiveRanking({ friends, me, onNudge, onChallenge }) {
  const [period, setPeriod] = React.useState('week'); // week | month | all
  const [selected, setSelected] = React.useState(null); // friend id
  const [justChanged, setJustChanged] = React.useState(false);

  const PERIODS = [
    { id: 'week', label: 'Tuần này', left: 'Còn 2 ngày' },
    { id: 'month', label: 'Tháng', left: 'Còn 12 ngày' },
    { id: 'all', label: 'Mọi lúc', left: 'Mọi thời điểm' },
  ];

  // Score model differs per period so the toggle visibly re-ranks
  const scoreFor = (f) => {
    if (period === 'week') return f.pct + f.streak * 2;
    if (period === 'month') return f.pct * 0.6 + f.streak * 4 + f.level * 3;
    return f.level * 10 + f.streak * 3 + f.pct * 0.3;
  };

  // Full ranked list incl. "me"
  const everyone = [{ ...me, id: 'me', isMe: true }, ...friends];
  const ranked = everyone.slice().sort((a, b) => scoreFor(b) - scoreFor(a));
  const top3 = ranked.slice(0, 3);
  const myRank = ranked.findIndex((x) => x.isMe) + 1;
  const myEntry = ranked[myRank - 1];
  const meInTop3 = myRank <= 3;

  const curPeriod = PERIODS.find((p) => p.id === period);

  function switchPeriod(id) {
    if (id === period) return;
    setSelected(null);
    setPeriod(id);
    setJustChanged(true);
    setTimeout(() => setJustChanged(false), 420);
  }

  // podium visual order: 2nd, 1st, 3rd
  const order = [top3[1], top3[0], top3[2]];
  const ranksByPos = [2, 1, 3];

  const selFriend = selected ? friends.find((f) => f.id === selected) : null;

  return (
    <div style={{
      background: 'linear-gradient(150deg, rgba(251,191,36,0.10), rgba(168,85,247,0.07) 60%, rgba(56,189,248,0.05))',
      border: '1px solid rgba(251,191,36,0.18)',
      borderRadius: 18, padding: '14px 14px 14px',
      marginBottom: 16,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* soft top glow */}
      <div style={{
        position: 'absolute', top: -70, left: '50%', transform: 'translateX(-50%)',
        width: 240, height: 140, borderRadius: '50%',
        background: 'radial-gradient(ellipse, rgba(251,191,36,0.22), transparent 70%)',
        pointerEvents: 'none',
      }} />

      {/* Header: title + countdown */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {I.trophy('#FBBF24', 15)}
          <div style={{ fontSize: 11.5, color: '#FCD34D', fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
            Bảng xếp hạng
          </div>
        </div>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 5,
          background: 'rgba(0,0,0,0.25)', border: '1px solid rgba(255,255,255,0.06)',
          borderRadius: 999, padding: '3px 10px',
          fontSize: 10.5, color: '#FCD34D', fontFamily: FONT_TEXT, fontWeight: 600,
        }}>
          <span style={{ width: 5, height: 5, borderRadius: 999, background: '#FBBF24', boxShadow: '0 0 6px #FBBF24' }} />
          {curPeriod.left}
        </div>
      </div>

      {/* Period segmented control */}
      <div style={{
        display: 'flex', gap: 3, position: 'relative',
        background: 'rgba(0,0,0,0.3)', borderRadius: 10, padding: 3,
        border: '1px solid rgba(255,255,255,0.05)', marginBottom: 16,
      }}>
        {PERIODS.map((p) => {
          const on = p.id === period;
          return (
            <button key={p.id} onClick={() => switchPeriod(p.id)} style={{
              flex: 1, padding: '7px 0', borderRadius: 8,
              background: on ? 'linear-gradient(135deg, rgba(251,191,36,0.25), rgba(245,158,11,0.18))' : 'transparent',
              border: on ? '1px solid rgba(251,191,36,0.4)' : '1px solid transparent',
              color: on ? '#FDE68A' : COLORS.textSecondary,
              fontSize: 12, fontWeight: 600, fontFamily: FONT_TEXT,
              cursor: 'pointer', transition: 'all 0.18s',
            }}>{p.label}</button>
          );
        })}
      </div>

      {/* Podium row */}
      <div key={period + (justChanged ? '1' : '0')} style={{
        display: 'flex', alignItems: 'flex-end', gap: 8, justifyContent: 'center',
        position: 'relative',
        animation: justChanged ? 'rank-pop 0.42s cubic-bezier(0.34,1.56,0.64,1)' : 'none',
      }}>
        {order.map((f, i) => (
          <PodiumColumn
            key={f ? f.id : i}
            f={f}
            rank={ranksByPos[i]}
            selected={selected === (f && f.id)}
            onSelect={() => {
              if (!f || f.isMe) { setSelected(null); return; }
              setSelected((s) => s === f.id ? null : f.id);
            }}
          />
        ))}
      </div>

      {/* Expanded detail for selected podium member */}
      {selFriend && (
        <div style={{
          marginTop: 14,
          background: 'rgba(8,15,30,0.72)', backdropFilter: 'blur(8px)',
          border: `1px solid ${selFriend.avatar}44`,
          borderRadius: 14, padding: '12px 14px',
          animation: 'rank-detail 0.28s cubic-bezier(0.34,1.4,0.64,1)',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', top: -30, right: -20, width: 120, height: 120, borderRadius: '50%',
            background: `radial-gradient(circle, ${selFriend.avatar}22, transparent 70%)`, pointerEvents: 'none',
          }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative' }}>
            <DropAvatar color={selFriend.avatar} pct={selFriend.pct} size={46} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: 'white', fontFamily: FONT_TEXT }}>{selFriend.name}</div>
              <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1, fontFamily: FONT_TEXT }}>
                {selFriend.handle} · uống lần cuối {selFriend.lastDrink}
              </div>
            </div>
            <button onClick={() => setSelected(null)} style={{
              width: 26, height: 26, borderRadius: 999, flexShrink: 0,
              background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)',
              color: COLORS.textMuted, cursor: 'pointer', fontSize: 14,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>×</button>
          </div>

          {/* mini stats */}
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            <MiniStat label="Hydrate" value={`${selFriend.pct}%`} color="#38BDF8" />
            <MiniStat label="Streak" value={`${selFriend.streak} ngày`} color="#FB923C" />
            <MiniStat label="Cấp" value={`LV ${selFriend.level}`} color="#A78BFA" />
          </div>

          {/* actions */}
          <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
            <button
              onClick={() => onNudge(selFriend)}
              disabled={selFriend.reminded}
              style={{
                flex: 1, padding: '9px 10px', borderRadius: 10,
                background: selFriend.reminded ? 'rgba(16,185,129,0.10)' : 'linear-gradient(135deg, rgba(56,189,248,0.24), rgba(14,165,233,0.18))',
                border: selFriend.reminded ? '1px solid rgba(16,185,129,0.3)' : '1px solid rgba(56,189,248,0.35)',
                color: selFriend.reminded ? '#86EFAC' : '#BAE6FD',
                fontSize: 12, fontFamily: FONT_TEXT, fontWeight: 600,
                cursor: selFriend.reminded ? 'default' : 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              }}>
              {selFriend.reminded ? '✓ Đã nhắc' : '💧 Nhắc uống nước'}
            </button>
            <button onClick={() => onChallenge(selFriend)} style={{
              flex: 1, padding: '9px 10px', borderRadius: 10,
              background: 'rgba(168,85,247,0.14)', border: '1px solid rgba(168,85,247,0.35)',
              color: '#DDD6FE', fontSize: 12, fontFamily: FONT_TEXT, fontWeight: 600,
              cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>⚔️ Thách đấu</button>
          </div>
        </div>
      )}

      {/* Your rank pill */}
      <div style={{
        marginTop: 14,
        display: 'flex', alignItems: 'center', gap: 12,
        background: meInTop3 ? 'rgba(56,189,248,0.10)' : 'rgba(255,255,255,0.04)',
        border: `1px solid ${meInTop3 ? 'rgba(56,189,248,0.3)' : 'rgba(255,255,255,0.08)'}`,
        borderRadius: 12, padding: '10px 12px',
        position: 'relative',
      }}>
        <div style={{
          width: 30, textAlign: 'center', flexShrink: 0,
          fontFamily: FONT_ROUND, fontWeight: 800, fontSize: 16,
          color: meInTop3 ? '#7DD3FC' : COLORS.textSecondary,
          letterSpacing: '-0.02em',
        }}>#{myRank}</div>
        <DropAvatar color={me.avatar} pct={myEntry.pct} size={38} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: 'white', fontFamily: FONT_TEXT }}>
            Bạn {meInTop3 && <span style={{ color: '#FCD34D', fontSize: 11 }}>· trong top 3 🎉</span>}
          </div>
          <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 1, fontFamily: FONT_TEXT }}>
            {myEntry.pct}% hôm nay · streak {me.streak} ngày
          </div>
        </div>
        {!meInTop3 && (() => {
          const ahead = ranked[myRank - 2];
          const gap = ahead ? Math.max(1, Math.round(scoreFor(ahead) - scoreFor(myEntry))) : 0;
          return (
            <div style={{
              textAlign: 'right', flexShrink: 0,
              fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT, lineHeight: 1.3,
            }}>
              <div style={{ color: '#7DD3FC', fontWeight: 600 }}>+{gap} điểm</div>
              <div>để vượt #{myRank - 1}</div>
            </div>
          );
        })()}
      </div>

      <style>{`
        @keyframes rank-pop {
          0% { opacity: 0.4; transform: translateY(8px) scale(0.97); }
          100% { opacity: 1; transform: translateY(0) scale(1); }
        }
        @keyframes rank-detail {
          0% { opacity: 0; transform: translateY(-6px) scale(0.98); }
          100% { opacity: 1; transform: translateY(0) scale(1); }
        }
        @keyframes drop-wave {
          0%, 100% { transform: translateX(0); }
          50% { transform: translateX(-12px); }
        }
      `}</style>
    </div>
  );
}

function MiniStat({ label, value, color }) {
  return (
    <div style={{
      flex: 1, textAlign: 'center',
      background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.05)',
      borderRadius: 10, padding: '8px 4px',
    }}>
      <div style={{ fontSize: 14, fontWeight: 700, color, fontFamily: FONT_ROUND, letterSpacing: '-0.01em' }}>{value}</div>
      <div style={{ fontSize: 9.5, color: COLORS.textMuted, marginTop: 2, fontFamily: FONT_TEXT, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{label}</div>
    </div>
  );
}

// Water-fill drop avatar — fill height reflects pct
function DropAvatar({ color, pct, size = 50, ring }) {
  const fillH = Math.max(8, Math.min(100, pct));
  return (
    <div style={{
      width: size, height: size, borderRadius: 999, flexShrink: 0,
      background: 'rgba(8,20,38,0.9)',
      border: ring ? `2px solid ${ring}` : `1.5px solid ${color}66`,
      boxShadow: ring ? `0 0 16px ${ring}77` : `0 2px 8px ${color}33`,
      position: 'relative', overflow: 'hidden',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {/* water fill */}
      <div style={{
        position: 'absolute', left: '-20%', right: '-20%', bottom: 0,
        height: `${fillH}%`,
        background: `linear-gradient(180deg, ${color}EE, ${color}AA)`,
        transition: 'height 0.5s cubic-bezier(0.34,1.4,0.64,1)',
      }}>
        {/* wavy top */}
        <div style={{
          position: 'absolute', top: -4, left: 0, right: 0, height: 8,
          background: color, borderRadius: '50%',
          opacity: 0.6,
          animation: 'drop-wave 2.6s ease-in-out infinite',
        }} />
      </div>
      {/* drop glyph on top */}
      <div style={{ position: 'relative', zIndex: 1, opacity: 0.92 }}>
        {I.drop('white', size * 0.42)}
      </div>
    </div>
  );
}

function PodiumColumn({ f, rank, selected, onSelect }) {
  if (!f) return <div style={{ flex: 1 }} />;
  const ringColor = rank === 1 ? '#FBBF24' : rank === 2 ? '#CBD5E1' : '#D97706';
  const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : '🥉';
  const isFirst = rank === 1;
  const avatarSize = isFirst ? 64 : 52;
  const pedH = rank === 1 ? 50 : rank === 2 ? 36 : 26;
  const shortName = f.isMe ? 'Bạn' : f.name.split(' ').slice(-1)[0];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1, minWidth: 0 }}>
      {/* crown for #1 */}
      <div style={{ height: 18, display: 'flex', alignItems: 'flex-end', marginBottom: 2 }}>
        {isFirst && <span style={{ fontSize: 16, filter: 'drop-shadow(0 2px 4px rgba(251,191,36,0.6))' }}>👑</span>}
      </div>

      <button
        onClick={onSelect}
        style={{
          background: 'none', border: 'none', padding: 0, cursor: f.isMe ? 'default' : 'pointer',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          width: '100%',
          transform: selected ? 'translateY(-3px)' : 'none',
          transition: 'transform 0.2s',
        }}>
        <div style={{ position: 'relative' }}>
          <DropAvatar color={f.avatar} pct={f.pct} size={avatarSize} ring={ringColor} />
          {/* medal badge */}
          <div style={{
            position: 'absolute', bottom: -6, left: '50%', transform: 'translateX(-50%)',
            width: 22, height: 22, borderRadius: 999,
            background: '#0B1120', border: `1.5px solid ${ringColor}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 11, zIndex: 2,
          }}>{medal}</div>
          {/* tap hint ring when selected */}
          {selected && (
            <div style={{
              position: 'absolute', inset: -4, borderRadius: 999,
              border: `1.5px dashed ${ringColor}`, opacity: 0.7,
              pointerEvents: 'none',
            }} />
          )}
        </div>

        <div style={{
          fontSize: isFirst ? 13 : 12, fontWeight: 700,
          color: f.isMe ? '#7DD3FC' : 'white', fontFamily: FONT_TEXT,
          textAlign: 'center', maxWidth: '100%', overflow: 'hidden',
          textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginTop: 4,
        }}>{shortName}</div>
      </button>

      {/* pedestal */}
      <div style={{
        width: '86%', height: pedH, marginTop: 8,
        background: isFirst
          ? `linear-gradient(180deg, ${ringColor}3A, ${ringColor}10)`
          : 'rgba(255,255,255,0.05)',
        border: `1px solid ${isFirst ? ringColor + '55' : 'rgba(255,255,255,0.08)'}`,
        borderRadius: '10px 10px 6px 6px',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        <div style={{
          fontSize: isFirst ? 17 : 15, fontFamily: FONT_ROUND, fontWeight: 800,
          color: 'white', letterSpacing: '-0.02em', lineHeight: 1,
        }}>{f.pct}%</div>
        {f.streak >= 7 && (
          <div style={{ fontSize: 9, color: '#FB923C', fontFamily: FONT_ROUND, fontWeight: 700, marginTop: 2 }}>
            🔥{f.streak}
          </div>
        )}
      </div>
    </div>
  );
}

window.FriendsScreen = FriendsScreen;
