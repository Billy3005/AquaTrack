import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Public, transparent explanation of how AquaTrack derives a daily water goal.
/// Mirrors aquatrack_backend/aquatrack-water-formula.md exactly so the number
/// shown on the drop is never a black box.
void showWaterFormulaInfoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WaterFormulaSheet(),
  );
}

const _cyan = Color(0xFF38BDF8);
const _cyanSoft = Color(0xFF7DD3FC);

class _WaterFormulaSheet extends StatelessWidget {
  const _WaterFormulaSheet();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.nightBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: _cyan, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AquaTrack — Công thức tính nước',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Intro(),
                  SizedBox(height: 20),
                  _SectionTitle('Công thức tổng'),
                  SizedBox(height: 8),
                  _CodeBox(
                    'total = nền tảng + vận động + công việc\n'
                    '        + sức khỏe + rau củ + cà phê + rượu bia\n\n'
                    'total = làm tròn đến 50ml gần nhất\n'
                    'total = tối thiểu 1.500ml',
                  ),
                  SizedBox(height: 20),
                  _SectionTitle('Các thành phần'),
                  SizedBox(height: 10),
                  _Component(
                    label: 'Nền tảng',
                    value: 'cân nặng × 35ml',
                    note: 'Nữ × 0.95',
                  ),
                  _Component(
                    label: 'Vận động',
                    value: 'cân nặng × 0–19ml',
                    note: 'Ít vận động → rất năng động',
                  ),
                  _Component(
                    label: 'Công việc',
                    value: '+0 → +500ml',
                    note: 'Văn phòng · Hỗn hợp · Ngoài trời · Tay chân',
                  ),
                  _Component(
                    label: 'Sức khỏe',
                    value: '+0 → +700ml',
                    note: 'Tiểu đường, cao huyết áp, thai kỳ…',
                  ),
                  _Component(
                    label: 'Rau củ quả',
                    value: '−100 → −400ml',
                    note: 'Ăn càng nhiều rau, trừ càng nhiều',
                  ),
                  _Component(
                    label: 'Cà phê',
                    value: '+120ml / cốc',
                    note: 'Bù phần lợi tiểu nhẹ',
                  ),
                  _Component(
                    label: 'Rượu bia',
                    value: '+200ml / đơn vị',
                    note: '1 đơn vị = 1 lon bia / 1 ly vang',
                  ),
                  SizedBox(height: 20),
                  _SectionTitle('Ví dụ thực tế'),
                  SizedBox(height: 8),
                  _CodeBox(
                    'Nam · 60kg · vừa phải · văn phòng\n'
                    'không bệnh · rau vừa · 1 cà phê · 0 rượu\n\n'
                    '60×35            = 2.100ml\n'
                    '60×14 (vận động)  = +840ml\n'
                    'rau vừa           = −250ml\n'
                    '1 cà phê          = +120ml\n'
                    '──────────────────────\n'
                    '= 2.810 → tròn 50 = 2.800ml\n'
                    '≈ 2,8 lít · 11 cốc 250ml',
                  ),
                  SizedBox(height: 20),
                  _SectionTitle('Quy đổi'),
                  SizedBox(height: 8),
                  _CodeBox(
                    'lít       = total / 1000\n'
                    'cốc 250ml = total / 250',
                  ),
                  SizedBox(height: 20),
                  _Disclaimer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'AquaTrack chụp ảnh ly nước → AI đếm ml → giúp bạn sống khoẻ hơn mỗi '
      'ngày. Mục tiêu nước hằng ngày của bạn không phải con số ngẫu nhiên: '
      'nó được tính minh bạch từ cơ thể và lối sống của bạn theo công thức '
      'dưới đây. App cũng tự điều chỉnh nhẹ theo thời tiết và vận động.',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.5,
        height: 1.5,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _cyanSoft,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String text;
  const _CodeBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFBAE6FD),
          fontSize: 12.5,
          height: 1.55,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _Component extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  const _Component({
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration:
                const BoxDecoration(color: _cyan, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _cyanSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đây là ước tính tham khảo, không thay thế lời khuyên y tế. '
              'Nếu bạn có bệnh thần kinh, tim mạch hoặc đang điều trị, hãy hỏi '
              'bác sĩ về lượng nước phù hợp.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
