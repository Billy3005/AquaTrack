// Session context: who is signed in, and what they are allowed to do.
//
// The capability map comes from the server (/admin/me) rather than being
// re-derived here, so the console can never offer a button the API would
// refuse. The UI still shows disabled controls instead of hiding them — a
// support agent should be able to see that "Reset dữ liệu" exists and is
// restricted, rather than wonder where it went.

import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { ApiError, SESSION_EXPIRED_EVENT, api, tokenStore } from './api';
import type { AdminProfile, Capability } from '../types';

interface AuthValue {
  profile: AdminProfile | null;
  loading: boolean;
  error: string | null;
  can: (cap: Capability) => boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Restore the session on boot. A stored token is not proof of staff access —
  // only /admin/me can confirm the role, so we always ask.
  useEffect(() => {
    if (!tokenStore.get()) {
      setLoading(false);
      return;
    }
    api
      .me()
      .then(setProfile)
      .catch(() => tokenStore.clear())
      .finally(() => setLoading(false));
  }, []);

  // Any 401 anywhere in the app ends the session here, not just in the call
  // that happened to notice. Without this the shell kept rendering with a
  // profile whose token was already gone.
  useEffect(() => {
    const onExpired = () => {
      setProfile(null);
      setError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    };
    window.addEventListener(SESSION_EXPIRED_EVENT, onExpired);
    return () => window.removeEventListener(SESSION_EXPIRED_EVENT, onExpired);
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    setError(null);
    await api.login(email, password);
    try {
      setProfile(await api.me());
    } catch (err) {
      // Valid app credentials, but not a staff account. Drop the token so the
      // console never holds one it cannot use.
      tokenStore.clear();
      const message =
        err instanceof ApiError && err.status === 403
          ? 'Tài khoản này không có quyền truy cập Admin Console'
          : 'Không lấy được thông tin quản trị viên';
      setError(message);
      throw new Error(message);
    }
  }, []);

  const signOut = useCallback(() => {
    tokenStore.clear();
    setProfile(null);
  }, []);

  const can = useCallback(
    (cap: Capability) => Boolean(profile?.capabilities?.[cap]),
    [profile],
  );

  const value = useMemo(
    () => ({ profile, loading, error, can, signIn, signOut }),
    [profile, loading, error, can, signIn, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
