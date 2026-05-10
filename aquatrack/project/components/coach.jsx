// CoachScreen — AI Coach chat
function CoachScreen({ current, goal, onNavigate, onLog }) {
  const pct = Math.round((current / goal) * 100);

  const [messages, setMessages] = React.useState([
    { from: 'ai', text: 'Chào buổi chiều! Bạn vừa log một ly cà phê đá 180ml — cà phê có tính lợi tiểu nhẹ ☕', time: '14:46' },
    { from: 'ai', text: 'Mình đề xuất uống thêm +250ml trong 30 phút tới để bù lại nhé.', time: '14:46', chips: ['Uống 250ml ngay', 'Xem tiến độ', 'Đặt nhắc nhở'] },
    { from: 'user', text: 'Trời nóng lắm hôm nay 😅', time: '14:48' },
    { from: 'ai', text: 'Đúng rồi — HCMC đang 34°C. Mình đã tự động tăng goal hôm nay từ 2,500ml lên 2,800ml. Bạn còn 1,350ml nữa.', time: '14:48' },
  ]);
  const [input, setInput] = React.useState('');

  function send(text) {
    if (!text.trim()) return;
    const t = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    setMessages((m) => [...m, { from: 'user', text, time: t }]);
    setInput('');
    setTimeout(() => {
      setMessages((m) => [...m, {
        from: 'ai',
        text: 'Mình hiểu rồi — sẽ điều chỉnh lịch nhắc cho phù hợp 💙',
        time: t,
      }]);
    }, 700);
  }

  return (
    <div style={{
      width: '100%', height: '100%', background: COLORS.nightBase,
      display: 'flex', flexDirection: 'column', fontFamily: FONT,
      color: COLORS.textPrimary,
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, #0A2545, #0B1120)',
        padding: '50px 16px 14px',
        borderBottom: '1px solid rgba(56,189,248,0.1)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 999,
            background: 'radial-gradient(circle at 30% 30%, #7DD3FC, #0EA5E9)',
            boxShadow: '0 0 20px rgba(56,189,248,0.6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{ width: 10, height: 10, borderRadius: 999, background: 'white' }} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600, color: 'white' }}>Aqua AI</div>
            <div style={{ fontSize: 11, color: '#86EFAC', display: 'flex', alignItems: 'center', gap: 5 }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: '#10B981', display: 'inline-block' }} />
              online · context-aware
            </div>
          </div>
          <button onClick={() => onNavigate && onNavigate('home')} style={{
            background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: 999, padding: '6px 12px', color: COLORS.textPrimary,
            fontFamily: FONT_TEXT, fontSize: 12, cursor: 'pointer',
          }}>Đóng</button>
        </div>

        {/* Pinned progress bar */}
        <div style={{
          background: 'rgba(8,30,56,0.6)', border: '1px solid rgba(56,189,248,0.2)',
          borderRadius: 12, padding: '10px 12px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          {I.drop('#38BDF8', 18)}
          <div style={{ flex: 1 }}>
            <div style={{
              fontSize: 12, color: COLORS.textPrimary, fontFamily: FONT_TEXT,
              display: 'flex', justifyContent: 'space-between',
              marginBottom: 4,
            }}>
              <span style={{ fontWeight: 600 }}>{current.toLocaleString()} / {goal.toLocaleString()}ml</span>
              <span style={{ color: COLORS.glow, fontWeight: 600, fontFamily: FONT_ROUND }}>{pct}%</span>
            </div>
            <div style={{ height: 5, background: 'rgba(255,255,255,0.08)', borderRadius: 999, overflow: 'hidden' }}>
              <div style={{
                height: '100%', width: `${pct}%`,
                background: 'linear-gradient(90deg, #0EA5E9, #38BDF8)',
                borderRadius: 999,
                boxShadow: '0 0 8px rgba(56,189,248,0.6)',
              }} />
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 14px 8px' }}>
        {/* Day separator */}
        <div style={{
          textAlign: 'center', fontSize: 10, color: COLORS.textMuted,
          margin: '4px 0 14px', fontFamily: FONT_TEXT, letterSpacing: '0.1em',
          textTransform: 'uppercase', fontWeight: 600,
        }}>Hôm nay</div>

        {messages.map((m, i) => (
          <Bubble key={i} m={m} onChip={(t) => {
            if (t === 'Uống 250ml ngay') { onLog && onLog(250); send(t); }
            else send(t);
          }} />
        ))}

        {/* typing dots after last user msg if last was user */}
      </div>

      {/* Composer */}
      <div style={{
        padding: '8px 12px 28px',
        borderTop: '1px solid rgba(56,189,248,0.08)',
        background: 'rgba(15,26,46,0.6)',
        backdropFilter: 'blur(12px)',
        display: 'flex', gap: 8, alignItems: 'flex-end',
      }}>
        <div style={{
          flex: 1,
          background: COLORS.nightCard,
          borderRadius: 22,
          padding: '10px 14px',
          display: 'flex', alignItems: 'center', gap: 8,
          border: '1px solid rgba(255,255,255,0.06)',
        }}>
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') send(input); }}
            placeholder="Hỏi Aqua AI bất cứ điều gì..."
            style={{
              flex: 1, background: 'transparent', border: 'none',
              color: COLORS.textPrimary, fontSize: 14, fontFamily: FONT_TEXT,
              outline: 'none',
            }}
          />
        </div>
        <button onClick={() => send(input)} style={{
          width: 42, height: 42, borderRadius: 999,
          background: input.trim() ? 'linear-gradient(135deg, #0EA5E9, #38BDF8)' : 'rgba(56,189,248,0.2)',
          border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: input.trim() ? '0 4px 12px rgba(14,165,233,0.4)' : 'none',
        }}>
          {I.send('white', 18)}
        </button>
      </div>
    </div>
  );
}

function Bubble({ m, onChip }) {
  const isAi = m.from === 'ai';
  return (
    <div style={{
      display: 'flex', flexDirection: 'column',
      alignItems: isAi ? 'flex-start' : 'flex-end',
      marginBottom: 12,
    }}>
      <div style={{
        maxWidth: '78%',
        background: isAi ? '#1E3A5F' : 'linear-gradient(135deg, #0EA5E9, #0284C7)',
        color: isAi ? '#BAE6FD' : 'white',
        padding: '10px 14px',
        fontSize: 13.5, lineHeight: 1.45,
        fontFamily: FONT_TEXT,
        borderRadius: isAi ? '4px 14px 14px 14px' : '14px 4px 14px 14px',
        boxShadow: isAi ? 'none' : '0 2px 8px rgba(14,165,233,0.25)',
      }}>
        {m.text}
      </div>
      {m.chips && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8, maxWidth: '85%' }}>
          {m.chips.map((c) => (
            <button key={c} onClick={() => onChip && onChip(c)} style={{
              background: 'rgba(56,189,248,0.12)',
              border: '1px solid rgba(56,189,248,0.3)',
              color: '#BAE6FD',
              padding: '6px 12px',
              borderRadius: 999,
              fontSize: 11.5, fontFamily: FONT_TEXT, fontWeight: 500,
              cursor: 'pointer',
            }}>{c}</button>
          ))}
        </div>
      )}
      <div style={{
        fontSize: 9.5, color: COLORS.textMuted, marginTop: 4,
        padding: '0 4px', fontFamily: FONT_TEXT,
      }}>{m.time}</div>
    </div>
  );
}

window.CoachScreen = CoachScreen;
