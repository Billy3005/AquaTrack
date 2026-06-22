// AuthScreens — Đăng nhập & Đăng ký
// Cùng chia sẻ layout: hero gradient với Living Drop, form ở dưới

function LoginScreen({ onNavigate, onSignedIn }) {
  return <AuthShell mode="login" onNavigate={onNavigate} onSignedIn={onSignedIn} />;
}

function RegisterScreen({ onNavigate, onSignedIn }) {
  return <AuthShell mode="register" onNavigate={onNavigate} onSignedIn={onSignedIn} />;
}

function AuthShell({ mode, onNavigate, onSignedIn }) {
  const isLogin = mode === 'login';
  const [email, setEmail] = React.useState(isLogin ? 'minh@aquatrack.app' : '');
  const [password, setPassword] = React.useState(isLogin ? '••••••••' : '');
  const [confirmPw, setConfirmPw] = React.useState('');
  const [name, setName] = React.useState('');
  const [showPw, setShowPw] = React.useState(false);
  const [remember, setRemember] = React.useState(true);
  const [agreed, setAgreed] = React.useState(false);
  const [loading, setLoading] = React.useState(false);

  function submit(e) {
    if (e) e.preventDefault();
    if (loading) return;
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      if (onSignedIn) onSignedIn();
      else if (onNavigate) onNavigate('home');
    }, 900);
  }

  const canSubmit = isLogin
    ? email && password
    : email && password && confirmPw && name && agreed && password === confirmPw;

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase,
      color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Hero */}
      <div style={{
        background: 'linear-gradient(180deg, #0A3460 0%, #0B1933 100%)',
        padding: isLogin ? '64px 24px 32px' : '58px 24px 22px',
        position: 'relative', overflow: 'hidden',
        flexShrink: 0,
      }}>
        {/* glow */}
        <div style={{
          position: 'absolute', top: -60, left: '50%', transform: 'translateX(-50%)',
          width: 320, height: 320, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.25), transparent 60%)',
          pointerEvents: 'none',
        }} />
        {/* floating bubbles */}
        {[12, 28, 55, 78, 92].map((left, i) => (
          <div key={i} style={{
            position: 'absolute',
            left: `${left}%`,
            bottom: `${10 + (i * 17) % 60}%`,
            width: 4 + (i % 3) * 2,
            height: 4 + (i % 3) * 2,
            borderRadius: '50%',
            background: 'rgba(125,211,252,0.4)',
            animation: `auth-bubble ${4 + (i % 3)}s ease-in infinite`,
            animationDelay: `${i * 0.4}s`,
          }} />
        ))}

        {/* Back button (for register) */}
        {!isLogin && (
          <button onClick={() => onNavigate && onNavigate('login')} style={{
            position: 'absolute', top: 50, left: 18,
            width: 36, height: 36, borderRadius: 999,
            background: 'rgba(255,255,255,0.06)',
            border: '1px solid rgba(255,255,255,0.08)',
            color: 'white', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 5,
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 6 L9 12 L15 18" />
            </svg>
          </button>
        )}

        {/* Living Drop logo */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14, position: 'relative' }}>
          <LivingDrop percent={isLogin ? 70 : 50} size={isLogin ? 110 : 92} glow={false} />
        </div>

        <div style={{ textAlign: 'center', position: 'relative' }}>
          <div style={{
            fontSize: 11, color: '#7DD3FC', fontWeight: 600,
            letterSpacing: '0.18em', textTransform: 'uppercase',
            fontFamily: FONT_TEXT, marginBottom: 4,
          }}>AquaTrack</div>
          <div style={{
            fontSize: 24, fontWeight: 700, color: 'white',
            letterSpacing: '-0.02em', fontFamily: FONT_ROUND,
            textWrap: 'pretty',
          }}>
            {isLogin ? 'Chào mừng trở lại 👋' : 'Tạo một cuộc đời nhiều nước'}
          </div>
          <div style={{
            fontSize: 12.5, color: '#BAE6FD', marginTop: 4,
            fontFamily: FONT_TEXT, lineHeight: 1.4,
          }}>
            {isLogin
              ? 'Đăng nhập để tiếp tục hành trình hydrate'
              : 'Vài giây thôi — đồng hành cùng bạn mỗi ngụm'}
          </div>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={submit} style={{
        flex: 1, overflow: 'auto',
        padding: '20px 22px 24px',
        display: 'flex', flexDirection: 'column',
      }}>
        {!isLogin && (
          <Field
            label="Tên hiển thị"
            placeholder="Minh Nguyễn"
            value={name}
            onChange={setName}
            icon={(
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
                <circle cx="12" cy="8" r="4"/><path d="M4 21 a8 8 0 0 1 16 0"/>
              </svg>
            )}
          />
        )}

        <Field
          label="Email"
          type="email"
          placeholder="ban@vidu.com"
          value={email}
          onChange={setEmail}
          icon={(
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="5" width="18" height="14" rx="2"/>
              <path d="M3 7 L12 13 L21 7"/>
            </svg>
          )}
        />

        <Field
          label="Mật khẩu"
          type={showPw ? 'text' : 'password'}
          placeholder="Ít nhất 8 ký tự"
          value={password}
          onChange={setPassword}
          icon={(
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <rect x="4" y="11" width="16" height="10" rx="2"/>
              <path d="M8 11 V8 a4 4 0 0 1 8 0 V11"/>
            </svg>
          )}
          trailing={(
            <button type="button" onClick={() => setShowPw(!showPw)} style={{
              background: 'none', border: 'none', cursor: 'pointer',
              color: COLORS.textSecondary, padding: 0,
              display: 'flex', alignItems: 'center',
            }}>
              {showPw ? (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M2 12 C5 6 9 4 12 4 C15 4 19 6 22 12 C19 18 15 20 12 20 C9 20 5 18 2 12 z"/>
                  <circle cx="12" cy="12" r="3"/>
                  <path d="M3 3 L21 21"/>
                </svg>
              ) : (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M2 12 C5 6 9 4 12 4 C15 4 19 6 22 12 C19 18 15 20 12 20 C9 20 5 18 2 12 z"/>
                  <circle cx="12" cy="12" r="3"/>
                </svg>
              )}
            </button>
          )}
        />

        {!isLogin && (
          <Field
            label="Nhập lại mật khẩu"
            type={showPw ? 'text' : 'password'}
            placeholder="Lặp lại để chắc chắn"
            value={confirmPw}
            onChange={setConfirmPw}
            error={confirmPw && password !== confirmPw ? 'Mật khẩu chưa trùng khớp' : null}
            icon={(
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <rect x="4" y="11" width="16" height="10" rx="2"/>
                <path d="M8 11 V8 a4 4 0 0 1 8 0 V11"/>
              </svg>
            )}
          />
        )}

        {/* Strength meter on register */}
        {!isLogin && password && (
          <PasswordStrength pw={password} />
        )}

        {/* Helper row */}
        {isLogin ? (
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            marginTop: 4, marginBottom: 16,
          }}>
            <label style={{
              display: 'flex', alignItems: 'center', gap: 8,
              fontSize: 12, color: COLORS.textSecondary, fontFamily: FONT_TEXT,
              cursor: 'pointer',
            }}>
              <Checkbox checked={remember} onChange={setRemember} />
              Ghi nhớ tôi
            </label>
            <button type="button" style={{
              background: 'none', border: 'none', cursor: 'pointer',
              color: '#7DD3FC', fontSize: 12, fontWeight: 600,
              fontFamily: FONT_TEXT, padding: 0,
            }}>Quên mật khẩu?</button>
          </div>
        ) : (
          <label style={{
            display: 'flex', alignItems: 'flex-start', gap: 8,
            marginTop: 6, marginBottom: 16,
            fontSize: 11.5, color: COLORS.textSecondary, fontFamily: FONT_TEXT,
            lineHeight: 1.5, cursor: 'pointer',
          }}>
            <div style={{ paddingTop: 2 }}>
              <Checkbox checked={agreed} onChange={setAgreed} />
            </div>
            <span>
              Tôi đồng ý với{' '}
              <span style={{ color: '#7DD3FC', fontWeight: 600 }}>Điều khoản dịch vụ</span>
              {' và '}
              <span style={{ color: '#7DD3FC', fontWeight: 600 }}>Chính sách riêng tư</span>
              {' của AquaTrack.'}
            </span>
          </label>
        )}

        {/* Submit */}
        <button type="submit" disabled={!canSubmit || loading} style={{
          width: '100%',
          background: canSubmit
            ? 'linear-gradient(135deg, #0EA5E9, #0284C7)'
            : 'rgba(255,255,255,0.05)',
          border: canSubmit ? '1px solid rgba(255,255,255,0.15)' : '1px solid rgba(255,255,255,0.05)',
          color: canSubmit ? 'white' : COLORS.textMuted,
          padding: '14px 16px',
          borderRadius: 12,
          fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 14,
          letterSpacing: '0.02em',
          cursor: canSubmit && !loading ? 'pointer' : 'not-allowed',
          boxShadow: canSubmit ? '0 8px 24px rgba(14,165,233,0.35)' : 'none',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {loading ? (
            <>
              <span style={{
                width: 14, height: 14, border: '2px solid rgba(255,255,255,0.3)',
                borderTopColor: 'white', borderRadius: '50%',
                animation: 'auth-spin 0.8s linear infinite',
              }} />
              Đang xử lý…
            </>
          ) : (
            <>
              {isLogin ? 'Đăng nhập' : 'Tạo tài khoản'}
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12 H19 M13 6 L19 12 L13 18"/>
              </svg>
            </>
          )}
        </button>

        {/* Or divider */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          margin: '18px 0 14px',
        }}>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.08)' }} />
          <div style={{ fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
            hoặc
          </div>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.08)' }} />
        </div>

        {/* Social */}
        <div style={{ display: 'flex', gap: 8 }}>
          <SocialBtn label="Apple" bg="#0F172A">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
              <path d="M17.5 12.5 c0-2.4 2-3.5 2-3.5 c-1.1-1.6-2.8-1.8-3.4-1.8 c-1.5-0.2-2.8 0.9-3.6 0.9 c-0.8 0-1.9-0.9-3.1-0.8 C7.8 7.4 6.3 8.3 5.5 9.7 c-1.7 3-0.4 7.4 1.3 9.8 c0.8 1.2 1.7 2.5 3 2.5 c1.2 0 1.7-0.8 3.1-0.8 c1.4 0 1.9 0.8 3.1 0.8 c1.3 0 2.1-1.2 2.9-2.4 c0.9-1.4 1.3-2.7 1.3-2.8 c0 0-2.5-1-2.7-3.8 z M15 5.4 c0.6-0.8 1.1-1.9 1-3 c-0.9 0-2 0.6-2.7 1.4 c-0.6 0.7-1.1 1.8-1 2.9 C13.4 6.8 14.4 6.2 15 5.4 z"/>
            </svg>
          </SocialBtn>
          <SocialBtn label="Google" bg="rgba(255,255,255,0.06)">
            <svg width="16" height="16" viewBox="0 0 48 48">
              <path d="M44 24 c0-1.4-0.1-2.7-0.4-4 H24 v7.5 H35.2 c-0.5 2.6-2 4.7-4.2 6.2 v5.2 h6.8 C41.7 35.4 44 30.1 44 24 z" fill="#4285F4"/>
              <path d="M24 44 c5.7 0 10.5-1.9 14-5.1 l-6.8-5.2 c-1.9 1.3-4.3 2-7.2 2 c-5.5 0-10.2-3.7-11.9-8.7 h-7 v5.4 C8.6 39 15.7 44 24 44 z" fill="#34A853"/>
              <path d="M12.1 27 c-0.4-1.3-0.7-2.7-0.7-4 c0-1.4 0.2-2.7 0.7-4 v-5.4 h-7 C3.7 16.6 3 20.2 3 24 c0 3.8 0.7 7.4 2.1 10.4 l7-5.4 z" fill="#FBBC05"/>
              <path d="M24 9.5 c3.1 0 5.9 1.1 8.1 3.2 l6-6 C34.5 3 29.7 1 24 1 C15.7 1 8.6 6 5.1 13.6 l7 5.4 c1.7-5 6.4-8.7 11.9-8.7 z" fill="#EA4335"/>
            </svg>
          </SocialBtn>
          <SocialBtn label="Facebook" bg="rgba(24,119,242,0.18)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="#60A5FA">
              <path d="M22 12 C22 6.5 17.5 2 12 2 S2 6.5 2 12 c0 5 3.7 9.1 8.4 9.9 v-7 H7.9 v-2.9 h2.5 V9.8 c0-2.5 1.5-3.9 3.8-3.9 c1.1 0 2.2 0.2 2.2 0.2 v2.5 h-1.3 c-1.2 0-1.6 0.8-1.6 1.6 V12 h2.8 l-0.5 2.9 h-2.3 v7 C18.3 21.1 22 17 22 12 z"/>
            </svg>
          </SocialBtn>
        </div>

        {/* Switch mode */}
        <div style={{
          marginTop: 22, textAlign: 'center',
          fontSize: 12.5, color: COLORS.textSecondary, fontFamily: FONT_TEXT,
        }}>
          {isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '}
          <button type="button" onClick={() => onNavigate && onNavigate(isLogin ? 'register' : 'login')} style={{
            background: 'none', border: 'none', cursor: 'pointer',
            color: '#7DD3FC', fontWeight: 700, fontSize: 12.5,
            fontFamily: FONT_TEXT,
            padding: 0,
          }}>{isLogin ? 'Đăng ký miễn phí' : 'Đăng nhập ngay'}</button>
        </div>
      </form>

      <style>{`
        @keyframes auth-spin { to { transform: rotate(360deg); } }
        @keyframes auth-bubble {
          0% { transform: translateY(0); opacity: 0; }
          30% { opacity: 0.8; }
          100% { transform: translateY(-120px); opacity: 0; }
        }
      `}</style>
    </div>
  );
}

