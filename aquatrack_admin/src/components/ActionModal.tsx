// The confirmation dialog for every destructive admin action.
//
// Ported from the prototype, with the guards made real: the reason is sent to
// the server and stored in the audit log, and the typed confirmation word is
// re-checked server-side. The dialog is the only path to these APIs in the UI,
// so there is exactly one place where "are you sure" is asked.

import { useEffect, useState } from 'react';
import { A } from '../icons';
import { AD, NUM } from '../theme';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { ABtn, AInput, ALabel, AModal, ATextarea } from './ui';
import type { ResetCodeResult, UserRow } from '../types';

export type ActionKind = 'lock' | 'unlock' | 'reset' | 'grant' | 'passwordReset';

export interface ActionTarget {
  id: string;
  name: string;
}

interface ActionConfig {
  title: string;
  desc: string;
  cta: string;
  danger: boolean;
  confirmWord?: string;
  grant?: boolean;
  /** Keeps the dialog open to show something the server returned exactly once. */
  showsResult?: boolean;
  successToast: string;
}

export const ACTIONS: Record<ActionKind, ActionConfig> = {
  lock: {
    title: 'Khoá tài khoản',
    desc: 'Người dùng sẽ không thể đăng nhập. Dữ liệu uống nước, streak và XP được giữ nguyên — mở khoá là khôi phục lại đầy đủ.',
    cta: 'Khoá tài khoản',
    danger: true,
    confirmWord: 'KHOA',
    successToast: 'Đã khoá tài khoản · ghi vào nhật ký thao tác',
  },
  unlock: {
    title: 'Mở khoá tài khoản',
    desc: 'Người dùng có thể đăng nhập lại ngay lập tức.',
    cta: 'Mở khoá',
    danger: false,
    successToast: 'Đã mở khoá tài khoản',
  },
  reset: {
    title: 'Reset dữ liệu uống nước',
    desc: 'Xoá toàn bộ lịch sử uống nước và đặt streak về 0. Xu và XP đã tích luỹ được GIỮ LẠI. Hành động KHÔNG THỂ hoàn tác.',
    cta: 'Reset dữ liệu',
    danger: true,
    confirmWord: 'RESET',
    successToast: 'Đã reset dữ liệu người dùng',
  },
  passwordReset: {
    title: 'Cấp mã đặt lại mật khẩu',
    desc: 'Sinh mã 6 số hiệu lực 10 phút. Đọc mã cho người dùng qua kênh hỗ trợ, họ tự nhập ở màn hình "Quên mật khẩu" trong app. Bạn không nhìn thấy và không đặt được mật khẩu mới của họ.',
    cta: 'Sinh mã',
    danger: false,
    showsResult: true,
    successToast: 'Đã cấp mã đặt lại · ghi vào nhật ký thao tác',
  },
  grant: {
    title: 'Tặng xu / XP thủ công',
    desc: 'Ghi có trực tiếp vào tài khoản. Cần lý do rõ ràng vì thao tác ảnh hưởng tới bảng xếp hạng.',
    cta: 'Xác nhận tặng',
    danger: false,
    grant: true,
    successToast: 'Đã cộng thưởng · ghi vào nhật ký thao tác',
  },
};

