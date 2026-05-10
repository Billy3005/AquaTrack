import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/enhanced_card.dart';

/// Stats screen matching exact design prototype
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'Tuần';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildMainMetric(),
                const SizedBox(height: 24),
                _buildWaveChart(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 32),
                _buildAIInsights(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LỊCH SỬ HYDRATION',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tuần này',
              style: AppTextStyles.headlineLarge.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildPeriodButton('Tuần'),
              _buildPeriodButton('Tháng'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.cyanLight, AppColors.cyanAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyanAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          period,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMainMetric() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '14.7',
          style: AppTextStyles.waterAmount.copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'L',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 28,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            '+8.9%',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveChart() {
    return EnhancedCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.surfaceColor.withValues(alpha: 0.6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lượng nước → 1.5L mỗi ngày trước',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                'Goal 100%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Wave chart
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _WaveChartPainter(),
            ),
          ),

          const SizedBox(height: 20),

          // Day labels with percentages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayLabel('T2', '102%', AppColors.success),
              _buildDayLabel('T3', '89%', AppColors.textSecondary),
              _buildDayLabel('T4', '100%', AppColors.success),
              _buildDayLabel('T5', '92%', AppColors.textSecondary),
              _buildDayLabel('T6', '67%', AppColors.error),
              _buildDayLabel('T7', '80%', AppColors.textSecondary),
              _buildDayLabel('CN', '78%', AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String day, String percentage, Color color) {
    return Column(
      children: [
        Text(
          percentage,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '84%',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Goal met',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '12',
                      style: AppTextStyles.displayMedium.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purpleXP,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withValues(alpha: 0.6)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Day streak',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '14.7L',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This week',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyanLight, AppColors.cyanAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyanAccent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'AI Insights',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInsightCard(
          'HYDRATION',
          'Buổi chiều là điểm yếu của bạn',
          'Bạn thường uống ít nhất vào khoảng 14-17h. Đặt nhắc nhở vào 15h để giúp tăng lượng nước.',
          AppColors.cyanAccent,
          Icons.trending_down,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          'PATTERN',
          'Thứ Hai & Thứ Tư đạt 100%',
          'Thứ Sáu chỉ đạt 67% — có thể do lịch họp tập. Đặt mục tiêu thấp hơn ngày bận.',
          AppColors.purpleXP,
          Icons.analytics,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          'WEATHER',
          'Hôm nay nóng — nước đá tăng',
          'Nhiệt độ 32°C hôm nay. Nên uống thêm 500ml và thêm nước đá để giải nhiệt.',
          AppColors.warning,
          Icons.wb_sunny,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String category,
    String title,
    String description,
    Color accentColor,
    IconData icon,
  ) {
    return EnhancedCard(
      padding: const EdgeInsets.all(22),
      borderColor: accentColor.withValues(alpha: 0.4),
      backgroundColor: accentColor.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the wave chart
class _WaveChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Data points representing hydration levels
    final points = [
      Offset(0, size.height * 0.15), // T2: 102%
      Offset(size.width * 0.17, size.height * 0.45), // T3: 89%
      Offset(size.width * 0.33, size.height * 0.15), // T4: 100%
      Offset(size.width * 0.5, size.height * 0.35), // T5: 92%
      Offset(size.width * 0.67, size.height * 0.8), // T6: 67%
      Offset(size.width * 0.83, size.height * 0.65), // T7: 80%
      Offset(size.width, size.height * 0.7), // CN: 78%
    ];

    // Gradient for the wave line
    final gradient = LinearGradient(
      colors: [
        AppColors.cyanLight.withValues(alpha: 0.9),
        AppColors.cyanAccent,
        AppColors.cyanDeep,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    // Create smooth wave path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) * 0.5,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) * 0.5,
        next.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    canvas.drawPath(path, paint);

    // Add area fill under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.cyanAccent.withValues(alpha: 0.25),
          AppColors.cyanAccent.withValues(alpha: 0.08),
          AppColors.cyanAccent.withValues(alpha: 0.02),
        ],
      ).createShader(rect);

    canvas.drawPath(fillPath, fillPaint);

    // Draw enhanced data points
    final pointPaint = Paint()..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Color based on performance
      if (i == 0 || i == 2) {
        // T2 and T4 (100%+)
        pointPaint.color = AppColors.success;
      } else if (i == 4) {
        // T6 (67% - lowest)
        pointPaint.color = AppColors.error;
      } else {
        pointPaint.color = AppColors.cyanAccent;
      }

      // Draw outer glow
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = pointPaint.color.withValues(alpha: 0.3);
      canvas.drawCircle(point, 12, glowPaint);

      // Draw main point
      canvas.drawCircle(point, 7, pointPaint);
      canvas.drawCircle(point, 7, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
