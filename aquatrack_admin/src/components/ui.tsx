// UI primitives — ported from the prototype's ui.jsx, typed and made
// controllable where a real screen needs it (the mock's inputs were static).

import type { CSSProperties, ReactNode } from 'react';
import { A } from '../icons';
import { AD, AF, NUM, TONE_COLORS, type Tone } from '../theme';

export function ACard({
  children,
  pad = 20,
  style,
}: {
  children: ReactNode;
  pad?: number;
  style?: CSSProperties;
}) {
  return (
    <div
      style={{
        background: AD.panel,
        border: `1px solid ${AD.border}`,
        borderRadius: 14,
        padding: pad,
        boxShadow: AD.shadow,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

export function ACardHead({
  title,
  sub,
  right,
}: {
  title: ReactNode;
  sub?: ReactNode;
  right?: ReactNode;
}) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 16, marginBottom: 16 }}>
      <div>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: AD.ink, letterSpacing: '-0.01em' }}>{title}</div>
        {sub && <div style={{ fontSize: 12, color: AD.ink3, marginTop: 3 }}>{sub}</div>}
      </div>
      {right}
    </div>
  );
}

type BtnKind = 'primary' | 'ghost' | 'soft' | 'danger' | 'dangerSolid';

export function ABtn({
  children,
  kind = 'ghost',
  size = 'md',
  icon,
  onClick,
  disabled,
  full,
  type = 'button',
  title,
}: {
  children?: ReactNode;
  kind?: BtnKind;
  size?: 'sm' | 'md' | 'lg';
  icon?: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  full?: boolean;
  type?: 'button' | 'submit';
  title?: string;
}) {
  const pads = { sm: '6px 11px', md: '9px 15px', lg: '11px 18px' };
  const fs = { sm: 12, md: 13, lg: 13.5 };
  const k: Record<BtnKind, CSSProperties> = {
    primary: {
      background: `linear-gradient(180deg, ${AD.accent}, ${AD.accentDeep})`,
      color: '#fff',
      border: '1px solid transparent',
      boxShadow: '0 2px 8px rgba(14,165,233,0.3)',
    },
    ghost: { background: '#fff', color: AD.ink2, border: `1px solid ${AD.borderStrong}` },
    soft: { background: AD.accentTint, color: AD.accentDeep, border: `1px solid ${AD.accentTint2}` },
    danger: { background: AD.redTint, color: AD.red, border: '1px solid #F8D2DA' },
    dangerSolid: { background: AD.red, color: '#fff', border: '1px solid transparent' },
  };
  return (
    <button
      type={type}
      title={title}
      onClick={onClick}
      disabled={disabled}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 7,
        padding: pads[size],
        borderRadius: 9,
        fontFamily: AF,
        fontSize: fs[size],
        fontWeight: 600,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.5 : 1,
        width: full ? '100%' : undefined,
        whiteSpace: 'nowrap',
        transition: 'filter .15s, transform .1s',
        ...k[kind],
      }}
      onMouseDown={(e) => (e.currentTarget.style.transform = 'translateY(1px)')}
      onMouseUp={(e) => (e.currentTarget.style.transform = 'none')}
      onMouseLeave={(e) => (e.currentTarget.style.transform = 'none')}
    >
      {icon}
      {children}
    </button>
  );
}

export function APill({ tone = 'slate', children, dot }: { tone?: Tone; children: ReactNode; dot?: boolean }) {
  const t = TONE_COLORS[tone] ?? TONE_COLORS.slate;
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        padding: '3.5px 9px',
        borderRadius: 999,
        background: t[1],
        color: t[0],
        fontSize: 11.5,
        fontWeight: 650,
        whiteSpace: 'nowrap',
      }}
    >
      {dot && <span style={{ width: 5.5, height: 5.5, borderRadius: '50%', background: t[0] }} />}
      {children}
    </span>
  );
}

export function AAvatar({ name, size = 34, hue }: { name: string; size?: number; hue?: number }) {
  const safe = name?.trim() || '?';
  const initials = safe
    .split(' ')
    .slice(-2)
    .map((w) => w[0])
    .join('')
    .toUpperCase();
  const h = hue != null ? hue : (safe.charCodeAt(0) * 13 + safe.length * 29) % 360;
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: '50%',
        flexShrink: 0,
        background: `linear-gradient(140deg, hsl(${h} 70% 62%), hsl(${(h + 38) % 360} 72% 46%))`,
        color: '#fff',
        fontSize: size * 0.36,
        fontWeight: 700,
        letterSpacing: '0.01em',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 1px 3px rgba(14,36,56,0.18)',
      }}
    >
      {initials}
    </div>
  );
}