export function ActionModal({
  kind,
  target,
  onClose,
  onDone,
}: {
  kind: ActionKind | null;
  target: ActionTarget | UserRow | null;
  onClose: () => void;
  onDone: (message: string, tone: 'success' | 'error') => void;
}) {
  const { profile } = useAuth();
  const [reason, setReason] = useState('');
  const [typed, setTyped] = useState('');
  const [coins, setCoins] = useState('100');
  const [xp, setXp] = useState('500');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<ResetCodeResult | null>(null);
  const [copied, setCopied] = useState(false);

  // Reset the form whenever a new action opens, so a previously typed reason
  // can never be reused by accident on a different user — and so a reset code
  // minted for one account is never left on screen while another is open.
  useEffect(() => {
    setReason('');
    setTyped('');
    setCoins('100');
    setXp('500');
    setError(null);
    setBusy(false);
    setResult(null);
    setCopied(false);
  }, [kind, target?.id]);

  if (!kind || !target) return null;
  const cfg = ACTIONS[kind];

  const reasonOk = reason.trim().length >= 6;
  const wordOk = !cfg.confirmWord || typed === cfg.confirmWord;
  const amountsOk = !cfg.grant || Number(coins) > 0 || Number(xp) > 0;
  const blocked = busy || !reasonOk || !wordOk || !amountsOk;

  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      if (kind === 'lock') await api.lockUser(target.id, reason.trim());
      if (kind === 'unlock') await api.unlockUser(target.id, reason.trim());
      if (kind === 'reset') await api.resetUser(target.id, reason.trim(), typed);
      if (kind === 'grant') await api.grant(target.id, Number(coins) || 0, Number(xp) || 0, reason.trim());
      if (kind === 'passwordReset') {
        // Hold the dialog open: this is the only time the code is ever shown.
        setResult(await api.issueResetCode(target.id, reason.trim()));
        setBusy(false);
        return;
      }
      onDone(cfg.successToast, 'success');
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Thao tác thất bại');
      setBusy(false);
    }
  };

  return (
    <AModal open onClose={busy ? () => {} : onClose} width={cfg.grant ? 500 : 460}>
      <div style={{ padding: '20px 22px 16px', display: 'flex', gap: 13, alignItems: 'flex-start', borderBottom: `1px solid ${AD.border}` }}>
        <div
          style={{
            width: 38,
            height: 38,
            borderRadius: 11,
            flexShrink: 0,
            background: cfg.danger ? AD.redTint : AD.accentTint,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {cfg.danger ? A.alert(AD.red, 19) : A.check(AD.accentDeep, 19)}
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15.5, fontWeight: 700 }}>{cfg.title}</div>
          <div style={{ fontSize: 12.5, color: AD.ink3, marginTop: 4 }}>
            {target.name} · {target.id.slice(0, 8)}
          </div>
        </div>
        <button onClick={onClose} disabled={busy} style={{ border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex' }}>
          {A.x(AD.ink3)}
        </button>
      </div>

      {result ? (
        <ResetCodePanel
          result={result}
          copied={copied}
          onCopy={async () => {
            try {
              await navigator.clipboard.writeText(result.code);
              setCopied(true);
            } catch {
              setCopied(false); // clipboard blocked — the code is on screen anyway
            }
          }}
          onFinish={() => {
            onDone(cfg.successToast, 'success');
            onClose();
          }}
        />
      ) : (
        <>
      <div style={{ padding: '18px 22px' }}>
        <div style={{ fontSize: 13, color: AD.ink2, lineHeight: 1.6 }}>{cfg.desc}</div>

        {cfg.grant && (
          <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
            <div style={{ flex: 1 }}>
              <ALabel>Số xu</ALabel>
              <AInput value={coins} onChange={(v) => setCoins(v.replace(/\D/g, ''))} placeholder="0" />
            </div>
            <div style={{ flex: 1 }}>
              <ALabel>Số XP</ALabel>
              <AInput value={xp} onChange={(v) => setXp(v.replace(/\D/g, ''))} placeholder="0" />
            </div>
          </div>
        )}

        <div style={{ marginTop: 16 }}>
          <ALabel>Lý do (bắt buộc — lưu vào nhật ký thao tác)</ALabel>
          <ATextarea value={reason} onChange={setReason} rows={2} placeholder="Ví dụ: spam bình luận trong thử thách ngày 01/08" />
          {reason.length > 0 && !reasonOk && (
            <div style={{ fontSize: 11.5, color: AD.amber, marginTop: 5 }}>Lý do cần ít nhất 6 ký tự</div>
          )}
        </div>

        {cfg.confirmWord && (
          <div style={{ marginTop: 14 }}>
            <ALabel>
              Gõ{' '}
              <code style={{ background: AD.redTint, color: AD.red, padding: '1px 6px', borderRadius: 4, fontWeight: 700 }}>{cfg.confirmWord}</code>{' '}
              để xác nhận
            </ALabel>
            <AInput value={typed} onChange={setTyped} placeholder={cfg.confirmWord} />
          </div>
        )}

        {error && (
          <div style={{ marginTop: 14, padding: '10px 12px', background: AD.redTint, border: '1px solid #F8D2DA', borderRadius: 9, fontSize: 12.5, color: AD.red }}>
            {error}
          </div>
        )}

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            marginTop: 16,
            padding: '10px 12px',
            background: AD.panelAlt,
            border: `1px solid ${AD.border}`,
            borderRadius: 9,
            fontSize: 11.5,
            color: AD.ink3,
            lineHeight: 1.5,
          }}
        >
          {A.history(AD.ink4)}
          <span>
            Thao tác này được ghi lại kèm tên bạn (<b style={{ color: AD.ink2 }}>{profile?.name}</b>), thời gian, địa chỉ IP và lý do.
          </span>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 10, padding: '14px 22px', borderTop: `1px solid ${AD.border}`, background: AD.panelAlt }}>
        <div style={{ flex: 1 }} />
        <ABtn onClick={onClose} disabled={busy}>
          Huỷ
        </ABtn>
        <ABtn kind={cfg.danger ? 'dangerSolid' : 'primary'} disabled={blocked} onClick={submit}>
          {busy ? 'Đang xử lý…' : cfg.cta}
        </ABtn>
      </div>
        </>
      )}
    </AModal>
  );
}

