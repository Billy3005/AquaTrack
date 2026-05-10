// ProfileScreen — user identity, lifetime stats, settings, body data
function ProfileScreen({ onNavigate }) {
  const [goal, setGoal] = React.useState(2500);
  const [editingGoal, setEditingGoal] = React.useState(false);
  const [reminders, setReminders] = React.useState([
    { time: '08:00', tone: 'Energetic', label: 'Khởi động ngày mới', on: true },
    { time: '12:00', tone: 'Friendly', label: 'Nhắc giữa trưa', on: true },
    { time: '15:00', tone: 'Gentle', label: 'Buổi chiều dễ quên', on: true },
    { time: '18:30', tone: 'Friendly', label: 'Sau giờ làm', on: false },
    { time: '20:00', tone: 'Calm', label: 'Cuối ngày', on: true },
  ]);
  const [bodyData] = React.useState({
    weight: 62, activity: 'Vừa phải', climate: 'Nhiệt đới (HCMC)', age: 28,
  });

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header w/ subtle gradient */}
      <div style={{
        background: 'linear-gradient(180deg, #0C2A4A 0%, #0B1120 100%)',
        padding: '54px 20px 16px',
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', top: -40, right: -40, width: 200, height: 200,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.18), transparent 60%)',
        }} />
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
            Profile
          </div>
          <button style={{
            width: 36, height: 36, borderRadius: 999,
            background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="3"/>
              <path d="M19.4 15 a2 2 0 0 0 0.4 2.2 L20 17.5 a1.6 1.6 0 0 1-2.3 2.3 L17.4 19.6 a2 2 0 0 0-2.2 0.4 a2 2 0 0 0-1.2 1.8 L14 22 a1.6 1.6 0 0 1-3.2 0 V21.8 a2 2 0 0 0-1.3-1.8 a2 2 0 0 0-2.2-0.4 L7.0 19.7 a1.6 1.6 0 0 1-2.3-2.3 L4.8 17.2 a2 2 0 0 0 0.4-2.2 a2 2 0 0 0-1.8-1.2 L3 13.6 a1.6 1.6 0 0 1 0-3.2 H3.4 a2 2 0 0 0 1.8-1.3 a2 2 0 0 0-0.4-2.2 L4.5 6.6 a1.6 1.6 0 0 1 2.3-2.3 L7.0 4.5 a2 2 0 0 0 2.2 0.4 H9.4 a2 2 0 0 0 1.2-1.8 V3 a1.6 1.6 0 0 1 3.2 0 V3.4 a2 2 0 0 0 1.2 1.8 a2 2 0 0 0 2.2-0.4 L17.4 4.5 a1.6 1.6 0 0 1 2.3 2.3 L19.6 7 a2 2 0 0 0-0.4 2.2 V9.4 a2 2 0 0 0 1.8 1.2 H21 a1.6 1.6 0 0 1 0 3.2 H20.6 a2 2 0 0 0-1.8 1.2 z"/>
            </svg>
          </button>
        </div>

        {/* Avatar + name */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 14 }}>
          {/* Avatar with frame ring */}
          <div style={{ position: 'relative', flexShrink: 0 }}>
            <div style={{
              width: 76, height: 76, borderRadius: 999,
              padding: 3,
              background: 'conic-gradient(from 220deg, #FBBF24, #818CF8, #38BDF8, #FBBF24)',
              boxShadow: '0 0 24px rgba(56,189,248,0.35)',
            }}>
              <div style={{
                width: '100%', height: '100%', borderRadius: 999,
                background: 'radial-gradient(circle at 30% 30%, #7DD3FC, #0284C7)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                border: '2px solid #0B1120',
              }}>
                {I.drop('white', 32)}
              </div>
            </div>
            {/* level chip on avatar */}
            <div style={{
              position: 'absolute', bottom: -4, right: -4,
              background: '#4F46E5', color: '#E0E7FF',
              fontFamily: FONT_ROUND, fontSize: 11, fontWeight: 700,
              padding: '3px 8px', borderRadius: 8,
              border: '2px solid #0B1120',
              letterSpacing: '0.04em',
            }}>LV 7</div>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 20, fontWeight: 600, color: 'white', letterSpacing: '-0.02em', fontFamily: FONT }}>
              Minh Nguyễn
            </div>
            <div style={{ fontSize: 12.5, color: '#A5B4FC', fontFamily: FONT_ROUND, fontWeight: 600, marginTop: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
              Aqua Warrior
              <span style={{ width: 3, height: 3, borderRadius: 999, background: '#A5B4FC', display: 'inline-block', opacity: 0.6 }} />
              <span style={{ color: COLORS.textSecondary, fontFamily: FONT_TEXT, fontWeight: 500 }}>Tham gia 84 ngày</span>
            </div>
            <div style={{ marginTop: 8 }}>
              <XPBar xp={1240} xpMax={2000} level={7} levelName="Aqua Warrior" />
            </div>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '16px 16px 20px' }}>
        {/* Lifetime stats */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 18 }}>
          <LifetimeStat icon={I.drop('#38BDF8', 16)} value="284L" label="Total water" />
          <LifetimeStat icon={I.flame('#F97316', 16)} value="21" label="Longest streak" sub="ngày" />
          <LifetimeStat icon={
            <svg width="16" height="16" viewBox="0 0 24 24" fill="#A78BFA">
              <rect x="3" y="5" width="18" height="16" rx="2"/>
              <path d="M7 3 V7 M17 3 V7" stroke="#A78BFA" strokeWidth="2" strokeLinecap="round"/>
              <rect x="3" y="9" width="18" height="1" fill="#0B1120"/>
            </svg>
          } value="84" label="Days active" sub="trên 90" />
        </div>

        {/* Avatar collection */}
        <SectionHeader title="Avatar collection" trailing="3/5" />
        <div style={{
          display: 'flex', gap: 10, overflowX: 'auto',
          paddingBottom: 8, marginBottom: 18,
          scrollbarWidth: 'none',
        }}>
          {[
            { c: '#38BDF8', n: 'Drop', u: true, cur: true },
            { c: '#0EA5E9', n: 'Wave', u: true },
            { c: '#A78BFA', n: 'Glacier', u: true },
            { c: '#0284C7', n: 'Ocean', u: false, lvl: 'LV 10' },
            { c: '#94A3B8', n: 'Cloud', u: false, lvl: 'LV 12' },
            { c: '#10B981', n: 'Spring', u: false, lvl: 'LV 15' },
          ].map((a, i) => (
            <div key={i} style={{ flexShrink: 0, width: 84, textAlign: 'center' }}>
              <div style={{
                width: 84, height: 84, borderRadius: 18,
                background: a.u
                  ? `radial-gradient(circle at 30% 30%, ${a.c}DD, ${a.c}55)`
                  : 'rgba(255,255,255,0.04)',
                border: a.cur
                  ? '2px solid #FBBF24'
                  : a.u
                  ? `1px solid ${a.c}66`
                  : '1px dashed rgba(255,255,255,0.15)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                position: 'relative',
                marginBottom: 6,
                boxShadow: a.u ? `0 4px 12px ${a.c}33` : 'none',
                opacity: a.u ? 1 : 0.5,
              }}>
                {a.u ? I.drop('white', 30) : <span style={{ fontSize: 14, color: COLORS.textMuted }}>🔒</span>}
                {a.cur && (
                  <div style={{
                    position: 'absolute', top: -8, right: -8,
                    background: '#FBBF24', color: '#451A03',
                    fontSize: 9, fontWeight: 700, fontFamily: FONT_ROUND,
                    padding: '2px 7px', borderRadius: 999,
                    letterSpacing: '0.04em',
                  }}>CUR</div>
                )}
              </div>
              <div style={{ fontSize: 11, color: COLORS.textSecondary, fontFamily: FONT_ROUND, fontWeight: 600 }}>
                {a.n}
              </div>
              {!a.u && (
                <div style={{ fontSize: 9.5, color: COLORS.textMuted, fontFamily: FONT_ROUND, marginTop: 1 }}>
                  {a.lvl}
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Themes */}
        <SectionHeader title="Themes" trailing="2/4" />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
          {[
            { n: 'Ocean Night', g: 'linear-gradient(135deg, #0C4A80, #082F5C)', cur: true, u: true },
            { n: 'Default Blue', g: 'linear-gradient(135deg, #38BDF8, #0EA5E9)', u: true },
            { n: 'Desert Sunset', g: 'linear-gradient(135deg, #F59E0B, #92400E)', lvl: 'LV 9' },
            { n: 'Forest Rain', g: 'linear-gradient(135deg, #059669, #064E3B)', lvl: 'LV 11' },
          ].map((t, i) => (
            <div key={i} style={{
              borderRadius: 14, padding: 12,
              background: COLORS.nightSurface,
              border: t.cur ? '1.5px solid #FBBF24' : '1px solid rgba(255,255,255,0.06)',
              opacity: t.u ? 1 : 0.6,
              display: 'flex', gap: 10, alignItems: 'center',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: t.g,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                opacity: t.u ? 1 : 0.5,
              }}>
                {!t.u && <span style={{ fontSize: 13 }}>🔒</span>}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600, color: 'white', fontFamily: FONT_TEXT }}>{t.n}</div>
                <div style={{ fontSize: 10, color: t.cur ? '#FBBF24' : COLORS.textMuted, fontFamily: FONT_ROUND, fontWeight: 600, marginTop: 1 }}>
                  {t.cur ? 'Đang dùng' : t.u ? 'Đã mở' : t.lvl}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Daily goal */}
        <SectionHeader title="Mục tiêu hàng ngày" />
        <div style={{
          background: COLORS.nightCard, borderRadius: 14, padding: '14px 16px',
          marginBottom: 18,
          border: '1px solid rgba(56,189,248,0.15)',
          display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{ flexShrink: 0 }}>{I.drop('#38BDF8', 22)}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, color: COLORS.textMuted, letterSpacing: '0.06em', textTransform: 'uppercase', fontWeight: 600, fontFamily: FONT_TEXT }}>
              Daily goal
            </div>
            {editingGoal ? (
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 2 }}>
                <input
                  type="number"
                  value={goal}
                  step={100}
                  min={1500}
                  max={4000}
                  autoFocus
                  onBlur={() => setEditingGoal(false)}
                  onKeyDown={(e) => e.key === 'Enter' && setEditingGoal(false)}
                  onChange={(e) => setGoal(Number(e.target.value))}
                  style={{
                    background: 'rgba(56,189,248,0.1)',
                    border: '1px solid rgba(56,189,248,0.4)',
                    borderRadius: 6, padding: '2px 6px',
                    color: 'white', fontSize: 18, fontWeight: 700,
                    fontFamily: FONT_ROUND, letterSpacing: '-0.02em',
                    width: 90, outline: 'none',
                  }}
                />
                <span style={{ fontSize: 12, color: COLORS.textSecondary }}>ml/day</span>
              </div>
            ) : (
              <div onClick={() => setEditingGoal(true)} style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 2, cursor: 'pointer' }}>
                <div style={{ fontSize: 22, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em' }}>
                  {goal.toLocaleString()}
                </div>
                <div style={{ fontSize: 12, color: COLORS.textSecondary }}>ml / day</div>
              </div>
            )}
            <div style={{ fontSize: 11, color: COLORS.textBright, marginTop: 4, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 4 }}>
              {I.spark('#38BDF8', 11)} AI điều chỉnh +300ml hôm nay (nóng)
            </div>
          </div>
          <button onClick={() => setEditingGoal(!editingGoal)} style={{
            background: 'rgba(56,189,248,0.12)', border: '1px solid rgba(56,189,248,0.3)',
            borderRadius: 999, padding: '6px 12px',
            color: '#BAE6FD', fontFamily: FONT_TEXT, fontSize: 11.5, fontWeight: 600,
            cursor: 'pointer',
          }}>{editingGoal ? 'Lưu' : 'Sửa'}</button>
        </div>

        {/* Reminder schedule */}
        <SectionHeader title="Lịch nhắc nhở" trailing={`${reminders.filter((r) => r.on).length}/${reminders.length}`} />
        <div style={{
          background: COLORS.nightSurface, borderRadius: 14,
          border: `1px solid ${COLORS.border}`,
          marginBottom: 18, overflow: 'hidden',
        }}>
          {reminders.map((r, i) => (
            <div key={i} style={{
              padding: '12px 14px',
              borderBottom: i < reminders.length - 1 ? '1px solid rgba(255,255,255,0.04)' : 'none',
              display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 10,
                background: r.on ? 'rgba(56,189,248,0.12)' : 'rgba(255,255,255,0.04)',
                border: r.on ? '1px solid rgba(56,189,248,0.3)' : '1px solid rgba(255,255,255,0.06)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 12,
                color: r.on ? '#BAE6FD' : COLORS.textMuted,
                fontFeatureSettings: '"tnum"',
                flexShrink: 0,
              }}>
                {r.time}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 500, color: r.on ? COLORS.textPrimary : COLORS.textMuted, fontFamily: FONT_TEXT }}>
                  {r.label}
                </div>
                <div style={{ fontSize: 10.5, color: COLORS.textMuted, marginTop: 1, fontFamily: FONT_TEXT }}>
                  Tone: {r.tone}
                </div>
              </div>
              <Toggle
                on={r.on}
                onChange={() => setReminders((rs) => rs.map((x, ix) => ix === i ? { ...x, on: !x.on } : x))}
              />
            </div>
          ))}
          <div style={{
            padding: '10px 14px', borderTop: '1px solid rgba(255,255,255,0.04)',
            display: 'flex', alignItems: 'center', gap: 8,
            fontSize: 12.5, color: '#7DD3FC', fontFamily: FONT_TEXT, fontWeight: 500,
            cursor: 'pointer',
          }}>
            {I.plus('#38BDF8', 14)} Thêm slot
          </div>
        </div>

        {/* Body data */}
        <SectionHeader title="My Body Data" subtitle="Dùng để AI tính goal" />
        <div style={{
          background: COLORS.nightCard, borderRadius: 14,
          border: '1px solid rgba(255,255,255,0.04)',
          padding: '4px 0',
          marginBottom: 18,
        }}>
          <BodyRow label="Cân nặng" value={`${bodyData.weight} kg`} hint="Cập nhật 2 tuần trước" />
          <BodyRow label="Tuổi" value={`${bodyData.age}`} />
          <BodyRow label="Mức vận động" value={bodyData.activity} pillColor="#10B981" />
          <BodyRow label="Climate zone" value={bodyData.climate} pillColor="#F59E0B" last />
        </div>

        {/* Sign out */}
        <button style={{
          width: '100%', padding: '14px',
          background: 'rgba(239,68,68,0.06)',
          border: '1px solid rgba(239,68,68,0.15)',
          borderRadius: 12,
          color: '#FCA5A5', fontFamily: FONT_TEXT, fontSize: 13, fontWeight: 600,
          cursor: 'pointer',
        }}>Đăng xuất</button>

        <div style={{ height: 12 }} />
      </div>

      <BottomTabBar active="profile" onNavigate={onNavigate} />
    </div>
  );
}