export function AStat({
  label,
  value,
  unit,
  delta,
  deltaCaption,
  icon,
  tone = 'sky',
  spark,
}: {
  label: string;
  value: ReactNode;
  unit?: string;
  delta?: number | null;
  deltaCaption?: string;
  icon: ReactNode;
  tone?: 'sky' | 'green' | 'amber' | 'purple';
  spark?: ReactNode;
}) {
  const up = delta != null && delta >= 0;
  const t = { sky: AD.accent, green: AD.green, amber: AD.amber, purple: AD.purple }[tone];
  return (
    <ACard pad={18} style={{ position: 'relative', overflow: 'hidden' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 12 }}>
        <div style={{ width: 30, height: 30, borderRadius: 9, background: `${t}14`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
        <div style={{ fontSize: 12.5, color: AD.ink2, fontWeight: 600 }}>{label}</div>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
        <div style={{ fontSize: 28, fontWeight: 750, color: AD.ink, letterSpacing: '-0.03em', ...NUM }}>{value}</div>
        {unit && <div style={{ fontSize: 13, color: AD.ink3, fontWeight: 600 }}>{unit}</div>}
      </div>
      {delta != null ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 8, fontSize: 12, color: up ? AD.green : AD.red, fontWeight: 650 }}>
          <span style={{ display: 'inline-flex', transform: up ? 'none' : 'rotate(180deg)' }}>{A.up(up ? AD.green : AD.red)}</span>
          {Math.abs(delta)}% <span style={{ color: AD.ink4, fontWeight: 500 }}>{deltaCaption}</span>
        </div>
      ) : (
        // No honest baseline to compare against — say so rather than show 0%.
        deltaCaption && <div style={{ marginTop: 8, fontSize: 12, color: AD.ink4 }}>{deltaCaption}</div>
      )}
      {spark && <div style={{ position: 'absolute', right: 0, bottom: 0, opacity: 0.5 }}>{spark}</div>}
    </ACard>
  );
}

export function AField({
  icon,
  placeholder,
  value,
  onChange,
  width = 260,
  onEnter,
}: {
  icon?: ReactNode;
  placeholder?: string;
  value?: string;
  onChange?: (v: string) => void;
  width?: number | string;
  onEnter?: () => void;
}) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, width, padding: '0 11px', height: 36, background: '#fff', border: `1px solid ${AD.borderStrong}`, borderRadius: 9 }}>
      {icon}
      <input
        value={value}
        onChange={(e) => onChange && onChange(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && onEnter && onEnter()}
        placeholder={placeholder}
        style={{ flex: 1, minWidth: 0, border: 'none', outline: 'none', background: 'transparent', fontFamily: AF, fontSize: 13, color: AD.ink }}
      />
    </div>
  );
}

export function ASelect<T extends string>({
  value,
  options,
  onChange,
  width,
}: {
  value: T;
  options: { value: T; label: string }[];
  onChange: (v: T) => void;
  width?: number;
}) {
  return (
    <div style={{ position: 'relative', width }}>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as T)}
        style={{
          appearance: 'none',
          width: '100%',
          height: 36,
          padding: '0 30px 0 12px',
          borderRadius: 9,
          border: `1px solid ${AD.borderStrong}`,
          background: '#fff',
          fontFamily: AF,
          fontSize: 13,
          color: AD.ink,
          fontWeight: 550,
          cursor: 'pointer',
          outline: 'none',
        }}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      <span style={{ position: 'absolute', right: 10, top: 11, pointerEvents: 'none' }}>{A.chevD(AD.ink3)}</span>
    </div>
  );
}

