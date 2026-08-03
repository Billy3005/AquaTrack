// Lightweight SVG charts — ported from the prototype's charts.jsx.
// No charting library: every mark is a path we control, which is why the
// console has no external runtime dependency beyond React.

import { useId, useState } from 'react';
import { AD, AF, NUM } from '../theme';

export function ALine({
  data,
  labels,
  width = 700,
  height = 190,
  color = AD.accent,
  compare,
  unit = 'DAU',
}: {
  data: number[];
  labels?: string[];
  width?: number;
  height?: number;
  color?: string;
  compare?: number[];
  unit?: string;
}) {
  const gradientId = useId();
  const [hover, setHover] = useState<number | null>(null);
  if (data.length < 2) return <div style={{ height, display: 'flex', alignItems: 'center', justifyContent: 'center', color: AD.ink4, fontSize: 13 }}>Chưa đủ dữ liệu để vẽ biểu đồ</div>;

  const max = Math.max(...data, ...(compare || [0]), 1) * 1.12;
  const px = (i: number) => (i / (data.length - 1)) * width;
  const py = (v: number) => height - (v / max) * height;
  const path = (arr: number[]) =>
    arr
      .map((v, i) => {
        if (i === 0) return `M${px(i)},${py(v)}`;
        const x0 = px(i - 1);
        const y0 = py(arr[i - 1]);
        const x1 = px(i);
        const y1 = py(v);
        const cx = (x0 + x1) / 2;
        return `C${cx},${y0} ${cx},${y1} ${x1},${y1}`;
      })
      .join('');

  return (
    <div style={{ position: 'relative' }}>
      <svg
        width="100%"
        viewBox={`0 0 ${width} ${height + 22}`}
        style={{ display: 'block', overflow: 'visible' }}
        onMouseLeave={() => setHover(null)}
        onMouseMove={(e) => {
          const r = e.currentTarget.getBoundingClientRect();
          const i = Math.round(((e.clientX - r.left) / r.width) * (data.length - 1));
          setHover(Math.max(0, Math.min(data.length - 1, i)));
        }}
      >
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.26" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0, 0.25, 0.5, 0.75, 1].map((g) => (
          <line key={g} x1="0" x2={width} y1={height * g} y2={height * g} stroke={AD.border} strokeWidth="1" strokeDasharray={g === 1 ? '' : '3 4'} />
        ))}
        {compare && compare.length === data.length && (
          <path d={path(compare)} fill="none" stroke={AD.ink4} strokeWidth="1.7" strokeDasharray="4 4" opacity="0.7" />
        )}
        <path d={`${path(data)} L${width},${height} L0,${height} Z`} fill={`url(#${gradientId})`} />
        <path d={path(data)} fill="none" stroke={color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
        {hover != null && (
          <g>
            <line x1={px(hover)} x2={px(hover)} y1="0" y2={height} stroke={color} strokeWidth="1" strokeDasharray="3 3" />
            <circle cx={px(hover)} cy={py(data[hover])} r="5.5" fill="#fff" stroke={color} strokeWidth="2.6" />
          </g>
        )}
        {data.map((_, i) =>
          i % Math.max(1, Math.round(data.length / 6)) === 0 ? (
            <text key={i} x={px(i)} y={height + 16} fontSize="10.5" fill={AD.ink4} textAnchor="middle" fontFamily={AF}>
              {labels?.[i] ?? i + 1}
            </text>
          ) : null,
        )}
      </svg>
      {hover != null && (
        <div
          style={{
            position: 'absolute',
            left: `${(hover / (data.length - 1)) * 100}%`,
            top: -6,
            transform: 'translate(-50%,-100%)',
            background: AD.navy,
            color: '#fff',
            padding: '7px 11px',
            borderRadius: 8,
            fontSize: 11.5,
            fontWeight: 650,
            whiteSpace: 'nowrap',
            pointerEvents: 'none',
            ...NUM,
          }}
        >
          {data[hover].toLocaleString('vi-VN')} {unit} · {labels?.[hover] ?? `ngày ${hover + 1}`}
        </div>
      )}
    </div>
  );
}

export function ADonut({ pct, size = 168, thickness = 18, label = 'đạt mục tiêu', sub }: { pct: number; size?: number; thickness?: number; label?: string; sub?: string }) {
  const gradientId = useId();
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#38BDF8" />
            <stop offset="100%" stopColor="#0284C7" />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#EDF3F9" strokeWidth={thickness} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={`url(#${gradientId})`}
          strokeWidth={thickness}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c}
          style={{ animation: 'ad-dash 1.1s cubic-bezier(.3,1,.4,1) forwards', ['--to' as string]: c * (1 - Math.min(100, pct) / 100) }}
        />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ fontSize: 34, fontWeight: 750, color: AD.ink, letterSpacing: '-0.03em', ...NUM }}>{Math.round(pct)}%</div>
        <div style={{ fontSize: 11.5, color: AD.ink3, fontWeight: 600 }}>{label}</div>
        {sub && <div style={{ fontSize: 10.5, color: AD.ink4, marginTop: 2 }}>{sub}</div>}
      </div>
    </div>
  );
}

