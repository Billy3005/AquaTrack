// LevelScreen — gamification, achievements, rewards
function LevelScreen({ onNavigate }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '54px 20px 12px' }}>
        <div style={{ fontSize: 11, color: '#C7D2FE', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
          Hành trình
        </div>
        <div style={{ fontSize: 26, fontWeight: 600, color: 'white', letterSpacing: '-0.02em', marginTop: 2 }}>
          Cấp độ & Thành tựu
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 20px' }}>
        {/* Level card */}
        <div style={{
          background: 'linear-gradient(135deg, #1A1040 0%, #2D1B6B 100%)',
          border: '1px solid #4F46E5',
          borderRadius: 18,
          padding: 18,
          marginBottom: 16,
          position: 'relative',
          overflow: 'hidden',
        }}>
          {/* shimmer */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'radial-gradient(circle at 80% 20%, rgba(165,180,252,0.25), transparent 50%)',
            pointerEvents: 'none',
          }} />

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
            <div>
              <div style={{ fontSize: 11, color: '#A5B4FC', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
                Cấp hiện tại
              </div>
              <div style={{ fontSize: 30, fontWeight: 700, color: 'white', letterSpacing: '-0.02em', marginTop: 2, fontFamily: FONT_ROUND }}>
                Aqua Warrior
              </div>
              <div style={{ fontSize: 12, color: '#C7D2FE', marginTop: 2, fontFamily: FONT_TEXT }}>
                Còn 760 XP để lên Lv 8
              </div>
            </div>
            <div style={{
              background: '#4F46E5',
              color: '#E0E7FF',
              padding: '4px 10px',
              borderRadius: 8,
              fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 13,
              letterSpacing: '0.04em',
              boxShadow: '0 2px 8px rgba(79,70,229,0.5)',
            }}>LV 7</div>
          </div>

          <div style={{ marginTop: 18, position: 'relative' }}>
            <XPBar xp={1240} xpMax={2000} level={7} levelName="Aqua Warrior" trackBg="#312E81" />
          </div>

          {/* Level ladder */}
          <div style={{
            display: 'flex', justifyContent: 'space-between', marginTop: 14,
            fontSize: 9.5, color: 'rgba(199,210,254,0.5)', fontFamily: FONT_ROUND, fontWeight: 600,
          }}>
            {[
              { lv: 5, n: 'Water Warrior' },
              { lv: 7, n: 'Aqua Warrior', cur: true },
              { lv: 10, n: 'Ocean Master' },
              { lv: 15, n: 'Hydration Legend' },
            ].map((s, i) => (
              <div key={i} style={{ textAlign: 'center', flex: 1, opacity: s.cur ? 1 : 0.6 }}>
                <div style={{ color: s.cur ? '#FBBF24' : '#A5B4FC', fontSize: 11, fontWeight: 700 }}>LV {s.lv}</div>
                <div style={{ marginTop: 1, color: s.cur ? 'white' : 'inherit' }}>{s.n}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Achievements */}
        <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, marginBottom: 10, fontFamily: FONT_TEXT }}>
          Thành tựu
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
          <Achievement icon="🔥" name="Streak 7 ngày" cond="7-day streak" reward="+50 XP" unlocked />
          <Achievement icon="⭐" name="Đủ nước 5 lần" cond="5× daily goal" reward="Theme unlock" unlocked />
          <Achievement icon="🌊" name="Tuần 14L" cond="2,000ml × 7 ngày" reward="Avatar frame" />
          <Achievement icon="🏆" name="Top 10% tuần" cond="Leaderboard" reward="Special badge" />
        </div>

        {/* Rewards */}
        <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, marginBottom: 10, fontFamily: FONT_TEXT }}>
          Phần thưởng đã mở khoá
        </div>
        <div style={{
          background: COLORS.nightSurface,
          border: `1px solid ${COLORS.border}`,
          borderRadius: 14,
          padding: 14,
        }}>
          <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 8 }}>
            Avatars
          </div>
          <div style={{ display: 'flex', gap: 10, marginBottom: 14 }}>
            {[
              { c: '#38BDF8', n: 'Drop', u: true },
              { c: '#0EA5E9', n: 'Wave', u: true },
              { c: '#0284C7', n: 'Ocean', u: false },
              { c: '#A78BFA', n: 'Glacier', u: false },
              { c: '#94A3B8', n: 'Cloud', u: false },
            ].map((a, i) => (
              <div key={i} style={{ flex: 1, textAlign: 'center', opacity: a.u ? 1 : 0.4 }}>
                <div style={{
                  width: '100%', aspectRatio: '1', borderRadius: 12,
                  background: a.u ? `radial-gradient(circle at 30% 30%, ${a.c}DD, ${a.c}66)` : 'rgba(255,255,255,0.05)',
                  border: a.u ? `1px solid ${a.c}88` : '1px dashed rgba(255,255,255,0.15)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 4,
                  boxShadow: a.u ? `0 4px 12px ${a.c}33` : 'none',
                }}>
                  {a.u ? I.drop('white', 18) : <span style={{ fontSize: 11, color: COLORS.textMuted }}>🔒</span>}
                </div>
                <div style={{ fontSize: 9.5, color: COLORS.textSecondary, fontFamily: FONT_ROUND }}>{a.n}</div>
              </div>
            ))}
          </div>
          <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 8 }}>
            Themes
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { n: 'Ocean Night', cur: true, g: 'linear-gradient(135deg, #0C4A80, #082F5C)' },
              { n: 'Default Blue', g: 'linear-gradient(135deg, #38BDF8, #0EA5E9)' },
              { n: 'Desert', g: 'linear-gradient(135deg, #F59E0B, #92400E)', locked: true },
              { n: 'Forest Rain', g: 'linear-gradient(135deg, #059669, #064E3B)', locked: true },
            ].map((t, i) => (
              <div key={i} style={{ flex: 1 }}>
                <div style={{
                  height: 38, borderRadius: 8, background: t.g,
                  border: t.cur ? '2px solid #FBBF24' : '1px solid rgba(255,255,255,0.1)',
                  opacity: t.locked ? 0.4 : 1,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {t.locked && <span style={{ fontSize: 10, color: 'white' }}>🔒</span>}
                </div>
                <div style={{ fontSize: 9.5, color: COLORS.textSecondary, fontFamily: FONT_ROUND, marginTop: 4, textAlign: 'center' }}>{t.n}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <BottomTabBar active="level" onNavigate={onNavigate} />
    </div>
  );
}

function Achievement({ icon, name, cond, reward, unlocked }) {
  return (
    <div style={{
      background: unlocked ? 'linear-gradient(135deg, rgba(129,140,248,0.10), rgba(56,189,248,0.06))' : COLORS.nightSurface,
      border: unlocked ? '1px solid rgba(129,140,248,0.4)' : '1px dashed rgba(255,255,255,0.1)',
      borderRadius: 14, padding: 12,
      opacity: unlocked ? 1 : 0.55,
      position: 'relative',
    }}>
      <div style={{ fontSize: 22, marginBottom: 4, filter: unlocked ? 'none' : 'grayscale(1)' }}>{icon}</div>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: COLORS.textPrimary, fontFamily: FONT_TEXT, letterSpacing: '-0.01em' }}>{name}</div>
      <div style={{ fontSize: 10.5, color: COLORS.textSecondary, marginTop: 2, fontFamily: FONT_TEXT }}>{cond}</div>
      <div style={{
        marginTop: 8,
        fontSize: 10, color: unlocked ? '#FDE68A' : COLORS.textMuted,
        fontFamily: FONT_ROUND, fontWeight: 600, letterSpacing: '0.04em',
      }}>{unlocked ? `✓ ${reward}` : reward}</div>
    </div>
  );
}

window.LevelScreen = LevelScreen;
