// Vietnamese number/date formatting. The console is Vietnamese-only, so these
// are deliberately not locale-parameterised.

export const vi = (n: number) => n.toLocaleString('vi-VN');

export const viDecimal = (n: number, digits = 1) =>
  n.toLocaleString('vi-VN', { minimumFractionDigits: digits, maximumFractionDigits: digits });

export function viDate(iso: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

export function viDateTime(iso: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return `${d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' })} · ${d.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
  })}`;
}

/** "2026-08-03" -> "3/8" for chart axis labels. */
export function shortDay(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return `${d.getDate()}/${d.getMonth() + 1}`;
}

export const LIQUID_LABELS: Record<string, string> = {
  water: 'Nước lọc',
  tea: 'Trà',
  coffee: 'Cà phê',
  juice: 'Nước ép',
  milk: 'Sữa',
  soda: 'Nước ngọt',
};

export const SOURCE_LABELS: Record<string, string> = {
  manual: 'Thủ công',
  quick_log: 'Ghi nhanh',
  smart_scan: 'Smart Scan',
  ai_suggestion: 'AI Coach',
  seed: 'Dữ liệu mẫu',
};