export function ASegment<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T;
  options: { value: T; label: string }[];
  onChange: (v: T) => void;
}) {
  return (
    <div style={{ display: 'inline-flex', background: '#EDF2F7', borderRadius: 9, padding: 3, gap: 2 }}>
      {options.map((o) => (
        <button
          key={o.value}
          onClick={() => onChange(o.value)}
          style={{
            padding: '6px 13px',
            borderRadius: 7,
            border: 'none',
            cursor: 'pointer',
            fontFamily: AF,
            fontSize: 12.5,
            fontWeight: 650,
            background: value === o.value ? '#fff' : 'transparent',
            color: value === o.value ? AD.ink : AD.ink3,
            boxShadow: value === o.value ? '0 1px 3px rgba(14,36,56,0.12)' : 'none',
          }}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function ALabel({ children }: { children: ReactNode }) {
  return <div style={{ fontSize: 11.5, fontWeight: 650, color: AD.ink2, marginBottom: 6 }}>{children}</div>;
}

export function AInput({
  value,
  onChange,
  placeholder,
  type = 'text',
  autoFocus,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  autoFocus?: boolean;
}) {
  return (
    <input
      value={value}
      type={type}
      autoFocus={autoFocus}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      style={{
        width: '100%',
        boxSizing: 'border-box',
        height: 38,
        padding: '0 12px',
        borderRadius: 9,
        border: `1px solid ${AD.borderStrong}`,
        fontFamily: AF,
        fontSize: 13,
        color: AD.ink,
        outline: 'none',
      }}
    />
  );
}

export function ATextarea({
  value,
  onChange,
  placeholder,
  rows = 2,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  rows?: number;
}) {
  return (
    <textarea
      value={value}
      rows={rows}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      style={{
        width: '100%',
        boxSizing: 'border-box',
        padding: '10px 12px',
        borderRadius: 9,
        border: `1px solid ${AD.borderStrong}`,
        fontFamily: AF,
        fontSize: 13,
        color: AD.ink,
        resize: 'vertical',
        outline: 'none',
      }}
    />
  );
}

export function ACheck({ checked, onChange }: { checked: boolean; onChange: () => void }) {
  return (
    <button
      onClick={onChange}
      style={{
        width: 17,
        height: 17,
        borderRadius: 5,
        cursor: 'pointer',
        padding: 0,
        border: `1.6px solid ${checked ? AD.accent : AD.borderStrong}`,
        background: checked ? AD.accent : '#fff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {checked && A.check('#fff', 11)}
    </button>
  );
}

export function AMenuItem({
  icon,
  label,
  onClick,
  danger,
  disabled,
}: {
  icon: ReactNode;
  label: string;
  onClick: () => void;
  danger?: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      title={disabled ? 'Vai trò của bạn không được phép thao tác này' : undefined}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 9,
        width: '100%',
        padding: '8px 10px',
        borderRadius: 8,
        border: 'none',
        background: 'transparent',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.45 : 1,
        fontFamily: AF,
        fontSize: 12.5,
        fontWeight: 600,
        color: danger ? AD.red : AD.ink2,
        textAlign: 'left',
      }}
      onMouseEnter={(e) => {
        if (!disabled) e.currentTarget.style.background = danger ? AD.redTint : '#F2F6FA';
      }}
      onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
    >
      {icon}
      {label}
    </button>
  );
}

export function AStatusPill({ status }: { status: string }) {
  const m: Record<string, [Tone, string]> = {
    active: ['green', 'Hoạt động'],
    inactive: ['slate', 'Không hoạt động'],
    locked: ['red', 'Đã khoá'],
  };
  const [tone, label] = m[status] ?? (['slate', status] as [Tone, string]);
  return (
    <APill tone={tone} dot>
      {label}
    </APill>
  );
}

// ── states ──────────────────────────────────────────────────────────────────

export function ASkeletonRows({ rows = 8, cols }: { rows?: number; cols: string }) {
  return (
    <div>
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} style={{ display: 'grid', gridTemplateColumns: cols, gap: 14, padding: '15px 22px', borderTop: `1px solid ${AD.border}`, alignItems: 'center' }}>
          {cols.split(' ').map((_c, c) => (
            <div
              key={c}
              style={{
                height: 11,
                borderRadius: 5,
                background: 'linear-gradient(90deg,#EDF2F7,#F6F9FC,#EDF2F7)',
                backgroundSize: '200% 100%',
                animation: `ad-shim 1.3s ease-in-out ${r * 0.05 + c * 0.03}s infinite`,
                width: c === 0 ? '75%' : `${45 + ((r + c) % 4) * 12}%`,
              }}
            />
          ))}
        </div>
      ))}
    </div>
  );
}

export function AEmpty({ title, sub, action, icon }: { title: string; sub?: string; action?: ReactNode; icon?: ReactNode }) {
  return (
    <div style={{ padding: '58px 24px', textAlign: 'center' }}>
      <div style={{ width: 56, height: 56, borderRadius: 16, background: AD.accentTint, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
        {icon || A.drop(AD.accent, 26)}
      </div>
      <div style={{ fontSize: 15, fontWeight: 700, color: AD.ink }}>{title}</div>
      {sub && <div style={{ fontSize: 13, color: AD.ink3, marginTop: 6, maxWidth: 380, marginLeft: 'auto', marginRight: 'auto', lineHeight: 1.55 }}>{sub}</div>}
      {action && <div style={{ marginTop: 18 }}>{action}</div>}
    </div>
  );
}

export function AError({ onRetry, message }: { onRetry: () => void; message?: string }) {
  return (
    <div style={{ padding: '52px 24px', textAlign: 'center' }}>
      <div style={{ width: 56, height: 56, borderRadius: 16, background: AD.redTint, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
        {A.alert(AD.red, 26)}
      </div>
      <div style={{ fontSize: 15, fontWeight: 700, color: AD.ink }}>Không tải được dữ liệu</div>
      <div style={{ fontSize: 13, color: AD.ink3, marginTop: 6 }}>{message || 'Máy chủ không phản hồi. Vui lòng thử lại sau ít phút.'}</div>
      <div style={{ marginTop: 18, display: 'flex', gap: 10, justifyContent: 'center' }}>
        <ABtn kind="primary" icon={A.reset('#fff')} onClick={onRetry}>
          Thử lại
        </ABtn>
      </div>
    </div>
  );
}

const pagerBtn = (active: boolean): CSSProperties => ({
  minWidth: 30,
  height: 30,
  padding: '0 8px',
  borderRadius: 8,
  cursor: 'pointer',
  fontFamily: AF,
  fontSize: 12.5,
  fontWeight: 650,
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  border: `1px solid ${active ? 'transparent' : AD.border}`,
  background: active ? AD.accent : '#fff',
  color: active ? '#fff' : AD.ink2,
  ...NUM,
});

export function APager({
  page,
  pages,
  total,
  pageSize,
  onPage,
  noun = 'người dùng',
}: {
  page: number;
  pages: number;
  total: number;
  pageSize: number;
  onPage: (p: number) => void;
  noun?: string;
}) {
  const nums: (number | '…')[] = [];
  for (let i = 1; i <= pages; i++) {
    if (i === 1 || i === pages || Math.abs(i - page) <= 1) nums.push(i);
    else if (nums[nums.length - 1] !== '…') nums.push('…');
  }
  const from = total === 0 ? 0 : (page - 1) * pageSize + 1;
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 22px', borderTop: `1px solid ${AD.border}` }}>
      <div style={{ fontSize: 12.5, color: AD.ink3, ...NUM }}>
        Hiển thị{' '}
        <b style={{ color: AD.ink2 }}>
          {from}–{Math.min(page * pageSize, total)}
        </b>{' '}
        trong <b style={{ color: AD.ink2 }}>{total.toLocaleString('vi-VN')}</b> {noun}
      </div>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <button onClick={() => onPage(Math.max(1, page - 1))} style={pagerBtn(false)}>
          {A.chevL(AD.ink2)}
        </button>
        {nums.map((n, i) =>
          n === '…' ? (
            <span key={i} style={{ padding: '0 4px', color: AD.ink4, fontSize: 13 }}>
              …
            </span>
          ) : (
            <button key={i} onClick={() => onPage(n)} style={pagerBtn(n === page)}>
              {n}
            </button>
          ),
        )}
        <button onClick={() => onPage(Math.min(pages, page + 1))} style={pagerBtn(false)}>
          {A.chevR(AD.ink2)}
        </button>
      </div>
    </div>
  );
}

export function AModal({ open, onClose, children, width = 460 }: { open: boolean; onClose: () => void; children: ReactNode; width?: number }) {
  if (!open) return null;
  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 90,
        background: 'rgba(10,32,54,0.44)',
        backdropFilter: 'blur(3px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        animation: 'ad-fade .18s ease-out',
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ width, background: '#fff', borderRadius: 16, boxShadow: AD.shadowUp, animation: 'ad-pop .22s cubic-bezier(.2,1.2,.4,1)', overflow: 'hidden' }}
      >
        {children}
      </div>
    </div>
  );
}

export type ToastState = { text: string; tone?: 'success' | 'error' } | null;

export function AToast({ toast }: { toast: ToastState }) {
  if (!toast) return null;
  const bad = toast.tone === 'error';
  return (
    <div
      style={{
        position: 'fixed',
        bottom: 26,
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 95,
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '12px 18px',
        background: AD.navy,
        color: '#fff',
        borderRadius: 11,
        boxShadow: AD.shadowUp,
        fontSize: 13,
        fontWeight: 600,
        animation: 'ad-toast .3s cubic-bezier(.2,1.2,.4,1)',
      }}
    >
      <span style={{ display: 'flex', width: 19, height: 19, borderRadius: '50%', background: bad ? AD.red : AD.green, alignItems: 'center', justifyContent: 'center' }}>
        {bad ? A.x('#fff', 12) : A.check('#fff', 12)}
      </span>
      {toast.text}
    </div>
  );
}

export function ASpinner({ size = 18, color = AD.accent }: { size?: number; color?: string }) {
  return (
    <span
      style={{
        width: size,
        height: size,
        borderRadius: '50%',
        border: `2px solid ${color}33`,
        borderTopColor: color,
        display: 'inline-block',
        animation: 'ad-spin .7s linear infinite',
      }}
    />
  );
}