export type BarDatum = { label: string; value: number };

export function ABars({
  data,
  height = 156,
  color = AD.accent,
  labelFmt = (d: BarDatum) => d.label,
  highlight,
  valueFmt = (v: number) => v.toLocaleString('vi-VN'),
}: {
  data: BarDatum[];
  height?: number;
  color?: string;
  labelFmt?: (d: BarDatum) => string;
  highlight?: string;
  valueFmt?: (v: number) => string;
}) {
  const max = Math.max(...data.map((d) => d.value), 1);
  return (
    <div style={{ display: 'flex', alignItems: 'stretch', gap: 6, height: height + 26 }}>
      {data.map((d, i) => {
        const hi = highlight === d.label;
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 7 }} title={valueFmt(d.value)}>
            <div style={{ flex: 1, width: '100%', display: 'flex', alignItems: 'flex-end' }}>
              <div
                style={{
                  width: '100%',
                  height: `${(d.value / max) * 100}%`,
                  minHeight: 4,
                  borderRadius: '6px 6px 3px 3px',
                  background: hi ? 'linear-gradient(180deg, #FBBF24, #D97706)' : `linear-gradient(180deg, ${color}, ${AD.accentDeep})`,
                  opacity: hi ? 1 : 0.55 + (d.value / max) * 0.45,
                  animation: `ad-grow .7s cubic-bezier(.2,1,.4,1) ${i * 0.035}s backwards`,
                  transformOrigin: 'bottom',
                }}
              />
            </div>
            <div style={{ fontSize: 10.5, color: hi ? AD.amber : AD.ink4, fontWeight: hi ? 700 : 550, ...NUM }}>{labelFmt(d)}</div>
          </div>
        );
      })}
    </div>
  );
}

export type Cohort = { label: string; size: number; values: (number | null)[] };

export function AHeatmap({ cohorts }: { cohorts: Cohort[] }) {
  const cell = (v: number | null) => {
    if (v == null) return { background: '#F5F8FB', color: 'transparent' };
    const t = v / 100;
    return { background: `rgba(14,165,233,${0.09 + t * 0.82})`, color: t > 0.5 ? '#fff' : AD.ink2 };
  };
  if (!cohorts.length) {
    return <div style={{ padding: '40px 0', textAlign: 'center', color: AD.ink4, fontSize: 13 }}>Chưa có cohort nào trong khoảng thời gian này</div>;
  }
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '112px repeat(8, 1fr)', gap: 4, marginBottom: 6 }}>
        <div />
        {Array.from({ length: 8 }, (_, i) => (
          <div key={i} style={{ fontSize: 10.5, color: AD.ink4, textAlign: 'center', fontWeight: 600 }}>
            T{i + 1}
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {cohorts.map((co, r) => (
          <div key={r} style={{ display: 'grid', gridTemplateColumns: '112px repeat(8, 1fr)', gap: 4, alignItems: 'center' }}>
            <div style={{ fontSize: 11.5, color: AD.ink2, fontWeight: 600, ...NUM }}>
              {co.label} <span style={{ color: AD.ink4, fontWeight: 500 }}>· {co.size.toLocaleString('vi-VN')}</span>
            </div>
            {co.values.map((v, i) => (
              <div
                key={i}
                title={v == null ? '' : `${v}%`}
                style={{ height: 30, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10.5, fontWeight: 650, ...NUM, ...cell(v) }}
              >
                {v == null ? '' : `${v}%`}
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

export function AHours({ data }: { data: number[] }) {
  const max = Math.max(...data, 0.01);
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height: 116 }}>
        {data.map((v, h) => {
          const peak = v === max && v > 0;
          return (
            <div
              key={h}
              title={`${h}:00 · ${v}%`}
              style={{
                flex: 1,
                height: `${(v / max) * 100}%`,
                minHeight: 3,
                borderRadius: 4,
                background: peak ? 'linear-gradient(180deg,#FBBF24,#D97706)' : h >= 7 && h <= 22 ? `linear-gradient(180deg,${AD.accent},${AD.accentDeep})` : '#CBDCEA',
                opacity: peak ? 1 : 0.85,
                animation: `ad-grow .6s cubic-bezier(.2,1,.4,1) ${h * 0.02}s backwards`,
                transformOrigin: 'bottom',
              }}
            />
          );
        })}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 10.5, color: AD.ink4, ...NUM }}>
        {['0h', '6h', '12h', '18h', '23h'].map((l) => (
          <span key={l}>{l}</span>
        ))}
      </div>
    </div>
  );
}

export function ASpark({ data, width = 108, height = 34, color = AD.accent }: { data: number[]; width?: number; height?: number; color?: string }) {
  if (data.length < 2) return null;
  const max = Math.max(...data);
  const min = Math.min(...data);
  const pts = data.map((v, i) => `${(i / (data.length - 1)) * width},${height - ((v - min) / (max - min || 1)) * (height - 4) - 2}`).join(' ');
  return (
    <svg width={width} height={height}>
      <polyline points={pts} fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" opacity="0.8" />
    </svg>
  );
}
