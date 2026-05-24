import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/coin_badge.dart';
import 'providers/stats_provider.dart';

/// Stats Screen - Complete redesign matching aquatrack/project/components/stats.jsx
class StatsScreenRedesign extends ConsumerStatefulWidget {
  const StatsScreenRedesign({super.key});

  @override
  ConsumerState<StatsScreenRedesign> createState() =>
      _StatsScreenRedesignState();
}

class _StatsScreenRedesignState extends ConsumerState<StatsScreenRedesign> {
  StatsPeriod _selectedPeriod = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    // Watch stats data from provider
    final statsAsync = ref.watch(statsNotifierProvider);
    final statsState = ref.watch(statsNotifierProvider.notifier);

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
                child: statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(error.toString()),
                  data: (statsData) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wave chart section
                        _buildWaveChartSection(statsData),
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
                  const CoinBadge(amount: 1240),
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
    final period = value == 'week' ? StatsPeriod.week : StatsPeriod.month;
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
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

  Widget _buildWaveChartSection(StatsData statsData) {
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
          _buildWaveChart(statsData),
          const SizedBox(height: 6),

          // Day labels
          _buildDayLabels(statsData),
        ],
      ),
    );
  }

  Widget _buildWaveChart(StatsData statsData) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: WaveChartPainter(_convertToWaveData(statsData.chartData)),
      ),
    );
  }

  Widget _buildDayLabels(StatsData statsData) {
    // Mock day labels for now
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Row(
      children: dayLabels.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;

        // Calculate mock percentage from chart data if available
        final mockPct = index < statsData.chartData.length
            ? (statsData.chartData[index].value /
                statsData.chartData[index].goal *
                100)
            : 50.0;

        Color labelColor;
        if (mockPct >= 100) {
          labelColor = const Color(0xFF86EFAC);
        } else if (mockPct < 80) {
          labelColor = const Color(0xFFFCA5A5);
        } else {
          labelColor = AppColors.textSecondary;
        }

        return Expanded(
          child: Column(
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${mockPct.round()}%',
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
            '84%',
            'đạt mục tiêu',
            const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            '12',
            'ngày streak',
            const Color(0xFFF97316),
            suffix: '🔥',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard('14.7L', 'tuần này', const Color(0xFFA78BFA)),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String value,
    String label,
    Color accent, {
    String? suffix,
  }) {
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
            const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
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

  /// Convert ChartDataPoint to DayData format for WaveChartPainter
  List<DayData> _convertToWaveData(List<ChartDataPoint> chartData) {
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return List.generate(7, (index) {
      if (index < chartData.length) {
        final point = chartData[index];
        final pct = ((point.value / point.goal) * 100).round();
        return DayData(day: dayLabels[index], pct: pct);
      } else {
        // Fill missing days with 0%
        return DayData(day: dayLabels[index], pct: 0);
      }
    });
  }

  /// Build error state widget
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Trigger refresh
                ref
                    .read(statsNotifierProvider.notifier)
                    .setPeriod(_selectedPeriod);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
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
      data.length,
      (i) => P + i * ((W - 2 * P) / (data.length - 1)),
    );
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
