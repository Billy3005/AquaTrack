// Thin typed client over the Wafubi REST API.
//
// Tokens live in localStorage. That is the pragmatic choice for a staff tool
// that has no cookie/CSRF infrastructure on the backend, and it is the same
// scheme the mobile app already uses. The trade-off is XSS exposure — which is
// why this app has no user-generated HTML rendering anywhere.

import type { AuditListResponse, AdminProfile, Overview, ResetCodeResult, UserDetail, UserListResponse } from '../types';

const TOKEN_KEY = 'aquatrack.admin.token';

// Same-origin by default: `vite.config.ts` proxies /api to the backend in dev,
// and a production build is expected to be served next to the API.
const BASE = import.meta.env.VITE_API_BASE_URL ?? '';

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export const tokenStore = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (t: string) => localStorage.setItem(TOKEN_KEY, t),
  clear: () => localStorage.removeItem(TOKEN_KEY),
};

/**
 * Broadcast when the server rejects our token. Clearing the token alone left
 * the shell rendered with a stale profile, so an expired session showed a
 * console full of failing panels instead of the login screen. AuthProvider
 * listens and drops the profile too.
 */
export const SESSION_EXPIRED_EVENT = 'aquatrack:session-expired';

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = tokenStore.get();
  const headers: Record<string, string> = { ...(init.headers as Record<string, string>) };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (init.body) headers['Content-Type'] = 'application/json';

  const res = await fetch(`${BASE}/api/v1${path}`, { ...init, headers });

  if (res.status === 401) {
    // The token expired or was revoked — drop it and tell the shell, so the
    // operator lands on the login screen instead of a console of failing panels.
    tokenStore.clear();
    window.dispatchEvent(new CustomEvent(SESSION_EXPIRED_EVENT));
    throw new ApiError(401, 'Phiên đăng nhập đã hết hạn');
  }

  if (!res.ok) {
    throw new ApiError(res.status, await readError(res));
  }

  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

async function readError(res: Response): Promise<string> {
  try {
    const body = await res.json();
    const detail = body?.detail;
    if (typeof detail === 'string') return detail;
    // FastAPI validation errors arrive as a list of {loc, msg, ...}.
    if (Array.isArray(detail) && detail[0]?.msg) return detail.map((d: { msg: string }) => d.msg).join('; ');
    return res.statusText;
  } catch {
    return res.statusText || `Lỗi ${res.status}`;
  }
}

const qs = (params: Record<string, string | number | undefined>) =>
  Object.entries(params)
    .filter(([, v]) => v !== undefined && v !== '')
    .map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`)
    .join('&');

export const api = {
  async login(email: string, password: string): Promise<string> {
    const body = await request<{ access_token: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    tokenStore.set(body.access_token);
    return body.access_token;
  },

  me: () => request<AdminProfile>('/admin/me'),

  overview: (rangeDays: number) => request<Overview>(`/admin/overview?range=${rangeDays}`),

  users: (params: { q?: string; status?: string; level?: string; page?: number; page_size?: number }) =>
    request<UserListResponse>(`/admin/users?${qs(params)}`),

  user: (id: string) => request<UserDetail>(`/admin/users/${id}`),

  lockUser: (id: string, reason: string) =>
    request<{ status: string }>(`/admin/users/${id}/lock`, { method: 'POST', body: JSON.stringify({ reason }) }),

  unlockUser: (id: string, reason: string) =>
    request<{ status: string }>(`/admin/users/${id}/unlock`, { method: 'POST', body: JSON.stringify({ reason }) }),

  resetUser: (id: string, reason: string, confirm: string) =>
    request<{ deletedLogs: number }>(`/admin/users/${id}/reset`, { method: 'POST', body: JSON.stringify({ reason, confirm }) }),

  /**
   * Returns a live 6-digit reset code — the only response on this API that
   * carries a credential. It is shown once in the modal and never persisted:
   * do not log it, store it in state longer than the dialog, or put it in a URL.
   */
  issueResetCode: (id: string, reason: string) =>
    request<ResetCodeResult>(`/admin/users/${id}/password-reset`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    }),

  grant: (id: string, coins: number, xp: number, reason: string) =>
    request<{ coins: number; totalXp: number }>(`/admin/users/${id}/grant`, {
      method: 'POST',
      body: JSON.stringify({ coins, xp, reason }),
    }),

  audit: (params: { page?: number; page_size?: number; action?: string; target_id?: string; q?: string }) =>
    request<AuditListResponse>(`/admin/audit?${qs(params)}`),

  /** Triggers a browser download; the CSV never passes through React state. */
  async exportUsers(): Promise<void> {
    const token = tokenStore.get();
    const res = await fetch(`${BASE}/api/v1/admin/users/export`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) throw new ApiError(res.status, await readError(res));
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `wafubi-users-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  },
};