/**
 * Shown once, after the server mints a reset code. The code lives only in this
 * component's props — it is never written to localStorage, never put in a URL,
 * and the audit log deliberately does not record it either, so this dialog is
 * the single copy. Closing it means asking for a new one.
 */
function ResetCodePanel({
  result,
  copied,
  onCopy,
  onFinish,
}: {
  result: ResetCodeResult;
  copied: boolean;
  onCopy: () => void;
  onFinish: () => void;
}) {
  return (
    <>
      <div style={{ padding: '20px 22px' }}>
        <div style={{ fontSize: 13, color: AD.ink2, lineHeight: 1.6 }}>
          Đọc mã này cho <b style={{ color: AD.ink }}>{result.email}</b>. Họ mở app → Đăng nhập → <b style={{ color: AD.ink }}>Quên mật khẩu</b> → nhập
          đúng email đó → bấm <b style={{ color: AD.ink }}>Gửi mã</b> → nhập mã dưới đây và mật khẩu mới.
        </div>

        <div
          style={{
            marginTop: 16,
            padding: '18px 20px',
            background: AD.accentTint,
            border: `1px solid ${AD.accent}`,
            borderRadius: 12,
            textAlign: 'center',
          }}
        >
          <div style={{ fontSize: 11, fontWeight: 700, color: AD.accentDeep, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
            Mã đặt lại · hiệu lực {result.ttlMinutes} phút
          </div>
          <div style={{ fontSize: 34, fontWeight: 750, color: AD.ink, letterSpacing: '0.16em', margin: '10px 0 12px', ...NUM }}>{result.code}</div>
          <ABtn onClick={onCopy} icon={copied ? A.check(AD.green, 14) : A.doc(AD.ink3, 14)}>
            {copied ? 'Đã sao chép' : 'Sao chép mã'}
          </ABtn>
        </div>

        {result.locked && (
          <div style={{ marginTop: 14, padding: '10px 12px', background: AD.redTint, border: '1px solid #F8D2DA', borderRadius: 9, fontSize: 12.5, color: AD.red, lineHeight: 1.5 }}>
            Tài khoản này đang bị khoá — đặt lại mật khẩu xong họ vẫn chưa đăng nhập được. Mở khoá trước nếu đó là điều bạn muốn.
          </div>
        )}

        <div style={{ marginTop: 14, padding: '10px 12px', background: AD.panelAlt, border: `1px solid ${AD.border}`, borderRadius: 9, fontSize: 11.5, color: AD.ink3, lineHeight: 1.5 }}>
          Mã chỉ hiện một lần và không được lưu vào nhật ký thao tác. Đóng cửa sổ là mất — cấp lại nếu cần. Sai 5 lần hoặc quá {result.ttlMinutes} phút thì mã tự huỷ.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 10, padding: '14px 22px', borderTop: `1px solid ${AD.border}`, background: AD.panelAlt }}>
        <div style={{ flex: 1 }} />
        <ABtn kind="primary" onClick={onFinish}>
          Đã đọc mã cho người dùng
        </ABtn>
      </div>
    </>
  );
}
