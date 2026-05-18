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

  // Top 3 of week (by pct + streak)
  const podium = friends.slice().sort((a, b) => (b.pct + b.streak * 2) - (a.pct + a.streak * 2)).slice(0, 3);

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
            {/* Weekly podium */}
            <div style={{
              background: 'linear-gradient(135deg, rgba(251,191,36,0.10), rgba(168,85,247,0.06))',
              border: '1px solid rgba(251,191,36,0.2)',
              borderRadius: 16, padding: '14px 14px 16px',
              marginBottom: 16,
              position: 'relative', overflow: 'hidden',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  {I.trophy('#FBBF24', 14)}
                  <div style={{ fontSize: 11, color: '#FCD34D', fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
                    Tuần này
                  </div>
                </div>
                <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT }}>
                  Còn 2 ngày
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, justifyContent: 'center' }}>
                {/* 2nd */}
                <PodiumPos rank={2} f={podium[1]} h={62} medal="🥈" />
                {/* 1st */}
                <PodiumPos rank={1} f={podium[0]} h={84} medal="🥇" />
                {/* 3rd */}
                <PodiumPos rank={3} f={podium[2]} h={48} medal="🥉" />
              </div>
            </div>

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

function PodiumPos({ rank, f, h, medal }) {
  if (!f) return null;
  const ringColor = rank === 1 ? '#FBBF24' : rank === 2 ? '#CBD5E1' : '#D97706';
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, flex: 1 }}>
      <div style={{ position: 'relative' }}>
        <div style={{
          width: rank === 1 ? 56 : 46, height: rank === 1 ? 56 : 46, borderRadius: 999,
          background: `radial-gradient(circle at 30% 30%, ${f.avatar}EE, ${f.avatar}88)`,
          border: `2px solid ${ringColor}`,
          boxShadow: rank === 1 ? `0 0 16px ${ringColor}88` : 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {I.drop('white', rank === 1 ? 24 : 20)}
        </div>
        <div style={{
          position: 'absolute', top: -8, right: -8, fontSize: rank === 1 ? 18 : 14,
        }}>{medal}</div>
      </div>
      <div style={{ fontSize: 11, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT, textAlign: 'center', maxWidth: 80, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
        {f.name.split(' ').slice(-1)[0]}
      </div>
      <div style={{
        background: rank === 1 ? `linear-gradient(180deg, ${ringColor}33, ${ringColor}11)` : 'rgba(255,255,255,0.04)',
        border: `1px solid ${rank === 1 ? ringColor + '44' : 'rgba(255,255,255,0.08)'}`,
        borderRadius: 8, padding: '4px 10px',
        fontSize: 12, fontFamily: FONT_ROUND, fontWeight: 700, color: 'white',
        letterSpacing: '-0.01em',
      }}>{f.pct}%</div>
    </div>
  );
}

window.FriendsScreen = FriendsScreen;
