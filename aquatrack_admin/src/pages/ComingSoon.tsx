// Placeholder screens for console sections whose backend does not exist yet.
//
// These are deliberately empty rather than wired to mock data: a console that
// shows invented numbers is worse than one that admits a gap, and a "Khoá tài
// khoản" button that silently does nothing is worse still. Each page states
// exactly what would have to be built first.

import { A } from '../icons';
import { AD } from '../theme';
import { ACard, APill } from '../components/ui';

export interface ComingSoonPage {
  path: string;
  title: string;
  intro: string;
  icon: (c: string, s?: number) => JSX.Element;
  blockers: string[];
}

export const COMING_SOON: ComingSoonPage[] = [
  {
    path: '/gamification',
    title: 'Gamification',
    icon: A.trophy,
    intro: 'Cấu hình level, luật XP, huy hiệu và cửa hàng xu.',
    blockers: [
      'Đường cong level đang hardcode trong app/core/leveling.py — cần đưa xuống bảng cấu hình trong DB trước khi cho sửa từ giao diện',
      'Danh sách huy hiệu nằm trong achievements_spec.md, chưa phải dữ liệu có thể truy vấn',
      'Cửa hàng mới có duy nhất vật phẩm Streak Freeze (app/api/v1/endpoints/shop.py)',
      'Sửa đường cong XP sẽ làm đổi level của toàn bộ người dùng hiện tại — cần chiến lược migration trước',
    ],
  },
  {
    path: '/content',
    title: 'Thử thách & nội dung',
    icon: A.doc,
    intro: 'Tạo, lên lịch và xuất bản thử thách cùng bài viết sức khoẻ.',
    blockers: [
      'Bảng challenges hiện là "cuộc đua giữa bạn bè" (models/challenge.py), không phải thử thách do admin tạo',
      'Chưa có mô hình dữ liệu cho bài viết / tips — cần bảng content mới',
      'Chưa có luồng duyệt bài (nháp → chờ duyệt → xuất bản)',
    ],
  },
  {
    path: '/reports',
    title: 'Báo cáo & kiểm duyệt',
    icon: A.flag,
    intro: 'Tiếp nhận báo cáo vi phạm, lỗi ứng dụng và nghi vấn gian lận chỉ số.',
    blockers: [
      'Chưa có bảng reports',
      'Ứng dụng chưa có bình luận hay nội dung do người dùng tạo để kiểm duyệt',
      'Phát hiện gian lận chỉ số (ví dụ 18L trong 40 phút) cần một job phân tích chạy nền',
    ],
  },
  {
    path: '/notifications',
    title: 'Thông báo đẩy',
    icon: A.bell,
    intro: 'Chiến dịch nhắc nhở định kỳ, kích hoạt theo hành vi và gửi hàng loạt.',
    blockers: [
      'Chưa tích hợp FCM — bảng users mới chỉ lưu cột push_token',
      'Chưa có bảng campaign và bộ đếm lượt gửi / lượt mở',
      'Cần worker chạy nền để gửi theo lịch và tôn trọng giờ yên tĩnh',
    ],
  },
  {
    path: '/settings',
    title: 'Cài đặt & phân quyền',
    icon: A.gear,
    intro: 'Quản lý thành viên nội bộ, mời tài khoản mới và chỉnh ma trận phân quyền.',
    blockers: [
      'Ma trận phân quyền đã tồn tại trong app/core/admin_roles.py nhưng đang là hằng số trong code, chưa sửa được từ giao diện',
      'Chưa có luồng mời thành viên qua email',
      'Đổi vai trò của một người cần chính nó là một thao tác có kiểm toán — sẽ dùng lại bảng audit_logs',
    ],
  },
];

export function ComingSoonScreen({ page }: { page: ComingSoonPage }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 750, color: AD.ink, letterSpacing: '-0.025em' }}>{page.title}</h1>
          <APill tone="amber">Chưa triển khai</APill>
        </div>
        <div style={{ fontSize: 13, color: AD.ink3, marginTop: 4 }}>{page.intro}</div>
      </div>

      <ACard pad={0}>
        <div style={{ padding: '46px 30px 34px', textAlign: 'center' }}>
          <div
            style={{
              width: 60,
              height: 60,
              borderRadius: 18,
              background: AD.accentTint,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 18px',
            }}
          >
            {page.icon(AD.accent, 28)}
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, color: AD.ink }}>Màn hình này chưa có dữ liệu thật</div>
          <div style={{ fontSize: 13, color: AD.ink3, marginTop: 8, maxWidth: 480, margin: '8px auto 0', lineHeight: 1.6 }}>
            Bản thiết kế đã có đầy đủ giao diện, nhưng backend chưa có API tương ứng. Console cố tình để trống thay vì hiển thị số liệu
            giả — một bảng điều khiển nói dối còn nguy hiểm hơn một bảng điều khiển thiếu.
          </div>
        </div>

        <div style={{ borderTop: `1px solid ${AD.border}`, background: AD.panelAlt, padding: '20px 26px 24px' }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: AD.ink2, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 14 }}>
            Cần làm trước khi bật màn hình này
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
            {page.blockers.map((b, i) => (
              <div key={i} style={{ display: 'flex', gap: 11, alignItems: 'flex-start', fontSize: 13, color: AD.ink2, lineHeight: 1.55 }}>
                <span
                  style={{
                    flexShrink: 0,
                    width: 20,
                    height: 20,
                    borderRadius: 6,
                    background: '#fff',
                    border: `1px solid ${AD.border}`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 11,
                    fontWeight: 700,
                    color: AD.ink3,
                    marginTop: 1,
                  }}
                >
                  {i + 1}
                </span>
                <span>{b}</span>
              </div>
            ))}
          </div>
        </div>
      </ACard>
    </div>
  );
}