/* ─── Fields ─────────────────────────────────────────── */

function Field({ label, type = 'text', placeholder, value, onChange, icon, trailing, error }) {
  const [focused, setFocused] = React.useState(false);
  const active = focused || value;
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{
        display: 'block',
        fontSize: 10.5, color: error ? '#FCA5A5' : '#7DD3FC',
        fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase',
        fontFamily: FONT_TEXT, marginBottom: 6,
      }}>{label}</label>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        background: COLORS.nightSurface,
        border: `1px solid ${error ? 'rgba(239,68,68,0.5)' : focused ? 'rgba(56,189,248,0.5)' : COLORS.border}`,
        boxShadow: focused ? '0 0 0 4px rgba(56,189,248,0.10)' : 'none',
        borderRadius: 12,
        padding: '12px 14px',
        transition: 'border-color 0.2s, box-shadow 0.2s',
      }}>
        <span style={{ color: active ? '#38BDF8' : COLORS.textMuted, flexShrink: 0, display: 'flex' }}>
          {icon}
        </span>
        <input
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            flex: 1, minWidth: 0,
            background: 'transparent', border: 'none', outline: 'none',
            color: 'white', fontSize: 14,
            fontFamily: FONT_TEXT,
            letterSpacing: type === 'password' && !value.includes('•') ? '0.04em' : 'normal',
          }}
        />
        {trailing}
      </div>
      {error && (
        <div style={{ fontSize: 11, color: '#FCA5A5', marginTop: 5, fontFamily: FONT_TEXT, display: 'flex', alignItems: 'center', gap: 4 }}>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="#EF4444">
            <circle cx="12" cy="12" r="10"/>
            <path d="M12 7 V13 M12 16 V17" stroke="white" strokeWidth="2" strokeLinecap="round"/>
          </svg>
          {error}
        </div>
      )}
    </div>
  );
}

