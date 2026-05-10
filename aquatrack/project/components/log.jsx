// LogScreen — explicit log drink flow
function LogScreen({ current, goal, onLog, onNavigate }) {
  const [type, setType] = React.useState('water');
  const [amount, setAmount] = React.useState(250);

  const types = [
    { id: 'water', label: 'Nước lọc' },
    { id: 'tea', label: 'Trà' },
    { id: 'coffee', label: 'Cà phê' },
    { id: 'juice', label: 'Trái cây' },
    { id: 'smoothie', label: 'Sinh tố' },
  ];

  const after = current + amount;
  const afterPct = Math.round((after / goal) * 100);

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '54px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button onClick={() => onNavigate && onNavigate('home')} style={{
          background: 'none', border: 'none', color: COLORS.textBright,
          fontSize: 14, fontFamily: FONT_TEXT, cursor: 'pointer', padding: 0,
        }}>← Huỷ</button>
        <div style={{ fontSize: 15, fontWeight: 600, color: 'white' }}>Log thức uống</div>
        <div style={{ width: 40 }} />
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '12px 20px 20px' }}>
        {/* Type chips */}
        <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT, marginBottom: 10 }}>
          Loại thức uống
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 22 }}>
          {types.map((t) => {
            const active = type === t.id;
            return (
              <button key={t.id} onClick={() => setType(t.id)} style={{
                background: active ? '#0C4A6E' : COLORS.nightCard,
                border: active ? `1.5px solid ${COLORS.borderActive}` : '1px solid rgba(255,255,255,0.06)',
                color: active ? '#E0F2FE' : COLORS.textPrimary,
                padding: '8px 14px', borderRadius: 999,
                fontFamily: FONT_TEXT, fontSize: 13, fontWeight: 500,
                cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 8,
              }}>
                <DrinkIcon type={t.id} size={18} />
                <span>{t.label}</span>
              </button>
            );
          })}
        </div>

        {/* Amount stepper */}
        <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT, marginBottom: 10 }}>
          Lượng
        </div>
        <div style={{
          background: COLORS.nightSurface,
          border: `1px solid ${COLORS.border}`,
          borderRadius: 16, padding: 18,
          display: 'flex', alignItems: 'center', gap: 16,
          marginBottom: 12,
        }}>
          <button onClick={() => setAmount(Math.max(50, amount - 50))} style={{
            width: 44, height: 44, borderRadius: 999,
            background: COLORS.nightCard, border: '1px solid rgba(255,255,255,0.08)',
            color: 'white', fontSize: 24, fontFamily: FONT_ROUND, fontWeight: 500, cursor: 'pointer',
          }}>−</button>
          <div style={{ flex: 1, textAlign: 'center' }}>
            <div style={{
              fontSize: 44, fontWeight: 700, color: 'white',
              fontFamily: FONT_ROUND, letterSpacing: '-0.04em', lineHeight: 1,
              fontFeatureSettings: '"tnum"',
            }}>{amount}</div>
            <div style={{ fontSize: 11, color: COLORS.textSecondary, marginTop: 4, letterSpacing: '0.06em', textTransform: 'uppercase' }}>ml</div>
          </div>
          <button onClick={() => setAmount(Math.min(1500, amount + 50))} style={{
            width: 44, height: 44, borderRadius: 999,
            background: COLORS.glow, border: 'none',
            color: '#082F49', fontSize: 24, fontFamily: FONT_ROUND, fontWeight: 600, cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(56,189,248,0.4)',
          }}>+</button>
        </div>

        {/* Quick picks */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
          {[100, 250, 500, 750].map((a) => (
            <QuickChip key={a} amount={a} active={amount === a} onClick={() => setAmount(a)} />
          ))}
        </div>

        {/* Preview */}
        <div style={{
          background: 'linear-gradient(135deg, rgba(56,189,248,0.10), rgba(14,165,233,0.04))',
          border: '1px solid rgba(56,189,248,0.25)',
          borderRadius: 14, padding: 14,
          marginBottom: 16,
        }}>
          <div style={{ fontSize: 11, color: COLORS.textBright, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase', marginBottom: 6, fontFamily: FONT_TEXT }}>
            Sau khi log
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <div style={{
              fontSize: 22, fontWeight: 700, color: 'white',
              fontFamily: FONT_ROUND, letterSpacing: '-0.02em', fontFeatureSettings: '"tnum"',
            }}>
              {after.toLocaleString()}<span style={{ fontSize: 13, color: COLORS.textSecondary, fontWeight: 500 }}> / {goal.toLocaleString()}ml</span>
            </div>
            <div style={{ fontSize: 18, color: COLORS.glow, fontWeight: 700, fontFamily: FONT_ROUND }}>{afterPct}%</div>
          </div>
          <div style={{ height: 6, background: 'rgba(255,255,255,0.08)', borderRadius: 999, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${Math.min(100, afterPct)}%`, background: 'linear-gradient(90deg, #0EA5E9, #38BDF8)', borderRadius: 999 }} />
          </div>
          <div style={{ fontSize: 11, color: '#86EFAC', marginTop: 8, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 4 }}>
            +20 XP · còn {Math.max(0, goal - after)}ml để đạt goal
          </div>
        </div>

        {/* Submit */}
        <button onClick={() => { onLog && onLog(amount, type); onNavigate && onNavigate('home'); }} style={{
          width: '100%', padding: '16px', borderRadius: 14,
          background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
          color: 'white', fontFamily: FONT_TEXT, fontSize: 15, fontWeight: 600,
          border: 'none', cursor: 'pointer',
          boxShadow: '0 6px 18px rgba(14,165,233,0.45)',
          letterSpacing: '-0.01em',
        }}>
          Log {amount}ml
        </button>
      </div>
    </div>
  );
}

window.LogScreen = LogScreen;
