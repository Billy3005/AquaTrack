import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Stats Screen - Complete redesign matching aquatrack/project/components/stats.jsx
class StatsScreenRedesign extends ConsumerStatefulWidget {
  const StatsScreenRedesign({super.key});

  @override
  ConsumerState<StatsScreenRedesign> createState() =>
      _StatsScreenRedesignState();
}

class _StatsScreenRedesignState extends ConsumerState<StatsScreenRedesign> {
  String _selectedPeriod = 'week';

  // Sample data for demonstration (in real app, this would come from provider)
  final List<DayData> weekData = [
    DayData(day: 'T2', pct: 102),
    DayData(day: 'T3', pct: 88),
    DayData(day: 'T4', pct: 100),
    DayData(day: 'T5', pct: 92),
    DayData(day: 'T6', pct: 67),
    DayData(day: 'T7', pct: 80),
    DayData(day: 'CN', pct: 78),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wave chart section
                      _buildWaveChartSection(),
                      const SizedBox(height: 16),

                      // Metric row
                      _buildMetricRow(),
                      const SizedBox(height: 18),

                      // AI insights
                      _buildAIInsights(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LỊCH SỬ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textBright,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tuần này',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.02,
                    ),
                  ),
                ],
              ),

              // Controls
              Row(
                children: [
                  _buildCoinBadge(1240),
                  const SizedBox(width: 8),
                  _buildPeriodToggle(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildCoinBadge(int amount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 9, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x2DFBBF24), // rgba(251,191,36,0.18)
            Color(0x0FF59E0B), // rgba(245,158,11,0.06)
          ],
        ),
        border: Border.all(
          color: const Color(0x73FBBF24), // rgba(251,191,36,0.45)
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.06),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCoinIcon(13),
          const SizedBox(width: 5),
          Text(
            amount.toString(),
            style: const TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFDE68A),
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.35, 0.3),
          radius: 0.75,
          colors: [
            Color(0xFFFEF3C7), // 0%
            Color(0xFFFBBF24), // 55%
            Color(0xFFB45309), // 100%
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF78350F),
          width: 0.6,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner circle
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFDE68A).withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
          ),
          // Dollar sign
          Text(
            '\$',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('week', 'Tuần'),
          _buildPeriodButton('month', 'Tháng'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.glow : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? const Color(0xFF082F49) : AppColors.textSecondary,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ),
    );
  }

  Widget _buildWaveChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C2A4A), Color(0xFF0B1933)],
        ),
        border: Border.all(
          color: const Color(0x2E38BDF8), // rgba(56,189,248,0.18)
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // Header with total and change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '14.7L',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'SF Pro Rounded',
                      letterSpacing: -0.02,
                    ),
                  ),
                  Text(
                    'tổng tuần · +1.2L vs tuần trước',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                decoration: BoxDecoration(
                  color: const Color(0x2610B981), // rgba(16,185,129,0.15)
                  border: Border.all(
                    color: const Color(0x4D10B981), // rgba(16,185,129,0.3)
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '+8.9%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF86EFAC),
                    fontFamily: 'SF Pro Rounded',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Wave chart
          _buildWaveChart(),
          const SizedBox(height: 6),

          // Day labels
          _buildDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWaveChart() {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: WaveChartPainter(weekData),
      ),
    );
  }

  Widget _buildDayLabels() {
    return Row(
      children: weekData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;

        Color labelColor;
        if (data.pct >= 100) {
          labelColor = const Color(0xFF86EFAC);
        } else if (data.pct < 80) {
          labelColor = const Color(0xFFFCA5A5);
        } else {
          labelColor = AppColors.textSecondary;
        }

        return Expanded(
          child: Column(
            children: [
              Text(
                data.day,
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.pct}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Rounded',
                  color: labelColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricRow() {
    return Row(
      children: [
        Expanded(
            child: _buildMetricCard(
                '84%', 'đạt mục tiêu', const Color(0xFF38BDF8))),
        const SizedBox(width: 8),
        Expanded(
            child: _buildMetricCard(
                '12', 'ngày streak', const Color(0xFFF97316),
                suffix: '🔥')),
        const SizedBox(width: 8),
        Expanded(
            child:
                _buildMetricCard('14.7L', 'tuần này', const Color(0xFFA78BFA))),
      ],
    );
  }

  Widget _buildMetricCard(String value, String label, Color accent,
      {String? suffix}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'SF Pro Rounded',
                letterSpacing: -0.02,
              ),
              children: suffix != null
                  ? [
                      TextSpan(
                        text: ' $suffix',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Text',
              letterSpacing: 0.04,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Color(0xFF38BDF8),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Gợi ý từ AI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Insight cards
        _buildInsightCard(
          color: const Color(0xFF38BDF8),
          tag: 'hydration',
          title: 'Buổi chiều là điểm yếu của bạn',
          body:
              'Bạn thường uống ít nhất vào khoảng 14–17h. Đặt nhắc nhở vào 15h sẽ giúp tăng 18% goal.',
        ),
        const SizedBox(height: 10),

        _buildInsightCard(
          color: const Color(0xFF818CF8),
          tag: 'pattern',
          title: 'Thứ Hai & Thứ Tư đạt 100%',
          body:
              'Thứ Sáu chỉ đạt 67% — có thể do lịch họp dày. Đặt mục tiêu thấp hơn ngày bận?',
        ),
        const SizedBox(height: 10),

        _buildInsightCard(
          color: const Color(0xFFF59E0B),
          tag: 'weather',
          title: 'Hôm nay nóng — goal đã tăng',
          body:
              'Nhiệt độ 34°C đã tự động tăng goal lên 2,800ml. Bạn đã uống được 1,450ml.',
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required Color color,
    required String tag,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: color.withValues(alpha: 0.13), width: 1),
          right: BorderSide(color: color.withValues(alpha: 0.13), width: 1),
          bottom: BorderSide(color: color.withValues(alpha: 0.13), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              color: color,
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Text',
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }
}

class DayData {
  final String day;
  final int pct;

  DayData({required this.day, required this.pct});
}

class WaveChartPainter extends CustomPainter {
  final List<DayData> data;

  WaveChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final P = 8.0; // padding

    // Calculate points
    final xs = List.generate(
        data.length, (i) => P + i * ((W - 2 * P) / (data.length - 1)));
    final ys = data.map((d) {
      final v = math.min(120, d.pct);
      return H - 8 - v / 120 * (H - 18);
    }).toList();

    // Goal line at 100%
    final goalY = H - 8 - 100 / 120 * (H - 18);

    // Draw goal line (dashed)
    final goalPaint = Paint()
      ..color = const Color(0x7338BDF8) // rgba(56,189,248,0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashPath = Path();
    double distance = 0;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    while (distance < W - 2 * P) {
      dashPath.moveTo(P + distance, goalY);
      dashPath.lineTo(P + math.min(distance + dashWidth, W - 2 * P), goalY);
      distance += dashWidth + dashSpace;
    }
    canvas.drawPath(dashPath, goalPaint);

    // Create smooth curve path
    final path = Path();
    path.moveTo(xs[0], ys[0]);

    for (int i = 1; i < xs.length; i++) {
      final px = xs[i - 1];
      final py = ys[i - 1];
      final x = xs[i];
      final y = ys[i];

      final cx1 = px + (x - px) / 2;
      final cx2 = px + (x - px) / 2;

      path.cubicTo(cx1, py, cx2, y, x, y);
    }

    // Create fill path
    final fillPath = Path.from(path);
    fillPath.lineTo(xs.last, H);
    fillPath.lineTo(xs.first, H);
    fillPath.close();

    // Draw fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x800EA5E9), // rgba(14,165,233,0.5)
          Color(0x190C3A5E), // rgba(12,58,94,0.1)
        ],
      ).createShader(Rect.fromLTWH(0, 0, W, H))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Draw points
    for (int i = 0; i < xs.length; i++) {
      final ok = data[i].pct >= 100;
      final pointColor = ok ? const Color(0xFF38BDF8) : const Color(0xFFF87171);

      // Outer circle (glow)
      final outerPaint = Paint()
        ..color = pointColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(xs[i], ys[i]), 5, outerPaint);

      // Inner circle
      final innerPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(xs[i], ys[i]), 2.8, innerPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = AppColors.nightBase
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(xs[i], ys[i]), 2.8, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