function SectionHeader({ title, subtitle, trailing }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      marginBottom: 10, paddingTop: 4,
    }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: COLORS.textPrimary, fontFamily: FONT_TEXT, letterSpacing: '-0.01em' }}>
          {title}
        </div>
        {subtitle && (
          <div style={{ fontSize: 10.5, color: COLORS.textMuted, marginTop: 1, fontFamily: FONT_TEXT }}>{subtitle}</div>
        )}
      </div>
      {trailing && (
        <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_ROUND, fontWeight: 600 }}>
          {trailing}
        </div>
      )}
    </div>
  );
}

function LifetimeStat({ icon, value, label, sub }) {
  return (
    <div style={{
      background: COLORS.nightCard, borderRadius: 12, padding: '12px 10px',
      border: '1px solid rgba(255,255,255,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 6 }}>
        {icon}
      </div>
      <div style={{ fontSize: 18, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em', lineHeight: 1 }}>
        {value}{sub && <span style={{ fontSize: 11, color: COLORS.textSecondary, fontWeight: 500, marginLeft: 3 }}>{sub}</span>}
      </div>
      <div style={{ fontSize: 10.5, color: COLORS.textSecondary, marginTop: 4, fontFamily: FONT_TEXT, letterSpacing: '0.02em' }}>
        {label}
      </div>
    </div>
  );
}

function Toggle({ on, onChange }) {
  return (
    <button onClick={onChange} style={{
      width: 42, height: 24, borderRadius: 999,
      background: on ? '#0EA5E9' : 'rgba(255,255,255,0.1)',
      border: 'none', cursor: 'pointer', position: 'relative',
      transition: 'background 0.2s ease',
      boxShadow: on ? '0 0 12px rgba(14,165,233,0.5)' : 'none',
      flexShrink: 0,
    }}>
      <span style={{
        position: 'absolute', top: 2, left: on ? 20 : 2,
        width: 20, height: 20, borderRadius: 999,
        background: 'white',
        transition: 'left 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
      }} />
    </button>
  );
}

function BodyRow({ label, value, hint, pillColor, last }) {
  return (
    <div style={{
      padding: '12px 14px',
      borderBottom: last ? 'none' : '1px solid rgba(255,255,255,0.04)',
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 500, color: COLORS.textPrimary, fontFamily: FONT_TEXT }}>{label}</div>
        {hint && <div style={{ fontSize: 10.5, color: COLORS.textMuted, marginTop: 1 }}>{hint}</div>}
      </div>
      {pillColor ? (
        <div style={{
          background: `${pillColor}1F`, color: pillColor,
          padding: '4px 10px', borderRadius: 999,
          fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 600,
          border: `1px solid ${pillColor}33`,
        }}>{value}</div>
      ) : (
        <div style={{
          fontSize: 13.5, color: 'white', fontFamily: FONT_ROUND, fontWeight: 600,
          fontFeatureSettings: '"tnum"',
        }}>{value}</div>
      )}
      {I.chevR(COLORS.textMuted, 14)}
    </div>
  );
}

window.ProfileScreen = ProfileScreen;
