// Design tokens — transcribed verbatim from the Claude Design prototype
// (aquatrack/project/admin/ui.jsx). Nothing here is invented: if a value needs
// to change, change it in both places or the console stops matching the mock.

import type { CSSProperties } from 'react';

export const AD = {
  bg: '#F3F7FB',
  panel: '#FFFFFF',
  panelAlt: '#FAFCFE',
  border: '#E3EBF3',
  borderStrong: '#D2DEEA',
  ink: '#0E2438',
  ink2: '#4A6379',
  ink3: '#8095A9',
  ink4: '#A9BACA',
  accent: '#0EA5E9',
  accentDeep: '#0284C7',
  accentTint: '#E7F6FE',
  accentTint2: '#CFEDFC',
  navy: '#0A2C4A',
  navy2: '#062036',
  green: '#0E9F6E',
  greenTint: '#E4F7F0',
  amber: '#D97706',
  amberTint: '#FEF3E2',
  red: '#DC2F4B',
  redTint: '#FDEDF0',
  purple: '#6366F1',
  purpleTint: '#EEEFFE',
  shadow: '0 1px 2px rgba(14,36,56,0.04), 0 6px 20px rgba(14,36,56,0.05)',
  shadowUp: '0 12px 40px rgba(14,36,56,0.16)',
} as const;

export const AF =
  '-apple-system, "SF Pro Display", "SF Pro Text", "Segoe UI", system-ui, sans-serif';

// Tabular figures — every number in a table or KPI must line up column-wise.
export const NUM: CSSProperties = {
  fontVariantNumeric: 'tabular-nums',
  fontFeatureSettings: '"tnum"',
};

export type Tone = 'slate' | 'sky' | 'green' | 'amber' | 'red' | 'purple';

export const TONE_COLORS: Record<Tone, [string, string]> = {
  slate: [AD.ink3, '#EEF3F8'],
  sky: [AD.accentDeep, AD.accentTint],
  green: [AD.green, AD.greenTint],
  amber: [AD.amber, AD.amberTint],
  red: [AD.red, AD.redTint],
  purple: [AD.purple, AD.purpleTint],
};
