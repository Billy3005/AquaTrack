// Staff sign-in. Uses the app's ordinary /auth/login, then /admin/me decides
// whether this account is staff — there is no separate admin credential store.

import { useEffect, useState, type FormEvent } from 'react';
import { A } from '../icons';
import { AD, AF } from '../theme';
import { useAuth } from '../lib/auth';
import { ABtn, AInput, ALabel } from '../components/ui';

export function LoginScreen() {
  const { signIn, error: sessionError } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [formError, setFormError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  // A failed attempt on this screen beats a stale "session expired" notice.
  const error = formError ?? sessionError;

  // The console is a fixed 1280px layout; the login card is not.
  useEffect(() => {
    document.body.classList.add('ad-auth');
    return () => document.body.classList.remove('ad-auth');
  }, []);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setFormError(null);
    try {
      await signIn(email.trim(), password);
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Đăng nhập thất bại');
      setBusy(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: `linear-gradient(160deg, ${AD.navy} 0%, ${AD.navy2} 100%)`,
        fontFamily: AF,
        padding: 24,
      }}
    >
      <form
        onSubmit={submit}
        style={{
          width: 400,
          background: '#fff',
          borderRadius: 18,
          boxShadow: AD.shadowUp,
          overflow: 'hidden',
          animation: 'ad-pop .3s cubic-bezier(.2,1.2,.4,1)',
        }}
      >
        <div style={{ padding: '30px 30px 22px', textAlign: 'center' }}>
          <div
            style={{
              width: 48,
              height: 48,
              borderRadius: 14,
              background: 'linear-gradient(140deg,#38BDF8,#0284C7)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 16px',
              boxShadow: '0 6px 20px rgba(56,189,248,0.4)',
            }}
          >
            {A.drop('#fff', 24)}
          </div>
          <div style={{ fontSize: 19, fontWeight: 750, color: AD.ink, letterSpacing: '-0.02em' }}>AquaTrack Admin Console</div>
          <div style={{ fontSize: 12.5, color: AD.ink3, marginTop: 6, lineHeight: 1.5 }}>
            Đăng nhập bằng tài khoản nhân sự. Tài khoản người dùng thường sẽ bị từ chối.
          </div>
        </div>

        <div style={{ padding: '0 30px 8px', display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div>
            <ALabel>Email</ALabel>
            <AInput value={email} onChange={setEmail} placeholder="ten.ban@aquatrack.vn" type="email" autoFocus />
          </div>
          <div>
            <ALabel>Mật khẩu</ALabel>
            <AInput value={password} onChange={setPassword} placeholder="••••••••" type="password" />
          </div>

          {error && (
            <div style={{ padding: '10px 12px', background: AD.redTint, border: '1px solid #F8D2DA', borderRadius: 9, fontSize: 12.5, color: AD.red, lineHeight: 1.5 }}>
              {error}
            </div>
          )}
        </div>

        <div style={{ padding: '18px 30px 26px' }}>
          <ABtn kind="primary" size="lg" full type="submit" disabled={busy || !email || !password}>
            {busy ? 'Đang đăng nhập…' : 'Đăng nhập'}
          </ABtn>
        </div>
      </form>
    </div>
  );
}
