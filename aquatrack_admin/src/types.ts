// Shapes returned by /api/v1/admin — kept in sync by hand with
// aquatrack_backend/app/services/admin_service.py.

export type Capability =
  | 'data.view'
  | 'data.export'
  | 'notify.send'
  | 'content.edit'
  | 'user.grant'
  | 'user.lock'
  | 'user.reset'
  | 'user.password_reset'
  | 'gamify.config'
  | 'members.manage'
  | 'audit.view';

export interface AdminProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  roleLabel: string;
  capabilities: Record<Capability, boolean>;
}

/** Response of POST /admin/users/:id/password-reset. `code` is a live secret. */
export interface ResetCodeResult {
  code: string;
  email: string;
  ttlMinutes: number;
  expiresAt: string;
  locked: boolean;
}

export interface Kpi {
  value: number;
  delta: number | null;
  deltaCaption: string;
}

export interface SeriesPoint {
  date: string;
  value: number;
}

export interface AuditEntry {
  id: string;
  actorId: string | null;
  actorName: string;
  actorRole: string;
  actorRoleLabel: string;
  action: string;
  actionLabel: string;
  tone: 'slate' | 'sky' | 'green' | 'amber' | 'red' | 'purple';
  targetType: string;
  targetId: string | null;
  targetLabel: string;
  reason: string;
  meta: Record<string, unknown> | null;
  ipAddress: string | null;
  createdAt: string | null;
  createdAtLabel: string;
}

export interface Overview {
  generatedAt: string;
  rangeDays: number;
  kpis: {
    dau: Kpi;
    goalCompletionRate: Kpi;
    avgStreak: Kpi;
    newUsersToday: Kpi;
  };
  totalUsers: number;
  dauSeries: SeriesPoint[];
  dauSeriesPrev: SeriesPoint[];
  goalBreakdown: { exceeded: number; met: number; missed: number; avgUsersPerDay: number };
  levelDistribution: { level: number; users: number }[];
  hourlyDistribution: number[];
  retentionCohorts: { label: string; size: number; values: (number | null)[] }[];
  recentAudit: AuditEntry[];
}

export interface UserRow {
  id: string;
  name: string;
  email: string;
  level: number;
  xp: number;
  rank: string;
  streak: number;
  avgMl: number;
  goalMl: number;
  coins: number;
  status: 'active' | 'inactive' | 'locked';
  role: string;
  lastActiveAt: string | null;
  lastActiveLabel: string;
  joinedAt: string | null;
  isVerified: boolean;
}

export interface UserListResponse {
  items: UserRow[];
  page: number;
  pageSize: number;
  pages: number;
  total: number;
  summary: { totalUsers: number; activeToday: number; lockedUsers: number };
}

export interface WatchFlag {
  tone: 'green' | 'amber' | 'red' | 'slate';
  label: string;
  text: string;
}

export interface UserDetail {
  id: string;
  name: string;
  email: string;
  status: 'active' | 'inactive' | 'locked';
  role: string;
  level: number;
  rank: string;
  xp: number;
  xpIntoLevel: number;
  xpForNextLevel: number;
  xpToNextLevel: number;
  levelProgress: number;
  coins: number;
  streak: number;
  longestStreak: number;
  goalMl: number;
  avgMl: number;
  goalPercent: number;
  totalLogs: number;
  totalVolumeMl: number;
  achievementsCount: number;
  scansCount: number;
  joinedAt: string | null;
  lastLoginAt: string | null;
  lastActiveAt: string | null;
  lastActiveLabel: string;
  isVerified: boolean;
  authProvider: 'google' | 'password';
  timezone: string;
  weekly: { date: string; label: string; ml: number }[];
  recentLogs: {
    id: string;
    loggedAt: string | null;
    loggedAtLabel: string;
    volumeMl: number;
    effectiveMl: number;
    liquidType: string;
    source: string;
  }[];
  flags: WatchFlag[];
  audit: AuditEntry[];
}

export interface AuditListResponse {
  items: AuditEntry[];
  page: number;
  pageSize: number;
  pages: number;
  total: number;
  actions: { value: string; label: string }[];
}
