import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/providers/user_stats_provider.dart';
import '../../core/repositories/stats_repository.dart';
import '../../shared/widgets/coin_badge.dart';
import 'providers/stats_provider.dart';

/// Stats / History screen — every widget is bound to real backend data
/// (see CONTEXT.md: Stats Period, Day Progress, Liquid Breakdown).
class StatsScreenRedesign extends ConsumerWidget {
  const StatsScreenRedesign({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final statsAsync = ref.watch(statsNotifierProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref, period),
              Expanded(
                child: statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _buildErrorState(ref, error.toString()),
                  data: (statsData) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWaveChartSection(statsData),
                        const SizedBox(height: 16),
                        _buildMetricRow(statsData),
                        const SizedBox(height: 18),
                        if (statsData.liquidBreakdown.isNotEmpty) ...[
                          _buildLiquidSection(statsData),
                          const SizedBox(height: 18),
                        ],
                        _buildAIInsights(statsData),
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

  // ---------------------------------------------------------------- helpers

  String _formatVolume(double volumeMl) {
    if (volumeMl < 1000) return '${volumeMl.round()}ml';
    return '${(volumeMl / 1000).toStringAsFixed(1)}L';
  }

  String _formatPercentage(double percentage) => '${percentage.round()}%';

  String _periodLabel(StatsPeriod period) =>
      period == StatsPeriod.week ? 'tuần này' : 'tháng này';

  String _periodTitle(StatsPeriod period) =>
      period == StatsPeriod.week ? 'Tuần này' : 'Tháng này';

  // ------------------------------------------------------------------ header

  Widget _buildHeader(BuildContext context, WidgetRef ref, StatsPeriod period) {
    final coins = ref.watch(userStatsProvider).valueOrNull?.coins ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
                  Text(
                    _periodTitle(period),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.02,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  CoinBadge(amount: coins),
                  const SizedBox(width: 8),
                  _buildPeriodToggle(ref, period),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(WidgetRef ref, StatsPeriod period) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton(ref, period, StatsPeriod.week, 'Tuần'),
          _buildPeriodButton(ref, period, StatsPeriod.month, 'Tháng'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    WidgetRef ref,
    StatsPeriod current,
    StatsPeriod value,
    String label,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => ref.read(statsPeriodProvider.notifier).state = value,
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

  // -------------------------------------------------------------- wave chart

  Widget _buildWaveChartSection(StatsData statsData) {
    final total = statsData.totalVolumeMl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C2A4A), Color(0xFF0B1933)],
        ),
        border: Border.all(color: const Color(0x2E38BDF8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatVolume(total),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'SF Pro Rounded',
                      letterSpacing: -0.02,
                    ),
                  ),
                  Text(
                    'tổng ${_periodLabel(statsData.period)} · ${statsData.chartData.length} ngày',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                  decoration: BoxDecoration(
                    color: const Color(0x2610B981),
                    border: Border.all(color: const Color(0x4D10B981)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatPercentage(statsData.goalCompletionRate * 100),
                    style: const TextStyle(
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
          SizedBox(
            width: double.infinity,
            height: 120,
            child: CustomPaint(
              painter: WaveChartPainter(_toPercents(statsData.chartData)),
            ),
          ),
          const SizedBox(height: 6),
          // Day labels only make sense in the 7-day week view.
          if (statsData.period == StatsPeriod.week)
            _buildWeekDayLabels(statsData),
        ],
      ),
    );
  }

  /// Percentage of goal for each day, used by the painter.
  List<double> _toPercents(List<ChartDataPoint> chartData) {
    return chartData
        .map((p) => p.goal > 0 ? (p.value / p.goal) * 100 : 0.0)
        .toList();
  }

  Widget _buildWeekDayLabels(StatsData statsData) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final data = statsData.chartData;

    return Row(
      children: List.generate(data.length, (index) {
        final point = data[index];
        final pct = point.goal > 0 ? point.value / point.goal * 100 : 0.0;
        // Real weekday from the date (DateTime.weekday: 1=Mon..7=Sun).
        final label = labels[(point.date.weekday - 1).clamp(0, 6)];

        Color labelColor;
        if (pct >= 100) {
          labelColor = const Color(0xFF86EFAC);
        } else if (pct < 80) {
          labelColor = const Color(0xFFFCA5A5);
        } else {
          labelColor = AppColors.textSecondary;
        }

        return Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${pct.round()}%',
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
      }),
    );
  }

  // ----------------------------------------------------------------- metrics

  Widget _buildMetricRow(StatsData statsData) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            _formatPercentage(statsData.goalCompletionRate * 100),
            'đạt mục tiêu',
            const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            '${statsData.streakDays}',
            'ngày streak',
            const Color(0xFFF97316),
            suffix: statsData.streakDays > 0 ? '🔥' : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            _formatVolume(statsData.totalVolumeMl),
            _periodLabel(statsData.period),
            const Color(0xFFA78BFA),
          ),
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
            style: const TextStyle(
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

  // --------------------------------------------------------- liquid breakdown

  static const Map<String, String> _liquidLabels = {
    'water': 'Nước lọc',
    'tea': 'Trà',
    'coffee': 'Cà phê',
    'juice': 'Nước trái cây',
    'smoothie': 'Sinh tố',
    'milk': 'Sữa',
    'soda': 'Nước ngọt',
    'other': 'Khác',
  };

  static const List<Color> _liquidColors = [
    Color(0xFF38BDF8),
    Color(0xFFA78BFA),
    Color(0xFFF59E0B),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFF60A5FA),
  ];

  String _liquidLabel(String type) => _liquidLabels[type.toLowerCase()] ?? type;

  Widget _buildLiquidSection(StatsData statsData) {
    // Show the biggest contributors first.
    final items = [...statsData.liquidBreakdown]
      ..sort((a, b) => b.totalVolumeMl.compareTo(a.totalVolumeMl));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_drink_outlined,
                color: Color(0xFF38BDF8), size: 14),
            SizedBox(width: 6),
            Text(
              'Phân tích loại nước',
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
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          decoration: BoxDecoration(
            color: AppColors.nightCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++)
                _buildLiquidRow(
                    items[i], _liquidColors[i % _liquidColors.length]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidRow(LiquidTypeBreakdown item, Color color) {
    final pct = item.volumePercentage.clamp(0, 100).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _liquidLabel(item.liquidType),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
              Text(
                '${_formatVolume(item.totalVolumeMl.toDouble())} · ${pct.round()}%',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'SF Pro Rounded',
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- insights

  Widget _buildAIInsights(StatsData statsData) {
    final insights = statsData.insights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
            SizedBox(width: 6),
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
        if (insights.isEmpty)
          _buildInsightCard(
            color: const Color(0xFF38BDF8),
            tag: 'hydration',
            title: 'Chưa đủ dữ liệu để phân tích',
            body:
                'Hãy log thêm vài ly nước trong tuần để mình đưa ra gợi ý chính xác hơn nhé.',
          )
        else
          for (int i = 0; i < insights.length; i++) ...[
            _buildInsightCard(
              color: _insightColor(insights[i].type),
              tag: insights[i].type,
              title: insights[i].title,
              body: insights[i].message,
            ),
            if (i < insights.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Color _insightColor(String type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'achievement':
        return const Color(0xFF10B981);
      case 'suggestion':
        return const Color(0xFF818CF8);
      case 'motivational':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF38BDF8);
    }
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
            style: const TextStyle(
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

  // ------------------------------------------------------------------- error

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
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
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(statsNotifierProvider),
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

class WaveChartPainter extends CustomPainter {
  /// Percentage-of-goal for each day (any length: 7 for week, 30 for month).
  final List<double> percents;

  WaveChartPainter(this.percents);

  @override
  void paint(Canvas canvas, Size size) {
    if (percents.isEmpty) return;

    final w = size.width;
    final h = size.height;
    const p = 8.0;

    final n = percents.length;
    final xs = List.generate(
      n,
      (i) => n == 1 ? w / 2 : p + i * ((w - 2 * p) / (n - 1)),
    );
    final ys = percents.map((pct) {
      final v = math.min(120.0, pct);
      return h - 8 - v / 120 * (h - 18);
    }).toList();

    // Goal line at 100%
    final goalY = h - 8 - 100 / 120 * (h - 18);
    final goalPaint = Paint()
      ..color = const Color(0x7338BDF8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashPath = Path();
    double distance = 0;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    while (distance < w - 2 * p) {
      dashPath.moveTo(p + distance, goalY);
      dashPath.lineTo(p + math.min(distance + dashWidth, w - 2 * p), goalY);
      distance += dashWidth + dashSpace;
    }
    canvas.drawPath(dashPath, goalPaint);

    // Smooth curve
    final path = Path()..moveTo(xs[0], ys[0]);
    for (int i = 1; i < xs.length; i++) {
      final px = xs[i - 1];
      final py = ys[i - 1];
      final x = xs[i];
      final y = ys[i];
      final cx = px + (x - px) / 2;
      path.cubicTo(cx, py, cx, y, x, y);
    }

    // Fill
    final fillPath = Path.from(path)
      ..lineTo(xs.last, h)
      ..lineTo(xs.first, h)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x800EA5E9), Color(0x190C3A5E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Points — hide individual dots in dense (month) view to avoid clutter.
    if (n <= 10) {
      for (int i = 0; i < xs.length; i++) {
        final ok = percents[i] >= 100;
        final pointColor =
            ok ? const Color(0xFF38BDF8) : const Color(0xFFF87171);

        canvas.drawCircle(
          Offset(xs[i], ys[i]),
          5,
          Paint()..color = pointColor.withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          Offset(xs[i], ys[i]),
          2.8,
          Paint()..color = pointColor,
        );
        canvas.drawCircle(
          Offset(xs[i], ys[i]),
          2.8,
          Paint()
            ..color = AppColors.nightBase
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveChartPainter oldDelegate) =>
      oldDelegate.percents != percents;
}
