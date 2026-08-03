// Nhật ký thao tác — the full, filterable audit trail.
//
// This screen is the reason the destructive actions are allowed to exist: every
// lock, reset, grant and export is here with who did it, when, from which IP,
// and why. Rows are append-only; the console offers no way to edit or delete.

import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { A } from '../icons';
import { AD, NUM } from '../theme';
import { api } from '../lib/api';
import { useApi, useDebounced } from '../lib/useApi';
import { vi, viDateTime } from '../lib/format';
import { useActions } from '../App';
import { ACard, AAvatar, AEmpty, AError, AField, APager, APill, ASelect, ASkeletonRows } from '../components/ui';

const COLS = '1.5fr 1.2fr 1.6fr 1.7fr 1fr';
const PAGE_SIZE = 20;

export function AuditScreen() {
  const { version } = useActions();
  const [q, setQ] = useState('');
  const [action, setAction] = useState('all');
  const [page, setPage] = useState(1);
  const debouncedQ = useDebounced(q);

  useEffect(() => {
    setPage(1);
  }, [debouncedQ, action]);

  const { data, loading, error, reload } = useApi(
    () => api.audit({ q: debouncedQ, action, page, page_size: PAGE_SIZE }),
    [debouncedQ, action, page, version],
  );

  const actionOptions = [{ value: 'all', label: 'Mọi loại thao tác' }, ...(data?.actions ?? [])];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div>
        <h1 style={{ margin: 0, fontSize: 22, fontWeight: 750, color: AD.ink, letterSpacing: '-0.025em' }}>Nhật ký thao tác</h1>
        <div style={{ fontSize: 13, color: AD.ink3, marginTop: 4, ...NUM }}>
          {data ? `${vi(data.total)} bản ghi` : 'Đang tải…'} · chỉ thêm mới, không sửa và không xoá
        </div>
      </div>

      <ACard pad={0}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 22px', flexWrap: 'wrap' }}>
          <AField icon={A.search(AD.ink3)} placeholder="Tìm theo người thực hiện, đối tượng hoặc lý do…" value={q} onChange={setQ} width={320} />
          <ASelect value={action} onChange={setAction} width={220} options={actionOptions} />
          <div style={{ marginLeft: 'auto', fontSize: 12.5, color: AD.ink3, ...NUM }}>{data ? `${vi(data.total)} kết quả` : '—'}</div>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: COLS,
            gap: 14,
            padding: '10px 22px',
            background: AD.panelAlt,
            borderTop: `1px solid ${AD.border}`,
            borderBottom: `1px solid ${AD.border}`,
          }}
        >
          {['Người thực hiện', 'Thao tác', 'Đối tượng', 'Lý do', 'Thời gian · IP'].map((h) => (
            <div key={h} style={{ fontSize: 11, fontWeight: 700, color: AD.ink3, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              {h}
            </div>
          ))}
        </div>

        {loading && !data && <ASkeletonRows rows={8} cols={COLS} />}
        {error && <AError onRetry={reload} message={error} />}
        {data && data.items.length === 0 && (
          <AEmpty
            icon={A.history(AD.accent, 24)}
            title="Chưa có bản ghi nào khớp bộ lọc"
            sub="Nhật ký sẽ tự động ghi lại mỗi lần khoá, mở khoá, reset dữ liệu, tặng thưởng hoặc xuất CSV."
          />
        )}

        {data?.items.map((entry) => (
          <div key={entry.id} style={{ display: 'grid', gridTemplateColumns: COLS, gap: 14, padding: '13px 22px', borderBottom: `1px solid ${AD.border}`, alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
              <AAvatar name={entry.actorName} size={30} />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 650, color: AD.ink, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{entry.actorName}</div>
                <div style={{ fontSize: 11, color: AD.ink3 }}>{entry.actorRoleLabel}</div>
              </div>
            </div>

            <div>
              <APill tone={entry.tone}>{entry.actionLabel}</APill>
            </div>

            <div style={{ fontSize: 12.5, color: AD.ink2, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {entry.targetType === 'user' && entry.targetId ? (
                <Link to={`/users/${entry.targetId}`} title={entry.targetLabel}>
                  {entry.targetLabel}
                </Link>
              ) : (
                <span title={entry.targetLabel}>{entry.targetLabel || '—'}</span>
              )}
              {entry.meta && (
                <div style={{ fontSize: 11, color: AD.ink4, marginTop: 2, ...NUM }}>
                  {Object.entries(entry.meta)
                    .map(([k, v]) => `${k}: ${String(v)}`)
                    .join(' · ')}
                </div>
              )}
            </div>

            <div style={{ fontSize: 12.5, color: AD.ink3, lineHeight: 1.45 }}>{entry.reason || '—'}</div>

            <div style={{ fontSize: 12, color: AD.ink3, textAlign: 'right', ...NUM }}>
              {viDateTime(entry.createdAt)}
              <div style={{ fontSize: 11, color: AD.ink4, marginTop: 2 }}>{entry.ipAddress || '—'}</div>
            </div>
          </div>
        ))}

        {data && data.items.length > 0 && (
          <APager page={data.page} pages={data.pages} total={data.total} pageSize={data.pageSize} onPage={setPage} noun="bản ghi" />
        )}
      </ACard>
    </div>
  );
}