function Checkbox({ checked, onChange }) {
  return (
    <span onClick={() => onChange(!checked)} style={{
      width: 16, height: 16, borderRadius: 4,
      background: checked ? 'linear-gradient(135deg, #0EA5E9, #0284C7)' : 'rgba(255,255,255,0.04)',
      border: checked ? '1px solid #38BDF8' : '1px solid rgba(255,255,255,0.15)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
      transition: 'all 0.15s',
    }}>
      {checked && (
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 12 L10 17 L19 7"/>
        </svg>
      )}
    </span>
  );
}

function PasswordStrength({ pw }) {
  const score = Math.min(4,
    (pw.length >= 8 ? 1 : 0) +
    (/[A-Z]/.test(pw) ? 1 : 0) +
    (/[0-9]/.test(pw) ? 1 : 0) +
    (/[^A-Za-z0-9]/.test(pw) ? 1 : 0)
  );
  const labels = ['Quá yếu', 'Yếu', 'Trung bình', 'Khá', 'Mạnh'];
  const colors = ['#EF4444', '#F97316', '#FBBF24', '#A3E635', '#10B981'];

  return (
    <div style={{ marginTop: -6, marginBottom: 12, fontFamily: FONT_TEXT }}>
      <div style={{ display: 'flex', gap: 4, marginBottom: 4 }}>
        {[0, 1, 2, 3].map((i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i < score ? colors[score] : 'rgba(255,255,255,0.06)',
            transition: 'background 0.2s',
          }} />
        ))}
      </div>
      <div style={{
        fontSize: 10.5,
        color: colors[score],
        fontWeight: 600,
      }}>{labels[score]} · gợi ý: dùng chữ hoa, số, ký tự đặc biệt</div>
    </div>
  );
}

function SocialBtn({ label, bg, children }) {
  return (
    <button type="button" style={{
      flex: 1,
      background: bg,
      border: '1px solid rgba(255,255,255,0.08)',
      borderRadius: 12,
      padding: '11px 0',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      color: 'white', cursor: 'pointer',
      fontFamily: FONT_TEXT, fontSize: 12, fontWeight: 600,
    }}>
      {children}
      {label}
    </button>
  );
}

window.LoginScreen = LoginScreen;
window.RegisterScreen = RegisterScreen;
