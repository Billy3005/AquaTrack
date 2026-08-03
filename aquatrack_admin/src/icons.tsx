// Icon set — ported 1:1 from the prototype's `A` object. Same call signature
// (colour, size) so the screen code reads identically to the design source.

import type { ReactElement } from 'react';

type Icon = (c: string, s?: number) => ReactElement;

export const A: Record<string, Icon> = {
  grid: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="8" rx="1.6" />
      <rect x="14" y="3" width="7" height="5" rx="1.6" />
      <rect x="14" y="11" width="7" height="10" rx="1.6" />
      <rect x="3" y="14" width="7" height="7" rx="1.6" />
    </svg>
  ),
  users: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="8" r="3.4" />
      <path d="M2.6 20a6.6 6.6 0 0 1 12.8 0" />
      <path d="M16.5 5.2a3.2 3.2 0 0 1 0 6" />
      <path d="M18 14.6a6.2 6.2 0 0 1 3.5 5.4" />
    </svg>
  ),
  trophy: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 4h10v5a5 5 0 0 1-10 0z" />
      <path d="M7 5.5H4.5A2.5 2.5 0 0 0 7 10" />
      <path d="M17 5.5h2.5A2.5 2.5 0 0 1 17 10" />
      <path d="M10 14h4l.6 3.4H9.4z" />
      <path d="M7.5 20.5h9" />
    </svg>
  ),
  doc: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 3h8l4 4v14H6z" />
      <path d="M14 3v4h4" />
      <path d="M9 12h6M9 16h6" />
    </svg>
  ),
  flag: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 21V4" />
      <path d="M5 5h11l-1.6 3.4L16 12H5z" />
    </svg>
  ),
  bell: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 15V10a6 6 0 1 0-12 0v5l-1.6 2.6h15.2z" />
      <path d="M10 20.4a2.4 2.4 0 0 0 4 0" />
    </svg>
  ),
  gear: (c, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3.2" />
      <path d="M12 2.8v2.4M12 18.8v2.4M4.5 4.5l1.7 1.7M17.8 17.8l1.7 1.7M2.8 12h2.4M18.8 12h2.4M4.5 19.5l1.7-1.7M17.8 6.2l1.7-1.7" />
    </svg>
  ),
  search: (c, s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round">
      <circle cx="11" cy="11" r="6.4" />
      <path d="M15.8 15.8 21 21" />
    </svg>
  ),
  filter: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 5h18l-7 8v6l-4 2v-8z" />
    </svg>
  ),
  down: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4v11M7.5 11 12 15.5 16.5 11M4.5 20h15" />
    </svg>
  ),
  lock: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4.5" y="10" width="15" height="10" rx="2.4" />
      <path d="M8 10V7.5a4 4 0 0 1 8 0V10" />
    </svg>
  ),
  unlock: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4.5" y="10" width="15" height="10" rx="2.4" />
      <path d="M8 10V7.5a4 4 0 0 1 7.6-1.6" />
    </svg>
  ),
  coin: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8">
      <ellipse cx="12" cy="7.4" rx="7" ry="3.2" />
      <path d="M5 7.4v9.2c0 1.8 3.1 3.2 7 3.2s7-1.4 7-3.2V7.4" strokeLinecap="round" />
      <path d="M5 12c0 1.8 3.1 3.2 7 3.2s7-1.4 7-3.2" strokeLinecap="round" />
    </svg>
  ),
  bolt: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M13 2 4 14h7v8l9-12h-7z" />
    </svg>
  ),
  reset: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1" />
      <path d="M3.5 4.5V10H9" />
    </svg>
  ),
  send: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 3 10.5 13.5" />
      <path d="M21 3l-6.8 18-3.7-7.5L3 9.8z" />
    </svg>
  ),
  drop: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c} fillOpacity="0.9">
      <path d="M12 3s-6.5 7.6-6.5 12.3A6.5 6.5 0 0 0 12 21.8a6.5 6.5 0 0 0 6.5-6.5C18.5 10.6 12 3 12 3z" />
    </svg>
  ),
  flame: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M12 2c0 4-4 5-4 10 0 4 1.6 7 4 7s4-3 4-7c0-3-2-4-2-7 0-1-1-2-2-3z" />
    </svg>
  ),
  dots: (c, s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <circle cx="5" cy="12" r="1.7" />
      <circle cx="12" cy="12" r="1.7" />
      <circle cx="19" cy="12" r="1.7" />
    </svg>
  ),
  chevR: (c, s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 5l7 7-7 7" />
    </svg>
  ),
  chevL: (c, s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 5l-7 7 7 7" />
    </svg>
  ),
  chevD: (c, s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 9l7 7 7-7" />
    </svg>
  ),
  up: (c, s = 13) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 19V6M6 11l6-6 6 6" />
    </svg>
  ),
  x: (c, s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.1" strokeLinecap="round">
      <path d="M6 6l12 12M18 6 6 18" />
    </svg>
  ),
  check: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4.5 12.5 9.5 17.5 19.5 6.5" />
    </svg>
  ),
  alert: (c, s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3.6 21.4 20H2.6z" />
      <path d="M12 9.6v4.6M12 17.3h.01" />
    </svg>
  ),
  clock: (c, s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="8.6" />
      <path d="M12 7.4V12l3 2" />
    </svg>
  ),
  history: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3.6 12a8.4 8.4 0 1 0 2.5-6" />
      <path d="M3.6 4.6V10H9" />
      <path d="M12 8v4.4l3 1.8" />
    </svg>
  ),
  plus: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.3" strokeLinecap="round">
      <path d="M12 5v14M5 12h14" />
    </svg>
  ),
  logout: (c, s = 15) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 4h4.5A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5H14" />
      <path d="M10 8l-4 4 4 4M6 12h9" />
    </svg>
  ),
};
